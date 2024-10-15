//
//  FoundationExtensions.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

extension String {
    /// Returns the string escaped and wrapped in quotes.
    var sqlIdentifier: String {
        "\"\(replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
