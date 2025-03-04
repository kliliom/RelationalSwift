//
//  TableRef.swift
//

import Foundation

/// A reference to a table in the database.
public protocol TableRef: Sendable {
    /// Table type.
    associatedtype TableType: Table

    /// SQL FROM clause.
    var _sqlFrom: String { get }

    /// SQL reference.
    var _sqlRef: String { get }

    /// References for all columns.
    var _allColumnRefs: [any ColumnRef] { get }
}
