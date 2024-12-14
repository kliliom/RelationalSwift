//
//  Database+Observation.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import Interface
import SQLite3

extension Database {
    /// Observe changes in a table.
    /// - Parameters:
    ///   - table: Table to observe.
    ///   - limit: Buffering policy for the stream.
    /// - Returns: Stream of table rows.
    public func observe<T: Table>(
        table: T.Type,
        bufferingPolicy limit: AsyncStream<[T]>.Continuation.BufferingPolicy = .unbounded
    ) throws -> AsyncStream<[T]> where T.TableRefType.TableType == T {
        let (stream, continuation) = AsyncStream.makeStream(of: [T].self, bufferingPolicy: limit)
        let service = getService(ObservationService.self)
        let observerID = try service.observe(table: table) { rows in
            continuation.yield(rows)
        } cleanup: {
            continuation.finish()
        }
        continuation.onTermination = { @Sendable [weak service] _ in
            Task { @DatabaseActor in
                service?.removeObserver(byID: observerID, for: T.name)
            }
        }
        return stream
    }

    /// Observe changes in a row.
    /// - Parameters:
    ///   - row: Row to observe.
    ///   - limit: Buffering policy for the stream.
    /// - Returns: Stream of the row.
    public func observe<T: Table & PrimaryKeyAccessible>(
        row: T,
        bufferingPolicy limit: AsyncStream<T?>.Continuation.BufferingPolicy = .unbounded
    ) throws -> AsyncStream<T?> where T.TableRefType.TableType == T {
        let (stream, continuation) = AsyncStream.makeStream(of: T?.self, bufferingPolicy: limit)
        let service = getService(ObservationService.self)
        let (observerID, rowID) = try service.observe(row: row) { row in
            continuation.yield(row)
        } cleanup: {
            continuation.finish()
        }
        continuation.onTermination = { @Sendable [weak service] _ in
            Task { @DatabaseActor in
                service?.removeObserver(byID: observerID, for: T.name, rowID: rowID)
            }
        }
        return stream
    }
}

/// Typealias for the `sqlite3_update_hook` callback.
private typealias Hook = @DatabaseActor @convention(c) (
    UnsafeMutableRawPointer?,
    Int32,
    UnsafePointer<CChar>?,
    UnsafePointer<CChar>?,
    sqlite3_int64
) -> Void

/// Hook for observing database changes.
private let hook: Hook = { servicePtr, _, _, tablePtr, rowID in
    guard let servicePtr, let tablePtr else { return }
    let service = Unmanaged<ObservationService>.fromOpaque(servicePtr).takeUnretainedValue()
    let table = String(cString: tablePtr)

    service.databaseDidChange(table: table, rowID: rowID)
}

/// Service for observing database changes.
final class ObservationService: Database.Service {
    /// Globally unique row identifier.
    struct RowID: Hashable {
        /// Table name.
        let table: String
        /// Row identifier.
        let rowID: Int64
    }

    /// Orchestrators for table observers.
    var tableObserverOrchestrators: [String: ObserverOrchestrator] = [:]
    /// Orchestrators for row observers.
    var rowObserverOrchestrators: [RowID: ObserverOrchestrator] = [:]

    /// Flag indicating if a transaction is in progress.
    var isInTransaction = false
    /// Tables changed in the current transaction.
    var tablesChangedInTransaction: Set<String> = []
    /// Rows changed in the current transaction.
    var rowsChangedInTransaction: [String: Set<Int64>] = [:]

    required init(database: Database) {
        super.init(database: database)

        let unsafeSelf = Unmanaged.passUnretained(self).toOpaque()
        database.directAccess { ptr in
            _ = sqlite3_update_hook(ptr, hook, unsafeSelf)
        }
    }

    /// Notifies the service of a change in the database.
    /// - Parameters:
    ///   - table: Table in which the change occurred.
    ///   - rowID: Row identifier of the changed row.
    func databaseDidChange(table: String, rowID: sqlite3_int64) {
        if isInTransaction {
            tablesChangedInTransaction.insert(table)
            rowsChangedInTransaction[table, default: []].insert(rowID)
        } else if let database {
            tableObserverOrchestrators[table]?.update(changeIn: database)
            rowObserverOrchestrators[RowID(table: table, rowID: rowID)]?.update(changeIn: database)
        } else {
            warn("Database no longer available for observation")
        }
    }

