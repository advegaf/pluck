// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Pluck",
    platforms: [
        // Runtime floor is macOS 26 (matches Info.plist's LSMinimumSystemVersion).
        // The HUD uses Liquid Glass (`.glassEffect`, `GlassEffectContainer`),
        // which requires macOS 26; the SwiftPM platform is raised to match so
        // the source doesn't need `@available` guards throughout.
        .macOS(.v26),
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
