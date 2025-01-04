//
//  ReadmeTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

import RelationalSwift

// Define a table:
@Table private struct User: Equatable {
    @Column(primaryKey: true) var id: Int
    @Column var name: String
    @Column var age: Int
    @Column var address: String?
}

@Suite("README File Tests")
struct ReadmeTests {
    @Test("Examples")
    func examplesInReadme() async throws {
        // Create a database:
        let db = try await Database.openInMemory()

        // Create the table in the database:
        try await db.createTable(for: User.self)

        // Insert entry:
        var joe = User(id: 0, name: "Joe", age: 21, address: nil)
        try await db.insert(&joe)

        var rows = try await db.from(User.self).where { $0.id == joe.id }.select()
        #expect(rows == [joe])

        // Query entries:
        // Get full user entries
        let users = try await db.from(User.self).where { $0.age > 20 }.select()

        // Get select fields only
        let names = try await db.from(User.self).where { $0.age > 20 }.select { $0.name }

        #expect(users == [joe])
        #expect(names == ["Joe"])

        // Update entry:
        joe.age = 22
        try await db.update(joe)

        rows = try await db.from(User.self).where { $0.id == joe.id }.select()
        #expect(rows == [joe])

        // Delete entry:
        try await db.delete(joe)

        rows = try await db.from(User.self).where { $0.id == joe.id }.select()
        #expect(rows == [])
    }
}
