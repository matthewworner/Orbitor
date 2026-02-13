import SpriteKit
import AppKit

/// Enhanced Head-Up Display for the screensaver with Mission Control aesthetic
class HUDOverlay: SKScene {
    
    // MARK: - UI Components
    
    private var backgroundLayer: SKNode!
    private var statsPanel: StatsPanel!
    private var infoCard: InfoCardView!
    private var discoveryBanner: DiscoveryBanner!
    private var factOverlay: FactOverlay!
    private var modeLabel: SKLabelNode!
    private var gridOverlay: SKShapeNode!
    
    // Achievement callback
    private var achievementManager = AchievementManager.shared
    
    // Settings
    var infoDensity: InfoDensity = .moderate {
        didSet { updateVisibility() }
    }
    
    // Update timer
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 0.5
    
    // Current state
    private var currentAltitude: Double = 400  // km
    private var currentVelocity: Double = 7.8 // km/s
    private var currentZone: OrbitalZone = .leo
    private var satelliteCount: Int = 0
    
    // MARK: - Initialization
    
    override init(size: CGSize) {
        super.init(size: size)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        
        // Background layer with grid
        setupBackground()
        
        // Stats panel (top-left)
        statsPanel = StatsPanel()
        statsPanel.position = CGPoint(x: 20, y: size.height - 150)
        addChild(statsPanel)
        
        // Info card (right side, contextual)
        infoCard = InfoCardView()
        infoCard.position = CGPoint(x: size.width - 240, y: size.height - 120)
        addChild(infoCard)
        
        // Discovery banner (center)
        discoveryBanner = DiscoveryBanner()
        discoveryBanner.position = CGPoint(x: size.width / 2 - 140, y: size.height / 2 + 50)
        addChild(discoveryBanner)
        
        // Fact overlay (bottom center)
        factOverlay = FactOverlay()
        factOverlay.position = CGPoint(x: size.width / 2 - 160, y: 80)
        addChild(factOverlay)
        
        // Mode label (bottom right)
        setupModeLabel()
        
        // Setup achievement callbacks
        setupAchievementCallbacks()
        
        // Start update timer
        startUpdateTimer()
        
        // Initial visibility update
        updateVisibility()
        
        #if DEBUG
        print("🎯 HUDOverlay: Initialized with Mission Control theme")
        #endif
    }
    
