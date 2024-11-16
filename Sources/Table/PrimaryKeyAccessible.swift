//
//  PrimaryKeyAccessible.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// Table with a primary key.
public protocol PrimaryKeyAccessible<KeyType> {
    associatedtype KeyType

    /// Primary key of the row.
    var _primaryKey: KeyType { get }

    /// Returns the SQL statement and binder provider for reading a row.
    static var selectAction: (String, @Sendable (KeyType) -> Binder) { get }
}

extension Database {
    /// Reads a row from the database.
    /// - Parameter key: Key of the row to read.
    /// - Returns: Row.
    public func select<T: Table & PrimaryKeyAccessible>(byKey key: T.KeyType) throws -> T? {
        let (statement, binderProvider) = T.selectAction
        let binder = binderProvider(key)
        let rows = try cached {
            try query(
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
        }
        return rows.first
    }
}

extension Database {
    /// Refreshes a row from the database.
    /// - Parameter row: Row to refresh.
    public func refresh<T: Table & PrimaryKeyAccessible>(_ row: inout T) throws {
        guard let refreshedRow = try cached({ try select(byKey: row._primaryKey) as T? }) else {
            throw TableError(message: "row not found.")
        }
        row = refreshedRow
    }
}
