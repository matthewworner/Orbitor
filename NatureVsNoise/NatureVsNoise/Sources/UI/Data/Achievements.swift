import Foundation
import SpriteKit

/// Achievement definitions and tracking for the gamification system
class AchievementManager {
    
    static let shared = AchievementManager()
    
    // MARK: - Achievement Definitions
    
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "first_flight",
            name: "First Flight",
            description: "See your first satellite",
            emoji: "🚀",
            requirement: 1,
            type: .satelliteSpotted
        ),
        Achievement(
            id: "home_sweet_home",
            name: "Home Sweet Home",
            description: "Locate the International Space Station",
            emoji: "🏠",
            requirement: 1,
            type: .notableSatellite,
            targetSatellite: "ISS"
        ),
        Achievement(
            id: "eye_in_sky",
            name: "Eye in the Sky",
            description: "Find the Hubble Space Telescope",
            emoji: "🔭",
            requirement: 1,
            type: .notableSatellite,
            targetSatellite: "HST"
        ),
        Achievement(
            id: "king_of_ring",
            name: "King of the Ring",
            description: "Spot a satellite in geostationary orbit",
            emoji: "👑",
            requirement: 1,
            type: .orbitalZone,
            targetZone: .geo
        ),
        Achievement(
            id: "speed_demon",
            name: "Speed Demon",
            description: "See a satellite at its fastest (periapsis)",
            emoji: "⚡",
            requirement: 1,
            type: .orbitalZone,
            targetZone: .leo
        ),
        Achievement(
            id: "moon_hunter",
            name: "Moon Hunter",
            description: "Find a satellite in highly elliptical orbit",
            emoji: "🌙",
            requirement: 1,
            type: .orbitalZone,
            targetZone: .heo
        ),
        Achievement(
            id: "dish_hunt",
            name: "Dish Hunt",
            description: "Identify a Starlink satellite",
            emoji: "📡",
            requirement: 1,
            type: .notableSatellite,
            targetSatellite: "STARLINK"
        ),
        Achievement(
            id: "collector",
            name: "Collector",
            description: "Find 10 different satellite types",
            emoji: "🛰️",
            requirement: 10,
            type: .satelliteTypes
        ),
        Achievement(
            id: "debris_expert",
            name: "Debris Expert",
            description: "Spot debris from 3 different countries",
            emoji: "🎯",
            requirement: 3,
            type: .countrySpotted
        ),
        Achievement(
            id: "globe_trotter",
            name: "Globe Trotter",
            description: "Visit all orbital zones in one session",
            emoji: "🌍",
            requirement: 3,
            type: .orbitalZone
        ),
        Achievement(
            id: "century_club",
            name: "Century Club",
            description: "Track 100 satellites in a session",
            emoji: "💯",
            requirement: 100,
            type: .satelliteSpotted
        ),
        Achievement(
            id: "orbits_master",
            name: "Orbits Master",
            description: "Complete 10 full orbits witnessed",
            emoji: "🔄",
            requirement: 10,
            type: .orbitsCompleted
        )
    ]
    
    // MARK: - State
    
    private(set) var unlockedAchievements: Set<String> = []
    private(set) var satelliteCounts: [String: Int] = [:]  // satellite type -> count
    private(set) var countryCounts: [String: Int] = [:]   // country -> count
    private(set) var zonesVisited: Set<OrbitalZone> = []
    private(set) var totalSatellitesSpotted: Int = 0
    private(set) var orbitsCompleted: Int = 0
    
    // Callbacks
    var onAchievementUnlocked: ((Achievement) -> Void)?
    
    // MARK: - UserDefaults Keys
    
    private let achievementsKey = "NatureVsNoise.unlockedAchievements"
    
    // MARK: - Initialization
    
    private init() {
        loadProgress()
    }
    
    // MARK: - Progress Tracking
    
    func trackSatelliteSpotted(name: String, country: String?, type: String, altitude: Double) {
        totalSatellitesSpotted += 1
        
        // Track satellite type
        satelliteCounts[type, default: 0] += 1
        
        // Track country
        if let country = country {
            countryCounts[country, default: 0] += 1
        }
        
        // Track orbital zone
        let zone = zoneForAltitude(altitude)
        zonesVisited.insert(zone)
        
        // Check achievements
        checkAchievements()
    }
    
    func trackOrbitCompleted() {
        orbitsCompleted += 1
        checkAchievements()
    }
    
    func trackNotableSatellite(_ name: String) {
        // Handled in satellite spotted
        checkAchievements()
    }
    
    private func zoneForAltitude(_ altitude: Double) -> OrbitalZone {
        if altitude <= 2000 {
            return .leo
        } else if altitude <= 35786 {
            return .meo
        } else {
            return .geo
        }
    }
    
    private func checkAchievements() {
        for achievement in AchievementManager.allAchievements {
            guard !unlockedAchievements.contains(achievement.id) else { continue }
            
            let unlocked: Bool
            switch achievement.type {
            case .satelliteSpotted:
                unlocked = totalSatellitesSpotted >= achievement.requirement
            case .satelliteTypes:
                unlocked = satelliteCounts.count >= achievement.requirement
            case .countrySpotted:
                unlocked = countryCounts.count >= achievement.requirement
            case .orbitalZone:
                if let targetZone = achievement.targetZone {
                    unlocked = zonesVisited.contains(targetZone) && 
                               zonesVisited.count >= achievement.requirement
                } else {
                    unlocked = zonesVisited.count >= achievement.requirement
                }
            case .notableSatellite:
                // Check if target satellite has been spotted
                let targetLower = achievement.targetSatellite?.lowercased() ?? ""
                unlocked = satelliteCounts.keys.contains { $0.lowercased().contains(targetLower) }
            case .orbitsCompleted:
                unlocked = orbitsCompleted >= achievement.requirement
            }
            
            if unlocked {
                unlockAchievement(achievement)
            }
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        unlockedAchievements.insert(achievement.id)
        saveProgress()
        onAchievementUnlocked?(achievement)
        
        #if DEBUG
        print("🏆 Achievement Unlocked: \(achievement.name)")
        #endif
    }
    
    // MARK: - Persistence
    
    func saveProgress() {
        UserDefaults.standard.set(Array(unlockedAchievements), forKey: achievementsKey)
    }
    
    private func loadProgress() {
        if let saved = UserDefaults.standard.stringArray(forKey: achievementsKey) {
            unlockedAchievements = Set(saved)
        }
    }
    
    func resetProgress() {
        unlockedAchievements.removeAll()
        satelliteCounts.removeAll()
        countryCounts.removeAll()
        zonesVisited.removeAll()
        totalSatellitesSpotted = 0
        orbitsCompleted = 0
        saveProgress()
    }
    
    // MARK: - Stats
    
    var progressSummary: String {
        return """
        Satellites Spotted: \(totalSatellitesSpotted)
        Countries: \(countryCounts.count)
        Orbital Zones: \(zonesVisited.count)
        Achievements: \(unlockedAchievements.count)/\(AchievementManager.allAchievements.count)
        """
    }
}