    /// Observe changes in a table.
    /// - Parameters:
    ///   - table: Table to observe.
    ///   - observer: Closure to execute on changes.
    ///   - cleanup: Closure to execute on cleanup.
    /// - Returns: Identifier of the observer.
    func observe<T: Table>(
        table _: T.Type,
        observer: @DatabaseActor @escaping (_ rows: [T]) -> Void,
        cleanup: @DatabaseActor @escaping () -> Void
    ) throws -> UUID where T.TableRefType.TableType == T {
        guard let database else {
            throw TableError(message: "Database no longer available for observation")
        }

        let orchestrator = tableObserverOrchestrators[T.name] ?? TableObserverOrchestrator<T>()
        tableObserverOrchestrators[T.name] = orchestrator

        let observer = TableObserver(callback: observer, cleanup: cleanup)
        orchestrator.addObserver(observer, in: database)

        return observer.id
    }

    /// Observe changes in a row.
    /// - Parameters:
    ///   - row: Row to observe.
    ///   - observer: Closure to execute on changes.
    ///   - cleanup: Closure to execute on cleanup.
    /// - Returns: Identifier of the observer and row identifier.
    func observe<T: Table & PrimaryKeyAccessible>(
        row: T,
        observer: @DatabaseActor @escaping (_ row: T?) -> Void,
        cleanup: @DatabaseActor @escaping () -> Void
    ) throws -> (UUID, Int64) where T.TableRefType.TableType == T {
        guard let database else {
            throw TableError(message: "Database no longer available for observation")
        }

        let rowID = try database.cached {
            try database.selectRowID(of: row)
        }

        guard let rowID else {
            throw TableError(message: "Row not found")
        }

        let key = RowID(table: T.name, rowID: rowID)
        let orchestrator = rowObserverOrchestrators[key]
            ?? RowObserverOrchestrator<T>(rowID: rowID, key: row._primaryKey)
        rowObserverOrchestrators[key] = orchestrator

        let observer = RowObserver(callback: observer, cleanup: cleanup)
        orchestrator.addObserver(observer, in: database)

        return (observer.id, rowID)
    }

    /// Removes an observer from the service.
    /// - Parameters:
    ///   - observerID: Observer identifier.
    ///   - table: Table to remove the observer from.
    ///   - rowID: Row identifier of the row to remove the observer from if the observer is a row observer.
    func removeObserver(byID observerID: UUID, for table: String, rowID: Int64? = nil) {
        if let rowID {
            // Remove row observer form the row orchestrator
            let key = RowID(table: table, rowID: rowID)
            guard let orchestrator = rowObserverOrchestrators[key] else { return }
            orchestrator.removeObserver(byID: observerID)

            // Remove the row orchestrator if it's empty
            if orchestrator.isEmpty {
                rowObserverOrchestrators.removeValue(forKey: key)
            }

        } else {
            // Remove table observer from the table orchestrator
            let key = table
            guard let orchestrator = tableObserverOrchestrators[key] else { return }
            orchestrator.removeObserver(byID: observerID)

            // Remove the table orchestrator if it's empty
            if orchestrator.isEmpty {
                tableObserverOrchestrators.removeValue(forKey: key)
            }
        }
    }

    override func transactionWillBegin() {
        isInTransaction = true
    }

    override func transactionDidCommit() {
        guard isInTransaction else {
            fatalError("Transaction did commit without beginning")
        }

        // Update observers with changes in the database
        guard let database else {
            warn("Database no longer available for observation")
            return
        }
        for table in tablesChangedInTransaction {
            tableObserverOrchestrators[table]?.update(changeIn: database)
        }
        for (table, rowIDs) in rowsChangedInTransaction {
            for rowID in rowIDs {
                rowObserverOrchestrators[RowID(table: table, rowID: rowID)]?.update(changeIn: database)
            }
        }

        // Reset transaction
        isInTransaction = false
        tablesChangedInTransaction.removeAll()
        rowsChangedInTransaction.removeAll()
    }

    override func transactionDidRollback() {
        guard isInTransaction else {
            fatalError("Transaction did commit without beginning")
        }

        // No changes made, reset transaction
        isInTransaction = false
        tablesChangedInTransaction.removeAll()
        rowsChangedInTransaction.removeAll()
    }

