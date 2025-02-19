//
//  AlterTable.swift
//

/// Base for all alter table changes.
public struct AlterTable: SQLBuilderAppendable, Sendable {
    /// Name of the table to alter.
    public var tableName: String

    /// Name of the table's schema.
    public var schemaName: String?

    /// Initializes a new `AlterTable` change.
    /// - Parameters:
    ///   - tableName: Name of the table to alter.
    ///   - schemaName: Name of the table's schema.
    public init(_ tableName: String, schema schemaName: String? = nil) {
        self.tableName = tableName
        self.schemaName = schemaName
    }

    public func append(to builder: inout SQLBuilder) {
        builder.sql.append("ALTER TABLE")
        if let schemaName {
            builder.sql.append(schemaName.asSQLIdentifier)
            builder.sql.append(".")
        }
        builder.sql.append(tableName.asSQLIdentifier)
    }

    /// Validates the change base.
    /// - Parameter validation: Validation to use.
    public func validate(in validation: Validation) {
        if tableName.isEmpty {
            validation.error(of: .tableNameEmpty)
        }

        if let schemaName, schemaName.isEmpty {
            validation.error(of: .schemaNameEmpty)
        }
    }
}
