// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureWallet",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureWallet", targets: ["FeatureWallet"])
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreDependencies"),
        .package(path: "../CorePresentation")
    ],
    targets: [
        .target(
            name: "FeatureWallet",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "CoreDependencies", package: "CoreDependencies"),
                .product(name: "CoreUI", package: "CorePresentation")
            ],
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .treatAllWarnings(as: .error),
                .treatWarning("DeprecatedDeclaration", as: .warning)
            ]
        )
    ]
)
