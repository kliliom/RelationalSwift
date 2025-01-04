//
//  DefaultColumnConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct DefaultColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = DefaultColumnConstraint(
            unsafeValue: "x"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.unsafeValue == "x")
        #expect(constraint.builtSQL == """
        DEFAULT x
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = DefaultColumnConstraint(
            unsafeValue: "x",
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.unsafeValue == "x")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" DEFAULT x
        """)
    }

    @Test("Validation fails if constraint name is empty")
    func validationFailsIfConstraintNameIsEmpty() throws {
        let constraint = DefaultColumnConstraint(
            unsafeValue: "x",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "DEFAULT")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int?.self, defaultValue: 123)
            .unsafeDefault("x", constraintName: "constraint")

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! DefaultColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" DEFAULT x
        """)
    }
}
