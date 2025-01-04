//
//  SelectSource.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Select source.
public struct SelectSource<T: TableRef>: Sendable {
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
    ) throws -> (String, Database.ManagedBinder, (repeat (each Column).ValueType).Type) {
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
    @DatabaseActor
    public func select<each Column: ColumnRef>(
        _ block: (T) -> (repeat each Column),
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [(repeat (each Column).ValueType)] {
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
        return try database.query(
            select.statement(),
            columns: repeat each columnRefs,
            binder: select.binder
        )
    }

    /// Executes a select query for all columns.
    /// - Parameters:
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    @DatabaseActor
    public func select(
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [T.TableType] {
        let select = SelectBuilder(
            from: tableRef._sqlFrom,
            columns: tableRef._readColumnSqlRefs,
            condition: condition,
            limit: limit,
            offset: offset
        )
        let database = database
        return try database.query(select.statement(), binder: select.binder) { stmt, index, _ in
            try T.TableType.read(from: stmt, startingAt: &index)
        }
    }

    /// Executes a select query for all columns and returns the first entry (if exists).
    /// - Returns: First entry of the query or nil.
    /// - Parameter block: Columns builder block.
    @DatabaseActor
    public func selectFirst<each Column: ColumnRef>(
        _ block: (T) -> (repeat each Column)
    ) throws -> (repeat (each Column).ValueType)? {
        try select(block, limit: 1).first
    }

    /// Executes a select query for all columns and returns the first entry (if exists).
    /// - Returns: First entry of the query or nil.
    @DatabaseActor
    public func selectFirst() throws -> T.TableType? {
        try select(limit: 1).first
    }

    /// Executes an update statement.
    /// - Parameters:
    ///   - columns: Columns to update.
    ///   - values: New values for the columns.
    @DatabaseActor
    public func update<each Column: ColumnRef>(
        columns: repeat KeyPath<T, each Column>,
        values: repeat (each Column).ValueType
    ) throws {
        var setters = [ColumnValueSetter]()
        repeat setters.append(
            ColumnValueSetter(
                columnName: tableRef[keyPath: each columns]._sqlName,
                valueBinder: (each values).managedBinder
            )
        )

        let stmt = UpdateBuilder(
            from: tableRef._sqlFrom,
            setters: setters,
            condition: condition
        )
        let database = database
        return try database.exec(stmt.statement(), binder: stmt.binder)
    }

    /// Executes a delete statement.
    @DatabaseActor
    public func delete() throws {
        let stmt = DeleteBuilder(
            from: tableRef._sqlFrom,
            condition: condition
        )
        let database = database
        return try database.exec(stmt.statement(), binder: stmt.binder)
    }

    /// Executes a count statement.
    /// - Parameters:
    ///   - distinct: Count only distinct rows. Default is `false`.
    ///   - block: Column builder block.
    /// - Returns: The count of the column vaues.
    @DatabaseActor
    public func count(
        distinct: Bool = false,
        _ block: (T) -> any ColumnRef
    ) throws -> Int64 {
        let stmt = CountBuilder(
            from: tableRef._sqlFrom,
            column: block(tableRef),
            condition: condition,
            distinct: distinct
        )
        let database = database
        return try database.query(stmt.statement(), binder: stmt.binder) { stmt, index, _ in
            try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Executes a count statement
    /// - Returns: The count of the rows.
    @DatabaseActor
    public func count() throws -> Int64 {
        let stmt = CountBuilder(
            from: tableRef._sqlFrom,
            condition: condition
        )
        let database = database
        return try database.query(stmt.statement(), binder: stmt.binder) { stmt, index, _ in
            try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Adds a condition to the select query.
    ///
    /// The condition is combined with the existing condition using the logical AND operator.
    ///
    /// - Parameter block: Condition builder block.
    /// - Returns: Select source with the added condition.
    public func `where`(_ block: (T) throws -> Condition) rethrows -> SelectSource<T> {
        try SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition.map { try $0 && block(tableRef) } ?? block(tableRef)
        )
    }
}

extension Database {
    /// Initializes a new select source.
    /// - Parameter table: Table type.
    /// - Returns: Select source.
    public nonisolated func from<T: Table, R: TableRef>(_ table: T.Type) -> SelectSource<R> where T.TableRefType == R {
        SelectSource(database: self, tableRef: table.table, condition: nil)
    }

    /// Initializes a new select source.
    /// - Parameter tableRef: Table reference.
    /// - Returns: Select source.
    public nonisolated func from<R: TableRef>(_ tableRef: R) -> SelectSource<R> {
        SelectSource(database: self, tableRef: tableRef, condition: nil)
    }
}
