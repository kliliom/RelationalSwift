# ``Database/Service``

Services can be used to add functionality to a database.

For example, we could create an authorization service that makes access to a database read-only.

```swift
import SQLite3

final class ReadOnlyAuthorizer: Database.Service {
    required init(database: Database) {
        super.init(database: database)

        database.directAccess { ptr in
            _ = sqlite3_set_authorizer(ptr, { _, action, _, _, _, _ in
                switch action {
                case SQLITE_SELECT, SQLITE_READ:
                    return SQLITE_OK
                default:
                    return SQLITE_DENY
                }
            }, nil)
        }
    }

    override func shutdown() {
        guard let database else { return }

        database.directAccess { ptr in
            _ = sqlite3_set_authorizer(ptr, nil, nil)
        }
    }
}

@DatabaseActor
func openDatabase(at url: URL) async throws -> Database {
    let db = try Database.open(url: url)
    _ = db.getService(ReadOnlyAuthorizer.self)
    return db
}
```

## Topics

### Creating Services

- ``Database/Service/init(database:)``

### Accessing Database

- ``Database/Service/database``

### Shutting Down Services

- ``Database/Service/shutdown()``

### Handling Transactions

- ``Database/Service/transactionWillBegin()``
- ``Database/Service/transactionDidCommit()``
- ``Database/Service/transactionDidRollback()``
