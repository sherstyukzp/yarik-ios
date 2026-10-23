// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Yarik",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [],
    dependencies: [
        .package(path: "Packages/YarikMesh"),
        .package(path: "localPackages/BitFoundation"),
    ],
    targets: [
        .testTarget(
            name: "YarikMeshTests",
            dependencies: [
                .product(name: "YarikMesh", package: "YarikMesh"),
                .product(name: "BitFoundation", package: "BitFoundation"),
            ],
            path: "YarikMeshTests",
            exclude: [
                "Info.plist",
                "README.md",
                "Performance/perf-floors.json",
            ],
            resources: [
                .process("Localization"),
                .process("Noise/NoiseTestVectors.json"),
                .process("Nostr/Fixtures"),
            ]
        ),
    ]
)
