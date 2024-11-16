//
//  DatabaseTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

@testable import Interface

@Suite("Database Tests")
struct DatabaseTests {
    @Test("db.prepare(statement:) throws")
    func prepare() async throws {
        let db = try await Database.openInMemory()
        let stmt = try await db.prepare(statement: "CREATE TABLE x (id INTEGER PRIMARY KEY)")

        // Deinit must be called on global executor
        await Global.shared.run { [stmt = consume stmt] in
            _ = stmt
        }

        await #expect(throws: InterfaceError(message: "nil handle while sqlite3_prepare_v2 == SQLITE_OK", code: -1)) {
            _ = try await db.prepare(statement: "")
        }
    }

    @Test("db.exec(_:) throws")
    func execWithDefaultParameters() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
    }

    @Test("db.exec(_:bind:{ stmt in })")
    func execBindBlock() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")
        try await db.exec(
            "UPDATE x SET id = 2 WHERE id = ?",
            bind: { stmt in
                try Int.bind(to: stmt, value: 1, at: 1)
            }
        )

        let rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [2])
    }

    @Test("db.exec(_:bind:...)")
    func execBindValue() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")
        try await db.exec(
            "UPDATE x SET id = 2 WHERE id = ?",
            bind: 1
        )

        let rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [2])
    }

    @Test("db.exec(_:binder:)")
    func execBinder() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")
        try await db.exec(
            "UPDATE x SET id = 2 WHERE id = ?",
            binder: { stmt, index in
                try Int.bind(to: stmt, value: 1, at: &index)
            }
        )

        let rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [2])
    }

    @Test("db.query(_:bind:step:) throws")
    func query() async throws {
        let db = try await Database.openInMemory()
        let bindCount = Counter()
        let stepCount = Counter()

        _ = try await db.query(
            "SELECT * FROM (VALUES (1), (2), (3))",
            bind: { _ in
                bindCount.increment()
            }, step: { _, _ in
                stepCount.increment()
            }
        )
        #expect(bindCount.value == 1)
        #expect(stepCount.value == 3)
    }

    @Test("db.query(_:bind:step:) throws + stop")
    func queryWithStop() async throws {
        let db = try await Database.openInMemory()
        let bindCount = Counter()
        let stepCount = Counter()

        _ = try await db.query(
            "SELECT * FROM (VALUES (1), (2), (3))",
            bind: { _ in
                bindCount.increment()
            }, step: { _, stop in
                stepCount.increment()
                if stepCount.value == 2 {
                    stop = true
                }
            }
        )
        #expect(bindCount.value == 1)
        #expect(stepCount.value == 2)
    }

    @Test("db.query(_:) throws")
    func queryWithDefaultParameters() async throws {
        let db = try await Database.openInMemory()

        _ = try await db.query("SELECT * FROM (VALUES (1), (2), (3))")
    }

    @Test("Database.openInMemory() async throws")
    func openInMemory() async throws {
        _ = try await Database.openInMemory()
    }

    @Test("Database.open(url:) async throws")
    func openURL() async throws {
        let url = if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            URL(filePath: NSTemporaryDirectory()).appending(component: UUID().uuidString)
        } else {
            URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        }
        _ = try await Database.open(url: url)

        await #expect(throws: InterfaceError(message: "can not open non-file url", code: -1)) {
            _ = try await Database.open(url: URL(string: "https://www.google.com")!)
        }
    }

    @Test("Last inserted row id")
    func lastInsertedRowID() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")

        await db.clearLastInsertedRowID()
        #expect(await db.lastInsertedRowID() == nil)

        try await db.exec("INSERT INTO x (id) VALUES (1)")
        #expect(await db.lastInsertedRowID() != nil)
    }

    @Test("Transaction", arguments: [
        TransactionKind.deferred,
        TransactionKind.immediate,
        TransactionKind.exclusive,
    ])
    func deferredTransaction(kind: TransactionKind) async throws {
        struct SomeError: Error, Equatable {}

        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")

        try await db.transaction(kind: kind) {
            try db.exec("INSERT INTO x (id) VALUES (1)")
        }

        var rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [1])

        await #expect(throws: SomeError()) {
            try await db.transaction(kind: .deferred) {
                try db.exec("DELETE FROM x")
                throw SomeError()
            }
        }

        rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [1])

        rows = try await db.transaction(kind: .deferred) {
            try db.exec("INSERT INTO x (id) VALUES (2)")
            return try db.query(
                "SELECT id FROM x",
                step: { stmt, _ in try Int.column(of: stmt, at: 0) }
            )
        }
        #expect(rows == [1, 2])

        rows = try await db.query(
            "SELECT id FROM x",
            step: { stmt, _ in try Int.column(of: stmt, at: 0) }
        )
        #expect(rows == [1, 2])
    }
}
