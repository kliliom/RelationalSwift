//
//  UpdateBuilderTests.swift
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

@Suite("Update Builder Tests")
struct UpdateBuilderTests {
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

    @Test("Update all")
    func updateAll() async throws {
        let builder = UpdateBuilder(
            from: "t",
            setters: [
                ColumnValueSetter(
                    columnName: "x",
                    valueBinder: { stmt, index in try 1.bind(to: stmt, at: &index) }
                ),
            ],
            condition: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "UPDATE t SET x = ?")

        try await db.exec(
            statement,
            bind: { stmt in var index = ManagedIndex(); try binder(stmt, &index) }
        )
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows.allSatisfy { $0.x == 1 })
    }

    @Test("Update with condition")
    func updateWithCondition() async throws {
        let builder = UpdateBuilder(
            from: "t",
            setters: [
                ColumnValueSetter(
                    columnName: "x",
                    valueBinder: { stmt, index in try 1.bind(to: stmt, at: &index) }
                ),
            ],
            condition: Condition(sql: "x > ?", binder: { try Int.bind(to: $0, value: 3, at: &$1) })
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "UPDATE t SET x = ? WHERE x > ?")

        try await db.exec(
            statement,
            bind: { stmt in var index = ManagedIndex(); try binder(stmt, &index) }
        )
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows.allSatisfy { $0.x == 1 })
    }

    @Test("Update multiple columns with condition")
    func updateMultipleColumnsWithCondition() async throws {
        let builder = UpdateBuilder(
            from: "t",
            setters: [
                ColumnValueSetter(
                    columnName: "x",
                    valueBinder: { stmt, index in try 1.bind(to: stmt, at: &index) }
                ),
                ColumnValueSetter(
                    columnName: "y",
                    valueBinder: { stmt, index in try 2.bind(to: stmt, at: &index) }
                ),
            ],
            condition: Condition(sql: "x > ?", binder: { try Int.bind(to: $0, value: 3, at: &$1) })
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "UPDATE t SET x = ? , y = ? WHERE x > ?")

        try await db.exec(
            statement,
            bind: { stmt in var index = ManagedIndex(); try binder(stmt, &index) }
        )
        let rows = try await db.from(TestEntry.table).select()
        #expect(rows.allSatisfy { $0.x == 1 })
        #expect(rows.allSatisfy { $0.y == 2 })
    }
}
