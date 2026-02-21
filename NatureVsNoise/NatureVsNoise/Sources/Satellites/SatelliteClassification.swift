import Foundation

/// Classification of satellite types for visual rendering
enum SatelliteClass: Equatable {
    case iss
    case starlink
    case notable(String)
    case activeSatellite
    case debris
    
    /// Display name for UI purposes
    var displayName: String {
        switch self {
        case .iss:
            return "International Space Station"
        case .starlink:
            return "Starlink"
        case .notable(let name):
            return name
        case .activeSatellite:
            return "Active Satellite"
        case .debris:
            return "Space Debris"
        }
    }
    
    /// Priority for rendering (higher = more important)
    var renderPriority: Int {
        switch self {
        case .iss:
            return 100
        case .notable:
            return 80
        case .starlink:
            return 50
        case .activeSatellite:
            return 30
        case .debris:
            return 10
        }
    }
    
    /// Whether this class should use 3D model rendering in SceneKit
    var useSceneKitModel: Bool {
        switch self {
        case .iss, .notable:
            return true
        case .starlink, .activeSatellite, .debris:
            return false  // Use Metal swarm for these
        }
    }
}

/// Known notable satellite name patterns for classification
enum NotableSatellitePatterns {
    /// ISS name patterns
    static let issNames = ["ISS", "ZARYA"]
    
    /// Starlink name pattern
    static let starlinkPrefix = "STARLINK"
    
    /// Notable satellite patterns with their classifications
    static let notablePatterns: [(patterns: [String], classification: SatelliteClass)] = [
        (["HUBBLE", "HST"], .notable("Hubble Space Telescope")),
        (["TIANHE", "TIANGONG"], .notable("Tiangong Space Station")),
        (["GPS", "NAVSTAR"], .notable("GPS Satellite")),
        (["GOES"], .notable("Weather Satellite")),
        (["LANDSAT"], .notable("Earth Observation")),
        (["SENTINEL"], .notable("ESA Sentinel")),
        (["SUOMI"], .notable("Weather Satellite")),
        (["JAMES WEBB", "JWST"], .notable("James Webb Telescope")),
        (["TDRS"], .notable("TDRS Communications")),
        (["TESS"], .notable("TESS Telescope"))
    ]
    
    /// Check if name matches ISS
    static func isISS(name: String) -> Bool {
        let upper = name.uppercased()
        return issNames.contains { upper.contains($0) }
    }
    
    /// Check if name matches Starlink
    static func isStarlink(name: String) -> Bool {
        return name.uppercased().hasPrefix(starlinkPrefix)
    }
    
    /// Find notable satellite classification for name
    static func findNotable(name: String) -> SatelliteClass? {
        let upper = name.uppercased()
        for (patterns, classification) in notablePatterns {
            if patterns.contains(where: { upper.contains($0) }) {
                return classification
            }
        }
        return nil
    }
}

/// Classification engine for satellites
struct SatelliteClassifier {
    
    /// Classify a satellite based on its properties
    static func classify(name: String, isDebris: Bool, country: String) -> SatelliteClass {
        // Check for ISS first (highest priority)
        if NotableSatellitePatterns.isISS(name: name) {
            return .iss
        }
        
        // Check for other notable satellites
        if let notable = NotableSatellitePatterns.findNotable(name: name) {
            return notable
        }
        
        // Check for Starlink
        if NotableSatellitePatterns.isStarlink(name: name) {
            return .starlink
        }
        
        // Check for debris
        if isDebris {
            return .debris
        }
        
        // Default to active satellite
        return .activeSatellite
    }
    
    /// Calculate satellite age from epoch
    static func calculateAge(epoch: Double) -> Double {
        let epochDate = julianToDate(julianDay: epoch)
        let now = Date()
        let age = now.timeIntervalSince(epochDate)
        return age / (365.25 * 24 * 3600)  // Years
    }
    
    /// Determine visual LOD based on camera distance
    static func lodForDistance(_ distance: Float) -> SatelliteLOD {
        if distance < 5 {
            return .full
        } else if distance < 15 {
            return .simplified
        } else {
            return .point
        }
    }
    
    // MARK: - Private Helpers
    
    private static func julianToDate(julianDay: Double) -> Date {
        let unixEpochJulian = 2440587.5
        let secondsPerDay = 86400.0
        let timeInterval = (julianDay - unixEpochJulian) * secondsPerDay
        return Date(timeIntervalSince1970: timeInterval)
    }
}

/// Level of Detail for satellite rendering
enum SatelliteLOD {
    case full       // Full 3D model with all details
    case simplified // Low-poly model or simplified geometry
    case point      // Metal point sprite (swarm)
    
    var maxPolygonCount: Int {
        switch self {
        case .full:
            return 1000
        case .simplified:
            return 100
        case .point:
            return 0
        }
    }
}
