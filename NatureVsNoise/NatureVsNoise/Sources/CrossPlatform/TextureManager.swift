import AppKit

#if os(macOS)
public typealias TextureImage = NSImage
#else
public typealias TextureImage = UIImage
#endif

/// Protocol for texture loading implementations
/// Allows swapping between bundle loading (production) and filesystem loading (testing)
public protocol TextureLoading {
    func loadTexture(named: String) -> TextureImage?
}

/// Production implementation: loads textures from the screensaver bundle
public final class BundleTextureLoader: TextureLoading {
    
    public init() {}
    
    public func loadTexture(named: String) -> TextureImage? {
        let bundle = Bundle(for: type(of: self))
        
        // Priority 1: Direct bundle resource
        if let path = bundle.path(forResource: named, ofType: "jpg") {
            return loadImage(from: path)
        }
        if let path = bundle.path(forResource: named, ofType: "png") {
            return loadImage(from: path)
        }
        
        // Priority 2: 8K subdirectory (where planet textures live)
        if let resourcePath = bundle.resourcePath {
            for ext in ["jpg", "png"] {
                let path = "\(resourcePath)/8K/\(named).\(ext)"
                if FileManager.default.fileExists(atPath: path) {
                    return loadImage(from: path)
                }
            }
            
            // Legacy path: Resources/Textures/8K/
            for ext in ["jpg", "png"] {
                let path = "\(resourcePath)/Textures/8K/\(named).\(ext)"
                if FileManager.default.fileExists(atPath: path) {
                    return loadImage(from: path)
                }
            }
        }
        
        return nil
    }
    
    #if os(macOS)
    private func loadImage(from path: String) -> NSImage? {
        return NSImage(contentsOfFile: path)
    }
    #else
    private func loadImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    #endif
}

/// Central texture loading manager
/// Thread-safe singleton for consistent texture access across the screensaver
public final class TextureManager {
    
    public static let shared = TextureManager()
    
    private let loader: TextureLoading
    private var cache: [String: TextureImage?] = [:]
    private let cacheLock = NSLock()
    
    /// Initialize with a specific loader (primarily for testing)
    public init(loader: TextureLoading = BundleTextureLoader()) {
        self.loader = loader
    }
    
    /// Load a texture by name, with caching for performance
    public func load(named: String) -> TextureImage? {
        // Check cache first (thread-safe)
        cacheLock.lock()
        if let cached = cache[named] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        // Load and cache
        let image = loader.loadTexture(named: named)
        
        cacheLock.lock()
        cache[named] = image
        cacheLock.unlock()
        
        return image
    }
    
    /// Clear the texture cache (call when memory pressure occurs)
    public func clearCache() {
        cacheLock.lock()
        cache.removeAll()
        cacheLock.unlock()
    }
    
    /// Preload common textures to avoid first-frame stutter
    public func preload(_ names: [String]) {
        for name in names {
            _ = load(named: name)
        }
    }
}

// MARK: - Convenience Extensions

public extension TextureManager {
    
    /// Load Earth textures with all layers
    struct EarthTextures {
        public let day: TextureImage?
        public let night: TextureImage?
        public let clouds: TextureImage?
    }
    
    /// Get all Earth-related textures in one call
    func loadEarthTextures() -> EarthTextures {
        return EarthTextures(
            day: load(named: "earth_8k_day"),
            night: load(named: "earth_8k_night"),
            clouds: load(named: "earth_8k_clouds")
        )
    }
    
    /// Get all planet textures
    func loadPlanetTextures() -> [String: TextureImage?] {
        let planetNames = ["sun_8k", "moon_8k", "mars_8k", "venus_8k_surface", 
                          "mercury_8k", "jupiter_8k", "saturn_8k"]
        var result: [String: TextureImage?] = [:]
        for name in planetNames {
            result[name] = load(named: name)
        }
        return result
    }
}