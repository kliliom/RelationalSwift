//
//  CreateTableTests.swift
//

import Testing

@testable import RelationalSwift

@Suite
struct CreateTableTests {
    @Test("Table has schema")
    func tableHasSchema() {
        let table = CreateTable("table", schema: "schema") {
            Column("column", ofType: Int.self)
        }

        #expect(table.tableName == "table")
        #expect(table.schemaName == "schema")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "schema" . "table" ( 
            "column" INTEGER NOT NULL 
         )
        """)
    }

    @Test("Table has no columns")
    func tableHasNoColumns() {
        let table = CreateTable("table") {}

        #expect(table.tableName == "table")
        #expect(table.columns.isEmpty)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( )
        """)
    }

    @Test("Table has one column")
    func tableHasOneColumn() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column" INTEGER NOT NULL 
         )
        """)
    }

    @Test("Table has multiple columns")
    func tableHasMultipleColumns() {
        let table = CreateTable("table") {
            Column("column1", ofType: Int.self)
            Column("column2", ofType: String.self)
        }

        #expect(table.tableName == "table")
        #expect(table.columns.count == 2)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column1" INTEGER NOT NULL , 
            "column2" TEXT NOT NULL 
         )
        """)
    }

    @Test("Table has one constraint")
    func tableHasOneConstraint() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .primaryKey(on: "column")

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.count == 1)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column" INTEGER NOT NULL , 
            PRIMARY KEY ( "column" ) 
         )
        """)
    }

    @Test("Table has multiple constraints")
    func tableHasMultipleConstraints() {
        let table = CreateTable("table") {
            Column("column1", ofType: Int.self)
            Column("column2", ofType: String.self)
        }
        .primaryKey(on: "column1")
        .unique(on: "column2")

        #expect(table.tableName == "table")
        #expect(table.columns.count == 2)
        #expect(table.constraints.count == 2)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column1" INTEGER NOT NULL , 
            "column2" TEXT NOT NULL , 
            PRIMARY KEY ( "column1" ) , 
            UNIQUE ( "column2" ) 
         )
        """)
    }

    @Test("Table is TEMPORARY")
    func tableIsTemporary() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .temporary()

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TEMPORARY TABLE "table" ( 
            "column" INTEGER NOT NULL 
         )
        """)
    }

    @Test("Table is IF NOT EXISTS")
    func tableHasIfNotExists() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .ifNotExists()

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE IF NOT EXISTS "table" ( 
            "column" INTEGER NOT NULL 
         )
        """)
    }

    @Test("Table is WITHOUT ROWID")
    func tableIsWithoutRowID() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .withoutRowID()

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column" INTEGER NOT NULL 
         ) WITHOUT ROWID
        """)
    }

    @Test("Table is STRICT")
    func tableIsStrict() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .strict()

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column" INTEGER NOT NULL 
         ) STRICT
        """)
    }

    @Test("Table is WITHOUT ROWID and STRICT")
    func tableIsWithoutRowIDAndStrict() {
        let table = CreateTable("table") {
            Column("column", ofType: Int.self)
        }
        .withoutRowID()
        .strict()

        #expect(table.tableName == "table")
        #expect(table.columns.count == 1)
        #expect(table.constraints.isEmpty)
        #expect(table.builtSQL == """
        CREATE TABLE "table" ( 
            "column" INTEGER NOT NULL 
         ) WITHOUT ROWID , STRICT
        """)
    }

    @Test("Validation fails when table name is empty")
    func validationFailsWhenTableNameIsEmpty() throws {
        let table = CreateTable("") {
            Column("column", ofType: Int.self)
        }
        let validation = Validation()
        table.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .tableNameEmpty)
        #expect(error.path == [.createTable("")])
    }

    @Test("Validation fails when schema name is empty")
    func validationFailsWhenSchemaNameIsEmpty() throws {
        let table = CreateTable("table", schema: "") {
            Column("column", ofType: Int.self)
        }
        let validation = Validation()
        table.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .schemaNameEmpty)
        #expect(error.path == [.createTable("table")])
    }

    @Test("Validation fails when table contains no columns")
    func validationFailsWhenTableContainsNoColumns() throws {
        let table = CreateTable("table") {}
        let validation = Validation()
        table.validate(in: validation)

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .noColumnsSpecified)
        #expect(error.path == [.createTable("table")])
    }

    @Test("Apply to database")
    func applyToDatabase() async throws {
        let table = CreateTable("test_table") {
            Column("id", ofType: Int.self)
                .primaryKey()
            Column("name", ofType: String.self)
            Column("email", ofType: String.self)
                .unique()
        }
        .temporary()
        .ifNotExists()
        .withoutRowID()
        .strict()
        .unsafeCheck("LENGTH(name) > 0")

        let db = try await Database.openInMemory()
        try await table.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('test_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
        #expect(columns.count == 3)
        #expect(columns[0] == "id")
        #expect(columns[1] == "name")
        #expect(columns[2] == "email")
    }

    @Test("Table with special identifiers")
    func tableWithSpecialIdentifiers() async throws {
        let table = CreateTable("test\"table") {
            Column("i\"d", ofType: Int.self)
                .primaryKey(constraintName: "con\"straint")
        }

        let db = try await Database.openInMemory()
        try await table.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('test\"table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
        #expect(columns.count == 1)
        #expect(columns[0] == "i\"d")
    }
}
