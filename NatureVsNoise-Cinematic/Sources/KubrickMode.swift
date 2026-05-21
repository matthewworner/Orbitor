import Foundation

/// Kubrick Mode: Cinematic rendering configuration
/// 
/// This mode emphasizes artistic interpretation over data accuracy.
/// Instead of showing satellites as dots, we show them as *light events*:
/// - Specular glints from tumbling solar panels
/// - Constellation patterns for coordinated satellite groups
/// - Orbital shell density visualization
/// - The ephemeral beauty of human presence in orbit
enum KubrickMode: String, CaseIterable {
    case glints        // Specular flashes from sun angle
    case constellations // Connected networks (Starlink)
    case shells        // Orbital altitude bands
    case density       // Heat map of satellite distribution
    case trails        // Motion paths showing velocity
    
    var displayName: String {
        switch self {
        case .glints: return "Glints"
        case .constellations: return "Constellations"
        case .shells: return "Orbital Shells"
        case .density: return "Density Map"
        case .trails: return "Motion Trails"
        }
    }
    
    var description: String {
        switch self {
        case .glints:
            return "Brief specular flashes as satellites tumble in sunlight"
        case .constellations:
            return "Network connections between coordinated satellite groups"
        case .shells:
            return "Altitude bands (LEO/MEO/GEO) as translucent shells"
        case .density:
            return "Color-coded density showing congestion hotspots"
        case .trails:
            return "Velocity vectors as fading light trails"
        }
    }
}

/// Orbital zone definitions
enum OrbitalZone: String, CaseIterable {
    case leo = "LEO"  // Low Earth Orbit: 160-2000 km
    case meo = "MEO"  // Medium Earth Orbit: 2000-35786 km
    case geo = "GEO"  // Geostationary: 35786 km
    case heo = "HEO"  // High Earth Orbit: beyond GEO
    
    var altitudeRange: ClosedRange<Double> {
        switch self {
        case .leo: return 160...2000
        case .meo: return 2000...35786
        case .geo: return 35786...35786
        case .heo: return 35786...100000
        }
    }
    
    var shellRadius: Float {
        switch self {
        case .leo: return 6371 + 550   // ~7000 km
        case .meo: return 6371 + 20000  // ~26000 km  
        case .geo: return 6371 + 35786  // ~42157 km
        case .heo: return 6371 + 50000  // ~56000 km
        }
    }
    
    var color: (r: Float, g: Float, b: Float) {
        switch self {
        case .leo: return (0.2, 0.8, 0.3)   // Green
        case .meo: return (0.8, 0.7, 0.2)   // Yellow
        case .geo: return (0.8, 0.3, 0.2)   // Red
        case .heo: return (0.3, 0.3, 0.8)   // Blue
        }
    }
}

/// Satellite group classification for constellation mode
enum SatelliteGroup: String, CaseIterable {
    case starlink
    case oneweb
    case iridium
    case globalstar
    case orbcomm
    case planet
    case ses
    case intelsat
    case gps
    case glonass
    case galileo
    case beidou
    case other
    
    var displayName: String {
        switch self {
        case .starlink: return "Starlink"
        case .oneweb: return "OneWeb"
        case .iridium: return "Iridium"
        case .globalstar: return "Globalstar"
        case .orbcomm: return "Orbcomm"
        case .planet: return "Planet Labs"
        case .ses: return "SES"
        case .intelsat: return "Intelsat"
        case .gps: return "GPS"
        case .glonass: return "GLONASS"
        case .galileo: return "Galileo"
        case .beidou: return "BeiDou"
        case .other: return "Other"
        }
    }
    
    var color: (r: Float, g: Float, b: Float) {
        switch self {
        case .starlink: return (0.1, 0.4, 0.9)      // SpaceX blue
        case .oneweb: return (0.6, 0.2, 0.8)         // Purple
        case .iridium: return (0.1, 0.1, 0.1)        // Near black
        case .globalstar: return (0.9, 0.6, 0.1)     // Orange
        case .orbcomm: return (0.8, 0.2, 0.2)        // Red
        case .planet: return (0.2, 0.7, 0.3)         // Green
        case .ses: return (0.1, 0.1, 0.6)            // Dark blue
        case .intelsat: return (0.5, 0.5, 0.5)       // Grey
        case .gps: return (0.3, 0.6, 1.0)            // Light blue
        case .glonass: return (0.8, 0.1, 0.1)        // Russian red
        case .galileo: return (0.1, 0.5, 0.8)        // EU blue
        case .beidou: return (0.9, 0.7, 0.1)         // Gold
        case .other: return (0.7, 0.7, 0.7)          // White
        }
    }
}