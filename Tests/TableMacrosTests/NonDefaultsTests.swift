//
//  NonDefaultsTests.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TableMacros)
    import TableMacros

    private let testMacros: [String: Macro.Type] = [
        "Table": TableMacro.self,
        "Column": ColumnMacro.self,
    ]
#endif

final class NonDefaultsTests: XCTestCase {
    func testMacroWithNonDefaultParameters() throws {
        #if canImport(TableMacros)
            assertMacroExpansion(
                """
                @Table("papaya") struct Contact {
                    @Column("apple", primaryKey: true) var id: Int32
                    @Column("pickle", insert: false) var name: String?
                    @Column("banana") var age: Int
                    @Column("peach") var gender: String
                    @Column("created_at", update: false) var createdAt: Date
                    @Column("updated_at") var updatedAt: Date
                }
                """,
                expandedSource: """
                struct Contact {
                    var id: Int32
                    var name: String?
                    var age: Int
                    var gender: String
                    var createdAt: Date
                    var updatedAt: Date

                    init(id: Int32 , name: String? , age: Int , gender: String , createdAt: Date , updatedAt: Date ) {
                        self.id = id
                        self.name = name
                        self.age = age
                        self.gender = gender
                        self.createdAt = createdAt
                        self.updatedAt = updatedAt
                    }

                    static var table: _TableRef {
                        _TableRef()
                    }

                    static func table(as alias: String) -> _TableRef {
                        _TableRef(as: alias)
                    }

                    struct _TableRef: TableRef {
                        typealias TableType = Contact
                        let _identifier = "\\"papaya\\""
                        let _alias: String?
                        let id: TypedColumnRef<Int32>
                        let name: TypedColumnRef<String?>
                        let age: TypedColumnRef<Int>
                        let gender: TypedColumnRef<String>
                        let createdAt: TypedColumnRef<Date>
                        let updatedAt: TypedColumnRef<Date>
                        init(as alias: String? = nil) {
                            self._alias = alias.map {
                                "\\"\\($0.replacingOccurrences(of: "\\"", with: "\\"\\""))\\""
                            }
                            let _source = _alias ?? _identifier
                            id = TypedColumnRef(named: "\\"apple\\"", of: _source)
                            name = TypedColumnRef(named: "\\"pickle\\"", of: _source)
                            age = TypedColumnRef(named: "\\"banana\\"", of: _source)
                            gender = TypedColumnRef(named: "\\"peach\\"", of: _source)
                            createdAt = TypedColumnRef(named: "\\"created_at\\"", of: _source)
                            updatedAt = TypedColumnRef(named: "\\"updated_at\\"", of: _source)
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
                        var _readColumnSqlRefs: [String] {
                            [id._sqlRef, name._sqlRef, age._sqlRef, gender._sqlRef, createdAt._sqlRef, updatedAt._sqlRef]
                        }
                    }
                }

                extension Contact: RelationalSwift.Table {
                    static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> Contact {
                        Contact(
                            id: try Int32.column(of: stmt, at: &index),
                            name: try String?.column(of: stmt, at: &index),
                            age: try Int.column(of: stmt, at: &index),
                            gender: try String.column(of: stmt, at: &index),
                            createdAt: try Date.column(of: stmt, at: &index),
                            updatedAt: try Date.column(of: stmt, at: &index)
                        )
                    }
                }

                extension Contact: RelationalSwift.Insertable {
                    static let readByRowIDAction: (String, @Sendable (Int64) -> Binder) =
                        (
                            \"""
                            SELECT "apple", "pickle", "banana", "peach", "created_at", "updated_at"
                            FROM "papaya"
                            WHERE rowid = ?
                            \""",
                            { rowID in
                                { stmt, index in
                                    // WHERE
                                    try Int64.bind(to: stmt, value: rowID, at: &index)
                                }
                            }
                        )
                    static let insertAction: (String, @Sendable (Contact) -> Binder) =
                        (
                            \"""
                            INSERT INTO "papaya" ("apple", "banana", "peach", "created_at", "updated_at")
                            VALUES (?, ?, ?, ?, ?)
                            \""",
                            { row in
                                { stmt, index in
                                    // VALUES
                                    try Int32.bind(to: stmt, value: row.id, at: &index)
                                    try Int.bind(to: stmt, value: row.age, at: &index)
                                    try String.bind(to: stmt, value: row.gender, at: &index)
                                    try Date.bind(to: stmt, value: row.createdAt, at: &index)
                                    try Date.bind(to: stmt, value: row.updatedAt, at: &index)
                                }
                            }
                        )
                    static let createTableAction: String =
                        \"""
                        CREATE TABLE "papaya" (
                            "apple" \\(Int32.detaultSQLStorageType) NOT NULL,
                            "pickle" \\(String?.detaultSQLStorageType),
                            "banana" \\(Int.detaultSQLStorageType) NOT NULL,
                            "peach" \\(String.detaultSQLStorageType) NOT NULL,
                            "created_at" \\(Date.detaultSQLStorageType) NOT NULL,
                            "updated_at" \\(Date.detaultSQLStorageType) NOT NULL,
                            PRIMARY KEY ("apple")
                        )
                        \"""
                }

                extension Contact: RelationalSwift.PrimaryKeyMutable {
                    typealias KeyType = (Int32)
                    static let updateAction: (String, @Sendable (Contact) -> Binder) =
                        (
                            \"""
                            UPDATE "papaya" SET "pickle" = ?, "banana" = ?, "peach" = ?, "updated_at" = ?
                            WHERE "apple" == ?
                            \""",
                            { row in
                                { stmt, index in
                                    // SET
                                    try String?.bind(to: stmt, value: row.name, at: &index)
                                    try Int.bind(to: stmt, value: row.age, at: &index)
                                    try String.bind(to: stmt, value: row.gender, at: &index)
                                    try Date.bind(to: stmt, value: row.updatedAt, at: &index)

                                    // WHERE
                                    try Int32.bind(to: stmt, value: row.id, at: &index)
                                }
                            }
                        )
                    static func updateAction(_ row: Self, columns: [PartialKeyPath<Self>]) throws -> (String, Binder) {
                        var sets = [String]()
                        var setBinds = [Binder]()

                        for column in columns {
                            if false {
                                /* do nothing */
                            } else if column == \\.name {
                        sets.append("\\"pickle\\" = ?")
                        setBinds.append(row.name.asBinder)
                            } else if column == \\.age {
                        sets.append("\\"banana\\" = ?")
                        setBinds.append(row.age.asBinder)
                            } else if column == \\.gender {
                        sets.append("\\"peach\\" = ?")
                        setBinds.append(row.gender.asBinder)
                            } else if column == \\.updatedAt {
                        sets.append("\\"updated_at\\" = ?")
                        setBinds.append(row.updatedAt.asBinder)
                            } else {
                                throw TableError(message: "\\(column) is not a column")
                            }
                        }

                        return (
                            \"""
                            UPDATE "papaya" SET \\(sets.joined(separator: ", "))
                            WHERE "apple" == ?
                            \""",
                            { [setBinds] stmt, index in
                                // SET
                                for bind in setBinds {
                                    try bind(stmt, &index)
                                }

                                // WHERE
                                try Int32.bind(to: stmt, value: row.id, at: &index)
                            }
                        )
                    }
                    static let deleteAction: (String, @Sendable (Contact) -> Binder) =
                        (
                            \"""
                            DELETE FROM "papaya"
                            WHERE "apple" == ?
                            \""",
                            { row in
                                { stmt, index in
                                    // WHERE
                                    try Int32.bind(to: stmt, value: row.id, at: &index)
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
