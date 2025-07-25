// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkUtilsKit",
	platforms: [.iOS("16.0"), .macOS("14.0")],
    products: [
        .library(name: "NetworkUtilsKit", targets: ["NetworkUtilsKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/rgmc95/UtilsKit.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "NetworkUtilsKit",
			dependencies: [.product(name: "UtilsKitCore", package: "UtilsKit")])
    ]
)
