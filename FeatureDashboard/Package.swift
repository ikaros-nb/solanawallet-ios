// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"]),
    ],
    targets: [
        .target(name: "FeatureDashboard"),
    ]
)
