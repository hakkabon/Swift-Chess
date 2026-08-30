// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftChess",
    platforms: [.macOS(.v13), .iOS(.v14)],
    products: [
        .library(name: "SwiftChess", targets: ["SwiftChess"]),
        .library(name: "ChessUIKit", targets: ["ChessUIKit"]),
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
        .target(
            name: "ChessUIKit",
            dependencies: ["SwiftChess", "ChessEngineKit"],
            path: "Sources/ChessUIKit",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "ChessUI",
            dependencies: ["ChessUIKit"],
            path: "Sources/ChessUI"
        ),
        .testTarget(
            name: "SwiftChessTests",
            dependencies: ["SwiftChess"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
