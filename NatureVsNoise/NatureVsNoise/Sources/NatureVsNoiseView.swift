import ScreenSaver
import SceneKit
import Metal
import SpriteKit


class NatureVsNoiseView: ScreenSaverView, SCNSceneRendererDelegate {

    // MARK: - Properties
    private var sceneView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    private var cameraController: CameraController!
    private var satelliteManager: SatelliteManager!
    private var satelliteRenderer: SatelliteRenderer!

    // Metal rendering (high-performance path)
    private var metalRenderer: MetalSatelliteRenderer?
    private var useMetalRendering: Bool = false

    // Feature flags
    private var featureFlags = FeatureFlags()

    // Hardware detection
    private lazy var hardwareCapabilities: HardwareCapabilities = detectHardware()

    private var animationTime: Double = 0
    private var lastUpdateTime: TimeInterval = 0
    private var displayLink: CVDisplayLink?
    
    // MARK: - Diagnostic State
    private var isFullScreenMode: Bool = false
    private var setupComplete: Bool = false
    private var firstFrameRendered: Bool = false
    private var setupStartTime: TimeInterval = 0
    private var firstFrameTime: TimeInterval = 0

    // Audio
    private var audioController: AudioController?

    // UI
    // private var hudOverlay: HUDOverlay?

    // Quality settings - read from UserDefaults, fallback to high
    private var qualityLevel: QualityLevel = {
        let saved = UserDefaults.standard.integer(forKey: "qualityLevel")
        return QualityLevel(rawValue: saved + 1) ?? .high
    }()
    
    // MARK: - Initialization
    
    private var hasSetupScene = false
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        // Detect full-screen mode: not preview AND has reasonable size
        isFullScreenMode = !isPreview && frame.width > 100 && frame.height > 100
        
        logDiagnostics("INIT", details: [
            "frame": "\(Int(frame.width))x\(Int(frame.height))",
            "isPreview": "\(isPreview)",
            "isFullScreen": "\(isFullScreenMode)"
        ])
        
