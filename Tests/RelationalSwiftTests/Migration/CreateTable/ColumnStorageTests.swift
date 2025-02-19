//
//  ColumnStorageTests.swift
//

import Testing

@testable import RelationalSwift

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
        var builder = SQLBuilder()
        argument.0.append(to: &builder)

        #expect(builder.sql == [argument.1])
    }
}
