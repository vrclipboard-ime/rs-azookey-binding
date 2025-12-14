// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "azookey-swift",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "azookey-swift",
            type: .dynamic,
            targets: ["azookey-swift"]),
        .library(
            name: "ffi",
            targets: ["azookey-swift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vrclipboard-ime/AzooKeyKanaKanjiConverter", branch: "481b52e8c6c6dc128320cb258a1b9fdeeb6b5b6e", traits: ["Zenzai"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "ffi"),
        .target(
            name: "azookey-swift",
            dependencies: [
                .product(name: "KanaKanjiConverterModule", package: "azookeykanakanjiconverter"),
                "ffi"
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)],
        ),
        .testTarget(
            name: "azookey-swiftTests",
            dependencies: ["azookey-swift"]
        ),
    ]
)
