import SpriteKit
import AppKit

/// Head-Up Display for the screensaver — "Astra" Mission Control redesign.
///
/// Layout (corner-anchored over the live 3D scene):
///   • top-left      mission title + live UTC clock + TRACKING pill + OS footer
///   • top-right     telemetry dashboard (total + ACTIVE/DEBRIS/DECAY) — `StatsPanel`
///   • bottom-left   contextual focus (NAME / ALT / VEL / INCL)
///   • bottom-right  classification legend (live counts per class)
///   • center        focus brackets; a slow scanline + footer coord strip overlay
class HUDOverlay: SKScene {

    // MARK: - UI Components

    private var backgroundLayer: SKNode!
    private var statsPanel: StatsPanel!               // top-right telemetry dashboard
    private var focusPanel: ContextualFocusPanel!     // bottom-left
    private var legendPanel: ClassificationLegend!     // bottom-right
    private var infoCard: InfoCardView!               // contextual dossier
    private var discoveryBanner: DiscoveryBanner!
    private var factOverlay: FactOverlay!
    private var gridOverlay: SKShapeNode!
    private var scanline: SKShapeNode!
    private var ambientTicker: AmbientTicker!

    // Top-left mission cluster
    private var missionPanel: GlassPanel!
    private var clockLabel: SKLabelNode!
    private var trackingDot: SKShapeNode!
    private var osFooter: SKLabelNode!
    private var footerStrip: SKLabelNode!

    // Center focus brackets
    private var focusReticle: SKNode!

    // Settings
    var infoDensity: InfoDensity = .moderate {
        didSet { updateVisibility() }
    }

    // Update timer
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 0.5

    // Current state
    private var currentAltitude: Double = 400  // km
    private var currentVelocity: Double = 7.8  // km/s
    private var currentInclination: Double = 51.6 // deg (focused object)
    private var currentFocusName: String = "DEEP SPACE"
    private var currentZone: OrbitalZone = .leo
    private var satelliteCount: Int = 0
    private var census: SatelliteManager.OrbitalCensus?

    private let utcFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

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

        // Register bundled JetBrains Mono (falls back to system mono if missing)
        MissionControlTheme.registerFonts(in: Bundle(for: HUDOverlay.self))

        setupBackground()
        setupMissionCluster()
        setupFocusReticle()

        // Top-right telemetry dashboard
        statsPanel = StatsPanel()
        addChild(statsPanel)

        // Bottom-left contextual focus
        focusPanel = ContextualFocusPanel()
        addChild(focusPanel)

        // Bottom-right classification legend
        legendPanel = ClassificationLegend()
        addChild(legendPanel)

        // Contextual dossier card (right, appears on focus)
        infoCard = InfoCardView()
        addChild(infoCard)

        // Discovery banner (center)
        discoveryBanner = DiscoveryBanner()
        addChild(discoveryBanner)

        // Fact overlay (bottom center)
        factOverlay = FactOverlay()
        addChild(factOverlay)

        // Footer coordinate strip
        footerStrip = SKLabelNode.hudLabel("COORD_REF: GRS80   |   VECTOR_SYNC: ENABLED   |   SENSOR_FEED: OPTICAL_PRIMARY",
                                           size: 8, color: MissionControlTheme.textMuted.withAlphaComponent(0.5),
                                           hAlign: .center, vAlign: .bottom)
        addChild(footerStrip)

        // Ambient ticker (slim one-liner above the footer strip)
        ambientTicker = AmbientTicker()
        addChild(ambientTicker)

