# ``Database``

Database provides safe access to SQLite databases. All operations on a database must go through a Database instance.

## Topics

### Opening databases

- ``Database/open(url:)``
- ``Database/openInMemory()``

### Executing Statements

- ``Database/exec(_:)``
- ``Database/exec(_:binder:)-1e07f``
- ``Database/exec(_:binder:)-53rqx``
- ``Database/exec(_:binding:_:)``

### Executing Queries

- ``Database/query(_:stepper:)-3nhk4``
- ``Database/query(_:stepper:)-1cteh``
- ``Database/query(_:binder:stepper:)-6qvlh``
- ``Database/query(_:binder:stepper:)-4476r``
- ``Database/query(_:binding:_:stepper:)``

### Transactions

- ``Database/transaction(kind:_:)``

### Statement Caching

- ``Database/cached(_:)``

### Last Inserted Row

- ``Database/lastInsertedRowID(_:)``

### Direct Database Access

- ``Database/directAccess(_:)``

### Database Services

- ``Database/Service``
- ``Database/getService(_:)``
- ``Database/shutdownService(_:)``
