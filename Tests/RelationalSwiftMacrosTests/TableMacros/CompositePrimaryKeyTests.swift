//
//  CompositePrimaryKeyTests.swift
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(RelationalSwiftMacros)
    import RelationalSwiftMacros

    private let testMacros: [String: Macro.Type] = [
        "Table": TableMacro.self,
        "Column": ColumnMacro.self,
    ]
#endif

final class CompositePrimaryKeyTests: XCTestCase {
    func testMacroWithNonDefaultParameters() throws {
        #if canImport(RelationalSwiftMacros)
            assertMacroExpansion(
                """
                @Table struct Contact {
                    @Column(primaryKey: true) var id1: Int32
                    @Column(primaryKey: true) var id2: String
                }
                """,
                expandedSource: """
                struct Contact {
                    var id1: Int32
                    var id2: String

                    init(id1: Int32 , id2: String ) {
                        self.id1 = id1
                        self.id2 = id2
                    }

                    static var table: _TableRef {
                        _TableRef()
                    }

                    static func table(as alias: String) -> _TableRef {
                        _TableRef(as: alias)
                    }

                    struct _TableRef: TableRef {
                        typealias TableType = Contact
                        let _identifier = "\\"Contact\\""
                        let _alias: String?
                        let id1: TypedColumnRef<Int32>
                        let id2: TypedColumnRef<String>
                        init(as alias: String? = nil) {
                            self._alias = alias.map {
                                "\\"\\($0.replacingOccurrences(of: "\\"", with: "\\"\\""))\\""
                            }
                            let _source = _alias ?? _identifier
                            id1 = TypedColumnRef(named: "\\"id1\\"", of: _source)
                            id2 = TypedColumnRef(named: "\\"id2\\"", of: _source)
                        }
                        var _sqlFrom: String {
                            if let _alias {
                                "\\(_identifier) AS \\(_alias)"
                            } else {
                                _identifier
                            }
                        }
                        var _sqlRef: String {
                            if let _alias {
                                _alias
                            } else {
                                _identifier
                            }
                        }
                        var _allColumnRefs: [any ColumnRef] {
                            [id1, id2]
                        }
                    }
                }

                extension Contact: RelationalSwift.Table {
                    static var name: String {
                        "Contact"
                    }
                    static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> Contact {
                        Contact(
                            id1: try Int32.column(of: stmt, at: &index),
                            id2: try String.column(of: stmt, at: &index)
                        )
                    }
                }

                extension Contact: RelationalSwift.Insertable {
                    static let readByRowIDAction: (String, @Sendable (Int64) -> Database.ManagedBinder) =
                        (
                            \"""
                            SELECT "id1", "id2"
                            FROM "Contact"
                            WHERE rowid = ?
                            \""",
                            { rowID in
                                { stmt, index in
                                    // WHERE
                                    try Int64.bind(to: stmt, value: rowID, at: &index)
                                }
                            }
                        )
                    static let insertAction: (String, @Sendable (Contact) -> Database.ManagedBinder) =
                        (
                            \"""
                            INSERT INTO "Contact" ("id1", "id2")
                            VALUES (?, ?)
                            \""",
                            { row in
                                { stmt, index in
                                    // VALUES
                                    try Int32.bind(to: stmt, value: row.id1, at: &index)
                                    try String.bind(to: stmt, value: row.id2, at: &index)
                                }
                            }
                        )
                    static let createTableAction: String =
                        \"""
                        CREATE TABLE "Contact" (
                            "id1" \\(Int32.detaultSQLStorageType) NOT NULL,
                            "id2" \\(String.detaultSQLStorageType) NOT NULL,
                            PRIMARY KEY ("id1", "id2")
                        )
                        \"""
                }

                extension Contact: RelationalSwift.PrimaryKeyAccessible {
                    var _primaryKey: KeyType {
                        (id1, id2)
                    }
                    static let selectAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
                        (
                            \"""
                            SELECT * FROM "Contact"
                            WHERE "id1" == ? AND "id2" == ?
                            \""",
                            { key in
                                { stmt, index in
                                    // WHERE
                                    try Int32.bind(to: stmt, value: key.0, at: &index)
                                    try String.bind(to: stmt, value: key.1, at: &index)
                                }
                            }
                        )
                    static let selectRowIDAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
                        (
                            \"""
                            SELECT rowid FROM "Contact"
                            WHERE "id1" == ? AND "id2" == ?
                            \""",
                            { key in
                                { stmt, index in
                                    // WHERE
                                    try Int32.bind(to: stmt, value: key.0, at: &index)
                                    try String.bind(to: stmt, value: key.1, at: &index)
                                }
                            }
                        )
                }

                extension Contact: RelationalSwift.PrimaryKeyMutable {
                    typealias KeyType = (Int32, String)
                    static let updateAction: (String, @Sendable (Contact) -> Database.ManagedBinder) =
                        (
                            \"""
                            UPDATE "Contact" SET 
                            WHERE "id1" == ? AND "id2" == ?
                            \""",
                            { row in
                                { stmt, index in
                                    // SET


                                    // WHERE
                                    try Int32.bind(to: stmt, value: row.id1, at: &index)
                                    try String.bind(to: stmt, value: row.id2, at: &index)
                                }
                            }
                        )
                    static func partialUpdateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Database.ManagedBinder) {
                        var sets = [String]()
                        var setBinds = [Database.ManagedBinder]()

                        for column in columns {
                            if false {
                                /* do nothing */

                            } else {
                                throw RelationalSwiftError.notAColumn(column: String(describing: column))
                            }
                        }

                        return (
                            \"""
                            UPDATE "Contact" SET \\(sets.joined(separator: ", "))
                            WHERE "id1" == ? AND "id2" == ?
                            \""",
                            { [setBinds] stmt, index in
                                // SET
                                for bind in setBinds {
                                    try bind(stmt, &index)
                                }

                                // WHERE
                                try Int32.bind(to: stmt, value: row.id1, at: &index)
                                try String.bind(to: stmt, value: row.id2, at: &index)
                            }
                        )
                    }
                    static let upsertAction: (String, @Sendable (Contact) -> Database.ManagedBinder)? =
                        (
                            \"""
                            INSERT INTO "Contact" ("id1", "id2")
                            VALUES (?, ?)
                            ON CONFLICT("id1", "id2")
                            DO UPDATE SET 
                            \""",
                            { row in
                                { stmt, index in
                                    // VALUES
                                    try Int32.bind(to: stmt, value: row.id1, at: &index)
                                    try String.bind(to: stmt, value: row.id2, at: &index)
                                }
                            }
                        )
                    static let deleteAction: (String, @Sendable (KeyType) -> Database.ManagedBinder) =
                        (
                            \"""
                            DELETE FROM "Contact"
                            WHERE "id1" == ? AND "id2" == ?
                            \""",
                            { key in
                                { stmt, index in
                                    // WHERE
                                    try Int32.bind(to: stmt, value: key.0, at: &index)
                                    try String.bind(to: stmt, value: key.1, at: &index)
                                }
                            }
                        )
                }
                """,
                macros: testMacros
            )
        #else
            try XCTSkipUnless(false, "This test should only be ran on host platform")
        #endif
    }
}
