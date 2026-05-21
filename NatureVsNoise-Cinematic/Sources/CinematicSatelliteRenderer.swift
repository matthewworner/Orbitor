import SceneKit
import simd

/// Renders satellites in Kubrick-style cinematic mode
/// Focuses on light events, glints, and constellation patterns
class CinematicSatelliteRenderer {
    
    // MARK: - Properties
    
    private weak var scene: SCNScene?
    private var containerNode: SCNNode!
    private var glintContainer: SCNNode!
    private var constellationContainer: SCNNode!
    private var trailContainer: SCNNode!
    
    // Satellites
    private var satellites: [CinematicSatellite] = []
    private var satelliteNodes: [SCNNode] = []
    private var glintNodes: [SCNNode] = []
    private var constellationLines: [SCNNode] = []
    private var trailNodes: [SCNNode] = []
    
    // Constellation connections
    private var connections: [ConstellationConnection] = []
    
    // Current mode
    private var currentMode: KubrickMode = .glints
    
    // Configuration
    private var maxVisibleSatellites = 200
    private var constellationConnectionDistance: Float = 5.0
    private var glintProbability: Float = 0.05
    private var trailLength: Int = 10
    
    // Animation
    private var animationTime: Float = 0
    
    // MARK: - Initialization
    
    init(scene: SCNScene) {
        self.scene = scene
        setupContainers()
    }
    
    private func setupContainers() {
        containerNode = SCNNode()
        containerNode.name = "CinematicSatellites"
        scene?.rootNode.addChildNode(containerNode)
        
        glintContainer = SCNNode()
        glintContainer.name = "Glints"
        containerNode.addChildNode(glintContainer)
        
        constellationContainer = SCNNode()
        constellationContainer.name = "Constellations"
        containerNode.addChildNode(constellationContainer)
        
        trailContainer = SCNNode()
        trailContainer.name = "Trails"
        containerNode.addChildNode(trailContainer)
    }
    
    // MARK: - Upload
    
    func uploadSatellites(_ satellites: [CinematicSatellite]) {
        self.satellites = Array(satellites.prefix(maxVisibleSatellites))
        createSatelliteNodes()
        calculateConstellationConnections()
        
        #if DEBUG
        print("🎬 CinematicRenderer: Uploaded \(self.satellites.count) satellites")
        #endif
    }
    
    private func createSatelliteNodes() {
        // Clear existing
        containerNode.childNodes.forEach { $0.childNodes.forEach { $0.removeFromParentNode() } }
        satelliteNodes.removeAll()
        glintNodes.removeAll()
        constellationLines.removeAll()
        trailNodes.removeAll()
        
        for satellite in satellites {
            // Main satellite node
            let node = createSatelliteNode(for: satellite)
            containerNode.addChildNode(node)
            satelliteNodes.append(node)
            
            // Glint node (hidden by default)
            let glintNode = createGlintNode(for: satellite)
            glintContainer.addChildNode(glintNode)
            glintNodes.append(glintNode)
            
            // Trail node
            let trailNode = createTrailNode(for: satellite)
            trailContainer.addChildNode(trailNode)
            trailNodes.append(trailNode)
        }
    }
    
    private func createSatelliteNode(for satellite: CinematicSatellite) -> SCNNode {
        let size = CGFloat(satellite.visualSize)
        let geometry = SCNSphere(radius: size)
        geometry.segmentCount = 16
        
        let material = SCNMaterial()
        let color = satellite.group.color
        
        // BRIGHT emission for visibility
        material.diffuse.contents = NSColor(
            red: CGFloat(color.r * 0.5),
            green: CGFloat(color.g * 0.5),
            blue: CGFloat(color.b * 0.5),
            alpha: 1.0
        )
        material.emission.contents = NSColor(
            red: CGFloat(color.r),
            green: CGFloat(color.g),
            blue: CGFloat(color.b),
            alpha: 1.0
        )
        material.emission.intensity = CGFloat(satellite.glowIntensity * 2.0)  // Double for visibility
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.8
        material.roughness.contents = 0.3
        
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.name = satellite.name
        node.position = SCNVector3(satellite.position.x, satellite.position.y, satellite.position.z)
        
        // Add glow sprite for ALL satellites
        addGlowSprite(to: node, satellite: satellite)
        
        return node
    }
    
    private func createGlintNode(for satellite: CinematicSatellite) -> SCNNode {
        // Specular flash - bright white sphere that appears briefly
        let size = CGFloat(satellite.visualSize * 4)  // Larger than satellite
        let geometry = SCNSphere(radius: size)
        geometry.segmentCount = 8
        
        let material = SCNMaterial()
        material.diffuse.contents = NSColor.clear
        material.emission.contents = NSColor.white
        material.emission.intensity = 0  // Starts off
        material.lightingModel = .constant
        material.blendMode = .add
        material.isDoubleSided = true
        material.cullMode = .front
        
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(satellite.position.x, satellite.position.y, satellite.position.z)
        node.isHidden = true
        
        return node
    }
    
