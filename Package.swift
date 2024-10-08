// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AVPlayerWrapper",
     platforms: [
        .iOS(.v12),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "AVPlayerWrapper",
            targets: ["AVPlayerWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/moslienko/AppViewUtilits.git", from: "1.3.1")
    ],
    targets: [
       .target(
            name: "AVPlayerWrapper",
            dependencies: ["AppViewUtilits"]
        ),
        .testTarget(
            name: "AVPlayerWrapperTests",
            dependencies: ["AVPlayerWrapper"]),
    ]
)
