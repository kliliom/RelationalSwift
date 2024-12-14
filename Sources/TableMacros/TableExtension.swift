//
//  TableExtension.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct TableExtension {
    let table: TableDecl

    private var nameDecl: DeclSyntax {
        let nameSyntax = SimpleStringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: [
                StringSegmentSyntax(content: .stringSegment(table.attribute.name ?? table.codeName)),
            ],
            closingQuote: .stringQuoteToken()
        )

        return DeclSyntax(stringLiteral: """
        static var name: String {
            \(nameSyntax)
        }
        """)
    }

    private var readFuncDecl: DeclSyntax {
        let fields = table.columns
            .map { "\($0.codeName): try \($0.codeType).column(of: stmt, at: &index)" }
            .joined(separator: ",\n")

        return DeclSyntax(stringLiteral: """
        static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> \(table.codeName) {
            \(table.codeName)(
                \(fields)
            )
        }
        """)
    }

    private func delcarations() -> [DeclSyntax] {
        [
            nameDecl,
            readFuncDecl,
        ]
    }

    static func syntax(
        for table: TableDecl
    ) -> ExtensionDeclSyntax {
        let declarations = Self(table: table).delcarations()
        let ext = ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: table.codeName),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax(
                    arrayLiteral: InheritedTypeSyntax(
                        type: TypeSyntax(stringLiteral: "RelationalSwift.Table")
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
