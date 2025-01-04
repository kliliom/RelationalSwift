//
//  Conditions.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A condition that can be used in a query.
public struct Condition: Sendable {
    /// SQL string representation of the condition.
    public let sql: String

    /// Binder that binds the condition values to the statement.
    public let binder: Database.ManagedBinder

    /// Initializes a new condition.
    /// - Parameters:
    ///   - sql: SQL string representation of the condition.
    ///   - binder: Binder that binds the condition values to the statement.
    init(sql: String, binder: @escaping Database.ManagedBinder) {
        self.sql = sql
        self.binder = binder
    }

    /// True condition.
    public static let `true` = Condition(sql: "TRUE", binder: { _, _ in })

    /// False condition.
    public static let `false` = Condition(sql: "FALSE", binder: { _, _ in })
}

// MARK: - Equatable and Compatable protocols for database

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

/// This protocol is used to define the types that can be compared for ordering in the database.
///
/// This is not the same as the `Comparable` protocol from the standard library.
/// The `Comparable` protocol from the standard library is used to compare the values of two instances of a type.
/// This protocol is used to compare values in an SQL query.
///
/// For example primitive types like `Int`, `String`, `Date`, etc. conform to this protocol.
/// However more complex types like `Array`, `Dictionary`, `Codable` etc. do not conform to this protocol.
public protocol SQLComparable {
    associatedtype StoredType
}

// MARK: - Equatable and Comparable conformances

extension Int: SQLEquatable, SQLComparable {
    public typealias StoredType = Int
}

extension Int32: SQLEquatable, SQLComparable {
    public typealias StoredType = Int32
}

extension Int64: SQLEquatable, SQLComparable {
    public typealias StoredType = Int64
}

extension Float: SQLEquatable, SQLComparable {
    public typealias StoredType = Float
}

extension Double: SQLEquatable, SQLComparable {
    public typealias StoredType = Double
}

extension String: SQLEquatable, SQLComparable {
    public typealias StoredType = String
}

extension UUID: SQLEquatable {
    public typealias StoredType = UUID
}

extension Data: SQLEquatable {
    public typealias StoredType = Data
}

extension Date: SQLEquatable, SQLComparable {
    public typealias StoredType = Date
}

extension Optional: SQLEquatable where Wrapped: SQLEquatable {
    public typealias StoredType = Wrapped
}

extension Optional: SQLComparable where Wrapped: SQLComparable {
    public typealias StoredType = Wrapped
}

// MARK: - Equatable Conditions

/// Creates a condition which compares a column to a value for equality.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that compares the column to the value for equality.
public func == <A: SQLEquatable, B: Bindable & SQLEquatable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) == ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which compares a value to a column for equality.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that compares the value to the column for equality.
public func == <A: Bindable & SQLEquatable, B: SQLEquatable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? == \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which compares two columns for equality.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that compares the two columns for equality.
public func == <A: SQLEquatable, B: SQLEquatable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) == \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which compares a column to a value for inequality.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that compares the column to the value for inequality.
public func != <A: SQLEquatable, B: Bindable & SQLEquatable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) != ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which compares a value to a column for inequality.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that compares the value to the column for inequality.
public func != <A: Bindable & SQLEquatable, B: SQLEquatable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? != \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which compares two columns for inequality.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that compares the two columns for inequality.
public func != <A: SQLEquatable, B: SQLEquatable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) != \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

// MARK: - Comparable Conditions

/// Creates a condition which checks if a column is less than a value.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that checks if the column is less than the value.
public func < <A: SQLComparable, B: Bindable & SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) < ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which checks if a value is less than a column.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that checks if the value is less than the column.
public func < <A: Bindable & SQLComparable, B: SQLComparable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? < \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if the first column is less than the second column.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that checks if the first column is less than the second column.
public func < <A: SQLComparable, B: SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) < \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if a column is less than or equal to a value.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that checks if the column is less than or equal to the value.
public func <= <A: SQLComparable, B: Bindable & SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) <= ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which checks if a value is less than or equal to a column.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that checks if the value is less than or equal to the column.
public func <= <A: Bindable & SQLComparable, B: SQLComparable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? <= \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if the first column is less than or equal to the second column.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that checks if the first column is less than or equal to the second column.
public func <= <A: SQLComparable, B: SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) <= \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if a column is greater than a value.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that checks if the column is greater than the value.
public func > <A: SQLComparable, B: Bindable & SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) > ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which checks if a value is greater than a column.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that checks if the value is greater than the column.
public func > <A: Bindable & SQLComparable, B: SQLComparable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? > \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if the first column is greater than the second column.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that checks if the first column is greater than the second column.
public func > <A: SQLComparable, B: SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) > \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if a column is greater than or equal to a value.
/// - Parameters:
///   - lhs: Column reference.
///   - rhs: Value to compare to.
/// - Returns: Condition that checks if the column is greater than or equal to the value.
public func >= <A: SQLComparable, B: Bindable & SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) >= ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

