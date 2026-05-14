// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureVault",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureVault", targets: ["FeatureVault"])
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreDependencies"),
        .package(path: "../CorePresentation")
    ],
    targets: [
        .target(
            name: "FeatureVault",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "CoreEntities", package: "CoreDomain"),
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
