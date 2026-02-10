// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "atmosphere",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "atmosphere", targets: ["atmosphere"])
    ],
    dependencies: [
        .package(path: "../swiftmark")
    ],
    targets: [
        .executableTarget(
            name: "atmosphere",
            dependencies: [
                .product(name: "SwiftMark", package: "SwiftMark")
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
