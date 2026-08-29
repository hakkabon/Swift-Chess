// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftChess",
    platforms: [.macOS(.v13), .iOS(.v14)],
    products: [
        .library(name: "SwiftChess", targets: ["SwiftChess"]),
        .executable(name: "ChessUI", targets: ["ChessUI"]),
    ],
    targets: [
        // 1. Your primary Swift frontend code
        .target(
            name: "SwiftChess",
            dependencies: ["ChessEngineKit"]
        ),
        // 2. The glue layer holding the generated UniFFI Swift file
        .target(
            name: "ChessEngineKit",
            dependencies: ["EngineFFI"]
        ),
        // The Auto-Injected Binary Target
        .binaryTarget(
            name: "EngineFFI",
//            path: "Frameworks/EngineFFI.xcframework"
            url: "https://github.com/hakkabon/Chess-Engine/releases/download/v0.0.1/ChessEngine.xcframework.zip",
            checksum: "ddbaf4730197d9537e22d8eacaa34599c90bac593f3ac7f847c21b78ba10eb8d"
        ),
        .executableTarget(
            name: "ChessUI",
            dependencies: ["SwiftChess, ChessEngineKit"],
            path: "Sources/ChessUI"
        ),
        .testTarget(
            name: "SwifChessTests",
            dependencies: ["SwiftChess"]
        ),
    ],
    // Swift 5 language mode keeps uniffi's concurrency annotations happy.
    swiftLanguageModes: [.v5]
)
