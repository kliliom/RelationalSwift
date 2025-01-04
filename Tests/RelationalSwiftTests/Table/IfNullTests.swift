//
//  IfNullTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

@Table private struct TestEntry {
    @Column var x: Int?
}

@Suite("IFNULL Tests")
struct IfNullTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
        for row in [nil, 1, 2, 3] {
            try await db.insert(TestEntry(x: row))
        }
    }

    @Test("ifNull in where")
    func inWhere() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) == 2 }.select { $0.x }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) != 2 }.select { $0.x }
        #expect(rows == [nil, 1, 3])

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) < 2 }.select { $0.x }
        #expect(rows == [nil, 1])

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) <= 2 }.select { $0.x }
        #expect(rows == [nil, 1, 2])

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) > 2 }.select { $0.x }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.x.ifNull(then: 1) >= 2 }.select { $0.x }
        #expect(rows == [2, 3])
    }

    @Test("ifNull in select")
    func inSelect() async throws {
        let rows = try await db.from(TestEntry.table)
            .select { $0.x.ifNull(then: 10) }
        #expect(rows == [10, 1, 2, 3])
    }
}
