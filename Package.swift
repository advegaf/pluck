// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Pluck",
    platforms: [
        // Runtime floor is macOS 26 (set in Info.plist's LSMinimumSystemVersion).
        // The SwiftPM platform floor stays at the highest enum value currently
        // exposed; none of the source requires a newer availability gate.
        .macOS(.v15),
    ],
    products: [
        .executable(name: "Pluck", targets: ["Pluck"]),
    ],
    targets: [
        .executableTarget(
            name: "Pluck",
            path: "Sources/Pluck",
            exclude: [
                "Resources/Info.plist",
                "Resources/entitlements.plist",
                // Finder propagates a zero-byte "Icon\r" marker file when
                // the enclosing folder has a custom icon. It has no role in
                // the package.
                "Icon\r",
                "Engine/Icon\r",
                "HUD/Icon\r",
                "Prefs/Icon\r",
                "Onboarding/Icon\r",
                "Resources/Icon\r",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-parse-as-library"]),
            ]
        ),
        .testTarget(
            name: "PluckTests",
            dependencies: ["Pluck"],
            path: "Tests/PluckTests",
            exclude: ["Icon\r"]
        ),
    ]
)
