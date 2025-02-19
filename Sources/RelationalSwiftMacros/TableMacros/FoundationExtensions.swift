//
//  FoundationExtensions.swift
//

import Foundation

extension String {
    /// Returns the string escaped and wrapped in quotes.
    var sqlIdentifier: String {
        "\"\(replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
