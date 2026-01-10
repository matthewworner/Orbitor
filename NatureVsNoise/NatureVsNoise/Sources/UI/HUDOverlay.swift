import SpriteKit

/// Minimalist Head-Up Display for the screensaver
class HUDOverlay: SKScene {
    
    // MARK: - UI Elements
    
    private var locationLabel: SKLabelNode!
    private var subLocationLabel: SKLabelNode!
    
    private var statsContainer: SKNode!
    private var satelliteLabel: SKLabelNode!
    private var fpsLabel: SKLabelNode!
    
    private var modeLabel: SKLabelNode!
    
    // MARK: - Initialization
    
    override init(size: CGSize) {
        super.init(size: size)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        
        // Font settings
        let fontName = "Menlo-Regular"
        let fontSize: CGFloat = 12
        let fontColor = SKColor(white: 0.8, alpha: 0.8)
        
        // 1. Top Left: Location/Target
        locationLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        locationLabel.fontSize = 14
        locationLabel.fontColor = .white
        locationLabel.horizontalAlignmentMode = .left
        locationLabel.verticalAlignmentMode = .top
        locationLabel.position = CGPoint(x: 20, y: size.height - 20)
        locationLabel.text = "TARGET: SYSTEM INITIALIZATION"
        addChild(locationLabel)
        
        subLocationLabel = SKLabelNode(fontNamed: fontName)
        subLocationLabel.fontSize = 10
        subLocationLabel.fontColor = fontColor
        subLocationLabel.horizontalAlignmentMode = .left
        subLocationLabel.verticalAlignmentMode = .top
        subLocationLabel.position = CGPoint(x: 20, y: size.height - 40)
        subLocationLabel.text = "COORDS: 0.00, 0.00, 0.00"
        addChild(subLocationLabel)
        
        // 2. Bottom Left: Stats
        statsContainer = SKNode()
        statsContainer.position = CGPoint(x: 20, y: 20)
        addChild(statsContainer)
        
        satelliteLabel = SKLabelNode(fontNamed: fontName)
        satelliteLabel.fontSize = fontSize
        satelliteLabel.fontColor = fontColor
        satelliteLabel.horizontalAlignmentMode = .left
        satelliteLabel.verticalAlignmentMode = .bottom
        satelliteLabel.position = CGPoint(x: 0, y: 20)
        satelliteLabel.text = "OBJECTS: 0 TRACKED"
        statsContainer.addChild(satelliteLabel)
        
        fpsLabel = SKLabelNode(fontNamed: fontName)
        fpsLabel.fontSize = 10
        fpsLabel.fontColor = SKColor(white: 0.5, alpha: 0.8)
        fpsLabel.horizontalAlignmentMode = .left
        fpsLabel.verticalAlignmentMode = .bottom
        fpsLabel.position = CGPoint(x: 0, y: 0)
        fpsLabel.text = "RENDER: METAL_API [GPU]"
        statsContainer.addChild(fpsLabel)
        
        // 3. Bottom Right: Mode
        modeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        modeLabel.fontSize = fontSize
        modeLabel.fontColor = fontColor
        modeLabel.horizontalAlignmentMode = .right
        modeLabel.verticalAlignmentMode = .bottom
        modeLabel.position = CGPoint(x: size.width - 20, y: 20)
        modeLabel.text = "MODE: CINEMATIC_AUTO"
        addChild(modeLabel)
    }
    
    // MARK: - Updates
    
    func updateTarget(_ name: String, coordinates: String) {
        locationLabel.text = "TARGET: \(name.uppercased())"
        subLocationLabel.text = "COORDS: \(coordinates)"
    }
    
    func updateStats(satelliteCount: Int, fps: Int) {
        satelliteLabel.text = "OBJECTS: \(formatNumber(satelliteCount)) TRACKED"
    }
    
    func updateLayout(for newSize: CGSize) {
        self.size = newSize
        
        locationLabel.position = CGPoint(x: 20, y: newSize.height - 20)
        subLocationLabel.position = CGPoint(x: 20, y: newSize.height - 40)
        modeLabel.position = CGPoint(x: newSize.width - 20, y: 20)
        // Stats container stays at bottom left
    }
    
    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
