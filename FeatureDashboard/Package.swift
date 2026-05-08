// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"])
    ],
    dependencies: [
        .package(path: "../CorePresentation")
    ],
    targets: [
        .target(
            name: "FeatureDashboard",
            dependencies: [
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
