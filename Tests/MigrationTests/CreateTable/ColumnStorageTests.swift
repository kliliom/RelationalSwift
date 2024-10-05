//
//  ColumnStorageTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import Migration

@Suite
struct ColumnStorageTests {
    @Test("Column storage append to builder", arguments: [
        (.integer, "INTEGER"),
        (.varchar(length: 12), "VARCHAR(12)"),
        (.text, "TEXT"),
        (.blob, "BLOB"),
        (.double, "DOUBLE"),
        (.decimal(precision: 1, scale: 2), "DECIMAL(1, 2)"),
        (.unsafe("FLOAT"), "FLOAT"),
    ] as [(ColumnStorage, String)])
    func columnStorageAppendToBuilder(argument: (ColumnStorage, String)) {
        let builder = SQLBuilder()
        argument.0.append(to: builder)

        #expect(builder.sql == [argument.1])
    }
}
