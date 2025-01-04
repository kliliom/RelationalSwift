//
//  ConflictResolution.swift
//  Created by Kristof Liliom in 2024.
//

/// Method to resolve conflicts.
public enum ConflictResolution: SQLConvertible, Sendable {
    /// ROLLBACK on conflict.
    case rollback
    /// ABORT on conflict.
    case abort
    /// FAIL on conflict.
    case fail
    /// IGNORE on conflict.
    case ignore
    /// REPLACE on conflict.
    case replace

    public func append(to builder: SQLBuilder) {
        switch self {
        case .rollback:
            builder.sql.append("ON CONFLICT ROLLBACK")
        case .abort:
            builder.sql.append("ON CONFLICT ABORT")
        case .fail:
            builder.sql.append("ON CONFLICT FAIL")
        case .ignore:
            builder.sql.append("ON CONFLICT IGNORE")
        case .replace:
            builder.sql.append("ON CONFLICT REPLACE")
        }
    }
}
