//
//  UtilsTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

@testable import Interface

@Suite("Utils Tests")
struct UtilsTests {
    @Test("Check equals")
    func checkEquals() async throws {
        let db = try await Database.openInMemory()
        let ptr = await db.db.ptr

        await #expect(throws: InterfaceError(message: "not an error", code: 0)) {
            try await { @DatabaseActor in
                try check(0, is: 1)
            }()
        }

        await #expect(throws: InterfaceError(message: "not an error", code: 0)) {
            try await { @DatabaseActor in
                try check(0, db: ptr, is: 1)
            }()
        }
    }

    @Test("Check contains")
    func checkContains() async throws {
        let db = try await Database.openInMemory()
        let ptr = await db.db.ptr

        await #expect(throws: InterfaceError(message: "not an error", code: 0)) {
            try await { @DatabaseActor in
                try check(0, in: 1, 2, 3)
            }()
        }

        await #expect(throws: InterfaceError(message: "not an error", code: 0)) {
            try await { @DatabaseActor in
                try check(0, db: ptr, in: 1, 2, 3)
            }()
        }
    }
}
