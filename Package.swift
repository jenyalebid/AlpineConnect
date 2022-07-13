// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AlpineConnect",
    platforms: [
        .iOS(.v15)
    ], products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AlpineConnect",
            targets: ["AlpineConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/codewinsdotcom/PostgresClientKit.git", from: "1.4.3"),
        .package(url: "https://github.com/jenyalebid/AlpineUI.git", from: "1.0.0"),
        .package(url: "https://github.com/Kitura/Swift-SMTP.git", from: "6.0.0")
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AlpineConnect",
            dependencies: ["PostgresClientKit", "AlpineUI", .product(name: "SwiftSMTP", package: "Swift-SMTP")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "AlpineConnectTests",
            dependencies: ["AlpineConnect"]),
    ]
)