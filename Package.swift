// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ometria",
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Ometria",
            targets: ["Ometria"]),
    ],
    dependencies: [
        .package(name: "Firebase",
                 url: "https://github.com/firebase/firebase-ios-sdk.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "Ometria",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "Firebase")
                ]),
    ]
)
