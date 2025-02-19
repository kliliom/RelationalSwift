//
//  NotNullColumnConstraint.swift
//

/// A NOT NULL constraint.
public struct NotNullColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Action to take on conflict.
    public var onConflict: ConflictResolution?

    /// Initializes a new NOT NULL constraint.
    /// - Parameters:
    ///   - onConflict: Action to take on conflict.
    ///   - constraintName: Name of the constraint.
    public init(
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) {
        self.onConflict = onConflict
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, column _: Column) {
        let validation = validation.with(child: .constraint(constraintName, type: "NOT NULL"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }
    }

    public func append(to builder: inout SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("NOT NULL")
        if let onConflict {
            onConflict.append(to: &builder)
        }
    }
}

extension Column {
    /// Creates a new column with a NOT NULL constraint applied.
    /// - Parameters:
    ///   - onConflict: Action to take on conflict.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with a NOT NULL constraint applied.
    public func notNull(
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) -> Column {
        replacingOrAppending(
            NotNullColumnConstraint(
                onConflict: onConflict,
                constraintName: constraintName
            )
        )
    }
}