    override func shutdown() {
        guard let database else { return }

        // Clear update hook
        database.directAccess { ptr in
            _ = sqlite3_update_hook(ptr, nil, nil)
        }
    }
}

extension ObservationService {
    /// Observer protocol.
    protocol Observer {
        /// Observer identifier.
        var id: UUID { get }
    }

    /// Observer for a table.
    struct TableObserver<T: Table>: Observer {
        let id = UUID()

        /// Callback to execute on changes.
        let callback: @DatabaseActor ([T]) -> Void

        /// Clean-up closure.
        let cleanup: @DatabaseActor () -> Void
    }

    /// Observer for a table row.
    struct RowObserver<T: Table>: Observer {
        let id = UUID()

        /// Callback to execute on changes.
        let callback: @DatabaseActor (T?) -> Void

        /// Clean-up closure.
        let cleanup: @DatabaseActor () -> Void
    }
}

extension ObservationService {
    /// Orchestrator for changes.
    @DatabaseActor
    protocol ObserverOrchestrator: AnyObject {
        /// Adds an observer to the orchestrator.
        /// - Parameters:
        ///  - observer: Observer to add.
        ///  - database: Database to observe.
        func addObserver(_ observer: Observer, in database: Database)

        /// Removes an observer from the orchestrator.
        /// - Parameter observerID: Observer identifier.
        func removeObserver(byID observerID: UUID)

        /// Updates observers with changes in the database.
        /// - Parameter database: Database to update from.
        func update(changeIn database: Database)

        /// Checks if the orchestrator has any observers, returning `true` if it doesn't.
        var isEmpty: Bool { get }
    }

    /// Orchestrator for changes in a table.
    class TableObserverOrchestrator<T: Table>: ObserverOrchestrator where T.TableRefType.TableType == T {
        /// Observers for the table.
        var observers: [UUID: TableObserver<T>] = [:]

        deinit {
            Task { @DatabaseActor [observers] in
                for observer in observers.values {
                    observer.cleanup()
                }
            }
        }

        func addObserver(_ observer: Observer, in database: Database) {
            guard let observer = observer as? TableObserver<T> else {
                warn("Invalid observer type: \(observer)")
                return
            }

            observers[observer.id] = observer
            observer.callback(readFreshData(from: database))
        }

        func removeObserver(byID observerID: UUID) {
            observers.removeValue(forKey: observerID)?.cleanup()
        }

        func update(changeIn database: Database) {
            let rows = readFreshData(from: database)
            for observer in observers.values {
                observer.callback(rows)
            }
        }

        var isEmpty: Bool {
            observers.isEmpty
        }

        private func readFreshData(from database: Database) -> [T] {
            do {
                return try database.from(T.self).select()
            } catch {
                warn("Observation failed to read fresh data from database: \(error)")
                return []
            }
        }
    }

    /// Orchestrator for changes in a table row.
    class RowObserverOrchestrator<T: Table & PrimaryKeyAccessible>: ObserverOrchestrator where T.TableRefType.TableType == T {
        /// Row identifier.
        let rowID: Int64
        /// Primary key of the row.
        let key: T.KeyType
        /// Observers for the table's row.
        var observers: [UUID: RowObserver<T>] = [:]

        init(rowID: Int64, key: T.KeyType) {
            self.rowID = rowID
            self.key = key
        }

        deinit {
            Task { @DatabaseActor [observers] in
                for observer in observers.values {
                    observer.cleanup()
                }
            }
        }

        func addObserver(_ observer: Observer, in database: Database) {
            guard let observer = observer as? RowObserver<T> else {
                warn("Invalid observer type: \(observer)")
                return
            }

            observers[observer.id] = observer
            observer.callback(readFreshData(from: database))
        }

        func removeObserver(byID observerID: UUID) {
            observers.removeValue(forKey: observerID)?.cleanup()
        }

        func update(changeIn database: Database) {
            let row = readFreshData(from: database)
            for observer in observers.values {
                observer.callback(row)
            }
        }

        var isEmpty: Bool {
            observers.isEmpty
        }

        private func readFreshData(from database: Database) -> T? {
            do {
                return try database.select(byKey: key)
            } catch {
                warn("Observation failed to read fresh data from database: \(error)")
                return nil
            }
        }
    }
}
