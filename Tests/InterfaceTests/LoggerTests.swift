//
//  LoggerTests.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

@testable import Interface

@Suite("Logger Tests")
struct LoggerTests {
    @Test("Warning")
    func warning() {
        warn("This is a warning.")
    }
}
