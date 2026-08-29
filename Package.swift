// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftChess",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftChess", targets: ["SwiftChess"]),
        .executable(name: "ChessUI", targets: ["ChessUI"]),
    ],
    targets: [
        .target(
            name: "ChessEngineKit",
            dependencies: ["EngineFFI"]
        ),
        .target(
            name: "SwiftChess",
            dependencies: ["ChessEngineKit"]
        ),
        .binaryTarget(
            name: "EngineFFI",
            path: "Frameworks/ChessEngineKitFFI.xcframework"
        ),
        .executableTarget(
            name: "ChessUI",
            dependencies: ["SwiftChess", "ChessEngineKit"],
            path: "Sources/ChessUI"
        ),
        .testTarget(
            name: "SwiftChessTests",
            dependencies: ["SwiftChess"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
