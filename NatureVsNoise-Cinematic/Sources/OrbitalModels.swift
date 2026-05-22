import SceneKit
import simd

/// Shared orbital zone definitions for satellite visualizations
/// Contains both real-world orbital mechanics and scene rendering parameters
public struct OrbitalZoneDefinition {
    
    /// Real-world altitude range in kilometers
    public let altitudeRange: ClosedRange<Double>
    
    /// Scene rendering radius (scene units from Earth center)
    public let sceneRadius: Float
    
    /// Default satellite count for this zone
    public let defaultCount: Int
    
    /// Visual color for zone rendering
    public let color: NSColor
    
    /// Orbital angular velocity (radians per frame at 60fps)
    public let orbitalSpeed: Float
    
    /// Human-readable name
    public let displayName: String
    
    /// Real-world orbital period range (minutes)
    public let periodRangeMinutes: ClosedRange<Double>
    
    // MARK: - Zone Instances
    
    public static let leo = OrbitalZoneDefinition(
        altitudeRange: 160...2000,
        sceneRadius: 5.0,
        defaultCount: 8,
        color: NSColor(red: 0.2, green: 1.0, blue: 0.35, alpha: 1.0),    // Green
        orbitalSpeed: 0.006,
        displayName: "LEO",
        periodRangeMinutes: 88...127
    )
    
    public static let meo = OrbitalZoneDefinition(
        altitudeRange: 2000...35786,
        sceneRadius: 9.0,
        defaultCount: 6,
        color: NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0),     // Yellow
        orbitalSpeed: 0.004,
        displayName: "MEO",
        periodRangeMinutes: 720...1436
    )
    
    public static let geo = OrbitalZoneDefinition(
        altitudeRange: 35786...35786,
        sceneRadius: 14.0,
        defaultCount: 8,
        color: NSColor(red: 1.0, green: 0.25, blue: 0.2, alpha: 1.0),     // Red
        orbitalSpeed: 0.002,
        displayName: "GEO",
        periodRangeMinutes: 1436...1436  // Synchronous orbit
    )
    
    public static let heo = OrbitalZoneDefinition(
        altitudeRange: 35786...100000,
        sceneRadius: 19.0,
        defaultCount: 4,
        color: NSColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0),      // Blue
        orbitalSpeed: 0.001,
        displayName: "HEO",
        periodRangeMinutes: 1436...6384
    )
    
    // MARK: - All Zones
    
    public static let allZones: [OrbitalZoneDefinition] = [leo, meo, geo, heo]
    
    /// Get zone by display name
    public static func zone(named name: String) -> OrbitalZoneDefinition? {
        allZones.first { $0.displayName == name }
    }
    
    /// Get zone for a given altitude
    public static func zone(forAltitude altitudeKm: Double) -> OrbitalZoneDefinition {
        if altitudeKm <= leo.altitudeRange.upperBound { return leo }
        if altitudeKm <= meo.altitudeRange.upperBound { return meo }
        if altitudeKm <= geo.altitudeRange.upperBound { return geo }
        return heo
    }
}

// MARK: - Conversion Utilities

public extension OrbitalZoneDefinition {
    
    /// Earth radius in km (WGS84 mean)
    static let earthRadiusKm: Double = 6371.0
    
    /// Convert altitude km to scene units
    /// Uses logarithmic scale for visual clarity
    func scenePosition(forAltitude altitudeKm: Double) -> Float {
        let altitudeNormalized = log(altitudeKm + Self.earthRadiusKm) / log(100000 + Self.earthRadiusKm)
        return sceneRadius * Float(altitudeNormalized) * Float.random(in: 0.98...1.02)
    }
    
    /// Convert scene radius to approximate altitude km
    func approximateAltitude(forSceneRadius radius: Float) -> Double {
        let normalized = Double(radius / sceneRadius)
        let altitude = exp(normalized * log(100000 + Self.earthRadiusKm)) - Self.earthRadiusKm
        return max(altitude, altitudeRange.lowerBound)
    }
    
    /// Orbital velocity range (km/s) using simplified circular orbit formula
    /// v = sqrt(GM/r) where GM = 3.986004418e14 m³/s²
    var velocityRangeKmS: ClosedRange<Double> {
        let gm = 3.986004418e14
        let r1 = (altitudeRange.lowerBound + Self.earthRadiusKm) * 1000  // meters
        let r2 = (altitudeRange.upperBound + Self.earthRadiusKm) * 1000
        
        let v1 = sqrt(gm / r1) / 1000  // km/s
        let v2 = sqrt(gm / r2) / 1000
        
        return v1...v2
    }
}

// MARK: - Legacy Compatibility

/// Legacy enum for code that expects zone enum
@available(*, deprecated, message: "Use OrbitalZoneDefinition instead")
public enum OrbitalZone: String, CaseIterable {
    case leo, meo, geo, heo
    
    public var definition: OrbitalZoneDefinition {
        switch self {
        case .leo: return .leo
        case .meo: return .meo
        case .geo: return .geo
        case .heo: return .heo
        }
    }
    
    public var displayName: String { definition.displayName }
    public var sceneRadius: Float { definition.sceneRadius }
    public var color: NSColor { definition.color }
    public var orbitalSpeed: Float { definition.orbitalSpeed }
}