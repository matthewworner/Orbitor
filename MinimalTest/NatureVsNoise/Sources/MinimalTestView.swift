import ScreenSaver
import AppKit

class MinimalTestView: ScreenSaverView {
    
    private var message: NSTextField!
    
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
        layer?.backgroundColor = NSColor.black.cgColor
        
        message = NSTextField(labelWithString: "Minimal Screensaver")
        message.frame = NSRect(x: 50, y: 50, width: 300, height: 40)
        message.textColor = NSColor.white
        message.font = NSFont.boldSystemFont(ofSize: 24)
        addSubview(message)
        
        print("✅ MinimalTestView: Initialized successfully")
    }
    
    override func startAnimation() {
        super.startAnimation()
        print("✅ MinimalTestView: Animation started")
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        print("✅ MinimalTestView: Animation stopped")
    }
    
    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()
    }
    
    override func animateOneFrame() {
        needsDisplay = true
    }
}
