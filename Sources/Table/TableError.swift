//
//  TableError.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Errors that can be thrown by the RelationalSwift.
public struct TableError: Error, Equatable {
    /// Action that was being performed when the error occurred.
    public let message: String

    /// Initializes a new error.
    /// - Parameter message: Error message.
    public init(message: String) {
        self.message = message
    }
}

extension TableError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}
