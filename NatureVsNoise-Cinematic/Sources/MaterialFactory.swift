import SceneKit

/// Factory for creating SceneKit materials used across satellite models
/// Centralizes material creation to ensure consistent appearance
public final class MaterialFactory {
    
    private init() {} // Static factory - no instantiation
    
    // MARK: - Satellite Materials
    
    /// Solar panel material - dark blue with subtle emission
    public static func solarPanel() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
        m.emission.contents = NSColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)
        m.emission.intensity = 0.8
        m.metalness.contents = 0.4
        m.roughness.contents = 0.25
        m.lightingModel = .physicallyBased
        return m
    }
    
    /// White painted surface - ISS modules, cubeSat bodies
    public static func white() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.95, alpha: 1.0)
        m.metalness.contents = 0.0
        m.roughness.contents = 0.6
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.15, alpha: 1.0)
        m.emission.intensity = 0.2
        return m
    }
    
    /// Gold foil - thermal blankets, radiators
    public static func gold() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        m.metalness.contents = 1.0
        m.roughness.contents = 0.2
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(red: 0.3, green: 0.25, blue: 0.1, alpha: 1.0)
        m.emission.intensity = 0.3
        return m
    }
    
    /// Black coating - starlink body, heat-resistant surfaces
    public static func black() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.1, alpha: 1.0)
        m.metalness.contents = 0.8
        m.roughness.contents = 0.3
        m.lightingModel = .physicallyBased
        return m
    }
    
    /// Metallic - rocket bodies, debris, engine bells
    public static func metal() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.4, alpha: 1.0)
        m.metalness.contents = 0.9
        m.roughness.contents = 0.4
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.05, alpha: 1.0)
        m.emission.intensity = 0.1
        return m
    }
    
    // MARK: - Cached Variants
    
    // Lazy-loaded cached instances for high-frequency use
    private static var _solarPanel: SCNMaterial?
    private static var _white: SCNMaterial?
    private static var _gold: SCNMaterial?
    private static var _black: SCNMaterial?
    private static var _metal: SCNMaterial?
    
    /// Get cached solar panel material (avoids recreation on every satellite)
    public static var solarPanelCached: SCNMaterial {
        if let cached = _solarPanel { return cached }
        let material = solarPanel()
        _solarPanel = material
        return material
    }
    
    /// Get cached white material
    public static var whiteCached: SCNMaterial {
        if let cached = _white { return cached }
        let material = white()
        _white = material
        return material
    }
    
    /// Get cached gold material
    public static var goldCached: SCNMaterial {
        if let cached = _gold { return cached }
        let material = gold()
        _gold = material
        return material
    }
    
    /// Get cached black material
    public static var blackCached: SCNMaterial {
        if let cached = _black { return cached }
        let material = black()
        _black = material
        return material
    }
    
    /// Get cached metal material
    public static var metalCached: SCNMaterial {
        if let cached = _metal { return cached }
        let material = metal()
        _metal = material
        return material
    }
    
    /// Clear all cached materials (call on memory warning)
    public static func clearCache() {
        _solarPanel = nil
        _white = nil
        _gold = nil
        _black = nil
        _metal = nil
    }
}