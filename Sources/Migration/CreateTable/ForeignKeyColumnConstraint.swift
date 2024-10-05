//
//  ForeignKeyColumnConstraint.swift
//  Created by Kristof Liliom in 2024.
//

/// A FOREIGN KEY constraint on a column.
public struct ForeignKeyColumnConstraint: ColumnConstraint {
    public var constraintName: String?

    /// Name of the foreign table.
    public var foreignTable: String

    /// Name of the foreign column.
    public var foreignColumn: String?

    /// Action to take on update of the foreign key.
    public var onUpdate: ForeignKeyAction?

    /// Action to take on delete of the foreign key.
    public var onDelete: ForeignKeyAction?

    /// Initializes a new FOREIGN KEY constraint.
    /// - Parameters:
    ///   - foreignTable: Name of the foreign table.
    ///   - foreignColumn: Name of the foreign column.
    ///   - onUpdate: Action to take on update of the foreign key.
    ///   - onDelete: Action to take on delete of the foreign key.
    ///   - constraintName: Name of the constraint.
    public init(
        referencing foreignTable: String,
        column foreignColumn: String? = nil,
        onUpdate: ForeignKeyAction? = nil,
        onDelete: ForeignKeyAction? = nil,
        constraintName: String? = nil
    ) {
        self.foreignTable = foreignTable
        self.foreignColumn = foreignColumn
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, column _: Column) {
        let validation = validation.with(child: .constraint(constraintName, type: "FOREIGN KEY"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        if let foreignColumn, foreignColumn.isEmpty {
            validation.error(of: .columnNameEmpty)
        }
    }

    public func append(to builder: SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.quoted)
        }
        builder.sql.append("REFERENCES")
        builder.sql.append(foreignTable.quoted)
        if let foreignColumn {
            [foreignColumn].append(to: builder, quoted: true, parentheses: true)
        }
        if let onUpdate {
            builder.sql.append("ON UPDATE")
            onUpdate.append(to: builder)
        }
        if let onDelete {
            builder.sql.append("ON DELETE")
            onDelete.append(to: builder)
        }
    }
}

extension Column {
    /// Creates a column with a FOREIGN KEY constraint applied.
    /// - Parameters:
    ///   - foreignTable: Name of the foreign table.
    ///   - column: Name of the foreign column.
    ///   - onUpdate: Action to take on update of the foreign key.
    ///   - onDelete: Action to take on delete of the foreign key.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new column with a FOREIGN KEY constraint applied.
    public func foreignKey(
        referencing foreignTable: String,
        column: String? = nil,
        onUpdate: ForeignKeyAction? = nil,
        onDelete: ForeignKeyAction? = nil,
        constraintName: String? = nil
    ) -> Column {
        appending(
            ForeignKeyColumnConstraint(
                referencing: foreignTable,
                column: column,
                onUpdate: onUpdate,
                onDelete: onDelete,
                constraintName: constraintName
            )
        )
    }
}
