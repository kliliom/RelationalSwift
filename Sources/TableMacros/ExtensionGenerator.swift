//
//  ExtensionGenerator.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ExtensionGenerator {
    let table: TableDecl

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

    private var readRowIDFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)

        if pks.isEmpty {
            return DeclSyntax(stringLiteral: """
            static func read(rowID: Int64) throws -> (String, Binder) {
                throw DB4SwiftError(message: "table \(table.codeName) does not have primary keys, read(rowID) not supported")
            }
            """)
        }

        let fields = table.columns
            .map { "\($0.sqlName.quoted)" }
            .joined(separator: ", ")

        return DeclSyntax(stringLiteral: """
        static func read(rowID: Int64) throws -> (String, Binder) {
            (
                \"\"\"
                SELECT \(fields)
                FROM \(table.sqlName.quoted)
                WHERE rowid = ?
                \"\"\",
                { stmt, index in
                    try Int64.bind(to: stmt, value: rowID, at: &index)
                }
            )
        }
        """)
    }

    private var insertFuncDecl: DeclSyntax {
        let columns = table.columns.filter { $0.attribute.insert ?? !$0.attribute.primaryKey }

        let colNames = columns.map(\.sqlName.quoted).joined(separator: ", ")
        let values = columns.map { _ in "?" }.joined(separator: ", ")
        let valueBinds = columns.map { "try \($0.codeType).bind(to: stmt, value: entry.\($0.codeName), at: &index)" }.joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static func insert(entry: \(table.codeName)) throws -> (String, Binder) {
            (
                \"\"\"
                INSERT INTO \(table.sqlName.quoted) (\(colNames))
                VALUES (\(values))
                \"\"\",
                { stmt, index in
                    \(valueBinds)
                }
            )
        }
        """)
    }

    private var updateFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)
        let columns = table.columns.filter { $0.attribute.update ?? !$0.attribute.primaryKey }

        if pks.isEmpty {
            return DeclSyntax(stringLiteral: """
            static func update(entry: \(table.codeName)) throws -> (String, Binder) {
                throw DB4SwiftError(message: "table \(table.codeName) does not have primary keys, update not supported")
            }
            """)
        }

        let sets = columns
            .map { "\($0.sqlName.quoted) = ?" }
            .joined(separator: ", ")
        let setBinds = columns
            .map { "try \($0.codeType).bind(to: stmt, value: entry.\($0.codeName), at: &index)" }
            .joined(separator: "\n")
        let wheres = pks
            .map { "\($0.sqlName.quoted) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .map { "try \($0.codeType).bind(to: stmt, value: entry.\($0.codeName), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static func update(entry: \(table.codeName)) throws -> (String, Binder) {
            (
                \"\"\"
                UPDATE \(table.sqlName.quoted) SET \(sets)
                WHERE \(wheres)
                \"\"\",
                { stmt, index in
                    // Set
                    \(setBinds)

                    // Where
                    \(whereBinds)
                }
            )
        }
        """)
    }

    private var deleteFuncDecl: DeclSyntax {
        let pks = table.columns.filter(\.attribute.primaryKey)

        if pks.isEmpty {
            return DeclSyntax(stringLiteral: """
            static func delete(entry: \(table.codeName)) throws -> (String, Binder) {
                throw DB4SwiftError(message: "table \(table.codeName) does not have primary keys, delete not supported")
            }
            """)
        }

        let wheres = pks
            .map { "\($0.sqlName.quoted) == ?" }
            .joined(separator: " AND ")
        let whereBinds = pks
            .map { "try \($0.codeType).bind(to: stmt, value: entry.\($0.codeName), at: &index)" }
            .joined(separator: "\n")

        return DeclSyntax(stringLiteral: """
        static func delete(entry: \(table.codeName)) throws -> (String, Binder) {
            (
                \"\"\"
                DELETE FROM \(table.sqlName.quoted)
                WHERE \(wheres)
                \"\"\",
                { stmt, index in
                    \(whereBinds)
                }
            )
        }
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
        static func createTable() throws -> String {
            \"\"\"
            CREATE TABLE \(table.sqlName.quoted) (
                \(columns.joined(separator: ",\n        "))
            )
            \"\"\"
        }
        """)
    }

    func delcarations() -> [DeclSyntax] {
        [
            readFuncDecl,
            readRowIDFuncDecl,
            insertFuncDecl,
            updateFuncDecl,
            deleteFuncDecl,
            createTableDecl,
        ]
    }
}
