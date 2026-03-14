// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SkibidiAltTab",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "SkibidiAltTab",
            path: "Sources/SkibidiAltTab"
        )
    ]
)
