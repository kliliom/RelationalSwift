//
//  TableConstraint.swift
//

/// A constraint on a table.
public protocol TableConstraint: SQLBuilderAppendable, Sendable {
    /// Name of the constraint.
    var constraintName: String? { get }

    /// Validates the constraint.
    /// - Parameters:
    ///   - validation: Validation to use.
    ///   - createTable: CreateTable the constraint is on.
    func validate(in validation: Validation, createTable: CreateTable)
}