        layoutComponents()
        startUpdateTimer()
        updateVisibility()
        presentBootSequence()
    }

    private var bootOverlay: BootSequenceOverlay?

    /// Show the boot sequence on first appearance, then fade into the live HUD.
    private func presentBootSequence() {
        let boot = BootSequenceOverlay(size: size)
        boot.zPosition = 1000
        addChild(boot)
        bootOverlay = boot
        boot.start { [weak self] in
            self?.bootOverlay?.removeFromParent()
            self?.bootOverlay = nil
        }
    }

    private func setupBackground() {
        backgroundLayer = SKNode()
        backgroundLayer.zPosition = -100
        addChild(backgroundLayer)

        // Faint full-screen telemetry grid
        gridOverlay = SKShapeNode()
        gridOverlay.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.04)
        gridOverlay.lineWidth = 0.5
        gridOverlay.alpha = 1
        backgroundLayer.addChild(gridOverlay)

        // Slow scanline sweeping top → bottom
        scanline = SKShapeNode()
        scanline.fillColor = MissionControlTheme.primarySoft.withAlphaComponent(0.05)
        scanline.strokeColor = .clear
        scanline.zPosition = 1
        backgroundLayer.addChild(scanline)
    }

    private func setupMissionCluster() {
        missionPanel = GlassPanel(size: CGSize(width: 330, height: 70))
        addChild(missionPanel)
        let c = missionPanel.content

        let title = SKLabelNode.hudLabel("NATURE'S CALM vs. HUMANITY'S NOISE", size: 9,
                                         color: MissionControlTheme.primarySoftColor, weight: .bold)
        title.position = CGPoint(x: 14, y: 70 - 18)
        c.addChild(title)

        let clockCaption = SKLabelNode.hudLabel("SYSTEM_TIME_UTC", size: 8, color: MissionControlTheme.textMut)
        clockCaption.position = CGPoint(x: 14, y: 70 - 34)
        c.addChild(clockCaption)

        clockLabel = SKLabelNode.hudLabel("00:00:00", size: 18, color: MissionControlTheme.white)
        clockLabel.position = CGPoint(x: 14, y: 70 - 54)
        c.addChild(clockLabel)

        // TRACKING pill (right side)
        let pill = SKShapeNode(rect: CGRect(x: 330 - 96, y: 70 - 50, width: 84, height: 20), cornerRadius: 3)
        pill.fillColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.12)
        pill.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.3)
        pill.lineWidth = 1
        c.addChild(pill)

        trackingDot = SKShapeNode(circleOfRadius: 3)
        trackingDot.fillColor = MissionControlTheme.primaryCyan
        trackingDot.strokeColor = .clear
        trackingDot.position = CGPoint(x: 330 - 86, y: 70 - 40)
        c.addChild(trackingDot)
        trackingDot.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 1.0), .fadeAlpha(to: 1.0, duration: 1.0)
        ])))

        let pillLabel = SKLabelNode.hudLabel("TRACKING", size: 9, color: MissionControlTheme.primaryCyan, weight: .bold)
        pillLabel.position = CGPoint(x: 330 - 76, y: 70 - 40)
        c.addChild(pillLabel)

        // OS version footer (below the panel)
        osFooter = SKLabelNode.hudLabel("OS_VERSION: v4.2.0-STABLE     LINK: ACTIVE_DOWNLINK",
                                        size: 8, color: MissionControlTheme.primarySoft.withAlphaComponent(0.4))
    }

    private func setupFocusReticle() {
        focusReticle = SKNode()
        focusReticle.alpha = 0.18
        focusReticle.zPosition = -50
        addChild(focusReticle)

        let box: CGFloat = 230
        let corner: CGFloat = 16
        let outline = SKShapeNode(rect: CGRect(x: -box/2, y: -box/2, width: box, height: box))
        outline.strokeColor = MissionControlTheme.primarySoft.withAlphaComponent(0.25)
        outline.lineWidth = 0.5
        focusReticle.addChild(outline)

        // Corner ticks
        let pts: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-box/2, box/2, corner, -corner), (box/2, box/2, -corner, -corner),
            (-box/2, -box/2, corner, corner), (box/2, -box/2, -corner, corner)
        ]
        for (x, y, dx, dy) in pts {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x + dx, y: y)); p.addLine(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y + dy))
            let tick = SKShapeNode(path: p)
            tick.strokeColor = MissionControlTheme.primarySoftColor
            tick.lineWidth = 1.5
            focusReticle.addChild(tick)
        }

        let label = SKLabelNode.hudLabel("AZIMUTH_LOCK_ENABLED", size: 8,
                                         color: MissionControlTheme.primarySoftColor, hAlign: .center, vAlign: .bottom)
        label.position = CGPoint(x: 0, y: box/2 + 6)
        focusReticle.addChild(label)
    }

    // MARK: - Layout

    private func layoutComponents() {
        let m: CGFloat = 20

        missionPanel.position = CGPoint(x: m, y: size.height - m - 70)
        osFooter.position = CGPoint(x: m + 2, y: size.height - m - 70 - 14)
        if osFooter.parent == nil { addChild(osFooter) }

        statsPanel.position = CGPoint(x: size.width - m - StatsPanel.panelWidth,
                                      y: size.height - m - StatsPanel.panelHeight)

        focusPanel.position = CGPoint(x: m, y: m)
        legendPanel.position = CGPoint(x: size.width - m - ClassificationLegend.panelWidth, y: m)

        infoCard.position = CGPoint(x: size.width - m - 240, y: size.height / 2 + 20)
        discoveryBanner.position = CGPoint(x: size.width / 2 - 140, y: size.height / 2 + 80)
        factOverlay.position = CGPoint(x: size.width / 2 - 160, y: 96)
        footerStrip.position = CGPoint(x: size.width / 2, y: 6)

        focusReticle.position = CGPoint(x: size.width / 2, y: size.height / 2)

        // Ambient ticker sits just above the footer coord strip, left-anchored from center.
        ambientTicker.position = CGPoint(x: size.width / 2 - 150, y: 22)

        rebuildBackground()
    }

    private func rebuildBackground() {
        // Grid spanning the screen
        let gridPath = CGMutablePath()
        let stepX: CGFloat = 33.3, stepY: CGFloat = 30
        var x: CGFloat = 0
        while x <= size.width { gridPath.move(to: CGPoint(x: x, y: 0)); gridPath.addLine(to: CGPoint(x: x, y: size.height)); x += stepX }
        var y: CGFloat = 0
        while y <= size.height { gridPath.move(to: CGPoint(x: 0, y: y)); gridPath.addLine(to: CGPoint(x: size.width, y: y)); y += stepY }
        gridOverlay.path = gridPath

        // Scanline bar + animation
        let barH: CGFloat = 90
        scanline.path = CGPath(rect: CGRect(x: 0, y: 0, width: size.width, height: barH), transform: nil)
        scanline.removeAllActions()
        scanline.position = CGPoint(x: 0, y: size.height)
        let sweep = SKAction.sequence([
            SKAction.moveTo(y: -barH, duration: 8.0),
            SKAction.moveTo(y: size.height, duration: 0)
        ])
        scanline.run(.repeatForever(sweep))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard missionPanel != nil else { return }
        layoutComponents()
        bootOverlay?.relayout(size: size)
    }

    // MARK: - Update Timer

    /// Start (or restart) the HUD update timer. Idempotent — safe to call from
    /// `startAnimation()` after a prior `stopAnimation()`.
    func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }

    private var tickCounter = 0

    private func updateDisplay() {
        clockLabel.text = utcFormatter.string(from: Date())
        if let census = census {
            statsPanel.update(census: census)
            legendPanel.update(census: census)
        }
        focusPanel.update(name: currentFocusName,
                          altitude: currentAltitude,
                          velocity: currentVelocity,
                          inclination: currentInclination)

        // Rotate the ambient ticker every ~6s (timer fires every 0.5s).
        tickCounter += 1
        if tickCounter % 12 == 1 {
            ambientTicker.rotate(census: census)
        }
    }

    // MARK: - Visibility

    private func updateVisibility() {
        switch infoDensity {
        case .minimal:
            statsPanel.alpha = 1; focusPanel.alpha = 1; legendPanel.alpha = 0.0
            missionPanel.alpha = 1; osFooter?.alpha = 0
            infoCard.alpha = 0; factOverlay.alpha = 0
            gridOverlay.alpha = 0; scanline.alpha = 0; focusReticle.alpha = 0; footerStrip.alpha = 0
            ambientTicker?.alpha = 0
        case .moderate:
            statsPanel.alpha = 1; focusPanel.alpha = 1; legendPanel.alpha = 1
            missionPanel.alpha = 1; osFooter?.alpha = 1
            infoCard.alpha = 1; factOverlay.alpha = 0
            gridOverlay.alpha = 1; scanline.alpha = 1; focusReticle.alpha = 0.18; footerStrip.alpha = 1
            ambientTicker?.alpha = 1
        case .educational:
            statsPanel.alpha = 1; focusPanel.alpha = 1; legendPanel.alpha = 1
            missionPanel.alpha = 1; osFooter?.alpha = 1
            infoCard.alpha = 1; factOverlay.alpha = 1
            gridOverlay.alpha = 1; scanline.alpha = 1; focusReticle.alpha = 0.18; footerStrip.alpha = 1
            ambientTicker?.alpha = 1
            factOverlay.startAutoShow()
        }
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

    /// Update the orbital census used by the telemetry dashboard + classification legend.
    func updateCensus(_ census: SatelliteManager.OrbitalCensus) {
        self.census = census
    }

    /// Update the contextual-focus readout (bottom-left panel).
    func updateFocus(name: String, inclination: Double) {
        currentFocusName = name
        currentInclination = inclination
    }

    /// Show a satellite info card
    func showSatellite(_ satellite: NotableSatellite) {
        guard infoDensity != .minimal else { return }
        infoCard.showSatellite(satellite)
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

    /// Stop update timer - called when screensaver is disabled
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        factOverlay.stopAutoShow()
    }

    deinit {
        updateTimer?.invalidate()
        factOverlay?.stopAutoShow()
    }
}

