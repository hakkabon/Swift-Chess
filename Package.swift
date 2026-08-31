// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftChess",
    platforms: [
        .macOS(.v13),
        // iPadOS uses SwiftPM's iOS platform declaration.
        .iOS(.v16),
    ],
    products: [
        .library(name: "SwiftChess", targets: ["SwiftChess"]),
        .library(name: "ChessUIKit", targets: ["ChessUIKit"]),
        // SwiftPM executables are suitable for the macOS launcher. The iPad
        // application bundle is defined by iOSApp/ChessUI.xcodeproj and links
        // the ChessUIKit library product above.
        .executable(name: "ChessUIMac", targets: ["ChessUIMac"]),
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
            name: "ChessUIMac",
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
