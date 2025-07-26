// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

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
    ], dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0")
    ], targets: [
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
    ], swiftLanguageVersions: [.v5]
)

