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
