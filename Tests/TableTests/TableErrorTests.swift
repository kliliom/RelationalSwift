//
//  TableErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import Table

@Suite("Table Error Tests")
struct TableErrorTests {
    @Test("Localization")
    func localization() {
        #expect(TableError(message: "x").localizedDescription == "x")
    }
}
