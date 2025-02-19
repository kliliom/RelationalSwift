//
//  TestUtils.swift
//

@testable import RelationalSwift

extension SQLConvertible {
    var builtSQL: String {
        let builder = SQLBuilder()
        append(to: builder)
        return builder.sql.joined(separator: " ")
    }
}
