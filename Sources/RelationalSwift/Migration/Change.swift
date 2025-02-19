//
//  Change.swift
//

/// A change that can be applied to a database.
public protocol Change: Sendable {
    /// Validates the change.
    ///
    /// This method returns validation checks that differ from the actual application of the change.
    /// Applying the change may still fail even if this method succeeds.
    ///
    /// - Parameter validation: Validation to use.
    func validate(in validation: Validation)

    /// Applies the change to a database.
    /// - Parameter db: Database to apply the change to.
    @DatabaseActor
    func apply(to db: Database) throws
}

/// A builder for changes.
@resultBuilder
public struct ChangeBuilder {
    /// Builds an array of changes.
    /// - Parameter changes: Changes to build.
    /// - Returns: An array of changes.
    public static func buildBlock(_ changes: Change...) -> [Change] {
        changes
    }
}
