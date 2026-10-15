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
        ),
        .executable(
            name: "OpenDisplayApp",
            targets: ["OpenDisplayApp"]
        ),
        .executable(
            name: "opendisplay",
            targets: ["OpenDisplayCLI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenDisplayCore",
            dependencies: [],
            path: "Sources/OpenDisplayCore"
        ),
        .executableTarget(
            name: "OpenDisplayApp",
            dependencies: ["OpenDisplayCore"],
            path: "Sources/OpenDisplayApp"
        ),
        .executableTarget(
            name: "OpenDisplayCLI",
            dependencies: ["OpenDisplayCore"],
            path: "Sources/OpenDisplayCLI"
        ),
        .testTarget(
            name: "OpenDisplayTests",
            dependencies: ["OpenDisplayCore"],
            path: "Tests/OpenDisplayTests"
        )
    ]
)
