// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicMerge",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MicMerge", path: "Sources/MicMerge"),
        .testTarget(name: "MicMergeTests", dependencies: ["MicMerge"], path: "Tests/MicMergeTests")
    ]
)
