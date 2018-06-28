// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Sdift",
    products: [
        .library(name: "Sdift", targets: ["Sdift"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "Sdift", dependencies: []),
        .testTarget(name: "SdiftTests", dependencies: ["Sdift"]),
    ]
)
