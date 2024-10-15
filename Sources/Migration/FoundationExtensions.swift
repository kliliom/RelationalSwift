//
//  FoundationExtensions.swift
//  Created by Kristof Liliom in 2024.
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

    var anyWrappedValue: WrappedType? { get }
}

extension Optional: OptionalProtocol {
    typealias WrappedType = Wrapped

    static var wrappedType: Wrapped.Type {
        Wrapped.self
    }

    var anyWrappedValue: Wrapped? {
        self
    }
}

extension RawRepresentable {
    /// The raw value type.
    static var rawValueType: any Any.Type {
        RawValue.self
    }
}

extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension UUID {
    func hexEncodedString() -> String {
        uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
