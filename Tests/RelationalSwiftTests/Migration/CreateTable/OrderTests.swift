//
//  OrderTests.swift
//  Created by Kristof Liliom in 2024.
//

import Testing

@testable import RelationalSwift

@Suite
struct OrderTests {
    @Test("Append to builder", arguments: [
        (.ascending, ["ASC"]),
        (.descending, ["DESC"]),
    ] as [(Order, [String])])
    func appendToBuilder(argument: (Order, [String])) {
        let order = argument.0
        let builder = SQLBuilder()
        order.append(to: builder)

        #expect(builder.sql == [argument.1.first!])
    }
}
