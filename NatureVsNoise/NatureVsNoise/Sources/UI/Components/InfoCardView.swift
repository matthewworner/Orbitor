import SpriteKit

/// Info card showing details about the current satellite or orbital zone
class InfoCardView: SKNode {
    
    // MARK: - UI Elements
    
    private var container: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var divider: SKShapeNode!
    private var detailsLabel: SKLabelNode!
    
    // Animation
    private var glowAction: SKAction?
    
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
        let cardWidth: CGFloat = 220
        let cardHeight: CGFloat = 100
        
        // Container
        let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight),
                          cornerWidth: MissionControlTheme.cornerRadius,
                          cornerHeight: MissionControlTheme.cornerRadius,
                          transform: nil)
        
        container = SKShapeNode(path: path)
        container.fillColor = MissionControlTheme.panelBg
        container.strokeColor = MissionControlTheme.amber.withAlphaComponent(0.6)
        container.lineWidth = 1
        container.alpha = 0
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        
        // Icon/emoji
        iconLabel = SKLabelNode(fontNamed: "SF Mono")
        iconLabel.fontSize = 24
        iconLabel.text = "🛰️"
        iconLabel.horizontalAlignmentMode = .left
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 15, y: cardHeight - 30)
        iconLabel.alpha = 0
        container.addChild(iconLabel)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "SF Mono")
        titleLabel.fontSize = 14
        titleLabel.fontColor = MissionControlTheme.amber
        titleLabel.text = "SATELLITE"
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 50, y: cardHeight - 25)
        titleLabel.alpha = 0
        container.addChild(titleLabel)
        
        // Subtitle (country or type)
        subtitleLabel = SKLabelNode(fontNamed: "SF Mono")
        subtitleLabel.fontSize = 10
        subtitleLabel.fontColor = MissionControlTheme.textMuted
        subtitleLabel.text = ""
        subtitleLabel.horizontalAlignmentMode = .left
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 50, y: cardHeight - 40)
        subtitleLabel.alpha = 0
        container.addChild(subtitleLabel)
        
        // Divider
        let dividerPath = CGMutablePath()
        dividerPath.move(to: CGPoint(x: 15, y: cardHeight - 52))
        dividerPath.addLine(to: CGPoint(x: cardWidth - 15, y: cardHeight - 52))
        divider = SKShapeNode(path: dividerPath)
        divider.strokeColor = MissionControlTheme.textMuted.withAlphaComponent(0.3)
        divider.lineWidth = 1
        divider.alpha = 0
        container.addChild(divider)
        
        // Details
        detailsLabel = SKLabelNode(fontNamed: "SF Mono")
        detailsLabel.fontSize = 10
        detailsLabel.fontColor = MissionControlTheme.textSecondary
        detailsLabel.text = ""
        detailsLabel.horizontalAlignmentMode = .left
        detailsLabel.verticalAlignmentMode = .top
        detailsLabel.position = CGPoint(x: 15, y: cardHeight - 65)
        detailsLabel.alpha = 0
        detailsLabel.preferredMaxLayoutWidth = cardWidth - 30
        container.addChild(detailsLabel)
        
        // Corner accent
        addCornerAccent(to: container, width: cardWidth, height: cardHeight)
    }
    
    private func addCornerAccent(to node: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Top-right corner accent
        let accentPath = CGMutablePath()
        accentPath.move(to: CGPoint(x: width - 20, y: height - 4))
        accentPath.addLine(to: CGPoint(x: width - 4, y: height - 4))
        accentPath.addLine(to: CGPoint(x: width - 4, y: height - 20))
        
        let accent = SKShapeNode(path: accentPath)
        accent.strokeColor = MissionControlTheme.amber.withAlphaComponent(0.5)
        accent.lineWidth = 2
        accent.alpha = 0
        accent.name = "cornerAccent"
        node.addChild(accent)
    }
    
    // MARK: - Show/Hide
    
    func showSatellite(_ satellite: NotableSatellite) {
        iconLabel.text = satellite.emoji
        titleLabel.text = satellite.name
        subtitleLabel.text = "\(satellite.type.rawValue) • \(satellite.country)"
        detailsLabel.text = satellite.description
        
        // Update border color based on type
        container.strokeColor = typeColor(for: satellite.type)
        
        animateIn()
    }
    
    func showZone(_ zone: OrbitalZone) {
        iconLabel.text = zoneIcon(for: zone)
        titleLabel.text = zone.description
        subtitleLabel.text = zone.altitudeRange
        detailsLabel.text = zoneDetails(for: zone)
        
        container.strokeColor = zone.color
        
        animateIn()
    }
    
    func hide() {
        animateOut()
    }
    
    private func typeColor(for type: SatelliteType) -> SKColor {
        switch type {
        case .crewed: return MissionControlTheme.magenta
        case .telescope: return MissionControlTheme.cyan
        case .navigation: return MissionControlTheme.amber
        case .communications: return .white
        case .earthObservation: return MissionControlTheme.other
        case .weather: return MissionControlTheme.usa
        case .military: return MissionControlTheme.russia
        case .constellation: return MissionControlTheme.cyan
        case .scientific: return MissionControlTheme.gold
        case .other: return .white
        }
    }
    
    private func zoneIcon(for zone: OrbitalZone) -> String {
        switch zone {
        case .leo: return "🟢"
        case .meo: return "🟡"
        case .geo: return "🟣"
        case .heo: return "🟠"
        }
    }
    
    private func zoneDetails(for zone: OrbitalZone) -> String {
        switch zone {
        case .leo:
            return "Fastest orbit zone\nMost crowded\nISS orbits here"
        case .meo:
            return "GPS orbits here\nMedium distance\nFewer satellites"
        case .geo:
            return "Stationary position\n24hr orbit\nTV satellites here"
        case .heo:
            return "Highly elliptical\nVariable altitude\nMolniya orbits"
        }
    }
    
    private func animateIn() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        container.run(fadeIn)
        
        iconLabel.run(SKAction.fadeIn(withDuration: 0.3))
        titleLabel.run(SKAction.fadeIn(withDuration: 0.3))
        subtitleLabel.run(SKAction.fadeIn(withDuration: 0.3))
        divider.run(SKAction.fadeIn(withDuration: 0.3))
        detailsLabel.run(SKAction.fadeIn(withDuration: 0.3))
        
        // Pulse the corner accent
        if let accent = container.childNode(withName: "cornerAccent") {
            accent.run(SKAction.fadeIn(withDuration: 0.3))
            
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ])
            accent.run(SKAction.repeatForever(pulse))
        }
    }
    
    private func animateOut() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        container.run(fadeOut)
        
        iconLabel.run(SKAction.fadeOut(withDuration: 0.3))
        titleLabel.run(SKAction.fadeOut(withDuration: 0.3))
        subtitleLabel.run(SKAction.fadeOut(withDuration: 0.3))
        divider.run(SKAction.fadeOut(withDuration: 0.3))
        detailsLabel.run(SKAction.fadeOut(withDuration: 0.3))
    }
}
