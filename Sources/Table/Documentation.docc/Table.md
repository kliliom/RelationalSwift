# ``Table``

Support for mapping Swift structs to database tables.

## Overview

The Table module provides a type-safe API for interacting with tables in the database.
It allows you to map Swift structs to database tables and perform CRUD operations on them.

<doc:Tutorial-Table-of-Contents>

### Getting Started

To get started, you need to define a struct that conforms to the `Table` protocol.
This conformance will be provided by the ``Table(_:readOnly:)`` macro:

```swift
import RelationalSwift

@Table("users") struct User {}
```

By default, the table name will be the same as the struct name, but you can specify a different name using the first
argument of the `@Table` macro.

Then you need to specify the columns of the table using the ``Column(_:primaryKey:insert:update:)`` macro:

```swift
@Table("users") struct User {
    @Column(primaryKey: true) var id: UUID
    @Column var name: String
    @Column var age: Int?
    @Column var gender: String?
    @Column("created_at", update: false) var createdAt: Date
}
```

By default, the column name will be the same as the property name, but you can specify a different name using the first
argument of the `@Column` macro.
To mark a column as the primary key, set the `primaryKey` argument to `true`.
You can also specify if a column should be included in the insert or update statements using the `insert` and `update`
arguments.

Now that we have our table defined, we need a database connection to interact with it.
For simplicity, we will use an in-memory database.
In-memory databases are useful for testing and prototyping, as they are destroyed when the connection is closed.

```swift
func getDatabase() async throws -> Database {
    return try await Database.openInMemory()
}
```

In-memory databases are always empty when opened, so we need to create the table before we can interact with it.
We can do this by calling the `createTable` method on the database instance:

```swift
func getDatabase() async throws -> Database {
    let db = try await Database.openInMemory()

    // Create the table
    try await db.createTable(User.self)

    return db
}
```

We can also add some mock data to the table to test our CRUD operations:

```swift
func getDatabase() async throws -> Database {
    let db = try await Database.openInMemory()

    // Create the table
    try await db.createTable(User.self)

    // Insert some mock data
    try await db.insert(User(id: UUID(), name: "Alice", age: 20, gender: nil, createdAt: Date()))
    try await db.insert(User(id: UUID(), name: "Bob", age: 18, gender: "M", createdAt: Date()))

    return db
}
```

Now that we have our database connection and table set up, we can start performing CRUD operations on it.
Let's create a SwiftUI view that displays the users in the table:



