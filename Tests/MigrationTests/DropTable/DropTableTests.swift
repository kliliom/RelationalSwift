//
//  DropTableTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface
@testable import Migration

@Suite
struct DropTableTests {
    @Test("Drop table has schema")
    func dropTableHasSchema() {
        let dropTable = DropTable("table", schema: "schema")

        #expect(dropTable.tableName == "table")
        #expect(dropTable.schemaName == "schema")
        #expect(dropTable.builtSQL == """
        DROP TABLE "schema" . "table"
        """)
    }

    @Test("Drop table has no schema")
    func dropTableHasNoSchema() {
        let dropTable = DropTable("table")

        #expect(dropTable.tableName == "table")
        #expect(dropTable.schemaName == nil)
        #expect(dropTable.builtSQL == """
        DROP TABLE "table"
        """)
    }

    @Test("Drop table if exists")
    func dropTableIfExists() {
        let dropTable = DropTable("table")
            .ifExists()

        #expect(dropTable.tableName == "table")
        #expect(dropTable.schemaName == nil)
        #expect(dropTable.builtSQL == """
        DROP TABLE IF EXISTS "table"
        """)
    }

    @Test("Validation fails when table name is empty")
    func validationFailsWhenTableNameIsEmpty() throws {
        let dropTable = DropTable("")

        let validation = Validation()
        dropTable.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .tableNameEmpty)
        #expect(error.path == [.dropTable("")])
    }

    @Test("Validation fails when schema name is empty")
    func validationFailsWhenSchemaNameIsEmpty() throws {
        let dropTable = DropTable("table", schema: "")

        let validation = Validation()
        dropTable.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .schemaNameEmpty)
        #expect(error.path == [.dropTable("table")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let createTable = CreateTable("test_table") {
            Column("column", ofType: Int.self)
        }

        let dropTable = DropTable("test_table")

        let db = try await Database.openInMemory()
        try await createTable.apply(to: db)
        try await dropTable.apply(to: db)

        let columns: [()] = try await db.query(
            "PRAGMA table_info('test_table')"
        )
        #expect(columns.count == 0)
    }
}
