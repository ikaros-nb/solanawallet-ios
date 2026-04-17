// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreInfrastructure",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"]),
    ],
    targets: [
        .target(name: "CoreInfrastructure"),
    ]
)
