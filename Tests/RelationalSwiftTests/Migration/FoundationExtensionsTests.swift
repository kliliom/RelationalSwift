//
//  FoundationExtensionsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct FoundationExtensionsTests {
    @Test("As SQL identifier")
    func asSQLIdentifier() {
        #expect("string".asSQLIdentifier == "\"string\"")
        #expect("str\"ing".asSQLIdentifier == "\"str\"\"ing\"")
    }

    @Test("Append to SQLBuilder as SQL identifier list")
    func appendAsSQLIdentifierList() {
        let builder = SQLBuilder()
        ["a", "b"].appendAsSQLIdentifierList(to: builder)

        #expect(builder.sql == ["(", "\"a\"", ",", "\"b\"", ")"])
    }

    @Test("Optional wrapped type")
    func optionalWrappedType() {
        let wrappedType = Optional<Int>.wrappedType

        let isInt = wrappedType == Int.self
        #expect(isInt)
    }

    private enum TestEnum: Int {
        case test
    }

    @Test("Raw value type")
    func rawValueType() {
        let rawValueType = TestEnum.rawValueType

        let isInt = rawValueType == Int.self
        #expect(isInt)
    }
}
