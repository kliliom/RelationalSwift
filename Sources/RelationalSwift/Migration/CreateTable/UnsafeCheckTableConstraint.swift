//
//  UnsafeCheckTableConstraint.swift
//

/// A CHECK constraint on a table.
///
/// This is considered unsafe as it allows for arbitrary SQL to be injected.
public struct UnsafeCheckTableConstraint: TableConstraint {
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

    public func validate(in validation: Validation, createTable _: CreateTable) {
        let validation = validation.with(child: .constraint(constraintName, type: "CHECK"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        if expression.isEmpty {
            validation.error(of: .expressionEmpty)
        }
    }

    public func append(to builder: inout SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("CHECK (")
        builder.sql.append(expression)
        builder.sql.append(")")
    }
}

extension CreateTable {
    /// Creates a new `CreateTable` with a CHECK constraint applied.
    /// - Parameters:
    ///   - expression: Expression to check.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new `CreateTable` with a CHECK constraint applied.
    public func unsafeCheck(
        _ expression: String,
        constraintName: String? = nil
    ) -> CreateTable {
        appending(
            UnsafeCheckTableConstraint(
                expression,
                constraintName: constraintName
            )
        )
    }
}
