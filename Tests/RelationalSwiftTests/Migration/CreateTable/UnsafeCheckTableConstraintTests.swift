//
//  UnsafeCheckTableConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct UnsafeCheckTableConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = UnsafeCheckTableConstraint(
            "name != ''"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.expression == "name != ''")
        #expect(constraint.builtSQL == """
        CHECK ( name != '' )
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = UnsafeCheckTableConstraint(
            "name != ''",
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.expression == "name != ''")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" CHECK ( name != '' )
        """)
    }

    @Test("Validation fails when constraint name is empty")
    func validationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = UnsafeCheckTableConstraint(
            "name != ''",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {})

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "CHECK")])
    }

    @Test("Validation fails when expression is empty")
    func validationFailsWhenExpressionIsEmpty() throws {
        let constraint = UnsafeCheckTableConstraint(
            ""
        )
        let validation = Validation()
        constraint.validate(in: validation, createTable: CreateTable("table") {})

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .expressionEmpty)
        #expect(error.path == [.constraint(nil, type: "CHECK")])
    }

    @Test("Convenience method on CreateTable")
    func convenienceMethodOnCreateTable() throws {
        let createTable = CreateTable("table") {
            Column("column", ofType: Int?.self)
        }.unsafeCheck(
            "column > 0",
            constraintName: "constraint"
        )

        try #require(createTable.constraints.count == 1)
        let constraint = createTable.constraints.first as! UnsafeCheckTableConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.expression == "column > 0")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" CHECK ( column > 0 )
        """)
    }
}
