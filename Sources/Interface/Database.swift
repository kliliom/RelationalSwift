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
            let error = InterfaceError(message: String(cString: sqlite3_errmsg(ptr)), code: result)
            try logAndIgnoreError({ throw error }())
        }
    }
}

/// Database options.
private struct DatabaseOptions: OptionSet {
    let rawValue: UInt32

    /// Cache and reuse the prepared statements.
    static let persistent = DatabaseOptions(rawValue: 1 << 0)
}

/// Database actor.
@DatabaseActor
public final class Database: Sendable {
    /// Database handle.
    let db: DatabaseHandle

    /// Database options.
    private var options: DatabaseOptions = []

    /// Statement cache.
    private var statementCache: [String: OpaquePointer] = [:]

    /// Initializes a database actor.
    /// - Parameter db: Database handle.
    init(db: consuming DatabaseHandle) {
        self.db = db
    }

    deinit {
        for (_, stmtPtr) in statementCache {
            sqlite3_finalize(stmtPtr)
        }
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
    public static func openInMemory() throws -> Database {
        var ptr: OpaquePointer?
        try check(sqlite3_open(":memory:", &ptr), is: SQLITE_OK)
        return Database(db: DatabaseHandle(ptr: ptr!))
    }

    /// Opens an on-disk database
    /// - Parameter url: URL of database to open.
    /// - Returns: The opened database.
    public static func open(url: URL) throws -> Database {
        guard url.isFileURL else {
            throw InterfaceError(message: "can not open non-file url", code: -1)
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
            try logAndIgnoreError(check(sqlite3_finalize(stmtPtr), db: dbPtr, is: SQLITE_OK))
        } else {
            try logAndIgnoreError(check(sqlite3_reset(stmtPtr), db: dbPtr, is: SQLITE_OK))
            try logAndIgnoreError(check(sqlite3_clear_bindings(stmtPtr), db: dbPtr, is: SQLITE_OK))
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

    /// Executes a transaction.
    /// - Parameters:
    ///   - kind: Transaction kind. Default is `.deferred`.
    ///   - block: Transaction block.
    /// - Returns: Result of the transaction.
    public func transaction<T>(
        kind: TransactionKind = .deferred,
        _ block: @DatabaseActor () throws -> T
    ) throws -> T {
        let beginStatement = switch kind {
        case .deferred:
            "BEGIN DEFERRED TRANSACTION"
        case .immediate:
            "BEGIN IMMEDIATE TRANSACTION"
        case .exclusive:
            "BEGIN EXCLUSIVE TRANSACTION"
        }

        try exec(beginStatement)

        do {
            let result = try block()
            try exec("COMMIT TRANSACTION")
            return result
        } catch {
            try exec("ROLLBACK TRANSACTION")
            throw error
        }
    }

    /// Executes a block of code with statement caching enabled.
    /// - Parameter block: Block of code.
    /// - Returns: Result of the block.
    public func cached<T>(_ block: @DatabaseActor () throws -> T) throws -> T {
        options.insert(.persistent)
        defer { options.remove(.persistent) }
        return try block()
    }
}
