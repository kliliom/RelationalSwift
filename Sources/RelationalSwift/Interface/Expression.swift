//
//  Expression.swift
//

import Foundation

public protocol Expression<ExpressionValue>: Sendable {
    associatedtype ExpressionValue

    /// Appends the SQL representation to the builder.
    /// - Parameter builder: SQL builder.
    func append(to builder: SQLBuilder)
}

// MARK: - Expr Cast Expressions

public struct ExprCastExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    var operand: any Expression

    public func append(to builder: SQLBuilder) {
        operand.append(to: builder)
    }
}

extension Expression {
    public func unsafeExprCast<T>(to _: T.Type) -> ExprCastExpression<T> {
        ExprCastExpression(operand: self)
    }
}

// MARK: - Keyword Expressions

public struct KeywordExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var keyword: String

    public init(_ keyword: String) {
        self.keyword = keyword
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append(keyword)
    }
}

public let sqlTrue = KeywordExpression<Bool>("TRUE")
public let sqlFalse = KeywordExpression<Bool>("FALSE")
let sqlAllColumns = KeywordExpression<Void>("*")

// MARK: - Unary Operators

public struct UnaryOperatorExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var `operator`: String
    public var operand: any Expression

    public init(_ operator: String, operand: any Expression) {
        self.operator = `operator`
        self.operand = operand
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("(")
        builder.sql.append(`operator`)
        operand.append(to: builder)
        builder.sql.append(")")
    }
}

public prefix func ! (_ operand: some Expression) -> UnaryOperatorExpression<Bool?> {
    UnaryOperatorExpression("NOT", operand: operand)
}

public struct SuffixUnaryOperatorExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var operand: any Expression
    public var `operator`: String

    public init(operand: any Expression, operator: String) {
        self.operand = operand
        self.operator = `operator`
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("(")
        operand.append(to: builder)
        builder.sql.append(`operator`)
        builder.sql.append(")")
    }
}

extension Expression {
    public func isNull() -> SuffixUnaryOperatorExpression<Bool> {
        SuffixUnaryOperatorExpression(operand: self, operator: "IS NULL")
    }

    public func isNotNull() -> SuffixUnaryOperatorExpression<Bool> {
        SuffixUnaryOperatorExpression(operand: self, operator: "IS NOT NULL")
    }
}

// MARK: - Cast Expressions

public struct CastExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var operand: any Expression
    public var type: String

    public init(_ operand: any Expression, as type: String) {
        self.operand = operand
        self.type = type
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("CAST(")
        operand.append(to: builder)
        builder.sql.append("AS")
        builder.sql.append(type)
        builder.sql.append(")")
    }
}

extension Expression {
    public func castToInteger() -> CastExpression<Int?> {
        CastExpression(self, as: "INTEGER")
    }

    public func castToDouble() -> CastExpression<Double?> {
        CastExpression(self, as: "REAL")
    }

    public func castToText() -> CastExpression<String?> {
        CastExpression(self, as: "TEXT")
    }

    public func castToBlob() -> CastExpression<Data?> {
        CastExpression(self, as: "BLOB")
    }
}

// MARK: - Binary Operators

public struct BinaryOperatorExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var `operator`: String
    public var left: any Expression
    public var right: any Expression

    public init(operator: String, left: any Expression, right: any Expression) {
        self.operator = `operator`
        self.left = left
        self.right = right
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("(")
        left.append(to: builder)
        builder.sql.append(`operator`)
        right.append(to: builder)
        builder.sql.append(")")
    }
}

public func && (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "AND", left: left, right: right)
}

public func || (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "OR", left: left, right: right)
}

public func == (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "==", left: left, right: right)
}

public func != (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "<>", left: left, right: right)
}

public func < (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "<", left: left, right: right)
}

public func <= (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: "<=", left: left, right: right)
}

public func > (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: ">", left: left, right: right)
}

