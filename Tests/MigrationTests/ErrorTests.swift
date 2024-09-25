//
//  ErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Migration

@Suite("Error Tests")
struct ErrorTests {
    @Test("Localization")
    func localization() {
        #expect(DB4SwiftMigrationError(message: "x").localizedDescription == "x")
    }
}
