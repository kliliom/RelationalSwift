//
//  ColumnTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

@testable import RelationalSwift

@Suite
struct ColumnTests {
    enum MyEnum: String {
        case a, b, c
    }

    @Test("Get default storage", arguments: [
        (Int.self, .integer),
        (Int32.self, .integer),
        (Int64.self, .integer),
        (Bool.self, .integer),
        (Float.self, .double),
        (Double.self, .double),
        (String.self, .text),
        (UUID.self, .blob),
        (Data.self, .blob),
        (Date.self, .double),
        (MyEnum.self, .text),
        (Int?.self, .integer),
        (Int32?.self, .integer),
        (Int64?.self, .integer),
        (Bool?.self, .integer),
        (Float?.self, .double),
        (Double?.self, .double),
        (String?.self, .text),
        (UUID?.self, .blob),
        (Data?.self, .blob),
        (Date?.self, .double),
        (MyEnum?.self, .text),
    ] as [(Any.Type, ColumnStorage)])
    func getDefaultStorage(argument: (Any.Type, ColumnStorage)) {
        #expect(Column.getDefaultStorage(for: argument.0) == argument.1)
    }

    @Test("NotNull constraint on non-optional types")
    func notNullConstraintOnNonOptionalTypes() {
        let column = Column("test", ofType: Int.self)

        #expect(column.constraints.count == 1)
        #expect(column.constraints[0] is NotNullColumnConstraint)
    }

    @Test("Missing NotNull constraint on optional types")
    func missingNotNullConstraintOnOptionalTypes() {
        let column = Column("test", ofType: Int?.self)

        #expect(column.constraints.count == 0)
    }

    @Test("Validation warning for missing NotNull constraint on non-optional types")
    func validationWarningForMissingNotNullConstraintOnNonOptionalTypes() throws {
        var column = Column("test", ofType: Int.self)
        column.constraints = []
        let validation = Validation()
        column.validate(in: validation)

        try #require(validation.warnings.count == 1)
        let warning = validation.warnings.first!
        #expect(warning.issue == .missingNotNullConstraintOnNonOptionalType)
        #expect(warning.path == [.column("test")])
    }

    @Test("Validation warning for NotNull constraint on optional types")
    func validationWarningForNotNullConstraintOnOptionalTypes() throws {
        var column = Column("test", ofType: Int?.self)
        column.constraints = [NotNullColumnConstraint()]
        let validation = Validation()
        column.validate(in: validation)

        try #require(validation.warnings.count == 1)
        let warning = validation.warnings.first!
        #expect(warning.issue == .notNullConstraintOnOptionalType)
        #expect(warning.path == [.column("test")])
    }

    @Test("Appending constraint")
    func appendingConstraint() {
        let column = Column("test", ofType: Int?.self)
        let newColumn = column.appending(NotNullColumnConstraint())
        let newColumn2 = newColumn.appending(NotNullColumnConstraint())

        #expect(newColumn.constraints.count == 1)
        #expect(newColumn2.constraints.count == 2)
    }

    @Test("Replacing or appending constraint")
    func replacingOrAppendingConstraint() {
        let column = Column("test", ofType: Int?.self)
        let newColumn = column.replacingOrAppending(NotNullColumnConstraint())
        let newColumn2 = newColumn.replacingOrAppending(NotNullColumnConstraint())

        #expect(newColumn.constraints.count == 1)
        #expect(newColumn2.constraints.count == 1)
    }

    @Test("Append to builder", arguments: [
        (Column("x", ofType: String.self), "\"x\" TEXT NOT NULL"),
        (Column("x", ofType: String?.self), "\"x\" TEXT"),
        (Column("x", ofType: String.self, storage: .varchar(length: 15)), "\"x\" VARCHAR(15) NOT NULL"),
        (Column("x\"", ofType: String.self), "\"x\"\"\" TEXT NOT NULL"),
    ] as [(Column, String)])
    func appendToBuilder(argument: (Column, String)) {
        let builder = SQLBuilder()
        argument.0.append(to: builder)

        #expect(builder.sql.joined(separator: " ") == argument.1)
    }
}
