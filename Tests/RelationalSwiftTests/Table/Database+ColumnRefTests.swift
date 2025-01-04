//
//  Database+ColumnRefTests.swift
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

    @Test("Query statement with ManagedBinder")
    func queryWithManagedBinder() async throws {
        let rows = try await db.query(
            "SELECT id, name FROM test_table WHERE id < ?",
            columns: TestEntry.table.id, TestEntry.table.name
        ) { stmt, index in
            try 10.bind(to: stmt, at: &index)
        }
        #expect(rows.map(\.0) == [1, 2, 3])
        #expect(rows.map(\.1) == ["a", "b", "c"])
    }
}
