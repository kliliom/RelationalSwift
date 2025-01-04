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

/// A type that can be bound to a statement as a parameter or extracted from a statement as a column.
public protocol Bindable: Expression<Self> & Sendable {
    /// Binds a value to a statement as a parameter.
    ///
    /// This method can be used inside ``Database/Binder`` closures.
    /// The leftmost SQL parameter has an index of 1.
    ///
    /// Here is an example of how to bind a value to a statement:
    ///
    /// ```swift
    /// try String.bind(to: stmt, value: "Hello, World!", at: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - value: The value to bind.
    ///   - index: The index of the parameter to bind the value to.
    @DatabaseActor
    static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws

    /// Extracts a column value from a statement.
    ///
    /// This method can be used inside ``Database/Stepper`` closures.
    /// The leftmost SQL column has an index of 0.
    ///
    /// Here is an example of how to extract a value from a statement:
    ///
    /// ```swift
    /// let value = try String.column(of: stmt, at: 0)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: The index of the column to extract the value from.
    /// - Returns: The extracted value.
    @DatabaseActor
    static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self

    /// Converts the value to an SQL literal.
    /// - Returns: The SQL literal representation of the value.
    func asSQLLiteral() throws -> String

    /// The default SQL storage type for the value.
    static var detaultSQLStorageType: String { get }
}

extension Bindable {
    public func append(to builder: SQLBuilder) {
        builder.sql.append("?")
        builder.binders.append(managedBinder)
    }
}

extension Bindable {
    /// Binds a value to a statement as a parameter.
    ///
    /// This method can be used inside ``Database/ManagedBinder`` closures.
    ///
    /// Here is an example of how to bind a value to a statement:
    ///
    /// ```swift
    /// try String.bind(to: stmt, value: "Hello, World!", at: &index)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - value: The value to bind.
    ///   - index: Managed index of the parameter to bind the value to.
    @DatabaseActor
    @inline(__always)
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: inout ManagedIndex) throws {
        index.value += 1
        try bind(to: stmt, value: value, at: index.value)
    }

    /// Extracts a column value from a statement.
    ///
    /// This method can be used inside ``Database/ManagedStepper`` closures.
    ///
    /// Here is an example of how to extract a value from a statement:
    ///
    /// ```swift
    /// let value = try String.column(of: stmt, at: &index)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: Managed index of the column to extract the value from.
    /// - Returns: The extracted value.
    @DatabaseActor
    @inline(__always)
    public static func column(of stmt: borrowing StatementHandle, at index: inout ManagedIndex) throws -> Self {
        defer { index.value += 1 }
        return try column(of: stmt, at: index.value)
    }
}

extension Bindable {
    /// Binds a value to a statement as a parameter.
    ///
    /// This method can be used inside ``Database/Binder`` closures.
    /// The leftmost SQL parameter has an index of 1.
    ///
    /// Here is an example of how to bind a value to a statement:
    ///
    /// ```swift
    /// try "Hello, World!".bind(to: stmt, at: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - index: The index of the parameter to bind the value to.
    @DatabaseActor
    @inline(__always)
    public func bind(to stmt: borrowing StatementHandle, at index: Int32) throws {
        try Self.bind(to: stmt, value: self, at: index)
    }

    /// Extracts a column value from a statement.
    ///
    /// This method can be used inside ``Database/Stepper`` closures.
    /// The leftmost SQL column has an index of 0.
    ///
    /// Here is an example of how to extract a value from a statement:
    ///
    /// ```swift
    /// var value = ""
    /// try value.column(of: stmt, at: 0)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: The index of the column to extract the value from.
    @DatabaseActor
    @inline(__always)
    public mutating func column(of stmt: borrowing StatementHandle, at index: Int32) throws {
        self = try Self.column(of: stmt, at: index)
    }

    /// Binds a value to a statement as a parameter.
    ///
    /// This method can be used inside ``Database/ManagedBinder`` closures.
    ///
    /// Here is an example of how to bind a value to a statement:
    ///
    /// ```swift
    /// try "Hello, World!".bind(to: stmt, at: &index)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to bind the value to.
    ///   - index: Managed index of the parameter to bind the value to.
    @DatabaseActor
    @inline(__always)
    public func bind(to stmt: borrowing StatementHandle, at index: inout ManagedIndex) throws {
        index.value += 1
        try Self.bind(to: stmt, value: self, at: index.value)
    }

