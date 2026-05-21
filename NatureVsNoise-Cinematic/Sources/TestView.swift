import ScreenSaver

/// Minimal test screensaver - SHOWS RED SCREEN IMMEDIATELY
class TestView: ScreenSaverView {
    
    private var testView: NSView!
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        print("🎬 [TEST] init frame: \(frame)")
        
        // Create a simple RED view - if this doesn't show, nothing will
        testView = NSView(frame: bounds)
        testView.autoresizingMask = [.width, .height]
        testView.wantsLayer = true
        testView.layer?.backgroundColor = NSColor.red.cgColor
        addSubview(testView)
        
        print("🎬 [TEST] Red view added")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        print("🎬 [TEST] init coder")
        
        testView = NSView(frame: bounds)
        testView.autoresizingMask = [.width, .height]
        testView.wantsLayer = true
        testView.layer?.backgroundColor = NSColor.red.cgColor
        addSubview(testView)
    }
    
    override func animateOneFrame() {
        // Flash colors to prove animation works
        let colors: [NSColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
        let idx = Int(Date().timeIntervalSince1970 * 2) % colors.count
        testView.layer?.backgroundColor = colors[idx].cgColor
    }
    
    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}