// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrchardKit",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "OrchardKit",
            targets: ["OrchardKit"]
        ),
        .library(
            name: "OrchardKitLogging",
            targets: ["OrchardKitLogging"]
        ),
    ],
    targets: [
        .target(
            name: "OrchardKit",
            dependencies: ["OrchardKitLogging"]
        ),
        .target(
            name: "OrchardKitLogging"
        ),
        .testTarget(
            name: "OrchardKitLoggingTests",
            dependencies: ["OrchardKitLogging"]
        ),
        .testTarget(
            name: "OrchardKitTests",
            dependencies: ["OrchardKit"]
        ),
    ]
)
