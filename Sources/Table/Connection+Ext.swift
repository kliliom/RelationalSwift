//
//  Connection+Ext.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

extension Bindable {
    var asBinder: Binder {
        { stmt, index in
            try Self.bind(to: stmt, value: self, at: &index)
        }
    }
}

extension Database {
    /// Executes a statement.
    /// - Parameter statement: Statement to execute.
    public func exec(
        _ statement: String
    ) throws {
        try exec(statement, bind: { _ in })
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

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - columns: Columns to extract.
    /// - Returns: Result of the query.
    public func query<each Column: ColumnRef>(
        _ statement: String,
        columns _: repeat each Column
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, step: { stmt, _ in
            var index = ManagedIndex()
            return try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    ///   - columns: Columns to extract.
    /// - Returns: Result of the query.
    public func query<each Column: ColumnRef>(
        _ statement: String,
        binder: Binder,
        columns _: repeat each Column
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        }, step: { stmt, _ in
            var index = ManagedIndex()
            return try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - bind: Values to bind.
    ///   - columns: Columns to extract.
    /// - Returns: Result of the query.
    public func query<each Bind: Bindable, each Column: ColumnRef>(
        _ statement: String,
        bind: (repeat each Bind),
        columns _: repeat each Column
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            repeat try (each Bind).bind(to: stmt, value: each bind, at: &index)
        }, step: { stmt, _ in
            var index = ManagedIndex()
            return try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - columns: Columns to extract.
    ///   - builder: Result builder.
    /// - Returns: Result of the query.
    public func query<T, each Column: ColumnRef>(
        _ statement: String,
        columns _: repeat each Column,
        builder: @Sendable (repeat (each Column).ValueType) -> T
    ) throws -> [T] {
        try query(statement, step: { stmt, _ in
            var index = ManagedIndex()
            return try builder(repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    ///   - columns: Columns to extract.
    ///   - builder: Result builder.
    /// - Returns: Result of the query.
    public func query<T, each Column: ColumnRef>(
        _ statement: String,
        binder: Binder,
        columns _: repeat each Column,
        builder: @Sendable (repeat (each Column).ValueType) -> T
    ) throws -> [T] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        }, step: { stmt, _ in
            var index = ManagedIndex()
            return try builder(repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - bind: Values to bind.
    ///   - columns: Columns to extract.
    ///   - builder: Result builder.
    /// - Returns: Result of the query.
    public func query<T, each Bind: Bindable, each Column: ColumnRef>(
        _ statement: String,
        bind: (repeat each Bind),
        columns _: repeat each Column,
        builder: @Sendable (repeat (each Column).ValueType) -> T
    ) throws -> [T] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            repeat try (each Bind).bind(to: stmt, value: each bind, at: &index)
        }, step: { stmt, _ in
            var index = ManagedIndex()
            return try builder(repeat (each Column).ValueType.column(of: stmt, at: &index))
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - binder: Value binder.
    ///   - step: Row reader.
    /// - Returns: Result of the query.
    public func query<T>(
        _ statement: String,
        binder: Binder,
        step: @Sendable (_ stmt: borrowing StatementHandle) throws -> T
    ) throws -> [T] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            try binder(stmt, &index)
        }, step: { stmt, _ in
            try step(stmt)
        })
    }

    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - bind: Values to bind.
    ///   - step: Row reader.
    /// - Returns: Result of the query.
    public func query<T, each Bind: Bindable>(
        _ statement: String,
        bind: (repeat each Bind),
        step: @Sendable (_ stmt: borrowing StatementHandle) throws -> T
    ) throws -> [T] {
        try query(statement, bind: { stmt in
            var index = ManagedIndex()
            repeat try (each Bind).bind(to: stmt, value: each bind, at: &index)
        }, step: { stmt, _ in
            try step(stmt)
        })
    }
}
