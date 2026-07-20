// swift-tools-version:5.9
//
// Headless test harness for NatureVsNoise.
//
// The screensaver itself is an Xcode .saver bundle (ScreenSaver.framework +
// AppKit), which SwiftPM can't easily compile. The testable surface — orbital
// propagation, TLE parsing, classification, FeatureFlags — is all Foundation
// only, so this Package exposes just that slice as a library and runs the
// existing XCTest files against it.
//
// Test files keep their original `@testable import NatureVsNoise` annotation
// (matching the Xcode module name); we name the SwiftPM library `NatureVsNoise`
// too so the same imports work here as in the Xcode build.

import PackageDescription

let package = Package(
    name: "NatureVsNoise",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NatureVsNoise", targets: ["NatureVsNoise"])
    ],
    targets: [
        .target(
            name: "NatureVsNoise",
            path: "NatureVsNoise/Sources",
            sources: [
                "Satellites/SGP4Propagator.swift",
                "Satellites/SatelliteClassification.swift",
                "Satellites/SatelliteManager.swift",
                "Satellites/TLEFetcher.swift",
                "FeatureFlags.swift",
            ]
        ),
        .testTarget(
            name: "NatureVsNoiseTests",
            dependencies: ["NatureVsNoise"],
            path: "NatureVsNoiseTests"
        ),
    ]
)
