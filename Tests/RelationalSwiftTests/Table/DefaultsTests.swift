//
//  DefaultsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

import RelationalSwift

@Table private struct TestEntry: Equatable {
    @Column var int: Int
    @Column var int32: Int32
    @Column var int64: Int64
    @Column var float: Float
    @Column var double: Double
    @Column var string: String
    @Column var uuid: UUID
    @Column var data: Data
    @Column var date: Date
}

@Suite("Default Table Operations With No Primary Key Tests")
struct DefaultsTests {
    let db: Database

    init() async throws {
        db = try await Database.openInMemory()
        try await db.createTable(for: TestEntry.self)
    }

    private var entry: TestEntry {
        TestEntry(
            int: 10,
            int32: 20,
            int64: 30,
            float: 40,
            double: 50,
            string: "60",
            uuid: UUID(uuidString: "f687360c-3669-4512-9713-63b9f5ac19f3")!,
            data: Data(base64Encoded: "FCnqGR2isiPqE/hSS00UhQ==")!,
            date: Date(timeIntervalSince1970: 70)
        )
    }

    @Test("Supported insert")
    func insert() async throws {
        try await db.insert(entry)

        let rows = try await db.query("SELECT * FROM TestEntry") { stmt, index, _ in
            try TestEntry.read(from: stmt, startingAt: &index)
        }
        #expect(rows.count == 1)
        #expect(rows[0] == entry)
    }
}
