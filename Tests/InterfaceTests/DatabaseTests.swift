//
//  DatabaseTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3
import Testing

@testable import Interface

@Suite("Database Tests")
struct DatabaseTests {
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

        await #expect(throws: InterfaceError.notAFileURL) {
            _ = try await Database.open(url: URL(string: "https://www.google.com")!)
        }
    }

    @Test("Last inserted row id")
    func lastInsertedRowID() async throws {
        let db = try await Database.openInMemory()

        try #expect(await db.lastInsertedRowID {
            try db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        } == nil)

        try #expect(await db.lastInsertedRowID {
            try db.exec("INSERT INTO x (id) VALUES (1)")
        } == 1)

        try #expect(await db.lastInsertedRowID {
            try db.exec("INSERT INTO x (id) VALUES (2) ON CONFLICT(id) DO NOTHING")
        } == 2)

        try #expect(await db.lastInsertedRowID {
            try db.exec("INSERT INTO x (id) VALUES (2) ON CONFLICT(id) DO NOTHING")
        } == nil)
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

        var rows = try await db.query("SELECT id FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }
        #expect(rows == [1])

        await #expect(throws: SomeError()) {
            try await db.transaction(kind: .deferred) {
                try db.exec("DELETE FROM x")
                throw SomeError()
            }
        }

        rows = try await db.query("SELECT id FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }
        #expect(rows == [1])

        rows = try await db.transaction(kind: .deferred) {
            try db.exec("INSERT INTO x (id) VALUES (2)")
            return try db.query("SELECT id FROM x") { stmt, _ in
                try Int.column(of: stmt, at: 0)
            }
        }
        #expect(rows == [1, 2])

        rows = try await db.query("SELECT id FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }
        #expect(rows == [1, 2])
    }

    @Test("Cached")
    func cached() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")

        let insertStmt = "INSERT INTO x (id) VALUES (?)"
        try await db.exec(insertStmt, binding: 1)
        try await db.cached {
            try db.exec(insertStmt, binding: 2)
            try db.exec(insertStmt, binding: 3)
        }

        let rows = try await db.query("SELECT id FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }
        #expect(rows == [1, 2, 3])

        let deleteStmt = "DELETE FROM x LIMIT 1"
        try await db.exec(deleteStmt)
        try await db.cached {
            try db.exec(deleteStmt)
            try db.exec(deleteStmt)
        }

        // We can use exec here because we expect no rows to be returned.
        try await db.exec("SELECT id FROM x")
    }

    @Test("Direct Access")
    func directAccess() async throws {
        let db = try await Database.openInMemory()

        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")

        try await db.directAccess { ptr in
            var stmt: OpaquePointer?
            var result = sqlite3_prepare_v2(ptr, "INSERT INTO x (id) VALUES (?)", -1, &stmt, nil)
            try #require(result == SQLITE_OK)

            defer { sqlite3_finalize(stmt) }

            result = sqlite3_bind_int(stmt, 1, 1)
            try #require(result == SQLITE_OK)

            result = sqlite3_step(stmt)
            try #require(result == SQLITE_DONE)
        }

        let rows = try await db.query("SELECT id FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }

        #expect(rows == [1])
    }
}