    /// Extracts a column value from a statement.
    ///
    /// This method can be used inside ``Database/ManagedStepper`` closures.
    ///
    /// Here is an example of how to extract a value from a statement:
    ///
    /// ```swift
    /// var value = ""
    /// try value.column(of: stmt, at: &index)
    /// ```
    ///
    /// - Parameters:
    ///   - stmt: The statement to extract the value from.
    ///   - index: Managed index of the column to extract the value from.
    @DatabaseActor
    @inline(__always)
    public mutating func column(of stmt: borrowing StatementHandle, at index: inout ManagedIndex) throws {
        defer { index.value += 1 }
        self = try Self.column(of: stmt, at: index.value)
    }
}

extension Bindable {
    /// Returns a managed binder for this value.
    public var managedBinder: Database.ManagedBinder {
        { stmt, index in
            try Self.bind(to: stmt, value: self, at: &index)
        }
    }
}

// MARK: - Bindable conformance for common types

extension Int: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Int, at index: Int32) throws {
        try Int64.bind(to: stmt, value: Int64(value), at: index)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Int {
        try Int(Int64.column(of: stmt, at: index))
    }

    public func asSQLLiteral() throws -> String {
        "\(self)"
    }

    public static var detaultSQLStorageType: String { "INTEGER" }
}

extension Int32: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try check(sqlite3_bind_int(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        sqlite3_column_int(stmt.stmtPtr, index)
    }

    public func asSQLLiteral() throws -> String {
        "\(self)"
    }

    public static var detaultSQLStorageType: String { "INTEGER" }
}

extension Int64: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try check(sqlite3_bind_int64(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        sqlite3_column_int64(stmt.stmtPtr, index)
    }

    public func asSQLLiteral() throws -> String {
        "\(self)"
    }

    public static var detaultSQLStorageType: String { "INTEGER" }
}

extension Bool: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try Int.bind(to: stmt, value: value ? 1 : 0, at: index)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        try Int.column(of: stmt, at: index) > 0
    }

    public func asSQLLiteral() throws -> String {
        "\(self ? "TRUE" : "FALSE")"
    }

    public static var detaultSQLStorageType: String { "BOOLEAN" }
}

extension Float: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try check(sqlite3_bind_double(stmt.stmtPtr, index, Double(value)), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        Float(sqlite3_column_double(stmt.stmtPtr, index))
    }

    public func asSQLLiteral() throws -> String {
        "\(self)"
    }

    public static var detaultSQLStorageType: String { "DOUBLE" }
}

extension Double: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try check(sqlite3_bind_double(stmt.stmtPtr, index, value), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        sqlite3_column_double(stmt.stmtPtr, index)
    }

    public func asSQLLiteral() throws -> String {
        "\(self)"
    }

    public static var detaultSQLStorageType: String { "DOUBLE" }
}

extension String: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
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

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        if let cString = sqlite3_column_text(stmt.stmtPtr, index) {
            return String(cString: cString)
        } else {
            throw RelationalSwiftError.unexpectedNullValue
        }
    }

    public func asSQLLiteral() throws -> String {
        let escaped = replacingOccurrences(of: "'", with: "''")
        return "'\(escaped)'"
    }

    public static var detaultSQLStorageType: String { "TEXT" }
}

extension UUID: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try withUnsafePointer(to: value.uuid) {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0, 16, SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index), sqlite3_column_bytes(stmt.stmtPtr, index) == 16 {
            let mem = blob.bindMemory(to: uuid_t.self, capacity: 1)
            return UUID(uuid: mem.pointee)
        } else {
            throw RelationalSwiftError.unexpectedNullValue
        }
    }

    public func asSQLLiteral() throws -> String {
        let bytes = withUnsafeBytes(of: uuid) { Data($0) }
        return try bytes.asSQLLiteral()
    }

    public static var detaultSQLStorageType: String { "BLOB" }
}

