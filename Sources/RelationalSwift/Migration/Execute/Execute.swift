//
//  Execute.swift
//

/// Executes a block of code.
public struct Execute: Change {
    /// Block to execute.
    public var block: @DatabaseActor (Database) throws -> Void

    /// Initializes a new `Execute`.
    /// - Parameter block: Block to execute.
    public init(block: @DatabaseActor @escaping (Database) throws -> Void) {
        self.block = block
    }

    public func validate(in _: Validation) {
        // No validation needed.
    }

    @DatabaseActor
    public func apply(to db: Database) throws {
        try block(db)
    }
}