// MARK: - Extension for old API compatibility

extension HUDOverlay {

    /// Legacy update method for compatibility
    func updateTarget(_ name: String, coordinates: String) {
        if let satellite = NotableSatellites.find(name: name) {
            showSatellite(satellite)
        }
    }

    /// Legacy update method for compatibility
    func updateStats(satelliteCount: Int, fps: Int) {
        self.satelliteCount = satelliteCount
    }
}

// MARK: - ContextualFocusPanel (bottom-left)

/// Bottom-left focus readout: NAME / ALTITUDE / VELOCITY / INCLINATION.
final class ContextualFocusPanel: SKNode {

    static let panelWidth: CGFloat = 300
    static let panelHeight: CGFloat = 122

    private let panel: GlassPanel
    private let nameValue: SKLabelNode
    private let altValue: SKLabelNode
    private let velValue: SKLabelNode
    private let incValue: SKLabelNode

    override init() {
        panel = GlassPanel(size: CGSize(width: ContextualFocusPanel.panelWidth,
                                        height: ContextualFocusPanel.panelHeight))
        nameValue = .hudLabel("DEEP SPACE", size: 11, color: MissionControlTheme.gold, hAlign: .right)
        altValue  = .hudLabel("0 KM", size: 11, color: MissionControlTheme.white, hAlign: .right)
        velValue  = .hudLabel("0 KM/S", size: 11, color: MissionControlTheme.white, hAlign: .right)
        incValue  = .hudLabel("0°", size: 11, color: MissionControlTheme.white, hAlign: .right)
        super.init()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        panel = GlassPanel(size: CGSize(width: ContextualFocusPanel.panelWidth,
                                        height: ContextualFocusPanel.panelHeight))
        nameValue = SKLabelNode(); altValue = SKLabelNode(); velValue = SKLabelNode(); incValue = SKLabelNode()
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        let w = ContextualFocusPanel.panelWidth, h = ContextualFocusPanel.panelHeight
        addChild(panel)
        let c = panel.content

        let header = SKLabelNode.hudLabel("◎ CONTEXTUAL_FOCUS", size: 9,
                                          color: MissionControlTheme.gold)
        header.position = CGPoint(x: 14, y: h - 18)
        c.addChild(header)

        let rows: [(String, SKLabelNode)] = [("NAME", nameValue), ("ALTITUDE", altValue),
                                             ("VELOCITY", velValue), ("INCLINATION", incValue)]
        var y = h - 40
        for (label, value) in rows {
            let l = SKLabelNode.hudLabel(label, size: 10, color: MissionControlTheme.textMut)
            l.position = CGPoint(x: 14, y: y)
            c.addChild(l)
            value.position = CGPoint(x: w - 14, y: y)
            c.addChild(value)
            // hairline under each row except last
            if label != "INCLINATION" {
                let div = SKShapeNode(rect: CGRect(x: 14, y: y - 9, width: w - 28, height: 1))
                div.fillColor = MissionControlTheme.hairline.withAlphaComponent(0.3)
                div.strokeColor = .clear
                c.addChild(div)
            }
            y -= 22
        }
    }

