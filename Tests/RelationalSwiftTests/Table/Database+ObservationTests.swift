//
//  Database+ObservationTests.swift
//

import Testing

@testable import RelationalSwift

@Table("test_table") private struct TestEntry: Equatable {
    @Column("id", primaryKey: true, insert: false) var id: Int
    @Column("name") var name: String
}

@Suite("Database Observation Tests")
struct DatabaseObservationTests {
    var db: Database!

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
    }

    @Test("Table observation sends initial event - empty array")
    mutating func tableObservationInitialEventEmptyArray() async throws {
        let collector = try await collectTable()
        db = nil
        try #require(await collector.value == [
            [],
        ])
    }

    @Test("Table observation sends initial event - existing entries")
    mutating func tableObservationInitialEventExistingEntries() async throws {
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        let collector = try await collectTable()
        db = nil
        try #require(await collector.value == [[TestEntry(id: 1, name: "Foo")]])
    }

    @Test("Table observation sends new entries")
    mutating func tableObservationNewEntries() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        try await db.insert(TestEntry(id: 1, name: "Bar"))
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
            [TestEntry(id: 1, name: "Foo"), TestEntry(id: 2, name: "Bar")],
        ])
    }

    @Test("Table observation sends updated entries")
    mutating func tableObservationUpdatedEntries() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        try await db.update(TestEntry(id: 1, name: "Bar"))
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
            [TestEntry(id: 1, name: "Bar")],
        ])
    }

    @Test("Table observation sends deleted entries")
    mutating func tableObservationDeletedEntries() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        try await db.delete(TestEntry(id: 1, name: "Foo"))
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
            [],
        ])
    }

    @Test("Table observation sends multiple events")
    mutating func tableObservationMultipleEvents() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        try await db.update(TestEntry(id: 1, name: "Bar"))
        try await db.insert(TestEntry(id: 0, name: "Baz"))
        try await db.delete(TestEntry(id: 2, name: "Baz"))
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
            [TestEntry(id: 1, name: "Bar")],
            [TestEntry(id: 1, name: "Bar"), TestEntry(id: 2, name: "Baz")],
            [TestEntry(id: 1, name: "Bar")],
        ])
    }

    @Test("Table observation can be cancelled")
    mutating func tableObservationCanBeCancelled() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        try await db.update(TestEntry(id: 1, name: "Bar"))
        try await db.insert(TestEntry(id: 0, name: "Baz"))
        try await db.delete(TestEntry(id: 2, name: "Baz"))
        collector.cancel()

        // Wait for cancellation to take effect
        _ = await collector.result

        // Test cleanup in service
        _ = try await Task { @DatabaseActor [db = db!] in
            let service = db.getService(ObservationService.self)
            try #require(service.tableObserverOrchestrators.isEmpty)
        }.value

        try await db.insert(TestEntry(id: 0, name: "Qux"))
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
            [TestEntry(id: 1, name: "Bar")],
            [TestEntry(id: 1, name: "Bar"), TestEntry(id: 2, name: "Baz")],
            [TestEntry(id: 1, name: "Bar")],
        ])
    }

    @Test("Table observation can be cancelled before first event")
    mutating func tableObservationCanBeCancelledBeforeFirstEvent() async throws {
        let collector = try await collectTable()
        collector.cancel()

        // Wait for cancellation to take effect
        _ = await collector.result

        try await db.insert(TestEntry(id: 0, name: "Foo"))
        db = nil
        try #require(await collector.value == [
            [],
        ])
    }

    @Test("Table observation batches changes in the same transaction")
    mutating func tableObservationBatchesChanges() async throws {
        let collector = try await collectTable()
        try await db.transaction {
            try db.insert(TestEntry(id: 0, name: "Foo"))
            try db.update(TestEntry(id: 1, name: "Bar"))
            try db.insert(TestEntry(id: 0, name: "Baz"))
            try db.delete(TestEntry(id: 2, name: "Baz"))
        }
        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Bar")],
        ])
    }

    @Test("Table observation ignores changes of rolled back transactions")
    mutating func tableObservationIgnoresRolledBackTransactions() async throws {
        let collector = try await collectTable()
        try? await db.transaction {
            try db.insert(TestEntry(id: 0, name: "Foo"))
            try db.update(TestEntry(id: 1, name: "Bar"))
            try db.insert(TestEntry(id: 0, name: "Baz"))
            try db.delete(TestEntry(id: 2, name: "Baz"))
            throw RelationalSwiftError.aborted(message: "Rollback")
        }
        db = nil
        try #require(await collector.value == [
            [],
        ])
    }

    @Test("Table observation cleans up after service shutdown")
    mutating func tableObservationCleansUpAfterServiceShutdown() async throws {
        let collector = try await collectTable()
        try await db.insert(TestEntry(id: 0, name: "Foo"))
        await db.shutdownService(ObservationService.self)
        try await db.insert(TestEntry(id: 0, name: "Bar"))

        db = nil
        try #require(await collector.value == [
            [],
            [TestEntry(id: 1, name: "Foo")],
        ])
    }

    @Test("Row observation sends initial event - initial entry")
    mutating func rowObservationInitialEventEmptyArray() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
        ])
    }

    @Test("Row observation sends initial event - no initial entry")
    mutating func rowObservationInitialEventNoInitialEntry() async throws {
        await #expect(throws: RelationalSwiftError.rowNotFound) {
            try await collectRow(TestEntry(id: 0, name: "Foo"))
        }
    }

    @Test("Row observation sends updated entries")
    mutating func rowObservationUpdatedEntries() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try await db.update(TestEntry(id: 1, name: "Bar"))
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
            TestEntry(id: 1, name: "Bar"),
        ])
    }

    @Test("Row observation sends deleted entries")
    mutating func rowObservationDeletedEntries() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try await db.delete(TestEntry(id: 1, name: "Foo"))
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
            nil,
        ])
    }

    @Test("Row observation sends multiple events")
    mutating func rowObservationMultipleEvents() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try await db.update(TestEntry(id: 1, name: "Bar"))
        try await db.insert(TestEntry(id: 0, name: "Baz"))
        try await db.delete(TestEntry(id: 2, name: "Baz"))
        try await db.delete(TestEntry(id: 1, name: "Bar"))
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
            TestEntry(id: 1, name: "Bar"),
            nil,
        ])
    }

    @Test("Row observation can be cancelled")
    mutating func rowObservationCanBeCancelled() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try await db.update(TestEntry(id: 1, name: "Bar"))
        collector.cancel()

        // Wait for cancellation to take effect
        _ = await collector.result

        // Test cleanup in service
        _ = try await Task { @DatabaseActor [db = db!] in
            let service = db.getService(ObservationService.self)
            try #require(service.rowObserverOrchestrators.isEmpty)
        }.value

        try await db.insert(TestEntry(id: 0, name: "Baz"))
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
            TestEntry(id: 1, name: "Bar"),
        ])
    }

    @Test("Row observation can be cancelled before first event")
    mutating func rowObservationCanBeCancelledBeforeFirstEvent() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        collector.cancel()

        // Wait for cancellation to take effect
        _ = await collector.result

        try await db.update(TestEntry(id: 1, name: "Bar"))
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
        ])
    }

    @Test("Row observation batches changes in the same transaction")
    mutating func rowObservationBatchesChanges() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try await db.transaction {
            try db.update(TestEntry(id: 1, name: "1"))
            try db.update(TestEntry(id: 1, name: "2"))
            try db.update(TestEntry(id: 1, name: "Bar"))
            try db.insert(TestEntry(id: 0, name: "Baz"))
            try db.delete(TestEntry(id: 2, name: "Baz"))
        }
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
            TestEntry(id: 1, name: "Bar"),
        ])
    }

    @Test("Row observation ignores changes of rolled back transactions")
    mutating func rowObservationIgnoresRolledBackTransactions() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        try? await db.transaction {
            try db.update(TestEntry(id: 1, name: "Bar"))
            try db.insert(TestEntry(id: 0, name: "Baz"))
            try db.delete(TestEntry(id: 2, name: "Baz"))
            throw RelationalSwiftError.aborted(message: "Rollback")
        }
        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
        ])
    }

    @Test("Row observation cleans up after service shutdown")
    mutating func rowObservationCleansUpAfterServiceShutdown() async throws {
        var entry = TestEntry(id: 0, name: "Foo")
        try await db.insert(&entry)

        let collector = try await collectRow(entry)
        await db.shutdownService(ObservationService.self)
        try await db.update(TestEntry(id: 1, name: "Bar"))

        db = nil
        try #require(await collector.value == [
            TestEntry(id: 1, name: "Foo"),
        ])
    }
}

extension DatabaseObservationTests {
    private func collectTable() async throws -> Task<[[TestEntry]], Never> {
        let stream = try await db.observe(table: TestEntry.self)
        return Task {
            var entries = [[TestEntry]]()
            for await entry in stream {
                entries.append(entry)
            }
            return entries
        }
    }

    private func collectRow(_ row: TestEntry) async throws -> Task<[TestEntry?], Never> {
        let stream = try await db.observe(row: row)
        return Task {
            var entries = [TestEntry?]()
            for await entry in stream {
                entries.append(entry)
            }
            return entries
        }
    }
}
