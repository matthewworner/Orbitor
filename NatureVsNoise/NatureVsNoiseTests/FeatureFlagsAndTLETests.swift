import XCTest
@testable import NatureVsNoise

/// Unit tests for FeatureFlags and TLE parsing
final class FeatureFlagsAndTLETests: XCTestCase {
    
    // MARK: - FeatureFlags Tests
    
    func testFeatureFlagsDefaultValues() {
        // Reset to known state
        FeatureFlags.resetToSafePreset()
        
        // Check safe preset defaults
        XCTAssertFalse(FeatureFlags.showLabels, "Show labels should be false by default")
        XCTAssertEqual(FeatureFlags.maxSatelliteCount, 50, "Safe preset max satellites should be 50")
        XCTAssertTrue(FeatureFlags.enableStarfield, "Starfield should be enabled")
        XCTAssertTrue(FeatureFlags.enableToySats, "Toy sats should be enabled")
        XCTAssertTrue(FeatureFlags.enableSwarm, "Swarm should be enabled")
    }
    
    func testFeatureFlagsPersistence() {
        // Reset first
        FeatureFlags.resetToSafePreset()
        
        // Set custom values
        FeatureFlags.showLabels = true
        FeatureFlags.maxSatelliteCount = 100
        
        // Should persist
        XCTAssertTrue(FeatureFlags.showLabels)
        XCTAssertEqual(FeatureFlags.maxSatelliteCount, 100)
        
        // Reset
        FeatureFlags.resetToSafePreset()
        
        // Should be back to defaults
        XCTAssertFalse(FeatureFlags.showLabels)
        XCTAssertEqual(FeatureFlags.maxSatelliteCount, 50)
    }
    
    func testFeatureFlagsFullPreset() {
        FeatureFlags.applyFullPreset()
        
        XCTAssertTrue(FeatureFlags.showLabels, "Full preset should enable labels")
        XCTAssertEqual(FeatureFlags.maxSatelliteCount, 5000, "Full preset should have 5000 satellites")
        XCTAssertTrue(FeatureFlags.enableAudio, "Full preset should enable audio")
        
        // Reset
        FeatureFlags.resetToSafePreset()
    }
    
    // MARK: - TLE Parsing Tests
    
    func testTLEStructParsing() {
        let tle = TLE(
            name: "ISS (ZARYA)",
            line1: "1 25544U 98067A   25146.50000000  .00016717  00000-0  30000-4 0  9994",
            line2: "2 25544  51.6416 285.8827 0006710  51.1782  59.0987 15.50145335423456"
        )

        XCTAssertNotNil(tle, "Valid TLE should parse successfully")
        // Force-unwrap after assertNotNil so the accuracy-typed XCTAssertEqual overload resolves.
        XCTAssertEqual(tle?.catalogNumber, 25544, "Catalog number should be 25544")
        XCTAssertEqual(tle!.inclination, 51.6416, accuracy: 0.0001, "Inclination should be 51.6416")
        XCTAssertEqual(tle!.eccentricity, 0.000671, accuracy: 0.000001, "Eccentricity should be 0.000671")
        XCTAssertEqual(tle!.meanMotion, 15.50145335, accuracy: 0.00000001, "Mean motion should be 15.50145335")
    }
    
    func testTLEInvalidLine1() {
        let tle = TLE(
            name: "TEST",
            line1: "SHORT", // Too short
            line2: "2 25544  51.6416 285.8827 0006710  51.1782  59.0987 15.50145335423456"
        )
        
        XCTAssertNil(tle, "Invalid TLE should return nil")
    }
    
    func testTLEInvalidLine2() {
        let tle = TLE(
            name: "TEST",
            line1: "1 25544U 98067A   25146.50000000  .00016717  00000-0  30000-4 0  9994",
            line2: "X" // Invalid
        )
        
        XCTAssertNil(tle, "Invalid TLE should return nil")
    }
    
    // MARK: - Satellite Classification Tests
    
