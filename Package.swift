// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Audiosmith",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Audiosmith", path: "Sources/Audiosmith"),
        .testTarget(name: "AudiosmithTests", dependencies: ["Audiosmith"], path: "Tests/AudiosmithTests")
    ]
)
