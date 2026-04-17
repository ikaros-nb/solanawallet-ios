// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureVault",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureVault", targets: ["FeatureVault"])
    ],
    targets: [
        .target(
            name: "FeatureVault",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .treatAllWarnings(as: .error),
                .treatWarning("DeprecatedDeclaration", as: .warning)
            ]
        )
    ]
)
