//
//  TestUtils.swift
//  Created by Kristof Liliom in 2024.
//

import Dispatch

class Counter: @unchecked Sendable {
    private(set) var value: Int = 0

    func increment() {
        value += 1
    }
}
