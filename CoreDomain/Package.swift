// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreDomain",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreEntities", targets: ["CoreEntities"]),
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
    ],
    targets: [
        .target(name: "CoreEntities"),
        .target(name: "CoreDomain"),
    ]
)
