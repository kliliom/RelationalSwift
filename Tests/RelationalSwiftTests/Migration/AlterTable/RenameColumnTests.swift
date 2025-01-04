//
//  RenameColumnTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct RenameColumnTests {
    @Test("Rename column")
    func renameColumn() {
        let change = AlterTable("table")
            .renameColumn(from: "old", to: "new")

        #expect(change.oldName == "old")
        #expect(change.newName == "new")
        #expect(change.builtSQL == """
        ALTER TABLE "table" RENAME COLUMN "old" TO "new"
        """)
    }

    @Test("Validation fails if old column name is empty")
    func validationFailsIfOldColumnNameIsEmpty() throws {
        let change = AlterTable("table")
            .renameColumn(from: "", to: "new")

        let validation = Validation()
        change.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.path == [.alterTable("RENAME COLUMN")])
        #expect(error.info == ["location": "old column name"])
    }

    @Test("Validation fails if new column name is empty")
    func validationFailsIfNewColumnNameIsEmpty() throws {
        let change = AlterTable("table")
            .renameColumn(from: "old", to: "")

        let validation = Validation()
        change.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.path == [.alterTable("RENAME COLUMN")])
        #expect(error.info == ["location": "new column name"])
    }

    @Test("Validation combines issues")
    func validationCombinesIssues() throws {
        let change = AlterTable("")
            .renameColumn(from: "", to: "")

        let validation = Validation()
        change.validate(in: validation)

        try #require(validation.errors.count == 3)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .columnNameEmpty)
        #expect(errors[2].issue == .columnNameEmpty)
        #expect(errors[0].path == [.alterTable("RENAME COLUMN")])
        #expect(errors[1].path == [.alterTable("RENAME COLUMN")])
        #expect(errors[2].path == [.alterTable("RENAME COLUMN")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let createTable = CreateTable("test_table") {
            Column("column", ofType: Int.self)
        }

        let renameColumn = AlterTable("test_table")
            .renameColumn(from: "column", to: "renamed_column")

        let db = try await Database.openInMemory()
        try await createTable.apply(to: db)
        try await renameColumn.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('test_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
        #expect(columns.count == 1)
        #expect(columns.first == "renamed_column")
    }
}
