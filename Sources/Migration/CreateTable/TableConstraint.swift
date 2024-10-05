//
//  TableConstraint.swift
//  Created by Kristof Liliom in 2024.
//

/// A constraint on a table.
public protocol TableConstraint: SQLConvertible, Sendable {
    /// Name of the constraint.
    var constraintName: String? { get }

    /// Validates the constraint.
    /// - Parameters:
    ///   - validation: Validation to use.
    ///   - createTable: CreateTable the constraint is on.
    func validate(in validation: Validation, createTable: CreateTable)
}
