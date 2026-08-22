// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ImperatorRetroPong",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ImperatorRetroPong",
            path: "Sources/ImperatorRetroPong"
        )
    ]
)
