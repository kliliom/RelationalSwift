//
//  ConditionsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

import RelationalSwift

@Table private struct TestEntry: Equatable {
    @Column(primaryKey: true, insert: false) var k: Int
    @Column var i: Int
    @Column var i32: Int32
    @Column var i64: Int64
    @Column var f32: Float
    @Column var f64: Double
    @Column var s: String
    @Column var u: UUID
    @Column var d: Data
    @Column var t: Date
    @Column var o: Int?
}

@Suite("Condition Tests: Type Support")
struct ConditionsTests {
    let db: Database
    private var e0 = TestEntry(
        k: 0, i: 0, i32: 0, i64: 0, f32: 0, f64: 0, s: "0",
        u: UUID(), d: "0".data(using: .utf8)!, t: Date(timeIntervalSinceReferenceDate: 0), o: 0
    )
    private var e1 = TestEntry(
        k: 1, i: 1, i32: 1, i64: 1, f32: 1, f64: 1, s: "1",
        u: UUID(), d: "1".data(using: .utf8)!, t: Date(timeIntervalSinceReferenceDate: 1), o: 1
    )
    private var e2 = TestEntry(
        k: 2, i: 2, i32: 2, i64: 2, f32: 2, f64: 2, s: "2",
        u: UUID(), d: "2".data(using: .utf8)!, t: Date(timeIntervalSinceReferenceDate: 2), o: 2
    )

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
        try await db.insert(&e0)
        try await db.insert(&e1)
        try await db.insert(&e2)
    }

    private func expect(_ entries: TestEntry..., where block: (TestEntry.TableRefType) throws -> Condition) async throws {
        let rows = try await db.from(TestEntry.self).where(block).select()
        #expect(rows == entries)
    }

    // swiftformat:disable yodaConditions

    @Test("SQL Equatable")
    func sqlEquatable() async throws {
        // Column == Value
        _ = try await expect(e1) { $0.i == e1.i }
        _ = try await expect(e1) { $0.i32 == e1.i32 }
        _ = try await expect(e1) { $0.i64 == e1.i64 }
        _ = try await expect(e1) { $0.f32 == e1.f32 }
        _ = try await expect(e1) { $0.f64 == e1.f64 }
        _ = try await expect(e1) { $0.s == e1.s }
        _ = try await expect(e1) { $0.u == e1.u }
        _ = try await expect(e1) { $0.d == e1.d }
        _ = try await expect(e1) { $0.t == e1.t }
        _ = try await expect(e1) { $0.o == e1.o }

        // Value == Column
        _ = try await expect(e0) { e0.i == $0.i }
        _ = try await expect(e0) { e0.i32 == $0.i32 }
        _ = try await expect(e0) { e0.i64 == $0.i64 }
        _ = try await expect(e0) { e0.f32 == $0.f32 }
        _ = try await expect(e0) { e0.f64 == $0.f64 }
        _ = try await expect(e0) { e0.s == $0.s }
        _ = try await expect(e0) { e0.u == $0.u }
        _ = try await expect(e0) { e0.d == $0.d }
        _ = try await expect(e0) { e0.t == $0.t }
        _ = try await expect(e0) { e0.o == $0.o }

        // Column == Column
        _ = try await expect(e0, e1, e2) { $0.i == $0.i }
        _ = try await expect(e0, e1, e2) { $0.i32 == $0.i32 }
        _ = try await expect(e0, e1, e2) { $0.i64 == $0.i64 }
        _ = try await expect(e0, e1, e2) { $0.f32 == $0.f32 }
        _ = try await expect(e0, e1, e2) { $0.f64 == $0.f64 }
        _ = try await expect(e0, e1, e2) { $0.s == $0.s }
        _ = try await expect(e0, e1, e2) { $0.u == $0.u }
        _ = try await expect(e0, e1, e2) { $0.d == $0.d }
        _ = try await expect(e0, e1, e2) { $0.t == $0.t }
        _ = try await expect(e0, e1, e2) { $0.o == $0.o }

        // Column != Value
        _ = try await expect(e0, e2) { $0.i != e1.i }
        _ = try await expect(e0, e2) { $0.i32 != e1.i32 }
        _ = try await expect(e0, e2) { $0.i64 != e1.i64 }
        _ = try await expect(e0, e2) { $0.f32 != e1.f32 }
        _ = try await expect(e0, e2) { $0.f64 != e1.f64 }
        _ = try await expect(e0, e2) { $0.s != e1.s }
        _ = try await expect(e0, e2) { $0.u != e1.u }
        _ = try await expect(e0, e2) { $0.d != e1.d }
        _ = try await expect(e0, e2) { $0.t != e1.t }
        _ = try await expect(e0, e2) { $0.o != e1.o }

        // Value != Column
        _ = try await expect(e1, e2) { e0.i != $0.i }
        _ = try await expect(e1, e2) { e0.i32 != $0.i32 }
        _ = try await expect(e1, e2) { e0.i64 != $0.i64 }
        _ = try await expect(e1, e2) { e0.f32 != $0.f32 }
        _ = try await expect(e1, e2) { e0.f64 != $0.f64 }
        _ = try await expect(e1, e2) { e0.s != $0.s }
        _ = try await expect(e1, e2) { e0.u != $0.u }
        _ = try await expect(e1, e2) { e0.d != $0.d }
        _ = try await expect(e1, e2) { e0.t != $0.t }
        _ = try await expect(e1, e2) { e0.o != $0.o }

        // Column != Column
        _ = try await expect { $0.i != $0.i }
        _ = try await expect { $0.i32 != $0.i32 }
        _ = try await expect { $0.i64 != $0.i64 }
        _ = try await expect { $0.f32 != $0.f32 }
        _ = try await expect { $0.f64 != $0.f64 }
        _ = try await expect { $0.s != $0.s }
        _ = try await expect { $0.u != $0.u }
        _ = try await expect { $0.d != $0.d }
        _ = try await expect { $0.t != $0.t }
        _ = try await expect { $0.o != $0.o }
    }

    @Test("SQL Comparable")
    func sqlComparable() async throws {
        // Column < Value
        _ = try await expect(e0) { $0.i < e1.i }
        _ = try await expect(e0) { $0.i32 < e1.i32 }
        _ = try await expect(e0) { $0.i64 < e1.i64 }
        _ = try await expect(e0) { $0.f32 < e1.f32 }
        _ = try await expect(e0) { $0.f64 < e1.f64 }
        _ = try await expect(e0) { $0.s < e1.s }
        _ = try await expect(e0) { $0.t < e1.t }
        _ = try await expect(e0) { $0.o < e1.o }

        // Value < Column
        _ = try await expect(e2) { e1.i < $0.i }
        _ = try await expect(e2) { e1.i32 < $0.i32 }
        _ = try await expect(e2) { e1.i64 < $0.i64 }
        _ = try await expect(e2) { e1.f32 < $0.f32 }
        _ = try await expect(e2) { e1.f64 < $0.f64 }
        _ = try await expect(e2) { e1.s < $0.s }
        _ = try await expect(e2) { e1.t < $0.t }
        _ = try await expect(e2) { e1.o < $0.o }

        // Column < Column
        _ = try await expect { $0.i < $0.i }
        _ = try await expect { $0.i32 < $0.i32 }
        _ = try await expect { $0.i64 < $0.i64 }
        _ = try await expect { $0.f32 < $0.f32 }
        _ = try await expect { $0.f64 < $0.f64 }
        _ = try await expect { $0.s < $0.s }
        _ = try await expect { $0.t < $0.t }
        _ = try await expect { $0.o < $0.o }

        // Column <= Value
        _ = try await expect(e0, e1) { $0.i <= e1.i }
        _ = try await expect(e0, e1) { $0.i32 <= e1.i32 }
        _ = try await expect(e0, e1) { $0.i64 <= e1.i64 }
        _ = try await expect(e0, e1) { $0.f32 <= e1.f32 }
        _ = try await expect(e0, e1) { $0.f64 <= e1.f64 }
        _ = try await expect(e0, e1) { $0.s <= e1.s }
        _ = try await expect(e0, e1) { $0.t <= e1.t }
        _ = try await expect(e0, e1) { $0.o <= e1.o }

        // Value <= Column
        _ = try await expect(e1, e2) { e1.i <= $0.i }
        _ = try await expect(e1, e2) { e1.i32 <= $0.i32 }
        _ = try await expect(e1, e2) { e1.i64 <= $0.i64 }
        _ = try await expect(e1, e2) { e1.f32 <= $0.f32 }
        _ = try await expect(e1, e2) { e1.f64 <= $0.f64 }
        _ = try await expect(e1, e2) { e1.s <= $0.s }
        _ = try await expect(e1, e2) { e1.t <= $0.t }
        _ = try await expect(e1, e2) { e1.o <= $0.o }

        // Column <= Column
        _ = try await expect(e0, e1, e2) { $0.i <= $0.i }
        _ = try await expect(e0, e1, e2) { $0.i32 <= $0.i32 }
        _ = try await expect(e0, e1, e2) { $0.i64 <= $0.i64 }
        _ = try await expect(e0, e1, e2) { $0.f32 <= $0.f32 }
        _ = try await expect(e0, e1, e2) { $0.f64 <= $0.f64 }
        _ = try await expect(e0, e1, e2) { $0.s <= $0.s }
        _ = try await expect(e0, e1, e2) { $0.t <= $0.t }
        _ = try await expect(e0, e1, e2) { $0.o <= $0.o }

        // Column > Value
        _ = try await expect(e2) { $0.i > e1.i }
        _ = try await expect(e2) { $0.i32 > e1.i32 }
        _ = try await expect(e2) { $0.i64 > e1.i64 }
        _ = try await expect(e2) { $0.f32 > e1.f32 }
        _ = try await expect(e2) { $0.f64 > e1.f64 }
        _ = try await expect(e2) { $0.s > e1.s }
        _ = try await expect(e2) { $0.t > e1.t }
        _ = try await expect(e2) { $0.o > e1.o }

        // Value > Column
        _ = try await expect(e0) { e1.i > $0.i }
        _ = try await expect(e0) { e1.i32 > $0.i32 }
        _ = try await expect(e0) { e1.i64 > $0.i64 }
        _ = try await expect(e0) { e1.f32 > $0.f32 }
        _ = try await expect(e0) { e1.f64 > $0.f64 }
        _ = try await expect(e0) { e1.s > $0.s }
        _ = try await expect(e0) { e1.t > $0.t }
        _ = try await expect(e0) { e1.o > $0.o }

        // Column > Column
        _ = try await expect { $0.i > $0.i }
        _ = try await expect { $0.i32 > $0.i32 }
        _ = try await expect { $0.i64 > $0.i64 }
        _ = try await expect { $0.f32 > $0.f32 }
        _ = try await expect { $0.f64 > $0.f64 }
        _ = try await expect { $0.s > $0.s }
        _ = try await expect { $0.t > $0.t }
        _ = try await expect { $0.o > $0.o }

        // Column >= Value
        _ = try await expect(e1, e2) { $0.i >= e1.i }
        _ = try await expect(e1, e2) { $0.i32 >= e1.i32 }
        _ = try await expect(e1, e2) { $0.i64 >= e1.i64 }
        _ = try await expect(e1, e2) { $0.f32 >= e1.f32 }
        _ = try await expect(e1, e2) { $0.f64 >= e1.f64 }
        _ = try await expect(e1, e2) { $0.s >= e1.s }
        _ = try await expect(e1, e2) { $0.t >= e1.t }
        _ = try await expect(e1, e2) { $0.o >= e1.o }

        // Value >= Column
        _ = try await expect(e0, e1) { e1.i >= $0.i }
        _ = try await expect(e0, e1) { e1.i32 >= $0.i32 }
        _ = try await expect(e0, e1) { e1.i64 >= $0.i64 }
        _ = try await expect(e0, e1) { e1.f32 >= $0.f32 }
        _ = try await expect(e0, e1) { e1.f64 >= $0.f64 }
        _ = try await expect(e0, e1) { e1.s >= $0.s }
        _ = try await expect(e0, e1) { e1.t >= $0.t }
        _ = try await expect(e0, e1) { e1.o >= $0.o }

        // Column >= Column
        _ = try await expect(e0, e1, e2) { $0.i >= $0.i }
        _ = try await expect(e0, e1, e2) { $0.i32 >= $0.i32 }
        _ = try await expect(e0, e1, e2) { $0.i64 >= $0.i64 }
        _ = try await expect(e0, e1, e2) { $0.f32 >= $0.f32 }
        _ = try await expect(e0, e1, e2) { $0.f64 >= $0.f64 }
        _ = try await expect(e0, e1, e2) { $0.s >= $0.s }
        _ = try await expect(e0, e1, e2) { $0.t >= $0.t }
        _ = try await expect(e0, e1, e2) { $0.o >= $0.o }
    }

    // swiftformat:enable yodaConditions
}
