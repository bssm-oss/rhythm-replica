// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RhythmReplica",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "RhythmReplicaKit", targets: ["RhythmReplicaKit"]),
        .executable(name: "RhythmReplica", targets: ["RhythmReplicaApp"]),
        .executable(name: "RhythmReplicaSelfCheck", targets: ["RhythmReplicaSelfCheck"])
    ],
    targets: [
        .target(
            name: "RhythmReplicaKit",
            path: "RhythmReplica",
            exclude: ["App/main.swift"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RhythmReplicaApp",
            dependencies: ["RhythmReplicaKit"],
            path: "AppLauncher"
        ),
        .executableTarget(
            name: "RhythmReplicaSelfCheck",
            dependencies: ["RhythmReplicaKit"],
            path: "Verification"
        )
    ]
)
