//
//  TableAttribute.swift
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct TableAttribute {
    var name: String?
    var readOnly = false

    static func read(
        from syntax: AttributeSyntax
    ) throws -> TableAttribute {
        var attribute = TableAttribute()
        let columnArgs = syntax.arguments?.as(LabeledExprListSyntax.self) ?? []
        for arg in columnArgs {
            let label = arg.label?.trimmedDescription
            switch label {
            case nil:
                guard let string = arg.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `name` argument's value")
                }
                attribute.name = string

            case "readOnly":
                guard let expression = arg.expression.as(BooleanLiteralExprSyntax.self),
                      case let .keyword(kind) = expression.literal.tokenKind,
                      kind == .true || kind == .false
                else {
                    throw ExpansionError(node: arg, message: "Failed to retrieve `readOnly` argument's value")
                }
                attribute.readOnly = kind == .true

            default:
                throw ExpansionError(node: arg, message: "Unknown argument: \(label ?? "?")")
            }
        }
        return attribute
    }
}
