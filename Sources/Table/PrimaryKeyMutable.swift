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
    static func partialUpdateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Binder)

    /// Returns the SQL statement and binder provider for updating a row or inserting a new one if it doesn't exist.
    ///
    /// For this operation to be supported, all of the table's primary key columns must be insertable.
    static var upsertAction: (String, @Sendable (Self) -> Binder)? { get }

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
    ///   - columns: Columns to update.
    public func update<T: Table & PrimaryKeyMutable>(
        _ row: T,
        columns: [PartialKeyPath<T>]
    ) throws {
        guard !columns.isEmpty else { return }

        let (statement, binder) = try T.partialUpdateAction(row, columns: columns)
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
    ///   - columns: Columns to update.
    public func update<T: Table & PrimaryKeyMutable>(
        _ row: T,
        columns: PartialKeyPath<T>...
    ) throws {
        try update(row, columns: columns)
    }

    /// Updates a row in the database or inserts a new one if it doesn't exist.
    /// - Parameter row: Row to update or insert.
    public func upsert<T: Table & PrimaryKeyMutable>(_ row: T) throws {
        guard let action = T.upsertAction else {
            throw TableError(message: "unsupported operation.")
        }
        let (statement, binderProvider) = action
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

extension Database {
    /// Updates a row in the database.
    ///
    /// This method refreshes the row with the updated values from the database.
    ///
    /// - Parameter row: Row to update.
    public func update(
        _ row: inout some Table & PrimaryKeyAccessible & PrimaryKeyMutable
    ) throws {
        try update(row)
        try refresh(&row)
    }

    /// Updates the specified columns of a row in the database.
    ///
    /// This method refreshes the row with the updated values from the database.
    ///
    /// - Parameters:
    ///   - row: Row to update.
    ///   - columns: Columns to update.
    public func update<T: Table & PrimaryKeyAccessible & PrimaryKeyMutable>(
        _ row: inout T,
        columns: [PartialKeyPath<T>]
    ) throws {
        try update(row, columns: columns)
        try refresh(&row)
    }

    /// Updates the specified columns of a row in the database.
    ///
    /// This method refreshes the row with the updated values from the database.
    ///
    /// - Parameters:
    ///   - row: Row to update.
    ///   - columns: Columns to update.
    public func update<T: Table & PrimaryKeyAccessible & PrimaryKeyMutable>(
        _ row: inout T,
        columns: PartialKeyPath<T>...
    ) throws {
        try update(row, columns: columns)
        try refresh(&row)
    }

    /// Updates a row in the database or inserts a new one if it doesn't exist.
    ///
    /// This method refreshes the row with the updated values from the database.
    ///
    /// - Parameter row: Row to update or insert.
    public func upsert(
        _ row: inout some Table & PrimaryKeyAccessible & PrimaryKeyMutable
    ) throws {
        try upsert(row)
        try refresh(&row)
    }
}