        // Setup immediately if we have a valid frame
        if frame.width > 0 && frame.height > 0 {
            // For full-screen, defer setup slightly to ensure view hierarchy is ready
            if isFullScreenMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.setupScene()
                    self?.hasSetupScene = true
                }
            } else {
                setupScene()
                hasSetupScene = true
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        
        // Update full-screen detection
        isFullScreenMode = !isPreview && newSize.width > 100 && newSize.height > 100
        
        logDiagnostics("SET_FRAME_SIZE", details: [
            "newSize": "\(Int(newSize.width))x\(Int(newSize.height))",
            "isFullScreen": "\(isFullScreenMode)"
        ])
        
        // Setup scene when we first get a valid size
        if !hasSetupScene && newSize.width > 0 && newSize.height > 0 {
            // For full-screen, defer setup to ensure view hierarchy is ready
            if isFullScreenMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self, !self.setupComplete else { return }
                    self.setupScene()
                    self.hasSetupScene = true
                }
            } else {
                setupScene()
                hasSetupScene = true
            }
        }
        
        // Update SCNView frame
        sceneView?.frame = bounds
    }
    
    override func startAnimation() {
        super.startAnimation()
    }
    
    // MARK: - Scene Setup
    
    // Diagnostic log file for debugging screensaver issues
    private func logToFile(_ message: String) {
        let logPath = NSHomeDirectory() + "/Library/Logs/NatureVsNoise.log"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? logMessage.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    }
    
    // Enhanced logging with context
    private func logDiagnostics(_ context: String, details: [String: Any] = [:]) {
        var message = "[DIAG] \(context)"
        message += " | isPreview: \(isPreview)"
        message += " | isFullScreen: \(isFullScreenMode)"
        message += " | bounds: \(Int(bounds.width))x\(Int(bounds.height))"
        message += " | setupComplete: \(setupComplete)"
        
        for (key, value) in details {
            message += " | \(key): \(value)"
        }
        
        logToFile(message)
    }
    
    private func setupScene() {
        guard !setupComplete else {
            logDiagnostics("SETUP_SKIP", details: ["reason": "already_complete"])
            return
        }
        
        setupStartTime = Date().timeIntervalSince1970
        
        // Initialize feature flags defaults
        FeatureFlags.initializeDefaults()
        
        logToFile("=== SCREENSAVER INIT START ===")
        logDiagnostics("SETUP_START", details: [
            "isFullScreen": "\(isFullScreenMode)",
            "isPreview": "\(isPreview)",
            "bounds": "\(Int(bounds.width))x\(Int(bounds.height))"
        ])
        logToFile("Bundle path: \(Bundle(for: type(of: self)).bundlePath)")
        
        if let resourcePath = Bundle(for: type(of: self)).resourcePath {
            logToFile("Resource path: \(resourcePath)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                logToFile("Resources found: \(contents.count) files")
                logToFile("First 5: \(contents.prefix(5))")
            }
        }
        
        // Create SceneKit view
        sceneView = SCNView(frame: bounds)
        sceneView.autoresizingMask = [.width, .height]
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        
        // Set up the renderer delegate to track first frame
        sceneView.delegate = self
        
        addSubview(sceneView)
        
        logDiagnostics("SCNVIEW_CREATED", details: [
            "superview": sceneView.superview != nil ? "yes" : "no",
            "window": sceneView.window != nil ? "yes" : "no"
        ])
        
        // Create scene
        scene = SCNScene()
        sceneView.scene = scene
        
        // Setup camera
        setupCamera()
        
        // CRITICAL: Tell the SCNView to use our camera!
        sceneView.pointOfView = cameraNode

        // Initialize camera controller  
        cameraController = CameraController(scene: scene, cameraNode: cameraNode, cameraPivot: cameraPivot)

        // Initialize satellite manager
        satelliteManager = SatelliteManager(bundle: Bundle(for: type(of: self)))
        logToFile("Satellite Count: \(satelliteManager.satellites.count)")

        // MINIMUM STABLE: Just planets
        addSolarSystem()
        
        // TEST: Re-enable Starfield
        addStarfield()
        
        // PHASE 3: Satellites (SceneKit Only)
        setupRenderers()
        addSatellites()

        // Camera at Earth, orbiting
        cameraPivot.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 20) // Start FAR
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        // CINEMATIC FLY-THROUGH: 2001 style
        // Phase 1: Approach Earth from distance
        let approach = SCNAction.move(to: SCNVector3(x: 0, y: 2, z: 8), duration: 15)
        approach.timingMode = .easeInEaseOut
        
        // Phase 2: Fly PAST Earth, through the satellite shell - GET CLOSER
        let flyPast = SCNAction.move(to: SCNVector3(x: -2, y: 1, z: 3), duration: 15)
        flyPast.timingMode = .easeIn
        
        // Phase 3: Swing around and reset - FARTHER to see the shell
        let swingAround = SCNAction.move(to: SCNVector3(x: 0, y: 5, z: 15), duration: 15)
        swingAround.timingMode = .easeOut
        
        let cinematicSequence = SCNAction.sequence([approach, flyPast, swingAround])
        cameraNode.runAction(SCNAction.repeatForever(cinematicSequence))
        
        sceneView.isPlaying = true
        
        // Initialize audio if enabled
        if FeatureFlags.enableAudio {
            // Check if audio files exist in bundle before initializing
            if let _ = Bundle.main.path(forResource: "ambient_solar_wind", ofType: "wav", inDirectory: "Audio/Ambient") ??
                         Bundle.main.path(forResource: "solar_wind_preview", ofType: "mp3", inDirectory: "Audio/Ambient") {
                audioController = AudioController()
                logToFile("🔊 Audio enabled and initialized")
            } else {
                logToFile("⚠️ Audio files not found in bundle - audio disabled")
            }
        }
        
        // Mark setup complete
        setupComplete = true
        let setupDuration = Date().timeIntervalSince1970 - setupStartTime
        logDiagnostics("SETUP_COMPLETE", details: [
            "duration": String(format: "%.3f", setupDuration)
        ])
        
        // Initialize UI (Phase 3)
        // hudOverlay = HUDOverlay(size: bounds.size)
        // sceneView.overlaySKScene = hudOverlay
        
        #if DEBUG
        print("🚀 NatureVsNoiseView: Initialized")
        print("   Hardware: \(hardwareCapabilities)")
        print("   Metal Rendering: \(useMetalRendering ? "ENABLED" : "DISABLED (SceneKit fallback)")")
        print("   Quality Level: \(qualityLevel)")
        #endif
    }
    
    /// Setup renderers based on feature flags
    private func setupRenderers() {
        // SAFE MODE: In full-screen, apply conservative settings to avoid black screen
        var effectiveUseMetal = FeatureFlags.enableSwarm
        var effectiveToySats = FeatureFlags.enableToySats
        
        if isFullScreenMode {
            logDiagnostics("SAFE_MODE_CHECK", details: [
                "enableSwarm": "\(FeatureFlags.enableSwarm)",
                "enableToySats": "\(FeatureFlags.enableToySats)"
            ])
            
            // In full-screen, disable Metal by default (known to cause black screen)
            // Only enable if user explicitly set it
            if FeatureFlags.enableSwarm {
                logToFile("⚠️ WARNING: Metal swarm enabled in full-screen - may cause black screen")
            }
            
            // Force safe values in full-screen mode
            effectiveUseMetal = false  // Always disable Metal in full-screen for now
            effectiveToySats = true    // Keep toy sats enabled
        }
        
        // Initialize Metal renderer if swarm is enabled
        if effectiveUseMetal {
            metalRenderer = MetalSatelliteRenderer()
            if metalRenderer != nil {
                useMetalRendering = true
                qualityLevel = .ultra

                // Configure Metal renderer for firefly swarm
                metalRenderer?.earthPosition = SIMD3<Float>(0, 0, 0) // Earth at origin
                metalRenderer?.showTrails = FeatureFlags.enableSwarm && FeatureFlags.showTrails
                metalRenderer?.trailLength = 1.5
                metalRenderer?.setTimeAcceleration(Float(satelliteManager.timeAcceleration))

                #if DEBUG
                print("✅ Metal renderer initialized for swarm")
                #endif
            }
        }

        // Initialize SceneKit renderer if toy sats are enabled
        if effectiveToySats {
            satelliteRenderer = SatelliteRenderer(scene: scene)
        }

        // Configure quality based on hardware
        configureQualitySettings()
    }
    
    /// Configure quality settings based on detected hardware
    private func configureQualitySettings() {
        switch hardwareCapabilities.tier {
        case .ultra:
            qualityLevel = .ultra
            satelliteRenderer.setQualityLevel(.high) // SatelliteRenderer max is .high
        case .high:
            qualityLevel = .high
            satelliteRenderer.setQualityLevel(.high)
        case .medium:
            qualityLevel = .medium
            satelliteRenderer.setQualityLevel(.medium)
        case .low:
            qualityLevel = .low
            satelliteRenderer.setQualityLevel(.low)
        }
    }
    
    // MARK: - Camera
    
    private var cameraPivot: SCNNode!  // Pivot for orbital rotation
    
    private func setupCamera() {
        // Create camera node
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 10000
        cameraNode.camera?.fieldOfView = 60
        
        // HIGH QUALITY VISUALS (Phase 3)
        // Enable HDR and Bloom for cinematic look
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.exposureOffset = -0.3 // Slightly darker space
        cameraNode.camera?.averageGray = 0.18
        cameraNode.camera?.whitePoint = 1.0
        
        // Bloom settings - DISABLED to preserve satellite colors
        cameraNode.camera?.bloomIntensity = 0.0 // Was washing out colors
        cameraNode.camera?.bloomThreshold = 1.0
        cameraNode.camera?.bloomBlurRadius = 0.0
        
        // Create a pivot node for orbital rotation
        // Camera will be offset from pivot, and rotating the pivot creates orbital motion
        cameraPivot = SCNNode()
        cameraPivot.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraPivot)
        
        // CRITICAL: Set initial camera position so something is visible immediately
        // CINEMATIC COMPOSITION: See Earth as beautiful sphere with visible debris shell
        cameraPivot.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 8) // Cinematic distance
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        
        logToFile("Camera initial position - Pivot: \(cameraPivot.position), Camera: \(cameraNode.position)")
        
        // PBR Lighting Environment
        // Simulates light coming from stars/galaxy
        scene.lightingEnvironment.contents = NSColor(white: 0.02, alpha: 1.0) // Very dark ambient
        scene.lightingEnvironment.intensity = 1.0
        
        // Minimal ambient light fill (for shadowed sides of planets)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 50 // Reduced from 100
        ambientLight.light?.color = NSColor(white: 0.2, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
    }
    
    

    
    // MARK: - Earth
    
    private func addEarth() {
        let earthGeometry = SCNSphere(radius: 2.0)
        earthGeometry.segmentCount = 64
        
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = NSColor.blue
        
        // Try to load day texture
        if let dayTexture = loadTexture(named: "earth_8k_day") {
            earthMaterial.diffuse.contents = dayTexture
        }
        
        // Try to load night texture for emission (city lights)
        if let nightTexture = loadTexture(named: "earth_8k_night") {
            earthMaterial.emission.contents = nightTexture
            earthMaterial.emission.intensity = 0.3
        }
        
        // Specular for ocean reflections
        earthMaterial.specular.contents = NSColor.white
        earthMaterial.shininess = 0.1
        
        earthGeometry.materials = [earthMaterial]
        
        let earthNode = SCNNode(geometry: earthGeometry)
        earthNode.name = "Earth"
        earthNode.position = SCNVector3(x: 30, y: 0, z: 0)
        
        // Earth's axial tilt (23.5 degrees)
        earthNode.eulerAngles.z = CGFloat.pi * 23.5 / 180.0
        
        scene.rootNode.addChildNode(earthNode)
        
        // Earth rotation (24 hours = show in 60 seconds for screensaver)
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 60)
        earthNode.runAction(SCNAction.repeatForever(rotation))
        
        // Add cloud layer
        addEarthClouds(parent: earthNode)
    }
    
    private func addEarthClouds(parent: SCNNode) {
        let cloudGeometry = SCNSphere(radius: 2.02) // Slightly larger than Earth
        cloudGeometry.segmentCount = 64
        
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = NSColor.clear
        cloudMaterial.transparent.contents = NSColor.white
        cloudMaterial.transparencyMode = .rgbZero
        cloudMaterial.isDoubleSided = true
        
        if let cloudTexture = loadTexture(named: "earth_8k_clouds") {
            cloudMaterial.transparent.contents = cloudTexture
        }
        
        cloudGeometry.materials = [cloudMaterial]
        
        let cloudNode = SCNNode(geometry: cloudGeometry)
        cloudNode.name = "Earth_Clouds"
        cloudNode.opacity = 0.6
        parent.addChildNode(cloudNode)
        
        // Clouds rotate slightly faster than Earth
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 55)
        cloudNode.runAction(SCNAction.repeatForever(rotation))
    }
    

    // MARK: - Solar System
    
    private func addSolarSystem() {
        // CRITICAL: Add Sun explicitly first (not in allPlanets array)
        let sunNode = PlanetFactory.createPlanet(PlanetFactory.PlanetData.sun)
        sunNode.position = SCNVector3(-100, 20, -100) // Move Sun to background
        scene.rootNode.addChildNode(sunNode)
        
        // Point light emanating from Sun
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .omni
        sunLight.light?.intensity = 5000 // Boosted
        sunLight.light?.temperature = 6500
        sunLight.light?.color = NSColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
        sunLight.light?.attenuationStartDistance = 0
        sunLight.light?.attenuationEndDistance = 1000
        sunLight.position = sunNode.position
        scene.rootNode.addChildNode(sunLight)
        
        // FAKE BLOOM: Add glowing shells around the Sun
        // Inner Glow
        let sunGlowGeo = SCNSphere(radius: 12.0)
        sunGlowGeo.segmentCount = 48
        let glowMat = SCNMaterial()
        glowMat.diffuse.contents = NSColor.clear
        glowMat.emission.contents = NSColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
        glowMat.transparencyMode = .aOne
        glowMat.transparent.contents = NSColor(white: 1.0, alpha: 0.4)
        glowMat.isDoubleSided = false
        glowMat.cullMode = .back
        sunGlowGeo.materials = [glowMat]
        let glowNode = SCNNode(geometry: sunGlowGeo)
        glowNode.opacity = 0.5
        glowNode.position = sunNode.position
        scene.rootNode.addChildNode(glowNode)
        
        // Outer Corona
        let coronaGeo = SCNSphere(radius: 18.0)
        coronaGeo.segmentCount = 48
        let coronaMat = SCNMaterial()
        coronaMat.diffuse.contents = NSColor.clear
        coronaMat.emission.contents = NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        coronaMat.transparencyMode = .aOne
        coronaMat.transparent.contents = NSColor(white: 1.0, alpha: 0.15)
        coronaMat.isDoubleSided = false
        coronaGeo.materials = [coronaMat]
        let coronaNode = SCNNode(geometry: coronaGeo)
        coronaNode.opacity = 0.3
        coronaNode.position = sunNode.position
        scene.rootNode.addChildNode(coronaNode)
        
        // Add all 8 planets
        for planetData in PlanetFactory.PlanetData.allPlanets {
            let planetNode = PlanetFactory.createPlanet(planetData)
            
            // CENTER EARTH FIX
            if planetData.name == "Earth" {
                planetNode.position = SCNVector3(0, 0, 0)
                addEarthClouds(parent: planetNode)
            }
            
            scene.rootNode.addChildNode(planetNode)
        }
    }
    
    // MARK: - Starfield
    
    private func addStarfield() {
        // Create a simple black background sphere
        let backgroundGeometry = SCNSphere(radius: 5000)
        backgroundGeometry.segmentCount = 16
        
        let backgroundMaterial = SCNMaterial()
        backgroundMaterial.diffuse.contents = NSColor.black // Clean black background
        // backgroundMaterial.diffuse.contents = loadTexture(named: "starfield_8k") // DISABLED: Causing pixelated noise look
        backgroundMaterial.isDoubleSided = true
        backgroundMaterial.cullMode = .front
        backgroundMaterial.lightingModel = .constant
        
        backgroundGeometry.materials = [backgroundMaterial]
        
        let backgroundNode = SCNNode(geometry: backgroundGeometry)
        backgroundNode.name = "Background"
        scene.rootNode.addChildNode(backgroundNode)
        
        // Create procedural stars as small emissive spheres
        let starContainer = SCNNode()
        starContainer.name = "Starfield"
        
        // Generate random stars
        let starCount = 5000 // Increased from 2000 for better density
        let starRadius: CGFloat = 0.5
        let fieldRadius: Float = 4000
        
        for _ in 0..<starCount {
            // Random position on sphere surface
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = acos(Float.random(in: -1...1))
            
            let x = fieldRadius * sin(phi) * cos(theta)
            let y = fieldRadius * sin(phi) * sin(theta)
            let z = fieldRadius * cos(phi)
            
            // Random star size and brightness
            let size = CGFloat.random(in: 0.3...1.5) * starRadius
            let brightness = CGFloat.random(in: 0.3...1.0)
            
            let starGeometry = SCNSphere(radius: size)
            starGeometry.segmentCount = 6
            
            let starMaterial = SCNMaterial()
            // Slight color variation (white to blue-white to yellow-white)
            let colorVariation = CGFloat.random(in: -0.1...0.1)
            starMaterial.emission.contents = NSColor(
                red: 1.0 + colorVariation,
                green: 1.0 + colorVariation,
                blue: 1.0 - colorVariation * 0.5,
                alpha: 1.0
            )
            starMaterial.emission.intensity = brightness
            starMaterial.lightingModel = .constant
            
            starGeometry.materials = [starMaterial]
            
            let starNode = SCNNode(geometry: starGeometry)
            starNode.position = SCNVector3(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z))
            starContainer.addChildNode(starNode)
        }
        
        scene.rootNode.addChildNode(starContainer)
    }

    // MARK: - Satellites

    private func addSatellites() {
        guard satelliteManager != nil else { return }
        
        // Use Metal accelerated path if available
        if useMetalRendering, let metalRenderer = metalRenderer {
            addSatellitesMetal(metalRenderer: metalRenderer)
        } else {
            addSatellitesSceneKit()
        }
    }
    
    /// Metal-accelerated satellite rendering (Apple Silicon)
    private func addSatellitesMetal(metalRenderer: MetalSatelliteRenderer) {
        guard let satelliteManager = satelliteManager else { return }
        
        let maxSatellites = qualityLevel.maxSatellites
        let satellites = Array(satelliteManager.satellites.prefix(maxSatellites))
        
        // Build color array
        var colors: [SIMD4<Float>] = []
        colors.reserveCapacity(satellites.count)
        for satellite in satellites {
            colors.append(satelliteManager.colorForSatellite(satellite))
        }
        
        // Upload to GPU (one-time or when data changes)
        if animationTime == 0 {
            metalRenderer.uploadSatellites(satellites, colors: colors)
        }
        
        // GPU propagates all positions in parallel
        metalRenderer.propagate(deltaTime: 0.1)
        
        // For hybrid rendering, get positions back from GPU and update SceneKit nodes
        // This allows us to use SceneKit's camera and lighting while Metal handles satellites
        let positions = metalRenderer.getInstancePositions()
        
        guard let satelliteRenderer = satelliteRenderer else { return }
        
        let earthOffset = SIMD3<Float>(30, 0, 0)
        let velocities: [SIMD3<Float>] = Array(repeating: .zero, count: positions.count)
        
        satelliteRenderer.updateSatellites(
            positions: positions,
            colors: colors,
            velocities: velocities,
            names: Array(repeating: "SAT", count: positions.count),
            earthOffset: earthOffset
        )
    }
    
    /// SceneKit satellite rendering (fallback for older hardware)
    private func addSatellitesSceneKit() {
        guard let satelliteManager = satelliteManager,
              let satelliteRenderer = satelliteRenderer else { return }

        var positions: [SIMD3<Float>] = []
        var colors: [SIMD4<Float>] = []
        var velocities: [SIMD3<Float>] = []
        var names: [String] = []

        let earthOffset = SIMD3<Float>(x: 0, y: 0, z: 0)
        // Use reasonable satellite count based on quality level
        // SceneKit can handle ~500-1000 nodes smoothly
        let safeMaxSatellites = qualityLevel.maxSatellites
        
        let scale: Float = 2.0 / 6371.0 // Scale KM (Radius 6371) to SceneKit (Radius 2.0)

        for satellite in satelliteManager.satellites.prefix(safeMaxSatellites) {
            let (position, velocity) = satelliteManager.getPositionAndVelocity(for: satellite, at: animationTime)

            positions.append(SIMD3<Float>(
                Float(position.x) * scale,
                Float(position.y) * scale,
                Float(position.z) * scale
            ))
            colors.append(satelliteManager.colorForSatellite(satellite))
            velocities.append(SIMD3<Float>(velocity))
            names.append(satellite.name)
        }

        satelliteRenderer.updateSatellites(
            positions: positions,
            colors: colors,
            velocities: velocities,
            names: names,
            earthOffset: earthOffset
        )

        // Add motion trails for high-orbit satellites (only if quality allows)
        if qualityLevel >= .medium {
            satelliteRenderer.addMotionTrails(positions: positions, velocities: velocities, earthOffset: earthOffset)
        }
    }

    private func setupAnimationTimer() {
        // Update satellites periodically for orbital motion
        let updateInterval = qualityLevel.updateInterval
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateSatellites()
        }
    }

    private func updateSatellites() {
        animationTime += 0.1
        addSatellites()
    }

    // MARK: - Texture Loading
    
    private func loadTexture(named name: String) -> NSImage? {
        let bundle = Bundle(for: type(of: self))
        
        // Priority 1: Bundle resources root
        if let bundlePath = bundle.path(forResource: name, ofType: "jpg") {
            return NSImage(contentsOfFile: bundlePath)
        }
        if let bundlePath = bundle.path(forResource: name, ofType: "png") {
            return NSImage(contentsOfFile: bundlePath)
        }
        
        // Priority 2: Bundle's Resources/Textures/8K subdirectory
        if let resourcePath = bundle.resourcePath {
            let texturePaths = [
                "\(resourcePath)/Textures/8K/\(name).jpg",
                "\(resourcePath)/Textures/8K/\(name).png"
            ]
            for path in texturePaths {
                if FileManager.default.fileExists(atPath: path) {
                    return NSImage(contentsOfFile: path)
                }
            }
        }
        
        // Priority 3: Development fallback (project directory)
        let projectPaths = [
            "/Users/pro/Projects/Screensaver/Resources/Textures/8K/\(name).jpg",
            "/Users/pro/Projects/Screensaver/Resources/Textures/8K/\(name).png"
        ]
        
        for path in projectPaths {
            if FileManager.default.fileExists(atPath: path) {
                return NSImage(contentsOfFile: path)
            }
        }
        
        #if DEBUG
        print("⚠️ NatureVsNoiseView: Texture '\(name)' not found")
        #endif
        
        return nil
    }
    
    // MARK: - Animation
    
    override func animateOneFrame() {
        // Track first frame render
        if !firstFrameRendered, let sceneView = sceneView {
            firstFrameRendered = true
            firstFrameTime = Date().timeIntervalSince1970
            let setupDuration = firstFrameTime - setupStartTime
            logDiagnostics("FIRST_FRAME", details: [
                "setupDuration": String(format: "%.3f", setupDuration),
                "totalDuration": String(format: "%.3f", firstFrameTime - setupStartTime)
            ])
        }
        
        // SceneKit handles animation automatically
        // Update Audio System
        /*
        guard let audioController = audioController,
              let cameraPivot = cameraPivot else { return }
        
        // Calculate camera world position (pivot + offset)
        // In our setup, cameraPivot moves, camera is child.
        // World Pos ≈ Pivot Pos (since camera is relatively close)
        let currentPos = cameraPivot.presentation.position
        
        // Find nearest planet for audio context
        // Planets are at known X positions (0, 15, 20, 30, 40, 80, 120, 160, 200)
        let nearest = findNearestPlanet(to: currentPos)
        
        audioController.update(cameraPosition: currentPos, targetNode: nearest)
        
        // Update UI
        if let hud = hudOverlay {
            let targetName = nearest?.name ?? "DEEP SPACE"
            let coords = String(format: "%.1f, %.1f, %.1f", currentPos.x, currentPos.y, currentPos.z)
            hud.updateTarget(targetName, coordinates: coords)
            
            // Stats (approximate count based on quality)
            hud.updateStats(satelliteCount: qualityLevel.maxSatellites, fps: 60)
        }
        */
    }
    
    // MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called every frame - can be used for per-frame diagnostics
        if !firstFrameRendered {
            firstFrameRendered = true
            firstFrameTime = Date().timeIntervalSince1970
            let setupDuration = firstFrameTime - setupStartTime
            logDiagnostics("FIRST_FRAME_RENDERED", details: [
                "setupDuration": String(format: "%.3f", setupDuration)
            ])
        }
    }
    
    private func findNearestPlanet(to position: SCNVector3) -> SCNNode? {
        // Simple heuristic based on X position
        // This relies on the linear layout of current implementation
        var minDistance: CGFloat = 10000
        var nearest: SCNNode? = nil
        
        scene?.rootNode.childNodes.forEach { node in
            // Filter for planets (names match PlanetData)
            if ["Sun", "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"].contains(node.name) {
                let dist = abs(node.position.x - position.x) // Only care about X for this linear tour
                if dist < minDistance {
                    minDistance = dist
                    nearest = node
                }
            }
        }
        return nearest
    }
    
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        return SettingsController.shared.makeConfigureSheet()
    }
    
    // MARK: - Hardware Detection
    
    private func detectHardware() -> HardwareCapabilities {
        var capabilities = HardwareCapabilities()
        
        // Check for Metal support
        if let device = MTLCreateSystemDefaultDevice() {
            capabilities.supportsAppleSilicon = device.supportsFamily(.apple7) || 
                                                 device.supportsFamily(.apple6) ||
                                                 device.supportsFamily(.apple5)
            capabilities.metalDeviceName = device.name
            
            // Determine tier based on device capabilities
            if device.supportsFamily(.apple7) {
                capabilities.tier = .ultra  // M1 Pro/Max/Ultra, M2, M3
            } else if device.supportsFamily(.apple6) {
                capabilities.tier = .high   // M1, A14+
            } else if device.supportsFamily(.apple5) {
                capabilities.tier = .medium // A12, A13
            } else {
                capabilities.tier = .low    // Older devices
            }
            
            // Check for unified memory (Apple Silicon indicator)
            capabilities.hasUnifiedMemory = device.hasUnifiedMemory
            
            #if DEBUG
            print("🔧 Hardware Detection:")
            print("   Device: \(device.name)")
            print("   Apple Silicon: \(capabilities.supportsAppleSilicon)")
            print("   Unified Memory: \(capabilities.hasUnifiedMemory)")
            print("   Tier: \(capabilities.tier)")
            #endif
        }
        
        return capabilities
    }
}

