// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutomaticUpdaterFramework",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AutomaticUpdaterFramework",
            targets: ["AutomaticUpdaterFramework"]),
        /*.executable(
            name: "Updater",
            targets: ["Updater"])*/
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.18")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AutomaticUpdaterFramework",
            dependencies: ["ZIPFoundation"],
            resources: [
                .process("Resources/Main.storyboard")
            ]),
        .testTarget(
            name: "AutomaticUpdaterFrameworkTests",
            dependencies: ["AutomaticUpdaterFramework"]),
        /*.executableTarget(
            name: "Updater",
            dependencies: ["AutomaticUpdaterFramework"])*/
    ]
)
