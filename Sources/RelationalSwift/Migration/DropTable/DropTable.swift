//
//  DropTable.swift
//

public struct DropTable: Change, SQLConvertible {
    public var tableName: String
    public var schemaName: String?
    public var ifExistsFlag: Bool = false

    public init(_ tableName: String, schema schemaName: String? = nil) {
        self.tableName = tableName
        self.schemaName = schemaName
    }

    public func validate(in validation: Validation) {
        let validation = validation.with(child: .dropTable(tableName))

        if tableName.isEmpty {
            validation.error(of: .tableNameEmpty)
        }

        if let schemaName, schemaName.isEmpty {
            validation.error(of: .schemaNameEmpty)
        }
    }

    public func ifExists() -> DropTable {
        var copy = self
        copy.ifExistsFlag = true
        return copy
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("DROP TABLE")
        if ifExistsFlag {
            builder.sql.append("IF EXISTS")
        }
        if let schemaName {
            builder.sql.append(schemaName.asSQLIdentifier)
            builder.sql.append(".")
        }
        builder.sql.append(tableName.asSQLIdentifier)
    }

    public func apply(to db: Database) throws {
        let builder = SQLBuilder()
        append(to: builder)
        try builder.execute(in: db)
    }
}
