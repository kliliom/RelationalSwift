//
//  ChangeSet.swift
//  Created by Kristof Liliom in 2024.
//

import Interface

/// A change set that groups multiple changes together.
public struct ChangeSet: Change {
    /// Name of the change set. This must be unique within a migration.
    public var id: String

    /// Whether the change set should always run on every migration.
    public var alwaysRun: Bool = false

    /// Changes to apply.
    public var changes: [Change]

    /// Initializes a new `ChangeSet`.
    /// - Parameters:
    ///   - id: Name of the change set. This must be unique within a migration.
    ///   - alwaysRun: Whether the change set should always run on every migration.
    ///   - changes: Changes to apply.
    public init(id: String, alwaysRun: Bool = false, @ChangeBuilder _ changes: () -> [Change]) {
        self.id = id
        self.alwaysRun = alwaysRun
        self.changes = changes()
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .changeSet(id))

        for change in changes {
            change.validate(in: validation)
        }
    }

    public func apply(to db: Database) throws {
        for change in changes {
            try change.apply(to: db)
        }
    }
}
