//
//  ColumnRef.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// ColumnRef is a protocol that represents a reference to a column in a table.
public protocol ColumnRef<ValueType>: Expression {
    /// Type of the value that the column holds.
    associatedtype ValueType: Bindable

    /// SQL reference to the column.
    ///
    /// This is a fully qualified reference to the column, including the table name.
    /// The value must be escaped properly to avoid conflicts with reserved keywords.
    var _sqlRef: String { get }

    /// SQL reference to the column.
    ///
    /// This is a reference to the column without the table name.
    /// The value must be escaped properly to avoid conflicts with reserved keywords.
    var _sqlName: String { get }

    /// Binder that binds values to the statement if needed.
    var binder: Database.ManagedBinder? { get }
}

/// A typed column reference.
///
/// This is a reference to a column in a table with a specific type.
public struct TypedColumnRef<Value: Bindable>: ColumnRef {
    public typealias ValueType = Value

    /// Name of the table.
    ///
    /// Escaped properly to avoid conflicts with reserved keywords.
    public let tableName: String

    /// Name of the column.
    ///
    /// Escaped properly to avoid conflicts with reserved keywords.
    public let columnName: String

    /// Initializes a new column reference.
    ///
    /// `columnName` and `tableName` must be escaped properly to avoid conflicts with reserved keywords.
    ///
    /// - Parameters:
    ///   - columnName: Name of the column.
    ///   - tableName: Name of the table.
    public init(named columnName: String, of tableName: String) {
        self.tableName = tableName
        self.columnName = columnName
    }

    public var _sqlRef: String {
        "\(tableName).\(columnName)"
    }

    public var _sqlName: String {
        columnName
    }

    public let binder: Database.ManagedBinder? = nil

    /// Returns a new column reference with a fallback value in case of null.
    /// - Parameter value: Fallback value in case of null.
    /// - Returns: A new column reference.
    public func ifNull<Wrapped>(then value: Wrapped) -> IfNullColumnRef<Wrapped> where ValueType == Wrapped? {
        IfNullColumnRef(self, value: value)
    }
}

/// A column reference with a fallback value in case of null.
///
/// This is a reference to a column in a table with a specific type and a fallback value in case of null.
public struct IfNullColumnRef<Value: Bindable>: ColumnRef {
    /// Type of the value that the column holds.
    public typealias ValueType = Value

    /// Column reference to a column that can be null.
    public let ref: any ColumnRef<Value?>

    /// Fallback value in case of null.
    public let value: Value

    /// Initializes a new column reference with a fallback value in case of null.
    /// - Parameters:
    ///   - ref: Column reference to a column that can be null.
    ///   - value: Fallback value in case of null.
    public init(_ ref: any ColumnRef<Value?>, value: Value) {
        self.ref = ref
        self.value = value
    }

    public var _sqlRef: String {
        "IFNULL(\(ref._sqlRef), ?)"
    }

    public var _sqlName: String {
        "IFNULL(\(ref._sqlName), ?)"
    }

    public var binder: Database.ManagedBinder? {
        { [value] stmt, index in
            try ref.binder?(stmt, &index)
            try ValueType.bind(to: stmt, value: value, at: &index)
        }
    }
}
