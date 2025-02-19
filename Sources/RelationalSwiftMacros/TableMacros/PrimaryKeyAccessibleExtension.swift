//
//  PrimaryKeyAccessibleExtension.swift
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct PrimaryKeyAccessibleExtension {
    let table: TableDecl

    private var primaryKeyVarDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        var keyTypes = pks
            .map(\.codeName)
            .joined(separator: ", ")

        if pks.count > 1 {
            keyTypes = "(\(keyTypes))"
        }
        return DeclSyntax(stringLiteral: """
            var _primaryKey: KeyType {
                \(keyTypes)
            }
            """
        )
    }

    private var readVarDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let wheres = pks
            .map { "\($0.sqlIdentifier) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .enumerated()
            .map { ($0.element.codeType, pks.count > 1 ? "key.\($0.offset)" : "key") }
            .map { "try \($0.0).bind(to: stmt, value: \($0.1), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let selectAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
            (
                \"\"\"
                SELECT * FROM \(table.sqlIdentifier)
                WHERE \(wheres)
                \"\"\",
                { key in
                    { stmt, index in
                        // WHERE
                        \(whereBinds)
                    }
                }
            )
        """)
    }

    private var readRowIDVarDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let wheres = pks
            .map { "\($0.sqlIdentifier) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .enumerated()
            .map { ($0.element.codeType, pks.count > 1 ? "key.\($0.offset)" : "key") }
            .map { "try \($0.0).bind(to: stmt, value: \($0.1), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let selectRowIDAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
            (
                \"\"\"
                SELECT rowid FROM \(table.sqlIdentifier)
                WHERE \(wheres)
                \"\"\",
                { key in
                    { stmt, index in
                        // WHERE
                        \(whereBinds)
                    }
                }
            )
        """)
    }

    func delcarations() -> [DeclSyntax] {
        [
            primaryKeyVarDecl,
            readVarDecl,
            readRowIDVarDecl,
        ]
    }

    static func syntax(
        for table: TableDecl
    ) -> ExtensionDeclSyntax? {
        guard !table.attribute.readOnly,
              table.columns.contains(where: \.attribute.primaryKey)
        else {
            return nil
        }

        let declarations = Self(table: table).delcarations()
        let ext = ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: table.codeName),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax(
                    arrayLiteral: InheritedTypeSyntax(
                        type: TypeSyntax(stringLiteral: "RelationalSwift.PrimaryKeyAccessible")
                    )
                )
            ),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax(
                    declarations.map { MemberBlockItemSyntax(decl: $0) }
                )
            )
        )
        return ext
    }
}
