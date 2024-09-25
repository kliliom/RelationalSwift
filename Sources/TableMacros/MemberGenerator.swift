//
//  MemberGenerator.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct MemberGenerator {
    let table: TableDecl

    private var memberwiseInitDecl: DeclSyntax {
        let params = table.columns.map { "\($0.codeName): \($0.codeType) " }.joined(separator: ", ")
        let assigns = table.columns.map { "self.\($0.codeName) = \($0.codeName) " }.joined(separator: "\n")
        return DeclSyntax(stringLiteral: """
        init(\(params)) {
            \(assigns)
        }
        """)
    }

    private var staticTableVarDecl: DeclSyntax {
        DeclSyntax(stringLiteral: """
        static var table: _TableRef {
            _TableRef()
        }
        """)
    }

    private var staticTableFuncDecl: DeclSyntax {
        DeclSyntax(stringLiteral: """
        static func table(as alias: String) -> _TableRef {
            _TableRef(as: alias)
        }
        """)
    }

    private var tableRefStruct: DeclSyntax {
        var members: [String] = []

        members.append("""
        typealias TableType = \(table.codeName)
        """)

        members.append("""
        let _name = "\(table.sqlName)"
        """)

        members.append("""
        let _alias: String?
        """)

        for column in table.columns {
            members.append("""
            let \(column.codeName): TypedColumnRef<\(column.codeType)>
            """)
        }

        members.append("""
        init(as alias: String? = nil) {
            self._alias = alias
            let _source = alias ?? _name
            \(table.columns.map { "\($0.codeName) = TypedColumnRef(named: \($0.sqlName.quoted), of: _source)" }.joined(separator: "\n"))
        }
        """)

        members.append("""
        var _sqlFrom: String {
            if let _alias {
                "\\"\\(_name)\\" AS \\(_alias)"
            } else {
                "\\"\\(_name)\\""
            }
        }
        """)

        members.append("""
        var _sqlRef: String {
            if let _alias {
                "\\"\\(_alias)\\""
            } else {
                "\\"\\(_name)\\""
            }
        }
        """)

        members.append("""
        var _readColumnSqlRefs: [String] {
            [\(table.columns.map { "\($0.codeName)._sqlRef" }.joined(separator: ", "))]
        }
        """)

        return DeclSyntax(
            fromProtocol: StructDeclSyntax(
                name: "_TableRef",
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: InheritedTypeListSyntax(
                        arrayLiteral: InheritedTypeSyntax(
                            type: TypeSyntax(stringLiteral: "TableRef")
                        )
                    )
                ),
                memberBlock: MemberBlockSyntax(
                    members: MemberBlockItemListSyntax(members.map { literal in
                        MemberBlockItemSyntax(decl: DeclSyntax(stringLiteral: literal))
                    })
                )
            )
        )
    }

    func delcarations() -> [DeclSyntax] {
        [
            memberwiseInitDecl,
            staticTableVarDecl,
            staticTableFuncDecl,
            tableRefStruct,
        ]
    }
}