/// Achievement definition
struct Achievement {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let requirement: Int
    let type: AchievementType
    var targetSatellite: String?
    var targetZone: OrbitalZone?
    
    var progressText: String {
        switch type {
        case .satelliteSpotted:
            return "\(AchievementManager.shared.totalSatellitesSpotted)/\(requirement)"
        case .satelliteTypes:
            return "\(AchievementManager.shared.satelliteCounts.count)/\(requirement)"
        case .countrySpotted:
            return "\(AchievementManager.shared.countryCounts.count)/\(requirement)"
        case .orbitalZone:
            return "\(AchievementManager.shared.zonesVisited.count)/\(requirement)"
        case .notableSatellite:
            return AchievementManager.shared.satelliteCounts.keys.contains { 
                $0.lowercased().contains(targetSatellite?.lowercased() ?? "")
            } ? "✓" : "○"
        case .orbitsCompleted:
            return "\(AchievementManager.shared.orbitsCompleted)/\(requirement)"
        }
    }
}

/// Achievement type for tracking
enum AchievementType {
    case satelliteSpotted       // Count total satellites
    case satelliteTypes         // Different types
    case countrySpotted        // Different countries
    case orbitalZone           // Different zones visited
    case notableSatellite      // Specific satellite found
    case orbitsCompleted       // Full orbits
}
