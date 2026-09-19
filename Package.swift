// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "ImperatorRetroPong",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ImperatorRetroPong",
            path: "Sources/ImperatorRetroPong",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
