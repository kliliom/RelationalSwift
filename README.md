# RelationalSwift

This is a library that provides a simple layer above SQLite for Swift.

It uses modern Swift features (async/await, parameter packs, etc) and only compiles with Swift 6.

> [!WARNING]
> This library is under active development, until 1.0 release breaking changes might be made.

## Requirements

- Swift 6.0 or later
- Xcode 16.0 or later
- iOS 14.0 or later
- macOS 11.0 or later
- macCatalyst 14.0 or later
- tvOS 14.0 or later

## Examples

Import library:

```swift
import RelationalSwift
```

Create a database:

```swift
// Open in-memory database
let db = try await Database.openInMemory()

// Open an on-disk database
let db = try await Database.open(url: myDatabaseURL)
```

Define a table:

```swift
@Table struct User: Equatable {
    @Column(primaryKey: true) var id: Int
    @Column var name: String
    @Column var age: Int
    @Column var address: String?
}
```

Create the table in the database:

```swift
try await db.createTable(User.self)
```

Insert entry:

```swift
var joe = User(id: 0, name: "Joe", age: 21, address: nil)
try await db.insert(entry: &joe)
```

Query entries:

```swift
// Get full user entries
let users = try await db.from(User.table).where { $0.age > 20 }.select()

// Get select fields only
let names = try await db.from(User.table).where { $0.age > 20 }.select { $0.name }
```

Update entry:

```swift
joe.age = 22
try await db.update(joe)
```

Delete entry:

```swift
try await db.delete(joe)
```