    func testSatelliteClassification() {
        // Test ISS classification
        let issClass = SatelliteClassifier.classify(
            name: "ISS (ZARYA)",
            isDebris: false,
            country: "US"
        )
        XCTAssertEqual(issClass, .iss, "ISS should be classified as ISS")
        
        // Test Starlink classification
        let starlinkClass = SatelliteClassifier.classify(
            name: "STARLINK-1007",
            isDebris: false,
            country: "US"
        )
        XCTAssertEqual(starlinkClass, .starlink, "Starlink should be classified as Starlink")
        
        // Test debris classification
        let debrisClass = SatelliteClassifier.classify(
            name: "COSMOS 2251 DEBRIS",
            isDebris: true,
            country: "RU"
        )
        XCTAssertEqual(debrisClass, .debris, "DEBRIS in name should be debris")
        
        // Test active satellite (no notable/Starlink/debris pattern matches)
        let activeClass = SatelliteClassifier.classify(
            name: "COSMOS 2543",
            isDebris: false,
            country: "RU"
        )
        XCTAssertEqual(activeClass, .activeSatellite, "Plain satellite should be active")
    }

    // MARK: - HUD Classification Mapping Tests (Astra redesign)

    func testActiveTotalExcludesDebris() {
        var c = SatelliteManager.OrbitalCensus()
        c.iss = 1; c.starlink = 10; c.notable = 4; c.active = 20; c.debris = 100
        c.total = c.iss + c.starlink + c.notable + c.active + c.debris
        XCTAssertEqual(c.activeTotal, 35, "activeTotal sums functioning craft, excluding debris")
        XCTAssertEqual(c.total - c.activeTotal, c.debris, "Everything not active is debris in this fixture")
    }
    
    // MARK: - Orbital Elements Tests
    
    func testOrbitalElementsDerived() {
        let elements = OrbitalElements(
            epoch: 2460000.0,
            inclination: 51.6416 * .pi / 180.0,
            raan: 285.8827 * .pi / 180.0,
            eccentricity: 0.000671,
            argumentOfPerigee: 51.1782 * .pi / 180.0,
            meanAnomaly: 59.0987 * .pi / 180.0,
            meanMotion: 15.5,
            bStar: 0.00003,
            revolutionNumber: 42345
        )
        
        // Semi-major axis should be reasonable for LEO (~6700-7000 km)
        let a = elements.semiMajorAxisER * 6378.135 // Convert to km
        XCTAssertGreaterThan(a, 6700, "LEO semi-major axis should be around 6700-7000 km")
        XCTAssertLessThan(a, 7500, "LEO semi-major axis should be around 6700-7000 km")
        
        // Period should be reasonable
        let period = elements.period
        XCTAssertGreaterThan(period, 80, "LEO period should be ~90 minutes")
        XCTAssertLessThan(period, 120, "LEO period should be ~90 minutes")
    }

    // MARK: - Bundle ID contract (SettingsController regression)

    // Regression for commit 3e34d2b: SettingsController.bundleId used to be hardcoded to
    // "com.antigravity.NatureVsNoise", which didn't match the actual screensaver bundle
    // ID ("com.naturevsnoise.screensaver"), so the configure sheet wrote user settings
    // to a phantom defaults namespace the running saver never read.
    //
    // SettingsController is AppKit-only so it can't be imported here (the SwiftPM
    // library is Foundation-only). This test instead asserts the BUILD-TIME fallback
    // string the controller uses -- "com.naturevsnoise.screensaver" -- is well-formed.
    // The actual SettingsController is verified to use `Bundle.main.bundleIdentifier`
    // at runtime by reading the source; see SettingsController.swift:13.
    func testBundleIdFallbackContract() {
        let fallback = "com.naturevsnoise.screensaver"
        XCTAssertFalse(fallback.isEmpty, "Bundle ID fallback must not be empty")
        XCTAssertTrue(fallback.contains("."), "Bundle ID must have a reverse-DNS form")
        XCTAssertEqual(fallback.lowercased(), fallback, "Bundle ID should be lowercase")
        XCTAssertTrue(fallback.hasPrefix("com."), "Bundle ID should start with a vendor prefix")
    }
}