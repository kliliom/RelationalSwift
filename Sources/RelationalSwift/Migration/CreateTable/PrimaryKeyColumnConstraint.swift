//
//  PrimaryKeyColumnConstraint.swift
//

/// A PRIMARY KEY constraint on a column.
public struct PrimaryKeyColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Order of the primary key.
    public var order: Order?

    /// Conflict resolution of the primary key.
    public var onConflict: ConflictResolution?

    /// Whether the primary key is auto-incrementing.
    public var autoIncrement: Bool

    /// Initializes a new PRIMARY KEY constraint.
    /// - Parameters:
    ///   - order: Order of the primary key.
    ///   - onConflict: Conflict resolution of the primary key.
    ///   - autoIncrement: Whether the primary key is auto-incrementing.
    ///   - constraintName: Name of the constraint.
    public init(
        order: Order? = nil,
        onConflict: ConflictResolution? = nil,
        autoIncrement: Bool = false,
        constraintName: String? = nil
    ) {
        self.order = order
        self.onConflict = onConflict
        self.autoIncrement = autoIncrement
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, column: Column) {
        let validation = validation.with(child: .constraint(constraintName, type: "PRIMARY KEY"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        if autoIncrement, column.storage != .integer {
            validation.warning(of: .autoIncrementOnNonInteger)
        }
    }

    public func append(to builder: inout SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("PRIMARY KEY")
        if let order {
            order.append(to: &builder)
        }
        if let onConflict {
            onConflict.append(to: &builder)
        }
        if autoIncrement {
            builder.sql.append("AUTOINCREMENT")
        }
    }
}

extension Column {
    /// Creates a new column with a PRIMARY KEY constraint applied.
    /// - Parameters:
    ///   - order: Order of the primary key.
    ///   - onConflict: Conflict resolution of the primary key.
    ///   - autoIncrement: Whether the primary key is auto-incrementing.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with a PRIMARY KEY constraint applied.
    public func primaryKey(
        order: Order? = nil,
        onConflict: ConflictResolution? = nil,
        autoIncrement: Bool = false,
        constraintName: String? = nil
    ) -> Column {
        appending(
            PrimaryKeyColumnConstraint(
                order: order,
                onConflict: onConflict,
                autoIncrement: autoIncrement,
                constraintName: constraintName
            )
        )
    }
}
