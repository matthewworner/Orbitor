import ScreenSaver
import SceneKit

/// Kubrick Cinematic Screensaver
/// Refactored: delegates to specialized modules for scene building, satellite creation, and orbital simulation
class KubrickView: ScreenSaverView, SCNSceneRendererDelegate {
    
    // MARK: - Properties
    
    private var sceneView: SCNView!
    private var scene: SCNScene!
    private var cameraPivot: SCNNode!
    
    private var setupComplete: Bool = false
    
    // Specialized modules (extracted from original monolithic KubrickView)
    private lazy var sceneBuilder: SceneBuilder = SceneBuilder(scene: scene, sceneView: sceneView)
    private lazy var orbitSimulator: SatelliteOrbitSimulator = SatelliteOrbitSimulator(scene: scene)
    
    private var animationTime: Double = 0
    private var lastUpdateTime: TimeInterval = 0
    
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
        
        // Create scene
        scene = SCNScene()
        
        // Setup camera via SceneBuilder
        let (pivot, _) = sceneBuilder.setupCamera()
        cameraPivot = pivot
        
        // Create SCNView
        sceneView = sceneBuilder.createSceneView(frame: bounds, delegate: self)
        addSubview(sceneView)
        
        // Build scene via SceneBuilder
        _ = sceneBuilder.addEarth()
        let (_, sunPos) = sceneBuilder.addSun()
        sceneBuilder.addStarfield()
        sceneBuilder.addPlanets()
        sceneBuilder.addLighting(sunPosition: sunPos)
        
        // Create satellites via OrbitSimulator
        orbitSimulator.createSatellites()
        
        setupComplete = true
        print("🎬 [Kubrick] Setup complete! Satellites: \(orbitSimulator.satelliteCount)")
    }
    
    // MARK: - Animation
    
    override func animateOneFrame() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update orbital simulation
        animationTime = orbitSimulator.update(deltaTime: delta)
        
        // Camera orbit
        cameraPivot.eulerAngles.y += CGFloat(0.003)
    }
    
    // MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called for each frame - animation handled in animateOneFrame()
    }
    
    // MARK: - Configuration
    
    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}