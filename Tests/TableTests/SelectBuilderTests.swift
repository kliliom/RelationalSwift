//
//  SelectBuilderTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift
@testable import Table

@Table("t") private struct TestEntry {
    @Column var x: Int
    @Column var y: Int
    @Column var z: Int
}

@Suite("Select Builder Tests")
struct SelectBuilderTests {
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

    @Test("Single column")
    func selectSingleColumn() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x"],
            condition: nil,
            limit: nil,
            offset: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x FROM t")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in var index = Int32(); return try Int.column(of: stmt, at: &index) }
        )
        #expect(rows == [1, 4, 7])
    }

    @Test("Multiple columns")
    func selectMultipleColumns() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x", "z"],
            condition: nil,
            limit: nil,
            offset: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x, z FROM t")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in
                var index = Int32()
                return try Int.column(of: stmt, at: &index) + Int.column(of: stmt, at: &index)
            }
        )
        #expect(rows == [4, 10, 16])
    }

    @Test("Single column with condition")
    func selectSingleColumnWithCondition() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x"],
            condition: Condition(sql: "x > ?", binder: { try Int.bind(to: $0, value: 3, at: &$1) }),
            limit: nil,
            offset: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x FROM t WHERE x > ?")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in var index = Int32(); return try Int.column(of: stmt, at: &index) }
        )
        #expect(rows == [4, 7])
    }

    @Test("Single column with limit")
    func selectSingleColumnWithLimit() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x"],
            condition: nil,
            limit: 2,
            offset: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x FROM t LIMIT ?")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in var index = Int32(); return try Int.column(of: stmt, at: &index) }
        )
        #expect(rows == [1, 4])
    }

    @Test("Single column with offset")
    func selectSingleColumnWithOffset() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x"],
            condition: nil,
            limit: nil,
            offset: 2
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x FROM t LIMIT -1 OFFSET ?")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in var index = Int32(); return try Int.column(of: stmt, at: &index) }
        )
        #expect(rows == [7])
    }

    @Test("Single column with limit and offset")
    func selectSingleColumnWithLimitAndOffset() async throws {
        let builder = SelectBuilder(
            from: "t",
            columns: ["x"],
            condition: nil,
            limit: 1,
            offset: 1
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT x FROM t LIMIT ? OFFSET ?")

        let rows = try await db.query(
            statement,
            bind: { stmt in var index = Int32(); try binder(stmt, &index) },
            step: { stmt, _ in var index = Int32(); return try Int.column(of: stmt, at: &index) }
        )
        #expect(rows == [4])
    }
}
