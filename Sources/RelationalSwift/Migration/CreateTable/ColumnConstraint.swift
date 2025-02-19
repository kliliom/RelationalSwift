//
//  ColumnConstraint.swift
//

/// A constraint that can be applied to a column.
public protocol ColumnConstraint: SQLBuilderAppendable, Sendable {
    /// Name of the constraint.
    var constraintName: String? { get }

    /// Validates the constraint.
    /// - Parameters:
    ///   - validation: Validation to use.
    ///   - column: Column the constraint is applied to.
    func validate(in validation: Validation, column: Column)
}
