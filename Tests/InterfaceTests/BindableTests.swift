//
//  BindableTests.swift
//  Created by Kristof Liliom in 2024.
//

import CoreGraphics
import Foundation
import Testing

import Interface

@Suite("Bindable Tests")
struct BindableTests {
    /// Runs statements that tests the type binding for `bind` and `column`.
    /// - Parameters:
    ///   - sqlType: SQL name of the type.
    ///   - writeValue: Value to write on insert.
    ///   - readValue: Value to compare after select.
    private func run(
        sqlType: String,
        writeValue: some Bindable & Equatable,
        readValue: some Bindable & Equatable
    ) async throws {
        let db = try await Database.openInMemory()
        try await db.exec("CREATE TABLE x (col \(sqlType))")
        try await db.exec(
            "INSERT INTO x (col) VALUES (?)",
            bind: { stmt in
                var index = Int32()
                try type(of: writeValue).bind(to: stmt, value: writeValue, at: &index)
            }
        )
        let rows = try await db.query(
            "SELECT col FROM x",
            step: { stmt, _ in
                var index = Int32()
                return try type(of: readValue).column(of: stmt, at: &index)
            }
        )
        #expect(rows == [readValue])
    }

    /// Runs statements that tests the type binding for `bind` and `column`.
    /// - Parameters:
    ///   - sqlType: SQL name of the type.
    ///   - value: Value to write on insert and compare to after select.
    private func run(sqlType: String, value: some Bindable & Equatable) async throws {
        try await run(sqlType: sqlType, writeValue: value, readValue: value)
    }

    // swiftformat:disable typeSugar
    @Test("Type: Int")
    func typeSupportInt() async throws {
        let value: Int = -63
        try await run(sqlType: "INTEGER", value: Int(value))
        try await run(sqlType: "INTEGER", value: Optional<Int>.some(value))
        try await run(sqlType: "INTEGER", value: Optional<Int>.none)
    }

    @Test("Type: Int32")
    func typeSupportInt32() async throws {
        let value: Int32 = -63
        try await run(sqlType: "INTEGER", value: Int32(value))
        try await run(sqlType: "INTEGER", value: Optional<Int32>.some(value))
        try await run(sqlType: "INTEGER", value: Optional<Int32>.none)
    }

    @Test("Type: Int64")
    func typeSupportInt64() async throws {
        let value: Int64 = -63
        try await run(sqlType: "INTEGER", value: Int64(value))
        try await run(sqlType: "INTEGER", value: Optional<Int64>.some(value))
        try await run(sqlType: "INTEGER", value: Optional<Int64>.none)
    }

    @Test("Type: Bool")
    func typeSupportBool() async throws {
        try await run(sqlType: "INTEGER", value: Bool(true))
        try await run(sqlType: "INTEGER", value: Bool(false))
        try await run(sqlType: "INTEGER", value: Optional<Bool>.some(true))
        try await run(sqlType: "INTEGER", value: Optional<Bool>.some(false))
        try await run(sqlType: "INTEGER", value: Optional<Bool>.none)
    }

    @Test("Type: Float")
    func typeSupportFloat() async throws {
        try await run(sqlType: "FLOAT", value: Float(132.456))
        try await run(sqlType: "FLOAT", value: Optional<Float>.some(132.456))
        try await run(sqlType: "FLOAT", value: Optional<Float>.none)
    }

    @Test("Type: Double")
    func typeSupportDouble() async throws {
        try await run(sqlType: "DOUBLE", value: Double(132.456))
        try await run(sqlType: "DOUBLE", value: Optional<Double>.some(132.456))
        try await run(sqlType: "DOUBLE", value: Optional<Double>.none)
    }

    @Test("Type: String")
    func typeSupportString() async throws {
        try await run(sqlType: "VARCHAR(255)", value: "hi")
        try await run(sqlType: "VARCHAR(255)", value: Optional<String>.some("hi"))
        try await run(sqlType: "VARCHAR(255)", value: Optional<String>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_text returned nil", code: -1)) {
            try await run(sqlType: "VARCHAR(255)", writeValue: Optional<String>.none, readValue: "")
        }
    }

    @Test("Type: UUID")
    func typeSupportUUID() async throws {
        let value = UUID(uuidString: "70e5bf82-563d-416d-b0a1-a06b626040c8")!
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<UUID>.some(value))
        try await run(sqlType: "BLOB", value: Optional<UUID>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<UUID>.none, readValue: UUID())
        }
    }

    @Test("Type: Data")
    func typeSupportData() async throws {
        let value = Data(base64Encoded: "1PVNEInC2OBMMNZPss9QUOV0ru5V4bsO88jfdqqL2qbjHTHyPtwJNvwmvp2YyXIpsBw9MQIcTgK2PaidASRa+O9YMVPb5NBCGDT2lA==")!
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<Data>.some(value))
        try await run(sqlType: "BLOB", value: Optional<Data>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<Data>.none, readValue: Data())
        }
    }

    @Test("Type: Date")
    func typeSupportDate() async throws {
        let value = Date(timeIntervalSince1970: 98431.021)
        try await run(sqlType: "DOUBLE", value: value)
        try await run(sqlType: "DOUBLE", value: Optional<Date>.some(value))
        try await run(sqlType: "DOUBLE", value: Optional<Date>.none)
    }

    @Test("Type: Codable")
    func typeSupportCodable() async throws {
        let value = CGRect(x: 10, y: 20, width: 30, height: 40)
        try await run(sqlType: "TEXT", value: value)
        try await run(sqlType: "TEXT", value: Optional<CGRect>.some(value))
        try await run(sqlType: "TEXT", value: Optional<CGRect>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<CGRect>.none, readValue: CGRect())
        }
    }

    @Test("Type: BindableArray")
    func typeSupportBindableArray() async throws {
        let value = [1, 2, 3]
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<[Int]>.some(value))
        try await run(sqlType: "BLOB", value: Optional<[Int]>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<[Int]>.none, readValue: [Int]())
        }
    }

    @Test("Type: BindableDictionary")
    func typeSupportBindableDictionary() async throws {
        let value = [
            "a": 10,
            "b": 20,
            "c": 30,
        ]
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<[String: Int]>.some(value))
        try await run(sqlType: "BLOB", value: Optional<[String: Int]>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<[String: Int]>.none, readValue: [Int]())
        }
    }

    @Test("Type: CodableArray")
    func typeSupportCodableArray() async throws {
        let value = [
            CGPoint(x: 10, y: 20),
            CGPoint(x: 30, y: 40),
            CGPoint(x: 50, y: 60),
        ]
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<[CGPoint]>.some(value))
        try await run(sqlType: "BLOB", value: Optional<[CGPoint]>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<[CGPoint]>.none, readValue: [Int]())
        }
    }

    @Test("Type: CodableDictionary")
    func typeSupportCodableDictionary() async throws {
        let value = [
            "a": CGPoint(x: 10, y: 20),
            "b": CGPoint(x: 30, y: 40),
            "c": CGPoint(x: 50, y: 60),
        ]
        try await run(sqlType: "BLOB", value: value)
        try await run(sqlType: "BLOB", value: Optional<[String: CGPoint]>.some(value))
        try await run(sqlType: "BLOB", value: Optional<[String: CGPoint]>.none)

        await #expect(throws: RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)) {
            try await run(sqlType: "BLOB", writeValue: Optional<[String: CGPoint]>.none, readValue: [Int]())
        }
    }
    // swiftformat:enable typeSugar
}

extension CGPoint: Bindable, @unchecked @retroactive Sendable {}
extension CGRect: Bindable, @unchecked @retroactive Sendable {}
