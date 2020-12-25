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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.42.0")
    ],
    targets: [
        .target(
            name: "SwiftLintBot",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "SwiftLintFramework", package: "SwiftLint")
            ],
            resources: [
                .copy("Resources/swiftlint.yml")
            ]
        )
    ]
)
