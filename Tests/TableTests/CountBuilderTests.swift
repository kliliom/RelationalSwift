//
//  CountBuilderTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift
@testable import Table

@Table("t") private struct TestEntry {
    @Column var x: Int?
}

@Suite("Count Builder Tests")
struct CountBuilderTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.exec("""
        CREATE TABLE t (
            x INTEGER
        )
        """)
        try await db.exec("INSERT INTO t (x) VALUES (1), (1), (7)")
    }

    @Test("Count rows")
    func countRows() async throws {
        let builder = CountBuilder(
            from: "t",
            condition: nil
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT COUNT(*) FROM t")

        let count = try await db.query(statement) { stmt, index in
            try binder(stmt, &index)
        } stepper: { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }.first
        #expect(count == 3)
    }

    @Test("Count column")
    func countColunm() async throws {
        let builder = CountBuilder(
            from: "t",
            column: "x",
            condition: nil,
            distinct: false
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT COUNT(x) FROM t")

        let count = try await db.query(statement) { stmt, index in
            try binder(stmt, &index)
        } stepper: { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }.first
        #expect(count == 3)
    }

    @Test("Count column distinct")
    func countColunmDistinct() async throws {
        let table = TestEntry.table
        let builder = CountBuilder(
            from: table._sqlFrom,
            column: table.x.ifNull(then: 0),
            condition: nil,
            distinct: true
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT COUNT(DISTINCT IFNULL(\"t\".\"x\", ?)) FROM \"t\"")

        let count = try await db.query(statement) { stmt, index in
            try binder(stmt, &index)
        } stepper: { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }.first
        #expect(count == 2)
    }

    @Test("Count with condition")
    func selectSingleColumnWithCondition() async throws {
        let builder = CountBuilder(
            from: "t",
            column: "x",
            condition: Condition(sql: "x > ?", binder: { try Int.bind(to: $0, value: 3, at: &$1) }),
            distinct: false
        )

        let statement = try builder.statement()
        let binder = builder.binder

        #expect(statement == "SELECT COUNT(x) FROM t WHERE x > ?")

        let count = try await db.query(statement) { stmt, index in
            try binder(stmt, &index)
        } stepper: { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }.first
        #expect(count == 1)
    }
}
