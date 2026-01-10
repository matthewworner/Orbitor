import SceneKit

/// Factory for creating planet nodes with textures
class PlanetFactory {
    
    /// Planet data with relative sizes (Earth = 1.0)
    struct PlanetData {
        let name: String
        let radius: Float
        let distance: Float      // From sun (AU scaled)
        let rotationPeriod: Double // Seconds for one rotation
        let axialTilt: Float     // Degrees
        let texturePrefix: String
        let hasRings: Bool
        let roughness: Float // PBR Roughness (0.0 - 1.0)
        let metalness: Float // PBR Metalness (0.0 - 1.0)
        
        static let sun = PlanetData(
            name: "Sun", radius: 10.0, distance: 0,
            rotationPeriod: 120, axialTilt: 7.25,
            texturePrefix: "sun_8k", hasRings: false,
            roughness: 1.0, metalness: 0.0
        )
        
        static let mercury = PlanetData(
            name: "Mercury", radius: 0.38, distance: 15,
            rotationPeriod: 58.6, axialTilt: 0.03,
            texturePrefix: "mercury_8k", hasRings: false,
            roughness: 0.9, metalness: 0.1
        )
        
        static let venus = PlanetData(
            name: "Venus", radius: 0.95, distance: 20,
            rotationPeriod: -243, axialTilt: 177.4, // Retrograde
            texturePrefix: "venus_8k", hasRings: false,
            roughness: 0.8, metalness: 0.0 // Clouds are matte
        )
        
        static let earth = PlanetData(
            name: "Earth", radius: 1.0, distance: 30,
            rotationPeriod: 60, axialTilt: 23.5,
            texturePrefix: "earth_8k_day", hasRings: false,
            roughness: 0.5, metalness: 0.0 // Mixed (ocean shiny, land matte)
        )
        
        static let mars = PlanetData(
            name: "Mars", radius: 0.53, distance: 40,
            rotationPeriod: 24.6, axialTilt: 25.2,
            texturePrefix: "mars_8k", hasRings: false,
            roughness: 0.9, metalness: 0.2 // Rusty dust
        )
        
        static let jupiter = PlanetData(
            name: "Jupiter", radius: 5.0, distance: 80,
            rotationPeriod: 9.9, axialTilt: 3.1,
            texturePrefix: "jupiter_8k", hasRings: false,
            roughness: 0.4, metalness: 0.0 // Gas giant sheen
        )
        
        static let saturn = PlanetData(
            name: "Saturn", radius: 4.5, distance: 120,
            rotationPeriod: 10.7, axialTilt: 26.7,
            texturePrefix: "saturn_8k", hasRings: true,
            roughness: 0.4, metalness: 0.0
        )
        
        static let uranus = PlanetData(
            name: "Uranus", radius: 2.0, distance: 160,
            rotationPeriod: -17.2, axialTilt: 97.8, // Extreme tilt
            texturePrefix: "uranus_8k", hasRings: false,
            roughness: 0.3, metalness: 0.0 // Ice giant
        )
        
        static let neptune = PlanetData(
            name: "Neptune", radius: 1.9, distance: 200,
            rotationPeriod: 16.1, axialTilt: 28.3,
            texturePrefix: "neptune_8k", hasRings: false,
            roughness: 0.3, metalness: 0.0
        )
        
        static let allPlanets: [PlanetData] = [
            .mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune
        ]
    }
    
    // MARK: - Planet Creation
    
