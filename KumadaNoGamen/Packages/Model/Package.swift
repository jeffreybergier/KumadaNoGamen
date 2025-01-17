// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let name = "Model"

let package = Package(
    name: name,
    products: [
        .library(
            name: name,
            targets: [name]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: name,
            dependencies: [
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
