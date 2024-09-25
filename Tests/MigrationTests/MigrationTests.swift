//
//  MigrationTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

import Interface
import Migration

@Suite("Migration Tests")
struct MigrationTests {
    let step1SQL = """
    CREATE TABLE Users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
    )
    """
    let step2SQL = """
    ALTER TABLE Users ADD COLUMN email TEXT DEFAULT NULL
    """

    @Test("Version with one Step")
    func singleStepVersion() async throws {
        let migration = Migration()

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)
    }

    @Test("Version with two Steps")
    func multipleStepVersion() async throws {
        let migration = Migration()

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }

            Step(name: "Add email to users") { db in
                try await db.exec(step2SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)
    }

    @Test("Multiple versions")
    func multipleVersions() async throws {
        let migration = Migration()

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }
        }

        try migration.add(version: 2) {
            Step(name: "Add email to users") { db in
                try await db.exec(step2SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)
    }

    @Test("Colliding versions")
    func collidingVersions() async throws {
        let migration = Migration()

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }
        }

        #expect(throws: DB4SwiftMigrationError(message: "migration version 1 already exists")) {
            try migration.add(version: 1) {
                Step(name: "Add email to users") { db in
                    try await db.exec(step2SQL)
                }
            }
        }
    }

    @Test("Multiple versions with swapped order")
    func multipleVersionsSwappedOrder() async throws {
        let migration = Migration()

        try migration.add(version: 2) {
            Step(name: "Add email to users") { db in
                try await db.exec(step2SQL)
            }
        }

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)
    }

    @Test("Running multiple times")
    func runningMultipleTimes() async throws {
        let migration = Migration()

        try migration.add(version: 1) {
            Step(name: "Add users") { db in
                try await db.exec(step1SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)

        try migration.add(version: 2) {
            Step(name: "Add email to users") { db in
                try await db.exec(step2SQL)
            }
        }

        try await migration.execute(on: db)
    }

    @Test("More migrated versions than versions to migrate")
    func moreMigratedVersionsThanVersionsToMigrate() async throws {
        var migration = Migration()
        try migration.add(version: 1) {}
        try migration.add(version: 2) {}
        try migration.add(version: 3) {}

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)

        migration = Migration()
        try migration.add(version: 1) {}
        try migration.add(version: 2) {}

        await #expect(throws: DB4SwiftMigrationError(message: "there are more migrated versions than versions to migrate")) {
            try await migration.execute(on: db)
        }
    }

    @Test("Running same versions with different versions")
    func runningMultipleTimesWithDifferingVersions() async throws {
        let migration = Migration()
        try migration.add(version: 1) {}
        try migration.add(version: 3) {}

        let db = try await Database.openInMemory()
        try await migration.execute(on: db)

        try migration.add(version: 2) {}

        await #expect(throws: DB4SwiftMigrationError(message: "migration order mismatch, got version 3, expected version 2")) {
            try await migration.execute(on: db)
        }
    }

    @Test("Running same versions with different hashes")
    func runningMultipleTimesWithDifferingHashes() async throws {
        let migration1 = Migration()
        try migration1.add(version: 1) {
            Step(name: "Add users-1") { db in
                try await db.exec(step1SQL)
            }
        }

        let migration2 = Migration()
        try migration2.add(version: 1) {
            Step(name: "Add users-2") { db in
                try await db.exec(step1SQL)
            }
        }

        let db = try await Database.openInMemory()
        try await migration1.execute(on: db)

        await #expect(throws: DB4SwiftMigrationError(message: "migration hash mismatch for version 1")) {
            try await migration2.execute(on: db)
        }
    }
}
