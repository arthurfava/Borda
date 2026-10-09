// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Borda",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "BordaCore", targets: ["BordaCore"]),
        .executable(name: "Borda", targets: ["Borda"])
    ],
    targets: [
        .target(
            name: "BordaCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Borda",
            dependencies: ["BordaCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "BordaCoreCheck",
            dependencies: ["BordaCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
