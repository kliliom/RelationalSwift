//
//  ColumnAttribute.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct ColumnAttribute {
    var name: String?
    var primaryKey = false
    var insert: Bool?
    var update: Bool?

    static func read(
        from syntax: AttributeSyntax
    ) throws -> ColumnAttribute {
        var attribute = ColumnAttribute()
        let columnArgs = syntax.arguments?.as(LabeledExprListSyntax.self) ?? []
        for arg in columnArgs {
            let label = arg.label?.trimmedDescription
            switch label {
            case nil:
                guard let string = arg.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `name` argument's value")
                }
                attribute.name = string

            case "primaryKey":
                guard let expression = arg.expression.as(BooleanLiteralExprSyntax.self),
                      case let .keyword(kind) = expression.literal.tokenKind,
                      kind == .true || kind == .false
                else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `primaryKey` argument's value")
                }
                attribute.primaryKey = kind == .true

            case "insert":
                guard let expression = arg.expression.as(BooleanLiteralExprSyntax.self),
                      case let .keyword(kind) = expression.literal.tokenKind,
                      kind == .true || kind == .false
                else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `insert` argument's value")
                }
                attribute.insert = kind == .true

            case "update":
                guard let expression = arg.expression.as(BooleanLiteralExprSyntax.self),
                      case let .keyword(kind) = expression.literal.tokenKind,
                      kind == .true || kind == .false
                else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `update` argument's value")
                }
                attribute.update = kind == .true

            default:
                throw ExpansionError(node: arg, message: "Unknown argument: \(label ?? "?")")
            }
        }
        return attribute
    }
}
