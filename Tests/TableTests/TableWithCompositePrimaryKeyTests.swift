//
//  TableWithCompositePrimaryKeyTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

@Table("t") private struct TestEntry: Equatable {
    @Column(primaryKey: true) var id1: Int
    @Column(primaryKey: true) var id2: Int
    @Column var x: Int
    @Column var y: Int
    @Column(update: false) var z: Int
}

@Suite("Default Table Operations With Composite Primary Key Tests")
struct TableWithCompositePrimaryKeyTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
    }

    private var entry: TestEntry {
        TestEntry(id1: 1, id2: 2, x: 10, y: 20, z: 30)
    }

    @Test("Select")
    func read() async throws {
        try await db.insert(entry)
        let row: TestEntry? = try await db.select(byKey: (1, 2))

        #expect(row == entry)
    }

    @Test("Insert")
    func insert() async throws {
        try await db.insert(entry)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Update")
    func update() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        entry.z = 40
        try await db.update(entry)

        entry.z = 30
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Update and refresh")
    func updateAndRefresh() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        entry.z = 40
        try await db.update(&entry)

        #expect(entry.z == 30)
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Partial update")
    func partialUpdate() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        entry.y = 40
        try await db.update(entry, columns: \.x)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [TestEntry(id1: 1, id2: 2, x: 20, y: 20, z: 30)])
    }

    @Test("Partial update and refresh")
    func partialUpdateAndRefresh() async throws {
        var entry = entry
        try await db.insert(&entry)
        entry.x = 20
        entry.y = 40
        entry.z = 40
        try await db.update(&entry, columns: \.x)

        #expect(entry.z == 30)
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Update or insert")
    func upsert() async throws {
        var entry = entry
        try await db.upsert(entry)

        var rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])

        entry.x = 20
        entry.y = 40
        entry.z = 40
        try await db.upsert(entry)

        entry.z = 30
        rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Update or insert and refresh")
    func upsertAndRefresh() async throws {
        var entry = entry
        try await db.upsert(&entry)

        var rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])

        entry.x = 20
        entry.y = 40
        entry.z = 40
        try await db.upsert(&entry)

        #expect(entry.z == 30)
        rows = try await db.from(TestEntry.table).select()
        #expect(rows == [entry])
    }

    @Test("Delete")
    func delete() async throws {
        var entry = entry
        try await db.insert(&entry)
        try await db.delete(entry)

        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [])
    }
}
