//
//  CreateTable.swift
//

/// A change that creates a table.
public struct CreateTable: Change, SQLBuilderAppendable {
    /// Name of the table.
    public var tableName: String

    /// Name of the table's schema.
    public var schemaName: String?

    /// Columns of the table.
    public var columns: [Column]

    /// Constraints of the table.
    public var constraints: [TableConstraint] = []

    /// TEMPORARY flag.
    public var temporaryFlag: Bool = false

    /// IF NOT EXISTS flag.
    public var ifNotExistsFlag: Bool = false

    /// WITHOUT ROWID flag.
    public var withoutRowIDFlag: Bool = false

    /// STRICT flag.
    public var strictFlag: Bool = false

    /// Initializes a new `CreateTable` change.
    /// - Parameters:
    ///   - tableName: Name of the table.
    ///   - schemaName: Name of the table's schema.
    ///   - columns: Columns of the table.
    public init(
        _ tableName: String,
        schema schemaName: String? = nil,
        @ColumnBuilder _ columns: () -> [Column]
    ) {
        self.tableName = tableName
        self.schemaName = schemaName
        self.columns = columns()
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .createTable(tableName))

        if tableName.isEmpty {
            validation.error(of: .tableNameEmpty)
        }

        if let schemaName, schemaName.isEmpty {
            validation.error(of: .schemaNameEmpty)
        }

        if columns.isEmpty {
            validation.error(of: .noColumnsSpecified)
        }

        for column in columns {
            column.validate(in: validation)
        }
    }

    /// Returns a new `CreateTable` change with the provided column appended.
    /// - Parameter constraint: Constraint to append.
    /// - Returns: A new `CreateTable` change with the provided column appended.
    public func appending(_ constraint: TableConstraint) -> CreateTable {
        var copy = self
        copy.constraints.append(constraint)
        return copy
    }

    /// Returns a new `CreateTable` change with the TEMPORARY flag set.
    /// - Returns: A new `CreateTable` change with the TEMPORARY flag set.
    public func temporary() -> CreateTable {
        var copy = self
        copy.temporaryFlag = true
        return copy
    }

    /// Returns a new `CreateTable` change with the IF NOT EXISTS flag set.
    /// - Returns: A new `CreateTable` change with the IF NOT EXISTS flag set.
    public func ifNotExists() -> CreateTable {
        var copy = self
        copy.ifNotExistsFlag = true
        return copy
    }

    /// Returns a new `CreateTable` change with the WITHOUT ROWID flag set.
    /// - Returns: A new `CreateTable` change with the WITHOUT ROWID flag set.
    public func withoutRowID() -> CreateTable {
        var copy = self
        copy.withoutRowIDFlag = true
        return copy
    }

    /// Returns a new `CreateTable` change with the STRICT flag set.
    /// - Returns: A new `CreateTable` change with the STRICT flag set.
    public func strict() -> CreateTable {
        var copy = self
        copy.strictFlag = true
        return copy
    }

    public func append(to builder: inout SQLBuilder) {
        builder.sql.append("CREATE")
        if temporaryFlag {
            builder.sql.append("TEMPORARY")
        }
        builder.sql.append("TABLE")
        if ifNotExistsFlag {
            builder.sql.append("IF NOT EXISTS")
        }
        if let schemaName {
            builder.sql.append(schemaName.asSQLIdentifier)
            builder.sql.append(".")
        }
        builder.sql.append(tableName.asSQLIdentifier)
        builder.sql.append("(")

        var isFirstLine = true

        for column in columns {
            if isFirstLine {
                isFirstLine = false
            } else {
                builder.sql.append(",")
            }
            builder.sql.append("\n   ")
            column.append(to: &builder)
        }

        for constraint in constraints {
            if isFirstLine {
                isFirstLine = false
            } else {
                builder.sql.append(",")
            }
            builder.sql.append("\n   ")
            constraint.append(to: &builder)
        }

        if !isFirstLine {
            builder.sql.append("\n")
        }

        builder.sql.append(")")

        if withoutRowIDFlag {
            builder.sql.append("WITHOUT ROWID")
        }

        if strictFlag {
            if withoutRowIDFlag {
                builder.sql.append(",")
            }
            builder.sql.append("STRICT")
        }
    }

    public func apply(to db: Database) throws {
        var builder = SQLBuilder()
        append(to: &builder)
        try db.run(builder.makeStatement())
    }
}
