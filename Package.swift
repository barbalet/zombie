// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "zombie",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "ZombieCore", targets: ["ZombieCore"]),
        .executable(name: "ZombieApp", targets: ["ZombieApp"]),
        .executable(name: "ZombieRegression", targets: ["ZombieRegression"])
    ],
    targets: [
        .target(
            name: "FieldOfChaosEngine",
            path: "foc/src/engine",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "ZombieCore",
            dependencies: ["FieldOfChaosEngine"],
            path: "zombie/Sources/ZombieCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "ZombieApp",
            dependencies: ["ZombieCore"],
            path: "zombie/Sources/ZombieApp"
        ),
        .executableTarget(
            name: "ZombieRegression",
            dependencies: ["ZombieCore"],
            path: "zombie/Sources/ZombieRegression"
        ),
        .testTarget(
            name: "ZombieCoreTests",
            dependencies: ["ZombieCore", "FieldOfChaosEngine"],
            path: "zombie/Tests/ZombieCoreTests"
        )
    ]
)
