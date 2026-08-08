import SceneKit

/// Efficient satellite renderer using optimized SceneKit techniques and data-driven visual classification
class SatelliteRenderer {

    // MARK: - Properties

    private weak var scene: SCNScene?
    private var satelliteContainer: SCNNode?
    private var trailContainer: SCNNode?
    private var satelliteNodes: [SCNNode] = []
    private var trailNodes: [SCNNode] = []

    // ponytail: was 50, a leftover from when Metal owned the full swarm and SceneKit only did
    // close-up hero satellites. Metal's disabled (deprecated currentRenderCommandEncoder), so
    // SceneKit now owns the whole swarm — match QualityLevel's own documented "SceneKit safe
    // limit" (NatureVsNoiseView.swift) instead of a stale hero-only number. Callers already pass
    // at most qualityLevel.maxSatellites; this is just the renderer's own ceiling.
    private let maxSatellites = 500 // ponytail: "SceneKit acceptable" tier
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
                enhanceMaterials(node: node)
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
    
    /// Enhance loaded materials for realistic SceneKit PBR
    private func enhanceMaterials(node: SCNNode) {
        if let geometry = node.geometry {
            for material in geometry.materials {
                // Ensure physical lighting
                if material.lightingModel != .physicallyBased {
                    material.lightingModel = .physicallyBased
                }
                
                // Boost metalness to ensure it reflects the HDRI environment
                // Only if it doesn't already have a strong map
                if let metalness = material.metalness.contents as? NSNumber, metalness.floatValue < 0.1 {
                    material.metalness.contents = 0.8
                } else if material.metalness.contents == nil {
                    material.metalness.contents = 0.9
                }
            }
        }
        
        for child in node.childNodes {
            enhanceMaterials(node: child)
        }
    }
    
    private func createISSPlaceholder() -> SCNNode {
        // Simplified ISS model - large structure with solar arrays
        let node = SCNNode()
        node.scale = SCNVector3(0.05, 0.05, 0.05)
        
        // Main truss
        let truss = SCNBox(width: 4.0, height: 0.2, length: 0.2, chamferRadius: 0.02)
        truss.materials = [MaterialFactory.whiteCached]
        let trussNode = SCNNode(geometry: truss)
        node.addChildNode(trussNode)
        
        // Habitat modules
        let module = SCNCylinder(radius: 0.3, height: 1.0)
        module.materials = [MaterialFactory.whiteCached]
        let moduleNode = SCNNode(geometry: module)
        moduleNode.eulerAngles.z = .pi / 2
        moduleNode.position = SCNVector3(0, 0.4, 0)
        node.addChildNode(moduleNode)
        
        // Solar arrays (4 pairs)
        for i in 0..<4 {
            let x = CGFloat(i - 1) * 1.2 - 0.3
            for sign in [-1.0, 1.0] {
                let panel = SCNBox(width: 0.8, height: 0.02, length: 2.0, chamferRadius: 0.01)
                panel.materials = [MaterialFactory.solarPanelCached]
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
        body.materials = [MaterialFactory.metalCached]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)
        
        // Small solar panel
        let panel = SCNBox(width: 1.2, height: 0.02, length: 0.8, chamferRadius: 0.01)
        panel.materials = [MaterialFactory.solarPanelCached]
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

            // Apply Earth offset
            node.position = SCNVector3(
                x: CGFloat(position.x + earthOffset.x),
                y: CGFloat(position.y + earthOffset.y),
                z: CGFloat(position.z + earthOffset.z)
            )

            node.isHidden = false

            // heroModels was loaded but never consulted — ISS/Hubble/TESS/TDRS always rendered as
            // the generic gold "active" template. Swap in the real model when the TLE name matches.
            let heroKey = i < names.count ? names[i] : ""
            if let heroTemplate = heroModels[heroKey] {
                applyHeroModel(to: node, template: heroTemplate, key: heroKey)
            } else {
                revertToActiveTemplateIfNeeded(node)
                // Apply age-based material degradation
                applyMaterialAging(to: node, age: age, classification: classification)
            }

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
        // ponytail: original rebuilt SCNGeometry + SCNMaterial every tick — that was the 23GB
        // leak class. Lazy fix: throttle geometry rebuilds to ~2 Hz (trail motion looks smooth at
        // that cadence) and share one static material across all trails.
        let now = CACurrentMediaTime()
        guard now - lastTrailRebuild >= trailRebuildInterval else { return }
        lastTrailRebuild = now

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
        geometry.materials = [SatelliteRenderer.trailMaterial]
        node.geometry = geometry
    }

    /// Shared trail material — created once, reused across every trail node.
    /// `updateTrailNode` used to allocate a new SCNMaterial per tick per visible satellite
    /// (~50 × updateHz per second). Hoisted here so all trails share one instance.
    private static let trailMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = NSColor(white: 1.0, alpha: 0.5)
        material.emission.contents = NSColor.white
        material.emission.intensity = 0.3
        material.lightingModel = .constant
        material.transparencyMode = .default
        return material
    }()

