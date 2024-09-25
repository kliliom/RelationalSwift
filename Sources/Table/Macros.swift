//
//  Macros.swift
//  Created by Kristof Liliom in 2024.
//

@attached(
    member,
    names: named(table), named(table(as:)),
    arbitrary
)
@attached(
    extension,
    names: named(read(from:startingAt:)), named(read(rowID:)), named(insert(entry:)), named(update(entry:)), named(delete(entry:)), named(createTable()),
    conformances: Table
)
public macro Table(
    _ name: String? = nil
) = #externalMacro(module: "TableMacros", type: "TableMacro")

@attached(peer)
public macro Column(
    _ name: String? = nil,
    primaryKey: Bool = false,
    insert: Bool? = nil,
    update: Bool? = nil
) = #externalMacro(module: "TableMacros", type: "ColumnMacro")
