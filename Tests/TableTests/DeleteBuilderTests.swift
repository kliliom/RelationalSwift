//
//  DeleteBuilderTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift
@testable import Table

@Table("t") private struct TestEntry: Equatable {
    @Column var x: Int
    @Column var y: Int
    @Column var z: Int
}

@Suite("Delete Builder Tests")
struct DeleteBuilderTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.exec("""
        CREATE TABLE t (
            x INTEGER,
            y INTEGER,
            z INTEGER
        )
        """)
        try await db.exec("INSERT INTO t (x, y, z) VALUES (1, 2, 3), (4, 5, 6), (7, 8, 9)")
    }

    @Test("Delete all")
    func deleteAll() async throws {
        let builder = DeleteBuilder(
            from: "t",
            condition: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "DELETE FROM t")

        try await db.exec(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) }
        )
        try await #expect(db.from(TestEntry.table).select().isEmpty)
    }

    @Test("Delete with condition")
    func deleteWithCondition() async throws {
        let builder = DeleteBuilder(
            from: "t",
            condition: Condition(sql: "x > ?", binder: { try Int.bind(to: $0, value: 3, at: &$1) })
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "DELETE FROM t WHERE x > ?")

        try await db.exec(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) }
        )
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows == [TestEntry(x: 1, y: 2, z: 3)])
    }
}
