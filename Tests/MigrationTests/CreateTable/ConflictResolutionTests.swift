//
//  ConflictResolutionTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct ConflictResolutionTests {
    @Test("Append to builder", arguments: [
        (.rollback, ["ON CONFLICT ROLLBACK"]),
        (.abort, ["ON CONFLICT ABORT"]),
        (.fail, ["ON CONFLICT FAIL"]),
        (.ignore, ["ON CONFLICT IGNORE"]),
        (.replace, ["ON CONFLICT REPLACE"]),
    ] as [(ConflictResolution, [String])])
    func appendToBuilder(argument: (ConflictResolution, [String])) {
        let resolution = argument.0
        let builder = SQLBuilder()
        resolution.append(to: builder)
        #expect(builder.sql == [argument.1.first!])
    }
}
