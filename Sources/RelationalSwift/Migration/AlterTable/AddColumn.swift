//
//  AddColumn.swift
//  Created by Kristof Liliom in 2024.
//

/// A change describing the addition of a column to a table.
///
/// SQL: `ALTER TABLE table_name ADD COLUMN column`
public struct AddColumn: AlterTableChange {
    /// Alter table base.
    public var alterTable: AlterTable

    /// Column to add.
    public let column: Column

    /// Initializes a new `AddColumn` change.
    /// - Parameters:
    ///   - alterTable: Alter table base.
    ///   - column: Column to add.
    public init(_ alterTable: AlterTable, _ column: Column) {
        self.alterTable = alterTable
        self.column = column
    }

    public func append(to builder: SQLBuilder) {
        alterTable.append(to: builder)
        builder.sql.append("ADD COLUMN")
        column.append(to: builder)
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .alterTable("ADD COLUMN"))

        alterTable.validate(in: validation)
        column.validate(in: validation)
    }

    public func apply(to db: Database) throws {
        let builder = SQLBuilder()
        append(to: builder)
        try builder.execute(in: db)
    }
}

extension AlterTable {
    /// Creates a change that adds a column to the table.
    /// - Parameter column: Column to add.
    /// - Returns: A change that adds a column to the table.
    public func addColumn(_ column: Column) -> AddColumn {
        AddColumn(self, column)
    }
}