extension Data: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try value.withUnsafeBytes {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index) {
            let count = sqlite3_column_bytes(stmt.stmtPtr, index)
            return Data(bytes: blob, count: Int(count))
        } else if sqlite3_column_type(stmt.stmtPtr, index) == SQLITE_NULL {
            throw RelationalSwiftError.unexpectedNullValue
        } else {
            return Data()
        }
    }

    public func asSQLLiteral() throws -> String {
        let hex = map { String(format: "%02x", $0) }.joined()
        return "X'\(hex)'"
    }

    public static var detaultSQLStorageType: String { "BLOB" }
}

extension Date: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try check(sqlite3_bind_double(stmt.stmtPtr, index, value.timeIntervalSince1970), db: stmt.dbPtr, is: SQLITE_OK)
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        Date(timeIntervalSince1970: sqlite3_column_double(stmt.stmtPtr, index))
    }

    public func asSQLLiteral() throws -> String {
        "\(timeIntervalSince1970)"
    }

    public static var detaultSQLStorageType: String { "DOUBLE" }
}

extension Bindable where Self: Codable {
    @DatabaseActor
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try data.withUnsafeBytes {
            try check(sqlite3_bind_blob(stmt.stmtPtr, index, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT), is: SQLITE_OK)
        }
    }

    @DatabaseActor
    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        if let blob = sqlite3_column_blob(stmt.stmtPtr, index) {
            let count = sqlite3_column_bytes(stmt.stmtPtr, index)
            let data = Data(bytes: blob, count: Int(count))
            let decoder = JSONDecoder()
            return try decoder.decode(Self.self, from: data)
        } else {
            throw RelationalSwiftError.unexpectedNullValue
        }
    }

    public func asSQLLiteral() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let hex = data.map { String(format: "%02x", $0) }.joined()
        return "X'\(hex)'"
    }

    public static var detaultSQLStorageType: String { "BLOB" }
}

extension Bindable where Self: RawRepresentable, RawValue: Bindable {
    @DatabaseActor
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        try RawValue.bind(to: stmt, value: value.rawValue, at: index)
    }

    @DatabaseActor
    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        let rawValue = try RawValue.column(of: stmt, at: index)
        if let value = Self(rawValue: rawValue) {
            return value
        } else {
            throw RelationalSwiftError.typeMappingFailed(
                value: String(describing: rawValue),
                type: String(describing: Self.self)
            )
        }
    }

    public func asSQLLiteral() throws -> String {
        try rawValue.asSQLLiteral()
    }

    public static var detaultSQLStorageType: String { RawValue.detaultSQLStorageType }
}

extension Optional: Expression where Wrapped: Bindable {
    public typealias ExpressionValue = Self

    public func append(to builder: SQLBuilder) {
        builder.sql.append("?")
        builder.binders.append(managedBinder)
    }
}

extension Optional: Bindable where Wrapped: Bindable {
    public static func bind(to stmt: borrowing StatementHandle, value: Self, at index: Int32) throws {
        if let value {
            try Wrapped.bind(to: stmt, value: value, at: index)
        } else {
            try check(sqlite3_bind_null(stmt.stmtPtr, index), db: stmt.dbPtr, is: SQLITE_OK)
        }
    }

    public static func column(of stmt: borrowing StatementHandle, at index: Int32) throws -> Self {
        if sqlite3_column_type(stmt.stmtPtr, index) == SQLITE_NULL {
            .none
        } else {
            try Wrapped.column(of: stmt, at: index)
        }
    }

    public func asSQLLiteral() throws -> String {
        switch self {
        case .none:
            "NULL"
        case let .some(value):
            try value.asSQLLiteral()
        }
    }

    public static var detaultSQLStorageType: String { Wrapped.detaultSQLStorageType }
}

extension Array: Expression where Self: Codable, Element: Bindable {
    public typealias ExpressionValue = Self

    public func append(to builder: SQLBuilder) {
        builder.sql.append("?")
        builder.binders.append(managedBinder)
    }
}

extension Array: Bindable where Self: Codable, Element: Bindable {}

extension Dictionary: Expression where Self: Codable, Key: Bindable, Value: Bindable {
    public typealias ExpressionValue = Self

    public func append(to builder: SQLBuilder) {
        builder.sql.append("?")
        builder.binders.append(managedBinder)
    }
}

extension Dictionary: Bindable where Self: Codable, Key: Bindable, Value: Bindable {}
