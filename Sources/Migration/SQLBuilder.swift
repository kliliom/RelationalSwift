//
//  SQLBuilder.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// SQL builder.
///
/// A SQL builder is used to construct SQL queries and execute them.
public class SQLBuilder {
    /// SQL parts.
    public var sql: [String] = []
    /// Parameter binders.
    public var binders: [Database.ManagedBinder] = []

    /// Executes the SQL query.
    /// - Parameter db: Database to execute the statement in.
    @DatabaseActor
    func execute(in db: Database) throws {
        let sql = sql.joined(separator: " ")
        let binders = binders
        try db.exec(sql) { handle, index in
            for binder in binders {
                try binder(handle, &index)
            }
        }
    }
}

/// SQL convertible.
public protocol SQLConvertible: Sendable {
    /// Appends the SQL representation to the builder.
    /// - Parameter builder: SQL builder.
    func append(to builder: SQLBuilder)
}
