//
//  InterfaceError.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Errors that can be thrown by the RelationalSwift client.
public struct InterfaceError: Error, Equatable {
    /// Action that was being performed when the error occurred.
    public let message: String
    /// SQLite error code.
    public let code: Int32

    /// Initializes a new error.
    /// - Parameters:
    ///   - message: Error message.
    ///   - code: SQLite error code.
    public init(message: String, code: Int32) {
        self.message = message
        self.code = code
    }
}

extension InterfaceError: LocalizedError {
    public var errorDescription: String? {
        "\(message) (\(code))"
    }
}