// MARK: - Hardware Capabilities

struct HardwareCapabilities: CustomStringConvertible {
    var supportsAppleSilicon: Bool = false
    var hasUnifiedMemory: Bool = false
    var metalDeviceName: String = "Unknown"
    var tier: HardwareTier = .medium
    
    var description: String {
        return "\(metalDeviceName) (\(tier), Apple Silicon: \(supportsAppleSilicon))"
    }
}

enum HardwareTier: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case ultra = 4
    
    static func < (lhs: HardwareTier, rhs: HardwareTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Quality Level

enum QualityLevel: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case ultra = 4
    
    /// Maximum satellites to render at this quality level
    var maxSatellites: Int {
        switch self {
        case .low: return 200      // SceneKit safe limit
        case .medium: return 500   // SceneKit acceptable
        case .high: return 1000    // Metal capable only
        case .ultra: return 5000   // Metal high-end only
        }
    }
    
    /// Update interval in seconds
    var updateInterval: TimeInterval {
        switch self {
        case .low: return 0.2      // 5 FPS updates
        case .medium: return 0.1   // 10 FPS updates
        case .high: return 0.05    // 20 FPS updates
        case .ultra: return 0.033  // 30 FPS updates
        }
    }
    
    /// Whether to show motion trails
    var showTrails: Bool {
        return self >= .medium
    }
    
    static func < (lhs: QualityLevel, rhs: QualityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
