//
//  SelectBuilder.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A builder for a select query.
struct SelectBuilder {
    /// Source table.
    let from: String

    /// Columns to select.
    let columns: [String]

    /// Columns binders.
    let columnBinders: [Binder]

    /// Condition.
    let condition: Condition?

    /// Row limit.
    let limit: Int?

    /// Row offset.
    let offset: Int?

    /// Initializes a new select query builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - columns: Columns to select.
    ///   - condition: Condition.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    init(from: String, columns: [String], condition: Condition?, limit: Int?, offset: Int?) {
        self.from = from
        self.columns = columns
        columnBinders = []
        self.condition = condition
        self.limit = limit
        self.offset = offset
    }

    /// Initializes a new select query builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - columns: Columns to select.
    ///   - condition: Condition.
    ///   - limit: Row limit.
    ///   - offset: Row offset.
    init(from: String, columns: [any ColumnRef], condition: Condition?, limit: Int?, offset: Int?) {
        self.from = from
        self.columns = columns.map(\._sqlRef)
        columnBinders = columns.compactMap(\.binder)
        self.condition = condition
        self.limit = limit
        self.offset = offset
    }

    /// Binder for the select query.
    var binder: Binder {
        var binder: Binder = { _, _ in }
        for columnBinder in columnBinders {
            let currentBinder = binder
            binder = { stmt, index in
                try currentBinder(stmt, &index)
                try columnBinder(stmt, &index)
            }
        }
        if let condition {
            let currentBinder = binder
            binder = { stmt, index in
                try currentBinder(stmt, &index)
                try condition.binder(stmt, &index)
            }
        }
        if let limit {
            let currentBinder = binder
            binder = { stmt, index in
                try currentBinder(stmt, &index)
                try Int.bind(to: stmt, value: limit, at: &index)
            }
        }
        if let offset {
            let currentBinder = binder
            binder = { stmt, index in
                try currentBinder(stmt, &index)
                try Int.bind(to: stmt, value: offset, at: &index)
            }
        }
        return binder
    }

    /// SQL statement for the select query.
    /// - Returns: SQL statement.
    func statement() throws -> String {
        guard !columns.isEmpty else {
            throw DB4SwiftError(message: "no columns to select")
        }
        var statement = ["SELECT", columns.joined(separator: ", "), "FROM", from]
        if let condition {
            statement.append("WHERE")
            statement.append(condition.sql)
        }
        if limit != nil {
            statement.append("LIMIT ?")
        }
        if offset != nil {
            if limit == nil {
                statement.append("LIMIT -1 OFFSET ?")
            } else {
                statement.append("OFFSET ?")
            }
        }
        return statement.joined(separator: " ")
    }
}
