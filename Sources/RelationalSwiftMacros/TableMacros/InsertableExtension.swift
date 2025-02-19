//
//  InsertableExtension.swift
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct InsertableExtension {
    let table: TableDecl

    private var readRowIDFuncDecl: DeclSyntax {
        let fields = table.columns
            .map(\.sqlIdentifier)
            .joined(separator: ", ")

        return DeclSyntax(stringLiteral: """
        static let readByRowIDAction: (String, @Sendable (Int64) -> Database.ManagedBinder) =
            (
                \"\"\"
                SELECT \(fields)
                FROM \(table.sqlIdentifier)
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

        let colNames = columns.map(\.sqlIdentifier).joined(separator: ", ")
        let values = columns.map { _ in "?" }.joined(separator: ", ")
        let valueBinds = columns.map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }.joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static let insertAction: (String, @Sendable (\(table.codeName)) -> Database.ManagedBinder) =
            (
                \"\"\"
                INSERT INTO \(table.sqlIdentifier) (\(colNames))
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
        var columns = table.columns.map { column in
            var constraints = ""
            if !column.codeType.isOptional {
                constraints += " NOT NULL"
            }
            return "\(column.sqlIdentifier) \\(\(column.codeType.description).detaultSQLStorageType)\(constraints)"
        }

        let pks = table.columns.filter(\.attribute.primaryKey)
        if !pks.isEmpty {
            let pk = "PRIMARY KEY (\(pks.map(\.sqlIdentifier).joined(separator: ", ")))"
            columns.append(pk)
        }

        return DeclSyntax(stringLiteral: """
        static let createTableAction: String =
            \"\"\"
            CREATE TABLE \(table.sqlIdentifier) (
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
