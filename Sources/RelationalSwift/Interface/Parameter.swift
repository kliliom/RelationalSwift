//
//  Parameter.swift
//

public struct Parameter<T: Bindable>: Bindable {
    final class Holder: Sendable {
        @DatabaseActor var value: T

        init(value: T) {
            self.value = value
        }
    }

    let holder: Holder

    public init(_ value: T) {
        self.holder = Holder(value: value)
    }

    @DatabaseActor public func value() -> T {
        holder.value
    }

    @DatabaseActor public func update(_ value: T) {
        holder.value = value
    }

    public static func bind(to stmt: borrowing StatementHandle, value: Parameter<T>, at index: Int32) throws {
        try T.bind(to: stmt, value: value.holder.value, at: index)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        throw RelationalSwiftError.unsupportedOperation
    }

    public static var detaultSQLStorageType: String {
        T.detaultSQLStorageType
    }

    public func asSQLLiteral() throws -> String {
        throw RelationalSwiftError.unsupportedOperation
    }
}
