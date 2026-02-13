// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ometria",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Ometria",
            targets: ["Ometria"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "10.10.0"..<"999.0.0")
    ],
    targets: [
        .target(
            name: "Ometria",
            dependencies: [
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
                ]),
    ]
)
