//
//  Utils.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

extension OpaquePointer: @unchecked @retroactive Sendable {}

/// Checks the result of a block and throws an error if it does not match the expected result.
/// - Parameters:
///   - block: The block to check.
///   - db: The database to check.
///   - result: The expected result.
/// - Throws: A `InterfaceError` if the result does not match the expected result.
@DatabaseActor
func check(_ block: @autoclosure () -> Int32, db: OpaquePointer? = nil, is result: Int32) throws {
    let code = block()
    guard result != code else { return }
    if let db {
        throw InterfaceError(sqlite: code, message: String(cString: sqlite3_errmsg(db)))
    } else {
        throw InterfaceError(sqlite: code, message: String(cString: sqlite3_errstr(code)))
    }
}

/// Checks the result of a block and throws an error if it does not match any of the expected results.
/// - Parameters:
///   - block: The block to check.
///   - db: The database to check.
///   - results: The expected results.
/// - Throws: A `InterfaceError` if the result does not match any of the expected results.
/// - Returns: The result of the block.
@DatabaseActor
func check(_ block: @autoclosure () -> Int32, db: OpaquePointer? = nil, in results: Int32...) throws -> Int32 {
    let code = block()
    guard !results.contains(code) else { return code }
    if let db {
        throw InterfaceError(sqlite: code, message: String(cString: sqlite3_errmsg(db)))
    } else {
        throw InterfaceError(sqlite: code, message: String(cString: sqlite3_errstr(code)))
    }
}
