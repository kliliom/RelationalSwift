//
//  SelectBuilder.swift
//

func buildSelect(
    into builder: inout SQLBuilder,
    from table: String,
    columns: [any Expression],
    condition: (any Expression)?,
    groupBy: [any Expression],
    having: (any Expression)?,
    orderBy: [OrderingTerm],
    limit: Int? = nil,
    offset: Int? = nil
) {
    builder.sql.append("SELECT")

    var isFirstColumn = true
    for column in columns {
        if isFirstColumn {
            isFirstColumn = false
        } else {
            builder.sql.append(",")
        }
        column.append(to: &builder)
    }

    builder.sql.append("FROM")
    builder.sql.append(table)

    if let condition {
        builder.sql.append("WHERE")
        condition.append(to: &builder)
    }

    if !groupBy.isEmpty {
        builder.sql.append("GROUP BY")
        var isFirstGroup = true
        for group in groupBy {
            if isFirstGroup {
                isFirstGroup = false
            } else {
                builder.sql.append(",")
            }
            group.append(to: &builder)
        }
    }

    if let having {
        builder.sql.append("HAVING")
        having.append(to: &builder)
    }

    if !orderBy.isEmpty {
        builder.sql.append("ORDER BY")
        var isFirstOrder = true
        for order in orderBy {
            if isFirstOrder {
                isFirstOrder = false
            } else {
                builder.sql.append(",")
            }
            order.append(to: &builder)
        }
    }

    if let limit {
        builder.sql.append("LIMIT ?")
        builder.binders.append(limit.managedBinder)
    }
    if let offset {
        if limit == nil {
            builder.sql.append("LIMIT -1 OFFSET ?")
        } else {
            builder.sql.append("OFFSET ?")
        }
        builder.binders.append(offset.managedBinder)
    }
}
