//
//  UniqueColumnConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct UniqueColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = UniqueColumnConstraint()

        #expect(constraint.constraintName == nil)
        #expect(constraint.builtSQL == """
        UNIQUE
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = UniqueColumnConstraint(constraintName: "constraint")

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" UNIQUE
        """)
    }

    @Test("Has ON CONFLICT")
    func hasConflictResolution() {
        let constraint = UniqueColumnConstraint(onConflict: .rollback)

        #expect(constraint.constraintName == nil)
        #expect(constraint.builtSQL == """
        UNIQUE ON CONFLICT ROLLBACK
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = UniqueColumnConstraint(
            onConflict: .rollback,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" UNIQUE ON CONFLICT ROLLBACK
        """)
    }

    @Test("Verification fails when constraint name is empty")
    func verificationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = UniqueColumnConstraint(constraintName: "")
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "UNIQUE")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int?.self)
            .unique(onConflict: .ignore, constraintName: "constraint")

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! UniqueColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.onConflict == .ignore)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" UNIQUE ON CONFLICT IGNORE
        """)
    }
}
