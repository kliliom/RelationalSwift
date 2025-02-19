//
//  ForeignKeyColumnConstraintTests.swift
//

import Testing

@testable import RelationalSwift

@Suite
struct ForeignKeyColumnConstraintTests {
    @Test("Has no constraint name")
    func hasNoConstraintName() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == nil)
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        REFERENCES "table"
        """)
    }

    @Test("Has constraint name")
    func hasConstraintName() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == nil)
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" REFERENCES "table"
        """)
    }

    @Test("Has no foreign columns")
    func hasNoForeignColumns() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == nil)
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        REFERENCES "table"
        """)
    }

    @Test("Has one foreign column")
    func hasOneForeignColumn() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            column: "column"
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == "column")
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        REFERENCES "table" ( "column" )
        """)
    }

    @Test("Has ON UPDATE action")
    func hasOnUpdateAction() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            column: "column",
            onUpdate: .cascade
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == "column")
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == nil)
        #expect(constraint.builtSQL == """
        REFERENCES "table" ( "column" ) ON UPDATE CASCADE
        """)
    }

    @Test("Has ON DELETE action")
    func hasOnDeleteAction() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            column: "column",
            onDelete: .cascade
        )

        #expect(constraint.constraintName == nil)
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == "column")
        #expect(constraint.onUpdate == nil)
        #expect(constraint.onDelete == .cascade)
        #expect(constraint.builtSQL == """
        REFERENCES "table" ( "column" ) ON DELETE CASCADE
        """)
    }

    @Test("Has all")
    func hasAll() {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            column: "column1",
            onUpdate: .cascade,
            onDelete: .restrict,
            constraintName: "constraint"
        )

        #expect(constraint.constraintName == "constraint")
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == "column1")
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == .restrict)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" REFERENCES "table" ( "column1" ) ON UPDATE CASCADE ON DELETE RESTRICT
        """)
    }

    @Test("Validation fails if constraint name is empty")
    func validationFailsIfConstraintNameIsEmpty() throws {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            constraintName: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .constraintNameEmpty)
        #expect(error.path == [.constraint("", type: "FOREIGN KEY")])
    }

    @Test("Validation fails if foreign column is empty")
    func validationFailsIfForeignColumnIsEmpty() throws {
        let constraint = ForeignKeyColumnConstraint(
            referencing: "table",
            column: ""
        )
        let validation = Validation()
        constraint.validate(in: validation, column: Column("column", ofType: Int.self))

        try #require(validation.errors.count == 1)
        let error = validation.errors.first!
        #expect(error.issue == .columnNameEmpty)
        #expect(error.path == [.constraint(nil, type: "FOREIGN KEY")])
    }

    @Test("Convenience method on Column")
    func convenienceMethodOnColumn() throws {
        let column = Column("column", ofType: Int?.self)
            .foreignKey(
                referencing: "table",
                column: "column1",
                onUpdate: .cascade,
                onDelete: .restrict,
                constraintName: "constraint"
            )

        try #require(column.constraints.count == 1)
        let constraint = column.constraints.first as! ForeignKeyColumnConstraint
        #expect(constraint.constraintName == "constraint")
        #expect(constraint.foreignTable == "table")
        #expect(constraint.foreignColumn == "column1")
        #expect(constraint.onUpdate == .cascade)
        #expect(constraint.onDelete == .restrict)
        #expect(constraint.builtSQL == """
        CONSTRAINT "constraint" REFERENCES "table" ( "column1" ) ON UPDATE CASCADE ON DELETE RESTRICT
        """)
    }
}
