// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Decode",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Decode", targets: ["Decode"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Decode",
            dependencies: ["SwiftTerm"],
            path: "Sources/Decode"
        ),
        .testTarget(
            name: "DecodeTests",
            dependencies: ["Decode"],
            path: "Tests/DecodeTests"
        )
    ]
)
