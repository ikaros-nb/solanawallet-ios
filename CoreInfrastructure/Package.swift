// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
    .treatWarning("DeprecatedDeclaration", as: .warning)
]

let package = Package(
    name: "CoreInfrastructure",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"])
    ],
    dependencies: [
        .package(path: "../CoreDomain")
    ],
    targets: [
        .target(
            name: "CoreInfrastructure",
            dependencies: [
                .product(name: "CoreEntities", package: "CoreDomain")
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
