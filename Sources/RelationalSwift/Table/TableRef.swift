//
//  TableRef.swift
//  Created by Kristof Liliom in 2024.
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

    /// SQL references for columns.
    var _readColumnSqlRefs: [String] { get }
}
