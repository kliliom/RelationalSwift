//
//  Connection+ExtTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

@Table("test_table") private struct TestEntry {
    @Column("id", primaryKey: true) var id: Int
    @Column("name") var name: String
}

@Suite("Connection Extension Tests")
struct ConnectionExtTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.exec("""
        CREATE TABLE test_table (
            id INTEGER PRIMARY KEY NOT NULL,
            name CHAR(255)
        )
        """)
        try await db.exec("INSERT INTO test_table (name) VALUES ('a'), ('b'), ('c')")
    }

    @Test("db.exec(_:)")
    func exec() async throws {
        try await db.exec("UPDATE test_table SET name = 'a2' WHERE id = 1")

        let rows = try await db.query("SELECT name FROM test_table", columns: TestEntry.table.name)
        #expect(rows == ["a2", "b", "c"])
    }

    @Test("db.exec(_:bind:)")
    func execBind() async throws {
        try await db.exec(
            "UPDATE test_table SET name = 'a2' WHERE id = ?",
            bind: 1
        )

        let rows = try await db.query(
            "SELECT name FROM test_table",
            columns: TestEntry.table.name
        )
        #expect(rows == ["a2", "b", "c"])
    }

    @Test("db.query(_:columns:)")
    func queryColumns() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table",
            columns: TestEntry.table.id, TestEntry.table.name
        )
        #expect(rows.map(\.0) == [1, 2, 3])
        #expect(rows.map(\.1) == ["a", "b", "c"])
    }

    @Test("db.query(_:binder:columns:)")
    func queryBinderColumns() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            binder: { try Int.bind(to: $0, value: 1, at: &$1) },
            columns: TestEntry.table.id, TestEntry.table.name
        )
        #expect(rows.map(\.0) == [1])
        #expect(rows.map(\.1) == ["a"])
    }

    @Test("db.query(_:bind:columns:)")
    func queryBindColumns() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            bind: 1,
            columns: TestEntry.table.id, TestEntry.table.name
        )
        #expect(rows.map(\.0) == [1])
        #expect(rows.map(\.1) == ["a"])
    }

    @Test("db.query(_:columns:builder:)")
    func queryColumnsBuilder() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table",
            columns: TestEntry.table.id, TestEntry.table.name,
            builder: { "\($0)-\($1)" }
        )
        #expect(rows == ["1-a", "2-b", "3-c"])
    }

    @Test("db.query(_:binder:columns:builder:)")
    func queryBinderColumnsBuilder() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            binder: { try Int.bind(to: $0, value: 1, at: &$1) },
            columns: TestEntry.table.id, TestEntry.table.name,
            builder: { "\($0)-\($1)" }
        )
        #expect(rows == ["1-a"])
    }

    @Test("db.query(_:bind:columns:builder:)")
    func queryBindColumnsBuilder() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            bind: 1,
            columns: TestEntry.table.id, TestEntry.table.name,
            builder: { "\($0)-\($1)" }
        )
        #expect(rows == ["1-a"])
    }

    @Test("db.query(_:binder:step:)")
    func queryBinderStep() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            binder: { try Int.bind(to: $0, value: 1, at: &$1) },
            step: {
                var index = ManagedIndex()
                let id = try Int.column(of: $0, at: &index)
                let name = try String.column(of: $0, at: &index)
                return "\(id)-\(name)"
            }
        )
        #expect(rows == ["1-a"])
    }

    @Test("db.query(_:bind:step:)")
    func queryBindStep() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id = ?",
            bind: 1,
            step: {
                var index = ManagedIndex()
                let id = try Int.column(of: $0, at: &index)
                let name = try String.column(of: $0, at: &index)
                return "\(id)-\(name)"
            }
        )
        #expect(rows == ["1-a"])
    }
}
