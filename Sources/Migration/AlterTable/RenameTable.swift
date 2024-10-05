//
//  RenameTable.swift
//  Created by Kristof Liliom in 2024.
//

/// A change describing the renaming of a table.
///
/// SQL: `ALTER TABLE table_name RENAME TO new_table_name`
public struct RenameTable: AlterTableChange {
    /// Alter table base.
    public var alterTable: AlterTable

    /// New table name.
    public var newTableName: String

    /// Initializes a new `RenameTable` change.
    /// - Parameters:
    ///   - alterTable: Alter table base.
    ///   - newTableName: New table name.
    public init(_ alterTable: AlterTable, to newTableName: String) {
        self.alterTable = alterTable
        self.newTableName = newTableName
    }

    public func append(to builder: SQLBuilder) {
        alterTable.append(to: builder)
        builder.sql.append("RENAME TO")
        builder.sql.append(newTableName.quoted)
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .alterTable("RENAME TO"))

        alterTable.validate(in: validation)

        if newTableName.isEmpty {
            validation.error(of: .tableNameEmpty, info: ["location": "new table name"])
        }
    }

    public func apply(to db: Database) throws {
        let builder = SQLBuilder()
        append(to: builder)
        try builder.execute(in: db)
    }
}

extension AlterTable {
    /// Creates a change that renames the table.
    /// - Parameter newTableName: New table name.
    /// - Returns: A change that renames the table.
    public func renameTable(to newTableName: String) -> RenameTable {
        RenameTable(self, to: newTableName)
    }
}
