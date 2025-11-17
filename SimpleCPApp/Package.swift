// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleCPApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SimpleCPApp",
            targets: ["SimpleCPApp"]
        )
    ],
    dependencies: [
        // No external dependencies - pure SwiftUI + Foundation
    ],
    targets: [
        .executableTarget(
            name: "SimpleCPApp",
            dependencies: [],
            path: "Sources/SimpleCPApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