public func >= (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Bool?> {
    BinaryOperatorExpression(operator: ">=", left: left, right: right)
}

public func + (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Double?> {
    BinaryOperatorExpression(operator: "+", left: left, right: right)
}

public func - (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Double?> {
    BinaryOperatorExpression(operator: "-", left: left, right: right)
}

public func * (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Double?> {
    BinaryOperatorExpression(operator: "*", left: left, right: right)
}

public func / (_ left: some Expression, _ right: some Expression) -> BinaryOperatorExpression<Double?> {
    BinaryOperatorExpression(operator: "/", left: left, right: right)
}

// MARK: - Scalar Function Expression

public struct ScalarFunctionExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var function: String
    public var arguments: [any Expression]

    public init(_ function: String, arguments: [any Expression]) {
        self.function = function
        self.arguments = arguments
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append(function)
        builder.sql.append("(")
        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                builder.sql.append(",")
            }
            argument.append(to: builder)
        }
        builder.sql.append(")")
    }
}

public struct ConcatFunctionExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var arguments: [any Expression]

    public init(arguments: [any Expression]) {
        self.arguments = arguments
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append("(")
        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                builder.sql.append("||")
            }
            argument.append(to: builder)
        }
        builder.sql.append(")")
    }
}

// MARK: - SQLite built-in scalar functions

public func abs(_ value: some Expression) -> ScalarFunctionExpression<Double?> {
    ScalarFunctionExpression("ABS", arguments: [value])
}

public func char(_ values: any Expression...) -> ScalarFunctionExpression<String> {
    ScalarFunctionExpression("CHAR", arguments: values)
}

public func coalesce(_ value: any Expression, _ values: any Expression...) -> ScalarFunctionExpression<Any> {
    ScalarFunctionExpression("COALESCE", arguments: [value] + values)
}

public func concat(_ value: any Expression, _ values: any Expression...) -> ConcatFunctionExpression<String> {
    ConcatFunctionExpression(arguments: [value] + values)
}

public func format(_ format: any Expression, _ values: any Expression...) -> ScalarFunctionExpression<String> {
    ScalarFunctionExpression("FORMAT", arguments: [format] + values)
}

public func glob(_ value: any Expression, pattern: any Expression) -> ScalarFunctionExpression<Bool?> {
    ScalarFunctionExpression("GLOB", arguments: [pattern, value])
}

public func hex(_ value: any Expression) -> ScalarFunctionExpression<String> {
    ScalarFunctionExpression("HEX", arguments: [value])
}

public func ifnull(_ value: any Expression, _ replacement: any Expression) -> ScalarFunctionExpression<Any> {
    ScalarFunctionExpression("IFNULL", arguments: [value, replacement])
}

public func iif(_ condition: any Expression, _ trueValue: any Expression, _ falseValue: any Expression) -> ScalarFunctionExpression<Any> {
    ScalarFunctionExpression("IIF", arguments: [condition, trueValue, falseValue])
}

public func instr(_ value: any Expression, pattern: any Expression) -> ScalarFunctionExpression<Int?> {
    ScalarFunctionExpression("INSTR", arguments: [value, pattern])
}

public func length(_ value: any Expression) -> ScalarFunctionExpression<Int?> {
    ScalarFunctionExpression("LENGTH", arguments: [value])
}

public func like(_ value: any Expression, pattern: any Expression) -> ScalarFunctionExpression<Bool?> {
    ScalarFunctionExpression("LIKE", arguments: [pattern, value])
}

public func like(_ value: any Expression, pattern: any Expression, escape: any Expression) -> ScalarFunctionExpression<Bool?> {
    ScalarFunctionExpression("LIKE", arguments: [pattern, value, escape])
}

public func lower(_ value: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("LOWER", arguments: [value])
}

public func ltrim(_ value: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("LTRIM", arguments: [value])
}

public func ltrim(_ value: any Expression, characters: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("LTRIM", arguments: [value, characters])
}

