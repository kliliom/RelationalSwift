//
//  SingleValueQuery.swift
//  Created by Kristof Liliom in 2025.
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
        statement = builder.statement()
        binder = builder.binder()
    }
}
