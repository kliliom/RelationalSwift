//
//  Order.swift
//

/// Order of a column.
public enum Order: SQLBuilderAppendable, Sendable {
    /// ASC order.
    case ascending
    /// DESC order.
    case descending

    public func append(to builder: inout SQLBuilder) {
        switch self {
        case .ascending:
            builder.sql.append("ASC")
        case .descending:
            builder.sql.append("DESC")
        }
    }
}
