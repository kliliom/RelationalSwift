//
//  SingleValueQuery.swift
//

public struct SingleValueQuery<Value>: Sendable {
    public typealias ExpressionValue = Value

    public var statement: String
    public var binder: Database.ManagedBinder

    public init(statement: String, binder: @escaping Database.ManagedBinder) {
        self.statement = statement
        self.binder = binder
    }

    public init(from builder: SQLBuilder) {
        let binders = builder.binders
        statement = builder.sql.joined(separator: " ")
        binder = { stmt, index in
            for binder in binders {
                try binder(stmt, &index)
            }
        }
    }
}
