//
//  Logger.swift
//  Created by Kristof Liliom in 2024.
//

@inline(never)
public func breakOnWarning() {}

private nonisolated(unsafe) var breakOnWarningInfoShown: Bool = false

package func warn(_ message: String) {
    print("[RelationalSwift] WARNING: \(message)")
    if !breakOnWarningInfoShown {
        breakOnWarningInfoShown = true
        print("[RelationalSwift] Set a symbolic breakpoint on `breakOnWarning` to see warnings in the debugger")
    }
    breakOnWarning()
}
