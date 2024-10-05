//
//  Column.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation

/// Column definition for a table.
public struct Column: SQLConvertible, Sendable {
    /// Name of the column.
    public var name: String

    /// Type of the data bound to the column.
    public var type: Any.Type

    /// Storage type of the column.
    public var storage: ColumnStorage

    /// Constraints of the column.
    public var constraints: [ColumnConstraint] = []

    /// Initializes a new column.
    ///
    /// The storage type is automatically determined based on the type of the column, but can be overridden
    /// by providing a custom storage type.
    ///
    /// - Parameters:
    ///   - name: Name of the column.
    ///   - type: Type of the data bound to the column.
    ///   - storage: Storage type of the column.
    public init(_ name: String, ofType type: Any.Type, storage: ColumnStorage? = nil) {
        self.name = name
        self.type = type
        self.storage = storage ?? Self.getDefaultStorage(for: type)

        if !(type is any OptionalProtocol.Type) {
            constraints.append(NotNullColumnConstraint())
        }
    }

    /// Validates the column.
    /// - Parameter validation: Validation to use.
    func validate(in validation: Validation) {
        let validation = validation.with(child: .column(name))

        if name.isEmpty {
            validation.error(of: .columnNameEmpty)
        }

        if type is any OptionalProtocol.Type {
            if constraints.contains(where: { $0 is NotNullColumnConstraint }) {
                validation.warning(of: .notNullConstraintOnOptionalType)
            }
        } else {
            if !constraints.contains(where: { $0 is NotNullColumnConstraint }) {
                validation.warning(of: .missingNotNullConstraintOnNonOptionalType)
            }
        }

        for constraint in constraints {
            constraint.validate(in: validation, column: self)
        }
    }

    /// Appends a constraint to the column.
    /// - Parameter constraint: Constraint to append.
    /// - Returns: A new column with the constraint appended.
    public func appending(_ constraint: ColumnConstraint) -> Column {
        var copy = self
        copy.constraints.append(constraint)
        return copy
    }

    /// Replaces the first constraint of the given type with the provided constraint, or appends it if no such
    /// constraint exists.
    /// - Parameter constraint: Constraint to replace or append.
    /// - Returns: A new column with the constraint replaced or appended.
    public func replacingOrAppending<T: ColumnConstraint>(_ constraint: T) -> Column {
        var copy = self
        if let index = copy.constraints.firstIndex(where: { $0 is T }) {
            copy.constraints[index] = constraint
        } else {
            copy.constraints.append(constraint)
        }
        return copy
    }

    /// Returns the default storage type for the given type.
    /// - Parameter type: Type to get the default storage type for.
    /// - Returns: Default storage type for the given type.
    static func getDefaultStorage(for type: Any.Type) -> ColumnStorage {
        if let optional = type as? any OptionalProtocol.Type {
            getDefaultStorage(for: optional.wrappedType)
        } else if let rawRepresentable = type as? any RawRepresentable.Type {
            getDefaultStorage(for: rawRepresentable.rawValueType)
        } else if type == Int.self {
            .integer
        } else if type == Int32.self {
            .integer
        } else if type == Int64.self {
            .integer
        } else if type == Bool.self {
            .integer
        } else if type == Float.self {
            .double
        } else if type == Double.self {
            .double
        } else if type == String.self {
            .text
        } else if type == UUID.self {
            .blob
        } else if type == Data.self {
            .blob
        } else if type == Date.self {
            .double
        } else {
            .blob
        }
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append(name.quoted)
        storage.append(to: builder)
        for constraint in constraints {
            constraint.append(to: builder)
        }
    }
}

/// A builder for columns.
@resultBuilder
public struct ColumnBuilder {
    /// Builds an array of columns.
    /// - Parameter columns: Columns to add.
    /// - Returns: An array of columns.
    public static func buildBlock(_ columns: Column...) -> [Column] {
        columns
    }
}
