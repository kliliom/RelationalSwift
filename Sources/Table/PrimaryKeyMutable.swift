//
//  PrimaryKeyMutable.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// Table with a primary key.
public protocol PrimaryKeyMutable<KeyType> {
    associatedtype KeyType

    /// Returns the SQL statement and binder provider for updating a row.
    static var updateAction: (String, @Sendable (Self) -> Binder) { get }

    /// Returns the SQL statement and binder provider for partially updating a row.
    static func updateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Binder)

    /// Returns the SQL statement and binder provider for deleting a row.
    static var deleteAction: (String, @Sendable (Self) -> Binder) { get }
}

extension Database {
    /// Updates a row in the database.
    /// - Parameter row: Row to update.
    public func update<T: Table & PrimaryKeyMutable>(_ row: T) throws {
        let (statement, binderProvider) = T.updateAction
        let binder = binderProvider(row)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Updates the specified columns of a row in the database.
    /// - Parameters:
    ///   - row: Row to update.
    ///   - firstColumn: First column to update.
    ///   - otherColumns: Additional columns to update.
    public func update<T: Table & PrimaryKeyMutable>(
        _ row: T,
        columns firstColumn: PartialKeyPath<T>,
        _ otherColumns: PartialKeyPath<T>...
    ) throws {
        let (statement, binder) = try T.updateAction(row, columns: [firstColumn] + otherColumns)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Deletes a row from the database.
    /// - Parameter row: Row to delete.
    public func delete<T: Table & PrimaryKeyMutable>(_ row: T) throws {
        let (statement, binderProvider) = T.deleteAction
        let binder = binderProvider(row)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }
}
