//
//  Database+ColumnRef.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

extension Database {
    /// Queries a statement.
    ///
    /// `query` methods can be used for statements that can return rows.
    ///
    /// The `binder` closure has a second parameter, `index`, which is a managed index for binding values.
    /// You are responsible for binding values in the `binder` closure in the correct order using the `index`.
    ///
    /// Here is an example of querying a statement with parameters:
    ///
    /// ```swift
    /// @Table("users")
    /// struct User {
    ///     @Column(primaryKey: true, insert: false) var id: Int
    ///     @Column var name: String
    ///     @Column var age: Int?
    /// }
    ///
    /// let namesAndAges = try await db.query(
    ///     "SELECT name, age FROM users WHERE age > ?",
    ///     columns: User.table.name, User.table.age
    /// ) { stmt, index in
    ///     try 20.bind(to: stmt, at: &index)
    /// }
    ///
    /// for (name, age) in namesAndAges {
    ///     print("\(name) is \(age.map { String($0) } ?? "unknown") years old.")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - statement: The statement to execute.
    ///   - columns: Columns to extract.
    ///   - binder: A closure that binds values to the statement.
    /// - Returns: Description
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
