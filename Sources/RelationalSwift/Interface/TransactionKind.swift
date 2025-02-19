//
//  TransactionKind.swift
//

/// Transaction kind.
public enum TransactionKind: Equatable, Sendable {
    /// Deferred transaction.
    case deferred
    /// Immediate transaction.
    case immediate
    /// Exclusive transaction.
    case exclusive
}
