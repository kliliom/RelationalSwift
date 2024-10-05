//
//  UnsafeCheckColumnConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct UnsafeCheckColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = UnsafeCheckColumnConstraint(
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
        let constraint = UnsafeCheckColumnConstraint(
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
        let constraint = UnsafeCheckColumnConstraint(
            "name != ''",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "CHECK")])
    }

    @Test("Validation fails when expression is empty")
    func validationFailsWhenExpressionIsEmpty() throws {
        let constraint = UnsafeCheckColumnConstraint(
            ""
        )
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .expressionEmpty)
        #expect(error.path == [.constraint(nil, type: "CHECK")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int?.self)
            .unsafeCheck("column > 0", constraintName: "constraint")

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! UnsafeCheckColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.expression == "column > 0")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" CHECK ( column > 0 )
        """)
    }
}
