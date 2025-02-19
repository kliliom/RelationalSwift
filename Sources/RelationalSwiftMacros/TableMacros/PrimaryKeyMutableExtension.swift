//
//  PrimaryKeyMutableExtension.swift
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
        static let updateAction: (String, @Sendable (\(table.codeName)) -> Database.ManagedBinder) =
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
                    setBinds.append(row.\($0.codeName).managedBinder)
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
        static func partialUpdateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Database.ManagedBinder) {
            var sets = [String]()
            var setBinds = [Database.ManagedBinder]()

            for column in columns {
                if false {
                    /* do nothing */
                \(columnCases)
                } else {
                    throw RelationalSwiftError.notAColumn(column: String(describing: column))
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

    private var upsertFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        guard pks.allSatisfy({ $0.attribute.insert ?? true }) else {
            return DeclSyntax(stringLiteral: """
            static let upsertAction: (String, @Sendable (\(table.codeName)) -> Database.ManagedBinder)? = nil
            """)
        }

        let columns = table.columns.filter { $0.attribute.insert ?? true }

        let colNames = columns
            .map(\.sqlIdentifier)
            .joined(separator: ", ")
        let values = columns
            .map { _ in "?" }
            .joined(separator: ", ")
        let valueBinds = columns
            .map { "try \($0.codeType).bind(to: stmt, value: row.\($0.codeName), at: &index)" }
            .joined(separator: "\n")
        let conflictKeys = pks
            .map(\.sqlIdentifier)
            .joined(separator: ", ")
        let updateKeys = columns
            .filter { $0.attribute.update ?? !$0.attribute.primaryKey }
            .map { "\($0.sqlIdentifier) = EXCLUDED.\($0.sqlIdentifier)" }
            .joined(separator: ", ")

        return DeclSyntax(stringLiteral: """
        static let upsertAction: (String, @Sendable (\(table.codeName)) -> Database.ManagedBinder)? =
            (
                \"\"\"
                INSERT INTO \(table.sqlIdentifier) (\(colNames))
                VALUES (\(values))
                ON CONFLICT(\(conflictKeys))
                DO UPDATE SET \(updateKeys)
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

    private var deleteFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        precondition(!pks.isEmpty)

        let wheres: String
        let whereBinds: String
        if pks.count == 1, let pk = pks.first {
            wheres = "\(pk.sqlIdentifier) == ?"
            whereBinds = "try \(pk.codeType).bind(to: stmt, value: key, at: &index)"
        } else {
            wheres = pks
                .map { "\($0.sqlIdentifier) == ?" }
                .joined(separator: " AND ")
            whereBinds = pks
                .enumerated()
                .map { "try \($0.1.codeType).bind(to: stmt, value: key.\($0.0), at: &index)" }
                .joined(separator: "\n")
        }

        return DeclSyntax(stringLiteral: """
        static let deleteAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
            (
                \"\"\"
                DELETE FROM \(table.sqlIdentifier)
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

    private func delcarations() -> [DeclSyntax] {
        [
            typealiasDecl,
            updateFuncDecl,
            partialUpdateFuncDecl,
            upsertFuncDecl,
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
