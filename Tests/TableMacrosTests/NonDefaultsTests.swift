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
                        let _name = "papaya"
                        let _alias: String?
                        let id: TypedColumnRef<Int32>
                        let name: TypedColumnRef<String?>
                        let age: TypedColumnRef<Int>
                        let gender: TypedColumnRef<String>
                        let createdAt: TypedColumnRef<Date>
                        let updatedAt: TypedColumnRef<Date>
                        init(as alias: String? = nil) {
                            self._alias = alias
                            let _source = alias ?? _name
                            id = TypedColumnRef(named: "apple", of: _source)
                            name = TypedColumnRef(named: "pickle", of: _source)
                            age = TypedColumnRef(named: "banana", of: _source)
                            gender = TypedColumnRef(named: "peach", of: _source)
                            createdAt = TypedColumnRef(named: "created_at", of: _source)
                            updatedAt = TypedColumnRef(named: "updated_at", of: _source)
                        }
                        var _sqlFrom: String {
                            if let _alias {
                                "\\"\\(_name)\\" AS \\(_alias)"
                            } else {
                                "\\"\\(_name)\\""
                            }
                        }
                        var _sqlRef: String {
                            if let _alias {
                                "\\"\\(_alias)\\""
                            } else {
                                "\\"\\(_name)\\""
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
                    static func read(rowID: Int64) throws -> (String, Binder) {
                        (
                            \"\"\"
                            SELECT "apple", "pickle", "banana", "peach", "created_at", "updated_at"
                            FROM "papaya"
                            WHERE rowid = ?
                            \"\"\",
                            { stmt, index in
                                try Int64.bind(to: stmt, value: rowID, at: &index)
                            }
                        )
                    }
                    static func insert(entry: Contact) throws -> (String, Binder) {
                        (
                            \"\"\"
                            INSERT INTO "papaya" ("banana", "peach", "created_at", "updated_at")
                            VALUES (?, ?, ?, ?)
                            \"\"\",
                            { stmt, index in
                                try Int.bind(to: stmt, value: entry.age, at: &index)
                                try String.bind(to: stmt, value: entry.gender, at: &index)
                                try Date.bind(to: stmt, value: entry.createdAt, at: &index)
                                try Date.bind(to: stmt, value: entry.updatedAt, at: &index)
                            }
                        )
                    }
                    static func update(entry: Contact) throws -> (String, Binder) {
                        (
                            \"\"\"
                            UPDATE "papaya" SET "pickle" = ?, "banana" = ?, "peach" = ?, "updated_at" = ?
                            WHERE "apple" == ?
                            \"\"\",
                            { stmt, index in
                                // Set
                                try String?.bind(to: stmt, value: entry.name, at: &index)
                                try Int.bind(to: stmt, value: entry.age, at: &index)
                                try String.bind(to: stmt, value: entry.gender, at: &index)
                                try Date.bind(to: stmt, value: entry.updatedAt, at: &index)

                                // Where
                                try Int32.bind(to: stmt, value: entry.id, at: &index)
                            }
                        )
                    }
                    static func delete(entry: Contact) throws -> (String, Binder) {
                        (
                            \"\"\"
                            DELETE FROM "papaya"
                            WHERE "apple" == ?
                            \"\"\",
                            { stmt, index in
                                try Int32.bind(to: stmt, value: entry.id, at: &index)
                            }
                        )
                    }
                    static func createTable() throws -> String {
                        \"\"\"
                        CREATE TABLE "papaya" (
                            "apple" INTEGER NOT NULL,
                            "pickle" TEXT,
                            "banana" INTEGER NOT NULL,
                            "peach" TEXT NOT NULL,
                            "created_at" DOUBLE NOT NULL,
                            "updated_at" DOUBLE NOT NULL,
                            PRIMARY KEY ("apple")
                        )
                        \"\"\"
                    }
                }
                """,
                macros: testMacros
            )
        #else
            try XCTSkipUnless(false, "This test should only be ran on host platform")
        #endif
    }
}
