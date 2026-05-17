import ScreenSaver

class MinimalView: ScreenSaverView {
    
    private var label: NSTextField!
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.blue.cgColor
        
        label = NSTextField(labelWithString: "Minimal Test")
        label.frame = NSRect(x: 50, y: 50, width: 200, height: 30)
        label.textColor = .white
        addSubview(label)
        
        print("✅ MinimalView: Initialized")
    }
    
    override func startAnimation() {
        super.startAnimation()
        print("✅ MinimalView: Animation started")
    }
    
    override func draw(_ rect: NSRect) {
        NSColor.blue.setFill()
        rect.fill()
    }
    
    override func animateOneFrame() {
        needsDisplay = true
    }
}
