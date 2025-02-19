//
//  SQLStatement.swift
//

import Foundation

public struct SQLStatement: Sendable {
    public let sql: String
    public let binders: [Database.ManagedBinder]

    public init(sql: String, binders: [Database.ManagedBinder]) {
        self.sql = sql
        self.binders = binders
    }
}

public func statement(_ statement: SQLStatement) -> SQLStatement {
    statement
}

extension SQLStatement: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral value: StringLiteralType) {
        self.sql = value
        self.binders = []
    }
}

extension SQLStatement: ExpressibleByStringInterpolation {
    public typealias StringInterpolation = SQLBuilder

    public init(stringInterpolation: SQLBuilder) {
        sql = stringInterpolation.sql.joined(separator: " ")
        binders = stringInterpolation.binders
    }
}

extension Database {
    @DatabaseActor
    public func run(_ sqlStmt: SQLStatement) throws {
        try exec(sqlStmt.sql) { stmt, index in
            for binder in sqlStmt.binders {
                try binder(stmt, &index)
            }
        }
    }
}
