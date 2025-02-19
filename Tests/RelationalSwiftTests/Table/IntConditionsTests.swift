//
//  IntConditionsTests.swift
//

import Foundation
import Testing

import RelationalSwift

@Table private struct TestEntry {
    @Column var a: Int
    @Column var b: Int?
    @Column var y: Int
    @Column var z: Int?
    @Column var w: Int?
}

@Suite("Condition Tests: Int")
struct IntConditionsTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
        for row in [nil, 1, 2, 3] {
            try await db.insert(TestEntry(a: row ?? 0, b: row, y: 2, z: 2, w: nil))
        }
    }

    var value: Int { 2 }
    var optional: Int? { 2 }
    var null: Int? { nil }

    @Test("Equal to")
    func equalTo() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a == value }.select { $0.a }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.a == optional }.select { $0.a }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.a == null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a == $0.y }.select { $0.a }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.a == $0.z }.select { $0.a }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.a == $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b == value }.select { $0.b }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.b == optional }.select { $0.b }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.b == null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b == $0.y }.select { $0.b }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.b == $0.z }.select { $0.b }
        #expect(rows == [2])

        rows = try await db.from(TestEntry.table).where { $0.b == $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Not equal to")
    func notEqualTo() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a != value }.select { $0.a }
        #expect(rows == [0, 1, 3])

        rows = try await db.from(TestEntry.table).where { $0.a != optional }.select { $0.a }
        #expect(rows == [0, 1, 3])

        rows = try await db.from(TestEntry.table).where { $0.a != null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a != $0.y }.select { $0.a }
        #expect(rows == [0, 1, 3])

        rows = try await db.from(TestEntry.table).where { $0.a != $0.z }.select { $0.a }
        #expect(rows == [0, 1, 3])

        rows = try await db.from(TestEntry.table).where { $0.a != $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b != value }.select { $0.b }
        #expect(rows == [1, 3])

        rows = try await db.from(TestEntry.table).where { $0.b != optional }.select { $0.b }
        #expect(rows == [1, 3])

        rows = try await db.from(TestEntry.table).where { $0.b != null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b != $0.y }.select { $0.b }
        #expect(rows == [1, 3])

        rows = try await db.from(TestEntry.table).where { $0.b != $0.z }.select { $0.b }
        #expect(rows == [1, 3])

        rows = try await db.from(TestEntry.table).where { $0.b != $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Less than")
    func lessThan() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a < value }.select { $0.a }
        #expect(rows == [0, 1])

        rows = try await db.from(TestEntry.table).where { $0.a < optional }.select { $0.a }
        #expect(rows == [0, 1])

        rows = try await db.from(TestEntry.table).where { $0.a < null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a < $0.y }.select { $0.a }
        #expect(rows == [0, 1])

        rows = try await db.from(TestEntry.table).where { $0.a < $0.z }.select { $0.a }
        #expect(rows == [0, 1])

        rows = try await db.from(TestEntry.table).where { $0.a < $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b < value }.select { $0.b }
        #expect(rows == [1])

        rows = try await db.from(TestEntry.table).where { $0.b < optional }.select { $0.b }
        #expect(rows == [1])

        rows = try await db.from(TestEntry.table).where { $0.b < null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b < $0.y }.select { $0.b }
        #expect(rows == [1])

        rows = try await db.from(TestEntry.table).where { $0.b < $0.z }.select { $0.b }
        #expect(rows == [1])

        rows = try await db.from(TestEntry.table).where { $0.b < $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Less than or equal to")
    func lessThanOrEqualTo() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a <= value }.select { $0.a }
        #expect(rows == [0, 1, 2])

        rows = try await db.from(TestEntry.table).where { $0.a <= optional }.select { $0.a }
        #expect(rows == [0, 1, 2])

        rows = try await db.from(TestEntry.table).where { $0.a <= null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a <= $0.y }.select { $0.a }
        #expect(rows == [0, 1, 2])

        rows = try await db.from(TestEntry.table).where { $0.a <= $0.z }.select { $0.a }
        #expect(rows == [0, 1, 2])

        rows = try await db.from(TestEntry.table).where { $0.a <= $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b <= value }.select { $0.b }
        #expect(rows == [1, 2])

        rows = try await db.from(TestEntry.table).where { $0.b <= optional }.select { $0.b }
        #expect(rows == [1, 2])

        rows = try await db.from(TestEntry.table).where { $0.b <= null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b <= $0.y }.select { $0.b }
        #expect(rows == [1, 2])

        rows = try await db.from(TestEntry.table).where { $0.b <= $0.z }.select { $0.b }
        #expect(rows == [1, 2])

        rows = try await db.from(TestEntry.table).where { $0.b <= $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Greater than")
    func greaterThan() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a > value }.select { $0.a }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.a > optional }.select { $0.a }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.a > null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a > $0.y }.select { $0.a }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.a > $0.z }.select { $0.a }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.a > $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b > value }.select { $0.b }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.b > optional }.select { $0.b }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.b > null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b > $0.y }.select { $0.b }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.b > $0.z }.select { $0.b }
        #expect(rows == [3])

        rows = try await db.from(TestEntry.table).where { $0.b > $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Greater than or equal")
    func greaterThanOrEqualTo() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.a >= value }.select { $0.a }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.a >= optional }.select { $0.a }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.a >= null }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.a >= $0.y }.select { $0.a }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.a >= $0.z }.select { $0.a }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.a >= $0.w }.select { $0.a }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b >= value }.select { $0.b }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.b >= optional }.select { $0.b }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.b >= null }.select { $0.b }
        #expect(rows == [])

        rows = try await db.from(TestEntry.table).where { $0.b >= $0.y }.select { $0.b }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.b >= $0.z }.select { $0.b }
        #expect(rows == [2, 3])

        rows = try await db.from(TestEntry.table).where { $0.b >= $0.w }.select { $0.b }
        #expect(rows == [])
    }

    @Test("Is null")
    func isNull() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.b.isNull() }.select { $0.b }
        #expect(rows == [nil])
    }

    @Test("Is not null")
    func isNotNull() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table).where { $0.b.isNotNull() }.select { $0.b }
        #expect(rows == [1, 2, 3])
    }

    @Test("In elements")
    func inElements() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table)
            .where { $0.b.in(1, 2, 3) }
            .select { $0.b }
        #expect(rows == [1, 2, 3])
    }

    @Test("In query")
    func inQuery() async throws {
        var rows: [Int?]

        rows = try await db.from(TestEntry.table)
            .where { try $0.a.in(db.from(TestEntry.table(as: "sub")).query { $0.y }) }
            .select { $0.a }
        #expect(rows == [2])
    }
}
