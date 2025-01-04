//
//  Table.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A table in the database.
public protocol Table<TableRefType>: Sendable {
    /// Table reference type.
    associatedtype TableRefType: TableRef

    /// Returns a table reference.
    static var table: TableRefType { get }

    /// Table name.
    static var name: String { get }

    /// Reads a row from the database.
    /// - Parameters:
    ///   - stmt: Statement handle.
    ///   - index: Starting index to read from.
    /// - Returns: Row.
    @DatabaseActor
    static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> Self
}
