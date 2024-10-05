//
//  ExecuteTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface
@testable import Migration

@Suite
struct ExecuteTests {
    @Test("Execute")
    func execute() {
        let execute = Execute { db in
            try db.exec("SELECT 1")
        }

        #expect(execute.block != nil)
    }

    @Test("Validation does nothing")
    func validationDoesNothing() {
        let execute = Execute { db in
            try db.exec("SELECT 1")
        }

        let validation = Validation()
        execute.validate(in: validation)

        #expect(validation.errors.isEmpty)
    }

    @Test("Apply runs block")
    func applyRunsBlock() async throws {
        let execute = Execute { db in
            try db.exec("CREATE TABLE test_table (a INTEGER)")
        }

        let db = try await Database.openInMemory()
        try await execute.apply(to: db)

        let columns = try await db.query(
            "PRAGMA table_info('test_table')",
            step: { stmt, _ in
                var index: Int32 = 1
                return try String.column(of: stmt, at: &index)
            }
        )
        #expect(columns.count == 1)
        #expect(columns.first == "a")
    }
}
