//
//  NotNullColumnConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct NotNullColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = NotNullColumnConstraint()

        #expect(constraint.constraintName == nil)
        #expect(constraint.builtSQL == """
        NOT NULL
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = NotNullColumnConstraint(constraintName: "constraint")

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" NOT NULL
        """)
    }

    @Test("Has ON CONFLICT")
    func hasConflictResolution() {
        let constraint = NotNullColumnConstraint(onConflict: .rollback)

        #expect(constraint.constraintName == nil)
        #expect(constraint.builtSQL == """
        NOT NULL ON CONFLICT ROLLBACK
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = NotNullColumnConstraint(
            onConflict: .rollback,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" NOT NULL ON CONFLICT ROLLBACK
        """)
    }

    @Test("Verification fails when constraint name is empty")
    func verificationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = NotNullColumnConstraint(constraintName: "")
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "NOT NULL")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int.self)
            .notNull(onConflict: .abort, constraintName: "constraint")

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! NotNullColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" NOT NULL ON CONFLICT ABORT
        """)
    }
}
