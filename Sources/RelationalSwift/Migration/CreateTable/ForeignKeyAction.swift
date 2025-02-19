//
//  ForeignKeyAction.swift
//

/// Action to take on foreign key changes.
public enum ForeignKeyAction: SQLBuilderAppendable, Sendable {
    /// CASCADE on foreign key changes.
    case cascade
    /// RESTRICT on foreign key changes.
    case restrict
    /// SET NULL on foreign key changes.
    case setNull
    /// SET DEFAULT on foreign key changes.
    case setDefault
    /// NO ACTION on foreign key changes.
    case noAction

    public func append(to builder: inout SQLBuilder) {
        switch self {
        case .cascade:
            builder.sql.append("CASCADE")
        case .restrict:
            builder.sql.append("RESTRICT")
        case .setNull:
            builder.sql.append("SET NULL")
        case .setDefault:
            builder.sql.append("SET DEFAULT")
        case .noAction:
            builder.sql.append("NO ACTION")
        }
    }
}
