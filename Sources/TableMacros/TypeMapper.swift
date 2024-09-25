//
//  TypeMapper.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

class TypeMapper {
    let defaultTypeMap = [
        "Int": "INTEGER",
        "Int32": "INTEGER",
        "Int64": "INTEGER",

        "Bool": "INTEGER",

        "Float": "FLOAT",
        "Double": "DOUBLE",

        "String": "TEXT",

        "Date": "DOUBLE",

        "UUID": "BLOB",
        "Data": "BLOB",
    ]

    func sqlType(for column: ColumnDecl) -> String {
        let defaultType = defaultTypeMap[column.codeType.storedType] ?? "BLOB"
        print("column.codeType", column.codeType, "defaultType", defaultType)
        return defaultType
    }
}
