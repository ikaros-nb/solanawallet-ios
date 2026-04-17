// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
    .treatWarning("DeprecatedDeclaration", as: .warning)
]

let package = Package(
    name: "CoreDomain",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
        .library(name: "CoreEntities", targets: ["CoreEntities"])
    ],
    targets: [
        .target(
            name: "CoreDomain",
            dependencies: ["CoreEntities"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CoreEntities",
            swiftSettings: swiftSettings
        )
    ]
)
