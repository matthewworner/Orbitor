import SceneKit

/// Efficient satellite renderer using optimized SceneKit techniques and high-fidelity procedural generation
class SatelliteRenderer {

    // MARK: - Properties

    private weak var scene: SCNScene?
    private var satelliteContainer: SCNNode?
    private var satelliteNodes: [SCNNode] = []

    // We only want a handful of visible "toy" sats. The dense swarm is Metal-based.
    private let maxSatellites = 50
    private var currentSatelliteCount = 0

    // Swarm particle system for dense firefly effect
    private var swarmParticleSystem: SCNParticleSystem?
    private let maxSwarmParticles = 10000

    // Geometry mode
    enum GeometryMode {
        case geometry, point
    }
    private var geometryMode: GeometryMode = .geometry

    // Single template for the toy sat shape
    private var toyTemplate: SCNNode?
    private var pointTemplate: SCNNode?

    // Shared Materials (Lazy loaded for performance)
    private lazy var goldFoilMaterial: SCNMaterial = {
        let m = SCNMaterial()
        // Warm gold foil — catches sunlight beautifully
        m.diffuse.contents = NSColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        m.metalness.contents = 1.0
        m.roughness.contents = 0.2
        m.lightingModel = .physicallyBased
        // Add emission for visibility
        m.emission.contents = NSColor(red: 0.3, green: 0.25, blue: 0.1, alpha: 1.0)
        m.emission.intensity = 0.5
        return m
    }()
    
    private lazy var silverMaterial: SCNMaterial = {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.92, alpha: 1.0)
        m.metalness.contents = 1.0
        m.roughness.contents = 0.15
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.3, alpha: 1.0)
        m.emission.intensity = 0.3
        return m
    }()
    
    private lazy var solarPanelMaterial: SCNMaterial = {
        let m = SCNMaterial()
        // Deep blue with subtle iridescence — looks realistic but visible
        m.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
        // Stronger emission so panels are visible even in shadow
        m.emission.contents = NSColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)
        m.emission.intensity = 0.6
        m.metalness.contents = 0.4
        m.roughness.contents = 0.25
        m.lightingModel = .physicallyBased
        return m
    }()
    
    private lazy var whitePaintMaterial: SCNMaterial = {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.98, alpha: 1.0)
        m.metalness.contents = 0.0
        m.roughness.contents = 0.6
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.3, alpha: 1.0)
        m.emission.intensity = 0.3
        return m
    }()
    
    // Debug logging
    private func logToFile(_ message: String) {
        let logPath = NSHomeDirectory() + "/Desktop/screensaver_debug.log"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        // Simple append
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write("[\(timestamp)] \(message)\n".data(using: .utf8)!)
            handle.closeFile()
        }
    }
    
    // MARK: - Safe API Stubs (Restored)
    
    enum Quality {
        case low, medium, high, ultra
    }
    
    func setQualityLevel(_ level: Quality) {
        // No-op in this renderer
    }
    
    func addMotionTrails(positions: [SIMD3<Float>], velocities: [SIMD3<Float>], earthOffset: SIMD3<Float>) {
        // No-op
    }

    // MARK: - Initialization

    init(scene: SCNScene) {
        self.scene = scene
        setupContainer()
        setupToyTemplate()
    }

    private func setupContainer() {
        satelliteContainer = SCNNode()
        satelliteContainer?.name = "Satellites"
        scene?.rootNode.addChildNode(satelliteContainer!)
    }
    
    private func setupToyTemplate() {
        toyTemplate = generateToyTemplate()
    }
    
    // MARK: - Satellite Management

    func updateSatellites(positions: [SIMD3<Float>],
                          colors: [SIMD4<Float>],
                          velocities: [SIMD3<Float>],
                          names: [String],
                          earthOffset: SIMD3<Float>) {

        // Early return if data is invalid
        guard positions.count == colors.count else { return }

        currentSatelliteCount = min(positions.count, maxSatellites)

        // Ensure we have enough nodes
        ensureNodeCapacity(currentSatelliteCount)

        // Update existing nodes
        for i in 0..<currentSatelliteCount {
            let node = satelliteNodes[i]
            let position = positions[i]

            // Apply Earth offset
            node.position = SCNVector3(
                x: CGFloat(position.x + earthOffset.x),
                y: CGFloat(position.y + earthOffset.y),
                z: CGFloat(position.z + earthOffset.z)
            )

            // Make visible
            node.isHidden = false
            
            // Random slow rotation for liveliness
            node.eulerAngles.x += 0.001
            node.eulerAngles.y += 0.001
        }

        // Hide unused nodes
        for i in currentSatelliteCount..<satelliteNodes.count {
            satelliteNodes[i].isHidden = true
        }
    }

    private func ensureNodeCapacity(_ capacity: Int) {
        while satelliteNodes.count < capacity {
            guard let template = toyTemplate else { continue }
            let satelliteNode = template.clone()
            
            satelliteNode.isHidden = true
            
            // Scale jitter for variety (±10%)
            let randomScale = CGFloat.random(in: 0.9...1.1)
            satelliteNode.scale = SCNVector3(
                satelliteNode.scale.x * randomScale,
                satelliteNode.scale.y * randomScale,
                satelliteNode.scale.z * randomScale
            )
            
            // Random initial rotation
            satelliteNode.eulerAngles = SCNVector3(
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2))
            )
            
            satelliteContainer?.addChildNode(satelliteNode)
            satelliteNodes.append(satelliteNode)
        }
    }
    
    // MARK: - Procedural Generation (Clean Version)
    
    private func generateToyTemplate() -> SCNNode {
        let node = SCNNode()
        // Increased scale for better visibility in full-screen
        node.scale = SCNVector3(0.15, 0.15, 0.15)

        let body = SCNBox(width: 1.0, height: 0.6, length: 0.6, chamferRadius: 0.05)
        body.materials = [goldFoilMaterial]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)

        // Main solar wing
        let mainWing = createPanelGeometry(width: 4.0, height: 0.5)
        let mainWingNode = SCNNode(geometry: mainWing)
        mainWingNode.position = SCNVector3(0, 1.8, 0)
        node.addChildNode(mainWingNode)

        // Crossbar wing
        let crossWing = createPanelGeometry(width: 2.0, height: 0.4)
        let crossWingNode = SCNNode(geometry: crossWing)
        crossWingNode.position = SCNVector3(0, -1.2, 0)
        crossWingNode.eulerAngles.z = .pi / 2
        node.addChildNode(crossWingNode)

        // Tiny antenna/dish hint
        let dish = SCNCone(topRadius: 0.4, bottomRadius: 0.05, height: 0.3)
        dish.materials = [whitePaintMaterial]
        let dishNode = SCNNode(geometry: dish)
        dishNode.position = SCNVector3(0.6, 0.2, 0.35)
        dishNode.eulerAngles.x = .pi / 6
        node.addChildNode(dishNode)

        return node
    }
    
    private func createPanelGeometry(width: CGFloat, height: CGFloat) -> SCNGeometry {
        let box = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0.01)
        box.materials = [solarPanelMaterial]
        return box
    }
}