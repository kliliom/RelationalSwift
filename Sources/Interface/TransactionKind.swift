//
//  TransactionKind.swift
//  Created by Kristof Liliom in 2024.
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
