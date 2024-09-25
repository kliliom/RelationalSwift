//
//  OperatorConditionsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

@Table private struct TestEntry {
    @Column var x: Int
}

@Suite("Condition Tests: Logic Operations")
struct OperatorConditionsTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
        for row in [1, 2, 3] {
            try await db.insert(TestEntry(x: row))
        }
    }

    @Test("AND operator")
    func andOperator() async throws {
        let rows = try await db.from(TestEntry.table)
            .where { $0.x <= 2 && $0.x >= 2 }
            .select { $0.x }
        #expect(rows == [2])
    }

    @Test("OR operator")
    func orOperator() async throws {
        let rows = try await db.from(TestEntry.table)
            .where { $0.x == 1 || $0.x == 3 }
            .select { $0.x }
        #expect(rows == [1, 3])
    }

    @Test("NOT operator")
    func notOperator() async throws {
        let rows = try await db.from(TestEntry.table)
            .where { !($0.x == 2) }
            .select { $0.x }
        #expect(rows == [1, 3])
    }
}
