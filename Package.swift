// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-github-api",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "GitHubAPI",
            targets: ["GitHubAPI"]
        ),
    ],
    targets: [
        .target(
            name: "GitHubAPI",
            path: "Sources/GitHubAPI"
        ),
        .testTarget(
            name: "GitHubAPITests",
            dependencies: ["GitHubAPI"],
            path: "Tests/GitHubAPITests"
        ),
    ]
)
