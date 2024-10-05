//
//  UnsafeCheckColumnConstraint.swift
//  Created by Kristof Liliom in 2024.
//

/// A CHECK constraint on a column.
///
/// This is considered unsafe as it allows for arbitrary SQL to be injected.
public struct UnsafeCheckColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Expression to check.
    public var expression: String

    /// Initializes a new CHECK constraint.
    /// - Parameters:
    ///   - expression: Expression to check.
    ///   - constraintName: Name of the constraint.
    public init(
        _ expression: String,
        constraintName: String? = nil
    ) {
        self.expression = expression
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, column _: Column) {
        let validation = validation.with(child: .constraint(constraintName, type: "CHECK"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        if expression.isEmpty {
            validation.error(of: .expressionEmpty)
        }
    }

    public func append(to builder: SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.quoted)
        }
        builder.sql.append("CHECK (")
        builder.sql.append(expression)
        builder.sql.append(")")
    }
}

extension Column {
    /// Creates a new column with a CHECK constraint applied.
    /// - Parameters:
    ///   - expression: Expression to check.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with a CHECK constraint applied.
    public func unsafeCheck(
        _ expression: String,
        constraintName: String? = nil
    ) -> Column {
        appending(
            UnsafeCheckColumnConstraint(
                expression,
                constraintName: constraintName
            )
        )
    }
}
