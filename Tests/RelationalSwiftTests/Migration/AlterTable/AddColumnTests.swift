//
//  AddColumnTests.swift
//

import Testing

@testable import RelationalSwift

@Suite
struct AddColumnTests {
    @Test("Add column")
    func addColumn() {
        let addColumn = AlterTable("table")
            .addColumn(Column("column", ofType: Int.self))

        #expect(addColumn.column.name == "column")
        #expect(String(describing: addColumn.column.type) == String(describing: Int.self))
        #expect(addColumn.column.constraints.count == 1)
        #expect(addColumn.builtSQL == """
        ALTER TABLE "table" ADD COLUMN "column" INTEGER NOT NULL
        """)
    }

    @Test("Validation combines issues")
    func validationCombinesIssues() throws {
        let addColumn = AlterTable("")
            .addColumn(Column("", ofType: Int.self))

        let validation = Validation()
        addColumn.validate(in: validation)

        try #require(validation.errors.count == 2)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .columnNameEmpty)
        #expect(errors[0].path == [.alterTable("ADD COLUMN")])
        #expect(errors[1].path == [.alterTable("ADD COLUMN"), .column("")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let createTable = CreateTable("test_table") {
            Column("column", ofType: Int.self)
        }

        let addColumn = AlterTable("test_table")
            .addColumn(Column("new_column", ofType: Int.self))

        let db = try await Database.openInMemory()
        try await createTable.apply(to: db)
        try await addColumn.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('test_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
        #expect(columns.count == 2)
        #expect(columns.contains("column"))
        #expect(columns.contains("new_column"))
    }
}
