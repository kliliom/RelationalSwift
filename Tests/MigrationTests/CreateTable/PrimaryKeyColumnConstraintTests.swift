//
//  PrimaryKeyColumnConstraintTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct PrimaryKeyColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = PrimaryKeyColumnConstraint()

        #expect(constraint.constraintName == nil)
        #expect(constraint.order == nil)
        #expect(constraint.onConflict == nil)
        #expect(constraint.autoIncrement == false)
        #expect(constraint.builtSQL == """
        PRIMARY KEY
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = PrimaryKeyColumnConstraint(
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.order == nil)
        #expect(constraint.onConflict == nil)
        #expect(constraint.autoIncrement == false)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY
        """)
    }

    @Test("Has ORDER")
    func hasOrder() {
        let constraint = PrimaryKeyColumnConstraint(
            order: .ascending
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.order == .ascending)
        #expect(constraint.onConflict == nil)
        #expect(constraint.autoIncrement == false)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ASC
        """)
    }

    @Test("Has ON CONFLICT")
    func hasOnConflict() {
        let constraint = PrimaryKeyColumnConstraint(
            onConflict: .rollback
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.order == nil)
        #expect(constraint.onConflict == .rollback)
        #expect(constraint.autoIncrement == false)
        #expect(constraint.builtSQL == """
        PRIMARY KEY ON CONFLICT ROLLBACK
        """)
    }

    @Test("Has AUTOINCREMENT")
    func hasAutoIncrement() {
        let constraint = PrimaryKeyColumnConstraint(
            autoIncrement: true
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.order == nil)
        #expect(constraint.onConflict == nil)
        #expect(constraint.autoIncrement == true)
        #expect(constraint.builtSQL == """
        PRIMARY KEY AUTOINCREMENT
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = PrimaryKeyColumnConstraint(
            order: .descending,
            onConflict: .abort,
            autoIncrement: true,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.order == .descending)
        #expect(constraint.onConflict == .abort)
        #expect(constraint.autoIncrement == true)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY DESC ON CONFLICT ABORT AUTOINCREMENT
        """)
    }

    @Test("Verification fails when constraint name is empty")
    func verificationFailsWhenConstraintNameIsEmpty() throws {
        let constraint = PrimaryKeyColumnConstraint(constraintName: "")
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "PRIMARY KEY")])
    }

    @Test("Verification fails when AUTOINCREMENT is used with a non-integer column")
    func verificationFailsWhenAutoIncrementIsUsedWithNonIntegerColumn() throws {
        let constraint = PrimaryKeyColumnConstraint(autoIncrement: true)
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: String.self))

        try #require(validation.warnings.count == 1)
        let warning = validation.warnings.first!
        #expect(warning.issue == .autoIncrementOnNonInteger)
        #expect(warning.path == [.constraint(nil, type: "PRIMARY KEY")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int?.self)
            .primaryKey(
                order: .descending,
                onConflict: .abort,
                autoIncrement: true,
                constraintName: "constraint"
            )

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! PrimaryKeyColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.order == .descending)
        #expect(constraint.onConflict == .abort)
        #expect(constraint.autoIncrement == true)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" PRIMARY KEY DESC ON CONFLICT ABORT AUTOINCREMENT
        """)
    }
}
