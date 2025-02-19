//
//  DeleteBuilder.swift
//

import Foundation

func buildDelete(
    into builder: SQLBuilder,
    from table: String,
    condition: (some Expression)?
) {
    builder.sql.append("DELETE FROM")
    builder.sql.append(table)

    if let condition {
        builder.sql.append("WHERE")
        condition.append(to: builder)
    }
}
