//
//  TestUtils.swift
//  Created by Kristof Liliom in 2024.
//

@testable import Migration

extension SQLConvertible {
    var builtSQL: String {
        let builder = SQLBuilder()
        append(to: builder)
        return builder.sql.joined(separator: " ")
    }
}
