// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Checkpoint",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Checkpoint",
            path: "Sources/Checkpoint"
        )
    ]
)
