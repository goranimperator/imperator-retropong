// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ImperatorPong",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ImperatorPong",
            path: "Sources/ImperatorPong"
        )
    ]
)
