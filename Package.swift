// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TextInjector",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "TextInjector", targets: ["TextInjectorApp"])],
    targets: [
        .target(name: "TextInjectorCore"),
        .executableTarget(name: "TextInjectorApp", dependencies: ["TextInjectorCore"]),
        .testTarget(name: "TextInjectorCoreTests", dependencies: ["TextInjectorCore"])
    ]
)
