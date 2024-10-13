//
//  ColumnRef.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

/// ColumnRef is a protocol that represents a reference to a column in a table.
public protocol ColumnRef<ValueType>: Sendable {
    /// Type of the value that the column holds.
    associatedtype ValueType: Bindable

    /// SQL reference to the column.
    var _sqlRef: String { get }

    /// SQL reference to the column.
    var _sqlName: String { get }

    /// Binder that binds the values to the statement.
    var binder: Binder? { get }
}

/// A typed column reference.
public struct TypedColumnRef<Value: Bindable>: ColumnRef {
    /// Type of the value that the column holds.
    public typealias ValueType = Value

    /// Name of the table.
    public let tableName: String

    /// Name of the column.
    public let columnName: String

    /// Initializes a new column reference.
    /// - Parameters:
    ///   - columnName: Name of the column.
    ///   - tableName: Name of the table.
    public init(named columnName: String, of tableName: String) {
        self.tableName = tableName
        self.columnName = columnName
    }

    /// SQL reference to the column.
    public var _sqlRef: String {
        "\"\(tableName)\".\"\(columnName)\""
    }

    /// SQL name of the column.
    public var _sqlName: String {
        "\"\(columnName)\""
    }

    /// Binder that binds the values to the statement.
    public let binder: Binder? = nil

    public func ifNull<Wrapped>(then value: Wrapped) -> IfNullColumnRef<Wrapped> where ValueType == Wrapped? {
        IfNullColumnRef(named: columnName, of: tableName, value: value)
    }
}

public struct IfNullColumnRef<Value: Bindable>: ColumnRef {
    /// Type of the value that the column holds.
    public typealias ValueType = Value

    /// Name of the table.
    public let tableName: String

    /// Name of the column.
    public let columnName: String

    /// Fallback value in case of null.
    public let value: Value

    /// Initializes a new column reference.
    /// - Parameters:
    ///   - columnName: Name of the column.
    ///   - tableName: Name of the table.
    ///   - value: Fallback value in case of null.
    public init(named columnName: String, of tableName: String, value: Value) {
        self.tableName = tableName
        self.columnName = columnName
        self.value = value
    }

    /// SQL reference to the column.
    public var _sqlRef: String {
        "IFNULL(\"\(tableName)\".\"\(columnName)\", ?)"
    }

    /// SQL name of the column.
    public var _sqlName: String {
        "IFNULL(\"\(columnName)\", ?)"
    }

    /// Binder that binds the values to the statement.
    public var binder: Binder? {
        { [value] stmt, index in
            try ValueType.bind(to: stmt, value: value, at: &index)
        }
    }
}
