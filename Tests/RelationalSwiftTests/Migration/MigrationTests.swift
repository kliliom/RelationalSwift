//
//  MigrationTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

@testable import RelationalSwift

@Suite
struct MigrationTests {
    let changeSet1 = ChangeSet(id: "change set 1") {
        CreateTable("test_table") {
            Column("id", ofType: Int.self)
                .primaryKey()
            Column("name", ofType: String.self)
        }
    }

    let changeSet2 = ChangeSet(id: "change set 2") {
        AlterTable("test_table")
            .addColumn(Column("age", ofType: Int.self))
    }

    let invalidChangeSet = ChangeSet(id: "invalid change set") {
        DropTable("test_table")
        AlterTable("test_table").dropColumn("non_existent_column")
    }

    private func getColumnNames(from db: Database) async throws -> [String] {
        try await db.query("PRAGMA table_info('test_table')") { stmt, _ in
            try String.column(of: stmt, at: 1)
        }
    }

    var temporaryFileURL: URL {
        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, macOS 13.0, *) {
            URL(filePath: NSTemporaryDirectory()).appending(component: UUID().uuidString)
        } else {
            URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        }
    }

    @Test("Initializer")
    func initializer() {
        let migration = Migration(changeSets: [])

        #expect(migration.changeSets.isEmpty)
    }

    @Test("Validate combines issues")
    func validateCombinesIssues() throws {
        let changeSet1 = ChangeSet(id: "id") {
            AlterTable("").dropColumn("")
        }
        let changeSet2 = ChangeSet(id: "id") {
            AlterTable("").dropColumn("")
        }
        let migration = Migration(changeSets: [
            changeSet1,
            changeSet2,
        ])

        let validation = migration.validate()

        try #require(validation.errors.count == 4)
        let errors = validation.errors
        #expect(errors[0].issue == .tableNameEmpty)
        #expect(errors[1].issue == .columnNameEmpty)
        #expect(errors[2].issue == .tableNameEmpty)
        #expect(errors[3].issue == .columnNameEmpty)
        #expect(errors[0].path == [.changeSet("id"), .alterTable("DROP COLUMN")])
        #expect(errors[1].path == [.changeSet("id"), .alterTable("DROP COLUMN")])
        #expect(errors[2].path == [.changeSet("id"), .alterTable("DROP COLUMN")])
        #expect(errors[3].path == [.changeSet("id"), .alterTable("DROP COLUMN")])
    }

    @Test("Migrate database connection")
    func migrateDatabaseConnection() async throws {
        let db = try await Database.openInMemory()

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(database: db)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2])
        try await migration2.migrate(database: db)

        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 3)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
        #expect(columns.contains("age"))
    }

    @Test("Migrate database connection with failure")
    func migrateDatabaseConnectionWithFailure() async throws {
        let db = try await Database.openInMemory()

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(database: db)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2, invalidChangeSet])
        try await #require(throws: RelationalSwiftError.error(message: "no such table: test_table")) {
            try await migration2.migrate(database: db)
        }

        let columns = try await getColumnNames(from: db)
        #expect(columns.isEmpty)
    }

    @Test("Migrate database file")
    func migrateDatabaseFile() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2])
        try await migration2.migrate(databaseAt: fileURL)

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 3)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
        #expect(columns.contains("age"))
    }

    @Test("Migrate database file with failure")
    func migrateDatabaseFileWithFailure() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2, invalidChangeSet])
        try await #require(throws: RelationalSwiftError.error(message: "no such table: test_table")) {
            try await migration2.migrate(databaseAt: fileURL)
        }

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.isEmpty)
    }

    @Test("Migrate database file with dry run")
    func migrateDatabaseFileWithDryRun() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2])
        try await migration2.migrate(databaseAt: fileURL, dryRun: true)

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 2)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
    }

    @Test("Migrate database file with dry run and failure")
    func migrateDatabaseFileWithDryRunAndFailure() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2, invalidChangeSet])
        try await #require(throws: RelationalSwiftError.error(message: "no such table: test_table")) {
            try await migration2.migrate(databaseAt: fileURL, dryRun: true)
        }

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 2)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
    }

    @Test("Migrate database file with temporary file")
    func migrateDatabaseFileWithTemporaryFile() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2])
        try await migration2.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 3)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
        #expect(columns.contains("age"))
    }

    @Test("Migrate database file with temporary file and failure")
    func migrateDatabaseFileWithTemporaryFileAndFailure() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2, invalidChangeSet])
        try await #require(throws: RelationalSwiftError.error(message: "no such table: test_table")) {
            try await migration2.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)
        }

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 2)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
    }

    @Test("Migrate database file with temporary file and dry run")
    func migrateDatabaseFileWithTemporaryFileAndDryRun() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2])
        try await migration2.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL, dryRun: true)

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 2)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
    }

    @Test("Migrate database file with temporary file and dry run and failure")
    func migrateDatabaseFileWithTemporaryFileAndDryRunAndFailure() async throws {
        let fileURL = temporaryFileURL

        let migration1 = Migration(changeSets: [changeSet1])
        try await migration1.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL)

        let migration2 = Migration(changeSets: [changeSet1, changeSet2, invalidChangeSet])
        try await #require(throws: RelationalSwiftError.error(message: "no such table: test_table")) {
            try await migration2.migrate(databaseAt: fileURL, usingTemporaryFileAt: temporaryFileURL, dryRun: true)
        }

        let db = try await Database.open(url: fileURL)
        let columns = try await getColumnNames(from: db)
        #expect(columns.count == 2)
        #expect(columns.contains("id"))
        #expect(columns.contains("name"))
    }
}
