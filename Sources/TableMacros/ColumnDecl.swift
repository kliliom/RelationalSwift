//
//  ColumnDecl.swift
//  Created by Kristof Liliom in 2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct ColumnDecl {
    enum CodeType: CustomStringConvertible {
        case required(name: String)
        case optional(name: String)

        var description: String {
            switch self {
            case let .required(name):
                name
            case let .optional(name):
                "\(name)?"
            }
        }

        var isOptional: Bool {
            switch self {
            case .required:
                false
            case .optional:
                true
            }
        }
    }

    var codeName: String
    var codeType: CodeType
    var attribute: ColumnAttribute

    var sqlIdentifier: String {
        (attribute.name ?? codeName).sqlIdentifier
    }

    var sqlIdentifierLiteral: String {
        "\"\(sqlIdentifier.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    static func read(
        from decl: VariableDeclSyntax
    ) throws -> ColumnDecl {
        guard decl.bindings.count == 1, let binding = decl.bindings.first else {
            throw ExpansionError(node: decl, message: "Unhandled case: multiple bindings")
        }

        guard let codeName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw ExpansionError(node: binding, message: "Failed to retrieve variable name")
        }
        guard let rawCodeType = binding.typeAnnotation?.type else {
            throw ExpansionError(node: binding, message: "Failed to retrieve variable type")
        }
        let codeType: CodeType = if let type = rawCodeType.as(IdentifierTypeSyntax.self) {
            .required(name: type.trimmedDescription)
        } else if let type = rawCodeType.as(OptionalTypeSyntax.self) {
            .optional(name: type.wrappedType.trimmedDescription)
        } else {
            throw ExpansionError(node: binding, message: "Unsupported type in column: \(rawCodeType.trimmedDescription)")
        }

        let columnAttrs = decl.attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .filter { $0.attributeName.trimmedDescription == "Column" }
        guard columnAttrs.count == 1, let columnAttr = columnAttrs.first else {
            throw ExpansionError(node: decl, message: "Variable declarations must have exactly one `Column` attribute")
        }
        let attribute = try ColumnAttribute.read(from: columnAttr)

        return ColumnDecl(
            codeName: codeName,
            codeType: codeType,
            attribute: attribute
        )
    }
}
