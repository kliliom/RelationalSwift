//
//  SQLQuery.swift
//

public struct SQLQuery<T>: Sendable {
    public let statement: SQLStatement
    public let stepper: Database.ManagedStepper<T>

    public init(statement: SQLStatement, stepper: @escaping Database.ManagedStepper<T>) {
        self.statement = statement
        self.stepper = stepper
    }
}

public func query<T>(_ statement: SQLStatement, stepper: @escaping Database.ManagedStepper<T>) -> SQLQuery<T> {
    SQLQuery(statement: statement, stepper: stepper)
}

extension SQLStatement {
    public func query<T>(stepper: @escaping Database.ManagedStepper<T>) -> SQLQuery<T> {
        SQLQuery(statement: self, stepper: stepper)
    }
}

extension Database {
    @DatabaseActor
    public func run<T>(_ sqlQuery: SQLQuery<T>) throws -> [T] {
        try query(sqlQuery.statement.sql, binder: { stmt, index in
            for binder in sqlQuery.statement.binders {
                try binder(stmt, &index)
            }
        }, stepper: sqlQuery.stepper)
    }
}
