//
//  UpdateBuilder.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A builder for an update statement.
struct UpdateBuilder {
    /// Source table.
    let from: String

    /// Column value setters.
    let setters: [ColumnValueSetter]

    /// Condition.
    let condition: Condition?

    /// Initializes a new delete statement builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - setters: Column value setters.
    ///   - condition: Condition.
    init(from: String, setters: [ColumnValueSetter], condition: Condition?) {
        self.from = from
        self.setters = setters
        self.condition = condition
    }

    /// Binder for the select query.
    var binder: Binder {
        var binder: Binder = { _, _ in }
        for setter in setters {
            let currentBinder = binder
            binder = { stmt, index in
                try currentBinder(stmt, &index)
                try setter.valueBinder(stmt, &index)
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

    /// SQL statement for the delete statement.
    /// - Returns: SQL statement.
    func statement() throws -> String {
        var statement = ["UPDATE", from]
        statement.append("SET")
        for (offset, setter) in setters.enumerated() {
            if offset > 0 {
                statement.append(",")
            }
            statement.append(setter.columnName)
            statement.append("= ?")
        }
        if let condition {
            statement.append("WHERE")
            statement.append(condition.sql)
        }
        return statement.joined(separator: " ")
    }
}
