// swift-tools-version: 6.0

import Foundation
import PackageDescription
import CompilerPluginSupport

// Use swift format when developing this library, but don't
// add additional dependency for the users of this library.
let useSwiftFormat: Bool = ProcessInfo.processInfo.environment["GITHUB_JOB"] != nil

var package = Package(
    name: "RelationalSwift",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .macCatalyst(.v14),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "RelationalSwift",
            targets: ["RelationalSwift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "RelationalSwift",
            dependencies: ["RelationalSwiftMacros"]
        ),
        .testTarget(
            name: "RelationalSwiftTests",
            dependencies: ["RelationalSwift"]
        ),
        .macro(
            name: "RelationalSwiftMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "RelationalSwiftMacrosTests",
            dependencies: [
                "RelationalSwiftMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)

if useSwiftFormat {
    package.dependencies.append(
        .package(url: "https://github.com/kliliom/SwiftFormatPlugin.git", from: "0.54.5")
    )

    let targets = ["RelationalSwift", "RelationalSwiftMacros"]
    package.targets.forEach { target in
        guard targets.contains(where: { target.name == $0 || target.name == "\($0)Tests" }) else { return }
        if target.plugins == nil {
            target.plugins = []
        }
        target.plugins?.append(.plugin(name: "SwiftFormatPlugin", package: "SwiftFormatPlugin"))
    }
}
