//
//  SelectSource.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

/// Select source.
public struct SelectSource<T: TableRef> {
    /// Database.
    let database: Database

    /// Table reference.
    let tableRef: T

    /// Condition.
    let condition: Condition?

    /// Creates a select query for selected columns.
    /// - Parameters:
    ///   - block: Columns builder block.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    public func query<each Column: ColumnRef>(
        _ block: (T) -> (repeat each Column),
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> (String, Binder, (repeat (each Column).ValueType).Type) {
        let columnRefs = block(tableRef)
        var columnSqlRefs: [any ColumnRef] = []
        repeat (columnSqlRefs.append(each columnRefs))

        let select = SelectBuilder(
            from: tableRef._sqlFrom,
            columns: columnSqlRefs,
            condition: condition,
            limit: limit,
            offset: offset
        )
        return try (select.statement(), select.binder, (repeat (each Column).ValueType).self)
    }

    /// Executes a select query for selected columns.
    /// - Parameters:
    ///   - block: Columns builder block.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    public func select<each Column: ColumnRef>(
        _ block: (T) -> (repeat each Column),
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [(repeat (each Column).ValueType)] {
        let columnRefs = block(tableRef)
        var columnSqlRefs: [any ColumnRef] = []
        repeat (columnSqlRefs.append(each columnRefs))

        let select = SelectBuilder(
            from: tableRef._sqlFrom,
            columns: columnSqlRefs,
            condition: condition,
            limit: limit,
            offset: offset
        )
        let database = database
        return try await database.query(
            select.statement(),
            binder: select.binder,
            columns: repeat each columnRefs
        )
    }

    /// Executes a select query for all columns.
    /// - Parameters:
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    public func select(
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [T.TableType] {
        let select = SelectBuilder(
            from: tableRef._sqlFrom,
            columns: tableRef._readColumnSqlRefs,
            condition: condition,
            limit: limit,
            offset: offset
        )
        let database = database
        return try await database.query(select.statement(), binder: select.binder) { stmt in
            var index = Int32()
            return try T.TableType.read(from: stmt, startingAt: &index)
        }
    }

    /// Executes a select query for all columns and returns the first entry (if exists).
    /// - Returns: First entry of the query or nil.
    /// - Parameter block: Columns builder block.
    public func selectFirst<each Column: ColumnRef>(
        _ block: (T) -> (repeat each Column)
    ) async throws -> (repeat (each Column).ValueType)? {
        try await select(block, limit: 1).first
    }

    /// Executes a select query for all columns and returns the first entry (if exists).
    /// - Returns: First entry of the query or nil.
    public func selectFirst() async throws -> T.TableType? {
        try await select(limit: 1).first
    }

    /// Executes a delete statement.
    public func delete() async throws {
        let stmt = DeleteBuilder(
            from: tableRef._sqlFrom,
            condition: condition
        )
        let database = database
        return try await database.exec(stmt.statement(), binder: stmt.binder)
    }

    /// Executes a count statement.
    /// - Parameters:
    ///   - distinct: Count only distinct rows. Default is `false`.
    ///   - block: Column builder block.
    /// - Returns: The count of the column vaues.
    public func count(
        distinct: Bool = false,
        _ block: (T) -> any ColumnRef
    ) async throws -> Int64 {
        let stmt = CountBuilder(
            from: tableRef._sqlFrom,
            column: block(tableRef),
            condition: condition,
            distinct: distinct
        )
        let database = database
        return try await database.query(stmt.statement(), binder: stmt.binder) { stmt in
            var index = Int32()
            return try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Executes a count statement
    /// - Returns: The count of the rows.
    public func count() async throws -> Int64 {
        let stmt = CountBuilder(
            from: tableRef._sqlFrom,
            condition: condition
        )
        let database = database
        return try await database.query(stmt.statement(), binder: stmt.binder) { stmt in
            var index = Int32()
            return try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Adds a condition to the select query.
    /// - Parameter block: Condition builder block.
    /// - Returns: Select source with the added condition.
    public func `where`(_ block: (T) throws -> Condition) rethrows -> SelectSource<T> {
        try SelectSource(database: database,
                         tableRef: tableRef,
                         condition: block(tableRef))
    }
}

extension Database {
    /// Initializes a new select source.
    /// - Parameter table: Table reference.
    /// - Returns: Select source.
    public nonisolated func from<T: TableRef>(_ table: T) -> SelectSource<T> {
        SelectSource(database: self, tableRef: table, condition: nil)
    }
}
