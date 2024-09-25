//
//  CountBuilder.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A builder for a count statement.
struct CountBuilder {
    /// Source table.
    let from: String

    /// Column to count.
    let column: String

    /// Columns binders.
    let columnBinders: [Binder]

    /// Condition.
    let condition: Condition?

    /// Distinct flag.
    let distinct: Bool

    /// Initializes a new count statement builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - column: Column to count or nil to count row.
    ///   - condition: Condition.
    ///   - distinct: Distinct flag.
    init(from: String, condition: Condition?) {
        self.from = from
        column = "*"
        columnBinders = []
        self.condition = condition
        distinct = false
    }

    /// Initializes a new count statement builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - column: Column to count or nil to count row.
    ///   - condition: Condition.
    ///   - distinct: Distinct flag.
    init(from: String, column: String, condition: Condition?, distinct: Bool) {
        self.from = from
        self.column = column
        columnBinders = []
        self.condition = condition
        self.distinct = distinct
    }

    /// Initializes a new count statement builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - column: Column to count or nil to count row.
    ///   - condition: Condition.
    ///   - distinct: Distinct flag.
    init(from: String, column: any ColumnRef, condition: Condition?, distinct: Bool) {
        self.from = from
        self.column = column._sqlRef
        if let binder = column.binder {
            columnBinders = [binder]
        } else {
            columnBinders = []
        }
        self.condition = condition
        self.distinct = distinct
    }

    /// Binder for the count statement.
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
        return binder
    }

    /// SQL statement for the count statement.
    /// - Returns: SQL statement.
    func statement() throws -> String {
        var statement = ["SELECT"]
        if distinct {
            statement.append("COUNT(DISTINCT \(column))")
        } else {
            statement.append("COUNT(\(column))")
        }
        statement.append(contentsOf: ["FROM", from])
        if let condition {
            statement.append("WHERE")
            statement.append(condition.sql)
        }
        return statement.joined(separator: " ")
    }
}
