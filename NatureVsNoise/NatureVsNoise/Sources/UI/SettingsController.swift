import AppKit
import ScreenSaver

class SettingsController: NSObject {
    
    // MARK: - Properties
    
    static let shared = SettingsController()
    private let bundleId = "com.antigravity.NatureVsNoise"
    
    // Settings Keys
    struct Keys {
        static let showSatellites = "showSatellites"
        static let satelliteDensity = "satelliteDensity" // 0.0 to 1.0
        static let qualityLevel = "qualityLevel" // 0=Low, 1=Med, 2=High, 3=Ultra
        static let showHUD = "showHUD"
    }
    
    var defaults: ScreenSaverDefaults? {
        return ScreenSaverDefaults(forModuleWithName: bundleId)
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        registerDefaults()
    }
    
    private func registerDefaults() {
        guard let defaults = defaults else { return }
        defaults.register(defaults: [
            Keys.showSatellites: true,
            Keys.satelliteDensity: 1.0,
            Keys.qualityLevel: 3, // High default
            Keys.showHUD: true
        ])
    }
    
    // MARK: - UI Construction
    
    func makeConfigureSheet() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nature vs Noise Settings"
        
        let container = NSView(frame: window.contentRect)
        window.contentView = container
        
        // Logo / Title
        let titleLabel = createLabel(text: "NATURE vs NOISE", fontSize: 24, bold: true)
        titleLabel.frame = NSRect(x: 20, y: 270, width: 410, height: 30)
        container.addSubview(titleLabel)
        
        // Satellites Toggle
        let satToggle = createCheckbox(title: "Show Satellites", state: bool(for: Keys.showSatellites))
        satToggle.frame = NSRect(x: 20, y: 230, width: 200, height: 24)
        satToggle.target = self
        satToggle.action = #selector(toggleSatellites(_:))
        container.addSubview(satToggle)
        
        // HUD Toggle
        let hudToggle = createCheckbox(title: "Show HUD Overlay", state: bool(for: Keys.showHUD))
        hudToggle.frame = NSRect(x: 20, y: 200, width: 200, height: 24)
        hudToggle.target = self
        hudToggle.action = #selector(toggleHUD(_:))
        container.addSubview(hudToggle)
        
        // Quality Segmented Control
        let qualityLabel = createLabel(text: "Visual Quality:", fontSize: 13, bold: false)
        qualityLabel.frame = NSRect(x: 20, y: 160, width: 100, height: 20)
        container.addSubview(qualityLabel)
        
        let qualitySeg = NSSegmentedControl(labels: ["Low", "Med", "High", "Ultra"], trackingMode: .selectOne, target: self, action: #selector(changeQuality(_:)))
        qualitySeg.frame = NSRect(x: 120, y: 155, width: 250, height: 24)
        qualitySeg.selectedSegment = integer(for: Keys.qualityLevel)
        container.addSubview(qualitySeg)
        
        // Done Button
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeSheet(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.frame = NSRect(x: 330, y: 20, width: 100, height: 32)
        container.addSubview(doneButton)
        
        // Version Info
        let versionLabel = createLabel(text: "v1.0.0 (Phase 3)", fontSize: 10, bold: false)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        container.addSubview(versionLabel)
        
        return window
    }
    
    // MARK: - Actions
    
    @objc private func toggleSatellites(_ sender: NSButton) {
        defaults?.set(sender.state == .on, forKey: Keys.showSatellites)
        defaults?.synchronize()
    }
    
    @objc private func toggleHUD(_ sender: NSButton) {
        defaults?.set(sender.state == .on, forKey: Keys.showHUD)
        defaults?.synchronize()
    }
    
    @objc private func changeQuality(_ sender: NSSegmentedControl) {
        defaults?.set(sender.selectedSegment, forKey: Keys.qualityLevel)
        defaults?.synchronize()
    }
    
    @objc private func closeSheet(_ sender: NSButton) {
        sender.window?.sheetParent?.endSheet(sender.window!)
    }
    
    // MARK: - Helpers
    
    private func bool(for key: String) -> Bool {
        return defaults?.bool(forKey: key) ?? true
    }
    
    private func integer(for key: String) -> Int {
        return defaults?.integer(forKey: key) ?? 2
    }
    
    private func createLabel(text: String, fontSize: CGFloat, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.isBezeled = false
        return label
    }
    
    private func createCheckbox(title: String, state: Bool) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        checkbox.state = state ? .on : .off
        return checkbox
    }
}
