//
//  GlobalTests.swift
//  Created by Kristof Liliom in 2024.
//

import CoreGraphics
import Foundation
import Testing

@testable import Interface

@Suite("Global Tests", .serialized)
struct GlobalTests {
    @Test("Run on shared executor")
    func runOnShared() async {
        let count = Counter()
        await Global.shared.run {
            count.increment()
        }
        #expect(count.value == 1)
    }

    @Test("Log error")
    func logError() async throws {
        let count = Counter()
        let errorReference = Reference<any Error>()
        await Database.set(logger: {
            errorReference.value = $0
        })
        await Global.shared.runLogError {
            count.increment()
            throw InterfaceError(message: "not an error", code: 0)
        }
        #expect(count.value == 1)

        var retries = 10
        while errorReference.value == nil, retries > 0 {
            retries -= 1
            if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
                try await Task.sleep(for: .seconds(0.01))
            } else {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        let expectedError = InterfaceError(message: "not an error", code: 0)
        #expect(errorReference.value as? InterfaceError == expectedError)
    }

    @Test("Log error with default logger")
    func testRunLogErrorPrintLogger() async throws {
        let count = Counter()
        await Database.setDefaultLogger()
        await Global.shared.runLogError {
            count.increment()
            throw InterfaceError(message: "not an error", code: 0)
        }
        #expect(count.value == 1)
    }
}
