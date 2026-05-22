import ScreenSaver
import SceneKit
import Metal
import SpriteKit


class NatureVsNoiseView: ScreenSaverView, SCNSceneRendererDelegate {

    // MARK: - Properties
    private var sceneView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    private var groundCameraNode: SCNNode!
    private var earthNode: SCNNode?
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
    
    // Viewpoint Cycling
    private enum ViewMode {
        case cinematicOrbit
        case groundStellarium
    }
    private var currentViewMode: ViewMode = .cinematicOrbit
    private var lastViewModeSwitchTime: TimeInterval = 0

    // Audio
    private var audioController: AudioController?

    // UI
    private var hudOverlay: HUDOverlay?

    // Quality settings - read from UserDefaults, fallback to high
    private var qualityLevel: QualityLevel = {
        let saved = UserDefaults.standard.integer(forKey: "qualityLevel")
        return QualityLevel(rawValue: saved) ?? .high
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
    
    override func stopAnimation() {
        // Clean up resources when screensaver is disabled
        sceneView?.isPlaying = false
        sceneView?.delegate = nil
        
        // Stop HUD update timer
        hudOverlay?.stopUpdateTimer()
        
        super.stopAnimation()
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
        
        setupGroundCamera()
        lastViewModeSwitchTime = Date().timeIntervalSince1970
        
        sceneView.isPlaying = true
        
        // Initialize audio if enabled
        if FeatureFlags.enableAudio {
            // Check if audio files exist in bundle before initializing
            if let _ = Bundle(for: type(of: self)).path(forResource: "ambient_solar_wind", ofType: "wav", inDirectory: "Audio/Ambient") ??
                         Bundle(for: type(of: self)).path(forResource: "solar_wind_preview", ofType: "mp3", inDirectory: "Audio/Ambient") {
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
        hudOverlay = HUDOverlay(size: bounds.size)
        sceneView.overlaySKScene = hudOverlay
        
        #if DEBUG
        print("🚀 NatureVsNoiseView: Initialized")
        print("   Hardware: \(hardwareCapabilities)")
        print("   Metal Rendering: \(useMetalRendering ? "ENABLED" : "DISABLED (SceneKit fallback)")")
        print("   Quality Level: \(qualityLevel)")
        #endif
    }
    
    /// Setup renderers based on feature flags
    private func setupRenderers() {
        // Hybrid rendering: Use Metal for swarm (via SceneKit delegate), SceneKit for hero satellites
        let effectiveUseMetal = FeatureFlags.enableSwarm
        let effectiveToySats = FeatureFlags.enableToySats
        
        logDiagnostics("RENDERER_SETUP", details: [
            "enableSwarm": "\(effectiveUseMetal)",
            "enableToySats": "\(effectiveToySats)",
            "isFullScreen": "\(isFullScreenMode)"
        ])
        
        // Initialize Metal renderer if swarm is enabled
        // Now works in full-screen via SCNSceneRendererDelegate integration
        if effectiveUseMetal {
            metalRenderer = MetalSatelliteRenderer.create()
            if metalRenderer != nil {
                useMetalRendering = true

                // Configure Metal renderer for firefly swarm
                metalRenderer?.earthPosition = SIMD3<Float>(0, 0, 0) // Earth at origin
                metalRenderer?.showTrails = FeatureFlags.showTrails
                metalRenderer?.trailLength = 1.5
                metalRenderer?.setTimeAcceleration(Float(satelliteManager.timeAcceleration))

                logToFile("✅ Metal renderer initialized for swarm (hybrid mode)")
            } else {
                logToFile("⚠️ Metal renderer creation failed - falling back to SceneKit only")
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
        // SceneKit requires a valid lighting environment for PBR, but large 8-bit NSImages can fail causing black screens.
        // Using a solid mid-grey color ensures all PBR metallic materials (satellites) reflect light safely.
        scene.lightingEnvironment.contents = NSColor(white: 0.3, alpha: 1.0)
        scene.lightingEnvironment.intensity = 2.0
        
        // Minimal ambient light fill (for shadowed sides of planets)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 50 // Reduced from 100
        ambientLight.light?.color = NSColor(white: 0.2, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
    }
    
    private func setupGroundCamera() {
        guard let earth = earthNode else { return }
        
        groundCameraNode = SCNNode()
        groundCameraNode.camera = SCNCamera()
        groundCameraNode.camera?.zNear = 0.05
        groundCameraNode.camera?.zFar = 10000
        groundCameraNode.camera?.fieldOfView = 90 // Wide angle for looking up at the sky
        groundCameraNode.camera?.wantsHDR = true
        groundCameraNode.camera?.exposureOffset = 0.5 // Slightly brighter to see stars better
        
        // Attach to Earth's surface. 
        // Earth radius is 2.0 in the scene. Cloud layer is 2.02.
        // We place the camera at z = 2.03 to be "on the ground" just above the clouds.
        groundCameraNode.position = SCNVector3(0, 0, 2.03)
        // Rotate camera 180 deg around Y-axis so it points AWAY from the center of the Earth (upwards into space)
        // SceneKit cameras point down -Z by default.
        groundCameraNode.eulerAngles.y = .pi
        
        earth.addChildNode(groundCameraNode)
    }
    
    

    
    // MARK: - Earth
    
    private func addEarth() {
        let earthGeometry = SCNSphere(radius: 2.0)
        earthGeometry.segmentCount = 64
        
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = NSColor.blue
        
        // Load all Earth textures via TextureManager
	let textures = TextureManager.shared.loadEarthTextures()
	
	// Try to load day texture
	if let dayTexture = textures.day {
            earthMaterial.diffuse.contents = dayTexture
        }
        
        // Try to load night texture for emission (city lights)
        if let nightTexture = textures.night {
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
        addEarthClouds(parent: earthNode, cloudTexture: textures.clouds)
    }
    
    private func addEarthClouds(parent: SCNNode, cloudTexture: NSImage?) {
        let cloudGeometry = SCNSphere(radius: 2.02) // Slightly larger than Earth
        cloudGeometry.segmentCount = 64
        
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = NSColor.clear
        cloudMaterial.transparent.contents = NSColor.white
        cloudMaterial.transparencyMode = .rgbZero
        cloudMaterial.isDoubleSided = true
        
        let textures = TextureManager.shared.loadEarthTextures()
        if let cloudTexture = cloudTexture {
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
                addEarthClouds(parent: planetNode, cloudTexture: TextureManager.shared.load(named: "earth_8k_clouds"))
                earthNode = planetNode
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
        
        let earthOffset = SIMD3<Float>(0, 0, 0)
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
        var classifications: [SatelliteClass] = []
        var ages: [Double] = []

        let earthOffset = SIMD3<Float>(x: 0, y: 0, z: 0)
        let safeMaxSatellites = qualityLevel.maxSatellites
        
        let scale: Float = 2.0 / 6371.0

        let satellites = Array(satelliteManager.satellites.prefix(safeMaxSatellites))
        
        for satellite in satellites {
            let (position, velocity) = satelliteManager.getPositionAndVelocity(for: satellite, at: animationTime)

            positions.append(SIMD3<Float>(
                Float(position.x) * scale,
                Float(position.y) * scale,
                Float(position.z) * scale
            ))
            colors.append(satelliteManager.colorForSatellite(satellite))
            velocities.append(SIMD3<Float>(velocity))
            names.append(satellite.name)
            classifications.append(satelliteManager.classifySatellite(satellite))
            ages.append(satelliteManager.calculateAge(satellite))
        }

        satelliteRenderer.updateSatellites(
            positions: positions,
            colors: colors,
            velocities: velocities,
            names: names,
            classifications: classifications,
            ages: ages,
            earthOffset: earthOffset
        )

        if qualityLevel >= .medium {
            satelliteRenderer.addMotionTrails(positions: positions, velocities: velocities, earthOffset: earthOffset)
        }
    }

    private func updateSatellites() {
        animationTime += 0.1
        addSatellites()
    }

    // MARK: - Animation
    
    override func animateOneFrame() {
        // Track first frame render
        if !firstFrameRendered, sceneView != nil {
            firstFrameRendered = true
            firstFrameTime = Date().timeIntervalSince1970
            let setupDuration = firstFrameTime - setupStartTime
            logDiagnostics("FIRST_FRAME", details: [
                "setupDuration": String(format: "%.3f", setupDuration),
                "totalDuration": String(format: "%.3f", firstFrameTime - setupStartTime)
            ])
        }
        
        // Update Audio System
        if let audioController = audioController {
            guard let cameraPivot = cameraPivot else { return }
            
            // Calculate camera world position (pivot + offset)
            // In our setup, cameraPivot moves, camera is child.
            // World Pos ≈ Pivot Pos (since camera is relatively close)
            let currentPos = cameraPivot.presentation.position
            
            // Find nearest planet for audio context
            // Planets are at known X positions (0, 15, 20, 30, 40, 80, 120, 160, 200)
            let nearest = findNearestPlanet(to: currentPos)
            
            audioController.update(cameraPosition: currentPos, targetNode: nearest)
        }
        
        // Update UI
        if let hud = hudOverlay {
            // Calculate approximate altitude from camera position
            let cameraDist = sqrt(
                cameraNode.position.x * cameraNode.position.x +
                cameraNode.position.y * cameraNode.position.y +
                cameraNode.position.z * cameraNode.position.z
            )
            
            // Convert SceneKit units to km (Earth radius = 2.0 in SceneKit, 6371km in reality)
            let altitudeKm = max(0, (cameraDist - 2.0) * 3185.5)
            let velocity = 7.8 - (altitudeKm / 20000.0)  // Approximate orbital velocity
            
            // Update HUD with current state
            hud.updateCamera(altitude: altitudeKm, velocity: max(3.0, velocity))
            hud.updateStats(satelliteCount: qualityLevel.maxSatellites, fps: 60)
            
            
            let targetName = findNearestPlanet(to: cameraNode.position)?.name ?? "DEEP SPACE"
            let coords = String(format: "%.1f, %.1f, %.1f", cameraNode.position.x, cameraNode.position.y, cameraNode.position.z)
            // Adjust HUD text for current mode
            if currentViewMode == .groundStellarium {
                hud.updateTarget("STELLARIUM MODE", coordinates: "SURFACE")
            } else {
                hud.updateTarget(targetName, coordinates: coords)
            }
        }
        
        // Viewpoint Cycling
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastViewModeSwitchTime > 30.0 { // Switch perspective every 30 seconds
            lastViewModeSwitchTime = currentTime
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 2.0
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if currentViewMode == .cinematicOrbit {
                currentViewMode = .groundStellarium
                sceneView?.pointOfView = groundCameraNode
            } else {
                currentViewMode = .cinematicOrbit
                sceneView?.pointOfView = cameraNode
            }
            
            SCNTransaction.commit()
        }
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
        
        // Update satellite positions and render Metal swarm
        let deltaTime = time - lastUpdateTime
        if deltaTime >= qualityLevel.updateInterval {
            updateSatellites()
            lastUpdateTime = time
        }
        
        // Render Metal swarm directly into SceneKit's render context
        if useMetalRendering, let metalRenderer = metalRenderer, let cameraNode = cameraNode {
            metalRenderer.render(into: renderer, camera: cameraNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // Pre-render hook - Metal rendering happens here for proper layering
        if useMetalRendering, let metalRenderer = metalRenderer, let cameraNode = cameraNode {
            metalRenderer.render(into: renderer, camera: cameraNode)
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
    case low = 0
    case medium = 1
    case high = 2
    case ultra = 3
    
    static func < (lhs: HardwareTier, rhs: HardwareTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Quality Level

enum QualityLevel: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case ultra = 3
    
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
