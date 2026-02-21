import SceneKit

/// Efficient satellite renderer using optimized SceneKit techniques and data-driven visual classification
class SatelliteRenderer {

    // MARK: - Properties

    private weak var scene: SCNScene?
    private var satelliteContainer: SCNNode?
    private var trailContainer: SCNNode?
    private var satelliteNodes: [SCNNode] = []
    private var trailNodes: [SCNNode] = []

    // SceneKit renders hero/detail satellites, Metal handles the swarm
    private let maxSatellites = 50
    private var currentSatelliteCount = 0

    // Templates for different satellite types
    private var activeSatelliteTemplate: SCNNode?
    private var debrisTemplate: SCNNode?
    private var starlinkTemplate: SCNNode?
    private var heroModels: [String: SCNNode] = [:]
    
    // Trail system
    private var trailPositions: [[SIMD3<Float>]] = []  // History for each satellite
    private let trailHistoryLength = 10

    // Shared Materials (Lazy loaded for performance)
    private lazy var goldFoilMaterial: SCNMaterial = {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        m.metalness.contents = 1.0
        m.roughness.contents = 0.2
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(red: 0.3, green: 0.25, blue: 0.1, alpha: 1.0)
        m.emission.intensity = 0.5
        return m
    }()
    
    private lazy var solarPanelMaterial: SCNMaterial = {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
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
    
    private lazy var debrisMaterial: SCNMaterial = {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.3, alpha: 1.0)
        m.metalness.contents = 0.8
        m.roughness.contents = 0.7
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.05, alpha: 1.0)
        m.emission.intensity = 0.1
        return m
    }()
    
    // MARK: - Quality Settings
    
    enum Quality {
        case low, medium, high
    }
    
    private var qualityLevel: Quality = .high
    
    func setQualityLevel(_ level: Quality) {
        qualityLevel = level
    }

    // MARK: - Initialization

    init(scene: SCNScene) {
        self.scene = scene
        setupContainers()
        setupTemplates()
        loadHeroModels()
    }

    private func setupContainers() {
        satelliteContainer = SCNNode()
        satelliteContainer?.name = "Satellites"
        scene?.rootNode.addChildNode(satelliteContainer!)
        
        trailContainer = SCNNode()
        trailContainer?.name = "Trails"
        scene?.rootNode.addChildNode(trailContainer!)
    }
    
    private func setupTemplates() {
        activeSatelliteTemplate = generateActiveSatelliteTemplate()
        debrisTemplate = generateDebrisTemplate()
        starlinkTemplate = generateStarlinkTemplate()
    }
    
    private func loadHeroModels() {
        // Load NASA 3D models for notable satellites
        // Using .glb format (glTF binary) which SceneKit supports
        let heroAssets: [(filename: String, names: [String])] = [
            ("hubble", ["HST", "HUBBLE", "1990-037B"]),
            ("tess", ["TESS", "TESS SATELLITE"]),
            ("tdrs", ["TDRS", "TRACKING DATA RELAY"]),
            ("juno", ["JUNO"])
        ]
        
        for asset in heroAssets {
            if let model = loadModel(named: asset.filename) {
                // Register under all alternate names
                for name in asset.names {
                    heroModels[name] = model
                }
            }
        }
        
        // ISS placeholder - create from procedural geometry if no model file
        if heroModels["ISS"] == nil {
            heroModels["ISS (ZARYA)"] = createISSPlaceholder()
        }
        
        // CubeSat placeholder
        heroModels["CUBESAT"] = createCubeSatPlaceholder()
    }
    
    private func loadModel(named name: String) -> SCNNode? {
        let bundle = Bundle(for: type(of: self))
        
        // Try .glb first (glTF binary)
        if let url = bundle.url(forResource: name, withExtension: "glb", subdirectory: "Models") {
            if let scene = try? SCNScene(url: url) {
                let node = scene.rootNode.clone()
                // Scale down for satellite rendering
                node.scale = SCNVector3(0.02, 0.02, 0.02)
                return node
            }
        }
        
        // Try .usdz
        if let url = bundle.url(forResource: name, withExtension: "usdz", subdirectory: "Models") {
            if let scene = try? SCNScene(url: url) {
                return scene.rootNode.clone()
            }
        }
        
        // Try .scn
        if let url = bundle.url(forResource: name, withExtension: "scn", subdirectory: "Models") {
            if let scene = try? SCNScene(url: url) {
                return scene.rootNode.clone()
            }
        }
        
        return nil
    }
    
    private func createISSPlaceholder() -> SCNNode {
        // Simplified ISS model - large structure with solar arrays
        let node = SCNNode()
        node.scale = SCNVector3(0.05, 0.05, 0.05)
        
        // Main truss
        let truss = SCNBox(width: 4.0, height: 0.2, length: 0.2, chamferRadius: 0.02)
        truss.materials = [whitePaintMaterial]
        let trussNode = SCNNode(geometry: truss)
        node.addChildNode(trussNode)
        
        // Habitat modules
        let module = SCNCylinder(radius: 0.3, height: 1.0)
        module.materials = [whitePaintMaterial]
        let moduleNode = SCNNode(geometry: module)
        moduleNode.eulerAngles.z = .pi / 2
        moduleNode.position = SCNVector3(0, 0.4, 0)
        node.addChildNode(moduleNode)
        
        // Solar arrays (4 pairs)
        for i in 0..<4 {
            let x = CGFloat(i - 1) * 1.2 - 0.3
            for sign in [-1.0, 1.0] {
                let panel = SCNBox(width: 0.8, height: 0.02, length: 2.0, chamferRadius: 0.01)
                panel.materials = [solarPanelMaterial]
                let panelNode = SCNNode(geometry: panel)
                panelNode.position = SCNVector3(x, CGFloat(sign) * 1.2, 0)
                node.addChildNode(panelNode)
            }
        }
        
        return node
    }
    
    private func createCubeSatPlaceholder() -> SCNNode {
        // Standard 1U CubeSat (10cm x 10cm x 10cm)
        let node = SCNNode()
        node.scale = SCNVector3(0.15, 0.15, 0.15)
        
        let body = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        body.materials = [debrisMaterial]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)
        
        // Small solar panel
        let panel = SCNBox(width: 1.2, height: 0.02, length: 0.8, chamferRadius: 0.01)
        panel.materials = [solarPanelMaterial]
        let panelNode = SCNNode(geometry: panel)
        panelNode.position = SCNVector3(0, 0.6, 0)
        node.addChildNode(panelNode)
        
        return node
    }

    // MARK: - Satellite Management

    func updateSatellites(positions: [SIMD3<Float>],
                          colors: [SIMD4<Float>],
                          velocities: [SIMD3<Float>],
                          names: [String],
                          classifications: [SatelliteClass],
                          ages: [Double],
                          earthOffset: SIMD3<Float>) {

        guard positions.count == colors.count else { return }

        currentSatelliteCount = min(positions.count, maxSatellites)
        
        // Clamp arrays to same count once
        let validClassifications: [SatelliteClass]
        let validAges: [Double]
        let validVelocities: [SIMD3<Float>]
        
        if classifications.count >= currentSatelliteCount {
            validClassifications = classifications
        } else {
            validClassifications = classifications + Array(repeating: .activeSatellite, count: currentSatelliteCount - classifications.count)
        }
        
        if ages.count >= currentSatelliteCount {
            validAges = ages
        } else {
            validAges = ages + Array(repeating: 5.0, count: currentSatelliteCount - ages.count)
        }
        
        if velocities.count >= currentSatelliteCount {
            validVelocities = velocities
        } else {
            validVelocities = velocities + Array(repeating: SIMD3<Float>(0, 0, 0), count: currentSatelliteCount - velocities.count)
        }
        
        // Initialize trail history if needed
        while trailPositions.count < currentSatelliteCount {
            trailPositions.append([])
        }

        ensureNodeCapacity(currentSatelliteCount)

        for i in 0..<currentSatelliteCount {
            let node = satelliteNodes[i]
            let position = positions[i]
            let classification = validClassifications[i]
            let age = validAges[i]
            let velocity = validVelocities[i]

            // Apply Earth offset
            node.position = SCNVector3(
                x: CGFloat(position.x + earthOffset.x),
                y: CGFloat(position.y + earthOffset.y),
                z: CGFloat(position.z + earthOffset.z)
            )

            node.isHidden = false
            
            // Apply age-based material degradation
            applyMaterialAging(to: node, age: age, classification: classification)
            
            // Apply velocity-based thermal glow
            applyThermalGlow(to: node, velocity: velocity)
            
            // Update trail history
            updateTrailHistory(for: i, position: position, earthOffset: earthOffset)
        }

        // Hide unused nodes
        for i in currentSatelliteCount..<satelliteNodes.count {
            satelliteNodes[i].isHidden = true
            if i < trailNodes.count {
                trailNodes[i].isHidden = true
            }
        }
    }
    
    // Legacy API for compatibility
    func updateSatellites(positions: [SIMD3<Float>],
                          colors: [SIMD4<Float>],
                          velocities: [SIMD3<Float>],
                          names: [String],
                          earthOffset: SIMD3<Float>) {
        // Provide default classifications
        let defaultClassifications = positions.map { _ in SatelliteClass.activeSatellite }
        let defaultAges = positions.map { _ in 5.0 }
        
        updateSatellites(
            positions: positions,
            colors: colors,
            velocities: velocities,
            names: names,
            classifications: defaultClassifications,
            ages: defaultAges,
            earthOffset: earthOffset
        )
    }

    private func ensureNodeCapacity(_ capacity: Int) {
        while satelliteNodes.count < capacity {
            // Create node with default template
            let node = activeSatelliteTemplate?.clone() ?? SCNNode()
            node.isHidden = true
            
            // Random variation
            let randomScale = CGFloat.random(in: 0.9...1.1)
            node.scale = SCNVector3(
                node.scale.x * randomScale,
                node.scale.y * randomScale,
                node.scale.z * randomScale
            )
            
            node.eulerAngles = SCNVector3(
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2))
            )
            
            satelliteContainer?.addChildNode(node)
            satelliteNodes.append(node)
            
            // Create corresponding trail node
            let trailNode = createTrailNode()
            trailContainer?.addChildNode(trailNode)
            trailNodes.append(trailNode)
        }
    }
    
    // MARK: - Motion Trails
    
    func addMotionTrails(positions: [SIMD3<Float>], velocities: [SIMD3<Float>], earthOffset: SIMD3<Float>) {
        // Implemented via updateTrailHistory - called during updateSatellites
    }
    
    private func updateTrailHistory(for index: Int, position: SIMD3<Float>, earthOffset: SIMD3<Float>) {
        guard index < trailPositions.count else { return }
        
        let offsetPosition = SIMD3<Float>(
            position.x + earthOffset.x,
            position.y + earthOffset.y,
            position.z + earthOffset.z
        )
        
        // Add current position
        trailPositions[index].append(offsetPosition)
        
        // Keep only recent history
        if trailPositions[index].count > trailHistoryLength {
            trailPositions[index].removeFirst()
        }
        
        // Update trail geometry
        if index < trailNodes.count {
            updateTrailNode(trailNodes[index], positions: trailPositions[index])
        }
    }
    
    private func createTrailNode() -> SCNNode {
        let node = SCNNode()
        node.name = "Trail"
        return node
    }
    
    private func updateTrailNode(_ node: SCNNode, positions: [SIMD3<Float>]) {
        // Clear old geometry by replacing with empty
        node.geometry = nil
        
        guard positions.count >= 2 else { return }
        
        // Create line geometry with fading colors
        var vertices: [SCNVector3] = []
        
        for pos in positions {
            vertices.append(SCNVector3(pos.x, pos.y, pos.z))
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        
        var indices: [Int32] = []
        for i in 0..<(vertices.count - 1) {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(white: 1.0, alpha: 0.5)
        material.emission.contents = NSColor.white
        material.emission.intensity = 0.3
        material.lightingModel = .constant
        material.transparencyMode = .default
        geometry.materials = [material]
        
        node.geometry = geometry
    }

    // MARK: - Material Effects
    
    private func applyMaterialAging(to node: SCNNode, age: Double, classification: SatelliteClass) {
        // Calculate roughness and emission based on age
        let roughness: CGFloat
        let emissionIntensity: CGFloat
        
        if age < 5 {
            // New satellite: bright, smooth
            roughness = 0.2
            emissionIntensity = 0.6
        } else if age < 15 {
            // Moderate age
            roughness = 0.5
            emissionIntensity = 0.3
        } else {
            // Old satellite: weathered
            roughness = 0.8
            emissionIntensity = 0.1
        }
        
        // Apply to all materials in the node
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                for material in geometry.materials {
                    material.roughness.contents = roughness
                    material.emission.intensity = emissionIntensity
                }
            }
        }
    }
    
    private func applyThermalGlow(to node: SCNNode, velocity: SIMD3<Float>) {
        let speed = simd_length(velocity)
        let normalized = min(speed / 8.0, 1.0)  // 8 km/s = max LEO speed
        
        // Warm glow for fast satellites, cool for slow
        let glowColor = NSColor(
            red: CGFloat(0.2 + normalized * 0.3),
            green: CGFloat(0.15),
            blue: CGFloat(0.3 - normalized * 0.2),
            alpha: 1.0
        )
        
        // Apply subtle emission tint
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                for material in geometry.materials {
                    if material.emission.intensity > 0.3 {
                        material.emission.contents = glowColor
                    }
                }
            }
        }
    }

    // MARK: - Template Generation
    
    private func generateActiveSatelliteTemplate() -> SCNNode {
        let node = SCNNode()
        node.scale = SCNVector3(0.15, 0.15, 0.15)

        let body = SCNBox(width: 1.0, height: 0.6, length: 0.6, chamferRadius: 0.05)
        body.materials = [goldFoilMaterial]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)

        let mainWing = createPanelGeometry(width: 4.0, height: 0.5)
        let mainWingNode = SCNNode(geometry: mainWing)
        mainWingNode.position = SCNVector3(0, 1.8, 0)
        node.addChildNode(mainWingNode)

        let crossWing = createPanelGeometry(width: 2.0, height: 0.4)
        let crossWingNode = SCNNode(geometry: crossWing)
        crossWingNode.position = SCNVector3(0, -1.2, 0)
        crossWingNode.eulerAngles.z = .pi / 2
        node.addChildNode(crossWingNode)

        let dish = SCNCone(topRadius: 0.4, bottomRadius: 0.05, height: 0.3)
        dish.materials = [whitePaintMaterial]
        let dishNode = SCNNode(geometry: dish)
        dishNode.position = SCNVector3(0.6, 0.2, 0.35)
        dishNode.eulerAngles.x = .pi / 6
        node.addChildNode(dishNode)

        return node
    }
    
    private func generateDebrisTemplate() -> SCNNode {
        let node = SCNNode()
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Irregular chunk - use multiple small boxes
        for _ in 0..<3 {
            let chunk = SCNBox(
                width: CGFloat.random(in: 0.3...1.0),
                height: CGFloat.random(in: 0.2...0.8),
                length: CGFloat.random(in: 0.2...0.6),
                chamferRadius: 0.05
            )
            chunk.materials = [debrisMaterial]
            let chunkNode = SCNNode(geometry: chunk)
            chunkNode.position = SCNVector3(
                CGFloat.random(in: -0.3...0.3),
                CGFloat.random(in: -0.3...0.3),
                CGFloat.random(in: -0.3...0.3)
            )
            chunkNode.eulerAngles = SCNVector3(
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2)),
                CGFloat.random(in: 0...(.pi * 2))
            )
            node.addChildNode(chunkNode)
        }
        
        return node
    }
    
    private func generateStarlinkTemplate() -> SCNNode {
        let node = SCNNode()
        node.scale = SCNVector3(0.08, 0.08, 0.08)
        
        // Starlink "pizza box" design - flat rectangular body
        let body = SCNBox(width: 2.0, height: 0.1, length: 1.0, chamferRadius: 0.02)
        body.materials = [whitePaintMaterial]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)
        
        // Single large solar panel
        let panel = SCNBox(width: 3.0, height: 0.02, length: 1.0, chamferRadius: 0.01)
        panel.materials = [solarPanelMaterial]
        let panelNode = SCNNode(geometry: panel)
        panelNode.position = SCNVector3(0, 0.5, 0)
        node.addChildNode(panelNode)
        
        return node
    }
    
    private func createPanelGeometry(width: CGFloat, height: CGFloat) -> SCNGeometry {
        let box = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0.01)
        box.materials = [solarPanelMaterial]
        return box
    }
}