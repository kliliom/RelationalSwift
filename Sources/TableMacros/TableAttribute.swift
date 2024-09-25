//
//  TableAttribute.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct TableAttribute {
    var name: String?

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

            default:
                throw ExpansionError(node: arg, message: "Unknown argument: \(label ?? "?")")
            }
        }
        return attribute
    }
}
