//
//  PrimaryKeyMutableExtension.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct PrimaryKeyMutableExtension {
    let table: TableDecl

    private var typealiasDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let keyTypes = pks
            .map(\.codeType.description)
            .joined(separator: ", ")
        return DeclSyntax(stringLiteral: """
            typealias KeyType = (\(keyTypes))
            """
        )
    }

    private var updateFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let columns = table.columns.filter { $0.attribute.update ?? !$0.attribute.primaryKey }
        let sets = columns
            .map { "\($0.sqlIdentifier) = ?" }
            .joined(separator: ", ")
        let setBinds = columns
            .map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }
            .joined(separator: "\n")
        let wheres = pks
            .map { "\($0.sqlIdentifier) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let updateAction: (String, @Sendable (\(table.codeName)) -> Binder) =
            (
                \"\"\"
                UPDATE \(table.sqlIdentifier) SET \(sets)
                WHERE \(wheres)
                \"\"\",
                { row in
                    { stmt, index in
                        // SET
                        \(setBinds)

                        // WHERE
                        \(whereBinds)
                    }
                }
            )
        """)
    }

    private var partialUpdateFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let columns = table.columns.filter { $0.attribute.update ?? !$0.attribute.primaryKey }
        let columnCases = columns
            .map {
                """
                } else if column == \\.\($0.codeName) {
                    sets.append("\($0.sqlIdentifier.replacingOccurrences(of: "\"", with: "\\\"")) = ?")
                    setBinds.append(row.\($0.codeName).asBinder)
                """
            }
            .joined(separator: "\n")
        let wheres = pks
            .map { "\($0.sqlIdentifier) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static func updateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Binder) {
            var sets = [String]()
            var setBinds = [Binder]()

            for column in columns {
                if false {
                    /* do nothing */
                \(columnCases)
                } else {
                    throw TableError(message: "\\(column) is not a column")
                }
            }

            return (
                \"\"\"
                UPDATE \(table.sqlIdentifier) SET \\(sets.joined(separator: ", "))
                WHERE \(wheres)
                \"\"\",
                { [setBinds] stmt, index in
                    // SET
                    for bind in setBinds {
                        try bind(stmt, &index)
                    }

                    // WHERE
                    \(whereBinds)
                }
            )
        }
        """)
    }

    private var deleteFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let wheres = pks
            .map { "\($0.sqlIdentifier) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let deleteAction: (String, @Sendable (\(table.codeName)) -> Binder) =
            (
                \"\"\"
                DELETE FROM \(table.sqlIdentifier)
                WHERE \(wheres)
                \"\"\",
                { row in
                    { stmt, index in
                        // WHERE
                        \(whereBinds)
                    }
                }
            )
        """)
    }

    private func delcarations() -> [DeclSyntax] {
        [
            typealiasDecl,
            updateFuncDecl,
            partialUpdateFuncDecl,
            deleteFuncDecl,
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
                        type: TypeSyntax(stringLiteral: "RelationalSwift.PrimaryKeyMutable")
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
