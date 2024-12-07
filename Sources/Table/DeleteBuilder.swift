//
//  DeleteBuilder.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A builder for a delete statement.
struct DeleteBuilder {
    /// Source table.
    let from: String

    /// Condition.
    let condition: Condition?

    /// Initializes a new delete statement builder.
    /// - Parameters:
    ///   - from: Source table.
    ///   - condition: Condition.
    init(from: String, condition: Condition?) {
        self.from = from
        self.condition = condition
    }

    /// Binder for the select query.
    var binder: Database.ManagedBinder {
        var binder: Database.ManagedBinder = { _, _ in }
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
        var statement = ["DELETE", "FROM", from]
        if let condition {
            statement.append("WHERE")
            statement.append(condition.sql)
        }
        return statement.joined(separator: " ")
    }
}
