//
//  InsertableExtension.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct InsertableExtension {
    let table: TableDecl

    private var readRowIDFuncDecl: DeclSyntax {
        let fields = table.columns
            .map { "\($0.sqlName.quoted)" }
            .joined(separator: ", ")

        return DeclSyntax(stringLiteral: """
        static let readByRowIDAction: (String, @Sendable (Int64) -> Binder) =
            (
                \"\"\"
                SELECT \(fields)
                FROM \(table.sqlName.quoted)
                WHERE rowid = ?
                \"\"\",
                { rowID in
                    { stmt, index in
                        // WHERE
                        try Int64.bind(to: stmt, value: rowID, at: &index)
                    }
                }
            )
        """)
    }

    private var insertFuncDecl: DeclSyntax {
        let columns = table.columns.filter { $0.attribute.insert ?? true }

        let colNames = columns.map(\.sqlName.quoted).joined(separator: ", ")
        let values = columns.map { _ in "?" }.joined(separator: ", ")
        let valueBinds = columns.map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }.joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let insertAction: (String, @Sendable (\(table.codeName)) -> Binder) =
            (
                \"\"\"
                INSERT INTO \(table.sqlName.quoted) (\(colNames))
                VALUES (\(values))
                \"\"\",
                { row in
                    { stmt, index in
                        // VALUES
                        \(valueBinds)
                    }
                }
            )
        """)
    }

    private var createTableDecl: DeclSyntax {
        let mapper = TypeMapper()
        var columns = table.columns.map { column in
            var constraints = ""
            if !column.codeType.isOptional {
                constraints += " NOT NULL"
            }
            return "\(column.sqlName.quoted) \(mapper.sqlType(for: column))\(constraints)"
        }

        let pks = table.columns.filter(\.attribute.primaryKey)
        if !pks.isEmpty {
            let pk = "PRIMARY KEY (\(pks.map(\.sqlName.quoted).joined(separator: ", ")))"
            columns.append(pk)
        }

        return DeclSyntax(stringLiteral: """
        static let createTableAction: String =
            \"\"\"
            CREATE TABLE \(table.sqlName.quoted) (
                \(columns.joined(separator: ",\n        "))
            )
            \"\"\"
        """)
    }

    private func delcarations() -> [DeclSyntax] {
        [
            readRowIDFuncDecl,
            insertFuncDecl,
            createTableDecl,
        ]
    }

    static func syntax(
        for table: TableDecl
    ) -> ExtensionDeclSyntax? {
        guard !table.attribute.readOnly else {
            return nil
        }

        let declarations = Self(table: table).delcarations()
        let ext = ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: table.codeName),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax(
                    arrayLiteral: InheritedTypeSyntax(
                        type: TypeSyntax(stringLiteral: "RelationalSwift.Insertable")
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
