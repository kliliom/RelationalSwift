//
//  Database+Service.swift
//  Created by Kristof Liliom in 2024.
//

import Foundation
import SQLite3

extension Database {
    /// A service that can be registered with a database.
    @DatabaseActor
    open class Service {
        /// Database managing the service.
        public private(set) weak var database: Database?

        /// Initializes a new service.
        /// - Parameter database: Database managing the service.
        public required init(database: Database) {
            self.database = database
        }

        /// Called when a transaction is about to begin.
        ///
        /// - Note: ``database`` is guaranteed to be open not nil.
        open func transactionWillBegin() {}

        /// Called when a transaction has committed.
        ///
        /// - Note: ``database`` is guaranteed to be open not nil.
        open func transactionDidCommit() {}

        /// Called when a transaction has rolled back.
        ///
        /// - Note: ``database`` is guaranteed to be open not nil.
        open func transactionDidRollback() {}

        /// Called when the service is about to be shut down.
        ///
        /// - Note: ``database`` may be nil if the database has been closed.
        open func shutdown() {}
    }

    /// Gets an instance of the specified service type.
    /// - Parameter type: Service type.
    /// - Returns: Service instance.
    public func getService<T: Service>(_ type: T.Type) -> T {
        guard let service = services[ObjectIdentifier(type)] as? T else {
            let service = T(database: self)
            services[ObjectIdentifier(type)] = service
            return service
        }

        return service
    }

    /// Shuts down the specified service.
    /// - Parameter type: Service type.
    public func shutdownService(_ type: Service.Type) {
        let removed = services.removeValue(forKey: ObjectIdentifier(type))
        removed?.shutdown()
    }

    /// Signals all services that a transaction is about to begin.
    func signalTransactionWillBegin() {
        for (_, service) in services {
            service.transactionWillBegin()
        }
    }

    /// Signals all services that a transaction has committed.
    func signalTransactionDidCommit() {
        for (_, service) in services {
            service.transactionDidCommit()
        }
    }

    /// Signals all services that a transaction has rolled back.
    func signalTransactionDidRollback() {
        for (_, service) in services {
            service.transactionDidRollback()
        }
    }
}
