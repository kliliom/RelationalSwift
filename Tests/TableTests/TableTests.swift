//
//  TableTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

@Table("t") private struct TestEntry: Equatable {
    @Column(primaryKey: true) var id: Int
    @Column var x: Int
    @Column var y: Int
}

@Suite("Default Table Operations With Primary Key Tests")
struct TableTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
    }

    private var entry: TestEntry {
        TestEntry(id: 1, x: 10, y: 20)
    }

    @Test("Supported insert")
    func insert() async throws {
        try await db.insert(entry)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Supported update")
    func update() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        try await db.update(entry)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Supported partial update")
    func partialUpdate() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        entry.y = 40
        try await db.update(entry, columns: \.x)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [TestEntry(id: 1, x: 20, y: 20)])
    }

    @Test("Supported delete")
    func delete() async throws {
        var entry = entry
        try await db.insert(&entry)
        try await db.delete(entry)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [])
    }
}
