//
//  ChangeTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct ChangeTests {
    @Test("Build block with changes")
    func buildBlockWithChanges() {
        let change1 = AlterTable("table").dropColumn("a")
        let change2 = AlterTable("table").dropColumn("b")
        let changes = ChangeBuilder.buildBlock(change1, change2)

        #expect(changes.count == 2)
        #expect((changes[0] as? DropColumn)?.columnName == "a")
        #expect((changes[1] as? DropColumn)?.columnName == "b")
    }
}
