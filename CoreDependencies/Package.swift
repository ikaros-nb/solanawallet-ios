// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreDependencies",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreDependencies", targets: ["CoreDependencies"])
    ],
    dependencies: [
        .package(path: "../CoreDomain")
    ],
    targets: [
        .target(
            name: "CoreDependencies",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .treatAllWarnings(as: .error),
                .treatWarning("DeprecatedDeclaration", as: .warning)
            ]
        )
    ]
)
