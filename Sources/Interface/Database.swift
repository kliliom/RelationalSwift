//
//  Database.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

/// Database handle.
public struct DatabaseHandle: ~Copyable, Sendable {
    /// Pointer to the database.
    let ptr: OpaquePointer

    /// Initializes a database handle.
    /// - Parameter ptr: Pointer to the database.
    init(ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        let result = sqlite3_close(ptr)
        if result != SQLITE_OK {
            let error = RelationalSwiftError(message: String(cString: sqlite3_errmsg(ptr)), code: result)
            Task {
                await Database.logger(error)
            }
        }
    }
}

/// Database actor.
@DatabaseActor
public final class Database: Sendable {
    /// Database handle.
    let db: DatabaseHandle

    /// Initializes a database actor.
    /// - Parameter db: Database handle.
    init(db: consuming DatabaseHandle) {
        self.db = db
    }
}

extension Database {
    /// Logger type.
    public typealias Logger = @MainActor (_ error: Error) -> Void

    /// Logger that uses `print` to log errors.
    private static let defaultLogger: Logger = { error in
        print("RelationalSwift error:", error)
    }

    /// Logger.
    static var logger: Logger = defaultLogger

    /// Set a logger.
    /// - Parameter logger: Logger.
    public static func set(logger: @escaping Logger) {
        self.logger = logger
    }

    /// Sets the default logger.
    public static func setDefaultLogger() {
        logger = defaultLogger
    }

    /// Opens an in-memory database.
    /// - Returns: The opened database.
    public static func openInMemory() async throws -> Database {
        var ptr: OpaquePointer?
        try check(sqlite3_open(":memory:", &ptr), is: SQLITE_OK)
        return Database(db: DatabaseHandle(ptr: ptr!))
    }

    /// Opens an on-disk database
    /// - Parameter url: URL of database to open.
    /// - Returns: The opened database.
    public static func open(url: URL) async throws -> Database {
        guard url.isFileURL else {
            throw RelationalSwiftError(message: "can not open non-file url", code: -1)
        }
        var ptr: OpaquePointer?
        let path: String = if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            url.path(percentEncoded: false)
        } else {
            url.path
        }
        try check(sqlite3_open(path, &ptr), is: SQLITE_OK)
        return Database(db: DatabaseHandle(ptr: ptr!))
    }
}

/// Statement handle.
public struct StatementHandle: ~Copyable, Sendable {
    /// Database pointer.
    let dbPtr: OpaquePointer
    /// Statement pointer.
    let stmtPtr: OpaquePointer

    /// Initializes a statement handle.
    /// - Parameters:
    ///   - dbPtr: Database pointer.
    ///   - stmtPtr: Statement pointer.
    init(dbPtr: OpaquePointer, stmtPtr: OpaquePointer) {
        self.dbPtr = dbPtr
        self.stmtPtr = stmtPtr
    }

    deinit {
        do {
            try check(sqlite3_finalize(stmtPtr), db: dbPtr, is: SQLITE_OK)
        } catch {
            Task {
                await Database.logger(error)
            }
        }
    }
}

extension Database {
    /// Prepares a statement.
    /// - Parameter statement: The statement to prepare.
    /// - Returns: The prepared statement.
    public func prepare(statement: String) throws -> StatementHandle {
        var ptr: OpaquePointer?
        try check(sqlite3_prepare_v2(db.ptr, statement, -1, &ptr, nil), db: db.ptr, is: SQLITE_OK)
        guard let ptr else {
            throw RelationalSwiftError(message: "nil handle while sqlite3_prepare_v2 == SQLITE_OK", code: -1)
        }
        return StatementHandle(dbPtr: db.ptr, stmtPtr: ptr)
    }

    /// Executes a statement.
    /// - Parameter statement: Statement to execute.
    public func exec(
        _ statement: String
    ) throws {
        let stmt = try prepare(statement: statement)

        try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, is: SQLITE_DONE)
    }

    /// Executes a statement, assuming it returns exactly one row.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - bind: A closure that binds values to the statement.
    public func exec(
        _ statement: String,
        bind: @Sendable (_ handle: borrowing StatementHandle) throws -> Void
    ) throws {
        let stmt = try prepare(statement: statement)
        try bind(stmt)

        try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, is: SQLITE_DONE)
    }

    /// Executes a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
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

    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - bind: A closure that binds values to the statement.
    ///   - step: A closure that extracts a value from the statement for each row.
    /// - Returns: Description
    public func query<R>(
        _ statement: String,
        bind: @Sendable (_ handle: borrowing StatementHandle) throws -> Void = { _ in },
        step: @Sendable (_ handle: borrowing StatementHandle, _ stop: inout Bool) throws -> R = { _, _ in () }
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

    /// Cleared value of the last inserted row ID.
    var clearedLastInsertedRowID: Int64 {
        -1
    }

    /// Clear last inserted row ID.
    public func clearLastInsertedRowID() {
        sqlite3_set_last_insert_rowid(db.ptr, clearedLastInsertedRowID)
    }

    /// Last inserted row ID.
    /// - Returns: Last inserted row ID or nil if the same as cleared value.
    public func lastInsertedRowID() -> Int64? {
        let id = sqlite3_last_insert_rowid(db.ptr)
        guard id != clearedLastInsertedRowID else { return nil }
        return id
    }
}
