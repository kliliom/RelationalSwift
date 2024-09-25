//
//  ErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Table

@Suite("Error Tests")
struct ErrorTests {
    @Test("Localization")
    func localization() {
        #expect(DB4SwiftError(message: "x").localizedDescription == "x")
    }
}
