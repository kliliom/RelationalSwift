//
//  SelectSourceTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

import RelationalSwift

@Table private struct TestEntry {
    @Column var a: Int
    @Column var b: Int?
}

@Suite("SelectSource Tests")
struct SelectSourceTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()

        try await db.createTable(for: TestEntry.self)
        try await db.insert(TestEntry(a: 1, b: 1))
        try await db.insert(TestEntry(a: 2, b: 2))
        try await db.insert(TestEntry(a: 2, b: 3))
        try await db.insert(TestEntry(a: 3, b: 4))
        try await db.insert(TestEntry(a: 3, b: 5))
        try await db.insert(TestEntry(a: 3, b: 6))
    }

    @Test("Multiple where clauses")
    func multipleWhereClauses() async throws {
        try await db.insert(TestEntry(a: 1, b: 2))

        var rows: [Int]
        rows = try await db.from(TestEntry.self)
            .where { $0.a == 1 }
            .where { $0.a == 2 }
            .select { $0.a }
        #expect(rows.count == 0)

        rows = try await db.from(TestEntry.self)
            .where { $0.a == 1 }
            .where { $0.b == 2 }
            .select { $0.a }
        #expect(rows.count == 1)
    }

    @Test("Select column from type")
    func selectColumnFromType() async throws {
        var rows: [Int]
        rows = try await db.from(TestEntry.self).where { $0.a == 1 }.select { $0.a }
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.self).where { $0.a == 2 }.select { $0.a }
        #expect(rows.count == 2)
        rows = try await db.from(TestEntry.self).where { $0.a == 3 }.select { $0.a }
        #expect(rows.count == 3)
    }

    @Test("Select column")
    func selectColumn() async throws {
        var rows: [Int]
        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select { $0.a }
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select { $0.a }
        #expect(rows.count == 2)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select { $0.a }
        #expect(rows.count == 3)
    }

    @Test("Select entry")
    func selectEntry() async throws {
        var rows: [TestEntry]
        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select()
        #expect(rows.count == 2)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select()
        #expect(rows.count == 3)
    }

    @Test("Select first")
    func selectFirst() async throws {
        var row: TestEntry?
        row = try await db.from(TestEntry.table).where { $0.a == 1 }.selectFirst()
        #expect(row?.b == 1)
        row = try await db.from(TestEntry.table).where { $0.a == 2 }.selectFirst()
        #expect(row?.b == 2)
        row = try await db.from(TestEntry.table).where { $0.a == 3 }.selectFirst()
        #expect(row?.b == 4)
        row = try await db.from(TestEntry.table).where { $0.a == 4 }.selectFirst()
        #expect(row == nil)
    }

    @Test("Select first column")
    func selectFirstColumn() async throws {
        var row: Int??
        row = try await db.from(TestEntry.table).where { $0.a == 1 }.selectFirst { $0.b }
        #expect(row == 1)
        row = try await db.from(TestEntry.table).where { $0.a == 2 }.selectFirst { $0.b }
        #expect(row == 2)
        row = try await db.from(TestEntry.table).where { $0.a == 3 }.selectFirst { $0.b }
        #expect(row == 4)
        row = try await db.from(TestEntry.table).where { $0.a == 4 }.selectFirst { $0.b }
        #expect(row == nil)
    }

    @Test("Update")
    func update() async throws {
        var rows: [TestEntry]
        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select()
        #expect(rows.count == 2)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select()
        #expect(rows.count == 3)

        try await db.from(TestEntry.table)
            .where { $0.a == 2 }
            .update(columns: \.a, values: 1)

        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 3)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select()
        #expect(rows.count == 0)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select()
        #expect(rows.count == 3)

        try await db.from(TestEntry.table)
            .update(columns: \.a, \.b, values: 1, 1)

        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 6)
        rows = try await db.from(TestEntry.table).where { $0.b == 1 }.select()
        #expect(rows.count == 6)
    }

    @Test("Delete")
    func delete() async throws {
        var rows: [TestEntry]
        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select()
        #expect(rows.count == 2)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select()
        #expect(rows.count == 3)

        try await db.from(TestEntry.table).where { $0.a == 2 }.delete()

        rows = try await db.from(TestEntry.table).where { $0.a == 1 }.select()
        #expect(rows.count == 1)
        rows = try await db.from(TestEntry.table).where { $0.a == 2 }.select()
        #expect(rows.count == 0)
        rows = try await db.from(TestEntry.table).where { $0.a == 3 }.select()
        #expect(rows.count == 3)
    }

    @Test("Count")
    func count() async throws {
        var count: Int64
        count = try await db.from(TestEntry.table).where { $0.a == 1 }.count()
        #expect(count == 1)
        count = try await db.from(TestEntry.table).where { $0.a == 2 }.count()
        #expect(count == 2)
        count = try await db.from(TestEntry.table).where { $0.a == 3 }.count()
        #expect(count == 3)
    }

    @Test("Count column")
    func countColumn() async throws {
        var count: Int64
        count = try await db.from(TestEntry.table).where { $0.a == 1 }.count { $0.a }
        #expect(count == 1)
        count = try await db.from(TestEntry.table).where { $0.a == 2 }.count { $0.a }
        #expect(count == 2)
        count = try await db.from(TestEntry.table).where { $0.a == 3 }.count { $0.a }
        #expect(count == 3)

        count = try await db.from(TestEntry.table).where { $0.a == 1 }.count(distinct: true) { $0.a }
        #expect(count == 1)
        count = try await db.from(TestEntry.table).where { $0.a == 2 }.count(distinct: true) { $0.a }
        #expect(count == 1)
        count = try await db.from(TestEntry.table).where { $0.a == 3 }.count(distinct: true) { $0.a }
        #expect(count == 1)
    }

    @Test("Order by")
    func orderBy() async throws {
        var rows: [TestEntry]

        rows = try await db.from(TestEntry.table).orderBy(asc: \.a).select()
        #expect(rows.map(\.a) == [1, 2, 2, 3, 3, 3])

        rows = try await db.from(TestEntry.table).orderBy { .asc($0.a) }.select()
        #expect(rows.map(\.a) == [1, 2, 2, 3, 3, 3])

        rows = try await db.from(TestEntry.table).orderBy(desc: \.a).orderBy(asc: \.b).select()
        #expect(rows.map(\.a) == [3, 3, 3, 2, 2, 1])
        #expect(rows.map(\.b) == [4, 5, 6, 2, 3, 1])

        rows = try await db.from(TestEntry.table).orderBy { .desc($0.a) }.orderBy { .asc($0.b) }.select()
        #expect(rows.map(\.a) == [3, 3, 3, 2, 2, 1])
        #expect(rows.map(\.b) == [4, 5, 6, 2, 3, 1])

        try await db.insert(TestEntry(a: 4, b: nil))
        rows = try await db.from(TestEntry.self).orderBy(asc: \.b, nullPosition: .first).select()
        #expect(rows.map(\.a) == [4, 1, 2, 2, 3, 3, 3])

        rows = try await db.from(TestEntry.self).orderBy(asc: \.b, nullPosition: .last).select()
        #expect(rows.map(\.a) == [1, 2, 2, 3, 3, 3, 4])
    }
}
