//
//  Insertable.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// Table with insertable rows.
public protocol Insertable {
    /// Returns the SQL statement and binder provider for inserting a row.
    static var insertAction: (String, @Sendable (Self) -> Binder) { get }

    /// Returns the SQL statement and binder provider for reading a row by row ID.
    static var readByRowIDAction: (String, @Sendable (Int64) -> Binder) { get }

    /// Returns the SQL statement for creating the table.
    static var createTableAction: String { get }
}

extension Database {
    /// Inserts a row into the database.
    /// - Parameter row: Row to insert.
    public func insert<T: Table & Insertable>(_ row: T) throws {
        let (statement, binderProvider) = T.insertAction
        let binder = binderProvider(row)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )
    }

    /// Inserts a row into the database.
    ///
    /// This method fetches the row by row ID after insertion and overwrites the input row with the fetched row.
    /// This is useful when the row has default values that are set by the database.
    ///
    /// - Parameter row: Row to insert.
    public func insert<T: Table & Insertable>(_ row: inout T) throws {
        clearLastInsertedRowID()
        let (statement, binderProvider) = T.insertAction
        let binder = binderProvider(row)
        try exec(
            statement,
            bind: { stmt in
                var index = ManagedIndex()
                try binder(stmt, &index)
            }
        )

        if let rowID = lastInsertedRowID() {
            let (statement, binderProvider) = T.readByRowIDAction
            let binder = binderProvider(rowID)
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
            guard let first = rows.first else {
                throw TableError(message: "failed to get row by rowid")
            }
            row = first
        }
    }

    /// Creates the table in the database.
    /// - Parameter tableType: Type to create the table for.
    public func createTable(for tableType: (some Table & Insertable).Type) throws {
        let statement = tableType.createTableAction
        try exec(statement)
    }
}
