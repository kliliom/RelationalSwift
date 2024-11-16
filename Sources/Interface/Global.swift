//
//  Global.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

@globalActor public actor DatabaseActor: GlobalActor {
    public static let shared = DatabaseActor()
}

/// Global actor.
@DatabaseActor
final class Global {
    /// Shared instance.
    static let shared = Global()

    /// Initializes the shared instance.
    private init() {}

    /// Runs a block on the shared executor.
    /// - Parameter block: Block to run.
    /// - Returns: Result of the block.
    func run<T>(_ block: @Sendable () throws -> T) rethrows -> T {
        try block()
    }

    /// Runs a block on the shared executor and logs any errors.
    /// - Parameter block: Block to run.
    func runLogError(_ block: @Sendable () throws -> Void) {
        try logAndIgnoreError(block())
    }
}
