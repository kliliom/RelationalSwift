//
//  RenameTableTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface
@testable import Migration

@Suite
struct RenameTableTests {
    @Test("Rename table")
    func renameTable() {
        let change = AlterTable("old")
            .renameTable(to: "new")

        #expect(change.newTableName == "new")
        #expect(change.builtSQL == """
        ALTER TABLE "old" RENAME TO "new"
        """)
    }

    @Test("Validation fails when table name is empty")
    func validationFailsWhenTableNameIsEmpty() throws {
        let change = AlterTable("old")
            .renameTable(to: "")

        let validation = Validation()
        change.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .tableNameEmpty)
        #expect(error.path == [.alterTable("RENAME TO")])
    }

    @Test("Validation combines issues")
    func validationCombinesIssues() throws {
        let change = AlterTable("")
            .renameTable(to: "")

        let validation = Validation()
        change.validate(in: validation)

        try #require(validation.errors.count == 2)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .tableNameEmpty)
        #expect(errors[0].path == [.alterTable("RENAME TO")])
        #expect(errors[1].path == [.alterTable("RENAME TO")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let createTable = CreateTable("old_table") {
            Column("column", ofType: Int.self)
        }

        let change = AlterTable("old_table")
            .renameTable(to: "new_table")

        let db = try await Database.openInMemory()
        try await createTable.apply(to: db)
        try await change.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('new_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
        #expect(columns.count == 1)
        #expect(columns.first == "column")
    }
}
