import Foundation
import simd

/// A satellite prepared for cinematic (Kubrick-style) rendering
struct CinematicSatellite: Identifiable {
    var id: UUID
    var name: String
    
    /// Current orbital position (normalized to Earth radius)
    var position: SIMD3<Float>
    
    /// Velocity vector (for trails and glint calculations)
    var velocity: SIMD3<Float>
    
    /// Satellite network/group
    var group: SatelliteGroup
    
    /// Visual classification
    var classification: CinematicClassification
    
    /// Orbital zone
    var zone: OrbitalZone
    
    /// Currently glinting (specular flash)
    var isGlinting: Bool
    
    /// Phase offset for glint animation
    var glintPhase: Float
    
    /// Duration of glint in seconds
    var glintDuration: Float
    
    /// Constellation connection indices
    var constellationConnections: [Int] = []
    
    /// Trail positions for motion blur effect
    var trailPositions: [SIMD3<Float>] = []
    
    /// Current glint intensity (0-1)
    var glintIntensity: Float = 0
    
    /// Color based on group
    var color: SIMD4<Float> {
        let c = group.color
        let base = SIMD4<Float>(c.r, c.g, c.b, 1.0)
        
        // Boost if glinting
        if isGlinting {
            return SIMD4<Float>(
                min(base.x * 3.0, 1.0),
                min(base.y * 3.0, 1.0),
                min(base.z * 3.0, 1.0),
                1.0
            )
        }
        
        return base
    }
    
    /// Size based on classification
    var visualSize: Float {
        switch classification {
        case .hero:
            return 0.15      // ISS, Hubble - visible
        case .constellation:
            return 0.08      // Starlink - medium
        case .navigation:
            return 0.06      // GPS, GLONASS - small
        case .scientific:
            return 0.12      // Hubble, JWST
        case .swarm:
            return 0.12      // General - visible
        case .debris:
            return 0.08      // Old satellites - small
        }
    }
    
    /// Glow intensity based on state
    var glowIntensity: Float {
        if isGlinting {
            return glintIntensity * 2.0
        }
        return 0.6 + Float(classification.renderPriority) * 0.005  // Higher base glow
    }
}

/// Visual classification for cinematic mode
enum CinematicClassification: Int, CaseIterable {
    case hero           // ISS, space stations
    case constellation  // Starlink, OneWeb
    case navigation     // GPS, GLONASS, Galileo
    case scientific     // Hubble, telescopes
    case debris         // Old satellites, fragments
    case swarm          // General satellites
    
    var renderPriority: Int {
        switch self {
        case .hero: return 100
        case .constellation: return 80
        case .scientific: return 70
        case .navigation: return 60
        case .debris: return 20
        case .swarm: return 30
        }
    }
    
    var minSize: Float {
        switch self {
        case .hero: return 0.12
        case .constellation: return 0.06
        case .scientific: return 0.10
        case .navigation: return 0.04
        case .debris: return 0.02
        case .swarm: return 0.02
        }
    }
}

/// Connection between satellites for constellation rendering
struct ConstellationConnection {
    var fromIndex: Int
    var toIndex: Int
    var intensity: Float  // 0-1, based on distance
}