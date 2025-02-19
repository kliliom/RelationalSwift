//
//  PrimaryKeyMutable.swift
//

/// Table with a primary key.
public protocol PrimaryKeyMutable<KeyType> {
    associatedtype KeyType

    /// Primary key of the row.
    var _primaryKey: KeyType { get }

    /// Returns the SQL statement and binder provider for updating a row.
    static var updateAction: (String, @Sendable (Self) -> Database.ManagedBinder) { get }

    /// Returns the SQL statement and binder provider for partially updating a row.
    static func partialUpdateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Database.ManagedBinder)

    /// Returns the SQL statement and binder provider for updating a row or inserting a new one if it doesn't exist.
    ///
    /// For this operation to be supported, all of the table's primary key columns must be insertable.
    static var upsertAction: (String, @Sendable (Self) -> Database.ManagedBinder)? { get }

    /// Returns the SQL statement and binder provider for deleting a row.
    static var deleteAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) { get }
}

extension Database {
    /// Updates a row in the database.
    /// - Parameter row: Row to update.
    public func update<T: Table & PrimaryKeyMutable>(_ row: T) throws {
        let (statement, binderProvider) = T.updateAction
        let binder = binderProvider(row)
        try cached {
            try exec(
                statement,
                binder: { stmt, index in
                    try binder(stmt, &index)
                }
            )
        }
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
        try cached {
            try exec(
                statement,
                binder: { stmt, index in
                    try binder(stmt, &index)
                }
            )
        }
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
            throw RelationalSwiftError.unsupportedOperation
        }
        let (statement, binderProvider) = action
        let binder = binderProvider(row)
        try cached {
            try exec(
                statement,
                binder: { stmt, index in
                    try binder(stmt, &index)
                }
            )
        }
    }

    /// Deletes a row from the database.
    /// - Parameter row: Row to delete.
    public func delete<T: Table & PrimaryKeyMutable>(_ row: T) throws {
        try delete(from: T.self, byKey: row._primaryKey)
    }

    /// Deletes a row from the database by key.
    /// - Parameters:
    ///   - table: Table to delete from.
    ///   - key: Key of the row to delete.
    public func delete<T: Table & PrimaryKeyMutable>(from table: T.Type, byKey key: T.KeyType) throws {
        _ = table
        let (statement, binderProvider) = T.deleteAction
        let binder = binderProvider(key)
        try cached {
            try exec(
                statement,
                binder: { stmt, index in
                    try binder(stmt, &index)
                }
            )
        }
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
