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
    static var selectAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) { get }

    /// Returns the SQL statement and binder provider for reading the rowid of a row.
    static var selectRowIDAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) { get }
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
                binder: { stmt, index in
                    try binder(stmt, &index)
                },
                stepper: { stmt, index, _ in
                    try T.read(from: stmt, startingAt: &index)
                }
            )
        }
        return rows.first
    }

    /// Reads the rowid of a row from the database.
    /// - Parameter row: Row to read the rowid of.
    /// - Returns: Rowid.
    public func selectRowID<T: Table & PrimaryKeyAccessible>(of row: T) throws -> Int64? {
        let (statement, binderProvider) = T.selectRowIDAction
        let binder = binderProvider(row._primaryKey)
        let rows = try cached {
            try query(
                statement,
                binder: { stmt, index in
                    try binder(stmt, &index)
                },
                stepper: { stmt, index, _ in
                    try Int64.column(of: stmt, at: &index)
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
