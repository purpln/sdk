// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "sdk",
    products: [
        .executable(name: "sdk", targets: ["Application"]),
    ],
    dependencies: [
        .package(url: "https://github.com/purpln/loop.git", branch: "main"),
    ],
    targets: [
        .target(name: "Architecture", dependencies: [
            .product(name: "Loop", package: "loop"),
        ]),
        .executableTarget(name: "Application", dependencies: [
            .target(name: "Architecture"),
            .target(name: "Coding"),
            .target(name: "File"),
            .target(name: "Piece"),
        ]),
        .target(name: "Coding"),
        .target(name: "File"),
        .target(name: "Piece"),
    ]
)

#if os(macOS)
package.platforms = [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16)]
#endif