    /// Minimum interval between full trail geometry rebuilds. The trail position list still
    /// grows every tick; only the SCNGeometry reconstruction is throttled.
    private let trailRebuildInterval: CFTimeInterval = 0.5
    private var lastTrailRebuild: CFTimeInterval = 0

    // MARK: - Hero Model Swap

    /// Node pooling means the same SCNNode gets reused across ticks; only touch children when the
    /// hero identity actually changes, matching the trail/geometry churn throttling elsewhere.
    private func applyHeroModel(to node: SCNNode, template: SCNNode, key: String) {
        let marker = "hero:\(key)"
        guard node.name != marker else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
        node.scale = template.scale
        for child in template.childNodes {
            node.addChildNode(child.clone())
        }
        node.name = marker
    }

    private func revertToActiveTemplateIfNeeded(_ node: SCNNode) {
        guard node.name?.hasPrefix("hero:") == true, let template = activeSatelliteTemplate else { return }
        node.childNodes.forEach { $0.removeFromParentNode() }
        node.scale = template.scale
        for child in template.childNodes {
            node.addChildNode(child.clone())
        }
        node.name = nil
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
        
        // ponytail: recolor by classification.hudColor — the same single source of truth the
        // HUD legend reads from — instead of leaving every pooled node on its gold "active"
        // template color regardless of actual class.
        let classColor = classification.hudColor

        // Apply to all materials in the node
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                for material in geometry.materials {
                    // Only apply flat roughness if it's NOT a complex texture map
                    // Otherwise we destroy the detailed PBR textures from the GLB
                    if !(material.roughness.contents is NSImage) && !(material.roughness.contents is NSString) {
                        material.roughness.contents = roughness
                    }
                    
                    if material.emission.intensity > 0.05 { // Don't add emission to everything, only stuff that glows
                        material.emission.intensity = emissionIntensity
                    }

                    material.diffuse.contents = classColor
                }
            }
        }
    }
    
    // MARK: - Template Generation
    
    private func generateActiveSatelliteTemplate() -> SCNNode {
        let node = SCNNode()
        node.scale = SCNVector3(0.035, 0.035, 0.035) // ponytail: was 0.15→0.07

        let body = SCNBox(width: 1.0, height: 0.6, length: 0.6, chamferRadius: 0.05)
        body.materials = [MaterialFactory.goldCached]
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
        dish.materials = [MaterialFactory.whiteCached]
        let dishNode = SCNNode(geometry: dish)
        dishNode.position = SCNVector3(0.6, 0.2, 0.35)
        dishNode.eulerAngles.x = .pi / 6
        node.addChildNode(dishNode)

        return node
    }
    
    private func generateDebrisTemplate() -> SCNNode {
        let node = SCNNode()
        node.scale = SCNVector3(0.025, 0.025, 0.025) // ponytail: was 0.1→0.05
        
        // Irregular chunk - use multiple small boxes
        for _ in 0..<3 {
            let chunk = SCNBox(
                width: CGFloat.random(in: 0.3...1.0),
                height: CGFloat.random(in: 0.2...0.8),
                length: CGFloat.random(in: 0.2...0.6),
                chamferRadius: 0.05
            )
            chunk.materials = [MaterialFactory.metalCached]
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
        node.scale = SCNVector3(0.02, 0.02, 0.02) // ponytail: was 0.08→0.04
        
        // Starlink "pizza box" design - flat rectangular body
        let body = SCNBox(width: 2.0, height: 0.1, length: 1.0, chamferRadius: 0.02)
        body.materials = [MaterialFactory.whiteCached]
        let bodyNode = SCNNode(geometry: body)
        node.addChildNode(bodyNode)
        
        // Single large solar panel
        let panel = SCNBox(width: 3.0, height: 0.02, length: 1.0, chamferRadius: 0.01)
        panel.materials = [MaterialFactory.solarPanelCached]
        let panelNode = SCNNode(geometry: panel)
        panelNode.position = SCNVector3(0, 0.5, 0)
        node.addChildNode(panelNode)
        
        return node
    }
    
    private func createPanelGeometry(width: CGFloat, height: CGFloat) -> SCNGeometry {
        let box = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0.01)
        box.materials = [MaterialFactory.solarPanelCached]
        return box
    }
}