public func max(_ value: any Expression, _ values: any Expression...) -> ScalarFunctionExpression<Any> {
    ScalarFunctionExpression("MAX", arguments: [value] + values)
}

public func min(_ value: any Expression, _ values: any Expression...) -> ScalarFunctionExpression<Any> {
    ScalarFunctionExpression("MIN", arguments: [value] + values)
}

public func nullif(_ value: any Expression, _ replacement: any Expression) -> ScalarFunctionExpression<Any?> {
    ScalarFunctionExpression("NULLIF", arguments: [value, replacement])
}

public func octetLength(_ value: any Expression) -> ScalarFunctionExpression<Int?> {
    ScalarFunctionExpression("OCTET_LENGTH", arguments: [value])
}

public func quote(_ value: any Expression) -> ScalarFunctionExpression<String> {
    ScalarFunctionExpression("QUOTE", arguments: [value])
}

public func random() -> ScalarFunctionExpression<Double> {
    ScalarFunctionExpression("RANDOM", arguments: [])
}

public func randomBlob(_ size: any Expression) -> ScalarFunctionExpression<Data> {
    ScalarFunctionExpression("RANDOMBLOB", arguments: [size])
}

public func replace(_ value: any Expression, pattern: any Expression, replacement: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("REPLACE", arguments: [value, pattern, replacement])
}

public func round(_ value: any Expression) -> ScalarFunctionExpression<Double?> {
    ScalarFunctionExpression("ROUND", arguments: [value])
}

public func round(_ value: any Expression, precision: any Expression) -> ScalarFunctionExpression<Double?> {
    ScalarFunctionExpression("ROUND", arguments: [value, precision])
}

public func rtrim(_ value: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("RTRIM", arguments: [value])
}

public func rtrim(_ value: any Expression, characters: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("RTRIM", arguments: [value, characters])
}

public func sign(_ value: any Expression) -> ScalarFunctionExpression<Int?> {
    ScalarFunctionExpression("SIGN", arguments: [value])
}

public func substr(_ value: any Expression, start: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("SUBSTR", arguments: [value, start])
}

public func substr(_ value: any Expression, start: any Expression, length: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("SUBSTR", arguments: [value, start, length])
}

public func trim(_ value: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("TRIM", arguments: [value])
}

public func trim(_ value: any Expression, characters: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("TRIM", arguments: [value, characters])
}

public func typeof(_ value: any Expression) -> ScalarFunctionExpression<String> {
    ScalarFunctionExpression("TYPEOF", arguments: [value])
}

public func unhex(_ value: any Expression) -> ScalarFunctionExpression<Data> {
    ScalarFunctionExpression("UNHEX", arguments: [value])
}

public func unhex(_ value: any Expression, separator: any Expression) -> ScalarFunctionExpression<Data> {
    ScalarFunctionExpression("UNHEX", arguments: [value, separator])
}

public func unicode(_ value: any Expression) -> ScalarFunctionExpression<Int?> {
    ScalarFunctionExpression("UNICODE", arguments: [value])
}

public func upper(_ value: any Expression) -> ScalarFunctionExpression<String?> {
    ScalarFunctionExpression("UPPER", arguments: [value])
}

public func zeroblob(_ size: any Expression) -> ScalarFunctionExpression<Data> {
    ScalarFunctionExpression("ZEROBLOB", arguments: [size])
}

extension Expression {
    public func abs() -> ScalarFunctionExpression<Double?> {
        ScalarFunctionExpression("ABS", arguments: [self])
    }

    public func coalesce(_ values: any Expression...) -> ScalarFunctionExpression<Any> {
        ScalarFunctionExpression("COALESCE", arguments: [self] + values)
    }

    public func concat(_ values: any Expression...) -> ConcatFunctionExpression<String> {
        ConcatFunctionExpression(arguments: [self] + values)
    }

