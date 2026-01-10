import UIKit
import SceneKit
import Metal

class NatureVsNoiseViewController: UIViewController {

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

    // Hardware detection
    private lazy var hardwareCapabilities: HardwareCapabilities = detectHardware()

    private var animationTime: Double = 0
    private var displayLink: CADisplayLink?

    // Audio
    private var audioController: AudioController?

    // UI
    private var hudOverlay: HUDOverlay?

    // Quality settings
    private var qualityLevel: QualityLevel = .high

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        // Create SceneKit view
        sceneView = SCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        view.addSubview(sceneView)

        // Create scene
        scene = SCNScene()
        sceneView.scene = scene

        // Setup camera
        setupCamera()

        // Initialize camera controller
        cameraController = CameraController(scene: scene, cameraNode: cameraNode, cameraPivot: cameraPivot)

        // Initialize satellite manager with bundle for resource loading
        satelliteManager = SatelliteManager(bundle: Bundle(for: type(of: self)))

        // Initialize renderers based on hardware capabilities
        setupRenderers()

        // Add celestial bodies
        addSolarSystem()
        addSatellites()
        addStarfield()

        // Start cinematic camera sequence
        cameraController.startCinematicSequence()

        // Start animation
        sceneView.isPlaying = true

        // Setup animation timer for satellite updates
        setupAnimationTimer()

        // Initialize Audio System (Phase 3) - Default ON for tvOS
        audioController = AudioController()

        // Initialize UI (Phase 3) - Minimal for tvOS
        hudOverlay = HUDOverlay(size: view.bounds.size)
        sceneView.overlaySKScene = hudOverlay

