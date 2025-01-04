# ``RelationalSwiftError``

All errors returned by ``RelationalSwift``.

## Overview

These errors contains 1-to-1 mappings of SQLite errors and also some other errors.

### Example Error Handling

```swift
do {
    try await db.exec("KREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
} catch let RelationalSwiftError.error(message) {
    print(message)
}

// prints: near "KREATE": syntax error
```

## Topics

### SQLite Errors

- ``RelationalSwiftError/error(message:)``
- ``RelationalSwiftError/internalError(message:)``
- ``RelationalSwiftError/permissionDenied(message:)``
- ``RelationalSwiftError/aborted(message:)``
- ``RelationalSwiftError/busy(message:)``
- ``RelationalSwiftError/locked(message:)``
- ``RelationalSwiftError/noMemory(message:)``
- ``RelationalSwiftError/readOnly(message:)``
- ``RelationalSwiftError/interrupted(message:)``
- ``RelationalSwiftError/ioError(message:)``
- ``RelationalSwiftError/corrupt(message:)``
- ``RelationalSwiftError/notFound(message:)``
- ``RelationalSwiftError/full(message:)``
- ``RelationalSwiftError/cannotOpen(message:)``
- ``RelationalSwiftError/protocolError(message:)``
- ``RelationalSwiftError/empty(message:)``
- ``RelationalSwiftError/schemaChanged(message:)``
- ``RelationalSwiftError/tooBig(message:)``
- ``RelationalSwiftError/constraintViolation(message:)``
- ``RelationalSwiftError/dataTypeMismatch(message:)``
- ``RelationalSwiftError/misuse(message:)``
- ``RelationalSwiftError/noLargeFileSupport(message:)``
- ``RelationalSwiftError/authorizationDenied(message:)``
- ``RelationalSwiftError/formatError(message:)``
- ``RelationalSwiftError/rangeError(message:)``
- ``RelationalSwiftError/notADatabase(message:)``
- ``RelationalSwiftError/otherSQLiteError(code:message:)``

### Other Errors

- ``RelationalSwiftError/notAFileURL``
- ``RelationalSwiftError/emptyStatement``
- ``RelationalSwiftError/unexpectedNullValue``
- ``RelationalSwiftError/typeMappingFailed(value:type:)``
