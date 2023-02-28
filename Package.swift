// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ometria",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Ometria",
            targets: ["Ometria"]),
    ],
    dependencies: [
        .package(name: "Firebase",
                 url: "https://github.com/firebase/firebase-ios-sdk.git",
                 "7.0.0"..<"11.0.0")
    ],
    targets: [
        .target(
            name: "Ometria",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "Firebase")
                ]),
    ]
)
