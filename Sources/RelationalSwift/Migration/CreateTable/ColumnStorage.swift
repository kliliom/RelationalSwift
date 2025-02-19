//
//  ColumnStorage.swift
//

/// Storage type for a column.
public enum ColumnStorage: SQLConvertible, Sendable, Equatable {
    /// INTEGER storage type.
    case integer
    /// VARCHAR storage type.
    case varchar(length: Int)
    /// TEXT storage type.
    case text
    /// BLOB storage type.
    case blob
    /// DOUBLE storage type.
    case double
    /// DECIMAL storage type.
    case decimal(precision: Int, scale: Int)
    /// Custom storage type.
    ///
    /// This is considered unsafe as it allows for arbitrary SQL to be injected.
    case unsafe(String)

    public func append(to builder: SQLBuilder) {
        switch self {
        case .integer:
            builder.sql.append("INTEGER")
        case let .varchar(length):
            builder.sql.append("VARCHAR(\(length))")
        case .text:
            builder.sql.append("TEXT")
        case .blob:
            builder.sql.append("BLOB")
        case .double:
            builder.sql.append("DOUBLE")
        case let .decimal(precision, scale):
            builder.sql.append("DECIMAL(\(precision), \(scale))")
        case let .unsafe(sql):
            builder.sql.append(sql)
        }
    }
}
