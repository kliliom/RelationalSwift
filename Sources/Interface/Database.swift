//
//  Database.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

@globalActor public actor DatabaseActor: GlobalActor {
    public static let shared = DatabaseActor()
}

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
        if sqlite3_close(ptr) != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(ptr))
            warn("Failed to close database: \(message)")
        }
    }
}

/// Database options.
struct DatabaseOptions: OptionSet {
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
    var options: DatabaseOptions = []

    /// Statement cache.
    var statementCache: [String: OpaquePointer] = [:]

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
            throw InterfaceError(message: "cannot open non-file url", code: -1)
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

extension Database {
    /// Captures the last inserted row ID.
    /// - Parameter block: Block of code.
    /// - Returns: Last inserted row ID.
    public func lastInsertedRowID(_ block: @DatabaseActor () throws -> Void) throws -> Int64? {
        sqlite3_set_last_insert_rowid(db.ptr, 0)
        try block()
        let id = sqlite3_last_insert_rowid(db.ptr)
        guard id != 0 else { return nil }
        return id
    }
}

extension Database {
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
}

extension Database {
    /// Executes a block of code with statement caching enabled.
    /// - Parameter block: Block of code.
    /// - Returns: Result of the block.
    public func cached<T>(_ block: @DatabaseActor () throws -> T) rethrows -> T {
        options.insert(.persistent)
        defer { options.remove(.persistent) }
        return try block()
    }
}
