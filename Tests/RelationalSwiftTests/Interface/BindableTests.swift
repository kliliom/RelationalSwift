//
//  BindableTests.swift
//  Created by Kristof Liliom in 2024.
//

import CoreGraphics
import Foundation
import Testing

import RelationalSwift

@Suite("Bindable Tests")
struct BindableTests {
    /// Runs statements that tests the type binding for `bind` and `column`.
    /// - Parameters:
    ///   - sqlType: SQL name of the type.
    ///   - writeValue: Value to write on insert.
    ///   - readValue: Value to compare after select.
    private func run<ReadType: Bindable & Equatable>(
        sqlType: String,
        writeValue: some Bindable & Equatable,
        readValue: ReadType
    ) async throws {
        let bindStepPairs: [(Database.Binder, Database.Stepper<ReadType>)] = [
            ( // Bind/column static functions of Bindable
                { stmt in
                    try type(of: writeValue).bind(to: stmt, value: writeValue, at: 1)
                },
                { stmt, _ in
                    try type(of: readValue).column(of: stmt, at: 0)
                }
            ),
            ( // Bind/column static functions of Bindable extension with managed index
                { stmt in
                    var index = ManagedIndex()
                    try type(of: writeValue).bind(to: stmt, value: writeValue, at: &index)
                },
                { stmt, _ in
                    var index = ManagedIndex()
                    return try type(of: readValue).column(of: stmt, at: &index)
                }
            ),
            ( // Bind/column member functions of Bindable extension
                { stmt in
                    try writeValue.bind(to: stmt, at: 1)
                },
                { stmt, _ in
                    var value = readValue
                    try value.column(of: stmt, at: 0)
                    return value
                }
            ),
            ( // Bind/column member functions of Bindable extension with managed index
                { stmt in
                    var index = ManagedIndex()
                    try writeValue.bind(to: stmt, at: &index)
                },
                { stmt, _ in
                    var index = ManagedIndex()
                    var value = readValue
                    try value.column(of: stmt, at: &index)
                    return value
                }
            ),
        ]

        for bindStepPair in bindStepPairs {
            let db = try await Database.openInMemory()
            try await db.exec("CREATE TABLE x (col \(sqlType))")
            try await db.exec("INSERT INTO x (col) VALUES (?)", binder: bindStepPair.0)
            let rows = try await db.query("SELECT col FROM x", stepper: bindStepPair.1)
            #expect(rows == [readValue])
        }
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
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: Int(value))
        try await run(sqlType: sqlType, value: Optional<Int>.some(value))
        try await run(sqlType: sqlType, value: Optional<Int>.none)
        #expect(try value.asSQLLiteral() == "-63")
    }

    @Test("Type: Int32")
    func typeSupportInt32() async throws {
        let value: Int32 = -63
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: Int32(value))
        try await run(sqlType: sqlType, value: Optional<Int32>.some(value))
        try await run(sqlType: sqlType, value: Optional<Int32>.none)
        #expect(try value.asSQLLiteral() == "-63")
    }

    @Test("Type: Int64")
    func typeSupportInt64() async throws {
        let value: Int64 = -63
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: Int64(value))
        try await run(sqlType: sqlType, value: Optional<Int64>.some(value))
        try await run(sqlType: sqlType, value: Optional<Int64>.none)
        #expect(try value.asSQLLiteral() == "-63")
    }

    @Test("Type: Bool")
    func typeSupportBool() async throws {
        let sqlType = Bool.detaultSQLStorageType
        try await run(sqlType: sqlType, value: Bool(true))
        try await run(sqlType: sqlType, value: Bool(false))
        try await run(sqlType: sqlType, value: Optional<Bool>.some(true))
        try await run(sqlType: sqlType, value: Optional<Bool>.some(false))
        try await run(sqlType: sqlType, value: Optional<Bool>.none)
        #expect(try true.asSQLLiteral() == "TRUE")
        #expect(try false.asSQLLiteral() == "FALSE")
    }

    @Test("Type: Float")
    func typeSupportFloat() async throws {
        let value: Float = 132.456
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: Float(value))
        try await run(sqlType: sqlType, value: Optional<Float>.some(value))
        try await run(sqlType: sqlType, value: Optional<Float>.none)
        #expect(try value.asSQLLiteral() == "132.456")
    }

    @Test("Type: Double")
    func typeSupportDouble() async throws {
        let value = 132.456
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: Double(value))
        try await run(sqlType: sqlType, value: Optional<Double>.some(value))
        try await run(sqlType: sqlType, value: Optional<Double>.none)
        #expect(try value.asSQLLiteral() == "132.456")
    }

    @Test("Type: String")
    func typeSupportString() async throws {
        let value = "what's up?"
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: String(value))
        try await run(sqlType: sqlType, value: Optional<String>.some(value))
        try await run(sqlType: sqlType, value: Optional<String>.none)
        #expect(try value.asSQLLiteral() == "'what''s up?'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<String>.none, readValue: "")
        }
    }

    @Test("Type: String (empty)")
    func typeSupportEmptyString() async throws {
        let value = ""
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: String(value))
        try await run(sqlType: sqlType, value: Optional<String>.some(value))
        try await run(sqlType: sqlType, value: Optional<String>.none)
        #expect(try value.asSQLLiteral() == "''")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<String>.none, readValue: "")
        }
    }

    @Test("Type: UUID")
    func typeSupportUUID() async throws {
        let value = UUID(uuidString: "70e5bf82-563d-416d-b0a1-a06b626040c8")!
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<UUID>.some(value))
        try await run(sqlType: sqlType, value: Optional<UUID>.none)
        #expect(try value.asSQLLiteral() == "X'70e5bf82563d416db0a1a06b626040c8'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<UUID>.none, readValue: UUID())
        }
    }

    @Test("Type: Data")
    func typeSupportData() async throws {
        let value = Data(base64Encoded: "1PVNEInC2OBMMNZPss9QUOV0ru5V4bsO88jfdqqL2qbjHTHyPtwJNvwmvp2YyXIpsBw9MQIcTgK2PaidASRa+O9YMVPb5NBCGDT2lA==")!
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<Data>.some(value))
        try await run(sqlType: sqlType, value: Optional<Data>.none)
        #expect(try value.asSQLLiteral() == "X'd4f54d1089c2d8e04c30d64fb2cf5050e574aeee55e1bb0ef3c8df76aa8bdaa6e31d31f23edc0936fc26be9d98c97229b01c3d31021c4e02b63da89d01245af8ef583153dbe4d0421834f694'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<Data>.none, readValue: Data())
        }
    }

    @Test("Type: Data (empty)")
    func typeSupportEmptyData() async throws {
        let value = Data()
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<Data>.some(value))
        try await run(sqlType: sqlType, value: Optional<Data>.none)
        #expect(try value.asSQLLiteral() == "X''")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<Data>.none, readValue: Data())
        }
    }

    @Test("Type: Date")
    func typeSupportDate() async throws {
        let value = Date(timeIntervalSince1970: 98431.021)
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<Date>.some(value))
        try await run(sqlType: sqlType, value: Optional<Date>.none)
        #expect(try value.asSQLLiteral() == "98431.02100002766")
    }

    @Test("Type: Codable")
    func typeSupportCodable() async throws {
        let value = CGRect(x: 10, y: 20, width: 30, height: 40)
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<CGRect>.some(value))
        try await run(sqlType: sqlType, value: Optional<CGRect>.none)
        #expect(try value.asSQLLiteral() == "X\'5b5b31302c32305d2c5b33302c34305d5d\'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<CGRect>.none, readValue: CGRect())
        }
    }

    @Test("Type: BindableArray")
    func typeSupportBindableArray() async throws {
        let value = [1, 2, 3]
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<[Int]>.some(value))
        try await run(sqlType: sqlType, value: Optional<[Int]>.none)
        #expect(try value.asSQLLiteral() == "X\'5b312c322c335d\'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<[Int]>.none, readValue: [Int]())
        }
    }

    @Test("Type: BindableDictionary")
    func typeSupportBindableDictionary() async throws {
        let value = [
            "a": 10,
            "b": 20,
        ]
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<[String: Int]>.some(value))
        try await run(sqlType: sqlType, value: Optional<[String: Int]>.none)

        let validLiterals = [
            "X\'7b2261223a31302c2262223a32307d\'",
            "X\'7b2262223a32302c2261223a31307d\'",
        ]
        #expect(try validLiterals.contains(value.asSQLLiteral()))

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<[String: Int]>.none, readValue: [Int]())
        }
    }

    @Test("Type: CodableArray")
    func typeSupportCodableArray() async throws {
        let value = [
            CGPoint(x: 10, y: 20),
            CGPoint(x: 30, y: 40),
            CGPoint(x: 50, y: 60),
        ]
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<[CGPoint]>.some(value))
        try await run(sqlType: sqlType, value: Optional<[CGPoint]>.none)
        #expect(try value.asSQLLiteral() == "X\'5b5b31302c32305d2c5b33302c34305d2c5b35302c36305d5d\'")

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<[CGPoint]>.none, readValue: [Int]())
        }
    }

    @Test("Type: CodableDictionary")
    func typeSupportCodableDictionary() async throws {
        let value = [
            "a": CGPoint(x: 10, y: 20),
            "b": CGPoint(x: 30, y: 40),
        ]
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<[String: CGPoint]>.some(value))
        try await run(sqlType: sqlType, value: Optional<[String: CGPoint]>.none)

        let validLiterals = [
            "X\'7b2261223a5b31302c32305d2c2262223a5b33302c34305d7d\'",
            "X\'7b2262223a5b33302c34305d2c2261223a5b31302c32305d7d\'",
        ]
        #expect(try validLiterals.contains(value.asSQLLiteral()))

        await #expect(throws: RelationalSwiftError.unexpectedNullValue) {
            try await run(sqlType: sqlType, writeValue: Optional<[String: CGPoint]>.none, readValue: [Int]())
        }
    }

    @Test("Type: RawRepresentable")
    func typeSupportRawRepresentable() async throws {
        let value: MyRawRepresentable = .first
        let sqlType = type(of: value).detaultSQLStorageType
        try await run(sqlType: sqlType, value: value)
        try await run(sqlType: sqlType, value: Optional<MyRawRepresentable>.some(value))
        try await run(sqlType: sqlType, value: Optional<MyRawRepresentable>.none)
        #expect(try value.asSQLLiteral() == "'first'")

        await #expect(throws: RelationalSwiftError.typeMappingFailed(value: "other", type: "MyRawRepresentable")) {
            try await run(sqlType: sqlType, writeValue: "other", readValue: MyRawRepresentable.first)
        }
    }

    @Test("Type: Optional")
    func typeSupportOptional() async throws {
        try #expect(Optional<Int>.some(-63).asSQLLiteral() == "-63")
        try #expect(Optional<Int>.none.asSQLLiteral() == "NULL")
        #expect(Int.detaultSQLStorageType == Optional<Int>.detaultSQLStorageType)
    }
    // swiftformat:enable typeSugar
}

extension CGPoint: Bindable, @unchecked @retroactive Sendable {}
extension CGRect: Bindable, @unchecked @retroactive Sendable {}

private enum MyRawRepresentable: String, Bindable {
    case first
    case second
}
