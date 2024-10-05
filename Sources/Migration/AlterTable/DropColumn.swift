//
//  DropColumn.swift
//  Created by Kristof Liliom in 2024.
//

/// A change describing the removal of a column from a table.
///
/// SQL: `ALTER TABLE table_name DROP COLUMN column_name`
public struct DropColumn: AlterTableChange {
    /// Alter table base.
    public var alterTable: AlterTable

    /// Column to drop.
    public var columnName: String

    /// Initializes a new `DropColumn` change.
    /// - Parameters:
    ///   - alterTable: Alter table base.
    ///   - columnName: Column to drop.
    public init(_ alterTable: AlterTable, _ columnName: String) {
        self.alterTable = alterTable
        self.columnName = columnName
    }

    public func append(to builder: SQLBuilder) {
        alterTable.append(to: builder)
        builder.sql.append("DROP COLUMN")
        builder.sql.append(columnName.quoted)
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .alterTable("DROP COLUMN"))

        alterTable.validate(in: validation)

        if columnName.isEmpty {
            validation.error(of: .columnNameEmpty)
        }
    }

    public func apply(to db: Database) throws {
        let builder = SQLBuilder()
        append(to: builder)
        try builder.execute(in: db)
    }
}

extension AlterTable {
    /// Creates a change that drops a column from the table.
    /// - Parameter columnName: Column to drop.
    /// - Returns: A change that drops a column from the table.
    public func dropColumn(_ columnName: String) -> DropColumn {
        DropColumn(self, columnName)
    }
}
