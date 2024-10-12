//
//  FoundationExtensions.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

extension String {
    /// Returns the string wrapped in quotes.
    var quoted: String {
        "\"\(self)\""
    }
}

extension [String] {
    /// Appends the elements to the builder.
    /// - Parameters:
    ///   - builder: SQL builder to append to.
    ///   - quoted: Whether to quote the elements.
    ///   - parentheses: Whether to wrap the elements in parentheses.
    func append(to builder: SQLBuilder, quoted: Bool, parentheses: Bool) {
        if parentheses {
            builder.sql.append("(")
        }
        for (index, column) in enumerated() {
            if index > 0 {
                builder.sql.append(",")
            }
            if quoted {
                builder.sql.append(column.quoted)
            } else {
                builder.sql.append(column)
            }
        }
        if parentheses {
            builder.sql.append(")")
        }
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
