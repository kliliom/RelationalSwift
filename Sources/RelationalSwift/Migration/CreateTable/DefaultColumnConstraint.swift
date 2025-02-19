//
//  DefaultColumnConstraint.swift
//

import Foundation

/// A DEFAULT constraint on a column.
public struct DefaultColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Value of the default constraint.
    public var unsafeValue: String

    /// Initializes a new DEFAULT constraint.
    /// - Parameters:
    ///   - unsafeValue: Value of the default constraint.
    ///   - constraintName: Name of the constraint.
    public init(
        unsafeValue: String,
        constraintName: String? = nil
    ) {
        self.unsafeValue = unsafeValue
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, column _: Column) {
        let validation = validation.with(child: .constraint(constraintName, type: "DEFAULT"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }
    }

    public func append(to builder: inout SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("DEFAULT")
        builder.sql.append(unsafeValue)
    }
}

extension Column {
    /// Creates a column with a DEFAULT constraint applied.
    ///
    /// This is considered unsafe as it allows for arbitrary SQL to be injected.
    ///
    /// - Parameters:
    ///   - sql: SQL to use for the default value.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with the DEFAULT constraint.
    public func unsafeDefault(
        _ sql: String,
        constraintName: String? = nil
    ) -> Column {
        replacingOrAppending(
            DefaultColumnConstraint(
                unsafeValue: sql,
                constraintName: constraintName
            )
        )
    }
}
