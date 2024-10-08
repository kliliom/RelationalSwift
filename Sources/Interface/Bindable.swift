//
//  Bindable.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

/// Static destructor type.
private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)

/// Transient destructor type.
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Bindable protocol.
///
/// This protocol is used to bind values to a statement and to extract values from a statement.
public protocol Bindable: Sendable {
    /// Binds a value to a statement.
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - value: The value to bind.
    ///   - index: The index of the parameter to bind the value to. This is an inout parameter, it will be incremented by 1 before the value is bound.
    static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws

    /// Extracts a value from a statement.
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: The index of the column to extract the value from. This is an inout parameter, it will be incremented by 1 after the value is extracted.
    /// - Returns: The extracted value.
    static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self
}

extension Bindable {
    /// Binds a value to a statement.
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - index: The index of the parameter to bind the value to. This is an inout parameter, it will be incremented by 1 before the value is bound.
    public func bind(to stmt: borrowing StatementHandle, at index: inout Int32) throws {
        try Self.bind(to: stmt, value: self, at: &index)
    }

    /// Extracts a value from a statement.
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: The index of the column to extract the value from. This is an inout parameter, it will be incremented by 1 after the value is extracted.
    public mutating func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws {
        self = try Self.column(of: stmt, at: &index)
    }
}

// MARK: - Bindable conformance for common types

extension Int: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Int, at index: inout Int32) throws {
        try Int64.bind(to: stmt, value: Int64(value), at: &index)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Int {
        try Int(Int64.column(of: stmt, at: &index))
    }
}

extension Int32: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try check(sqlite3_bind_int(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        return sqlite3_column_int(stmt.stmtPtr, index)
    }
}

extension Int64: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try check(sqlite3_bind_int64(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        return sqlite3_column_int64(stmt.stmtPtr, index)
    }
}

extension Bool: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        try Int.bind(to: stmt, value: value ? 1 : 0, at: &index)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        try Int.column(of: stmt, at: &index) > 0
    }
}

extension Float: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try check(sqlite3_bind_double(stmt.stmtPtr, index, Double(value)), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        return Float(sqlite3_column_double(stmt.stmtPtr, index))
    }
}

extension Double: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try check(sqlite3_bind_double(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        return sqlite3_column_double(stmt.stmtPtr, index)
    }
}

extension String: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1

        let success = try value.utf8.withContiguousStorageIfAvailable { ptr in
            try check(sqlite3_bind_text(stmt.stmtPtr, index, ptr.baseAddress, Int32(ptr.count), SQLITE_TRANSIENT), is: SQLITE_OK)
            return SQLITE_OK
        }
        if let success, success == SQLITE_OK {
            return
        }

        var copy = value
        try copy.withUTF8 { ptr in
            try check(sqlite3_bind_text(stmt.stmtPtr, index, ptr.baseAddress, Int32(ptr.count), SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        if let cString = sqlite3_column_text(stmt.stmtPtr, index) {
            return String(cString: cString)
        } else {
            throw RelationalSwiftError(message: "sqlite3_column_text returned nil", code: -1)
        }
    }
}

extension UUID: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try withUnsafePointer(to: value.uuid) {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0, 16, SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index), sqlite3_column_bytes(stmt.stmtPtr, index) == 16 {
            let mem = blob.bindMemory(to: uuid_t.self, capacity: 1)
            return UUID(uuid: mem.pointee)
        } else {
            throw RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)
        }
    }
}

extension Data: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try value.withUnsafeBytes {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index) {
            let count = sqlite3_column_bytes(stmt.stmtPtr, index)
            return Data(bytes: blob, count: Int(count))
        } else {
            throw RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)
        }
    }
}

extension Date: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1
        try check(sqlite3_bind_double(stmt.stmtPtr, index, value.timeIntervalSince1970), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        return Date(timeIntervalSince1970: sqlite3_column_double(stmt.stmtPtr, index))
    }
}

extension Bindable where Self: Codable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        index += 1

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try data.withUnsafeBytes {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        defer { index += 1 }
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index) {
            let count = sqlite3_column_bytes(stmt.stmtPtr, index)
            let data = Data(bytes: blob, count: Int(count))
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } else {
            throw RelationalSwiftError(message: "sqlite3_column_blob returned nil", code: -1)
        }
    }
}

extension Optional: Bindable where Wrapped: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout Int32) throws {
        if let value {
            try Wrapped.bind(to: stmt, value: value, at: &index)
        } else {
            index += 1
            try check(sqlite3_bind_null(stmt.stmtPtr, index), db: stmt.dbPtr, is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: inout Int32) throws -> Self {
        if sqlite3_column_type(stmt.stmtPtr, index) == SQLITE_NULL {
            index += 1
            return .none
        } else {
            return try Wrapped.column(of: stmt, at: &index)
        }
    }
}

extension Array: Bindable where Self: Codable, Element: Bindable {}
extension Dictionary: Bindable where Self: Codable, Key: Bindable, Value: Bindable {}
