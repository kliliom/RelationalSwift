//
//  DropColumnTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface
@testable import Migration

@Suite
struct DropColumnTests {
    @Test("Drop column")
    func dropColumn() {
        let dropColumn = AlterTable("table")
            .dropColumn("column")

        #expect(dropColumn.columnName == "column")
        #expect(dropColumn.builtSQL == """
        ALTER TABLE "table" DROP COLUMN "column"
        """)
    }

    @Test("Validation fails if column name is empty")
    func validationFailsIfColumnNameIsEmpty() throws {
        let dropColumn = AlterTable("table")
            .dropColumn("")

        let validation = Validation()
        dropColumn.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.path == [.alterTable("DROP COLUMN")])
    }

    @Test("Validation combines issues")
    func validationCombinesIssues() throws {
        let dropColumn = AlterTable("")
            .dropColumn("")

        let validation = Validation()
        dropColumn.validate(in: validation)

        try #require(validation.errors.count == 2)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .columnNameEmpty)
        #expect(errors[0].path == [.alterTable("DROP COLUMN")])
        #expect(errors[1].path == [.alterTable("DROP COLUMN")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let createTable = CreateTable("test_table") {
            Column("column", ofType: Int.self)
            Column("droppable_column", ofType: Int.self)
        }

        let dropColumn = AlterTable("test_table")
            .dropColumn("droppable_column")

        let db = try await Database.openInMemory()
        try await createTable.apply(to: db)
        try await dropColumn.apply(to: db)

        let columns = try await db.query(
            "PRAGMA table_info('test_table')",
            step: { stmt, _ in
                try String.column(of: stmt, at: 1)
            }
        )
        #expect(columns.count == 1)
        #expect(columns.first == "column")
    }
}