    func update(name: String, altitude: Double, velocity: Double, inclination: Double) {
        nameValue.text = name.uppercased()
        altValue.text = String(format: "%.0f KM", altitude)
        velValue.text = String(format: "%.2f KM/S", velocity)
        incValue.text = String(format: "%.2f°", inclination)
    }
}

// MARK: - ClassificationLegend (bottom-right)

/// Bottom-right legend: color chip + class code + live count, one row per `SatelliteClass`.
final class ClassificationLegend: SKNode {

    static let panelWidth: CGFloat = 200

    private let panel: GlassPanel
    private var countLabels: [String: SKLabelNode] = [:]

    private static let rows = SatelliteClass.legendOrder
    private static var panelHeight: CGFloat { 30 + CGFloat(rows.count) * 22 + 12 }

    override init() {
        panel = GlassPanel(size: CGSize(width: ClassificationLegend.panelWidth,
                                        height: ClassificationLegend.panelHeight))
        super.init()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        panel = GlassPanel(size: CGSize(width: ClassificationLegend.panelWidth,
                                        height: ClassificationLegend.panelHeight))
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        let w = ClassificationLegend.panelWidth
        let h = ClassificationLegend.panelHeight
        addChild(panel)
        let c = panel.content

        let header = SKLabelNode.hudLabel("CLASSIFICATION", size: 9, color: MissionControlTheme.textMut)
        header.position = CGPoint(x: 14, y: h - 18)
        c.addChild(header)

        let div = SKShapeNode(rect: CGRect(x: 14, y: h - 26, width: w - 28, height: 1))
        div.fillColor = MissionControlTheme.hairlineColor
        div.strokeColor = .clear
        c.addChild(div)

        var y = h - 42
        for cls in ClassificationLegend.rows {
            let chip = SKShapeNode(rect: CGRect(x: 14, y: y - 5, width: 10, height: 10), cornerRadius: 2)
            chip.fillColor = cls.hudColor
            chip.strokeColor = .clear
            c.addChild(chip)

            let code = SKLabelNode.hudLabel(cls.legendCode, size: 10, color: MissionControlTheme.white)
            code.position = CGPoint(x: 32, y: y)
            c.addChild(code)

            let count = SKLabelNode.hudLabel("—", size: 10, color: MissionControlTheme.textSec, hAlign: .right)
            count.position = CGPoint(x: w - 14, y: y)
            c.addChild(count)
            countLabels[cls.legendCode] = count

            y -= 22
        }
    }

