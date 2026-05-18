// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
    .treatWarning("DeprecatedDeclaration", as: .warning)
]

let package = Package(
    name: "CoreInfrastructure",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"])
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(url: "https://github.com/p2p-org/solana-swift", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "CoreInfrastructure",
            dependencies: [
                .product(name: "CoreDomain", package: "CoreDomain"),
                .product(name: "CoreEntities", package: "CoreDomain"),
                .product(name: "SolanaSwift", package: "solana-swift")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CoreInfrastructureTests",
            dependencies: ["CoreInfrastructure"],
            swiftSettings: swiftSettings
        )
    ]
)
