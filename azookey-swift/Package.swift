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
        .package(url: "https://github.com/azookey/AzooKeyKanaKanjiConverter", branch: "66a341b7e656c2fff02c1399882e88ee067b3d31", traits: ["Zenzai"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "ffi"),
        .target(
            name: "azookey-swift",
            dependencies: [
                .product(name: "KanaKanjiConverterModuleWithDefaultDictionary", package: "AzooKeyKanaKanjiConverter"),
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
