//
//  PrimaryKeyTableConstraint.swift
//

/// A PRIMARY KEY constraint on a table.
public struct PrimaryKeyTableConstraint: TableConstraint {
    public var constraintName: String?

    /// Columns of the primary key.
    public var columns: [String]

    /// Conflict resolution of the primary key.
    public var onConflict: ConflictResolution?

    /// Initializes a new PRIMARY KEY constraint.
    /// - Parameters:
    ///   - firstColumn: Column of the primary key.
    ///   - otherColumns: Additional columns of the primary key.
    ///   - onConflict: Conflict resolution of the primary key.
    ///   - constraintName: Name of the constraint.
    public init(
        on firstColumn: String,
        _ otherColumns: [String] = [],
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) {
        columns = [firstColumn] + otherColumns
        self.onConflict = onConflict
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, createTable: CreateTable) {
        let validation = validation.with(child: .constraint(constraintName, type: "PRIMARY KEY"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        if columns.isEmpty {
            validation.error(of: .noColumnsSpecified)
        }

        for (offset, column) in columns.enumerated() {
            if column.isEmpty {
                validation.error(of: .columnNameEmpty, info: ["column index": String(offset)])
            }

            if !createTable.columns.contains(where: { $0.name == column }) {
                validation.error(of: .columnNotFound, info: ["column": column])
            }
        }
    }

    public func append(to builder: SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("PRIMARY KEY")
        columns.appendAsSQLIdentifierList(to: builder)
        if let onConflict {
            onConflict.append(to: builder)
        }
    }
}

extension CreateTable {
    /// Creates a new `CreateTable` change with a PRIMARY KEY constraint appended.
    /// - Parameters:
    ///   - firstColumn: Column of the primary key.
    ///   - otherColumns: Additional columns of the primary key.
    ///   - onConflict: Conflict resolution of the primary key.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new `CreateTable` change with a PRIMARY KEY constraint appended.
    public func primaryKey(
        on firstColumn: String,
        _ otherColumns: String...,
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) -> CreateTable {
        appending(
            PrimaryKeyTableConstraint(
                on: firstColumn,
                otherColumns,
                onConflict: onConflict,
                constraintName: constraintName
            )
        )
    }
}
