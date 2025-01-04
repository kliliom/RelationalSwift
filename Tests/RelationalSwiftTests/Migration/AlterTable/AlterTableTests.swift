//
//  AlterTableTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct AlterTableTests {
    @Test("Alter table has schema")
    func alterTableHasSchema() {
        let alterTable = AlterTable("table", schema: "schema")

        #expect(alterTable.tableName == "table")
        #expect(alterTable.schemaName == "schema")
        #expect(alterTable.builtSQL == """
        ALTER TABLE "schema" . "table"
        """)
    }

    @Test("Alter table has no schema")
    func alterTableHasNoSchema() {
        let alterTable = AlterTable("table")

        #expect(alterTable.tableName == "table")
        #expect(alterTable.schemaName == nil)
        #expect(alterTable.builtSQL == """
        ALTER TABLE "table"
        """)
    }

    @Test("Validation fails when table name is empty")
    func validationFailsWhenTableNameIsEmpty() throws {
        let alterTable = AlterTable("")

        let validation = Validation()
        alterTable.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .tableNameEmpty)
        #expect(error.path == [])
    }

    @Test("Validation fails when schema name is empty")
    func validationFailsWhenSchemaNameIsEmpty() throws {
        let alterTable = AlterTable("table", schema: "")

        let validation = Validation()
        alterTable.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .schemaNameEmpty)
        #expect(error.path == [])
    }
}
