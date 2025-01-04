//
//  ReadOnlyTableTests.swift
//  Created by Kristof Liliom in 2024.
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

final class ReadOnlyTableTests: XCTestCase {
    func testMacroWithReadOnlyTableParameters() throws {
        #if canImport(RelationalSwiftMacros)
            assertMacroExpansion(
                """
                @Table("papaya", readOnly: true) struct Contact {
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
                    static var name: String {
                        "papaya"
                    }
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
                """,
                macros: testMacros
            )
        #else
            try XCTSkipUnless(false, "This test should only be ran on host platform")
        #endif
    }
}
