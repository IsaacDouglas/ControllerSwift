// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ControllerSwift",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "ControllerSwift", targets: ["ControllerSwift"])
    ],
    dependencies: [
        .package(name: "PerfectCRUD", url: "https://github.com/PerfectlySoft/Perfect-CRUD.git", from: "2.0.0"),
        .package(name: "PerfectCrypto", url: "https://github.com/PerfectlySoft/Perfect-Crypto.git", from: "3.0.0"),
        .package(name: "PerfectHTTP", url: "https://github.com/PerfectlySoft/Perfect-HTTP.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "ControllerSwift",
            dependencies: ["PerfectCRUD", "PerfectCrypto", "PerfectHTTP"],
            path: "Sources"),
        .testTarget(
            name: "ControllerSwiftTests",
            dependencies: ["ControllerSwift"]),
    ]
)
