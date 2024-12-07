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

public typealias Bind = @Sendable (_ handle: borrowing StatementHandle) throws -> Void

public typealias Step<R> = @Sendable (_ handle: borrowing StatementHandle, _ stop: inout Bool) throws -> R

extension Database {
    /// Executes a statement, assuming it returns exactly one row.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - bind: A closure that binds values to the statement.
    public func exec(
        _ statement: String,
        bind: Bind
    ) throws {
        let stmt = try prepare(statement: statement)
        try bind(stmt)

        try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, is: SQLITE_DONE)
    }

    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - bind: A closure that binds values to the statement.
    ///   - step: A closure that extracts a value from the statement for each row.
    /// - Returns: Description
    public func query<R>(
        _ statement: String,
        bind: Bind,
        step: Step<R>
    ) throws -> [R] {
        let stmt = try prepare(statement: statement)
        try bind(stmt)

        var rows = [R]()
        var code = try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, in: SQLITE_ROW, SQLITE_DONE)
        var stop = false
        while code == SQLITE_ROW {
            try rows.append(step(stmt, &stop))
            if stop {
                code = SQLITE_DONE
            } else {
                code = try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, in: SQLITE_ROW, SQLITE_DONE)
            }
        }
        return rows
    }
}

extension Database {
    /// Executes a statement.
    /// - Parameter statement: Statement to execute.
    @inline(__always)
    public func exec(
        _ statement: String
    ) throws {
        try exec(statement, bind: { _ in })
    }

    /// Executes a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    @inline(__always)
    public func exec(
        _ statement: String,
        binder: Binder
    ) throws {
        try exec(statement, bind: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        })
    }

    /// Executes a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - bind: Values to bind.
    @inline(__always)
    public func exec<each Bind: Bindable>(
        _ statement: String,
        bind: repeat each Bind
    ) throws {
        // It should be possible to skip this "packing into an array" trick
        // in the future, but current Swift 6 compiler has an issue with this
        // try exec(statement, bind: { stmt in
        //     var index = ManagedIndex()
        //     try repeat (each bind).bind(to: stmt, at: &index)
        // })

        var binders = [Binder]()
        repeat (binders.append((each bind).asBinder))
        let captured = binders
        try exec(statement, bind: { stmt in
            var index = ManagedIndex()
            try captured.forEach { try $0(stmt, &index) }
        })
    }
}

extension Database {
    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - bind: A closure that binds values to the statement.
    ///   - step: A closure that extracts a value from the statement for each row.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R>(
        _ statement: String,
        step: Step<R>
    ) throws -> [R] {
        try query(statement, bind: { _ in }, step: step)
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    ///   - step: Row reader.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R>(
        _ statement: String,
        binder: Binder,
        step: Step<R>
    ) throws -> [R] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        }, step: { stmt, stop in
            try step(stmt, &stop)
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - bind: Values to bind.
    ///   - step: Row reader.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<R, each Bind: Bindable>(
        _ statement: String,
        bind: (repeat each Bind),
        step: Step<R>
    ) throws -> [R] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            repeat try (each Bind).bind(to: stmt, value: each bind, at: &index)
        }, step: { stmt, stop in
            try step(stmt, &stop)
        })
    }
}
