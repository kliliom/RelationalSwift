//
//  Database+Statement.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

/// Statement handle.
public struct StatementHandle: ~Copyable, Sendable {
    /// Database pointer.
    let dbPtr: OpaquePointer
    /// Statement pointer.
    let stmtPtr: OpaquePointer
    /// Whether to free the statement on deinit.
    let freeOnDeinit: Bool

    /// Initializes a statement handle.
    /// - Parameters:
    ///   - dbPtr: Database pointer.
    ///   - stmtPtr: Statement pointer.
    ///   - freeOnDeinit: Whether to free the statement on deinit.
    init(dbPtr: OpaquePointer, stmtPtr: OpaquePointer, freeOnDeinit: Bool) {
        self.dbPtr = dbPtr
        self.stmtPtr = stmtPtr
        self.freeOnDeinit = freeOnDeinit
    }

    deinit {
        if freeOnDeinit {
            if sqlite3_finalize(stmtPtr) != SQLITE_OK {
                let message = String(cString: sqlite3_errmsg(dbPtr))
                warn("Failed to finalize statement: \(message)")
            }
        } else {
            if sqlite3_reset(stmtPtr) != SQLITE_OK {
                let message = String(cString: sqlite3_errmsg(dbPtr))
                warn("Failed to reset statement: \(message)")
            }
            if sqlite3_clear_bindings(stmtPtr) != SQLITE_OK {
                let message = String(cString: sqlite3_errmsg(dbPtr))
                warn("Failed to clear bindings: \(message)")
            }
        }
    }
}

extension Database {
    /// Prepares a statement.
    /// - Parameter statement: The statement to prepare.
    /// - Returns: The prepared statement.
    public func prepare(statement: String) throws -> StatementHandle {
        let useCache = options.contains(.persistent)

        if useCache, let stmtPtr = statementCache[statement] {
            return StatementHandle(dbPtr: db.ptr, stmtPtr: stmtPtr, freeOnDeinit: false)
        }

        var ptr: OpaquePointer?
        let flags: UInt32 = if useCache {
            UInt32(bitPattern: SQLITE_PREPARE_PERSISTENT)
        } else {
            0
        }
        try check(sqlite3_prepare_v3(db.ptr, statement, -1, flags, &ptr, nil), db: db.ptr, is: SQLITE_OK)
        guard let ptr else {
            throw InterfaceError(message: "nil handle while sqlite3_prepare_v2 == SQLITE_OK", code: -1)
        }

        if useCache {
            statementCache[statement] = ptr
        }

        return StatementHandle(dbPtr: db.ptr, stmtPtr: ptr, freeOnDeinit: !useCache)
    }
}

extension Database {
    /// A closure for binding parameters to a statement.
    /// - Parameters:
    ///   - stmt: The statement to bind values to.
    public typealias Binder = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle
    ) throws -> Void

    /// A closure for extracting values from a statement.
    /// - Parameters:
    ///   - stmt: The statement to extract values from.
    ///   - stop: A boolean that can be set to true to stop the iteration.
    public typealias Stepper<R> = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ stop: inout Bool
    ) throws -> R

    /// Executes a statement.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - binder: A closure that binds values to the statement.
    public func exec(
        _ statement: String,
        binder: Binder
    ) throws {
        let stmt = try prepare(statement: statement)
        try binder(stmt)

        try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, is: SQLITE_DONE)
    }

    /// Executes a statement.
    /// - Parameter statement: Statement to execute.
    @inline(__always)
    public func exec(
        _ statement: String
    ) throws {
        try exec(statement, binder: { _ in })
    }

    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - binder: A closure that binds values to the statement.
    ///   - stepper: A closure that extracts a value from the statement for each row.
    /// - Returns: Description
    public func query<R>(
        _ statement: String,
        binder: Binder,
        stepper: Stepper<R>
    ) throws -> [R] {
        let stmt = try prepare(statement: statement)
        try binder(stmt)

        var rows = [R]()
        var code = try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, in: SQLITE_ROW, SQLITE_DONE)
        var stop = false
        while code == SQLITE_ROW {
            try rows.append(stepper(stmt, &stop))
            if stop {
                code = SQLITE_DONE
            } else {
                code = try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, in: SQLITE_ROW, SQLITE_DONE)
            }
        }
        return rows
    }

    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - stepper: A closure that extracts a value from the statement for each row.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R>(
        _ statement: String,
        stepper: Stepper<R>
    ) throws -> [R] {
        try query(statement, binder: { _ in }, stepper: stepper)
    }
}

