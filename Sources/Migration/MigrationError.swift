//
//  MigrationError.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Errors that can be thrown by the RelationalSwift.
public struct MigrationError: Error, Equatable {
    /// Action that was being performed when the error occurred.
    public let message: String
    /// Error code.
    public let code: Int
    /// Additional information about the error.
    public let info: [String: String]

    /// Initializes a new error.
    /// - Parameters:
    ///   - message: Error message.
    ///   - code: Error code.
    ///   - info: Additional information about the error.
    init(message: String, code: Int, info: [String: String]) {
        self.message = message
        self.code = code
        self.info = info
    }
}

extension MigrationError: LocalizedError {
    public var errorDescription: String? {
        "\(message) [\(code)]"
    }
}

extension MigrationError {
    /// Creates a change set order mismatch error.
    /// - Parameters:
    ///   - expectedID: Expected change set ID.
    ///   - actualID: Actual change set ID.
    /// - Returns: A change set order mismatch error.
    public static func changeSetOrderMismatch(expectedID: String, actualID: String) -> MigrationError {
        MigrationError(
            message: "change set order mismatch",
            code: 1,
            info: [
                "expected change set ID": expectedID,
                "actual change set ID": actualID,
            ]
        )
    }

    /// Creates a duplicate change set ID error.
    /// - Parameter id: Duplicate change set ID.
    /// - Returns: A duplicate change set ID error.
    public static func duplicateChangeSetID(_ id: String) -> MigrationError {
        MigrationError(
            message: "duplicate change set IDs",
            code: 2,
            info: [
                "change set ID": id,
            ]
        )
    }
}
