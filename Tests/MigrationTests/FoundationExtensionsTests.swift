//
//  FoundationExtensionsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct FoundationExtensionsTests {
    @Test("Quoted string")
    func quotedString() {
        let string = "string"
        let quoted = string.quoted

        #expect(quoted == "\"string\"")
    }

    @Test("Append to SQLBuilder")
    func appendToSQLBuilder() {
        let builder = SQLBuilder()
        ["a", "b"].append(to: builder, quoted: false, parentheses: false)

        #expect(builder.sql == ["a", ",", "b"])
    }

    @Test("Append to SQLBuilder with parentheses")
    func appendToSQLBuilderWithParentheses() {
        let builder = SQLBuilder()
        ["a", "b"].append(to: builder, quoted: false, parentheses: true)

        #expect(builder.sql == ["(", "a", ",", "b", ")"])
    }

    @Test("Append to SQLBuilder with quoted")
    func appendToSQLBuilderWithQuoted() {
        let builder = SQLBuilder()
        ["a", "b"].append(to: builder, quoted: true, parentheses: false)

        #expect(builder.sql == ["\"a\"", ",", "\"b\""])
    }

    @Test("Append to SQLBuilder with quoted and parentheses")
    func appendToSQLBuilderWithQuotedAndParentheses() {
        let builder = SQLBuilder()
        ["a", "b"].append(to: builder, quoted: true, parentheses: true)

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
