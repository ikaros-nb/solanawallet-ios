// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CorePresentation",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreUI", targets: ["CoreUI"]),
    ],
    targets: [
        .target(name: "CoreUI"),
    ]
)
