//
//  RelationalSwiftError.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

public enum RelationalSwiftError: Error, Equatable {
    /// `SQLITE_ERROR`
    ///
    /// No other more specific error code is available.
    case error(message: String)
    /// `SQLITE_INTERNAL`
    ///
    /// Internal malfunction.
    case internalError(message: String)
    /// `SQLITE_PERM`
    ///
    /// Requested access mode for a newly created database could not be provided.
    case permissionDenied(message: String)
    /// `SQLITE_ABORT`
    ///
    /// Operation was aborted prior to completion.
    case aborted(message: String)
    /// `SQLITE_BUSY`
    ///
    /// Database file could not be written because of concurrent activity by some other database connection.
    case busy(message: String)
    /// `SQLITE_LOCKED`
    ///
    /// Write operation could not continue because of a conflict within the same database connection or a conflict
    /// with a different database connection that uses a shared cache.
    case locked(message: String)
    /// `SQLITE_NOMEM`
    ///
    /// SQLite was unable to allocate all the memory it needed to complete the operation.
    case noMemory(message: String)
    /// `SQLITE_READONLY`
    ///
    /// Attempt is made to alter some data for which the current database connection does not have write permission.
    case readOnly(message: String)
    /// `SQLITE_INTERRUPT`
    ///
    /// Operation was interrupted by the `sqlite3_interrupt()` interface.
    case interrupted(message: String)
    /// `SQLITE_IOERR`
    ///
    /// Operation could not finish because the operating system reported an I/O error.
    case ioError(message: String)
    /// `SQLITE_CORRUPT`
    ///
    /// Database file has been corrupted.
    case corrupt(message: String)
    /// `SQLITE_NOTFOUND`
    ///
    /// `sqlite3_file_control()`, `xSetSystemCall()`, `sqlite3_vtab_rhs_value()` returned `SQLITE_NOTFOUND`.
    case notFound(message: String)
    /// `SQLITE_FULL`
    ///
    /// Write could not complete because the disk is full.
    case full(message: String)
    /// `SQLITE_CANTOPEN`
    ///
    /// SQLite was unable to open a file.
    case cannotOpen(message: String)
    /// `SQLITE_PROTOCOL`
    ///
    /// Problem with the file locking protocol used by SQLite.
    case protocolError(message: String)
    /// `SQLITE_EMPTY`
    ///
    /// > Not currently used by SQLite.
    case empty(message: String)
    /// `SQLITE_SCHEMA`
    ///
    /// Database schema has changed.
    case schemaChanged(message: String)
    /// `SQLITE_TOOBIG`
    ///
    /// String or BLOB was too large.
    case tooBig(message: String)
    /// `SQLITE_CONSTRAINT`
    ///
    /// SQL constraint violation occurred while trying to process an SQL statement.
    case constraintViolation(message: String)
    /// `SQLITE_MISMATCH`
    ///
    /// Datatype mismatch.
    case dataTypeMismatch(message: String)
    /// `SQLITE_MISUSE`
    ///
    /// Application uses any SQLite interface in a way that is undefined or unsupported.
    case misuse(message: String)
    /// `SQLITE_NOLFS`
    ///
    /// Returned on systems that do not support large files when the database grows to be larger than what the
    /// filesystem can handle.
    case noLargeFileSupport(message: String)
    /// `SQLITE_AUTH`
    ///
    /// Authorizer callback indicates that an SQL statement being prepared is not authorized.
    case authorizationDenied(message: String)
    /// `SQLITE_FORMAT`
    ///
    /// > Not currently used by SQLite.
    case formatError(message: String)
    /// `SQLITE_RANGE`
    ///
    /// Parameter number argument to one of the `sqlite3_bind` routines or the `sqlite3_column` routines is out of range.
    case rangeError(message: String)
    /// `SQLITE_NOTADB`
    ///
    /// File being opened does not appear to be an SQLite database file.
    case notADatabase(message: String)
    /// Other SQLite error.
    case otherSQLiteError(code: Int32, message: String)
    /// Not an URL with the `file:` scheme.
    case notAFileURL
    /// Statement contains no SQL.
    case emptyStatement
    /// SQLite returned NULL when reading a non-optional value.
    case unexpectedNullValue
    /// Failed to map value to type.
    case typeMappingFailed(value: String, type: String)
    /// Row not found in a table.
    case rowNotFound
    /// Unsupported operation.
    case unsupportedOperation
    /// Database service stopped.
    case serviceStopped
    /// No columns specified in the SELECT statement.
    case noColumnsSpecified
    /// Column not found.
    case notAColumn(column: String)
    /// Changeset order mismatch during migration.
    case changesetOrderMissmatch(expectedID: String, actualID: String)
    /// Duplicate changeset ID during migration.
    case duplicateChangesetID(id: String)

    /// Initializes an `RelationalSwiftError` from an SQLite error code.
    /// - Parameters:
    ///   - code: SQLite error code.
    ///   - message: Error message.
    init(sqlite code: Int32, message: String) {
        switch code {
        case SQLITE_ERROR:
            self = .error(message: message)
        case SQLITE_INTERNAL:
            self = .internalError(message: message)
        case SQLITE_PERM:
            self = .permissionDenied(message: message)
        case SQLITE_ABORT:
            self = .aborted(message: message)
        case SQLITE_BUSY:
            self = .busy(message: message)
        case SQLITE_LOCKED:
            self = .locked(message: message)
        case SQLITE_NOMEM:
            self = .noMemory(message: message)
        case SQLITE_READONLY:
            self = .readOnly(message: message)
        case SQLITE_INTERRUPT:
            self = .interrupted(message: message)
        case SQLITE_IOERR:
            self = .ioError(message: message)
        case SQLITE_CORRUPT:
            self = .corrupt(message: message)
        case SQLITE_NOTFOUND:
            self = .notFound(message: message)
        case SQLITE_FULL:
            self = .full(message: message)
        case SQLITE_CANTOPEN:
            self = .cannotOpen(message: message)
        case SQLITE_PROTOCOL:
            self = .protocolError(message: message)
        case SQLITE_EMPTY:
            self = .empty(message: message)
        case SQLITE_SCHEMA:
            self = .schemaChanged(message: message)
        case SQLITE_TOOBIG:
            self = .tooBig(message: message)
        case SQLITE_CONSTRAINT:
            self = .constraintViolation(message: message)
        case SQLITE_MISMATCH:
            self = .dataTypeMismatch(message: message)
        case SQLITE_MISUSE:
            self = .misuse(message: message)
        case SQLITE_NOLFS:
            self = .noLargeFileSupport(message: message)
        case SQLITE_AUTH:
            self = .authorizationDenied(message: message)
        case SQLITE_FORMAT:
            self = .formatError(message: message)
        case SQLITE_RANGE:
            self = .rangeError(message: message)
        case SQLITE_NOTADB:
            self = .notADatabase(message: message)
        default:
            self = .otherSQLiteError(code: code, message: message)
        }
    }
}
