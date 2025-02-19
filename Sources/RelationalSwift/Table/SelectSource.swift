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
    let condition: ExprCastExpression<Bool?>?

    /// Group by terms.
    let groupBy: [any Expression]

    /// Having term.
    let having: (any Expression)?

    /// Ordering terms.
    let orderingTerms: [OrderingTerm]

    /// Creates a select query for selected columns.
    /// - Parameters:
    ///   - block: Columns builder block.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    public func query<Column: Expression>(
        _ block: (T) -> (Column),
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> SingleValueQuery<Column.ExpressionValue> where Column.ExpressionValue: Bindable {
        let builder = SQLBuilder()
        buildSelect(
            into: builder,
            from: tableRef._sqlFrom,
            columns: [block(tableRef)],
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderBy: orderingTerms,
            limit: limit,
            offset: offset
        )

        return SingleValueQuery(from: builder)
    }

    /// Executes a select query for selected columns.
    /// - Parameters:
    ///   - block: Columns builder block.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    /// - Returns: Result of the query.
    @DatabaseActor
    public func select<each Column: Expression>(
        _ block: (T) -> (repeat each Column),
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [(repeat (each Column).ExpressionValue)] where repeat (each Column).ExpressionValue: Bindable {
        let columnRefs = block(tableRef)
        var columnSqlRefs: [any Expression] = []
        repeat (columnSqlRefs.append(each columnRefs))

        let builder = SQLBuilder()
        buildSelect(
            into: builder,
            from: tableRef._sqlFrom,
            columns: columnSqlRefs,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderBy: orderingTerms,
            limit: limit,
            offset: offset
        )

        let database = database
        return try database.query(
            builder.statement(),
            columns: repeat each columnRefs,
            binder: builder.binder()
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
        let builder = SQLBuilder()
        buildSelect(
            into: builder,
            from: tableRef._sqlFrom,
            columns: tableRef._allColumnRefs,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderBy: orderingTerms,
            limit: limit,
            offset: offset
        )

        let database = database
        return try builder.query(in: database) { stmt, index, _ in
            try T.TableType.read(from: stmt, startingAt: &index)
        }
    }

    /// Executes a select query for all columns and returns the first entry (if exists).
    /// - Returns: First entry of the query or nil.
    /// - Parameter block: Columns builder block.
    @DatabaseActor
    public func selectFirst<each Column: Expression>(
        _ block: (T) -> (repeat each Column)
    ) throws -> (repeat (each Column).ExpressionValue)? where repeat (each Column).ExpressionValue: Bindable {
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
        values: repeat (each Column).ExpressionValue
    ) throws where repeat (each Column).ExpressionValue: Bindable {
        var setters = [ColumnValueSetter]()
        repeat setters.append(
            ColumnValueSetter(
                columnName: tableRef[keyPath: each columns]._sqlName,
                valueBinder: (each values).managedBinder
            )
        )

        let builder = SQLBuilder()
        buildUpdate(
            into: builder,
            in: tableRef._sqlFrom,
            setters: setters,
            condition: condition
        )

        let database = database
        return try database.exec(builder.statement(), binder: builder.binder())
    }

    /// Executes a delete statement.
    @DatabaseActor
    public func delete() throws {
        let builder = SQLBuilder()
        buildDelete(
            into: builder,
            from: tableRef._sqlFrom,
            condition: condition
        )

        let database = database
        return try database.exec(builder.statement(), binder: builder.binder())
    }

    /// Executes a count statement.
    /// - Parameters:
    ///   - distinct: Count only distinct rows. Default is `false`.
    ///   - block: Expression builder block.
    /// - Returns: The count of the column vaues.
    @DatabaseActor
    public func count(
        distinct: Bool = false,
        _ block: (T) -> any Expression
    ) throws -> Int64 {
        let builder = SQLBuilder()
        buildSelect(
            into: builder,
            from: tableRef._sqlFrom,
            columns: [
                block(tableRef).count(distinct: distinct),
            ],
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderBy: orderingTerms
        )

        let database = database
        return try builder.query(in: database) { stmt, index, _ in
            try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Executes a count statement
    /// - Returns: The count of the rows.
    @DatabaseActor
    public func count() throws -> Int64 {
        let builder = SQLBuilder()
        buildSelect(
            into: builder,
            from: tableRef._sqlFrom,
            columns: [
                sqlAllColumns.count(),
            ],
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderBy: orderingTerms
        )

        let database = database
        return try builder.query(in: database) { stmt, index, _ in
            try Int64.column(of: stmt, at: &index)
        }.first ?? 0
    }

    /// Adds a condition to the select query.
    ///
    /// The condition is combined with the existing condition using the logical AND operator.
    ///
    /// - Parameter block: Condition builder block.
    /// - Returns: Select source with the added condition.
    public func `where`<E: Expression>(
        _ block: (T) throws -> E
    ) rethrows -> SelectSource<T> where E.ExpressionValue == Bool {
        try `where` { try block($0).unsafeExprCast(to: Bool?.self) }
    }

    /// Adds a condition to the select query.
    ///
    /// The condition is combined with the existing condition using the logical AND operator.
    ///
    /// - Parameter block: Condition builder block.
    /// - Returns: Select source with the added condition.
    public func `where`<E: Expression>(
        _ block: (T) throws -> E
    ) rethrows -> SelectSource<T> where E.ExpressionValue == Bool? {
        let condition = if let condition {
            try (condition && block(tableRef)).unsafeExprCast(to: Bool?.self)
        } else {
            try block(tableRef).unsafeExprCast(to: Bool?.self)
        }

        return SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderingTerms: orderingTerms
        )
    }

    /// Adds an ordering term to the select query.
    /// - Parameter block: Ordering term builder block.
    /// - Returns: Select source with the added ordering term.
    public func orderBy(_ block: (T) throws -> OrderingTerm) rethrows -> SelectSource<T> {
        try SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderingTerms: orderingTerms + [block(tableRef)]
        )
    }

    /// Adds an ascending ordering term to the select query.
    /// - Parameters:
    ///   - keyPath: Key path to order by.
    ///   - nullPosition: Null position.
    /// - Returns: Select source with the added ordering term.
    public func orderBy(
        asc keyPath: KeyPath<T, some Expression>,
        nullPosition: OrderingTerm.NullPosition? = nil
    ) -> SelectSource<T> {
        SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderingTerms: orderingTerms + [.asc(tableRef[keyPath: keyPath], nullPosition: nullPosition)]
        )
    }

    /// Adds a descending ordering term to the select query.
    /// - Parameters:
    ///   - keyPath: Key path to order by.
    ///   - nullPosition: Null position.
    /// - Returns: Select source with the added ordering term.
    public func orderBy(
        desc keyPath: KeyPath<T, some Expression>,
        nullPosition: OrderingTerm.NullPosition? = nil
    ) -> SelectSource<T> {
        SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having,
            orderingTerms: orderingTerms + [.desc(tableRef[keyPath: keyPath], nullPosition: nullPosition)]
        )
    }

    /// Adds a group by term to the select query.
    /// - Parameter block: Group by term builder block.
    /// - Returns: Select source with the added group by term.
    public func groupBy(_ block: (T) -> any Expression) -> SelectSource<T> {
        SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy + [block(tableRef)],
            having: having,
            orderingTerms: orderingTerms
        )
    }

    /// Adds a having term to the select query.
    /// - Parameter block: Having term builder block.
    /// - Returns: Select source with the added having term.
    public func having<E: Expression>(_ block: (T) -> E) -> SelectSource<T> where E.ExpressionValue == Bool {
        SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having.map { $0 && block(tableRef) } ?? block(tableRef),
            orderingTerms: orderingTerms
        )
    }

    /// Adds a having term to the select query.
    /// - Parameter block: Having term builder block.
    /// - Returns: Select source with the added having term.
    public func having<E: Expression>(_ block: (T) -> E) -> SelectSource<T> where E.ExpressionValue == Bool? {
        SelectSource(
            database: database,
            tableRef: tableRef,
            condition: condition,
            groupBy: groupBy,
            having: having.map { $0 && block(tableRef) } ?? block(tableRef),
            orderingTerms: orderingTerms
        )
    }
}

extension Database {
    /// Initializes a new select source.
    /// - Parameter table: Table type.
    /// - Returns: Select source.
    public nonisolated func from<T: Table, R: TableRef>(_ table: T.Type) -> SelectSource<R> where T.TableRefType == R {
        SelectSource(database: self, tableRef: table.table, condition: nil, groupBy: [], having: nil, orderingTerms: [])
    }

    /// Initializes a new select source.
    /// - Parameter tableRef: Table reference.
    /// - Returns: Select source.
    public nonisolated func from<R: TableRef>(_ tableRef: R) -> SelectSource<R> {
        SelectSource(database: self, tableRef: tableRef, condition: nil, groupBy: [], having: nil, orderingTerms: [])
    }
}
