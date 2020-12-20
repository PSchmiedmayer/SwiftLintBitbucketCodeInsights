// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "SwiftLint Bitbucket Code Insights",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "SwiftLintBot", targets: ["SwiftLintBot"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "SwiftLintBot",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "SwiftLintBotTests",
            dependencies: [
                .target(name: "SwiftLintBot")
            ]
        )
    ]
)
