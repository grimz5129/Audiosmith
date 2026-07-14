// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Audify",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Audify", path: "Sources/Audify"),
        .testTarget(name: "AudifyTests", dependencies: ["Audify"], path: "Tests/AudifyTests")
    ]
)
