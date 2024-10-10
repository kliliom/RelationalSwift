//
//  Table.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
@_exported import Interface

/// A table in the database.
public protocol Table<TableRefType>: Sendable {
    /// Table reference type.
    associatedtype TableRefType: TableRef

    /// Returns a table reference.
    static var table: TableRefType { get }

    /// Reads a row from the database.
    /// - Parameters:
    ///   - stmt: Statement handle.
    ///   - index: Starting index to read from.
    /// - Returns: Row.
    static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> Self

    /// Reads a row from the database.
    /// - Parameter rowID: Row ID.
    /// - Returns: SQL statement and binder.
    static func read(rowID: Int64) throws -> (String, Binder)

    /// Inserts a row into the database.
    /// - Parameter entry: Row to insert.
    /// - Returns: SQL statement and binder.
    static func insert(entry: Self) throws -> (String, Binder)

    /// Updates a row in the database.
    /// - Parameter entry: Row to update.
    /// - Returns: SQL statement and binder.
    static func update(entry: Self) throws -> (String, Binder)

    /// Deletes a row from the database.
    /// - Parameter entry: Row to delete.
    /// - Returns: SQL statement and binder.
    static func delete(entry: Self) throws -> (String, Binder)

    /// Creates this table in the database.
    /// - Returns: SQL statement.
    static func createTable() throws -> String
}

extension Database {
    /// Inserts a row into the database.
    /// - Parameter entry: Row to insert.
    public func insert<T: Table>(_ entry: T) throws {
        let (statement, binder) = try T.insert(entry: entry)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Inserts a row into the database.
    /// - Parameter entry: Row to insert.
    public func insert<T: Table>(_ entry: inout T) throws {
        clearLastInsertedRowID()
        let (statement, binder) = try T.insert(entry: entry)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )

        if let rowID = lastInsertedRowID() {
            let (statement, binder) = try T.read(rowID: rowID)
            let rows = try query(
                statement,
                bind: { stmt in
                    var index = ManagedIndex()
                    try binder(stmt, &index)
                },
                step: { stmt, _ in
                    var index = ManagedIndex()
                    return try T.read(from: stmt, startingAt: &index)
                }
            )
            guard let row = rows.first else {
                throw DB4SwiftError(message: "failed to get row by rowid")
            }
            entry = row
        }
    }

    /// Updates a row in the database.
    /// - Parameter entry: Row to update.
    public func update<T: Table>(_ entry: T) throws {
        let (statement, binder) = try T.update(entry: entry)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Deletes a row from the database.
    /// - Parameter entry: Row to delete.
    public func delete<T: Table>(_ entry: T) throws {
        let (statement, binder) = try T.delete(entry: entry)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Creates the table in the database.
    /// - Parameter tableType: Type to create the table for.
    public func createTable(for tableType: (some Table).Type) throws {
        let statement = try tableType.createTable()
        try exec(statement)
    }
}
