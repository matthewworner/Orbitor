import SpriteKit

/// Top-right **telemetry dashboard** (Astra HUD): total tracked objects with an
/// ACTIVE / DEBRIS / DECAY breakdown. Driven by `SatelliteManager.OrbitalCensus`.
/// (Replaces the old combined stats panel; the altitude/velocity readout now lives
/// in the bottom-left contextual-focus panel.)
class StatsPanel: SKNode {

    static let panelWidth: CGFloat = 232
    static let panelHeight: CGFloat = 104

    private let panel: GlassPanel
    private let totalLabel: SKLabelNode
    private let activeValue: SKLabelNode
    private let debrisValue: SKLabelNode

    private var displayedTotal = 0

    override init() {
        panel = GlassPanel(size: CGSize(width: StatsPanel.panelWidth, height: StatsPanel.panelHeight))
        totalLabel = .hudLabel("0", size: 28, color: MissionControlTheme.primarySoftColor,
                               weight: .bold, hAlign: .right)
        activeValue = .hudLabel("—", size: 11, color: MissionControlTheme.white)
        debrisValue = .hudLabel("—", size: 11, color: MissionControlTheme.white)
        super.init()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        panel = GlassPanel(size: CGSize(width: StatsPanel.panelWidth, height: StatsPanel.panelHeight))
        totalLabel = SKLabelNode(); activeValue = SKLabelNode()
        debrisValue = SKLabelNode()
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        let w = StatsPanel.panelWidth, h = StatsPanel.panelHeight
        addChild(panel)
        let c = panel.content

        let header = SKLabelNode.hudLabel("TOTAL_TRACKED_OBJECTS", size: 9,
                                          color: MissionControlTheme.textMut, hAlign: .right)
        header.position = CGPoint(x: w - 12, y: h - 18)
        c.addChild(header)

        totalLabel.position = CGPoint(x: w - 44, y: h - 42)
        c.addChild(totalLabel)

        let objs = SKLabelNode.hudLabel("OBJS", size: 8,
                                        color: MissionControlTheme.primarySoft.withAlphaComponent(0.5),
                                        hAlign: .right)
        objs.position = CGPoint(x: w - 12, y: h - 36)
        c.addChild(objs)

        // Divider
        let div = SKShapeNode(rect: CGRect(x: 12, y: h - 58, width: w - 24, height: 1))
        div.fillColor = MissionControlTheme.hairlineColor
        div.strokeColor = .clear
        c.addChild(div)

        // 2 breakdown columns (DECAY omitted — not derivable from TLE data)
        let cols: [(String, SKLabelNode)] = [("ACTIVE", activeValue),
                                             ("DEBRIS", debrisValue)]
        let colW = (w - 24) / 2
        for (i, (title, value)) in cols.enumerated() {
            let x = 12 + CGFloat(i) * colW
            let t = SKLabelNode.hudLabel(title, size: 8, color: MissionControlTheme.textMut)
            t.position = CGPoint(x: x, y: h - 72)
            c.addChild(t)
            value.position = CGPoint(x: x, y: h - 88)
            c.addChild(value)
        }
    }

    // MARK: - Update

    func update(census: SatelliteManager.OrbitalCensus) {
        animateTotal(to: census.total)
        activeValue.text = format(census.activeTotal)
        debrisValue.text = format(census.debris)
    }

    private func animateTotal(to target: Int) {
        guard target != displayedTotal else { return }
        let start = displayedTotal
        displayedTotal = target
        let duration: TimeInterval = 0.5
        let action = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            let p = Double(elapsed) / duration
            let v = Int(Double(start) + (Double(target - start) * min(1, p)))
            self?.totalLabel.text = self?.format(v)
        }
        totalLabel.run(action)
    }

    private func format(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