    public func format(_ values: any Expression...) -> ScalarFunctionExpression<String> {
        ScalarFunctionExpression("FORMAT", arguments: [self] + values)
    }

    public func glob(pattern: any Expression) -> ScalarFunctionExpression<Bool?> {
        ScalarFunctionExpression("GLOB", arguments: [pattern, self])
    }

    public func instr(pattern: any Expression) -> ScalarFunctionExpression<Int?> {
        ScalarFunctionExpression("INSTR", arguments: [self, pattern])
    }

    public func length() -> ScalarFunctionExpression<Int?> {
        ScalarFunctionExpression("LENGTH", arguments: [self])
    }

    public func like(pattern: any Expression) -> ScalarFunctionExpression<Bool?> {
        ScalarFunctionExpression("LIKE", arguments: [pattern, self])
    }

    public func like(pattern: any Expression, escape: any Expression) -> ScalarFunctionExpression<Bool?> {
        ScalarFunctionExpression("LIKE", arguments: [pattern, self, escape])
    }

    public func lower() -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("LOWER", arguments: [self])
    }

    public func ltrim() -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("LTRIM", arguments: [self])
    }

    public func ltrim(characters: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("LTRIM", arguments: [self, characters])
    }

    public func octetLength() -> ScalarFunctionExpression<Int?> {
        ScalarFunctionExpression("OCTET_LENGTH", arguments: [self])
    }

    public func quote() -> ScalarFunctionExpression<String> {
        ScalarFunctionExpression("QUOTE", arguments: [self])
    }

    public func replace(pattern: any Expression, replacement: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("REPLACE", arguments: [self, pattern, replacement])
    }

    public func round() -> ScalarFunctionExpression<Double?> {
        ScalarFunctionExpression("ROUND", arguments: [self])
    }

    public func round(precision: any Expression) -> ScalarFunctionExpression<Double?> {
        ScalarFunctionExpression("ROUND", arguments: [self, precision])
    }

    public func rtrim() -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("RTRIM", arguments: [self])
    }

    public func rtrim(characters: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("RTRIM", arguments: [self, characters])
    }

    public func sign() -> ScalarFunctionExpression<Int?> {
        ScalarFunctionExpression("SIGN", arguments: [self])
    }

    public func substr(start: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("SUBSTR", arguments: [self, start])
    }

    public func substr(start: any Expression, length: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("SUBSTR", arguments: [self, start, length])
    }

    public func trim() -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("TRIM", arguments: [self])
    }

    public func trim(characters: any Expression) -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("TRIM", arguments: [self, characters])
    }

    public func typeof() -> ScalarFunctionExpression<String> {
        ScalarFunctionExpression("TYPEOF", arguments: [self])
    }

    public func upper() -> ScalarFunctionExpression<String?> {
        ScalarFunctionExpression("UPPER", arguments: [self])
    }
}

// MARK: - Aggregate Function Expression

public struct AggregateFunctionExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var function: String
    public var distinct: Bool
    public var arguments: [any Expression]

    public init(_ function: String, distinct: Bool, arguments: [any Expression]) {
        self.function = function
        self.distinct = distinct
        self.arguments = arguments
    }

    public func append(to builder: SQLBuilder) {
        builder.sql.append(function)
        builder.sql.append("(")
        if distinct {
            builder.sql.append("DISTINCT")
        }
        for (index, argument) in arguments.enumerated() {
            if index > 0 {
                builder.sql.append(",")
            }
            argument.append(to: builder)
        }
        builder.sql.append(")")
    }
}

// MARK: - SQLite built-in aggregate functions

