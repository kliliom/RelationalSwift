//
//  InterfaceErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Interface

@Suite("Interface Error Tests")
struct InterfaceErrorTests {
    @Test("Localization")
    func localization() {
        #expect(InterfaceError(message: "x", code: 1).localizedDescription == "x (1)")
    }
}
