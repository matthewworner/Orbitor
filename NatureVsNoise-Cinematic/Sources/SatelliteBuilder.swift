import SceneKit
import simd

/// Builds procedural satellite geometry for the Kubrick screensaver
/// Encapsulates all satellite model creation logic
public final class SatelliteBuilder {
    
    private init() {} // Static factory
    
    // MARK: - Satellite Types
    
    public enum SatelliteType: CaseIterable {
        case iss           // Large structure with solar panels
        case starlink      // Flat panel design
        case cubeSat       // Small cube
        case rocket        // Cylinder body
        case debris        // Small irregular
        
        public var template: SCNNode {
            switch self {
            case .iss: return createISSTemplate()
            case .starlink: return createStarlinkTemplate()
            case .cubeSat: return createCubeSatTemplate()
            case .rocket: return createRocketTemplate()
            case .debris: return createDebrisTemplate()
            }
        }
    }
    
    // MARK: - Template Creation
    
    public static func createISSTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.15, 0.15, 0.15)
        
        // Truss structure
        let truss = SCNBox(width: 4.0, height: 0.15, length: 0.15, chamferRadius: 0.02)
        truss.materials = [MaterialFactory.solarPanelCached]
        root.addChildNode(SCNNode(geometry: truss))
        
        // Modules (cylinders)
        let module = SCNCylinder(radius: 0.25, height: 1.2)
        module.materials = [MaterialFactory.whiteCached]
        let moduleNode = SCNNode(geometry: module)
        moduleNode.eulerAngles.z = .pi / 2
        moduleNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(moduleNode)
        
        // Solar arrays (4 pairs)
        for i in 0..<4 {
            let x = CGFloat(i - 1) * 1.2 - 0.3
            for sign in [-1.0, 1.0] {
                let panel = SCNBox(width: 0.8, height: 0.02, length: 2.2, chamferRadius: 0.01)
                panel.materials = [MaterialFactory.solarPanelCached]
                let panelNode = SCNNode(geometry: panel)
                panelNode.position = SCNVector3(x, CGFloat(sign) * 1.4, 0)
                root.addChildNode(panelNode)
            }
        }
        
        // Radiators
        let radiator = SCNBox(width: 0.3, height: 0.02, length: 1.5, chamferRadius: 0.01)
        radiator.materials = [MaterialFactory.goldCached]
        let radNode = SCNNode(geometry: radiator)
        radNode.position = SCNVector3(0, 0.6, 0.8)
        radNode.eulerAngles.x = 0.3
        root.addChildNode(radNode)
        
        return root
    }
    
    public static func createStarlinkTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.2, 0.2, 0.2)
        
        // Body - flat square
        let body = SCNBox(width: 0.3, height: 0.08, length: 0.3, chamferRadius: 0.02)
        body.materials = [MaterialFactory.blackCached]
        root.addChildNode(SCNNode(geometry: body))
        
        // Two solar panels on each side
        for side in [-1.0, 1.0] {
            let panel = SCNBox(width: 0.6, height: 0.01, length: 0.3, chamferRadius: 0.01)
            panel.materials = [MaterialFactory.solarPanelCached]
            let panelNode = SCNNode(geometry: panel)
            panelNode.position = SCNVector3(0, 0, side * 0.45)
            root.addChildNode(panelNode)
        }
        
        return root
    }
    
    public static func createCubeSatTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.25, 0.25, 0.25)
        
        // Main body
        let body = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        body.materials = [MaterialFactory.whiteCached]
        root.addChildNode(SCNNode(geometry: body))
        
        // Antenna
        let antenna = SCNCylinder(radius: 0.05, height: 0.8)
        antenna.materials = [MaterialFactory.goldCached]
        let antNode = SCNNode(geometry: antenna)
        antNode.position = SCNVector3(0.3, 0.6, 0)
        root.addChildNode(antNode)
        
        return root
    }
    
    public static func createRocketTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.2, 0.2, 0.2)
        
        // Body cylinder
        let body = SCNCylinder(radius: 0.15, height: 1.0)
        body.materials = [MaterialFactory.whiteCached]
        let bodyNode = SCNNode(geometry: body)
        root.addChildNode(bodyNode)
        
        // Nose cone
        let nose = SCNCone(topRadius: 0, bottomRadius: 0.15, height: 0.4)
        nose.materials = [MaterialFactory.goldCached]
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 0.7, 0)
        root.addChildNode(noseNode)
        
        // Engine
        let engine = SCNCylinder(radius: 0.18, height: 0.15)
        engine.materials = [MaterialFactory.metalCached]
        let engineNode = SCNNode(geometry: engine)
        engineNode.position = SCNVector3(0, -0.55, 0)
        root.addChildNode(engineNode)
        
        return root
    }
    
    public static func createDebrisTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.15, 0.15, 0.15)
        
        // Irregular shape
        let debris = SCNBox(width: 0.4, height: 0.3, length: 0.5, chamferRadius: 0.1)
        debris.materials = [MaterialFactory.metalCached]
        root.addChildNode(SCNNode(geometry: debris))
        
        return root
    }
}

// MARK: - Satellite Instance

/// Represents a single satellite in the scene with orbital parameters
public struct SatelliteInstance {
    public let id: String
    public var position: SIMD3<Float>
    public var orbitAngle: Float
    public var orbitSpeed: Float
    public var orbitRadius: Float
    public var orbitInclination: Float
    public var scale: Float
    public var rotationSpeed: SIMD3<Float>
    public var type: SatelliteBuilder.SatelliteType
    public var color: NSColor
    
    public init(
        id: String,
        orbitAngle: Float,
        orbitSpeed: Float,
        orbitRadius: Float,
        orbitInclination: Float,
        scale: Float,
        rotationSpeed: SIMD3<Float>,
        type: SatelliteBuilder.SatelliteType,
        color: NSColor
    ) {
        self.id = id
        self.position = SIMD3<Float>(0, 0, 0)
        self.orbitAngle = orbitAngle
        self.orbitSpeed = orbitSpeed
        self.orbitRadius = orbitRadius
        self.orbitInclination = orbitInclination
        self.scale = scale
        self.rotationSpeed = rotationSpeed
        self.type = type
        self.color = color
    }
    
    /// Update position based on orbital angle
    public mutating func updatePosition() {
        orbitAngle += orbitSpeed
        
        let x = orbitRadius * cos(orbitAngle)
        let z = orbitRadius * sin(orbitAngle)
        let y = orbitRadius * sin(orbitInclination) * sin(orbitAngle)
        position = SIMD3<Float>(x, y, z)
    }
}