//
//  Migration.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// A migration that groups multiple change sets together.
public class Migration {
    /// Change sets to apply.
    let changeSets: [ChangeSet]

    /// Initializes a new `Migration`.
    /// - Parameter changeSets: Change sets to apply.
    public init(changeSets: [ChangeSet]) {
        self.changeSets = changeSets
    }

    /// Validates the migration.
    ///
    /// This method returns validation checks that differ from the actual application of the change.
    /// Applying the change may still fail even if this method succeeds.
    ///
    /// - Returns: A store of validation issues.
    public func validate() -> Validation.Store {
        let validation = Validation()
        for changeSet in changeSets {
            changeSet.validate(in: validation)
        }
        return validation.store
    }

    /// Migrates an opened database.
    /// - Parameter database: Database to migrate.
    @DatabaseActor
    public func migrate(
        database: Database
    ) throws {
        try executeMigration(on: database)
    }

    /// Migrates a database at a given URL.
    ///
    /// This method modifies the database directly and is not the safest way to migrate a database.
    /// Migration errors can leave the database in an inconsistent state from which it may be difficult to recover.
    ///
    /// When performing a dry run, the database is copied to a temporary file and the migration is applied to
    /// the copy. No changes are made to the original database.
    ///
    /// - Parameters:
    ///   - databaseURL: URL of the database to migrate.
    ///   - dryRun: Whether to perform a dry run.
    @DatabaseActor
    public func migrate(
        databaseAt databaseURL: URL,
        dryRun: Bool = false
    ) throws {
        if dryRun {
            let temporaryFileURL = if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, macOS 13.0, *) {
                URL(filePath: NSTemporaryDirectory()).appending(component: UUID().uuidString)
            } else {
                URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            }
            defer {
                try? FileManager.default.removeItem(at: temporaryFileURL)
            }
            try migrate(
                databaseAt: databaseURL,
                usingTemporaryFileAt: temporaryFileURL,
                dryRun: true
            )
        } else {
            try executeMigration(databaseAt: databaseURL)
        }
    }

    /// Migrates a database at a given URL using a temporary file.
    ///
    /// This method copies the database to a temporary file and migrates the copy. If the migration is successful,
    /// the original database is replaced with the temporary file. If the migration fails, the temporary file is
    /// left in place.
    ///
    /// When performing a dry run, the database is copied to the temporary file and the migration is applied to
    /// the copy. No changes are made to the original database.
    ///
    /// - Parameters:
    ///   - databaseURL: URL of the database to migrate.
    ///   - temporaryFileURL: URL of the temporary file to use.
    ///   - dryRun: Whether to perform a dry run.
    @DatabaseActor
    public func migrate(
        databaseAt databaseURL: URL,
        usingTemporaryFileAt temporaryFileURL: URL,
        dryRun: Bool = false
    ) throws {
        let fileManager = FileManager.default

        let temporaryFilePath: String = if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            temporaryFileURL.path(percentEncoded: false)
        } else {
            temporaryFileURL.path
        }

        if fileManager.fileExists(atPath: temporaryFilePath) {
            try fileManager.removeItem(at: temporaryFileURL)
        }

        let databasePath: String = if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            databaseURL.path(percentEncoded: false)
        } else {
            databaseURL.path
        }

        if fileManager.fileExists(atPath: databasePath) {
            try fileManager.copyItem(at: databaseURL, to: temporaryFileURL)
        }

        try executeMigration(databaseAt: temporaryFileURL)

        if !dryRun {
            if fileManager.fileExists(atPath: databasePath) {
                try fileManager.removeItem(at: databaseURL)
            }
            try fileManager.moveItem(at: temporaryFileURL, to: databaseURL)
        }
    }

    /// Migrates a database at a given URL.
    /// - Parameter databaseURL: URL of the database to migrate.
    @DatabaseActor
    private func executeMigration(
        databaseAt databaseURL: URL
    ) throws {
        let db = try Database.open(url: databaseURL)
        try executeMigration(on: db)
    }
}

