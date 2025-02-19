//
//  LoggerTests.swift
//

import Foundation
import Testing

@testable import RelationalSwift

@Suite("Logger Tests")
struct LoggerTests {
    @Test("Warning")
    func warning() {
        warn("This is a warning.")
    }
}
