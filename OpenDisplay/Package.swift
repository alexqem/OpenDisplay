// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenDisplay",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "OpenDisplayCore",
            targets: ["OpenDisplayCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenDisplayCore",
            dependencies: [],
            path: "Sources/OpenDisplayCore"
        ),
        .testTarget(
            name: "OpenDisplayTests",
            dependencies: ["OpenDisplayCore"],
            path: "Tests/OpenDisplayTests"
        )
    ]
)
