import XCTest
import simd
@testable import NatureVsNoise

/// Unit tests for SGP4 orbital propagator
/// Tests verify orbital mechanics using known TLE data
final class SGP4PropagatorTests: XCTestCase {
    
    // MARK: - Test TLE Data
    
    /// ISS (ZARYA) - Low Earth Orbit, ~400km altitude
    private let issTLE = OrbitalElements(
        epoch: 2460000.0, // Simplified Julian date
        inclination: 51.6416 * .pi / 180.0,
        raan: 285.8827 * .pi / 180.0,
        eccentricity: 0.0006710,
        argumentOfPerigee: 51.1782 * .pi / 180.0,
        meanAnomaly: 59.0987 * .pi / 180.0,
        meanMotion: 15.50145335,
        bStar: 0.00003,
        revolutionNumber: 42345
    )
    
    /// GEO satellite - ~35,786km altitude, 24-hour period
    private let geoTLE = OrbitalElements(
        epoch: 2460000.0,
        inclination: 0.05 * .pi / 180.0,
        raan: 100.0 * .pi / 180.0,
        eccentricity: 0.0001,
        argumentOfPerigee: 180.0 * .pi / 180.0,
        meanAnomaly: 0.0,
        meanMotion: 1.0027,
        bStar: 0.0,
        revolutionNumber: 1
    )
    
    // MARK: - Basic Propagation Tests
    
    func testISSLowEarthOrbitPropagation() {
        let propagator = SGP4Propagator(elements: issTLE)
        
        // Propagate for 1 minute
        let result = propagator.propagate(minutesSinceEpoch: 1.0)
        
        // Should have valid position
        XCTAssertNotNil(result.position, "Position should not be nil")
        XCTAssertNil(result.error, "Should not have propagation error")
        
        // ISS at ~400km should have position magnitude around 6800-6900 km
        let r = simd_length(result.position)
        XCTAssertGreaterThan(r, 6700, "ISS should be above Earth's surface (~6778 km)")
        XCTAssertLessThan(r, 7500, "ISS should not be too high for LEO")
    }
    
    func testGEOSatellitePropagation() {
        let propagator = SGP4Propagator(elements: geoTLE)
        
        // Propagate for 1 minute
        let result = propagator.propagate(minutesSinceEpoch: 1.0)
        
        // Should have valid position
        XCTAssertNotNil(result.position, "Position should not be nil")
        XCTAssertNil(result.error, "Should not have propagation error")
        
        // GEO at ~42,164 km should be around 42000-43000 km from center
        let r = simd_length(result.position)
        XCTAssertGreaterThan(r, 40000, "GEO should be far from Earth")
        XCTAssertLessThan(r, 50000, "GEO should not be too far")
    }
    
    // MARK: - Velocity Tests

    // Regression for commit d8d53b7: SGP4 velocity was 13x too high because the formula
    // divided by 60.0 to convert min->sec but was missing the / tumin factor (13.4468),
    // so velocity came out in earth-radii/TU/min instead of km/s. LEO computed as 103
    // km/s vs real ~7.66; GEO ~41 vs ~3.07. Both ratios identical to the missing constant,
    // which is what surfaced the bug. If a future change re-introduces the unit bug,
    // these tests will fail with v well outside the 7-9 / 2.5-4 km/s window.

    func testVelocityUnitsAreKmPerSecondNotEarthRadiiPerMinute_LEO() {
        let propagator = SGP4Propagator(elements: issTLE)

        let result = propagator.propagate(minutesSinceEpoch: 1.0)

        let v = simd_length(result.velocity)
        // LEO velocity ~7.8 km/s
        XCTAssertGreaterThan(v, 7.0, "LEO velocity should be around 7-8 km/s")
        XCTAssertLessThan(v, 9.0, "LEO velocity should not be too high")
    }

    func testVelocityUnitsAreKmPerSecondNotEarthRadiiPerMinute_GEO() {
        let propagator = SGP4Propagator(elements: geoTLE)

        let result = propagator.propagate(minutesSinceEpoch: 1.0)

        let v = simd_length(result.velocity)
        // GEO velocity ~3.07 km/s
        XCTAssertGreaterThan(v, 2.5, "GEO velocity should be around 3 km/s")
        XCTAssertLessThan(v, 4.0, "GEO velocity should not be too high")
    }
    
    // MARK: - Error Handling Tests
    
    func testHighlyEccentricOrbit() {
        var eccentricTLE = issTLE
        eccentricTLE = OrbitalElements(
            epoch: eccentricTLE.epoch,
            inclination: eccentricTLE.inclination,
            raan: eccentricTLE.raan,
            eccentricity: 0.9, // Highly elliptical
            argumentOfPerigee: eccentricTLE.argumentOfPerigee,
            meanAnomaly: eccentricTLE.meanAnomaly,
            meanMotion: eccentricTLE.meanMotion,
            bStar: eccentricTLE.bStar,
            revolutionNumber: eccentricTLE.revolutionNumber
        )
        
        let propagator = SGP4Propagator(elements: eccentricTLE)
        let result = propagator.propagate(minutesSinceEpoch: 1.0)
        
        // Should handle eccentric orbit (may have validity error, that's ok)
        XCTAssertNotNil(result.position)
    }
    
    // MARK: - Time Evolution Tests
    
    func testPositionChangesOverTime() {
        let propagator = SGP4Propagator(elements: issTLE)
        
        let result1 = propagator.propagate(minutesSinceEpoch: 0.0)
        let result10 = propagator.propagate(minutesSinceEpoch: 10.0)
        
        // Positions should be different
        let dist = simd_distance(result1.position, result10.position)
        XCTAssertGreaterThan(dist, 10.0, "Satellite should move noticeably over 10 minutes")
    }
    
    // MARK: - Orbital Period Tests
    
    func testOrbitalPeriodCalculation() {
        // ISS has ~15.5 rev/day, period = 1440/15.5 ≈ 92.9 minutes
        let period = issTLE.period
        XCTAssertGreaterThan(period, 80.0, "ISS period should be around 90 minutes")
        XCTAssertLessThan(period, 110.0, "ISS period should be around 90 minutes")
    }
    
    func testGEOPeriodCalculation() {
        // GEO has ~1 rev/day, period = 1440 minutes
        let period = geoTLE.period
        XCTAssertGreaterThan(period, 1300.0, "GEO period should be around 24 hours (1440 min)")
        XCTAssertLessThan(period, 1600.0, "GEO period should be around 24 hours (1440 min)")
    }
}