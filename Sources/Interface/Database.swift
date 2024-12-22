//
//  Database.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

/// A singleton actor for database operations.
@globalActor public actor DatabaseActor: GlobalActor {
    public static let shared = DatabaseActor()
}

/// Wrapper type for a handle to an SQLite database.
public struct DatabaseHandle: ~Copyable, Sendable {
    /// Handle to the database.
    let ptr: OpaquePointer

    /// Initializes a database handle.
    /// - Parameter ptr: Handle to the database.
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

    /// Transaction is active.
    static let transactionActive = DatabaseOptions(rawValue: 2 << 0)
}

/// An interface for interacting with an SQLite database.
@DatabaseActor
public final class Database: Sendable {
    /// Handle to the database.
    let db: DatabaseHandle

    /// Runtime options.
    var options: DatabaseOptions = []

    /// Statement cache.
    var statementCache: [String: OpaquePointer] = [:]

    /// Registered services.
    var services: [ObjectIdentifier: Service] = [:]

    /// Initializes a database connection.
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
    /// Opens a connection to an in-memory database.
    ///
    /// In-memory databases are not persisted to disk and are destroyed when the connection is closed.
    ///
    /// Here is an example of opening an in-memory database:
    ///
    /// ```swift
    /// let db = try await Database.openInMemory()
    /// ```
    ///
    /// - Returns: A new ``Database`` instance pointing to an in-memory database.
    public static func openInMemory() throws -> Database {
        var ptr: OpaquePointer?
        try check(sqlite3_open(":memory:", &ptr), is: SQLITE_OK)
        return Database(db: DatabaseHandle(ptr: ptr!))
    }

    /// Opens a connection to an on-disk database.
    ///
    /// > Only URLs with the `file:` scheme are supported.
    ///
    /// Here is an example of how to open a database from the documents directory:
    ///
    /// ```swift
    /// // Get the URL of the documents directory.
    /// let documentsURL = FileManager.default
    ///     .urls(for: .documentDirectory, in: .userDomainMask)
    ///     .first!
    ///
    /// // Append the database file name to the documents URL.
    /// let databaseURL = documentsURL.appending(path: "db.sqlite")
    ///
    /// // Open the database.
    /// let db = try await Database.open(url: databaseURL)
    /// ```
    ///
    /// - Parameter url: File URL of database to open.
    /// - Returns: A new ``Database`` instance pointing to the database at the given URL.
    public static func open(url: URL) throws -> Database {
        guard url.isFileURL else {
            throw InterfaceError.notAFileURL
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
    ///
    /// This method is useful when you need to capture the last inserted row ID after an `INSERT` statement.
    ///
    /// Here is an example of capturing the last inserted row ID:
    ///
    /// ```swift
    /// let rowID = try await db.lastInsertedRowID {
    ///     try db.exec("INSERT INTO users (name, age) VALUES ('Foo', 42)")
    /// }
    /// if let rowID {
    ///     print("Inserted row with ROWID: \(rowID)")
    /// }
    /// ```
    ///
    /// - Parameter block: Block which contains the `INSERT` statement.
    /// - Returns: Last inserted row ID or `nil` if no row was inserted.
    public func lastInsertedRowID(_ block: @DatabaseActor () throws -> Void) throws -> Int64? {
        sqlite3_set_last_insert_rowid(db.ptr, 0)
        try block()
        let id = sqlite3_last_insert_rowid(db.ptr)
        guard id != 0 else { return nil }
        return id
    }
}

extension Database {
    /// Executes multiple SQL statements in a single transaction.
    ///
    /// This method is useful when you need to execute multiple SQL statements in a single transaction.
    ///
    /// If an error occurs during the execution of the `block` closure or when committing the transaction, the
    /// transaction is rolled back.
    ///
    /// Here is an example of executing multiple SQL statements in a transaction:
    ///
    /// ```swift
    /// try await db.transaction {
    ///     try db.exec("INSERT INTO users (name, age) VALUES ('Foo', 42)")
    ///     try db.exec("INSERT INTO users (name, age) VALUES ('Bar', 24)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - kind: Transaction kind. Default value is ``TransactionKind/deferred``.
    ///   - block: Block which contains the SQL statements.
    /// - Returns: Result of the `block` closure.
    public func transaction<T>(
        kind: TransactionKind = .deferred,
        _ block: @DatabaseActor () throws -> T
    ) throws -> T {
        if options.contains(.transactionActive) {
            warn("Nested transactions are not supported, executing in the current transaction.")
            return try block()
        }

        options.insert(.transactionActive)
        signalTransactionWillBegin()
        defer { options.remove(.transactionActive) }

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
            signalTransactionDidCommit()
            return result
        } catch {
            signalTransactionDidRollback()
            do {
                try exec("ROLLBACK TRANSACTION")
            } catch {
                warn("Failed to rollback transaction: \(error)")
                fatalError("Aborting due to failed transaction rollback.")
            }
            throw error
        }
    }
}

extension Database {
    /// Executes a block of code with statement caching enabled.
    ///
    /// Statement caching speeds up the execution of SQL statements by reusing prepared statements.
    ///
    /// Here is an example of using statement caching:
    ///
    /// ```swift
    /// let names = try await db.cached {
    ///     try db.query("SELECT name FROM users") { stmt, index, _ in
    ///         try String.column(of: stmt, at: &index)
    ///     }
    /// }
    /// ```
    ///
    /// The cached variant of the statement is only used within a `cached` block:
    ///
    /// ```swift
    /// try await db.cached {
    ///     // Caches the statement on the first run
    ///     try db.exec("INSERT INTO users (name) VALUES (?)", binding: "Baz")
    /// }
    ///
    /// try await db.cached {
    ///     // Reuses the cached statement
    ///     try db.exec("INSERT INTO users (name) VALUES (?)", binding: "Foo")
    /// }
    ///
    /// // Does not reuse the cached statement
    /// try await db.exec("INSERT INTO users (name) VALUES (?)", binding: "Baz")
    /// ```
    ///
    /// - Parameter block: Block containing the SQL statements.
    /// - Returns: Result of the `block` closure.
    public func cached<T>(_ block: @DatabaseActor () throws -> T) rethrows -> T {
        if options.contains(.persistent) {
            return try block()
        }

        options.insert(.persistent)
        defer { options.remove(.persistent) }
        return try block()
    }
}

extension Database {
    /// Gives direct access to the database handle.
    ///
    /// This method is useful when you need to access the database handle directly using the SQLite C API.
    ///
    /// - Warning: It is highly discouraged to store or use the database handle outside of the `block` closure.
    ///
    /// - Parameter block: Block in which the database handle is safely accessible.
    /// - Returns: Result of the `block` closure.
    public func directAccess<T>(_ block: @DatabaseActor (_ ptr: OpaquePointer) throws -> T) rethrows -> T {
        try block(db.ptr)
    }
}
