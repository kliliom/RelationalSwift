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
    conformances: Table, PrimaryKeyMutable, Insertable,
    names:
    named(read(from:startingAt:)),
    named(insertAction), named(readByRowIDAction), named(createTableAction),
    named(KeyType), named(updateAction), named(partialUpdateAction(_:columns:)), named(deleteAction)
)
public macro Table(
    _ name: String? = nil,
    readOnly: Bool = false
) = #externalMacro(module: "TableMacros", type: "TableMacro")

@attached(peer)
public macro Column(
    _ name: String? = nil,
    primaryKey: Bool = false,
    insert: Bool? = nil,
    update: Bool? = nil
) = #externalMacro(module: "TableMacros", type: "ColumnMacro")
