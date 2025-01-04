//
//  SelectBuilder.swift
//  Created by Kristof Liliom in 2024.
//

func buildSelect(
    into builder: SQLBuilder,
    from table: String,
    columns: [any Expression],
    condition: (some Expression)? = nil,
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
        column.append(to: builder)
    }

    builder.sql.append("FROM")
    builder.sql.append(table)

    if let condition {
        builder.sql.append("WHERE")
        condition.append(to: builder)
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
