//
//  InterfaceErrorTests.swift
//  Created by Kristof Liliom in 2024.
//

import SQLite3
import Testing

@testable import Interface

@Suite("Interface Error Tests")
struct InterfaceErrorTests {
    @Test("Known SQLite Mappings", arguments: [
        (SQLITE_ERROR, .error(message: "message")),
        (SQLITE_INTERNAL, .internalError(message: "message")),
        (SQLITE_PERM, .permissionDenied(message: "message")),
        (SQLITE_ABORT, .aborted(message: "message")),
        (SQLITE_BUSY, .busy(message: "message")),
        (SQLITE_LOCKED, .locked(message: "message")),
        (SQLITE_NOMEM, .noMemory(message: "message")),
        (SQLITE_READONLY, .readOnly(message: "message")),
        (SQLITE_INTERRUPT, .interrupted(message: "message")),
        (SQLITE_IOERR, .ioError(message: "message")),
        (SQLITE_CORRUPT, .corrupt(message: "message")),
        (SQLITE_NOTFOUND, .notFound(message: "message")),
        (SQLITE_FULL, .full(message: "message")),
        (SQLITE_CANTOPEN, .cannotOpen(message: "message")),
        (SQLITE_PROTOCOL, .protocolError(message: "message")),
        (SQLITE_EMPTY, .empty(message: "message")),
        (SQLITE_SCHEMA, .schemaChanged(message: "message")),
        (SQLITE_TOOBIG, .tooBig(message: "message")),
        (SQLITE_CONSTRAINT, .constraintViolation(message: "message")),
        (SQLITE_MISMATCH, .dataTypeMismatch(message: "message")),
        (SQLITE_MISUSE, .misuse(message: "message")),
        (SQLITE_NOLFS, .noLargeFileSupport(message: "message")),
        (SQLITE_AUTH, .authorizationDenied(message: "message")),
        (SQLITE_FORMAT, .formatError(message: "message")),
        (SQLITE_RANGE, .rangeError(message: "message")),
        (SQLITE_NOTADB, .notADatabase(message: "message")),
    ] as [(Int32, InterfaceError)])
    func knownSQLiteMappings(code: Int32, expected: InterfaceError) {
        #expect(InterfaceError(sqlite: code, message: "message") == expected)
    }

    @Test("Unknown SQLite Mapping")
    func unknownSQLiteMapping() {
        #expect(InterfaceError(sqlite: 0, message: "message") == .otherSQLiteError(code: 0, message: "message"))
    }
}
