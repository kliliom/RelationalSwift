//
//  Scenario1.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Testing

import Migration

private enum AddressType: String {
    case home
    case work
    case other
}

private struct AddressPoint: Codable, Bindable, Equatable {
    var x: Int
    var y: Int

    static let zero = AddressPoint(x: 0, y: 0)
}

private let userID1 = UUID()

private let changeSetV1 = ChangeSet(id: "add addresses") {
    CreateTable("addresses") {
        Column("id", ofType: Int.self)
            .primaryKey(autoIncrement: true)
        Column("address_line_1", ofType: String.self)
        Column("address_line_2", ofType: String?.self)
            .unique(onConflict: .ignore)
        Column("city", ofType: String.self)
        Column("state", ofType: String.self)
        Column("zip", ofType: String.self, storage: .varchar(length: 15))
        Column("country", ofType: String.self, defaultValue: "US")
        Column("type", ofType: AddressType.self)
        Column("point", ofType: AddressPoint.self, defaultValue: .zero)
    }

    Execute { db in
        try db.exec("""
        INSERT INTO addresses (address_line_1, city, state, zip, type) VALUES ('123 Main St', 'Springfield', 'IL', '62701', 'home')
        """)
        try db.exec("""
        INSERT INTO addresses (address_line_1, city, state, zip, type) VALUES ('456 Elm St', 'Springfield', 'IL', '62701', 'work')
        """)
    }
}

private let changeSetV2 = ChangeSet(id: "add users") {
    CreateTable("users") {
        Column("id", ofType: UUID.self)
            .primaryKey()
        Column("name", ofType: String.self)
        Column("email", ofType: String.self)
    }

    Execute { db in
        try db.exec("""
        INSERT INTO users (id, name, email) VALUES (?, 'John Doe', '')
        """, bind: userID1)
    }

    CreateTable("user_addresses") {
        Column("user_id", ofType: UUID.self)
        Column("address_id", ofType: Int.self)
            .foreignKey(referencing: "addresses", column: "id", onUpdate: .cascade, onDelete: .restrict, constraintName: "fk_user_addresses_address_id")
    }
    .primaryKey(on: "user_id", "address_id", onConflict: .replace)
    .unique(on: "address_id")
    .unsafeCheck("user_id != 0")
    .foreignKey(on: "address_id", referencing: "users", columns: "id", onUpdate: .cascade, onDelete: .cascade)

    Execute { db in
        try db.exec("""
        INSERT INTO user_addresses (user_id, address_id) VALUES (?, 1)
        """, bind: userID1)
    }
}

@Test("Migrate scenario 1")
func migrateScenario1() async throws {
    let migration = Migration(changeSets: [
        changeSetV1,
        changeSetV2,
    ])

    let db = try await Database.openInMemory()
    try await migration.migrate(database: db)

    let addressesOfUser1 = try await db.query(
        """
        SELECT a.*
        FROM addresses a
        JOIN user_addresses ua ON a.id = ua.address_id
        WHERE ua.user_id = ?
        """,
        bind: { stmt in
            var index = ManagedIndex()
            try userID1.bind(to: stmt, at: &index)
        },
        step: { stmt, _ in
            var index = ManagedIndex()
            let id = try Int.column(of: stmt, at: &index)
            let addressLine1 = try String.column(of: stmt, at: &index)
            let addressLine2 = try String?.column(of: stmt, at: &index)
            let city = try String.column(of: stmt, at: &index)
            let state = try String.column(of: stmt, at: &index)
            let zip = try String.column(of: stmt, at: &index)
            let country = try String.column(of: stmt, at: &index)
            let type = try AddressType(rawValue: String.column(of: stmt, at: &index))
            let point = try AddressPoint.column(of: stmt, at: &index)
            return (id, addressLine1, addressLine2, city, state, zip, country, type, point)
        }
    )

    #expect(addressesOfUser1.count == 1)
    let addressOfUser1 = addressesOfUser1[0]
    #expect(addressOfUser1.0 == 1)
    #expect(addressOfUser1.1 == "123 Main St")
    #expect(addressOfUser1.2 == nil)
    #expect(addressOfUser1.3 == "Springfield")
    #expect(addressOfUser1.4 == "IL")
    #expect(addressOfUser1.5 == "62701")
    #expect(addressOfUser1.6 == "US")
    #expect(addressOfUser1.7 == .home)
    #expect(addressOfUser1.8 == .zero)
}
