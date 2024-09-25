//
//  Binder.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface

public typealias Binder = @Sendable (_ stmt: borrowing StatementHandle, _ index: inout Int32) throws -> Void
