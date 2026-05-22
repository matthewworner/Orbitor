import SceneKit
import simd

/// Manages satellite orbital simulation for the Kubrick screensaver
/// Handles satellite instance creation, position updates, and scene node management
public final class SatelliteOrbitSimulator {
    
    private let scene: SCNScene
    private var satellites: [SatelliteInstance] = []
    private var satelliteNodes: [String: SCNNode] = [:]
    private var orbitalRings: [SCNNode] = []
    
    // Animation state
    private var animationTime: Double = 0
    private var lastUpdateTime: TimeInterval = 0
    
    public init(scene: SCNScene) {
        self.scene = scene
    }
    
    // MARK: - Zone Configuration
    
    // Uses shared OrbitalZoneDefinition from OrbitalModels
    private var zones: [OrbitalZoneDefinition] { OrbitalZoneDefinition.allZones }
    
    // MARK: - Satellite Creation
    
    /// Create satellites distributed across orbital zones
    public func createSatellites() {
        for (zoneIndex, zone) in zones.enumerated() {
            // Create orbital ring
            createOrbitalRing(radius: CGFloat(zone.sceneRadius), color: zone.color)
            
            // Create satellites
            for i in 0..<zone.defaultCount {
                let satId = "sat-\(zoneIndex)-\(i)"
                let startAngle = Float(i) / Float(zone.defaultCount) * .pi * 2
                let inclination = Float.random(in: -0.5...0.5)
                
                // Pick satellite type based on zone
                let satType: SatelliteBuilder.SatelliteType
                let types = SatelliteBuilder.SatelliteType.allCases
                switch zoneIndex {
                case 0: satType = types.randomElement() ?? .rocket
                case 1: satType = Bool.random() ? .cubeSat : .rocket
                default: satType = Bool.random() ? .starlink : .cubeSat
                }
                
                let sat = SatelliteInstance(
                    id: satId,
                    orbitAngle: startAngle,
                    orbitSpeed: zone.orbitalSpeed * Float.random(in: 0.9...1.1),
                    orbitRadius: zone.sceneRadius * Float.random(in: 0.98...1.02),
                    orbitInclination: inclination,
                    scale: Float.random(in: 0.8...1.2),
                    rotationSpeed: SIMD3<Float>(
                        Float.random(in: -0.5...0.5),
                        Float.random(in: -0.5...0.5),
                        Float.random(in: -0.5...0.5)
                    ),
                    type: satType,
                    color: zone.color
                )
                satellites.append(sat)
                
                // Create scene node from template
                let node = satType.template.clone()
                node.name = satId
                satelliteNodes[satId] = node
                scene.rootNode.addChildNode(node)
            }
        }
    }
    
    // MARK: - Orbital Rings
    
    private func createOrbitalRing(radius: CGFloat, color: NSColor) {
        let segments = 64
        var vertices: [SCNVector3] = []
        
        for i in 0...segments {
            let angle = CGFloat(i) / CGFloat(segments) * .pi * 2
            vertices.append(SCNVector3(radius * cos(angle), 0, radius * sin(angle)))
        }
        
        var indices: [Int32] = []
        for i in 0..<segments {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let ringGeo = SCNGeometry(sources: [source], elements: [element])
        
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = color.withAlphaComponent(0.15)
        ringMat.emission.contents = color
        ringMat.emission.intensity = 0.6
        ringMat.lightingModel = .constant
        ringGeo.materials = [ringMat]
        
        let ring = SCNNode(geometry: ringGeo)
        ring.name = "orbital-ring"
        scene.rootNode.addChildNode(ring)
        orbitalRings.append(ring)
    }
    
    // MARK: - Animation
    
    /// Update all satellite positions based on orbital mechanics
    /// Call this once per frame
    public func update(deltaTime: TimeInterval) -> Double {
        animationTime += deltaTime
        
        // Update satellites
        for i in 0..<satellites.count {
            var sat = satellites[i]
            sat.updatePosition()
            
            if let node = satelliteNodes[sat.id] {
                node.position = SCNVector3(sat.position.x, sat.position.y, sat.position.z)
                
                // Rotate satellite
                node.eulerAngles.x += CGFloat(sat.rotationSpeed.x * 0.01)
                node.eulerAngles.y += CGFloat(sat.rotationSpeed.y * 0.01)
                node.eulerAngles.z += CGFloat(sat.rotationSpeed.z * 0.01)
            }
            
            satellites[i] = sat
        }
        
        // Pulse orbital rings
        let pulse = (sin(animationTime * 1.2) + 1) / 2 * 0.2 + 0.6
        for ring in orbitalRings {
            ring.geometry?.firstMaterial?.emission.intensity = CGFloat(pulse)
        }
        
        return animationTime
    }
    
    // MARK: - Accessors
    
    public var satelliteCount: Int { satellites.count }
    
    public func getSatellites() -> [SatelliteInstance] { satellites }
    
    public func getSceneNode(for satId: String) -> SCNNode? { satelliteNodes[satId] }
}