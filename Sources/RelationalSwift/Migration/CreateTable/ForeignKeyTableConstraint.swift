//
//  ForeignKeyTableConstraint.swift
//

/// A FOREIGN KEY constraint on a table.
public struct ForeignKeyTableConstraint: TableConstraint {
    public var constraintName: String?

    /// Name of the columns in the table.
    public var tableColumns: [String]

    /// Name of the foreign table.
    public var foreignTable: String

    /// Name of the columns in the foreign table.
    public var foreignColumns: [String]

    /// Action to take on update of the foreign key.
    public var onUpdate: ForeignKeyAction?

    /// Action to take on delete of the foreign key.
    public var onDelete: ForeignKeyAction?

    /// Initializes a new FOREIGN KEY constraint.
    /// - Parameters:
    ///   - tableColumn: Name of the column in the table.
    ///   - otherTableColumns: Additional names of columns in the table.
    ///   - foreignTable: Name of the foreign table.
    ///   - foreignColumn: Name of the column in the foreign table.
    ///   - otherForeignColumns: Additional names of columns in the foreign table.
    ///   - onUpdate: Action to take on update of the foreign key.
    ///   - onDelete: Action to take on delete of the foreign key.
    ///   - constraintName: Name of the constraint.
    public init<each T: StringProtocol>(
        on tableColumn: String,
        _ otherTableColumns: repeat each T,
        referencing foreignTable: String,
        columns foreignColumn: String,
        _ otherForeignColumns: repeat each T,
        onUpdate: ForeignKeyAction? = nil,
        onDelete: ForeignKeyAction? = nil,
        constraintName: String? = nil
    ) {
        tableColumns = [tableColumn]
        repeat (tableColumns.append(String(each otherTableColumns)))
        self.foreignTable = foreignTable
        foreignColumns = [foreignColumn]
        repeat (foreignColumns.append(String(each otherForeignColumns)))
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.constraintName = constraintName
    }

    public func validate(in validation: Validation, createTable: CreateTable) {
        let validation = validation.with(child: .constraint(constraintName, type: "FOREIGN KEY"))

        if let constraintName, constraintName.isEmpty {
            validation.error(of: .constraintNameEmpty)
        }

        for column in tableColumns {
            if !createTable.columns.contains(where: { $0.name == column }) {
                validation.error(of: .columnNotFound, info: ["column": column])
            }
        }

        for (offset, foreignColumn) in foreignColumns.enumerated() {
            if foreignColumn.isEmpty {
                validation.error(of: .columnNameEmpty, info: ["foreign column index": String(offset)])
            }
        }

        if tableColumns.isEmpty {
            validation.error(of: .noColumnsSpecified)
        }

        if tableColumns.count != foreignColumns.count {
            validation.error(of: .columnCountMismatch)
        }
    }

    public func append(to builder: SQLBuilder) {
        if let constraintName {
            builder.sql.append("CONSTRAINT")
            builder.sql.append(constraintName.asSQLIdentifier)
        }
        builder.sql.append("FOREIGN KEY")
        tableColumns.appendAsSQLIdentifierList(to: builder)
        builder.sql.append("REFERENCES")
        builder.sql.append(foreignTable.asSQLIdentifier)
        if !foreignColumns.isEmpty {
            foreignColumns.appendAsSQLIdentifierList(to: builder)
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

extension CreateTable {
    /// Creates a new `CreateTable` change with a FOREIGN KEY constraint appended.
    /// - Parameters:
    ///   - tableColumn: Name of the column in the table.
    ///   - otherTableColumns: Additional names of columns in the table.
    ///   - foreignTable: Name of the foreign table.
    ///   - foreignColumn: Name of the column in the foreign table.
    ///   - otherForeignColumns: Additional names of columns in the foreign table.
    ///   - onUpdate: Action to take on update of the foreign key.
    ///   - onDelete: Action to take on delete of the foreign key.
    ///   - constraintName: Name of the constraint.
    /// - Returns: A new `CreateTable` change with a FOREIGN KEY constraint appended.
    public func foreignKey<each T: StringProtocol>(
        on tableColumn: String,
        _ otherTableColumns: repeat each T,
        referencing foreignTable: String,
        columns foreignColumn: String,
        _ otherForeignColumns: repeat each T,
        onUpdate: ForeignKeyAction? = nil,
        onDelete: ForeignKeyAction? = nil,
        constraintName: String? = nil
    ) -> CreateTable {
        appending(
            ForeignKeyTableConstraint(
                on: tableColumn, repeat each otherTableColumns,
                referencing: foreignTable,
                columns: foreignColumn, repeat each otherForeignColumns,
                onUpdate: onUpdate,
                onDelete: onDelete,
                constraintName: constraintName
            )
        )
    }
}
