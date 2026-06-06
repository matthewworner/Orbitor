import SpriteKit

/// Contextual dossier card shown when the camera focuses a notable satellite or
/// orbital zone. Astra redesign: glass panel, type-colored accent border, mono type.
class InfoCardView: SKNode {

    static let cardWidth: CGFloat = 240
    static let cardHeight: CGFloat = 116

    private let panel: GlassPanel
    private let iconLabel: SKLabelNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private let detailsLabel: SKLabelNode
    private let statusDot: SKShapeNode
    private let statusLabel: SKLabelNode

    override init() {
        panel = GlassPanel(size: CGSize(width: InfoCardView.cardWidth, height: InfoCardView.cardHeight),
                           borderColor: MissionControlTheme.amber.withAlphaComponent(0.6))
        iconLabel = SKLabelNode(text: "🛰️")
        titleLabel = .hudLabel("SATELLITE", size: 14, color: MissionControlTheme.amber, weight: .bold)
        subtitleLabel = .hudLabel("", size: 10, color: MissionControlTheme.textMut)
        detailsLabel = .hudLabel("", size: 10, color: MissionControlTheme.textSec, vAlign: .top)
        statusDot = SKShapeNode(circleOfRadius: 3)
        statusLabel = .hudLabel("ACTIVE", size: 9, color: MissionControlTheme.other)
        super.init()
        setupUI()
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        panel = GlassPanel(size: CGSize(width: InfoCardView.cardWidth, height: InfoCardView.cardHeight))
        iconLabel = SKLabelNode(); titleLabel = SKLabelNode(); subtitleLabel = SKLabelNode()
        detailsLabel = SKLabelNode(); statusDot = SKShapeNode(); statusLabel = SKLabelNode()
        super.init(coder: aDecoder)
        setupUI()
        alpha = 0
    }

    private func setupUI() {
        let w = InfoCardView.cardWidth, h = InfoCardView.cardHeight
        addChild(panel)
        let c = panel.content

        iconLabel.fontSize = 22
        iconLabel.horizontalAlignmentMode = .left
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 14, y: h - 24)
        c.addChild(iconLabel)

        titleLabel.position = CGPoint(x: 46, y: h - 20)
        c.addChild(titleLabel)

        subtitleLabel.position = CGPoint(x: 46, y: h - 36)
        c.addChild(subtitleLabel)

        let div = SKShapeNode(rect: CGRect(x: 14, y: h - 50, width: w - 28, height: 1))
        div.fillColor = MissionControlTheme.hairlineColor
        div.strokeColor = .clear
        c.addChild(div)

        detailsLabel.position = CGPoint(x: 14, y: h - 60)
        detailsLabel.preferredMaxLayoutWidth = w - 28
        detailsLabel.numberOfLines = 0
        c.addChild(detailsLabel)

        statusDot.fillColor = MissionControlTheme.other
        statusDot.strokeColor = .clear
        statusDot.position = CGPoint(x: 18, y: 14)
        c.addChild(statusDot)

        statusLabel.position = CGPoint(x: 28, y: 14)
        c.addChild(statusLabel)
    }

    // MARK: - Show / Hide

    func showSatellite(_ satellite: NotableSatellite) {
        iconLabel.text = satellite.emoji
        titleLabel.text = satellite.name.uppercased()
        subtitleLabel.text = "\(satellite.type.rawValue.uppercased()) • \(satellite.country.uppercased())"
        detailsLabel.text = satellite.description
        let color = typeColor(for: satellite.type)
        titleLabel.fontColor = color
        panel.setBorder(color.withAlphaComponent(0.6))
        setStatus(text: "ACTIVE", color: MissionControlTheme.other)
        animateIn()
    }

    func showZone(_ zone: OrbitalZone) {
        iconLabel.text = zoneIcon(for: zone)
        titleLabel.text = zone.description.uppercased()
        subtitleLabel.text = zone.altitudeRange.uppercased()
        detailsLabel.text = zoneDetails(for: zone)
        titleLabel.fontColor = zone.color
        panel.setBorder(zone.color)
        setStatus(text: "ZONE", color: zone.color)
        animateIn()
    }

    func hide() { animateOut() }

    private func setStatus(text: String, color: SKColor) {
        statusLabel.text = text
        statusLabel.fontColor = color
        statusDot.fillColor = color
    }

    // MARK: - Mappings

    private func typeColor(for type: SatelliteType) -> SKColor {
        switch type {
        case .crewed:          return MissionControlTheme.magenta
        case .telescope:       return MissionControlTheme.cyan
        case .navigation:      return MissionControlTheme.amber
        case .communications:  return .white
        case .earthObservation:return MissionControlTheme.other
        case .weather:         return MissionControlTheme.usa
        case .military:        return MissionControlTheme.russia
        case .constellation:   return MissionControlTheme.cyan
        case .scientific:      return MissionControlTheme.gold
        case .other:           return .white
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
        case .leo: return "Fastest orbit zone\nMost crowded · ISS orbits here"
        case .meo: return "GPS orbits here\nMedium distance · fewer satellites"
        case .geo: return "Stationary position\n24hr orbit · TV satellites here"
        case .heo: return "Highly elliptical\nVariable altitude · Molniya orbits"
        }
    }

    // MARK: - Animation

    private func animateIn() {
        removeAllActions()
        run(.fadeIn(withDuration: 0.3))
    }

    private func animateOut() {
        removeAllActions()
        run(.fadeOut(withDuration: 0.3))
    }
}
