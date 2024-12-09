# ``InterfaceError``

All errors returned by ``Interface``.

## Overview

These errors contains 1-to-1 mappings of SQLite errors and also some other errors.

### Example Error Handling

```swift
do {
    try await db.exec("KREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
} catch let InterfaceError.error(message) {
    print(message)
}

// prints: near "KREATE": syntax error
```

## Topics

### SQLite Errors

- ``InterfaceError/error(message:)``
- ``InterfaceError/internalError(message:)``
- ``InterfaceError/permissionDenied(message:)``
- ``InterfaceError/aborted(message:)``
- ``InterfaceError/busy(message:)``
- ``InterfaceError/locked(message:)``
- ``InterfaceError/noMemory(message:)``
- ``InterfaceError/readOnly(message:)``
- ``InterfaceError/interrupted(message:)``
- ``InterfaceError/ioError(message:)``
- ``InterfaceError/corrupt(message:)``
- ``InterfaceError/notFound(message:)``
- ``InterfaceError/full(message:)``
- ``InterfaceError/cannotOpen(message:)``
- ``InterfaceError/protocolError(message:)``
- ``InterfaceError/empty(message:)``
- ``InterfaceError/schemaChanged(message:)``
- ``InterfaceError/tooBig(message:)``
- ``InterfaceError/constraintViolation(message:)``
- ``InterfaceError/dataTypeMismatch(message:)``
- ``InterfaceError/misuse(message:)``
- ``InterfaceError/noLargeFileSupport(message:)``
- ``InterfaceError/authorizationDenied(message:)``
- ``InterfaceError/formatError(message:)``
- ``InterfaceError/rangeError(message:)``
- ``InterfaceError/notADatabase(message:)``
- ``InterfaceError/otherSQLiteError(code:message:)``

### Other Errors

- ``InterfaceError/notAFileURL``
- ``InterfaceError/emptyStatement``
- ``InterfaceError/unexpectedNullValue``
- ``InterfaceError/typeMappingFailed(value:type:)``
