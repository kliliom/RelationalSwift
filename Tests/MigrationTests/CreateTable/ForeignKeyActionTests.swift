//
//  ForeignKeyActionTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct ForeignKeyActionTests {
    @Test("Append to builder", arguments: [
        (.cascade, ["CASCADE"]),
        (.restrict, ["RESTRICT"]),
        (.setNull, ["SET NULL"]),
        (.setDefault, ["SET DEFAULT"]),
        (.noAction, ["NO ACTION"]),
    ] as [(ForeignKeyAction, [String])])
    func appendToBuilder(argument: (ForeignKeyAction, [String])) {
        let action = argument.0
        let builder = SQLBuilder()
        action.append(to: builder)
        #expect(builder.sql == [argument.1.first!])
    }
}
