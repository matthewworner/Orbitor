import SpriteKit

/// Real-time statistics panel showing satellite counts and orbital data
class StatsPanel: SKNode {
    
    // MARK: - UI Elements
    
    private var container: SKShapeNode!
    private var titleLabel: SKLabelNode!
    private var satelliteCountLabel: SKLabelNode!
    private var altitudeLabel: SKLabelNode!
    private var velocityLabel: SKLabelNode!
    private var zoneIndicator: SKShapeNode!
    private var zoneLabel: SKLabelNode!
    
    // Animation
    private var pulseAction: SKAction?
    private var countUpAction: SKAction?
    
    // Current values for animation
    private var displayedCount: Int = 0
    private var targetCount: Int = 0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Create container with rounded rect
        let panelWidth: CGFloat = 180
        let panelHeight: CGFloat = 130
        
        let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                          cornerWidth: MissionControlTheme.cornerRadius,
                          cornerHeight: MissionControlTheme.cornerRadius,
                          transform: nil)
        
        container = SKShapeNode(path: path)
        container.fillColor = MissionControlTheme.panelBg
        container.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.5)
        container.lineWidth = 1
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "SF Mono")
        titleLabel.fontSize = 10
        titleLabel.fontColor = MissionControlTheme.textMuted
        titleLabel.text = "MISSION STATS"
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .top
        titleLabel.position = CGPoint(x: 12, y: panelHeight - 18)
        container.addChild(titleLabel)
        
        // Satellite count
        satelliteCountLabel = SKLabelNode(fontNamed: "SF Mono")
        satelliteCountLabel.fontSize = 18
        satelliteCountLabel.fontColor = MissionControlTheme.cyan
        satelliteCountLabel.text = "0"
        satelliteCountLabel.horizontalAlignmentMode = .left
        satelliteCountLabel.verticalAlignmentMode = .center
        satelliteCountLabel.position = CGPoint(x: 12, y: panelHeight - 50)
        container.addChild(satelliteCountLabel)
        
        let countSubtitle = SKLabelNode(fontNamed: "SF Mono")
        countSubtitle.fontSize = 8
        countSubtitle.fontColor = MissionControlTheme.textMuted
        countSubtitle.text = "OBJECTS TRACKED"
        countSubtitle.horizontalAlignmentMode = .left
        countSubtitle.verticalAlignmentMode = .center
        countSubtitle.position = CGPoint(x: 12, y: panelHeight - 65)
        container.addChild(countSubtitle)
        
        // Altitude
        altitudeLabel = SKLabelNode(fontNamed: "SF Mono")
        altitudeLabel.fontSize = 11
        altitudeLabel.fontColor = MissionControlTheme.textSecondary
        altitudeLabel.text = "ALT: 0 km"
        altitudeLabel.horizontalAlignmentMode = .left
        altitudeLabel.verticalAlignmentMode = .center
        altitudeLabel.position = CGPoint(x: 12, y: panelHeight - 85)
        container.addChild(altitudeLabel)
        
        // Velocity
        velocityLabel = SKLabelNode(fontNamed: "SF Mono")
        velocityLabel.fontSize = 11
        velocityLabel.fontColor = MissionControlTheme.textSecondary
        velocityLabel.text = "VEL: 0 km/s"
        velocityLabel.horizontalAlignmentMode = .left
        velocityLabel.verticalAlignmentMode = .center
        velocityLabel.position = CGPoint(x: 12, y: panelHeight - 102)
        container.addChild(velocityLabel)
        
        // Zone indicator
        zoneIndicator = SKShapeNode(circleOfRadius: 6)
        zoneIndicator.fillColor = MissionControlTheme.leo
        zoneIndicator.strokeColor = .clear
        zoneIndicator.position = CGPoint(x: panelWidth - 25, y: panelHeight - 25)
        container.addChild(zoneIndicator)
        
        zoneLabel = SKLabelNode(fontNamed: "SF Mono")
        zoneLabel.fontSize = 10
        zoneLabel.fontColor = MissionControlTheme.cyan
        zoneLabel.text = "LEO"
        zoneLabel.horizontalAlignmentMode = .left
        zoneLabel.verticalAlignmentMode = .center
        zoneLabel.position = CGPoint(x: panelWidth - 55, y: panelHeight - 28)
        container.addChild(zoneLabel)
        
        // Corner brackets decoration
        addCornerBrackets(to: container, width: panelWidth, height: panelHeight)
    }
    
    private func addCornerBrackets(to node: SKShapeNode, width: CGFloat, height: CGFloat) {
        let bracketLength: CGFloat = 10
        let inset: CGFloat = 4
        
        // Top-left
        let tlPath = CGMutablePath()
        tlPath.move(to: CGPoint(x: inset, y: height - inset - bracketLength))
        tlPath.addLine(to: CGPoint(x: inset, y: height - inset))
        tlPath.addLine(to: CGPoint(x: inset + bracketLength, y: height - inset))
        
        let tl = SKShapeNode(path: tlPath)
        tl.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.3)
        tl.lineWidth = 1
        node.addChild(tl)
        
        // Bottom-right
        let brPath = CGMutablePath()
        brPath.move(to: CGPoint(x: width - inset, y: inset + bracketLength))
        brPath.addLine(to: CGPoint(x: width - inset, y: inset))
        brPath.addLine(to: CGPoint(x: width - inset - bracketLength, y: inset))
        
        let br = SKShapeNode(path: brPath)
        br.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.3)
        br.lineWidth = 1
        node.addChild(br)
    }
    
    // MARK: - Updates
    
    func update(satelliteCount: Int, altitude: Double, velocity: Double, zone: OrbitalZone) {
        // Animate count
        if satelliteCount != displayedCount {
            animateCount(to: satelliteCount)
        }
        
        // Update altitude
        altitudeLabel.text = String(format: "ALT: %.0f km", altitude)
        
        // Update velocity
        velocityLabel.text = String(format: "VEL: %.1f km/s", velocity)
        
        // Update zone
        zoneLabel.text = zone.rawValue
        zoneIndicator.fillColor = zone.color
    }
    
    private func animateCount(to target: Int) {
        targetCount = target
        
        let duration: TimeInterval = 0.5
        let steps = 20
        let stepValue = Double(target - displayedCount) / Double(steps)
        
        displayedCount = target
        
        // Create custom action for counting
        let action = SKAction.customAction(withDuration: duration) { [weak self] _, elapsedTime in
            let progress = elapsedTime / CGFloat(duration)
            let currentValue = self?.displayedCount ?? 0
            let displayValue = Int(Double(currentValue) * Double(progress))
            self?.satelliteCountLabel.text = formatNumber(displayValue)
        }
        
        satelliteCountLabel.run(action)
    }
    
    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
    
    // MARK: - Pulse Animation
    
    func pulse() {
        let scaleUp = SKAction.scale(to: 1.02, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        container.run(pulse)
    }
}
