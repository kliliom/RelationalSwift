//
//  ForeignKeyTableConstraintTests.swift
//

import Testing

@testable import RelationalSwift

@Suite
struct ForeignKeyTableConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.tableColumns == ["tableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        FOREIGN KEY ( "tableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" )
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.tableColumns == ["tableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" FOREIGN KEY ( "tableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" )
        """)
    }

    @Test("Has one foreign column")
    func hasOneForeignColumn() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.tableColumns == ["tableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        FOREIGN KEY ( "tableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" )
        """)
    }

    @Test("Has multiple foreign columns")
    func hasMultipleForeignColumns() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            "otherTableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            "otherForeignColumn"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.tableColumns == ["tableColumn", "otherTableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn", "otherForeignColumn"])
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        FOREIGN KEY ( "tableColumn" , "otherTableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" , "otherForeignColumn" )
        """)
    }

    @Test("Has onUpdate action")
    func hasOnUpdateAction() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            onUpdate: .cascade
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.tableColumns == ["tableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        FOREIGN KEY ( "tableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" ) ON UPDATE CASCADE
        """)
    }

    @Test("Has onDelete action")
    func hasOnDeleteAction() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            onDelete: .setNull
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.tableColumns == ["tableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == .setNull)
        #expect(constraint.builtSQL == """
        FOREIGN KEY ( "tableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" ) ON DELETE SET NULL
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            "otherTableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            "otherForeignColumn",
            onUpdate: .cascade,
            onDelete: .setNull,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.tableColumns == ["tableColumn", "otherTableColumn"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn", "otherForeignColumn"])
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == .setNull)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" FOREIGN KEY ( "tableColumn" , "otherTableColumn" ) REFERENCES "foreignTable" ( "foreignColumn" , "otherForeignColumn" ) ON UPDATE CASCADE ON DELETE SET NULL
        """)
    }

    @Test("Validation fails when constraint name is empty")
    func validationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("tableColumn", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "FOREIGN KEY")])
    }

    @Test("Validation fails when table column is not found")
    func validationFailsWhenTableColumnIsNotFound() throws {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn"
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {})

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNotFound)
        #expect(error.info["column"] == "tableColumn")
        #expect(error.path == [.constraint(nil, type: "FOREIGN KEY")])
    }

    @Test("Validation fails when foreign column is empty")
    func validationFailsWhenForeignColumnIsEmpty() throws {
        let constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("tableColumn", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.info["foreign column index"] == "0")
        #expect(error.path == [.constraint(nil, type: "FOREIGN KEY")])
    }

    @Test("Validation fails when no columns are specified")
    func validationFailsWhenNoColumnsAreSpecified() throws {
        var constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn"
        )
        constraint.tableColumns = []
        constraint.foreignColumns = []
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {})

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .noColumnsSpecified)
        #expect(error.path == [.constraint(nil, type: "FOREIGN KEY")])
    }

    @Test("Validation fails when column count mismatch")
    func validationFailsWhenColumnCountMismatch() throws {
        var constraint = ForeignKeyTableConstraint(
            on: "tableColumn",
            referencing: "foreignTable",
            columns: "foreignColumn"
        )
        constraint.foreignColumns = []
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("tableColumn", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnCountMismatch)
        #expect(error.path == [.constraint(nil, type: "FOREIGN KEY")])
    }

    @Test("Convenience method on CreateTable")
    func convenienceMethodOnCreateTable() throws {
        let createTable = CreateTable("table") {
            Column("column", ofType: Int?.self)
        }.foreignKey(
            on: "column",
            referencing: "foreignTable",
            columns: "foreignColumn",
            onUpdate: .cascade,
            onDelete: .restrict,
            constraintName: "constraint"
        )

        try #require(createTable.constraints.count == 1)
        let constraint = createTable.constraints.first as! ForeignKeyTableConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.tableColumns == ["column"])
        #expect(constraint.foreignTable == "foreignTable")
        #expect(constraint.foreignColumns == ["foreignColumn"])
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == .restrict)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" FOREIGN KEY ( "column" ) REFERENCES "foreignTable" ( "foreignColumn" ) ON UPDATE CASCADE ON DELETE RESTRICT
        """)
    }
}
