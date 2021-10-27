// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
#if os(macOS) || os(Linux)
let package = Package(
    name: "Switchblade",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Switchblade",
            targets: ["Switchblade"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git",   .upToNextMinor(from: "1.3.8")),
        .package(url: "https://github.com/vapor/postgres-kit.git", .exact("2.3.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .systemLibrary(
                    name: "CSQLite",
                    path: "./Sources/CSQLite",
                    providers: [.apt(["libsqlite3-dev"])]),
        .target(
            name: "Switchblade",
            dependencies: ["CSQLite","CryptoSwift",.product(name: "PostgresKit", package: "postgres-kit", condition: .when(platforms: [.linux,.macOS]))],
            path: "./Sources/switchblade"),
        .testTarget(
            name: "SwitchbladeTests",
            dependencies: ["Switchblade"],
            path: "./Tests/switchbladeTests"),
    ]
)
#endif

#if os(iOS) || os(tvOS)
let package = Package(
    name: "Switchblade",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Switchblade",
            targets: ["Switchblade"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git",   .upToNextMinor(from: "1.3.8")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .systemLibrary(
                    name: "CSQLite",
                    path: "./Sources/CSQLite",
                    providers: [.apt(["libsqlite3-dev"])]),
        .target(
            name: "Switchblade",
            dependencies: ["CSQLite","CryptoSwift"],
            path: "./Sources/switchblade"),
        .testTarget(
            name: "SwitchbladeTests",
            dependencies: ["Switchblade"],
            path: "./Tests/switchbladeTests"),
    ]
)
#endif
