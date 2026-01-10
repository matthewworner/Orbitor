import Foundation

struct FeatureFlags {
    // User defaults keys
    private static let useMetalSatellitesKey = "useMetalSatellites"
    private static let showLabelsKey = "showLabels"
    private static let maxSatelliteCountKey = "maxSatelliteCount"
    private static let enableStarfieldKey = "enableStarfield"
    private static let enableToySatsKey = "enableToySats"
    private static let enableSwarmKey = "enableSwarm"

    // Default values for safe preset
    static let safePreset: [String: Any] = [
        useMetalSatellitesKey: false,
        showLabelsKey: false,
        maxSatelliteCountKey: 50,
        enableStarfieldKey: true,
        enableToySatsKey: true,
        enableSwarmKey: false  // Start with swarm off for safety
    ]

    // Getters with defaults
    static var useMetalSatellites: Bool {
        get { UserDefaults.standard.bool(forKey: useMetalSatellitesKey) }
        set { UserDefaults.standard.set(newValue, forKey: useMetalSatellitesKey) }
    }

    static var showLabels: Bool {
        get { UserDefaults.standard.bool(forKey: showLabelsKey) }
        set { UserDefaults.standard.set(newValue, forKey: showLabelsKey) }
    }

    static var maxSatelliteCount: Int {
        get { UserDefaults.standard.integer(forKey: maxSatelliteCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: maxSatelliteCountKey) }
    }

    static var enableStarfield: Bool {
        get { UserDefaults.standard.bool(forKey: enableStarfieldKey) }
        set { UserDefaults.standard.set(newValue, forKey: enableStarfieldKey) }
    }

    static var enableToySats: Bool {
        get { UserDefaults.standard.bool(forKey: enableToySatsKey) }
        set { UserDefaults.standard.set(newValue, forKey: enableToySatsKey) }
    }

    static var enableSwarm: Bool {
        get { UserDefaults.standard.bool(forKey: enableSwarmKey) }
        set { UserDefaults.standard.set(newValue, forKey: enableSwarmKey) }
    }

    // Initialize with safe defaults if not set
    static func initializeDefaults() {
        let defaults = UserDefaults.standard
        for (key, value) in safePreset {
            if defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
    }

    // Reset to safe preset
    static func resetToSafePreset() {
        let defaults = UserDefaults.standard
        for (key, value) in safePreset {
            defaults.set(value, forKey: key)
        }
    }
}