    private func createTrailNode(for satellite: CinematicSatellite) -> SCNNode {
        // Trail as a line geometry
        let node = SCNNode()
        node.name = "Trail-\(satellite.name)"
        return node
    }
    
    private func addGlowSprite(to node: SCNNode, satellite: CinematicSatellite) {
        // Create billboard glow effect using a sprite - BIGGER for visibility
        let glowGeo = SCNPlane(width: 0.6, height: 0.6)
        
        let glowMat = SCNMaterial()
        glowMat.diffuse.contents = NSColor.clear
        glowMat.emission.contents = NSColor(
            red: CGFloat(satellite.group.color.r),
            green: CGFloat(satellite.group.color.g),
            blue: CGFloat(satellite.group.color.b),
            alpha: 1.0
        )
        glowMat.emission.intensity = 1.0  // Strong glow
        glowMat.lightingModel = .constant
        glowMat.isDoubleSided = true
        glowMat.blendMode = .add
        
        glowGeo.materials = [glowMat]
        
        let glowNode = SCNNode(geometry: glowGeo)
        glowNode.name = "Glow"
        
        // Billboard constraint to always face camera
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = .all
        glowNode.constraints = [constraint]
        
        node.addChildNode(glowNode)
    }
    
    private func calculateConstellationConnections() {
        connections.removeAll()
        
        // Group satellites by constellation
        let groups = Dictionary(grouping: satellites.enumerated()) { $0.element.group }
        
        for (group, indices) in groups {
            guard group != .other else { continue }  // Skip ungrouped
            
            let positions = indices.map { satellites[$0.offset].position }
            
            // Connect nearby satellites in same constellation
            for i in 0..<positions.count {
                for j in (i+1)..<positions.count {
                    let distance = simd_distance(positions[i], positions[j])
                    
                    if distance < constellationConnectionDistance {
                        let intensity = 1.0 - (distance / constellationConnectionDistance)
                        connections.append(ConstellationConnection(
                            fromIndex: indices[i].offset,
                            toIndex: indices[j].offset,
                            intensity: intensity
                        ))
                    }
                }
            }
        }
        
        createConstellationLines()
    }
    
    private func createConstellationLines() {
        // Clear existing
        constellationContainer.childNodes.forEach { $0.removeFromParentNode() }
        constellationLines.removeAll()
        
        for connection in connections {
            guard connection.fromIndex < satelliteNodes.count,
                  connection.toIndex < satelliteNodes.count else { continue }
            
            let fromPos = satellites[connection.fromIndex].position
            let toPos = satellites[connection.toIndex].position
            
            let lineNode = createConnectionLine(from: fromPos, to: toPos, intensity: connection.intensity)
            constellationContainer.addChildNode(lineNode)
            constellationLines.append(lineNode)
        }
    }
    
    private func createConnectionLine(from: SIMD3<Float>, to: SIMD3<Float>, intensity: Float) -> SCNNode {
        let geometry = SCNCylinder(radius: 0.002, height: CGFloat(simd_distance(from, to)))
        
        let material = SCNMaterial()
        material.diffuse.contents = NSColor.white.withAlphaComponent(CGFloat(intensity * 0.3))
        material.emission.contents = NSColor.white
        material.emission.intensity = CGFloat(intensity * 0.5)
        material.lightingModel = .constant
        material.blendMode = .add
        
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        
        // Position at midpoint
        let midpoint = (from + to) / 2
        node.position = SCNVector3(midpoint.x, midpoint.y, midpoint.z)
        
        // Orient along line
        let direction = to - from
        let up = SIMD3<Float>(0, 1, 0)
        let axis = cross(up, direction)
        let angle = acos(dot(up, normalize(direction)))
        
        if simd_length(axis) > 0.001 {
            let q = simd_quatf(angle: angle, axis: normalize(axis))
            node.simdRotation = SIMD4<Float>(q.imag.x, q.imag.y, q.imag.z, q.real)
        }
        
        return node
    }
    
    // MARK: - Update
    
    func updatePositions(_ satellites: [CinematicSatellite]) {
        self.satellites = satellites
        
        for (index, sat) in satellites.enumerated() {
            guard index < satelliteNodes.count else { break }
            
            let node = satelliteNodes[index]
            node.position = SCNVector3(sat.position.x, sat.position.y, sat.position.z)
            
            // Update glint
            updateGlint(for: index, satellite: sat)
            
            // Update trail
            updateTrail(for: index, positions: self.satellites)
        }
        
        // Update constellation lines
        updateConstellations()
    }
    
