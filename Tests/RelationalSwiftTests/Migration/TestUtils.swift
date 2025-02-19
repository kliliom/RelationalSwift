//
//  TestUtils.swift
//

@testable import RelationalSwift

extension SQLBuilderAppendable {
    var builtSQL: String {
        var builder = SQLBuilder()
        append(to: &builder)
        return builder.sql.joined(separator: " ")
    }
}
