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

class Reference<T>: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 1)
    private var _value: T?
    var value: T? {
        get {
            semaphore.wait()
            defer { semaphore.signal() }
            return _value
        } set {
            semaphore.wait()
            defer { semaphore.signal() }
            _value = newValue
        }
    }
}
