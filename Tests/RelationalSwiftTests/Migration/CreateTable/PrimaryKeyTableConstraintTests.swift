//
//  PrimaryKeyTableConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct PrimaryKeyTableConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.columns == ["column"])
        #expect(constraint.onConflict == nil)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ( "column" )
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column",
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.columns == ["column"])
        #expect(constraint.onConflict == nil)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY ( "column" )
        """)
    }

    @Test("Has one column")
    func hasOneColumn() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.columns == ["column"])
        #expect(constraint.onConflict == nil)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ( "column" )
        """)
    }

    @Test("Has multiple columns")
    func hasMultipleColumns() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column1", ["column2"]
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.columns == ["column1", "column2"])
        #expect(constraint.onConflict == nil)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ( "column1" , "column2" )
        """)
    }

    @Test("Has ON CONFLICT")
    func hasOnConflict() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column",
            onConflict: .rollback
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.columns == ["column"])
        #expect(constraint.onConflict == .rollback)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ( "column" ) ON CONFLICT ROLLBACK
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = PrimaryKeyTableConstraint(
            on: "column1", ["column2"],
            onConflict: .rollback,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.columns == ["column1", "column2"])
        #expect(constraint.onConflict == .rollback)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY ( "column1" , "column2" ) ON CONFLICT ROLLBACK
        """)
    }

    @Test("Verification fails when constraint name is empty")
    func verificationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = PrimaryKeyTableConstraint(
            on: "column",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("column", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "PRIMARY KEY")])
    }

    @Test("Verification fails when columns are empty")
    func verificationFailsWhenColumnsAreEmpty() throws {
        var constraint = PrimaryKeyTableConstraint(
            on: "column"
        )
        constraint.columns = []
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("column", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .noColumnsSpecified)
        #expect(error.path == [.constraint(nil, type: "PRIMARY KEY")])
    }

    @Test("Verification fails when column name is empty")
    func verificationFailsWhenColumnNameIsEmpty() throws {
        let constraint = PrimaryKeyTableConstraint(
            on: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {
            Column("", ofType: Int.self)
        })

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.info["column index"] == "0")
        #expect(error.path == [.constraint(nil, type: "PRIMARY KEY")])
    }

    @Test("Verification fails when column is not in table")
    func verificationFailsWhenColumnIsNotInTable() throws {
        let constraint = PrimaryKeyTableConstraint(
            on: "column"
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {})

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNotFound)
        #expect(error.info["column"] == "column")
        #expect(error.path == [.constraint(nil, type: "PRIMARY KEY")])
    }

    @Test("Convenience method on CreateTable")
    func convenienceMethodOnCreateTable() throws {
        let createTable = CreateTable("table") {
            Column("column", ofType: Int?.self)
        }.primaryKey(
            on: "column",
            onConflict: .fail,
            constraintName: "constraint"
        )

        try #require(createTable.constraints.count == 1)
        let constraint = createTable.constraints.first as! PrimaryKeyTableConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.columns == ["column"])
        #expect(constraint.onConflict == .fail)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY ( "column" ) ON CONFLICT FAIL
        """)
    }
}
