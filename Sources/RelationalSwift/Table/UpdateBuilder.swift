//
//  UpdateBuilder.swift
//

import Foundation

func buildUpdate(
    into builder: inout SQLBuilder,
    in table: String,
    setters: [ColumnValueSetter],
    condition: (some Expression)?
) {
    builder.sql.append("UPDATE")
    builder.sql.append(table)
    builder.sql.append("SET")

    for (offset, setter) in setters.enumerated() {
        if offset > 0 {
            builder.sql.append(",")
        }
        builder.sql.append(setter.columnName)
        builder.sql.append("= ?")
        builder.binders.append(setter.valueBinder)
    }
    if let condition {
        builder.sql.append("WHERE")
        condition.append(to: &builder)
    }
}
