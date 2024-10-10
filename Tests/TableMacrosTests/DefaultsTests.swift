//
//  DefaultsTests.swift
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

final class DefaultsTests: XCTestCase {
    func testMacroWithDefaultParameters() throws {
        #if canImport(TableMacros)
            assertMacroExpansion(
                """
                @Table struct Contact {
                    @Column var id: Int32
                    @Column var name: String?
                }
                """,
                expandedSource: """
                struct Contact {
                    var id: Int32
                    var name: String?

                    init(id: Int32 , name: String? ) {
                        self.id = id
                        self.name = name
                    }

                    static var table: _TableRef {
                        _TableRef()
                    }

                    static func table(as alias: String) -> _TableRef {
                        _TableRef(as: alias)
                    }

                    struct _TableRef: TableRef {
                        typealias TableType = Contact
                        let _name = "Contact"
                        let _alias: String?
                        let id: TypedColumnRef<Int32>
                        let name: TypedColumnRef<String?>
                        init(as alias: String? = nil) {
                            self._alias = alias
                            let _source = alias ?? _name
                            id = TypedColumnRef(named: "id", of: _source)
                            name = TypedColumnRef(named: "name", of: _source)
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
                            [id._sqlRef, name._sqlRef]
                        }
                    }
                }

                extension Contact: RelationalSwift.Table {
                    static func read(from stmt: borrowing StatementHandle, startingAt index: inout ManagedIndex) throws -> Contact {
                        Contact(
                            id: try Int32.column(of: stmt, at: &index),
                            name: try String?.column(of: stmt, at: &index)
                        )
                    }
                    static func read(rowID: Int64) throws -> (String, Binder) {
                        throw DB4SwiftError(message: "table Contact does not have primary keys, read(rowID) not supported")
                    }
                    static func insert(entry: Contact) throws -> (String, Binder) {
                        (
                            \"\"\"
                            INSERT INTO "Contact" ("id", "name")
                            VALUES (?, ?)
                            \"\"\",
                            { stmt, index in
                                try Int32.bind(to: stmt, value: entry.id, at: &index)
                                try String?.bind(to: stmt, value: entry.name, at: &index)
                            }
                        )
                    }
                    static func update(entry: Contact) throws -> (String, Binder) {
                        throw DB4SwiftError(message: "table Contact does not have primary keys, update not supported")
                    }
                    static func delete(entry: Contact) throws -> (String, Binder) {
                        throw DB4SwiftError(message: "table Contact does not have primary keys, delete not supported")
                    }
                    static func createTable() throws -> String {
                        \"\"\"
                        CREATE TABLE "Contact" (
                            "id" INTEGER NOT NULL,
                            "name" TEXT
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
