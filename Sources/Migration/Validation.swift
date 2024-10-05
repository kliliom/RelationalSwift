//
//  Validation.swift
//  Created by Kristof Liliom in 2024.
//

/// A type that conllecs validation issues.
public struct Validation {
    /// A component of a path.
    public enum Component: Equatable {
        /// Change set.
        case changeSet(_ changeSetName: String)
        /// Create table.
        case createTable(_ tableName: String)
        /// Drop table.
        case dropTable(_ tableName: String)
        /// Alter table.
        case alterTable(_ tableName: String)
        /// Add column.
        case column(_ columnName: String)
        /// Drop column.
        case constraint(_ constraintName: String?, type: String)
    }

    /// A severity level.
    public enum Severity {
        /// Info.
        case info
        /// Warning.
        case warning
        /// Error.
        case error
    }

    /// A validation issue.
    public struct Issue: Sendable, Equatable {
        /// Message.
        public let message: String

        /// Code.
        public let code: Int

        /// Initializes a new issue.
        /// - Parameters:
        ///   - message: Message.
        ///   - code: Code.
        fileprivate init(message: String, code: Int) {
            self.message = message
            self.code = code
        }

        public static func == (lhs: Issue, rhs: Issue) -> Bool {
            lhs.code == rhs.code
        }
    }

    /// A validation diagnostic.
    public struct Diagnostic {
        /// Severity.
        public let severity: Severity

        /// Issue.
        public let issue: Issue

        /// Additional information.
        public let info: [String: String]

        /// Path.
        public let path: [Component]

        /// Initializes a new diagnostic.
        /// - Parameters:
        ///   - severity: Severity.
        ///   - issue: Issue.
        ///   - info: Additional information.
        ///   - path: Path.
        public init(severity: Severity, issue: Issue, info: [String: String], path: [Component]) {
            self.severity = severity
            self.issue = issue
            self.info = info
            self.path = path
        }
    }

    /// A store for diagnostics.
    public class Store {
        /// Diagnostics.
        public var diagnostics: [Diagnostic] = []

        /// Initializes a new store.
        public init() {}

        /// Adds a diagnostic.
        /// - Parameter diagnostic: Diagnostic.
        public func add(_ diagnostic: Diagnostic) {
            diagnostics.append(diagnostic)
        }

        /// Diagnostics with info severity.
        public var infos: [Diagnostic] {
            diagnostics.filter { $0.severity == .info }
        }

        /// Diagnostics with warning severity.
        public var warnings: [Diagnostic] {
            diagnostics.filter { $0.severity == .warning }
        }

        /// Diagnostics with error severity.
        public var errors: [Diagnostic] {
            diagnostics.filter { $0.severity == .error }
        }
    }

    /// Store.
    public var store = Store()

    /// Current path.
    public var currentPath: [Component] = []

    /// Initializes a new validation.
    public init() {}

    /// Initializes a new validation with cild appended to the current path.
    /// - Parameter child: Child component.
    /// - Returns: A new validation with child appended to the current path.
    public func with(child: Component) -> Validation {
        var copy = self
        copy.currentPath.append(child)
        return copy
    }

    /// Adds an info diagnostic.
    /// - Parameters:
    ///   - issue: Issue.
    ///   - info: Additional information.
    public func info(of issue: Issue, info: [String: String] = [:]) {
        store.add(.init(severity: .info, issue: issue, info: info, path: currentPath))
    }

    /// Adds a warning diagnostic.
    /// - Parameters:
    ///   - issue: Issue.
    ///   - info: Additional information.
    public func warning(of issue: Issue, info: [String: String] = [:]) {
        store.add(.init(severity: .warning, issue: issue, info: info, path: currentPath))
    }

    /// Adds an error diagnostic.
    /// - Parameters:
    ///   - issue: Issue.
    ///   - info: Additional information.
    public func error(of issue: Issue, info: [String: String] = [:]) {
        store.add(.init(severity: .error, issue: issue, info: info, path: currentPath))
    }

    /// Diagnostic with info severity.
    public var infos: [Diagnostic] {
        store.infos
    }

    /// Diagnostic with warning severity.
    public var warnings: [Diagnostic] {
        store.warnings
    }

    /// Diagnostic with error severity.
    public var errors: [Diagnostic] {
        store.errors
    }
}

extension Validation.Issue {
    /// Column name is empty.
    public static let columnNameEmpty = Validation.Issue(
        message: "column name is empty",
        code: 1
    )

    /// Missing NOT NULL constraint on non-Optional type.
    public static let missingNotNullConstraintOnNonOptionalType = Validation.Issue(
        message: "missing NOT NULL constraint on non-Optional type",
        code: 2
    )

    /// NOT NULL constraint on Optional type.
    public static let notNullConstraintOnOptionalType = Validation.Issue(
        message: "NOT NULL constraint on Optional type",
        code: 3
    )

    /// Multiple PRIMARY KEY constraints on the same column.
    public static let multiplePrimaryKeyConstraints = Validation.Issue(
        message: "multiple PRIMARY KEY constraints on the same column",
        code: 4
    )

    /// PRIMARY KEY and FOREIGN KEY column constraints on the same column.
    public static let primaryKeyAndForeignKeyConstraint = Validation.Issue(
        message: "PRIMARY KEY and FOREIGN KEY column constraints on the same column",
        code: 5
    )

    /// Constraint name is empty.
    public static let constraintNameEmpty = Validation.Issue(
        message: "constraint name is empty",
        code: 6
    )

    /// AUTOINCREMENT on a non-INTEGER column.
    public static let autoIncrementOnNonInteger = Validation.Issue(
        message: "AUTOINCREMENT on a non-INTEGER column",
        code: 7
    )

    /// Column not found.
    public static let columnNotFound = Validation.Issue(
        message: "column not found",
        code: 8
    )

    /// Column count mismatch between table and foreign columns.
    public static let columnCountMismatch = Validation.Issue(
        message: "column count mismatch between table and foreign columns",
        code: 9
    )

    /// No columns specified.
    public static let noColumnsSpecified = Validation.Issue(
        message: "no columns specified",
        code: 10
    )

    /// Expression is empty.
    public static let expressionEmpty = Validation.Issue(
        message: "expression is empty",
        code: 11
    )

    /// Table name is empty.
    public static let tableNameEmpty = Validation.Issue(
        message: "table name is empty",
        code: 12
    )

    /// Schema name is empty.
    public static let schemaNameEmpty = Validation.Issue(
        message: "schema name is empty",
        code: 13
    )
}
