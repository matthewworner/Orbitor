import Foundation

/// Feature flags for controlling rendering options and presets
/// Stored in UserDefaults for persistence across launches
struct FeatureFlags {
    // MARK: - Rendering Options

    /// Enable Metal-accelerated satellite rendering (firefly swarm)
    var useMetalSatellites: Bool {
        get { UserDefaults.standard.bool(forKey: "useMetalSatellites") }
        set { UserDefaults.standard.set(newValue, forKey: "useMetalSatellites") }
    }

    /// Show satellite labels (disabled by default for performance)
    var showLabels: Bool {
        get { UserDefaults.standard.bool(forKey: "showLabels") }
        set { UserDefaults.standard.set(newValue, forKey: "showLabels") }
    }

    /// Maximum number of satellites to render
    var maxSatelliteCount: Int {
        get { UserDefaults.standard.integer(forKey: "maxSatelliteCount") }
        set { UserDefaults.standard.set(newValue, forKey: "maxSatelliteCount") }
    }

    /// Enable starfield background
    var enableStarfield: Bool {
        get { UserDefaults.standard.bool(forKey: "enableStarfield") }
        set { UserDefaults.standard.set(newValue, forKey: "enableStarfield") }
    }

    /// Enable toy satellite geometry (SceneKit cross/T shapes)
    var enableToySats: Bool {
        get { UserDefaults.standard.bool(forKey: "enableToySats") }
        set { UserDefaults.standard.set(newValue, forKey: "enableToySats") }
    }

    /// Enable firefly swarm (Metal point sprites)
    var enableSwarm: Bool {
        get { UserDefaults.standard.bool(forKey: "enableSwarm") }
        set { UserDefaults.standard.set(newValue, forKey: "enableSwarm") }
    }

    // MARK: - Presets

    /// Apply safe preset: minimal features for stability
    func applySafePreset() {
        useMetalSatellites = false
        showLabels = false
        maxSatelliteCount = 800
        enableStarfield = true
        enableToySats = true
        enableSwarm = false
    }

    /// Apply full preset: all features enabled
    func applyFullPreset() {
        useMetalSatellites = true
        showLabels = false  // Keep off for performance
        maxSatelliteCount = 40000
        enableStarfield = true
        enableToySats = true
        enableSwarm = true
    }

    /// Apply toy-only preset: just toy sats, no swarm
    func applyToyOnlyPreset() {
        useMetalSatellites = false
        showLabels = false
        maxSatelliteCount = 50
        enableStarfield = true
        enableToySats = true
        enableSwarm = false
    }

    /// Apply swarm-only preset: just fireflies, no geometry
    func applySwarmOnlyPreset() {
        useMetalSatellites = true
        showLabels = false
        maxSatelliteCount = 40000
        enableStarfield = true
        enableToySats = false
        enableSwarm = true
    }

    // MARK: - Initialization

    init() {
        // Set defaults if not already set
        if UserDefaults.standard.object(forKey: "useMetalSatellites") == nil {
            applySafePreset()
        }
    }

    // MARK: - Debug

    var debugDescription: String {
        return """
        FeatureFlags:
          Metal Satellites: \(useMetalSatellites)
          Show Labels: \(showLabels)
          Max Satellites: \(maxSatelliteCount)
          Starfield: \(enableStarfield)
          Toy Sats: \(enableToySats)
          Swarm: \(enableSwarm)
        """
    }
}