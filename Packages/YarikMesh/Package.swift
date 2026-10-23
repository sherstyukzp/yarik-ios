// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "YarikMesh",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "YarikMesh",
            targets: ["YarikMesh"]
        ),
    ],
    dependencies: [
        .package(path: "../../localPackages/Arti"),
        .package(path: "../../localPackages/BitFoundation"),
        .package(path: "../../localPackages/BitLogger"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.23.2"),
    ],
    targets: [
        .target(
            name: "YarikMesh",
            dependencies: [
                .product(name: "P256K", package: "swift-secp256k1"),
                .product(name: "BitFoundation", package: "BitFoundation"),
                .product(name: "BitLogger", package: "BitLogger"),
                .product(name: "Tor", package: "Arti"),
            ],
            path: "Sources/YarikMesh",
            exclude: [
                "Reference",
                "Info.plist",
                "bitchat.entitlements",
                "bitchat-macOS.entitlements",
                "LaunchScreen.storyboard",
                "_PreviewHelpers/PreviewAssets.xcassets",
                "ViewModels/Extensions/README.md",
            ],
            resources: [
                .process("Localizable.xcstrings"),
            ]
        ),
    ]
)
