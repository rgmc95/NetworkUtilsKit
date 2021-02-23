// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkUtilsKit",
    platforms: [.iOS("10.0")],
    products: [
        .library(
            name: "NetworkUtilsKit",
            targets: ["NetworkUtilsKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/rgmc95/UtilsKit.git", from: "2.0.7"),
    ],
    targets: [
        .target(
            name: "NetworkUtilsKit",
            dependencies: ["UtilsKit"],
            path: "./NetworkUtilsKit/Core")
    ]
)
