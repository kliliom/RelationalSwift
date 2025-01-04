//
//  UniqueColumnConstraint.swift
//  Created by Kristof Liliom in 2024.
//

/// A UNIQUE constraint on a column.
public struct UniqueColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Action to take on conflict.
    public var onConflict: ConflictResolution?

    /// Initializes a new UNIQUE constraint.
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
        let validation = validation.with(child: .constraint(constraintName, type: "UNIQUE"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }
    }

    public func append(to builder: SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("UNIQUE")
        if let onConflict {
            onConflict.append(to: builder)
        }
    }
}

extension Column {
    /// Creates a new column with a UNIQUE constraint applied.
    /// - Parameters:
    ///   - onConflict: Action to take on conflict.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with a UNIQUE constraint applied.
    public func unique(
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) -> Column {
        appending(
            UniqueColumnConstraint(
                onConflict: onConflict,
                constraintName: constraintName
            )
        )
    }
}
