import ScreenSaver
import SceneKit
import simd
import AppKit // For NSImage

/// Kubrick Cinematic Screensaver - Procedural satellite shapes
class KubrickView: ScreenSaverView, SCNSceneRendererDelegate {
    
    // MARK: - Properties
    
    private var sceneView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    private var cameraPivot: SCNNode!
    
    private var animationTime: Double = 0
    private var lastUpdateTime: TimeInterval = 0
    private var setupComplete: Bool = false
    
    // Satellite data
    private var satellites: [SatelliteInstance] = []
    private var satelliteNodes: [String: SCNNode] = [:]
    
    // MARK: - Satellite Model
    
    struct SatelliteInstance {
        let id: String
        var position: SIMD3<Float>
        var orbitAngle: Float
        var orbitSpeed: Float
        var orbitRadius: Float
        var orbitInclination: Float
        var scale: Float
        var rotationSpeed: SIMD3<Float>
        var type: SatelliteType
        var color: NSColor
    }
    
    enum SatelliteType {
        case iss           // Large structure with solar panels
        case starlink      // Flat panel design
        case cubeSat       // Small cube
        case rocket        // Cylinder body
        case debris        // Small irregular
        
        var template: SCNNode {
            switch self {
            case .iss: return createISSTemplate()
            case .starlink: return createStarlinkTemplate()
            case .cubeSat: return createCubeSatTemplate()
            case .rocket: return createRocketTemplate()
            case .debris: return createDebrisTemplate()
            }
        }
    }
    
    // MARK: - Satellite Templates
    