extension Migration {
    /// Name of the migration log table.
    private static let tableName = "_relational_swift_migration_log"

    /// Record of a change set migration.
    private struct MigrationRecord {
        /// Identifier of the change set.
        let id: String
        /// Order of the change set.
        let order: Int
        /// Time the change set was started.
        let startedAt: Date
        /// Time the change set was completed.
        let completedAt: Date
    }

    /// Checks that the change set IDs are unique.
    private func checkChangeSetUniqueIDs() throws {
        var uniqueIDs = Set<String>()
        for changeSet in changeSets {
            if uniqueIDs.contains(changeSet.id) {
                throw RelationalSwiftError.duplicateChangesetID(id: changeSet.id)
            }
            uniqueIDs.insert(changeSet.id)
        }
    }

    /// Executes the migration on a database.
    /// - Parameter database: Database to migrate.
    @DatabaseActor
    private func executeMigration(
        on database: Database
    ) throws {
        try checkChangeSetUniqueIDs()

        try prepareMigrationTables(in: database)

        // Read the migration records from the database.
        var migrationRecords = try readMigrationRecords(from: database)
        var nextAvailableIndex = 0

        for changeSet in changeSets {
            // If the change set should always run, apply it.
            if changeSet.alwaysRun {
                try changeSet.apply(to: database)
                continue
            }

            // If the change set has already been applied, skip it.
            if let migrationRecord = migrationRecords.first {
                migrationRecords.removeFirst()

                if migrationRecord.id == changeSet.id {
                    nextAvailableIndex = migrationRecord.order + 1
                    continue
                } else {
                    throw RelationalSwiftError.changesetOrderMissmatch(
                        expectedID: changeSet.id,
                        actualID: migrationRecord.id
                    )
                }
            }

            // Apply the change set and insert a record.
            let startedAt = Date()
            try changeSet.apply(to: database)
            let completedAt = Date()

            let record = MigrationRecord(
                id: changeSet.id,
                order: nextAvailableIndex,
                startedAt: startedAt,
                completedAt: completedAt
            )
            try insertMigrationRecord(record, into: database)
            nextAvailableIndex += 1
        }
    }

    /// Prepares the migration tables in a database.
    /// - Parameter database: Database to prepare.
    @DatabaseActor
    private func prepareMigrationTables(
        in database: Database
    ) throws {
        try database.exec("""
        CREATE TABLE IF NOT EXISTS \(Self.tableName) (
            id TEXT PRIMARY KEY,
            "order" INTEGER NOT NULL,
            started_at TEXT NOT NULL,
            completed_at TEXT NOT NULL
        )
        """)
    }

    /// Reads the migration records from a database.
    /// - Parameter database: Database to read from.
    /// - Returns: An array of migration records.
    @DatabaseActor
    private func readMigrationRecords(
        from database: Database
    ) throws -> [MigrationRecord] {
        let rows = try database.query("""
        SELECT id, "order", started_at, completed_at
        FROM \(Self.tableName)
        ORDER BY "order" ASC
        """) { stmt, index, _ in
            try MigrationRecord(
                id: String.column(of: stmt, at: &index),
                order: Int.column(of: stmt, at: &index),
                startedAt: Date.column(of: stmt, at: &index),
                completedAt: Date.column(of: stmt, at: &index)
            )
        }
        return rows
    }

    /// Inserts a migration record into a database.
    /// - Parameters:
    ///   - record: Record to insert.
    ///   - database: Database to insert into.
    @DatabaseActor
    private func insertMigrationRecord(
        _ record: MigrationRecord,
        into database: Database
    ) throws {
        try database.exec("""
        INSERT INTO \(Self.tableName) (id, "order", started_at, completed_at)
        VALUES (?, ?, ?, ?)
        """) { stmt, index in
            try record.id.bind(to: stmt, at: &index)
            try record.order.bind(to: stmt, at: &index)
            try record.startedAt.bind(to: stmt, at: &index)
            try record.completedAt.bind(to: stmt, at: &index)
        }
    }
}
