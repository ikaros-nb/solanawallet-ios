// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureWallet",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureWallet", targets: ["FeatureWallet"]),
    ],
    targets: [
        .target(name: "FeatureWallet"),
    ]
)
