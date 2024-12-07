//
//  Conditions.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

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

public protocol DBEquatable {
    associatedtype StoredType
}

public protocol DBComparable {
    associatedtype StoredType
}

// MARK: - Equatable and Comparable conformances

extension Int: DBEquatable, DBComparable {
    public typealias StoredType = Int
}

extension Int32: DBEquatable, DBComparable {
    public typealias StoredType = Int32
}

extension Int64: DBEquatable, DBComparable {
    public typealias StoredType = Int64
}

extension Float: DBEquatable, DBComparable {
    public typealias StoredType = Float
}

extension Double: DBEquatable, DBComparable {
    public typealias StoredType = Double
}

extension String: DBEquatable, DBComparable {
    public typealias StoredType = String
}

extension UUID: DBEquatable {
    public typealias StoredType = UUID
}

extension Data: DBEquatable {
    public typealias StoredType = Data
}

extension Date: DBEquatable, DBComparable {
    public typealias StoredType = Date
}

extension Optional: DBEquatable where Wrapped: DBEquatable {
    public typealias StoredType = Wrapped
}

extension Optional: DBComparable where Wrapped: DBComparable {
    public typealias StoredType = Wrapped
}

// MARK: - Equatable Conditions

public func == <A: DBEquatable, B: Bindable & DBEquatable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) == ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func == <A: DBEquatable, B: DBEquatable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) == \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

public func != <A: DBEquatable, B: Bindable & DBEquatable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) != ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func != <A: DBEquatable, B: DBEquatable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) != \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

// MARK: - Comparable Conditions

public func < <A: DBComparable, B: Bindable & DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) < ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func < <A: DBComparable, B: DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) < \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

public func <= <A: DBComparable, B: Bindable & DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) <= ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func <= <A: DBComparable, B: DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) <= \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

public func > <A: DBComparable, B: Bindable & DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) > ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func > <A: DBComparable, B: DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) > \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

public func >= <A: DBComparable, B: Bindable & DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: B
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) >= ?)") { stmt, index in
        try lhs.binder?(stmt, &index)
        try B.bind(to: stmt, value: rhs, at: &index)
    }
}

public func >= <A: DBComparable, B: DBComparable>(
    lhs: some ColumnRef<A>,
    rhs: some ColumnRef<B>
) -> Condition where A.StoredType == B.StoredType {
    Condition(sql: "(\(lhs._sqlRef) >= \(rhs._sqlRef))") { stmt, index in
        try lhs.binder?(stmt, &index)
        try rhs.binder?(stmt, &index)
    }
}

// MARK: - Boolean Operators

public func && (lhs: Condition, rhs: Condition) -> Condition {
    Condition(sql: "(\(lhs.sql) AND \(rhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
        try rhs.binder(stmt, &index)
    }
}

public func || (lhs: Condition, rhs: Condition) -> Condition {
    Condition(sql: "(\(lhs.sql) OR \(rhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
        try rhs.binder(stmt, &index)
    }
}

public prefix func ! (lhs: Condition) -> Condition {
    Condition(sql: "(NOT \(lhs.sql))") { stmt, index in
        try lhs.binder(stmt, &index)
    }
}

// MARK: - Null support

extension ColumnRef {
    public func isNull<U: Bindable>() -> Condition where ValueType == U? {
        Condition(sql: "(\(_sqlRef) IS NULL)") { _, _ in }
    }

    public func isNotNull<U: Bindable>() -> Condition where ValueType == U? {
        Condition(sql: "(\(_sqlRef) IS NOT NULL)") { _, _ in }
    }
}

// MARK: - In support

extension ColumnRef where ValueType: DBEquatable {
    public func `in`(_ values: ValueType...) -> Condition {
        Condition(sql: "(\(_sqlRef) IN (\(values.map { _ in "?" }.joined(separator: ","))))") { stmt, index in
            for value in values {
                try ValueType.bind(to: stmt, value: value, at: &index)
            }
        }
    }

    public func `in`(_ query: (String, Database.ManagedBinder, ValueType.Type)) -> Condition {
        Condition(sql: "(\(_sqlRef) IN (\(query.0)))") { stmt, index in
            try query.1(stmt, &index)
        }
    }
}
