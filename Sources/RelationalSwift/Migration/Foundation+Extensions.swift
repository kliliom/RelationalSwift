//
//  Foundation+Extensions.swift
//

import Foundation

extension String {
    /// Returns the string escaped and wrapped in quotes.
    var asSQLIdentifier: String {
        "\"\(replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

extension [String] {
    /// Appends the elements to the builder.
    /// - Parameter builder: SQL builder to append to.
    func appendAsSQLIdentifierList(to builder: SQLBuilder) {
        builder.sql.append("(")
        for (index, column) in enumerated() {
            if index > 0 {
                builder.sql.append(",")
            }
            builder.sql.append(column.asSQLIdentifier)
        }
        builder.sql.append(")")
    }
}

/// A type-erased value.
protocol OptionalProtocol<WrappedType> {
    associatedtype WrappedType

    /// The wrapped type.
    static var wrappedType: WrappedType.Type { get }
}

extension Optional: OptionalProtocol {
    typealias WrappedType = Wrapped

    static var wrappedType: Wrapped.Type {
        Wrapped.self
    }
}

extension RawRepresentable {
    /// The raw value type.
    static var rawValueType: any Any.Type {
        RawValue.self
    }
}
