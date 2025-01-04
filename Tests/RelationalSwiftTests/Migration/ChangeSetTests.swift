//
//  ChangeSetTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct ChangeSetTests {
    @Test("Build block with changes")
    func buildBlockWithChanges() {
        let change1 = AlterTable("table").dropColumn("a")
        let change2 = AlterTable("table").dropColumn("b")
        let changeSet = ChangeSet(id: "drop columns") {
            change1
            change2
        }

        #expect(changeSet.id == "drop columns")
        #expect(changeSet.changes.count == 2)
        #expect((changeSet.changes[0] as? DropColumn)?.columnName == "a")
        #expect((changeSet.changes[1] as? DropColumn)?.columnName == "b")
    }

    @Test("Validation combines issues")
    func validationCombinesIssues() throws {
        let changeSet = ChangeSet(id: "change set") {
            AlterTable("").dropColumn("")
            AlterTable("").dropColumn("")
        }
        let validation = Validation()
        changeSet.validate(in: validation)

        try #require(validation.errors.count == 4)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .columnNameEmpty)
        #expect(errors[2].issue == .tableNameEmpty)
        #expect(errors[3].issue == .columnNameEmpty)
        #expect(errors[0].path == [.changeSet("change set"), .alterTable("DROP COLUMN")])
        #expect(errors[1].path == [.changeSet("change set"), .alterTable("DROP COLUMN")])
        #expect(errors[2].path == [.changeSet("change set"), .alterTable("DROP COLUMN")])
        #expect(errors[3].path == [.changeSet("change set"), .alterTable("DROP COLUMN")])
    }

    @Test("Apply changes")
    func applyChanges() async throws {
        let changeSet = ChangeSet(id: "change set") {
            CreateTable("test_table") {
                Column("column", ofType: Int.self)
            }
            AlterTable("test_table")
                .addColumn(Column("new_column", ofType: Int.self))
            AlterTable("test_table")
                .dropColumn("column")
        }

        let db = try await Database.openInMemory()
        try await changeSet.apply(to: db)

        let columns = try await db.query("PRAGMA table_info('test_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }

        #expect(columns.count == 1)
        #expect(columns[0] == "new_column")
    }
}
