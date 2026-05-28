// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Cairn",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "CairnKit",
            targets: ["CairnKit"]
        ),
        .executable(
            name: "Cairn",
            targets: ["Cairn"]
        ),
        .executable(
            name: "CairnFixture",
            targets: ["CairnFixture"]
        ),
        .executable(
            name: "CairnSmokeSuite",
            targets: ["CairnSmokeSuite"]
        ),
        .executable(
            name: "CursorMotion",
            targets: ["CursorMotion"]
        ),
        .executable(
            name: "StandaloneCursor",
            targets: ["StandaloneCursor"]
        ),
    ],
    targets: [
        .target(
            name: "CairnKit",
            path: "packages/CairnKit/Sources/CairnKit"
        ),
        .executableTarget(
            name: "Cairn",
            dependencies: ["CairnKit"],
            path: "apps/Cairn/Sources/Cairn"
        ),
        .executableTarget(
            name: "CairnFixture",
            dependencies: ["CairnKit"],
            path: "apps/CairnFixture/Sources/CairnFixture"
        ),
        .executableTarget(
            name: "CairnSmokeSuite",
            dependencies: ["CairnKit"],
            path: "apps/CairnSmokeSuite/Sources/CairnSmokeSuite"
        ),
        .executableTarget(
            name: "CursorMotion",
            path: "experiments/CursorMotion/Sources/CursorMotion"
        ),
        .target(
            name: "StandaloneCursorSupport",
            path: "experiments/StandaloneCursor/Sources/StandaloneCursorSupport"
        ),
        .executableTarget(
            name: "StandaloneCursor",
            dependencies: ["StandaloneCursorSupport"],
            path: "experiments/StandaloneCursor/Sources/StandaloneCursor"
        ),
        .testTarget(
            name: "CairnKitTests",
            dependencies: ["CairnKit"],
            path: "packages/CairnKit/Tests/CairnKitTests"
        ),
        .testTarget(
            name: "StandaloneCursorSupportTests",
            dependencies: ["StandaloneCursorSupport"],
            path: "experiments/StandaloneCursor/Tests/StandaloneCursorSupportTests"
        ),
    ]
)
