# ``RelationalSwift``

Low level access to SQLite.

## Overview

The ``RelationalSwift`` module provides low level access to SQLite. It is used by other higher level modules in
RelationalSwift to interact with SQLite databases.

### Gettings Started

To get started, you can create a new instance of the ``Database`` class. This class will be the connection to the
SQLite database.

```swift
import RelationalSwift

// Open a database connection to a local file
let db = try await Database.open(url: databaseURL)
```

After you have a connection to the database, you can execute SQL statements.

```swift
// Create a table
try await db.exec("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER
    )
    """)

// Insert a user
try await db.exec("INSERT INTO users (name, age) VALUES (?, ?)") { stmt in
    try "Foo".bind(to: stmt, at: 1)
    try 42.bind(to: stmt, at: 2)
}

// Select the name of all users
let names = try await db.query("SELECT name FROM users") { stmt, _ in
    try String.column(of: stmt, at: 0)
}

// names = ["Foo"]
```

Once all references to the ``Database`` instance are released, the database connection will be closed.

## Topics

### Connection to a Database

- ``Database``

### Binding & Extracting Values

- ``Bindable``
- ``Database/Binder``
- ``Database/Stepper``
- ``Database/ManagedBinder``
- ``Database/ManagedStepper``
- ``ManagedIndex``

### Access Management

- ``DatabaseActor``

### Errors

- ``RelationalSwiftError``

### Internal Types

- ``DatabaseHandle``
- ``StatementHandle``
