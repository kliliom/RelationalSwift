//
//  Error.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Errors that can be thrown by the DB4Swift.
public struct DB4SwiftMigrationError: Error, Equatable {
    /// Action that was being performed when the error occurred.
    public let message: String

    /// Initializes a new error.
    /// - Parameter message: Error message.
    public init(message: String) {
        self.message = message
    }
}

extension DB4SwiftMigrationError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}
