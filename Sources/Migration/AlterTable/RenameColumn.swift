//
//  RenameColumn.swift
//  Created by Kristof Liliom in 2024.
//

/// A change describing the renaming of a column in a table.
///
/// SQL: `ALTER TABLE table_name RENAME COLUMN old_column_name TO new_column_name`
public struct RenameColumn: AlterTableChange {
    /// Alter table base.
    public var alterTable: AlterTable

    /// Old column name.
    public let oldName: String

    /// New column name.
    public let newName: String

    /// Initializes a new `RenameColumn` change.
    /// - Parameters:
    ///   - alterTable: Alter table base.
    ///   - oldName: Old column name.
    ///   - newName: New column name.
    public init(_ alterTable: AlterTable, from oldName: String, to newName: String) {
        self.alterTable = alterTable
        self.oldName = oldName
        self.newName = newName
    }

    public func append(to builder: SQLBuilder) {
        alterTable.append(to: builder)
        builder.sql.append("RENAME COLUMN")
        builder.sql.append(oldName.asSQLIdentifier)
        builder.sql.append("TO")
        builder.sql.append(newName.asSQLIdentifier)
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .alterTable("RENAME COLUMN"))

        alterTable.validate(in: validation)

        if oldName.isEmpty {
            validation.error(of: .columnNameEmpty, info: ["location": "old column name"])
        }

        if newName.isEmpty {
            validation.error(of: .columnNameEmpty, info: ["location": "new column name"])
        }
    }

    public func apply(to db: Database) throws {
        let builder = SQLBuilder()
        append(to: builder)
        try builder.execute(in: db)
    }
}

extension AlterTable {
    /// Creates a change that renames a column in the table.
    /// - Parameters:
    ///   - oldName: Old column name.
    ///   - newName: New column name.
    /// - Returns: A change that renames a column in the table.
    public func renameColumn(from oldName: String, to newName: String) -> RenameColumn {
        RenameColumn(self, from: oldName, to: newName)
    }
}