    private func updateGlint(for index: Int, satellite: CinematicSatellite) {
        guard index < glintNodes.count else { return }
        
        let glintNode = glintNodes[index]
        glintNode.position = SCNVector3(satellite.position.x, satellite.position.y, satellite.position.z)
        
        // Calculate glint animation
        let time = animationTime
        let phase = satellite.glintPhase
        let duration = satellite.glintDuration
        
        if satellite.isGlinting {
            glintNode.isHidden = false
            
            // Animate glint intensity
            let glintCycle = Double(time + phase) / Double(duration)
            let intensity = Float(abs(sin(glintCycle * .pi * 2)))
            
            if let geometry = glintNode.geometry, let material = geometry.firstMaterial {
                material.emission.intensity = CGFloat(intensity * 3.0)
            }
        } else {
            glintNode.isHidden = true
        }
    }
    
    private func updateTrail(for index: Int, positions: [CinematicSatellite]) {
        guard index < trailNodes.count, index < positions.count else { return }
        
        let trailNode = trailNodes[index]
        let sat = positions[index]
        let maxTrail = 10
        var trailPositions = sat.trailPositions
        trailPositions.append(sat.position)
        
        if trailPositions.count > maxTrail {
            trailPositions.removeFirst()
        }
        
        // Update the satellite's trail positions
        if index < self.satellites.count {
            self.satellites[index].trailPositions = trailPositions
        }
        
        // Only show trails in appropriate modes
        if currentMode == .trails || currentMode == .glints {
            updateTrailGeometry(trailNode, positions: trailPositions, satellite: sat)
        } else {
            trailNode.geometry = nil
        }
    }
    
    private func updateTrailGeometry(_ node: SCNNode, positions: [SIMD3<Float>], satellite: CinematicSatellite) {
        guard positions.count >= 2 else {
            node.geometry = nil
            return
        }
        
        let vertices = positions.map { SCNVector3($0.x, $0.y, $0.z) }
        let source = SCNGeometrySource(vertices: vertices)
        
        var indices: [Int32] = []
        for i in 0..<(vertices.count - 1) {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        let color = satellite.group.color
        material.diffuse.contents = NSColor(
            red: CGFloat(color.r),
            green: CGFloat(color.g),
            blue: CGFloat(color.b),
            alpha: 0.5
        )
        material.emission.contents = NSColor(
            red: CGFloat(color.r),
            green: CGFloat(color.g),
            blue: CGFloat(color.b),
            alpha: 1.0
        )
        material.emission.intensity = 0.3
        material.lightingModel = .constant
        material.blendMode = .add
        
        geometry.materials = [material]
        
        node.geometry = geometry
    }
    
    private func updateConstellations() {
        guard currentMode == .constellations else {
            constellationContainer.isHidden = true
            return
        }
        
        constellationContainer.isHidden = false
        
        // Update line positions
        for (index, connection) in connections.enumerated() {
            guard index < constellationLines.count,
                  connection.fromIndex < satellites.count,
                  connection.toIndex < satellites.count else { continue }
            
            let from = satellites[connection.fromIndex].position
            let to = satellites[connection.toIndex].position
            
            let lineNode = constellationLines[index]
            
            // Update position and height
            let midpoint = (from + to) / 2
            lineNode.position = SCNVector3(midpoint.x, midpoint.y, midpoint.z)
            
            let distance = simd_distance(from, to)
            if let geometry = lineNode.geometry as? SCNCylinder {
                geometry.height = CGFloat(distance)
                
                // Orient along line
                let direction = to - from
                let up = SIMD3<Float>(0, 1, 0)
                let axis = cross(up, direction)
                let angle = acos(dot(up, normalize(direction)))
                
                if simd_length(axis) > 0.001 {
                    let q = simd_quatf(angle: angle, axis: normalize(axis))
                    lineNode.simdRotation = SIMD4<Float>(q.imag.x, q.imag.y, q.imag.z, q.real)
                }
            }
        }
    }
    
    // MARK: - Mode
    
    func setMode(_ mode: KubrickMode) {
        currentMode = mode
        
        // Show/hide containers based on mode
        switch mode {
        case .glints:
            glintContainer.isHidden = false
            constellationContainer.isHidden = true
            trailContainer.isHidden = true
        case .constellations:
            glintContainer.isHidden = false
            constellationContainer.isHidden = false
            trailContainer.isHidden = true
        case .shells:
            glintContainer.isHidden = true
            constellationContainer.isHidden = true
            trailContainer.isHidden = true
        case .density:
            glintContainer.isHidden = false
            constellationContainer.isHidden = true
            trailContainer.isHidden = true
        case .trails:
            glintContainer.isHidden = false
            constellationContainer.isHidden = true
            trailContainer.isHidden = false
        }
        
        #if DEBUG
        print("🎬 CinematicRenderer: Mode set to \(mode.displayName)")
        #endif
    }
    
    func update(time: Float) {
        animationTime = time
    }
}