    static func createISSTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.15, 0.15, 0.15)
        
        // Truss structure
        let truss = SCNBox(width: 4.0, height: 0.15, length: 0.15, chamferRadius: 0.02)
        truss.materials = [makeSolarPanelMaterial()]
        root.addChildNode(SCNNode(geometry: truss))
        
        // Modules (cylinders)
        let module = SCNCylinder(radius: 0.25, height: 1.2)
        module.materials = [makeWhiteMaterial()]
        let moduleNode = SCNNode(geometry: module)
        moduleNode.eulerAngles.z = .pi / 2
        moduleNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(moduleNode)
        
        // Solar arrays (4 pairs)
        for i in 0..<4 {
            let x = CGFloat(i - 1) * 1.2 - 0.3
            for sign in [-1.0, 1.0] {
                let panel = SCNBox(width: 0.8, height: 0.02, length: 2.2, chamferRadius: 0.01)
                panel.materials = [makeSolarPanelMaterial()]
                let panelNode = SCNNode(geometry: panel)
                panelNode.position = SCNVector3(x, CGFloat(sign) * 1.4, 0)
                root.addChildNode(panelNode)
            }
        }
        
        // Radiators
        let radiator = SCNBox(width: 0.3, height: 0.02, length: 1.5, chamferRadius: 0.01)
        radiator.materials = [makeGoldMaterial()]
        let radNode = SCNNode(geometry: radiator)
        radNode.position = SCNVector3(0, 0.6, 0.8)
        radNode.eulerAngles.x = 0.3
        root.addChildNode(radNode)
        
        return root
    }
    
    static func createStarlinkTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.2, 0.2, 0.2)
        
        // Body - flat square
        let body = SCNBox(width: 0.3, height: 0.08, length: 0.3, chamferRadius: 0.02)
        body.materials = [makeBlackMaterial()]
        root.addChildNode(SCNNode(geometry: body))
        
        // Two solar panels on each side
        for side in [-1.0, 1.0] {
            let panel = SCNBox(width: 0.6, height: 0.01, length: 0.3, chamferRadius: 0.01)
            panel.materials = [makeSolarPanelMaterial()]
            let panelNode = SCNNode(geometry: panel)
            panelNode.position = SCNVector3(0, 0, side * 0.45)
            root.addChildNode(panelNode)
        }
        
        return root
    }
    
    static func createCubeSatTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.25, 0.25, 0.25)
        
        // Main body
        let body = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        body.materials = [makeWhiteMaterial()]
        root.addChildNode(SCNNode(geometry: body))
        
        // Antenna
        let antenna = SCNCylinder(radius: 0.05, height: 0.8)
        antenna.materials = [makeGoldMaterial()]
        let antNode = SCNNode(geometry: antenna)
        antNode.position = SCNVector3(0.3, 0.6, 0)
        root.addChildNode(antNode)
        
        return root
    }
    
    static func createRocketTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.2, 0.2, 0.2)
        
        // Body cylinder
        let body = SCNCylinder(radius: 0.15, height: 1.0)
        body.materials = [makeWhiteMaterial()]
        let bodyNode = SCNNode(geometry: body)
        root.addChildNode(bodyNode)
        
        // Nose cone
        let nose = SCNCone(topRadius: 0, bottomRadius: 0.15, height: 0.4)
        nose.materials = [makeGoldMaterial()]
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 0.7, 0)
        root.addChildNode(noseNode)
        
        // Engine
        let engine = SCNCylinder(radius: 0.18, height: 0.15)
        engine.materials = [makeMetalMaterial()]
        let engineNode = SCNNode(geometry: engine)
        engineNode.position = SCNVector3(0, -0.55, 0)
        root.addChildNode(engineNode)
        
        return root
    }
    
    static func createDebrisTemplate() -> SCNNode {
        let root = SCNNode()
        root.scale = SCNVector3(0.15, 0.15, 0.15)
        
        // Irregular shape
        let debris = SCNBox(width: 0.4, height: 0.3, length: 0.5, chamferRadius: 0.1)
        debris.materials = [makeMetalMaterial()]
        root.addChildNode(SCNNode(geometry: debris))
        
        return root
    }
    
    // MARK: - Materials
    
    static func makeSolarPanelMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
        m.emission.contents = NSColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0)
        m.emission.intensity = 0.8
        m.metalness.contents = 0.4
        m.roughness.contents = 0.25
        m.lightingModel = .physicallyBased
        return m
    }
    
    static func makeWhiteMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.95, alpha: 1.0)
        m.metalness.contents = 0.0
        m.roughness.contents = 0.6
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.15, alpha: 1.0)
        m.emission.intensity = 0.2
        return m
    }
    
    static func makeGoldMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)
        m.metalness.contents = 1.0
        m.roughness.contents = 0.2
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(red: 0.3, green: 0.25, blue: 0.1, alpha: 1.0)
        m.emission.intensity = 0.3
        return m
    }
    
    static func makeBlackMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.1, alpha: 1.0)
        m.metalness.contents = 0.8
        m.roughness.contents = 0.3
        m.lightingModel = .physicallyBased
        return m
    }
    
    static func makeMetalMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(white: 0.4, alpha: 1.0)
        m.metalness.contents = 0.9
        m.roughness.contents = 0.4
        m.lightingModel = .physicallyBased
        m.emission.contents = NSColor(white: 0.05, alpha: 1.0)
        m.emission.intensity = 0.1
        return m
    }
    
    // MARK: - Initialization
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        sceneView?.frame = bounds
    }
    
    // MARK: - Scene Setup
    
    private func setupScene() {
        guard !setupComplete else { return }
        
        print("🎬 [Kubrick] Setup starting...")
        
        // Create SCNView
        sceneView = SCNView(frame: bounds)
        sceneView.autoresizingMask = [.width, .height]
        sceneView.backgroundColor = NSColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1.0)
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.delegate = self
        addSubview(sceneView)
        
        // Create scene
        scene = SCNScene()
        sceneView.scene = scene
        
        // Camera pivot
        cameraPivot = SCNNode()
        scene.rootNode.addChildNode(cameraPivot)
        
        // Camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 500
        cameraPivot.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(0, 3, 14)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        sceneView.pointOfView = cameraNode
        sceneView.isPlaying = true
        
        // Build scene
        addEarth()
        addSun()
        addStarfield()
        addPlanets()
        addSatellites()
        addLighting()
        
        setupComplete = true
        print("🎬 [Kubrick] Setup complete!")
    }
    
    private func addEarth() {
        let earthGeo = SCNSphere(radius: 2.0)
        earthGeo.segmentCount = 96
        
        let earthMat = SCNMaterial()
        earthMat.lightingModel = .physicallyBased
        earthMat.metalness.contents = 0.1
        earthMat.roughness.contents = 0.6
        
        // Load Earth texture
        if let earthTexture = loadTexture(named: "earth_8k_day") {
            earthMat.diffuse.contents = earthTexture
            
            // Load night texture for city lights
            if let nightTexture = loadTexture(named: "earth_8k_night") {
                earthMat.emission.contents = nightTexture
                earthMat.emission.intensity = 0.5
            }
        } else {
            earthMat.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
            earthMat.emission.contents = NSColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.6)
            earthMat.emission.intensity = 0.5
        }
        
        earthGeo.materials = [earthMat]
        
        let earth = SCNNode(geometry: earthGeo)
        earth.name = "Earth"
        scene.rootNode.addChildNode(earth)
        
        // Clouds layer
        if let cloudsTexture = loadTexture(named: "earth_8k_clouds") {
            let cloudsGeo = SCNSphere(radius: 2.05)
            let cloudsMat = SCNMaterial()
            cloudsMat.diffuse.contents = cloudsTexture
            cloudsMat.transparent.contents = cloudsTexture
            cloudsMat.transparencyMode = .default
            cloudsMat.isDoubleSided = true
            cloudsMat.lightingModel = .physicallyBased
            cloudsGeo.materials = [cloudsMat]
            
            let cloudsNode = SCNNode(geometry: cloudsGeo)
            cloudsNode.name = "Clouds"
            // Slightly faster rotation for clouds
            let cloudRotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 50)
            cloudsNode.runAction(SCNAction.repeatForever(cloudRotation))
            scene.rootNode.addChildNode(cloudsNode)
        }
        
        // Atmosphere glow
        let atmoGeo = SCNSphere(radius: 2.15)
        let atmoMat = SCNMaterial()
        atmoMat.diffuse.contents = NSColor.clear
        atmoMat.emission.contents = NSColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.15)
        atmoMat.emission.intensity = 1.0
        atmoMat.lightingModel = .constant
        atmoMat.isDoubleSided = true
        atmoMat.blendMode = .add
        atmoGeo.materials = [atmoMat]
        scene.rootNode.addChildNode(SCNNode(geometry: atmoGeo))
    }
    
    private func addSun() {
        let sunGeo = SCNSphere(radius: 8)
        sunGeo.segmentCount = 48
        
        let sunMat = SCNMaterial()
        sunMat.lightingModel = .constant
        
        // Load Sun texture
        if let sunTexture = loadTexture(named: "sun_8k") {
            sunMat.diffuse.contents = sunTexture
            sunMat.emission.contents = sunTexture
        } else {
            sunMat.diffuse.contents = NSColor(red: 1.0, green: 0.98, blue: 0.85, alpha: 1.0)
            sunMat.emission.contents = NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
        }
        sunMat.emission.intensity = 3.0
        sunGeo.materials = [sunMat]
        
        let sun = SCNNode(geometry: sunGeo)
        sun.position = SCNVector3(-100, 40, -60)
        scene.rootNode.addChildNode(sun)
        
        // Corona glow
        let coronaGeo = SCNSphere(radius: 12)
        let coronaMat = SCNMaterial()
        coronaMat.diffuse.contents = NSColor.clear
        coronaMat.emission.contents = NSColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.4)
        coronaMat.emission.intensity = 1.5
        coronaMat.lightingModel = .constant
        coronaMat.isDoubleSided = true
        coronaMat.blendMode = .add
        coronaGeo.materials = [coronaMat]
        
        let corona = SCNNode(geometry: coronaGeo)
        corona.position = sun.position
        scene.rootNode.addChildNode(corona)
    }
    
    // MARK: - Texture Loading
    
    private func loadTexture(named name: String) -> NSImage? {
        let bundle = Bundle(for: type(of: self))
        
        // Priority 1: Bundle's Resources/8K subdirectory
        if let resourcePath = bundle.resourcePath {
            let texturePaths = [
                "\(resourcePath)/8K/\(name).jpg",
                "\(resourcePath)/8K/\(name).png"
            ]
            for path in texturePaths {
                if FileManager.default.fileExists(atPath: path) {
                    return NSImage(contentsOfFile: path)
                }
            }
        }
        
        // Priority 2: Development fallback paths
        let devPaths = [
            "/Users/pro/Projects/Secondary/Screensaver/NatureVsNoise-Cinematic/Sources/8K/\(name).jpg",
            "/Users/pro/Projects/Secondary/Screensaver/NatureVsNoise-Cinematic/Sources/8K/\(name).png"
        ]
        for path in devPaths {
            if FileManager.default.fileExists(atPath: path) {
                return NSImage(contentsOfFile: path)
            }
        }
        
        #if DEBUG
        print("⚠️ [Kubrick] Texture '\(name)' not found")
        #endif
        
        return nil
    }
    
    private func addStarfield() {
        // Try to load starfield texture first
        var useTexture = false
        if let starfieldTexture = loadTexture(named: "starfield_8k") {
            useTexture = true
            
            // Create a large sphere with starfield texture inside-out
            let skyGeo = SCNSphere(radius: 350)
            skyGeo.segmentCount = 48
            
            let skyMat = SCNMaterial()
            skyMat.diffuse.contents = starfieldTexture
            skyMat.isDoubleSided = true
            skyMat.lightingModel = .constant
            skyGeo.materials = [skyMat]
            
            let sky = SCNNode(geometry: skyGeo)
            // Rotate to align texture
            sky.eulerAngles.x = .pi / 2
            scene.rootNode.addChildNode(sky)
        }
        
        if !useTexture {
            // Procedural starfield
            for _ in 0..<350 {
                let starGeo = SCNSphere(radius: CGFloat.random(in: 1.2...2.8))
                starGeo.segmentCount = 6
                
                let starMat = SCNMaterial()
                let bright = CGFloat.random(in: 0.85...1.0)
                let temp = CGFloat.random(in: -0.1...0.1)
                starMat.emission.contents = NSColor(
                    red: min(bright + temp, 1.0),
                    green: bright,
                    blue: max(bright - temp * 0.3, 0.7),
                    alpha: 1.0
                )
                starMat.emission.intensity = bright * 1.5
                starMat.lightingModel = .constant
                starGeo.materials = [starMat]
                
                let star = SCNNode(geometry: starGeo)
                let theta = Double.random(in: 0...(2 * .pi))
                let phi = acos(Double.random(in: -1...1))
                let r: Double = 400
                star.position = SCNVector3(
                    CGFloat(r * sin(phi) * cos(theta)),
                    CGFloat(r * sin(phi) * sin(theta)),
                    CGFloat(r * cos(phi))
                )
                scene.rootNode.addChildNode(star)
            }
        }
    }
    
    // MARK: - Planets
    
    private func addPlanets() {
        // Add planets from the original screensaver
        let planetConfigs: [(name: String, radius: CGFloat, position: SCNVector3, texture: String, color: NSColor)] = [
            ("Moon", 0.5, SCNVector3(3.5, 0.5, 0), "moon_8k", NSColor(white: 0.7, alpha: 1.0)),
            ("Mars", 0.7, SCNVector3(6, -1, -2), "mars_8k", NSColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)),
            ("Venus", 0.9, SCNVector3(8, 1, 3), "venus_8k_surface", NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)),
            ("Mercury", 0.4, SCNVector3(5, 0.5, 2), "mercury_8k", NSColor(white: 0.5, alpha: 1.0)),
            ("Jupiter", 3.5, SCNVector3(15, -2, -5), "jupiter_8k", NSColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0)),
            ("Saturn", 3.0, SCNVector3(22, 1, -8), "saturn_8k", NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)),
        ]
        
        for config in planetConfigs {
            addPlanet(name: config.name, radius: config.radius, position: config.position, textureName: config.texture, fallbackColor: config.color, hasRings: config.name == "Saturn")
        }
    }
    
    private func addPlanet(name: String, radius: CGFloat, position: SCNVector3, textureName: String, fallbackColor: NSColor, hasRings: Bool = false) {
        let geo = SCNSphere(radius: radius)
        geo.segmentCount = 64
        
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        
        if let texture = loadTexture(named: textureName) {
            mat.diffuse.contents = texture
        } else {
            mat.diffuse.contents = fallbackColor
        }
        
        geo.materials = [mat]
        
        let planet = SCNNode(geometry: geo)
        planet.name = name
        planet.position = position
        scene.rootNode.addChildNode(planet)
        
        // Saturn rings
        if hasRings {
            let ringGeo = SCNTube(innerRadius: radius * 2.2, outerRadius: radius * 4.0, height: 0.1)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = fallbackColor.withAlphaComponent(0.8)
            ringMat.isDoubleSided = true
            ringMat.lightingModel = .physicallyBased
            ringGeo.materials = [ringMat, ringMat, ringMat]
            
            let ringNode = SCNNode(geometry: ringGeo)
            ringNode.eulerAngles.x = .pi / 3 // Tilt rings
            planet.addChildNode(ringNode)
        }
    }
    
    private func addSatellites() {
        // Zone configs: (radius, count, color, speed)
        let zones: [(Float, Int, NSColor, Float)] = [
            (5.0, 8, NSColor(red: 0.2, green: 1.0, blue: 0.35, alpha: 1.0), 0.006),   // LEO - green
            (9.0, 6, NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0), 0.004),  // MEO - yellow
            (14.0, 8, NSColor(red: 1.0, green: 0.25, blue: 0.2, alpha: 1.0), 0.002),  // GEO - red
            (19.0, 4, NSColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1.0), 0.001)   // HEO - blue
        ]
        
        // Satellite type distribution per zone
        let types: [SatelliteType] = [.iss, .starlink, .cubeSat, .rocket, .debris]
        
        for (zoneIndex, zone) in zones.enumerated() {
            // Create orbital ring
            createOrbitalRing(radius: CGFloat(zone.0), color: zone.2)
            
            // Create satellites
            for i in 0..<zone.1 {
                let satId = "sat-\(zoneIndex)-\(i)"
                let startAngle = Float(i) / Float(zone.1) * .pi * 2
                let inclination = Float.random(in: -0.5...0.5)
                
                // Pick satellite type
                let satType: SatelliteType
                if zoneIndex == 0 {
                    // LEO: mix of ISS, rocket, debris
                    satType = types.randomElement() ?? .rocket
                } else if zoneIndex == 1 {
                    // MEO: mostly cubeSats
                    satType = Bool.random() ? .cubeSat : .rocket
                } else {
                    // GEO/HEO: mostly starlinks
                    satType = Bool.random() ? .starlink : .cubeSat
                }
                
                let sat = SatelliteInstance(
                    id: satId,
                    position: SIMD3<Float>(0, 0, 0),
                    orbitAngle: startAngle,
                    orbitSpeed: zone.3 * Float.random(in: 0.9...1.1),
                    orbitRadius: zone.0 * Float.random(in: 0.98...1.02),
                    orbitInclination: inclination,
                    scale: Float.random(in: 0.8...1.2),
                    rotationSpeed: SIMD3<Float>(
                        Float.random(in: -0.5...0.5),
                        Float.random(in: -0.5...0.5),
                        Float.random(in: -0.5...0.5)
                    ),
                    type: satType,
                    color: zone.2
                )
                satellites.append(sat)
                
                // Create node from template
                let node = satType.template.clone()
                node.name = satId
                satelliteNodes[satId] = node
                scene.rootNode.addChildNode(node)
            }
        }
    }
    
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
    }
    
    private func addLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 250
        ambient.light?.color = NSColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)
        
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.intensity = 700
        sunLight.light?.temperature = 5500
        sunLight.light?.color = NSColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        sunLight.position = SCNVector3(-100, 40, -60)
        sunLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunLight)
    }
    
    // MARK: - Animation
    
    override func animateOneFrame() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        animationTime += delta
        
        // Update satellites
        for i in 0..<satellites.count {
            var sat = satellites[i]
            sat.orbitAngle += sat.orbitSpeed
            
            // Calculate position
            let x = sat.orbitRadius * cos(sat.orbitAngle)
            let z = sat.orbitRadius * sin(sat.orbitAngle)
            let y = sat.orbitRadius * sin(sat.orbitInclination) * sin(sat.orbitAngle)
            sat.position = SIMD3<Float>(x, y, z)
            
            // Update node
            if let node = satelliteNodes[sat.id] {
                node.position = SCNVector3(x, y, z)
                
                // Rotate satellite
                node.eulerAngles.x += CGFloat(sat.rotationSpeed.x * 0.01)
                node.eulerAngles.y += CGFloat(sat.rotationSpeed.y * 0.01)
                node.eulerAngles.z += CGFloat(sat.rotationSpeed.z * 0.01)
            }
            
            satellites[i] = sat
        }
        
        // Camera orbit
        cameraPivot.eulerAngles.y += CGFloat(0.003)
        
        // Pulse rings
        let pulse = (sin(animationTime * 1.2) + 1) / 2 * 0.2 + 0.6
        scene.rootNode.childNodes.filter { $0.name == "orbital-ring" }.forEach {
            $0.geometry?.firstMaterial?.emission.intensity = CGFloat(pulse)
        }
    }
    
    // MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {}
    
    // MARK: - Configuration
    
    override var hasConfigureSheet: Bool { return false }
    override var configureSheet: NSWindow? { return nil }
}