/// Creates a condition which checks if a value is greater than or equal to a column.
/// - Parameters:
///   - lhs: Value to compare to.
///   - rhs: Column reference.
/// - Returns: Condition that checks if the value is greater than or equal to the column.
public func >= <A: Bindable & SQLComparable, B: SQLComparable>(
    lhs: A,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(? >= \(rhs._sqlRef))") { stmt, index in
        try A.bind(to: stmt, value: lhs, at: &index)
        try rhs.binder?(stmt, &index)
    }
}

/// Creates a condition which checks if the first column is greater than or equal to the second column.
/// - Parameters:
///   - lhs: First column reference.
///   - rhs: Second column reference.
/// - Returns: Condition that checks if the first column is greater than or equal to the second column.
public func >= <A: SQLComparable, B: SQLComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) >= \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

// MARK: - Boolean Operators

/// Creates a condition is a logical AND of two conditions.
/// - Parameters:
///   - lhs: First condition.
///   - rhs: Second condition.
/// - Returns: Condition that is a logical AND of the two conditions.
public func && (lhs: Condition, rhs: Condition) -> Condition {
    Condition(sql: "(\(lhs.sql) AND \(rhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
        try rhs.binder(stmt, &index)
    }
}

/// Creates a condition is a logical OR of two conditions.
/// - Parameters:
///   - lhs: First condition.
///   - rhs: Second condition.
/// - Returns: Condition that is a logical OR of the two conditions.
public func || (lhs: Condition, rhs: Condition) -> Condition {
    Condition(sql: "(\(lhs.sql) OR \(rhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
        try rhs.binder(stmt, &index)
    }
}

/// Creates a condition that is the logical NOT of another condition.
/// - Parameter lhs: Condition.
/// - Returns: Condition that is the logical NOT of another condition.
public prefix func ! (lhs: Condition) -> Condition {
    Condition(sql: "(NOT \(lhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
    }
}

// MARK: - Null support

extension ColumnRef {
    /// Creates a condition that checks if the column is null.
    /// - Returns: Condition that checks if the column is null.
    public func isNull<U: Bindable>() -> Condition where ValueType == U? {
        Condition(sql: "(\(_sqlRef) IS NULL)") { _, _ in }
    }

    /// Creates a condition that checks if the column is not null.
    /// - Returns: Condition that checks if the column is not null.
    public func isNotNull<U: Bindable>() -> Condition where ValueType == U? {
        Condition(sql: "(\(_sqlRef) IS NOT NULL)") { _, _ in }
    }
}

// MARK: - In support

extension ColumnRef where ValueType: SQLEquatable {
    /// Creates a condition that checks if the column is in a list of values.
    /// - Parameter values: List of values to check against.
    /// - Returns: Condition that checks if the column is in the list of values.
    public func `in`(_ values: ValueType...) -> Condition {
        Condition(sql: "(\(_sqlRef) IN (\(values.map { _ in "?" }.joined(separator: ","))))") { stmt, index in
            for value in values {
                try ValueType.bind(to: stmt, value: value, at: &index)
            }
        }
    }

    /// Creates a condition that checks if the column is in a subquery.
    /// - Parameter query: Subquery to check against.
    /// - Returns: Condition that checks if the column is in the subquery.
    public func `in`(_ query: (String, Database.ManagedBinder, ValueType.Type)) -> Condition {
        Condition(sql: "(\(_sqlRef) IN (\(query.0)))") { stmt, index in
            try query.1(stmt, &index)
        }
    }
}