extension Database {
    /// A closure for binding parameters to a statement with managed index.
    /// - Parameters:
    ///   - stmt: The statement to bind values to.
    ///   - index: A managed index for binding values.
    public typealias ManagedBinder = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ index: inout ManagedIndex
    ) throws -> Void

    /// A closure for extracting values from a statement with managed index.
    /// - Parameters:
    ///   - stmt: The statement to extract values from.
    ///   - index: A managed index for extracting values.
    ///   - stop: A boolean that can be set to true to stop the iteration.
    public typealias ManagedStepper<R> = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ index: inout ManagedIndex,
        _ stop: inout Bool
    ) throws -> R

    /// Executes a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    @inline(__always)
    public func exec(
        _ statement: String,
        binder: ManagedBinder
    ) throws {
        try exec(statement, binder: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    ///   - stepper: Row reader.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R>(
        _ statement: String,
        binder: ManagedBinder,
        stepper: ManagedStepper<R>
    ) throws -> [R] {
        try query(statement, binder: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        }, stepper: { stmt, stop in
            var index = ManagedIndex()
            return try stepper(stmt, &index, &stop)
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - stepper: Row reader.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R>(
        _ statement: String,
        stepper: ManagedStepper<R>
    ) throws -> [R] {
        try query(statement, binder: { _, _ in }, stepper: stepper)
    }
}

extension Database {
    /// Executes a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - firstValue: First value to bind.
    ///   - otherValues: Other values to bind.
    @inline(__always)
    public func exec<each Values: Bindable>(
        _ statement: String,
        binding firstValue: some Bindable,
        _ otherValues: repeat each Values
    ) throws {
        // It should be possible to skip this "packing into an array" trick
        // in the future, but current Swift 6 compiler has an issue with this
        // try exec(statement, binder: { stmt, index in
        //     try firstValue.bind(to: stmt, at: &index)
        //     try repeat (each otherValues).bind(to: stmt, at: &index)
        // })

        var binders: [ManagedBinder] = [
            firstValue.managedBinder,
        ]
        repeat (binders.append((each otherValues).managedBinder))
        let captured = binders
        try exec(statement, binder: { stmt, index in
            try captured.forEach { try $0(stmt, &index) }
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - firstValue: First value to bind.
    ///   - otherValues: Other values to bind.
    ///   - stepper: Row reader.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R, each Values: Bindable>(
        _ statement: String,
        binding firstValue: some Bindable,
        _ otherValues: repeat each Values,
        stepper: ManagedStepper<R>
    ) throws -> [R] {
        // It should be possible to skip this "packing into an array" trick
        // in the future, but current Swift 6 compiler has an issue with this
        // try query(statement, binder: { stmt, index in
        //     try firstValue.bind(to: stmt, at: &index)
        //     repeat try (each Values).bind(to: stmt, value: each otherValues, at: &index)
        // }, stepper: { stmt, index, stop in
        //     try stepper(stmt, &index, &stop)
        // })

        var binders: [ManagedBinder] = [
            firstValue.managedBinder,
        ]
        repeat (binders.append((each otherValues).managedBinder))
        let captured = binders
        return try query(statement, binder: { stmt, index in
            try captured.forEach { try $0(stmt, &index) }
        }, stepper: { stmt, index, stop in
            try stepper(stmt, &index, &stop)
        })
    }
}
