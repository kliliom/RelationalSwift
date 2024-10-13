//
//  ColumnValueSetter.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// A column name and a value binder pair.
public struct ColumnValueSetter: Sendable {
    /// Name of the column.
    public var columnName: String

    /// Value binder.
    public var valueBinder: Binder

    /// Initializes a column value setter.
    /// - Parameters:
    ///   - columnName: Name of the column.
    ///   - valueBinder: Value binder.
    public init(columnName: String, valueBinder: @escaping Binder) {
        self.columnName = columnName
        self.valueBinder = valueBinder
    }
}
