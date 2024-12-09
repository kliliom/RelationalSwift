//
//  Database+Statement.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

/// Wrapper type for a handle to an SQLite statement.
public struct StatementHandle: ~Copyable, Sendable {
    /// Handle to the database.
    let dbPtr: OpaquePointer
    /// Handle to the statement.
    let stmtPtr: OpaquePointer
    /// Flag to free the statement on deinit.
    ///
    /// If the statement is cached, it should not be freed on deinit.
    let freeOnDeinit: Bool

    /// Initializes a statement handle.
    /// - Parameters:
    ///   - dbPtr: Handle to the database.
    ///   - stmtPtr: Handle to the statement.
    ///   - freeOnDeinit: Flag to free the statement on deinit.
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
    /// Prepares a statement for execution.
    /// - Parameter statement: SQL statement to prepare.
    /// - Returns: A handle to the prepared statement.
    func prepare(statement: String) throws -> StatementHandle {
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
            throw InterfaceError.emptyStatement
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
    ///   - stmt: The statement handle to bind values to.
    public typealias Binder = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle
    ) throws -> Void

    /// A closure for extracting values from a statement.
    /// - Parameters:
    ///   - stmt: The statement handle to extract values from.
    ///   - stop: A boolean that can be set to true to stop reading rows.
    public typealias Stepper<R> = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ stop: inout Bool
    ) throws -> R

    /// Executes a statement.
    ///
    /// `exec` methods can be used for statements that do not return any rows.
    ///
    /// You are responsible for binding values in the `binder` closure to the correct parameter index.
    /// The leftmost parameter has an index of 1.
    ///
    /// Here is an example of executing a statement with parameters:
    ///
    /// ```swift
    /// try await db.exec("INSERT INTO users (name, age) VALUES (?, ?)") { stmt in
    ///     try "Foo".bind(to: stmt, at: 1)
    ///     try 42.bind(to: stmt, at: 2)
    /// }
    /// ````
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - binder: A closure that binds values to the statement.
    public func exec(
        _ statement: String,
        binder: Binder
    ) throws {
        let stmt = try prepare(statement: statement)
        try binder(stmt)

        try check(sqlite3_step(stmt.stmtPtr), db: stmt.dbPtr, is: SQLITE_DONE)
    }

    /// Executes a statement without parameters.
    ///
    /// `exec` methods can be used for statements that do not return any rows.
    ///
    /// Here is an example of executing a statement without parameters:
    ///
    /// ```swift
    /// try await db.exec("DELETE FROM users")
    /// ```
    ///
    /// > This is a convenience method for ``exec(_:binder:)-1e07f`` with an empty binder.
    ///
    /// - Parameter statement: SQL statement to execute.
    @inline(__always)
    public func exec(
        _ statement: String
    ) throws {
        try exec(statement, binder: { _ in })
    }

    /// Queries a statement.
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// You are responsible for binding values in the `binder` closure to the correct parameter index.
    /// The leftmost parameter has an index of 1.
    ///
    /// For every row in the result set, the `stepper` closure is called.
    /// You are responsible for extracting the values from the statement from the correct column index.
    /// The leftmost column has an index of 0.
    /// The `stepper` closure has a second parameter, `stop`, which can be set to `true` to stop the iteration.
    ///
    /// Here is an example of querying a statement with parameters:
    ///
    /// ```swift
    /// let namesAndAges = try await db.query("SELECT name, age FROM users WHERE age > ?") { stmt in
    ///     try 20.bind(to: stmt, at: 1)
    /// } stepper: { stmt, _ in
    ///     let name = try String.column(of: stmt, at: 0)
    ///     let age = try Int.column(of: stmt, at: 1)
    ///     return (name, age)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age) years old.")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - binder: A closure that binds values to the statement.
    ///   - stepper: A closure that extracts a values from the statement for each row.
    /// - Returns: Result rows of the query.
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

    /// Queries a statement without parameters.
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// For every row in the result set, the `stepper` closure is called.
    /// You are responsible for extracting the values from the statement from the correct column index.
    /// The leftmost column has an index of 0.
    /// The `stepper` closure has a second parameter, `stop`, which can be set to `true` to stop the iteration.
    ///
    /// Here is an example of querying a statement without parameters:
    ///
    /// ```swift
    /// let namesAndAges = try await db.query("SELECT name, age FROM users") { stmt, _ in
    ///     let name = try String.column(of: stmt, at: 0)
    ///     let age = try Int.column(of: stmt, at: 1)
    ///     return (name, age)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age) years old.")
    /// }
    /// ```
    ///
    /// > This is a convenience method for ``query(_:binder:stepper:)-6qvlh`` with an empty binder.
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
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
    ///   - stmt: The statement handle to bind values to.
    ///   - index: A managed index for binding values.
    public typealias ManagedBinder = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ index: inout ManagedIndex
    ) throws -> Void

    /// A closure for extracting values from a statement with managed index.
    /// - Parameters:
    ///   - stmt: The statement handle to extract values from.
    ///   - index: A managed index for extracting values.
    ///   - stop: A boolean that can be set to true to stop the iteration.
    public typealias ManagedStepper<R> = @DatabaseActor @Sendable (
        _ stmt: borrowing StatementHandle,
        _ index: inout ManagedIndex,
        _ stop: inout Bool
    ) throws -> R

    /// Executes a statement.
    ///
    /// `exec` methods can be used for statements that do not return any rows.
    ///
    /// The `binder` closure has a second parameter, `index`, which is a managed index for binding values.
    /// You are responsible for binding values in the `binder` closure in the correct order using the `index`.
    ///
    /// Here is an example of executing a statement with parameters:
    ///
    /// ```swift
    /// try await db.exec("INSERT INTO users (name, age) VALUES (?, ?)") { stmt, index in
    ///     try "Foo".bind(to: stmt, at: &index)
    ///     try 42.bind(to: stmt, at: &index)
    /// }
    /// ````
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - binder: A closure that binds values to the statement.
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
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// The `binder` closure has a second parameter, `index`, which is a managed index for binding values.
    /// You are responsible for binding values in the `binder` closure in the correct order using the `index`.
    ///
    /// For every row in the result set, the `stepper` closure is called.
    /// The `stepper` closure has a second parameter, `index`, which is a managed index for extracting values.
    /// You are responsible for extracting the values from the statement in the correct order using the `index`.
    /// The `stepper` closure has a third parameter, `stop`, which can be set to `true` to stop the iteration.
    ///
    /// Here is an example of querying a statement with parameters:
    ///
    /// ```swift
    /// let namesAndAges = try await db.query("SELECT name, age FROM users WHERE age > ?") { stmt, index in
    ///     try 20.bind(to: stmt, at: &index)
    /// } stepper: { stmt, index, _ in
    ///     let name = try String.column(of: stmt, at: &index)
    ///     let age = try Int.column(of: stmt, at: &index)
    ///     return (name, age)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age) years old.")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - binder: A closure that binds values to the statement.
    ///   - stepper: A closure that extracts a values from the statement for each row.
    /// - Returns: Result rows of the query.
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

    /// Queries a statement without parameters.
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// For every row in the result set, the `stepper` closure is called.
    /// The `stepper` closure has a second parameter, `index`, which is a managed index for extracting values.
    /// You are responsible for extracting the values from the statement in the correct order using the `index`.
    /// The `stepper` closure has a third parameter, `stop`, which can be set to `true` to stop the iteration.
    ///
    /// Here is an example of querying a statement with parameters:
    ///
    /// ```swift
    /// let namesAndAges = try await db.query("SELECT name, age FROM users") { stmt, index, _ in
    ///     let name = try String.column(of: stmt, at: &index)
    ///     let age = try Int.column(of: stmt, at: &index)
    ///     return (name, age)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age) years old.")
    /// }
    /// ```
    ///
    /// > This is a convenience method for ``query(_:binder:stepper:)-4476r`` with an empty binder.
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - stepper: A closure that extracts a values from the statement for each row.
    /// - Returns: Result rows of the query.
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
    ///
    /// `exec` methods can be used for statements that do not return any rows.
    ///
    /// You are responsible for binding values in the `binding` parameters in the correct order.
    ///
    /// Here is an example of executing a statement with parameters:
    ///
    /// ```swift
    /// try await db.exec("INSERT INTO users (name, age) VALUES (?, ?)",
    ///                   binding: "Foo", 42)
    /// ````
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
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
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// You are responsible for binding values in the `binding` parameters in the correct order.
    ///
    /// For every row in the result set, the `stepper` closure is called.
    /// The `stepper` closure has a second parameter, `index`, which is a managed index for extracting values.
    /// You are responsible for extracting the values from the statement in the correct order using the `index`.
    /// The `stepper` closure has a third parameter, `stop`, which can be set to `true` to stop the iteration.
    ///
    /// Here is an example of querying a statement with parameters:
    ///
    /// ```swift
    /// let namesAndAges = try await db.query(
    ///     "SELECT name, age FROM users WHERE age > ?",
    ///     binding: 20
    /// ) { stmt, index, _ in
    ///     let name = try String.column(of: stmt, at: &index)
    ///     let age = try Int.column(of: stmt, at: &index)
    ///     return (name, age)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age) years old.")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - statement: SQL statement to execute.
    ///   - firstValue: First value to bind.
    ///   - otherValues: Other values to bind.
    ///   - stepper: Row reader.
    /// - Returns: Result rows of the query.
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
