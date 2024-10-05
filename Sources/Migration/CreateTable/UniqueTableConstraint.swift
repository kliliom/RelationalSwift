//
//  UniqueTableConstraint.swift
//  Created by Kristof Liliom in 2024.
//

/// A UNIQUE constraint on a table.
public struct UniqueTableConstraint: TableConstraint {
    public var constraintName: String?

    /// Columns to apply the constraint on.
    public var columns: [String]

    /// Conflict resolution of the constraint.
    public var onConflict: ConflictResolution?

    /// Initializes a new UNIQUE constraint.
    /// - Parameters:
    ///   - firstColumn: Column to apply the constraint on.
    ///   - otherColumns: Additional columns to apply the constraint on.
    ///   - onConflict: Conflict resolution of the constraint.
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
        let validation = validation.with(child: .constraint(constraintName, type: "UNIQUE"))

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
            builder.sql.append(constraintName.quoted)
        }
        builder.sql.append("UNIQUE")
        columns.append(to: builder, quoted: true, parentheses: true)
        if let onConflict {
            onConflict.append(to: builder)
        }
    }
}

extension CreateTable {
    /// Creates a new `CreateTable` change with a UNIQUE constraint appended.
    /// - Parameters:
    ///   - firstColumn: Column to apply the constraint on.
    ///   - otherColumns: Additional columns to apply the constraint on.
    ///   - onConflict: Conflict resolution of the constraint.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new `CreateTable` change with a UNIQUE constraint appended.
    public func unique(
        on firstColumn: String,
        _ otherColumns: String...,
        onConflict: ConflictResolution? = nil,
        constraintName: String? = nil
    ) -> CreateTable {
        appending(
            UniqueTableConstraint(
                on: firstColumn,
                otherColumns,
                onConflict: onConflict,
                constraintName: constraintName
            )
        )
    }
}
