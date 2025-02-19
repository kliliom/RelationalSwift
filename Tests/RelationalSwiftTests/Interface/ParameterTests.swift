//
//  ParameterTests.swift
//

import Testing

import RelationalSwift

@Table private struct TestEntry {
    @Column var a: Int
    @Column var b: Int?
}

@Suite("Parameter Tests")
struct ParameterTests {
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

    @Test("Parameter write")
    func parameterWrite() async throws {
        let t = TestEntry.table
        let p = Parameter(1)
        let query = query("SELECT \(t.b) FROM \(t) WHERE \(t.a) = \(p)") { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }

        #expect(Parameter<Int>.detaultSQLStorageType == "INTEGER")

        var rows: [Int]
        rows = try await db.run(query)
        #expect(rows == [1])

        await p.update(2)
        rows = try await db.run(query)
        #expect(rows == [2, 3])

        await p.update(3)
        rows = try await db.run(query)
        #expect(rows == [4, 5, 6])
    }

    @Test("Parameter read")
    func parameterRead() async throws {
        let t = TestEntry.table
        let p = Parameter(1)
        let query = query("SELECT \(p) FROM \(t)") { stmt, index, _ in
            try Parameter<Int>.column(of: stmt, at: &index)
        }

        #expect(await p.value() == 1)
        await #expect(throws: RelationalSwiftError.unsupportedOperation) {
            try await db.run(query)
        }
        await #expect(throws: RelationalSwiftError.unsupportedOperation) {
            try await p.asSQLLiteral()
        }
    }
}
