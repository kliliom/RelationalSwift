//
//  Macros.swift
//

@attached(
    member,
    names: named(table), named(table(as:)),
    arbitrary
)
@attached(
    extension,
    conformances: Table, PrimaryKeyAccessible, PrimaryKeyMutable, Insertable,
    names:
    named(name), named(read(from:startingAt:)),
    named(_primaryKey), named(selectAction), named(selectRowIDAction),
    named(insertAction), named(readByRowIDAction), named(createTableAction),
    named(KeyType), named(updateAction), named(partialUpdateAction), named(upsertAction), named(deleteAction)
)
public macro Table(
    _ name: String? = nil,
    readOnly: Bool = false
) = #externalMacro(module: "RelationalSwiftMacros", type: "TableMacro")

@attached(peer)
public macro Column(
    _ name: String? = nil,
    primaryKey: Bool = false,
    insert: Bool? = nil,
    update: Bool? = nil
) = #externalMacro(module: "RelationalSwiftMacros", type: "ColumnMacro")
