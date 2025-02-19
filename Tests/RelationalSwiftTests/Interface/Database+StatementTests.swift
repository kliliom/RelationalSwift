//
//  Database+StatementTests.swift
//

import Foundation
import Testing

@testable import RelationalSwift

@Suite("Database+Statement Prepare Tests")
struct DatabaseStatementPrepareTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
    }

    @Test("Prepare statement succeeds")
    func prepareSuccess() async throws {
        _ = try await db.prepare(statement: "PRAGMA table_info('x')")
    }

    @Test("Prepare statement fails with invalid SQL")
    func prepareFailsWithInvalidSQL() async throws {
        await #expect(throws: RelationalSwiftError.error(message: "near \"pickle\": syntax error")) {
            _ = try await db.prepare(statement: "pickle")
        }
    }

    @Test("Prepare statement fails with nil handle")
    func prepareFailsWithNilHandle() async throws {
        await #expect(throws: RelationalSwiftError.emptyStatement) {
            _ = try await db.prepare(statement: "")
        }
    }
}

@Suite("Database+Statement Binder/Stepper Tests")
struct DatabaseStatementBinderStepperTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
    }

    @Test("Exec statement with Binder")
    func execWithBinder() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)") { _ in
            // No-op
        }
        try await db.exec("INSERT INTO x (id) VALUES (?)") { stmt in
            try Int.bind(to: stmt, value: 1, at: 1)
        }
    }

    @Test("Exec statement without Binder")
    func execWithoutBinder() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")
    }

    @Test("Query statement with Binder/Stepper")
    func queryWithBinderStepper() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")

        let count = try await db.query("SELECT COUNT(*) FROM x WHERE id = ?") { stmt in
            try Int.bind(to: stmt, value: 1, at: 1)
        } stepper: { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }

        #expect(count == [1])
    }

    @Test("Query statement with Stepper")
    func queryWithStepper() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")

        let count = try await db.query("SELECT COUNT(*) FROM x") { stmt, _ in
            try Int.column(of: stmt, at: 0)
        }

        #expect(count == [1])
    }

    @Test("Query statement with Stepper and stop")
    func queryWithStepperAndStop() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1), (2), (3), (4), (5)")

        let count = try await db.query("SELECT id FROM x ORDER BY id") { stmt, stop in
            let value = try Int.column(of: stmt, at: 0)
            stop = value == 3
            return value
        }

        #expect(count == [1, 2, 3])
    }
}

@Suite("Database+Statement ManagedBinder/ManagedStepper Tests")
struct DatabaseStatementManagedBinderManagedStepperTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
    }

    @Test("Exec statement with ManagedBinder")
    func execWithManagedBinder() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)") { _, _ in
            // No-op
        }
        try await db.exec("INSERT INTO x (id) VALUES (?)") { stmt, index in
            try Int.bind(to: stmt, value: 1, at: &index)
        }
    }

    @Test("Query statement with ManagedBinder/ManagedStepper")
    func queryWithManagedBinderManagedStepper() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")

        let count = try await db.query("SELECT COUNT(*) FROM x WHERE id = ?") { stmt, index in
            try Int.bind(to: stmt, value: 1, at: &index)
        } stepper: { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }

        #expect(count == [1])
    }

    @Test("Query statement with ManagedStepper")
    func queryWithManagedStepper() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")

        let count = try await db.query("SELECT COUNT(*) FROM x") { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }

        #expect(count == [1])
    }
}

@Suite("Database+Statement bindings/ManagedStepper Tests")
struct DatabaseStatementBindingManagedStepperTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
    }

    @Test("Exec statement with bindings")
    func execWithManagedBinder() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (?)", binding: 1)
    }

    @Test("Query statement with bindings/ManagedStepper")
    func queryWithManagedBinderManagedStepper() async throws {
        try await db.exec("CREATE TABLE x (id INTEGER PRIMARY KEY)")
        try await db.exec("INSERT INTO x (id) VALUES (1)")

        let count = try await db.query("SELECT COUNT(*) FROM x WHERE id = ?", binding: 1) { stmt, index, _ in
            try Int.column(of: stmt, at: &index)
        }

        #expect(count == [1])
    }
}