        #if DEBUG
        print("🚀 NatureVsNoiseViewController: Initialized")
        print("   Hardware: \(hardwareCapabilities)")
        print("   Metal Rendering: \(useMetalRendering ? "ENABLED" : "DISABLED (SceneKit fallback)")")
        print("   Quality Level: \(qualityLevel)")
        #endif
    }

    /// Setup renderers based on hardware capabilities
    private func setupRenderers() {
        // Try Metal first for best performance
        if hardwareCapabilities.supportsAppleSilicon {
            metalRenderer = MetalSatelliteRenderer()
            if metalRenderer != nil {
                useMetalRendering = true
                qualityLevel = .ultra

                // Configure Metal renderer
                metalRenderer?.earthPosition = SIMD3<Float>(30, 0, 0)
                metalRenderer?.showTrails = true
                metalRenderer?.trailLength = 2.0
                metalRenderer?.setTimeAcceleration(Float(satelliteManager.timeAcceleration))

                #if DEBUG
                print("✅ Metal renderer initialized for Apple Silicon")
                #endif
            }
        }

        // Always initialize SceneKit renderer as fallback
        satelliteRenderer = SatelliteRenderer(scene: scene)

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

        // Bloom settings
        cameraNode.camera?.bloomIntensity = 1.5
        cameraNode.camera?.bloomThreshold = 0.8 // Only bright objects bloom (Sun, lights, satellites)
        cameraNode.camera?.bloomBlurRadius = 16.0

        // Create a pivot node for orbital rotation
        // Camera will be offset from pivot, and rotating the pivot creates orbital motion
        cameraPivot = SCNNode()
        cameraPivot.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraPivot)

        // PBR Lighting Environment
        // Simulates light coming from stars/galaxy
        scene.lightingEnvironment.contents = UIColor(white: 0.02, alpha: 1.0) // Very dark ambient
        scene.lightingEnvironment.intensity = 1.0

        // Minimal ambient light fill (for shadowed sides of planets)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 50 // Reduced from 100
        ambientLight.light?.color = UIColor(white: 0.2, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
    }

    // MARK: - Solar System

    private func addSolarSystem() {
        // CRITICAL: Add Sun explicitly first (not in allPlanets array)
        let sunNode = PlanetFactory.createPlanet(PlanetFactory.PlanetData.sun)
        scene.rootNode.addChildNode(sunNode)

        // Point light emanating from Sun
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .omni
        sunLight.light?.intensity = 2000
        sunLight.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        sunLight.light?.attenuationStartDistance = 0
        sunLight.light?.attenuationEndDistance = 500
        sunLight.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(sunLight)

        // Add all 8 planets
        for planetData in PlanetFactory.PlanetData.allPlanets {
            let planetNode = PlanetFactory.createPlanet(planetData)
            scene.rootNode.addChildNode(planetNode)

            // Special handling for Earth - add cloud layer
            if planetData.name == "Earth" {
                addEarthClouds(parent: planetNode)
            }
        }
    }

    private func addEarthClouds(parent: SCNNode) {
        let cloudGeometry = SCNSphere(radius: 2.02) // Slightly larger than Earth
        cloudGeometry.segmentCount = 64

        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = UIColor.clear
        cloudMaterial.transparent.contents = UIColor.white
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

    // MARK: - Starfield

    private func addStarfield() {
        // Create a simple black background sphere
        let backgroundGeometry = SCNSphere(radius: 5000)
        backgroundGeometry.segmentCount = 16

        let backgroundMaterial = SCNMaterial()
        backgroundMaterial.diffuse.contents = UIColor.black
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
        let starCount = 2000
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
            starMaterial.emission.contents = UIColor(
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

        let earthOffset = SIMD3<Float>(x: 30, y: 0, z: 0)
        let maxSatellites = qualityLevel.maxSatellites

        for satellite in satelliteManager.satellites.prefix(maxSatellites) {
            let (position, velocity) = satelliteManager.getPositionAndVelocity(for: satellite, at: animationTime)

            positions.append(SIMD3<Float>(position))
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

    private func loadTexture(named name: String) -> UIImage? {
        let bundle = Bundle(for: type(of: self))

        // Priority 1: Bundle resources root
        if let bundlePath = bundle.path(forResource: name, ofType: "jpg") {
            return UIImage(contentsOfFile: bundlePath)
        }
        if let bundlePath = bundle.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: bundlePath)
        }

        // Priority 2: Bundle's Resources/Textures/8K subdirectory
        if let resourcePath = bundle.resourcePath {
            let texturePaths = [
                "\(resourcePath)/Textures/8K/\(name).jpg",
                "\(resourcePath)/Textures/8K/\(name).png"
            ]
            for path in texturePaths {
                if FileManager.default.fileExists(atPath: path) {
                    return UIImage(contentsOfFile: path)
                }
            }
        }

        // Priority 3: Development fallback (project directory)
        let projectPaths = [
            "/Users/pro/Projects/screensaver/Resources/Textures/8K/\(name).jpg",
            "/Users/pro/Projects/screensaver/Resources/Textures/8K/\(name).png"
        ]

        for path in projectPaths {
            if FileManager.default.fileExists(atPath: path) {
                return UIImage(contentsOfFile: path)
            }
        }

        #if DEBUG
        print("⚠️ NatureVsNoiseViewController: Texture '\(name)' not found")
        #endif

        return nil
    }

    // MARK: - Animation

    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateFrame() {
        // Update Audio System
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

        // Trigger mission voice clips (Phase 4)
        triggerMissionClips(for: nearest)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        sceneView?.frame = CGRect(origin: .zero, size: size)
        hudOverlay?.updateLayout(for: size)
    }

    private func findNearestPlanet(to position: SCNVector3) -> SCNNode? {
        // Simple heuristic based on X position
        // This relies on the linear layout of current implementation
        var minDistance: Float = 10000
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

    // MARK: - Siri Remote Controls

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [sceneView]
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .select:
                // Show settings menu
                showSettings()
            case .menu:
                // Exit app (tvOS behavior)
                dismiss(animated: true)
            case .playPause:
                // Toggle audio
                toggleAudio()
            default:
                break
            }
        }
        super.pressesBegan(presses, with: event)
    }

    private func showSettings() {
        // TODO: Implement tvOS settings UI
        #if DEBUG
        print("📺 Settings menu requested")
        #endif
    }

    private func toggleAudio() {
        audioController?.toggleMute()
        #if DEBUG
        print("🔊 Audio toggled")
        #endif
    }

    private func triggerMissionClips(for planet: SCNNode?) {
        guard let planetName = planet?.name, let audioController = audioController else { return }

        // Trigger appropriate mission clips based on planet
        switch planetName {
        case "Earth":
            // Play ISS or Apollo clip occasionally
            if Int.random(in: 0...100) < 5 { // 5% chance
                audioController.playMissionClip("iss_construction")
            }
        case "Mars":
            // Play Perseverance landing clip
            if Int.random(in: 0...100) < 10 { // 10% chance
                audioController.playMissionClip("perseverance_mars_landing")
            }
        case "Jupiter":
            // Play Voyager clip
            if Int.random(in: 0...100) < 3 { // 3% chance
                audioController.playMissionClip("voyager_golden_record")
            }
        default:
            break
        }
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
        case .low: return 5000
        case .medium: return 15000
        case .high: return 30000
        case .ultra: return 50000
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