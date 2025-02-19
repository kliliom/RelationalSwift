//
//  TableDecl.swift
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct TableDecl {
    var codeName: String
    var attribute: TableAttribute
    var columns: [ColumnDecl] = []

    var sqlIdentifier: String {
        (attribute.name ?? codeName).sqlIdentifier
    }

    var sqlIdentifierLiteral: String {
        "\"\(sqlIdentifier.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    static func read(
        from decl: some DeclGroupSyntax
    ) throws -> TableDecl {
        guard let decl = decl.as(StructDeclSyntax.self) else {
            throw ExpansionError(node: decl, message: "`Table` attribute can only be placed on structs")
        }

        let tableAttrs = decl.attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .filter { $0.attributeName.trimmedDescription == "Table" }
        guard tableAttrs.count == 1, let tableAttr = tableAttrs.first else {
            throw ExpansionError(node: decl, message: "Struct declarations must have exactly one `Table` attribute")
        }
        let attribute = try TableAttribute.read(from: tableAttr)

        var columns: [ColumnDecl] = []
        for member in decl.memberBlock.members {
            if member.decl.is(FunctionDeclSyntax.self) {
                continue
            }
            if member.decl.is(InitializerDeclSyntax.self) {
                continue
            }

            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                throw ExpansionError(node: member, message: "Tables can only have variable declarations")
            }

            try columns.append(ColumnDecl.read(from: varDecl))
        }

        return TableDecl(
            codeName: decl.name.text,
            attribute: attribute,
            columns: columns
        )
    }
}
