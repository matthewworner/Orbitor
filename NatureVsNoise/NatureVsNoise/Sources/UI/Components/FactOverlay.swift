import SpriteKit

/// Overlay for displaying educational facts
class FactOverlay: SKNode {
    
    // MARK: - UI Elements
    
    private var container: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var factLabel: SKLabelNode!
    private var categoryLabel: SKLabelNode!
    
    // State
    private var isShowing = false
    private var currentFact: EducationalFact?
    private var dismissTimer: Timer?
    
    // Settings
    var autoShowFacts = true
    var factFrequency: FactFrequency = .medium
    
    enum FactFrequency: TimeInterval {
        case low = 30
        case medium = 20
        case high = 10
    }
    
    private var showTimer: Timer?
    
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
        let overlayWidth: CGFloat = 320
        let overlayHeight: CGFloat = 60
        
        // Subtle container
        let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight),
                          cornerWidth: MissionControlTheme.cornerRadius,
                          cornerHeight: MissionControlTheme.cornerRadius,
                          transform: nil)
        
        container = SKShapeNode(path: path)
        container.fillColor = MissionControlTheme.deepSpaceColor
        container.strokeColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.2)
        container.lineWidth = 1
        container.alpha = 0
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        
        // Icon
        iconLabel = SKLabelNode(fontNamed: "SF Mono")
        iconLabel.fontSize = 20
        iconLabel.text = "💡"
        iconLabel.horizontalAlignmentMode = .left
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 15, y: overlayHeight / 2)
        iconLabel.alpha = 0
        container.addChild(iconLabel)
        
        // Fact text (multiline)
        factLabel = SKLabelNode(fontNamed: "SF Mono")
        factLabel.fontSize = 12
        factLabel.fontColor = MissionControlTheme.white
        factLabel.text = ""
        factLabel.horizontalAlignmentMode = .left
        factLabel.verticalAlignmentMode = .center
        factLabel.position = CGPoint(x: 45, y: overlayHeight / 2 + 8)
        factLabel.alpha = 0
        factLabel.preferredMaxLayoutWidth = overlayWidth - 60
        container.addChild(factLabel)
        
        // Category
        categoryLabel = SKLabelNode(fontNamed: "SF Mono")
        categoryLabel.fontSize = 8
        categoryLabel.fontColor = MissionControlTheme.textMuted
        categoryLabel.text = ""
        categoryLabel.horizontalAlignmentMode = .left
        categoryLabel.verticalAlignmentMode = .center
        categoryLabel.position = CGPoint(x: 45, y: overlayHeight / 2 - 15)
        categoryLabel.alpha = 0
        container.addChild(categoryLabel)
        
        // Scan line effect
        addScanlineEffect(to: container, width: overlayWidth, height: overlayHeight)
    }
    
    private func addScanlineEffect(to node: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Create scan lines
        let scanlines = SKEffectNode()
        scanlines.shouldRasterize = true
        scanlines.zPosition = 10
        
        // Simple vertical line that moves
        let line = SKShapeNode(rectOf: CGSize(width: 1, height: height))
        line.fillColor = MissionControlTheme.primaryCyan.withAlphaComponent(0.1)
        line.strokeColor = .clear
        line.position = CGPoint(x: width / 2, y: height / 2)
        line.name = "scanline"
        scanlines.addChild(line)
        
        node.addChild(scanlines)
    }
    
    // MARK: - Show Fact
    
    func showNextFact() {
        guard !isShowing else { return }
        
        let fact = EducationalFacts.randomFact()
        showFact(fact)
    }
    
    func showFact(_ fact: EducationalFact) {
        guard !isShowing else { return }
        
        currentFact = fact
        isShowing = true
        
        // Update content
        iconLabel.text = fact.emoji
        factLabel.text = fact.text
        categoryLabel.text = fact.category.rawValue.uppercased()
        
        // Reset state
        container.alpha = 0
        iconLabel.alpha = 0
        factLabel.alpha = 0
        categoryLabel.alpha = 0
        
        // Animate in
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        container.run(fadeIn)
        
        let delay = SKAction.wait(forDuration: 0.1)
        let showElements = SKAction.fadeIn(withDuration: 0.3)
        
        run(SKAction.sequence([delay, SKAction.run { [weak self] in
            self?.iconLabel.run(showElements)
            self?.factLabel.run(showElements)
            self?.categoryLabel.run(showElements)
        }]))
        
        // Animate scanline
        if let scanlines = container.childNode(withName: "scanline") as? SKEffectNode,
           let line = scanlines.childNode(withName: "scanline") {
            let scan = SKAction.moveBy(x: 0, y: 60, duration: 2.0)
            line.run(SKAction.repeatForever(scan))
        }
        
        // Auto dismiss
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: fact.duration, repeats: false) { [weak self] _ in
            self?.hideFact()
        }
    }
    
    func hideFact() {
        guard isShowing else { return }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        container.run(fadeOut)
        
        let delay = SKAction.wait(forDuration: 0.5)
        let reset = SKAction.run { [weak self] in
            self?.isShowing = false
            self?.currentFact = nil
        }
        
        run(SKAction.sequence([delay, reset]))
    }
    
    // MARK: - Auto-Show Timer
    
    func startAutoShow() {
        guard autoShowFacts else { return }
        
        stopAutoShow()
        
        // Initial delay
        showTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.showNextFact()
            self?.scheduleFacts()
        }
    }
    
    private func scheduleFacts() {
        guard autoShowFacts, isShowing == false else { return }
        
        let interval = factFrequency.rawValue
        showTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.showNextFact()
        }
    }
    
    func stopAutoShow() {
        showTimer?.invalidate()
        showTimer = nil
    }
    
    // MARK: - Update Settings
    
    func updateFrequency(_ frequency: FactFrequency) {
        factFrequency = frequency
        
        // Restart timer with new frequency
        if autoShowFacts {
            startAutoShow()
        }
    }
    
    func setAutoShow(_ enabled: Bool) {
        autoShowFacts = enabled
        
        if enabled {
            startAutoShow()
        } else {
            stopAutoShow()
            hideFact()
        }
    }
}
