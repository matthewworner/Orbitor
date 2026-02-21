import Foundation

struct FeatureFlags {
    // User defaults keys
    private static let showLabelsKey = "showLabels"
    private static let maxSatelliteCountKey = "maxSatelliteCount"
    private static let enableStarfieldKey = "enableStarfield"
    private static let enableToySatsKey = "enableToySats"
    private static let enableSwarmKey = "enableSwarm"  // Controls Metal swarm rendering
    private static let showTrailsKey = "showTrails"
    private static let enableAudioKey = "enableAudio"

    // Default values for safe preset
    static let safePreset: [String: Any] = [
        showLabelsKey: false,
        maxSatelliteCountKey: 50,
        enableStarfieldKey: true,
        enableToySatsKey: true,
        enableSwarmKey: true,   // Metal swarm enabled (now works in full-screen)
        showTrailsKey: true,
        enableAudioKey: false
    ]
    
    // Full preset with all features enabled
    static let fullPreset: [String: Any] = [
        showLabelsKey: true,
        maxSatelliteCountKey: 5000,
        enableStarfieldKey: true,
        enableToySatsKey: true,
        enableSwarmKey: true,
        showTrailsKey: true,
        enableAudioKey: true
    ]

    // Getters with defaults
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

    /// Enable Metal swarm rendering (thousands of point sprites)
    /// This now works in full-screen mode via SceneKit delegate integration
    static var enableSwarm: Bool {
        get { UserDefaults.standard.bool(forKey: enableSwarmKey) }
        set { UserDefaults.standard.set(newValue, forKey: enableSwarmKey) }
    }
    
    static var showTrails: Bool {
        get { UserDefaults.standard.bool(forKey: showTrailsKey) }
        set { UserDefaults.standard.set(newValue, forKey: showTrailsKey) }
    }
    
    static var enableAudio: Bool {
        get { UserDefaults.standard.bool(forKey: enableAudioKey) }
        set { UserDefaults.standard.set(newValue, forKey: enableAudioKey) }
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
    
    // Apply full preset
    static func applyFullPreset() {
        let defaults = UserDefaults.standard
        for (key, value) in fullPreset {
            defaults.set(value, forKey: key)
        }
    }
}