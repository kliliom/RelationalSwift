//
//  ExpressionTests.swift
//

import Foundation
import SQLite3
import Testing

@testable import RelationalSwift

@Table private struct TestEntry {
    @Column(primaryKey: true, insert: false, update: false) var id: Int
    @Column var cat: String
    @Column var value: Int
    @Column var price: Double
    @Column var desc: String
    @Column var isActive: Bool
    @Column var maybe: String?
}

@Suite("Expression Tests")
struct ExpressionTests {
    var db: Database!

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
        try await insertRows()
    }

    private func insertRows(prefix: Int = 6) async throws {
        let rows: [TestEntry] = [
            .init(id: 1, cat: "A", value: 10, price: 1.0, desc: "10", isActive: true, maybe: nil),
            .init(id: 2, cat: "B", value: 20, price: 2.0, desc: "20", isActive: false, maybe: " Optional "),
            .init(id: 3, cat: "C", value: 30, price: 3.0, desc: "30", isActive: true, maybe: nil),
            .init(id: 4, cat: "A", value: 40, price: 4.0, desc: "40", isActive: false, maybe: " Optional"),
            .init(id: 5, cat: "B", value: 50, price: 5.0, desc: "50", isActive: true, maybe: nil),
            .init(id: 6, cat: "C", value: 60, price: 6.0, desc: "60", isActive: false, maybe: "Optional "),
        ]
        for row in rows.prefix(prefix) {
            try await db.insert(row)
        }
    }

    @Test("ExprCastExpression")
    func exprCastExpression() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.id.unsafeExprCast(to: String.self) }

        #expect(rows == ["1", "2", "3", "4", "5", "6"])
    }

    @Test("UnaryOperatorExpression: Negation")
    func unaryOperatorExpressionNegation() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { !$0.isActive }

        #expect(rows == [false, true, false, true, false, true])
    }

    @Test("SuffixUnaryOperatorExpression: IsNull")
    func suffixUnaryOperatorExpressionIsNull() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.maybe.isNull() }

        #expect(rows == [true, false, true, false, true, false])
    }

    @Test("SuffixUnaryOperatorExpression: IsNotNull")
    func suffixUnaryOperatorExpressionIsNotNull() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.maybe.isNotNull() }

        #expect(rows == [false, true, false, true, false, true])
    }

    @Test("CastExpression: Integer")
    func castExpressionInteger() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.desc.castToInteger() }

        #expect(rows == [10, 20, 30, 40, 50, 60])
    }

    @Test("CastExpression: Double")
    func castExpressionDouble() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.id.castToDouble() }

        #expect(rows == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    }

    @Test("CastExpression: Text")
    func castExpressionText() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value.castToText() }

        #expect(rows == ["10", "20", "30", "40", "50", "60"])
    }

    @Test("CastExpression: Blob")
    func castExpressionBlob() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.desc.castToBlob() }

        #expect(rows == [
            Data("10".utf8),
            Data("20".utf8),
            Data("30".utf8),
            Data("40".utf8),
            Data("50".utf8),
            Data("60".utf8),
        ])
    }

    @Test("BinaryOperatorExpression: AND")
    func binaryOperatorExpressionAnd() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.isActive && $0.value > 20 }

        #expect(rows == [false, false, true, false, true, false])
    }

    @Test("BinaryOperatorExpression: OR")
    func binaryOperatorExpressionOr() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.isActive || $0.value > 40 }

        #expect(rows == [true, false, true, false, true, true])
    }

    @Test("BinaryOperatorExpression: ==")
    func binaryOperatorExpressionEqual() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.cat == "A" }

        #expect(rows == [true, false, false, true, false, false])
    }

    @Test("BinaryOperatorExpression: <>")
    func binaryOperatorExpressionNotEqual() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.cat != "A" }

        #expect(rows == [false, true, true, false, true, true])
    }

    @Test("BinaryOperatorExpression: <")
    func binaryOperatorExpressionLessThan() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value < 30 }

        #expect(rows == [true, true, false, false, false, false])
    }

    @Test("BinaryOperatorExpression: <=")
    func binaryOperatorExpressionLessThanOrEqual() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value <= 30 }

        #expect(rows == [true, true, true, false, false, false])
    }

    @Test("BinaryOperatorExpression: >")
    func binaryOperatorExpressionGreaterThan() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value > 30 }

        #expect(rows == [false, false, false, true, true, true])
    }

    @Test("BinaryOperatorExpression: >=")
    func binaryOperatorExpressionGreaterThanOrEqual() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value >= 30 }

        #expect(rows == [false, false, true, true, true, true])
    }

    @Test("BinaryOperatorExpression: +")
    func binaryOperatorExpressionAddition() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value + 10 }

        #expect(rows == [20, 30, 40, 50, 60, 70])
    }

    @Test("BinaryOperatorExpression: -")
    func binaryOperatorExpressionSubtraction() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value - 10 }

        #expect(rows == [0, 10, 20, 30, 40, 50])
    }

    @Test("BinaryOperatorExpression: *")
    func binaryOperatorExpressionMultiplication() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value * 10 }

        #expect(rows == [100, 200, 300, 400, 500, 600])
    }

    @Test("BinaryOperatorExpression: /")
    func binaryOperatorExpressionDivision() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { $0.value / 10 }

        #expect(rows == [1, 2, 3, 4, 5, 6])
    }

    @Test("ScalarFunctionExpression: abs")
    func scalarFunctionExpressionAbs() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { abs($0.value - 30) },
            db.from(TestEntry.self)
                .select { ($0.value - 30).abs() },
        ]

        for rows in multiRows {
            #expect(rows == [20, 10, 0, 10, 20, 30])
        }
    }

    @Test("ScalarFunctionExpression: char")
    func scalarFunctionExpressionChar() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { char($0.value / 10 + 64) }

        #expect(rows == ["A", "B", "C", "D", "E", "F"])
    }

    @Test("ScalarFunctionExpression: coalesce")
    func scalarFunctionExpressionCoalesce() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { coalesce($0.maybe, "default").castToText() },
            db.from(TestEntry.self)
                .select { $0.maybe.coalesce("default").castToText() },
        ]

        for rows in multiRows {
            #expect(rows == ["default", " Optional ", "default", " Optional", "default", "Optional "])
        }
    }

    @Test("ConcatFunctionExpression: concat")
    func scalarFunctionExpressionConcat() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { concat($0.cat, $0.desc) },
            db.from(TestEntry.self)
                .select { $0.cat.concat($0.desc) },
        ]

        for rows in multiRows {
            #expect(rows == ["A10", "B20", "C30", "A40", "B50", "C60"])
        }
    }

    @Test("ScalarFunctionExpression: format")
    func scalarFunctionExpressionFormat() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { format("%d %s", $0.value, $0.cat) },
            db.from(TestEntry.self)
                .select { "%d %s".format($0.value, $0.cat) },
        ]

        for rows in multiRows {
            #expect(rows == ["10 A", "20 B", "30 C", "40 A", "50 B", "60 C"])
        }
    }

    @Test("ScalarFunctionExpression: glob")
    func scalarFunctionExpressionGlob() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { glob($0.cat, pattern: "C*") },
            db.from(TestEntry.self)
                .select { $0.cat.glob(pattern: "C*") },
        ]

        for rows in multiRows {
            #expect(rows == [false, false, true, false, false, true])
        }
    }

    @Test("ScalarFunctionExpression: hex")
    func scalarFunctionExpressionHex() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { hex($0.value) }

        #expect(rows == ["3130", "3230", "3330", "3430", "3530", "3630"])
    }

    @Test("ScalarFunctionExpression: ifnull")
    func scalarFunctionExpressionIfNull() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { ifnull($0.maybe, "default").castToText() }

        #expect(rows == ["default", " Optional ", "default", " Optional", "default", "Optional "])
    }

    @Test("ScalarFunctionExpression: iif")
    func scalarFunctionExpressionIif() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { iif($0.isActive, "active", "inactive").castToText() }

        #expect(rows == ["active", "inactive", "active", "inactive", "active", "inactive"])
    }

    @Test("ScalarFunctionExpression: instr")
    func scalarFunctionExpressionInstr() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { instr($0.cat, pattern: "B") },
            db.from(TestEntry.self)
                .select { $0.cat.instr(pattern: "B") },
        ]

        for rows in multiRows {
            #expect(rows == [0, 1, 0, 0, 1, 0])
        }
    }

    @Test("ScalarFunctionExpression: length")
    func scalarFunctionExpressionLength() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { length($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.length() },
        ]

        for rows in multiRows {
            #expect(rows == [nil, 10, nil, 9, nil, 9])
        }
    }

    @Test("ScalarFunctionExpression: like")
    func scalarFunctionExpressionLike() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { like($0.cat, pattern: "C%") },
            db.from(TestEntry.self)
                .select { $0.cat.like(pattern: "C%") },
        ]

        for rows in multiRows {
            #expect(rows == [false, false, true, false, false, true])
        }
    }

    @Test("ScalarFunctionExpression: like with escape")
    func scalarFunctionExpressionLikeWithEscape() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { like($0.cat, pattern: "C%", escape: "C") },
            db.from(TestEntry.self)
                .select { $0.cat.like(pattern: "C%", escape: "C") },
        ]

        for rows in multiRows {
            #expect(rows == [false, false, false, false, false, false])
        }
    }

    @Test("ScalarFunctionExpression: lower")
    func scalarFunctionExpressionLower() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { lower($0.cat) },
            db.from(TestEntry.self)
                .select { $0.cat.lower() },
        ]

        for rows in multiRows {
            #expect(rows == ["a", "b", "c", "a", "b", "c"])
        }
    }

    @Test("ScalarFunctionExpression: ltrim")
    func scalarFunctionExpressionLtrim() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { ltrim($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.ltrim() },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "Optional ", nil, "Optional", nil, "Optional "])
        }
    }

    @Test("ScalarFunctionExpression: ltrim with characters")
    func scalarFunctionExpressionLtrimWithCharacters() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { ltrim($0.maybe, characters: " O") },
            db.from(TestEntry.self)
                .select { $0.maybe.ltrim(characters: " O") },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "ptional ", nil, "ptional", nil, "ptional "])
        }
    }

    @Test("ScalarFunctionExpression: max")
    func scalarFunctionExpressionMax() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { max($0.value, $0.id).castToInteger() }

        #expect(rows == [10, 20, 30, 40, 50, 60])
    }

    @Test("ScalarFunctionExpression: min")
    func scalarFunctionExpressionMin() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { min($0.value, $0.id).castToInteger() }

        #expect(rows == [1, 2, 3, 4, 5, 6])
    }

    @Test("ScalarFunctionExpression: nullif")
    func scalarFunctionExpressionNullIf() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { nullif($0.value <= 30, sqlTrue).castToInteger() }

        #expect(rows == [nil, nil, nil, 0, 0, 0])
    }

    @Test("ScalarFunctionExpression: octetLength")
    func scalarFunctionExpressionOctetLength() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { octetLength($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.octetLength() },
        ]

        for rows in multiRows {
            #expect(rows == [nil, 10, nil, 9, nil, 9])
        }
    }

    @Test("ScalarFunctionExpression: quote")
    func scalarFunctionExpressionQuote() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { quote($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.quote() },
        ]

        for rows in multiRows {
            #expect(rows == [
                "NULL",
                "' Optional '",
                "NULL",
                "' Optional'",
                "NULL",
                "'Optional '",
            ])
        }
    }

    @Test("ScalarFunctionExpression: random")
    func scalarFunctionExpressionRandom() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { _ in random() }

        #expect(rows.count == 6)
    }

    @Test("ScalarFunctionExpression: randomBlob")
    func scalarFunctionExpressionRandomBlob() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { _ in randomBlob(10) }

        #expect(rows.count == 6)
        #expect(rows.allSatisfy { $0.count == 10 })
    }

    @Test("ScalarFunctionExpression: replace")
    func scalarFunctionExpressionReplace() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { replace($0.maybe, pattern: "O", replacement: "o") },
            db.from(TestEntry.self)
                .select { $0.maybe.replace(pattern: "O", replacement: "o") },
        ]

        for rows in multiRows {
            #expect(rows == [nil, " optional ", nil, " optional", nil, "optional "])
        }
    }

    @Test("ScalarFunctionExpression: round")
    func scalarFunctionExpressionRound() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { round($0.price / 2) },
            db.from(TestEntry.self)
                .select { ($0.price / 2).round() },
        ]

        for rows in multiRows {
            #expect(rows == [1.0, 1.0, 2.0, 2.0, 3.0, 3.0])
        }
    }

    @Test("ScalarFunctionExpression: round with precision")
    func scalarFunctionExpressionRoundWithPrecision() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { round($0.price / 2, precision: 1) },
            db.from(TestEntry.self)
                .select { ($0.price / 2).round(precision: 1) },
        ]

        for rows in multiRows {
            #expect(rows == [0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
        }
    }

    @Test("ScalarFunctionExpression: rtrim")
    func scalarFunctionExpressionRtrim() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { rtrim($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.rtrim() },
        ]

        for rows in multiRows {
            #expect(rows == [nil, " Optional", nil, " Optional", nil, "Optional"])
        }
    }

    @Test("ScalarFunctionExpression: rtrim with characters")
    func scalarFunctionExpressionRtrimWithCharacters() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { rtrim($0.maybe, characters: " l") },
            db.from(TestEntry.self)
                .select { $0.maybe.rtrim(characters: " l") },
        ]

        for rows in multiRows {
            #expect(rows == [nil, " Optiona", nil, " Optiona", nil, "Optiona"])
        }
    }

    @Test("ScalarFunctionExpression: sign")
    func scalarFunctionExpressionSign() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { sign($0.value - 30) },
            db.from(TestEntry.self)
                .select { ($0.value - 30).sign() },
        ]

        for rows in multiRows {
            #expect(rows == [-1, -1, 0, 1, 1, 1])
        }
    }

    @Test("ScalarFunctionExpression: substr")
    func scalarFunctionExpressionSubstr() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { substr($0.maybe, start: 2) },
            db.from(TestEntry.self)
                .select { $0.maybe.substr(start: 2) },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "Optional ", nil, "Optional", nil, "ptional "])
        }
    }

    @Test("ScalarFunctionExpression: substr with length")
    func scalarFunctionExpressionSubstrWithLength() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { substr($0.maybe, start: 2, length: 3) },
            db.from(TestEntry.self)
                .select { $0.maybe.substr(start: 2, length: 3) },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "Opt", nil, "Opt", nil, "pti"])
        }
    }

    @Test("ScalarFunctionExpression: trim")
    func scalarFunctionExpressionTrim() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { trim($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.trim() },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "Optional", nil, "Optional", nil, "Optional"])
        }
    }

    @Test("ScalarFunctionExpression: trim with characters")
    func scalarFunctionExpressionTrimWithCharacters() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { trim($0.maybe, characters: " Ol") },
            db.from(TestEntry.self)
                .select { $0.maybe.trim(characters: " Ol") },
        ]

        for rows in multiRows {
            #expect(rows == [nil, "ptiona", nil, "ptiona", nil, "ptiona"])
        }
    }

    @Test("ScalarFunctionExpression: typeof")
    func scalarFunctionExpressionTypeOf() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { typeof($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.typeof() },
        ]

        for rows in multiRows {
            #expect(rows == ["null", "text", "null", "text", "null", "text"])
        }
    }

    @Test("ScalarFunctionExpression: unhex")
    func scalarFunctionExpressionUnhex() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { unhex($0.desc) }

        #expect(rows == [
            Data([0x10]),
            Data([0x20]),
            Data([0x30]),
            Data([0x40]),
            Data([0x50]),
            Data([0x60]),
        ])
    }

    @Test("ScalarFunctionExpression: unhex with separator")
    func scalarFunctionExpressionUnhexWithSeparator() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { unhex($0.desc, separator: " ") }

        #expect(rows == [
            Data([0x10]),
            Data([0x20]),
            Data([0x30]),
            Data([0x40]),
            Data([0x50]),
            Data([0x60]),
        ])
    }

    @Test("ScalarFunctionExpression: unicode")
    func scalarFunctionExpressionUnicode() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { unicode($0.cat) }

        #expect(rows == [65, 66, 67, 65, 66, 67])
    }

    @Test("ScalarFunctionExpression: upper")
    func scalarFunctionExpressionUpper() async throws {
        let multiRows = try await [
            db.from(TestEntry.self)
                .select { upper($0.cat) },
            db.from(TestEntry.self)
                .select { $0.cat.upper() },
        ]

        for rows in multiRows {
            #expect(rows == ["A", "B", "C", "A", "B", "C"])
        }
    }

    @Test("ScalarFunctionExpression: zeroblob")
    func scalarFunctionExpressionZeroblob() async throws {
        let rows = try await db.from(TestEntry.self)
            .select { zeroblob($0.value) }

        #expect(rows == [
            Data(count: 10),
            Data(count: 20),
            Data(count: 30),
            Data(count: 40),
            Data(count: 50),
            Data(count: 60),
        ])
        #expect(rows.allSatisfy { $0.allSatisfy { byte in byte == 0 } })
    }

    @Test("AggregateFunctionExpression: avg")
    func aggregateFunctionExpressionAvg() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { avg($0.value) },
            db.from(TestEntry.self)
                .select { $0.value.avg() },
        ]

        for rows in multiRows {
            #expect(rows == [30.0])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { avg($0.value, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.value.avg(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [35.0])
        }
    }

    @Test("AggregateFunctionExpression: count")
    func aggregateFunctionExpressionCount() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { count($0.maybe) },
            db.from(TestEntry.self)
                .select { $0.maybe.count() },
        ]

        for rows in multiRows {
            #expect(rows == [4])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { count($0.maybe, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.maybe.count(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [3])
        }
    }

    @Test("AggregateFunctionExpression: count *")
    func aggregateFunctionExpressionCountStar() async throws {
        try await insertRows(prefix: 3)

        let rows = try await db.from(TestEntry.self)
            .select { _ in count() }

        #expect(rows == [9])
    }

    @Test("AggregateFunctionExpression: groupConcat")
    func aggregateFunctionExpressionGroupConcat() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { groupConcat($0.cat) },
            db.from(TestEntry.self)
                .select { $0.cat.groupConcat() },
        ]

        for rows in multiRows {
            #expect(rows == ["A,B,C,A,B,C,A,B,C"])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { groupConcat($0.cat, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.cat.groupConcat(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == ["A,B,C"])
        }
    }

    @Test("AggregateFunctionExpression: groupConcat with separator")
    func aggregateFunctionExpressionGroupConcatWithSeparator() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { groupConcat($0.cat, separator: " ") },
            db.from(TestEntry.self)
                .select { $0.cat.groupConcat(separator: " ") },
        ]

        for rows in multiRows {
            #expect(rows == ["A B C A B C A B C"])
        }
    }

    @Test("AggregateFunctionExpression: max")
    func aggregateFunctionExpressionMax() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { max($0.value) },
            db.from(TestEntry.self)
                .select { $0.value.max() },
        ]

        for rows in multiRows {
            #expect(rows == [60])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { max($0.value, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.value.max(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [60])
        }
    }

    @Test("AggregateFunctionExpression: min")
    func aggregateFunctionExpressionMin() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { min($0.value) },
            db.from(TestEntry.self)
                .select { $0.value.min() },
        ]

        for rows in multiRows {
            #expect(rows == [10])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { min($0.value, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.value.min(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [10])
        }
    }

    @Test("AggregateFunctionExpression: sum")
    func aggregateFunctionExpressionSum() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { sum($0.value) },
            db.from(TestEntry.self)
                .select { $0.value.sum() },
        ]

        for rows in multiRows {
            #expect(rows == [270.0])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { sum($0.value, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.value.sum(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [210.0])
        }
    }

    @Test("AggregateFunctionExpression: total")
    func aggregateFunctionExpressionTotal() async throws {
        try await insertRows(prefix: 3)

        let multiRows = try await [
            db.from(TestEntry.self)
                .select { total($0.value) },
            db.from(TestEntry.self)
                .select { $0.value.total() },
        ]

        for rows in multiRows {
            #expect(rows == [270.0])
        }

        let multiRowsDistinct = try await [
            db.from(TestEntry.self)
                .select { total($0.value, distinct: true) },
            db.from(TestEntry.self)
                .select { $0.value.total(distinct: true) },
        ]

        for rows in multiRowsDistinct {
            #expect(rows == [210.0])
        }
    }
}
