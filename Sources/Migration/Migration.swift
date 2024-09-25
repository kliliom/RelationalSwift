//
//  Migration.swift
//  Created by Kristof Liliom in 2024.
//

import CryptoKit
import Foundation

@_exported import Interface

/// An atomic migration step.
public struct Step: Sendable {
    /// The name describing the step.
    ///
    /// Do not use the same name for different steps.
    /// Do not change the name of a step once it has been used.
    public var name: String

    /// The actions to be executed in the step.
    public var actions: @Sendable (_ db: Database) async throws -> Void

    /// Initializes a new migration step.
    /// - Parameters:
    ///   - name: Name describing the step.
    ///   - actions: Actions to be executed in the step.
    public init(name: String, actions: @Sendable @escaping (_: Database) async throws -> Void) {
        self.name = name
        self.actions = actions
    }
}

/// Builder for migration steps.
@resultBuilder
public struct StepsBuilder {
    public static func buildBlock(_ components: Step...) -> [Step] {
        components
    }
}

/// Migration class.
public final class Migration {
    /// Describes a migration version.
    private struct Version {
        /// Version number.
        var number: Int
        /// Steps to be executed in the version.
        var steps: [Step]
        /// Hash of the steps.
        var hash: String
    }

    /// Describes a migrated version.
    private struct MigratedVersion {
        /// Version number.
        let number: Int
        /// Hash of the steps.
        let hash: String
        /// Migration start time.
        let startedAt: Date
        /// Migration end time.
        let endedAt: Date
    }

    /// Array of versions to be migrated.
    private var versions: [Version] = []

    /// Table name for migration log.
    private let tableName = "_db4swift_migration_log"

    /// Initializes a new Migration.
    public init() {}

    /// Adds a new migration version.
    /// - Parameters:
    ///   - version: Version number.
    ///   - builder: Steps builder.
    public func add(version: Int, @StepsBuilder builder: () -> [Step]) throws {
        guard !versions.contains(where: { $0.number == version }) else {
            throw DB4SwiftMigrationError(message: "migration version \(version) already exists")
        }
        let steps = builder()
        let names = steps.map(\.name).joined(separator: "")
        let hash = Insecure.MD5.hash(data: Data(names.utf8)).map {
            String(format: "%02hhx", $0)
        }.joined()
        versions.append(Version(number: version, steps: steps, hash: hash))
    }

    /// Executes the migration.
    /// - Parameter db: Database to execute the migration on.
    public func execute(on db: Database) async throws {
        // Check if the migration log table exists.
        let count = try await db.query("SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?") { [tableName] handle in
            var index = Int32()
            try String.bind(to: handle, value: tableName, at: &index)
        } step: { handle, _ in
            var index = Int32()
            return try Int.column(of: handle, at: &index)
        }.first ?? 0

        // Create the migration log table if it does not exist.
        if count == 0 {
            try await db.exec("""
            CREATE TABLE "\(tableName)" (
                "number" INTEGER PRIMARY KEY,
                "hash" TEXT NOT NULL,
                "started_at" DOUBLE NOT NULL,
                "ended_at" DOUBLE NOT NULL
            )
            """)
        }

        // Fetch migrated versions.
        let migratedVersions: [MigratedVersion] = try await db.query(
            """
            SELECT "number", "hash", "started_at", "ended_at" FROM "\(tableName)" ORDER BY "number" ASC
            """,
            step: { handle, _ in
                var index = Int32()
                return try MigratedVersion(
                    number: Int.column(of: handle, at: &index),
                    hash: String.column(of: handle, at: &index),
                    startedAt: Date.column(of: handle, at: &index),
                    endedAt: Date.column(of: handle, at: &index)
                )
            }
        )

        // Sort versions and check if they match the migrated versions.
        var versions = if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            versions.sorted(using: KeyPathComparator(\.number))
        } else {
            versions.sorted(by: { lhs, rhs in
                lhs.number < rhs.number
            })
        }
        for migratedVersion in migratedVersions {
            guard let version = versions.first else {
                throw DB4SwiftMigrationError(message: "there are more migrated versions than versions to migrate")
            }
            guard version.number == migratedVersion.number else {
                throw DB4SwiftMigrationError(message: "migration order mismatch, got version \(migratedVersion.number), expected version \(version.number)")
            }
            guard version.hash == migratedVersion.hash else {
                throw DB4SwiftMigrationError(message: "migration hash mismatch for version \(version.number)")
            }
            versions.removeFirst()
        }

        // Execute the remaining versions.
        for version in versions {
            let startedAt = Date()
            for step in version.steps {
                try await step.actions(db)
            }
            let endedAt = Date()

            try await db.exec(
                """
                INSERT INTO \(tableName) ("number", "hash", "started_at", "ended_at") VALUES (?, ?, ?, ?)
                """,
                bind: { handle in
                    var index = Int32()
                    try Int.bind(to: handle, value: version.number, at: &index)
                    try String.bind(to: handle, value: version.hash, at: &index)
                    try Date.bind(to: handle, value: startedAt, at: &index)
                    try Date.bind(to: handle, value: endedAt, at: &index)
                }
            )
        }
    }
}