    func update(census: SatelliteManager.OrbitalCensus) {
        func set(_ cls: SatelliteClass, _ n: Int) { countLabels[cls.legendCode]?.text = format(n) }
        set(.iss, census.iss)
        set(.starlink, census.starlink)
        set(.notable(""), census.notable)
        set(.activeSatellite, census.active)
        set(.debris, census.debris)
    }

    private func format(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - BootSequenceOverlay

/// Opening "systems online" sequence: title + typed telemetry boot log + progress
/// line, shown for the first few seconds then faded out into the live scene.
final class BootSequenceOverlay: SKNode {

    private let backdrop: SKShapeNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private let logLabel: SKLabelNode
    private let progressTrack: SKShapeNode
    private let progressFill: SKShapeNode
    private let progressPct: SKLabelNode
    private var screenSize: CGSize

    private let logLines = [
        "Loading TLE catalog… 23,418 objects",
        "Propagating orbits (SGP4)…",
        "Renderer: SceneKit + Metal",
        "Connecting to Global Relay Network…",
        "Tracking online."
    ]

    init(size: CGSize) {
        screenSize = size
        backdrop = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        titleLabel = .hudLabel("NATURE'S CALM  vs.  HUMANITY'S NOISE", size: 22,
                               color: MissionControlTheme.primarySoftColor, weight: .bold,
                               hAlign: .center, vAlign: .center)
        subtitleLabel = .hudLabel("REAL-TIME VISUALIZATION OF 23,000+ OBJECTS ORBITING EARTH · DATA: CELESTRAK · SGP4",
                                  size: 9, color: MissionControlTheme.textSec, hAlign: .center, vAlign: .center)
        logLabel = .hudLabel("", size: 11, color: MissionControlTheme.primaryCyan, hAlign: .left, vAlign: .top)
        progressTrack = SKShapeNode()
        progressFill = SKShapeNode()
        progressPct = .hudLabel("0%", size: 10, color: MissionControlTheme.primarySoftColor, hAlign: .right, vAlign: .center)
        super.init()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        screenSize = .zero
        backdrop = SKShapeNode(); titleLabel = SKLabelNode(); subtitleLabel = SKLabelNode()
        logLabel = SKLabelNode(); progressTrack = SKShapeNode(); progressFill = SKShapeNode()
        progressPct = SKLabelNode()
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        backdrop.fillColor = NSColor(red: 5/255, green: 10/255, blue: 20/255, alpha: 0.92)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        logLabel.numberOfLines = 0
        logLabel.preferredMaxLayoutWidth = 360

        [titleLabel, subtitleLabel, logLabel, progressTrack, progressFill, progressPct].forEach { addChild($0) }
        relayout(size: screenSize)
    }

    func relayout(size: CGSize) {
        screenSize = size
        backdrop.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        let cx = size.width / 2, cy = size.height / 2
        titleLabel.position = CGPoint(x: cx, y: cy + 80)
        subtitleLabel.position = CGPoint(x: cx, y: cy + 50)
        logLabel.position = CGPoint(x: cx - 180, y: cy - 10)

        let barW: CGFloat = 360, barH: CGFloat = 3
        let barX = cx - barW / 2, barY = cy - 90
        progressTrack.path = CGPath(rect: CGRect(x: barX, y: barY, width: barW, height: barH), transform: nil)
        progressTrack.fillColor = MissionControlTheme.textMuted.withAlphaComponent(0.25)
        progressTrack.strokeColor = .clear
        progressPct.position = CGPoint(x: barX + barW, y: barY + 14)
        updateProgress(0, barX: barX, barY: barY, barW: barW, barH: barH)
    }

    private func updateProgress(_ p: CGFloat, barX: CGFloat, barY: CGFloat, barW: CGFloat, barH: CGFloat) {
        progressFill.path = CGPath(rect: CGRect(x: barX, y: barY, width: barW * p, height: barH), transform: nil)
        progressFill.fillColor = MissionControlTheme.primaryCyan
        progressFill.strokeColor = .clear
        progressPct.text = "\(Int(p * 100))%"
    }

    /// Run the sequence (~4s), then fade out and call `completion`.
    func start(completion: @escaping () -> Void) {
        let cx = screenSize.width / 2, cy = screenSize.height / 2
        let barW: CGFloat = 360, barH: CGFloat = 3
        let barX = cx - barW / 2, barY = cy - 90

        var actions: [SKAction] = [.wait(forDuration: 0.4)]
        var shown = ""
        let perLine = 0.55
        for (i, line) in logLines.enumerated() {
            actions.append(.run { [weak self] in
                shown += (shown.isEmpty ? "" : "\n") + "[BOOT] " + line
                self?.logLabel.text = shown
                let p = CGFloat(i + 1) / CGFloat(self?.logLines.count ?? 1)
                self?.updateProgress(p, barX: barX, barY: barY, barW: barW, barH: barH)
            })
            actions.append(.wait(forDuration: perLine))
        }
        actions.append(.wait(forDuration: 0.4))
        actions.append(.fadeOut(withDuration: 0.6))
        actions.append(.run { completion() })
        run(.sequence(actions))
    }
}

// MARK: - AmbientTicker (bottom-center, always-on)

/// Slim one-line ambient ticker: a small pulsing dot + rotating text — a census
/// stat or a short educational one-liner. Matches the Stitch "Orbital Ambient Ticker".
final class AmbientTicker: SKNode {

    private let dot: SKShapeNode
    private let label: SKLabelNode
    private var rotateIndex = 0

    override init() {
        dot = SKShapeNode(circleOfRadius: 3)
        label = .hudLabel("", size: 9, color: MissionControlTheme.textSec, hAlign: .left, vAlign: .center)
        super.init()
        dot.fillColor = MissionControlTheme.primaryCyan
        dot.strokeColor = .clear
        dot.position = CGPoint(x: 0, y: 0)
        addChild(dot)
        label.position = CGPoint(x: 12, y: 0)
        addChild(label)
        dot.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.3, duration: 1.2), .fadeAlpha(to: 1.0, duration: 1.2)
        ])))
    }

    required init?(coder aDecoder: NSCoder) {
        dot = SKShapeNode(); label = SKLabelNode()
        super.init(coder: aDecoder)
    }

    /// Advance to the next ticker message. Alternates census stats with facts.
    func rotate(census: SatelliteManager.OrbitalCensus?) {
        rotateIndex += 1
        let useStat = (rotateIndex % 2 == 0)
        if useStat, let c = census {
            let stats = [
                "STARLINK · \(format(c.starlink)) tracked",
                "DEBRIS · \(format(c.debris)) objects in orbit",
                "ACTIVE · \(format(c.activeTotal)) functioning craft",
                "TRACKED · \(format(c.total)) total objects"
            ]
            setText(stats[(rotateIndex / 2) % stats.count], color: MissionControlTheme.primaryCyan)
        } else {
            setText(EducationalFacts.randomFact().text, color: MissionControlTheme.textSec)
        }
    }

    private func setText(_ text: String, color: SKColor) {
        dot.fillColor = color
        label.text = text
        label.removeAllActions()
        label.alpha = 0
        label.run(.fadeIn(withDuration: 0.4))
    }

    private func format(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