    // Diagnostic log file
    private static func logToFile(_ message: String) {
        let logPath = NSHomeDirectory() + "/Desktop/screensaver_debug.log"
        let logMessage = "[PlanetFactory] \(message)\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? logMessage.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    }
    
    /// Creates a planet node with texture and rotation
    static func createPlanet(_ data: PlanetData) -> SCNNode {
        logToFile("Creating planet: \(data.name) with texture prefix: \(data.texturePrefix)")
        
        let geometry = SCNSphere(radius: CGFloat(data.radius * 2))
        geometry.segmentCount = 96 // Increased smoothness for PBR
        
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = defaultColor(for: data.name)
        material.roughness.contents = NSNumber(value: data.roughness)
        material.metalness.contents = NSNumber(value: data.metalness)
        
        // Try to load texture
        if let texture = loadTexture(named: data.texturePrefix) {
            logToFile("✅ Texture LOADED for \(data.name): \(data.texturePrefix)")
            material.diffuse.contents = texture
            
            // Emissive for sun
            if data.name == "Sun" {
                material.emission.contents = texture
                material.emission.intensity = 2.0 // High intensity for bloom
                material.lightingModel = .constant // Sun emits light, doesn't receive
            }
        } else {
            logToFile("❌ Texture FAILED for \(data.name): \(data.texturePrefix)")
        }
        
        // Load Normal Map if available
        if let normalMap = loadTexture(named: "\(data.texturePrefix)_normal") {
            material.normal.contents = normalMap
            material.normal.intensity = 1.0
        }
        
        geometry.materials = [material]
        

        // Special material properties for specific planets
        if data.name == "Earth" {
            // Try to load night texture for emission (city lights)
            if let nightTexture = loadTexture(named: "earth_8k_night") {
                material.emission.contents = nightTexture
                material.emission.intensity = 0.5
            }
            
            // Specular/Roughness map for ocean reflections
            // Use specular map as roughness (inverted) or just specific map
            if let specularMap = loadTexture(named: "earth_8k_specular") {
                material.roughness.contents = specularMap
                // Invert specularity for roughness: where spec is white (shiny), roughness should be black (smooth)
                // SceneKit might need a custom shader modifier for perfect control, but this is a good start.
                // Alternatively, simpler hack:
                material.specular.contents = specularMap
                material.lightingModel = .phong // Fallback to Phong if we want explicit specular control without roughness map
                // But let's stick to PBR:
                 material.lightingModel = .physicallyBased
                 // For PBR, roughness map text is usually: Black = Smooth, White = Rough.
                 // Ocean specular maps are White = Water, Black = Land.
                 // So we need to invert it.
                 // If we don't have an inverted map, we can stick to Phong for Earth OR just rely on the scalar.
            } else {
                 material.roughness.contents = 0.8 // Land defaults
            }
        }
        
        let node = SCNNode(geometry: geometry)
        node.name = data.name
        node.position = SCNVector3(x: CGFloat(data.distance), y: 0, z: 0)
        
        // Apply axial tilt
        node.eulerAngles.z = CGFloat(data.axialTilt) * .pi / 180.0
        
        // Add rotation
        let direction: CGFloat = data.rotationPeriod < 0 ? -1 : 1
        let period = abs(data.rotationPeriod)
        let rotation = SCNAction.rotateBy(x: 0, y: direction * .pi * 2, z: 0, duration: period)
        node.runAction(SCNAction.repeatForever(rotation))
        
        // Add rings for Saturn
        if data.hasRings {
            addRings(to: node, innerRadius: CGFloat(data.radius * 2.2), outerRadius: CGFloat(data.radius * 4.0))
        }
        
        return node
    }
    
    // MARK: - Rings
    
    private static func addRings(to node: SCNNode, innerRadius: CGFloat, outerRadius: CGFloat) {
        // Create ring geometry using a tube (cylinder with inner radius)
        let ringGeometry = SCNTube(innerRadius: innerRadius, outerRadius: outerRadius, height: 0.1)
        
        let ringMaterial = SCNMaterial()
        ringMaterial.diffuse.contents = ImageLoader.color(white: 0.8, alpha: 0.7)
        ringMaterial.isDoubleSided = true
        ringMaterial.lightingModel = .physicallyBased
        
        if let ringTexture = loadTexture(named: "saturn_rings_16k") {
            ringMaterial.diffuse.contents = ringTexture
            ringMaterial.transparent.contents = ringTexture
            ringMaterial.transparencyMode = .dualLayer
        }
        
        ringGeometry.materials = [ringMaterial, ringMaterial, ringMaterial]
        
        let ringNode = SCNNode(geometry: ringGeometry)
        ringNode.name = "\(node.name ?? "Planet")_Rings"
        ringNode.eulerAngles.x = .pi / 2 // Rotate to horizontal
        node.addChildNode(ringNode)
    }
    
    // MARK: - Helpers
    
    private static func defaultColor(for planet: String) -> CrossPlatformColor {
        switch planet {
        case "Sun": return ImageLoader.orange
        case "Mercury": return ImageLoader.gray
        case "Venus": return ImageLoader.color(red: 0.9, green: 0.8, blue: 0.6, alpha: 1)
        case "Earth": return ImageLoader.blue
        case "Mars": return ImageLoader.color(red: 0.8, green: 0.3, blue: 0.2, alpha: 1)
        case "Jupiter": return ImageLoader.color(red: 0.8, green: 0.7, blue: 0.6, alpha: 1)
        case "Saturn": return ImageLoader.color(red: 0.9, green: 0.8, blue: 0.6, alpha: 1)
        case "Uranus": return ImageLoader.color(red: 0.6, green: 0.8, blue: 0.9, alpha: 1)
        case "Neptune": return ImageLoader.color(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        default: return ImageLoader.white
        }
    }
    
    private static func loadTexture(named name: String) -> CrossPlatformImage? {
        return ImageLoader.loadImage(named: name)
    }
}

// MARK: - Embedded ImageLoader
// Embedded here to resolve linking issues during initial verification.
// Ideally should be in Sources/CrossPlatform/ImageLoader.swift and linked to the target.

#if os(macOS)
import AppKit
public typealias CrossPlatformImage = NSImage
public typealias CrossPlatformColor = NSColor
#else
import UIKit
public typealias CrossPlatformImage = UIImage
public typealias CrossPlatformColor = UIColor
#endif

/// Cross-platform image and color utilities
public class ImageLoader {

    /// Load an image from the bundle
    public static func loadImage(named name: String) -> CrossPlatformImage? {
        let bundle = Bundle(for: ImageLoader.self)
        
        // Debug: Print bundle path for troubleshooting
        #if DEBUG
        print("🔍 ImageLoader: Searching for '\(name)' in bundle: \(bundle.bundlePath)")
        #endif

        // Try bundle resource path directly (this is where Copy Bundle Resources puts files)
        if let bundlePath = bundle.path(forResource: name, ofType: "jpg") {
            #if DEBUG
            print("✅ ImageLoader: Found '\(name).jpg' at \(bundlePath)")
            #endif
            #if os(macOS)
            return NSImage(contentsOfFile: bundlePath)
            #else
            return UIImage(contentsOfFile: bundlePath)
            #endif
        }
        if let bundlePath = bundle.path(forResource: name, ofType: "png") {
            #if DEBUG
            print("✅ ImageLoader: Found '\(name).png' at \(bundlePath)")
            #endif
            #if os(macOS)
            return NSImage(contentsOfFile: bundlePath)
            #else
            return UIImage(contentsOfFile: bundlePath)
            #endif
        }

        // Fallback: Check bundle's Resources directory directly
        if let resourcePath = bundle.resourcePath {
            let directPaths = [
                "\(resourcePath)/\(name).jpg",
                "\(resourcePath)/\(name).png"
            ]
            for path in directPaths {
                if FileManager.default.fileExists(atPath: path) {
                    #if DEBUG
                    print("✅ ImageLoader: Found at direct path: \(path)")
                    #endif
                    #if os(macOS)
                    return NSImage(contentsOfFile: path)
                    #else
                    return UIImage(contentsOfFile: path)
                    #endif
                }
            }
        }

        // Log missing texture for debugging
        #if DEBUG
        print("❌ ImageLoader: Image '\(name)' NOT FOUND in bundle")
        if let resourcePath = bundle.resourcePath {
            print("   Bundle resources path: \(resourcePath)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                print("   Contents: \(contents.prefix(10))")
            }
        }
        #endif

        return nil
    }

    /// Create a color from RGB values
    public static func color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> CrossPlatformColor {
        #if os(macOS)
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
        #else
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        #endif
    }

    /// Create a color from white value
    public static func color(white: CGFloat, alpha: CGFloat = 1.0) -> CrossPlatformColor {
        #if os(macOS)
        return NSColor(white: white, alpha: alpha)
        #else
        return UIColor(white: white, alpha: alpha)
        #endif
    }

    /// Predefined colors
    public static var orange: CrossPlatformColor {
        #if os(macOS)
        return .orange
        #else
        return .orange
        #endif
    }

    public static var gray: CrossPlatformColor {
        #if os(macOS)
        return .gray
        #else
        return .gray
        #endif
    }

    public static var blue: CrossPlatformColor {
        #if os(macOS)
        return .blue
        #else
        return .blue
        #endif
    }

    public static var white: CrossPlatformColor {
        #if os(macOS)
        return .white
        #else
        return .white
        #endif
    }

    public static var black: CrossPlatformColor {
        #if os(macOS)
        return .black
        #else
        return .black
        #endif
    }
}
