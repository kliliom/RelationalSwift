//
//  Binder.swift
//  Created by Kristof Liliom in 2024.
//

public typealias Binder = @Sendable (_ stmt: borrowing StatementHandle, _ index: inout ManagedIndex) throws -> Void

extension Bindable {
    var asBinder: Binder {
        { stmt, index in
            try Self.bind(to: stmt, value: self, at: &index)
        }
    }
}
