//
//  SQLEquatable.swift
//

import Foundation

/// This protocol is used to define the types that can be compared for equality in the database.
///
/// This is not the same as the `Equatable` protocol from the standard library.
/// The `Equatable` protocol from the standard library is used to compare the values of two instances of a type.
/// This protocol is used to compare values in an SQL query.
///
/// For example primitive types like `Int`, `String`, `Date`, etc. conform to this protocol.
/// However more complex types like `Array`, `Dictionary`, `Codable` etc. do not conform to this protocol.
public protocol SQLEquatable {
    associatedtype StoredType
}

// MARK: - Equatable and Comparable conformances

extension Bool: SQLEquatable {
    public typealias StoredType = Int
}

extension Int: SQLEquatable {
    public typealias StoredType = Int
}

extension Int32: SQLEquatable {
    public typealias StoredType = Int32
}

extension Int64: SQLEquatable {
    public typealias StoredType = Int64
}

extension Float: SQLEquatable {
    public typealias StoredType = Float
}

extension Double: SQLEquatable {
    public typealias StoredType = Double
}

extension String: SQLEquatable {
    public typealias StoredType = String
}

extension UUID: SQLEquatable {
    public typealias StoredType = UUID
}

extension Data: SQLEquatable {
    public typealias StoredType = Data
}

extension Date: SQLEquatable {
    public typealias StoredType = Date
}

extension Optional: SQLEquatable where Wrapped: SQLEquatable {
    public typealias StoredType = Wrapped
}
