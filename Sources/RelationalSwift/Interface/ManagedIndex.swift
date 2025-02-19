//
//  ManagedIndex.swift
//

/// Index that is managed by the database.
public struct ManagedIndex {
    /// Value of the index.
    public var value: Int32

    /// Creates a new managed index.
    /// - Parameter value: Initial value of the index.
    public init(value: Int32 = 0) {
        self.value = value
    }
}