public func avg(_ value: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<Double?> {
    AggregateFunctionExpression("AVG", distinct: distinct, arguments: [value])
}

public func count(_ value: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<Int> {
    AggregateFunctionExpression("COUNT", distinct: distinct, arguments: [value])
}

public func count() -> AggregateFunctionExpression<Int> {
    AggregateFunctionExpression("COUNT", distinct: false, arguments: [sqlAllColumns])
}

public func groupConcat(_ value: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<String> {
    AggregateFunctionExpression("GROUP_CONCAT", distinct: distinct, arguments: [value])
}

public func groupConcat(_ value: any Expression, separator: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<String> {
    AggregateFunctionExpression("GROUP_CONCAT", distinct: distinct, arguments: [value, separator])
}

public func max<T: Expression>(_ value: T, distinct: Bool = false) -> AggregateFunctionExpression<T.ExpressionValue?> {
    AggregateFunctionExpression("MAX", distinct: distinct, arguments: [value])
}

public func min<T: Expression>(_ value: T, distinct: Bool = false) -> AggregateFunctionExpression<T.ExpressionValue?> {
    AggregateFunctionExpression("MIN", distinct: distinct, arguments: [value])
}

public func sum(_ value: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<Double?> {
    AggregateFunctionExpression("SUM", distinct: distinct, arguments: [value])
}

public func total(_ value: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<Double> {
    AggregateFunctionExpression("TOTAL", distinct: distinct, arguments: [value])
}

extension Expression {
    public func avg(distinct: Bool = false) -> AggregateFunctionExpression<Double?> {
        AggregateFunctionExpression("AVG", distinct: distinct, arguments: [self])
    }

    public func count(distinct: Bool = false) -> AggregateFunctionExpression<Int> {
        AggregateFunctionExpression("COUNT", distinct: distinct, arguments: [self])
    }

    public func groupConcat(distinct: Bool = false) -> AggregateFunctionExpression<String> {
        AggregateFunctionExpression("GROUP_CONCAT", distinct: distinct, arguments: [self])
    }

    public func groupConcat(separator: any Expression, distinct: Bool = false) -> AggregateFunctionExpression<String> {
        AggregateFunctionExpression("GROUP_CONCAT", distinct: distinct, arguments: [self, separator])
    }

    public func max(distinct: Bool = false) -> AggregateFunctionExpression<ExpressionValue?> {
        AggregateFunctionExpression("MAX", distinct: distinct, arguments: [self])
    }

    public func min(distinct: Bool = false) -> AggregateFunctionExpression<ExpressionValue?> {
        AggregateFunctionExpression("MIN", distinct: distinct, arguments: [self])
    }

    public func sum(distinct: Bool = false) -> AggregateFunctionExpression<Double?> {
        AggregateFunctionExpression("SUM", distinct: distinct, arguments: [self])
    }

    public func total(distinct: Bool = false) -> AggregateFunctionExpression<Double> {
        AggregateFunctionExpression("TOTAL", distinct: distinct, arguments: [self])
    }
}

// MARK: - Query Expressions

struct SingleValueQueryExpression<Value>: Expression {
    public typealias ExpressionValue = Value

    public var query: SingleValueQuery<Value>

    public func append(to builder: SQLBuilder) {
        builder.sql.append("(")
        builder.sql.append(query.statement)
        builder.binders.append(query.binder)
        builder.sql.append(")")
    }
}

// MARK: - In Expressions

public struct InExpression: Expression {
    public typealias ExpressionValue = Bool?

    public var operand: any Expression
    public var values: [any Expression]

    public init(_ operand: any Expression, values: [any Expression]) {
        self.operand = operand
        self.values = values
    }

    public func append(to builder: SQLBuilder) {
        operand.append(to: builder)
        builder.sql.append("IN (")
        for (index, value) in values.enumerated() {
            if index > 0 {
                builder.sql.append(",")
            }
            value.append(to: builder)
        }
        builder.sql.append(")")
    }
}

extension Expression {
    public func `in`(_ values: any Expression...) -> InExpression {
        InExpression(self, values: values)
    }

    public func `in`(_ query: SingleValueQuery<some Bindable>) -> InExpression {
        InExpression(self, values: [SingleValueQueryExpression(query: query)])
    }
}
