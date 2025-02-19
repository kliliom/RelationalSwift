//
//  ColumnRef.swift
//

import Foundation

/// ColumnRef is a protocol that represents a reference to a column in a table.
public protocol ColumnRef: Expression {
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
    public typealias ExpressionValue = Value

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

    public func append(to builder: inout SQLBuilder) {
        builder.sql.append(_sqlRef)
    }
}
