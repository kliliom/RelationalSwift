//
//  SQLComparable.swift
//

import Foundation

/// This protocol is used to define the types that can be compared for ordering in the database.
///
/// This is not the same as the `Comparable` protocol from the standard library.
/// The `Comparable` protocol from the standard library is used to compare the values of two instances of a type.
/// This protocol is used to compare values in an SQL query.
///
/// For example primitive types like `Int`, `String`, `Date`, etc. conform to this protocol.
/// However more complex types like `Array`, `Dictionary`, `Codable` etc. do not conform to this protocol.
public protocol SQLComparable: SQLEquatable {
    associatedtype StoredType
}

// MARK: - Equatable and Comparable conformances

extension Int: SQLComparable {}

extension Int32: SQLComparable {}

extension Int64: SQLComparable {}

extension Float: SQLComparable {}

extension Double: SQLComparable {}

extension String: SQLComparable {}

extension Date: SQLComparable {}

extension Optional: SQLComparable where Wrapped: SQLComparable {
    public typealias StoredType = Wrapped
}
