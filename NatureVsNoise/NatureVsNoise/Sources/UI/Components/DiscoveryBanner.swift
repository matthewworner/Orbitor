import SpriteKit

/// Discovery banner for achievement and satellite notifications
class DiscoveryBanner: SKNode {
    
    // MARK: - UI Elements
    
    private var container: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var progressBar: SKShapeNode!
    private var progressFill: SKShapeNode!
    
    // State
    private var isShowing = false
    private var dismissTimer: Timer?
    
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
        let bannerWidth: CGFloat = 280
        let bannerHeight: CGFloat = 70
        
        // Container with glow effect
        let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: bannerWidth, height: bannerHeight),
                          cornerWidth: MissionControlTheme.cornerRadius,
                          cornerHeight: MissionControlTheme.cornerRadius,
                          transform: nil)
        
        container = SKShapeNode(path: path)
        container.fillColor = MissionControlTheme.panelBg
        container.strokeColor = MissionControlTheme.gold.withAlphaComponent(0.8)
        container.lineWidth = 2
        container.alpha = 0
        container.position = CGPoint(x: 0, y: 0)
        container.setScale(0.8)
        addChild(container)
        
        // Icon
        iconLabel = SKLabelNode(fontNamed: "SF Mono")
        iconLabel.fontSize = 28
        iconLabel.text = "🏆"
        iconLabel.horizontalAlignmentMode = .left
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 15, y: bannerHeight / 2)
        iconLabel.alpha = 0
        container.addChild(iconLabel)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "SF Mono")
        titleLabel.fontSize = 14
        titleLabel.fontColor = MissionControlTheme.gold
        titleLabel.text = "ACHIEVEMENT UNLOCKED"
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 60, y: bannerHeight / 2 + 10)
        titleLabel.alpha = 0
        container.addChild(titleLabel)
        
        // Subtitle
        subtitleLabel = SKLabelNode(fontNamed: "SF Mono")
        subtitleLabel.fontSize = 11
        subtitleLabel.fontColor = MissionControlTheme.textSecondary
        subtitleLabel.text = ""
        subtitleLabel.horizontalAlignmentMode = .left
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 60, y: bannerHeight / 2 - 12)
        subtitleLabel.alpha = 0
        container.addChild(subtitleLabel)
        
        // Progress bar background
        let progressPath = CGMutablePath()
        progressPath.addRoundedRect(in: CGRect(x: 15, y: 10, width: bannerWidth - 30, height: 4),
                                   cornerWidth: 2, cornerHeight: 2)
        progressBar = SKShapeNode(path: progressPath)
        progressBar.fillColor = MissionControlTheme.textMuted.withAlphaComponent(0.3)
        progressBar.strokeColor = .clear
        progressBar.alpha = 0
        container.addChild(progressBar)
        
        // Progress fill
        let fillPath = CGMutablePath()
        fillPath.addRoundedRect(in: CGRect(x: 15, y: 10, width: 0, height: 4),
                               cornerWidth: 2, cornerHeight: 2)
        progressFill = SKShapeNode(path: fillPath)
        progressFill.fillColor = MissionControlTheme.gold
        progressFill.strokeColor = .clear
        progressFill.alpha = 0
        container.addChild(progressFill)
        
        // Glow effect behind
        addGlowEffect(to: container, width: bannerWidth, height: bannerHeight)
    }
    
    private func addGlowEffect(to node: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Outer glow
        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10])
        
        let glowRect = CGRect(x: -5, y: -5, width: width + 10, height: height + 10)
        let glowPath = CGPath(roundedRect: glowRect,
                              cornerWidth: MissionControlTheme.cornerRadius + 5,
                              cornerHeight: MissionControlTheme.cornerRadius + 5,
                              transform: nil)
        let glowShape = SKShapeNode(path: glowPath)
        glowShape.fillColor = MissionControlTheme.gold.withAlphaComponent(0.2)
        glowShape.strokeColor = .clear
        glow.addChild(glowShape)
        
        node.addChild(glow)
        node.zPosition = -1
    }
    
    // MARK: - Show Achievement
    
    func showAchievement(_ achievement: Achievement) {
        iconLabel.text = achievement.emoji
        titleLabel.text = achievement.name.uppercased()
        subtitleLabel.text = achievement.description
        
        showBanner(duration: 4.0)
    }
    
    // MARK: - Show Discovery
    
    func showDiscovery(name: String, description: String) {
        iconLabel.text = "🔍"
        titleLabel.text = "SATELLITE FOUND"
        subtitleLabel.text = "\(name): \(description)"
        
        showBanner(duration: 3.0)
    }
    
    // MARK: - Show Fact
    
    func showFact(_ fact: EducationalFact) {
        iconLabel.text = fact.emoji
        titleLabel.text = "DID YOU KNOW?"
        subtitleLabel.text = fact.text
        
        showBanner(duration: fact.duration)
    }
    
    // MARK: - Animation
    
    private func showBanner(duration: TimeInterval) {
        guard !isShowing else {
            // Queue this banner
            return
        }
        
        isShowing = true
        
        // Reset state
        container.alpha = 0
        container.setScale(0.8)
        iconLabel.alpha = 0
        titleLabel.alpha = 0
        subtitleLabel.alpha = 0
        progressBar.alpha = 0
        progressFill.alpha = 0
        
        // Animate in
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        scaleUp.timingMode = .easeOut
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        container.run(SKAction.group([scaleUp, fadeIn]))
        
        let delay = SKAction.wait(forDuration: 0.1)
        let showElements = SKAction.fadeIn(withDuration: 0.2)
        
        run(SKAction.sequence([delay, SKAction.group([
            iconLabel.run(showElements),
            titleLabel.run(showElements),
            subtitleLabel.run(showElements),
            progressBar.run(showElements)
        ])]))
        
        // Progress bar animation
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.animateProgress(duration: duration)
            }
        ]))
        
        // Auto dismiss
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hideBanner()
        }
    }
    
    private func animateProgress(duration: TimeInterval) {
        progressFill.alpha = 1
        
        let bannerWidth: CGFloat = 280 - 30
        let endWidth = bannerWidth
        
        // Animate progress bar shrinking (time remaining)
        let shrink = SKAction.customAction(withDuration: duration) { [weak self] node, elapsedTime in
            guard let fill = self?.progressFill else { return }
            let progress = CGFloat(elapsedTime / CGFloat(duration))
            let currentWidth = endWidth * (1 - progress)
            
            // Redraw path
            let path = CGMutablePath()
            path.addRoundedRect(in: CGRect(x: 15, y: 10, width: max(0, currentWidth), height: 4),
                               cornerWidth: 2, cornerHeight: 2)
            fill.path = path
        }
        
        progressFill.run(shrink)
    }
    
    private func hideBanner() {
        isShowing = true
        
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.3)
        scaleDown.timingMode = .easeIn
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        container.run(SKAction.group([scaleDown, fadeOut]))
        
        let delay = SKAction.wait(forDuration: 0.3)
        let reset = SKAction.run { [weak self] in
            self?.isShowing = false
        }
        
        run(SKAction.sequence([delay, reset]))
    }
    
    // MARK: - Force Hide
    
    func forceHide() {
        dismissTimer?.invalidate()
        hideBanner()
    }
}
