//
//  MigrationErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct MigrationErrorTests {
    @Test("Initializer")
    func initializer() {
        let error = MigrationError(
            message: "message",
            code: 1,
            info: ["key": "value"]
        )

        #expect(error.message == "message")
        #expect(error.code == 1)
        #expect(error.info == ["key": "value"])
    }

    @Test("Error description")
    func errorDescription() {
        let error = MigrationError(
            message: "message",
            code: 1,
            info: ["key": "value"]
        )

        #expect(error.errorDescription == "message [1]")
    }

    @Test("Change set order mismatch")
    func changeSetOrderMismatch() {
        let error = MigrationError.changeSetOrderMismatch(
            expectedID: "expected",
            actualID: "actual"
        )

        #expect(error.message == "change set order mismatch")
        #expect(error.code == 1)
        #expect(error.info == [
            "expected change set ID": "expected",
            "actual change set ID": "actual",
        ])
    }

    @Test("Duplicate change set ID")
    func duplicateChangeSetID() {
        let error = MigrationError.duplicateChangeSetID("id")

        #expect(error.message == "duplicate change set IDs")
        #expect(error.code == 2)
        #expect(error.info == ["change set ID": "id"])
    }
}
