// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ometria",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Ometria",
            targets: ["Ometria"]),
    ],
    dependencies: [
        .package(name: "Firebase",
                   url: "https://github.com/firebase/firebase-ios-sdk.git",
                   .branch("6.33-spm-beta"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Ometria",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "Firebase")
                ]),
        .testTarget(
            name: "OmetriaTests",
            dependencies: ["Ometria"]),
    ]
)
