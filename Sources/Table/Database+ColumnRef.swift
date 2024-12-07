//
//  Database+ColumnRef.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

extension Database {
    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - columns: Columns to extract.
    ///   - binder: A closure that binds values to the statement.
    /// - Returns: Description
    @inline(__always)
    public func query<each Column: ColumnRef>(
        _ statement: String,
        columns _: repeat each Column,
        binder: Binder
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, binder: binder) { stmt, _ in
            var index = ManagedIndex()
            return try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        }
    }

    /// Queries a statement, assuming it returns zero or more rows.
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - columns: Columns to extract.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<each Column: ColumnRef>(
        _ statement: String,
        columns _: repeat each Column
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement) { stmt, index, _ in
            try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        }
    }
}

extension Database {
    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - columns: Columns to extract.
    ///   - binder: Value binder.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<each Column: ColumnRef>(
        _ statement: String,
        columns _: repeat each Column,
        binder: ManagedBinder
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, binder: binder) { stmt, index, _ in
            try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        }
    }
}

extension Database {
    /// Queries a statement.
    /// - Parameters:
    ///   - statement: Statement to execute.
    ///   - columns: Columns to extract.
    ///   - firstValue: First value to bind.
    ///   - otherValues: Other values to bind.
    /// - Returns: Result of the query.
    @inline(__always)
    public func query<each Column: ColumnRef, each Values: Bindable>(
        _ statement: String,
        columns _: repeat each Column,
        binding firstValue: some Bindable,
        _ otherValues: repeat each Values
    ) throws -> [(repeat (each Column).ValueType)] {
        try query(statement, binding: firstValue, repeat each otherValues) { stmt, index, _ in
            try (repeat (each Column).ValueType.column(of: stmt, at: &index))
        }
    }
}