    private func setupBackground() {
        backgroundLayer = SKNode()
        backgroundLayer.zPosition = -100
        addChild(backgroundLayer)
        
        // Subtle grid overlay
        let gridWidth: CGFloat = 200
        let gridHeight: CGFloat = 150
        let gridPath = CGMutablePath()
        
        // Horizontal lines
        for i in 0..<6 {
            let y = CGFloat(i) * (gridHeight / 5)
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: gridWidth, y: y))
        }
        
        // Vertical lines
        for i in 0..<7 {
            let x = CGFloat(i) * (gridWidth / 6)
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: gridHeight))
        }
        
        gridOverlay = SKShapeNode(path: gridPath)
        gridOverlay.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.1)
        gridOverlay.lineWidth = 0.5
        gridOverlay.position = CGPoint(x: 20, y: size.height - 160)
        gridOverlay.alpha = 0.5
        backgroundLayer.addChild(gridOverlay)
    }
    
    private func setupModeLabel() {
        modeLabel = SKLabelNode(fontNamed: "SF Mono")
        modeLabel.fontSize = 10
        modeLabel.fontColor = MissionControlTheme.textMuted
        modeLabel.text = "MODE: CINEMATIC_AUTO"
        modeLabel.horizontalAlignmentMode = .right
        modeLabel.verticalAlignmentMode = .bottom
        modeLabel.position = CGPoint(x: size.width - 20, y: 20)
        addChild(modeLabel)
    }
    
    private func setupAchievementCallbacks() {
        achievementManager.onAchievementUnlocked = { [weak self] achievement in
            self?.discoveryBanner.showAchievement(achievement)
        }
    }
    
    // MARK: - Update Timer
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }
    
    private func updateDisplay() {
        // Update stats panel
        statsPanel.update(
            satelliteCount: satelliteCount,
            altitude: currentAltitude,
            velocity: currentVelocity,
            zone: currentZone
        )
    }
    
    // MARK: - Visibility
    
    private func updateVisibility() {
        switch infoDensity {
        case .minimal:
            statsPanel.alpha = 1
            infoCard.alpha = 0
            factOverlay.alpha = 0
            gridOverlay.alpha = 0
        case .moderate:
            statsPanel.alpha = 1
            infoCard.alpha = 1
            factOverlay.alpha = 0
            gridOverlay.alpha = 0.5
        case .educational:
            statsPanel.alpha = 1
            infoCard.alpha = 1
            factOverlay.alpha = 1
            gridOverlay.alpha = 0.5
            factOverlay.startAutoShow()
        }
    }
    
    // MARK: - Layout
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        // Reposition elements
        statsPanel.position = CGPoint(x: 20, y: size.height - 150)
        infoCard.position = CGPoint(x: size.width - 240, y: size.height - 120)
        discoveryBanner.position = CGPoint(x: size.width / 2 - 140, y: size.height / 2 + 50)
        factOverlay.position = CGPoint(x: size.width / 2 - 160, y: 80)
        modeLabel.position = CGPoint(x: size.width - 20, y: 20)
        gridOverlay.position = CGPoint(x: 20, y: size.height - 160)
    }
    
    // MARK: - Public Updates
    
    /// Update satellite count
    func updateStats(count: Int) {
        satelliteCount = count
    }
    
    /// Update camera position data
    func updateCamera(altitude: Double, velocity: Double) {
        currentAltitude = altitude
        currentVelocity = velocity
        currentZone = zoneForAltitude(altitude)
    }
    
    /// Show a satellite info card
    func showSatellite(_ satellite: NotableSatellite) {
        guard infoDensity != .minimal else { return }
        
        infoCard.showSatellite(satellite)
        
        // Track for achievements
        achievementManager.trackSatelliteSpotted(
            name: satellite.name,
            country: satellite.country,
            type: satellite.type.rawValue,
            altitude: currentAltitude
        )
    }
    
    /// Show orbital zone info
    func showZone(_ zone: OrbitalZone) {
        guard infoDensity != .minimal else { return }
        
        currentZone = zone
        infoCard.showZone(zone)
    }
    
    /// Hide info card
    func hideInfoCard() {
        infoCard.hide()
    }
    
    /// Show a discovery notification
    func showDiscovery(name: String, description: String) {
        discoveryBanner.showDiscovery(name: name, description: description)
    }
    
    /// Show a fact
    func showFact(_ fact: EducationalFact) {
        guard infoDensity == .educational else { return }
        factOverlay.showFact(fact)
    }
    
    /// Enable/disable educational facts
    func setEducationalFacts(enabled: Bool, frequency: FactOverlay.FactFrequency = .medium) {
        factOverlay.setAutoShow(enabled)
        factOverlay.updateFrequency(frequency)
    }
    
    // MARK: - Helpers
    
    private func zoneForAltitude(_ altitude: Double) -> OrbitalZone {
        if altitude <= 2000 {
            return .leo
        } else if altitude <= 35786 {
            return .meo
        } else {
            return .geo
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        updateTimer?.invalidate()
        factOverlay.stopAutoShow()
    }
}

// MARK: - Extension for old API compatibility

extension HUDOverlay {
    
    /// Legacy update method for compatibility
    func updateTarget(_ name: String, coordinates: String) {
        // Check if it's a notable satellite
        if let satellite = NotableSatellites.find(name: name) {
            showSatellite(satellite)
        }
    }
    
    /// Legacy update method for compatibility  
    func updateStats(satelliteCount: Int, fps: Int) {
        self.satelliteCount = satelliteCount
    }
}
