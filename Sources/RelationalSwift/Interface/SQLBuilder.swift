//
//  SQLBuilder.swift
//

public struct SQLBuilder: StringInterpolationProtocol {
    public typealias StringLiteralType = String

    public var sql: [String] = []

    public var binders: [Database.ManagedBinder] = []

    public init(literalCapacity: Int, interpolationCount: Int) {
        sql.reserveCapacity(interpolationCount + 1)
        binders.reserveCapacity(interpolationCount)
    }

    public init() {}

    public mutating func appendLiteral(_ literal: StringLiteralType) {
        sql.append(literal)
    }

    public mutating func appendInterpolation(_ value: some Expression) {
        value.append(to: &self)
    }

    public mutating func appendInterpolation(_ value: some TableRef) {
        sql.append(value._sqlFrom)
    }
}

extension SQLBuilder {
    func statement() -> String {
        sql.joined(separator: " ")
    }

    func binder() -> Database.ManagedBinder {
        { [binders] handle, index in
            for binder in binders {
                try binder(handle, &index)
            }
        }
    }

    public func makeStatement() -> SQLStatement {
        SQLStatement(stringInterpolation: self)
    }
}

public protocol SQLBuilderAppendable {
    func append(to interpolation: inout SQLBuilder)
}
