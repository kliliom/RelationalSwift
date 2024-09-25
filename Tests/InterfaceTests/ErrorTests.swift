//
//  ErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface

@Suite("Error Tests")
struct ErrorTests {
    @Test("Localization")
    func localization() {
        #expect(RelationalSwiftError(message: "x", code: 1).localizedDescription == "x (1)")
    }
}
