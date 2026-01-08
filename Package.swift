// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Zen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Zen", targets: ["Zen"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Zen",
            dependencies: [],
            path: "Sources/Zen"
        )
    ]
)
