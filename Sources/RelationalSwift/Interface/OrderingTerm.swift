//
//  OrderingTerm.swift
//

public enum OrderingTerm: Sendable {
    public enum NullPosition: Sendable {
        case first
        case last
    }

    case asc(any Expression, nullPosition: NullPosition? = nil)
    case desc(any Expression, nullPosition: NullPosition? = nil)
}

extension OrderingTerm: SQLBuilderAppendable {
    private var sqlOrder: String {
        switch self {
        case .asc:
            "ASC"
        case .desc:
            "DESC"
        }
    }

    public func append(to builder: inout SQLBuilder) {
        switch self {
        case let .asc(expression, nullPosition),
             let .desc(expression, nullPosition):
            expression.append(to: &builder)

            builder.sql.append(sqlOrder)

            switch nullPosition {
            case .none:
                break
            case .first:
                builder.sql.append("NULLS FIRST")
            case .last:
                builder.sql.append("NULLS LAST")
            }
        }
    }
}
