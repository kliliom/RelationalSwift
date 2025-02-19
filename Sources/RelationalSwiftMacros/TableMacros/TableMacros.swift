//
//  TableMacros.swift
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct MacroError: Error {
    let message: String

    static let generationFailed = MacroError(message: "Failed to create table")
}

struct ExpansionError: Error {
    let node: any SyntaxProtocol
    let message: String
}

struct ColumnSpec {
    var varName: String
    var varType: String
    var columnName: String
    var primaryKey: Bool
}

public struct TableMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        do {
            let table = try TableDecl.read(from: declaration)
            return MemberGenerator(table: table).delcarations()
        } catch {
            if let error = error as? ExpansionError {
                context.addDiagnostics(from: MacroError(message: error.message),
                                       node: error.node)
                throw MacroError.generationFailed
            } else {
                throw error
            }
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf _: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        do {
            let table = try TableDecl.read(from: declaration)
            return [
                TableExtension.syntax(for: table),
                InsertableExtension.syntax(for: table),
                PrimaryKeyAccessibleExtension.syntax(for: table),
                PrimaryKeyMutableExtension.syntax(for: table),
            ].compactMap(\.self)
        } catch {
            if let error = error as? ExpansionError {
                context.addDiagnostics(from: MacroError(message: error.message),
                                       node: error.node)
                throw MacroError.generationFailed
            } else {
                throw error
            }
        }
    }
}

public struct ColumnMacro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Does nothing, used only to decorate members with data
        []
    }
}

@main
struct RelationalSwiftPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TableMacro.self,
        ColumnMacro.self,
    ]
}
