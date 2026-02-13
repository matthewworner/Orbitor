import AppKit
import ScreenSaver
import Foundation

// Access FeatureFlags from the main sources

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
        static let infoDensity = "infoDensity" // 0=Minimal, 1=Moderate, 2=Educational
        static let showOrbitalZones = "showOrbitalZones"
        static let showCountryColors = "showCountryColors"
        static let discoveryMode = "discoveryMode"
        static let educationalFacts = "educationalFacts"
        static let factFrequency = "factFrequency" // 0=Low, 1=Medium, 2=High
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
            Keys.showHUD: true,
            Keys.infoDensity: 1, // Moderate default
            Keys.showOrbitalZones: true,
            Keys.showCountryColors: true,
            Keys.discoveryMode: true,
            Keys.educationalFacts: true,
            Keys.factFrequency: 1 // Medium
        ])
    }
    
    // MARK: - UI Construction
    
    func makeConfigureSheet() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nature vs Noise Settings"
        
        let container = NSView(frame: window.contentRect)
        window.contentView = container
        
        // Logo / Title
        let titleLabel = createLabel(text: "NATURE vs NOISE", fontSize: 24, bold: true)
        titleLabel.frame = NSRect(x: 20, y: 350, width: 410, height: 30)
        container.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = createLabel(text: "Screensaver Options", fontSize: 12, bold: false)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 20, y: 330, width: 410, height: 20)
        container.addSubview(subtitleLabel)
        
        // === VISUALS SECTION ===
        let visualsLabel = createLabel(text: "VISUALS", fontSize: 11, bold: true)
        visualsLabel.textColor = .secondaryLabelColor
        visualsLabel.frame = NSRect(x: 20, y: 290, width: 100, height: 16)
        container.addSubview(visualsLabel)
        
        // Starfield Toggle
        let starfieldToggle = createCheckbox(title: "Show Starfield", state: FeatureFlags.enableStarfield)
        starfieldToggle.frame = NSRect(x: 20, y: 260, width: 200, height: 24)
        starfieldToggle.target = self
        starfieldToggle.action = #selector(toggleStarfield(_:))
        container.addSubview(starfieldToggle)
        
        // Toy Satellites Toggle
        let toySatToggle = createCheckbox(title: "Show Toy Satellites", state: FeatureFlags.enableToySats)
        toySatToggle.frame = NSRect(x: 20, y: 230, width: 200, height: 24)
        toySatToggle.target = self
        toySatToggle.action = #selector(toggleToySats(_:))
        container.addSubview(toySatToggle)
        
        // Metal Swarm Toggle
        let metalToggle = createCheckbox(title: "Metal Rendering (Experimental)", state: FeatureFlags.enableSwarm)
        metalToggle.frame = NSRect(x: 20, y: 200, width: 250, height: 24)
        metalToggle.target = self
        metalToggle.action = #selector(toggleMetal(_:))
        container.addSubview(metalToggle)
        
        // Motion Trails Toggle
        let trailsToggle = createCheckbox(title: "Motion Trails", state: FeatureFlags.showTrails)
        trailsToggle.frame = NSRect(x: 20, y: 170, width: 200, height: 24)
        trailsToggle.target = self
        trailsToggle.action = #selector(toggleTrails(_:))
        container.addSubview(trailsToggle)
        
        // === AUDIO SECTION ===
        let audioLabel = createLabel(text: "AUDIO", fontSize: 11, bold: true)
        audioLabel.textColor = .secondaryLabelColor
        audioLabel.frame = NSRect(x: 240, y: 290, width: 100, height: 16)
        container.addSubview(audioLabel)
        
        // Audio Toggle
        let audioToggle = createCheckbox(title: "Enable Audio", state: FeatureFlags.enableAudio)
        audioToggle.frame = NSRect(x: 240, y: 260, width: 200, height: 24)
        audioToggle.target = self
        audioToggle.action = #selector(toggleAudio(_:))
        container.addSubview(audioToggle)
        
        // Info label
        let audioInfoLabel = createLabel(text: "Requires real audio files in bundle", fontSize: 10, bold: false)
        audioInfoLabel.textColor = .tertiaryLabelColor
        audioInfoLabel.frame = NSRect(x: 240, y: 240, width: 200, height: 16)
        container.addSubview(audioInfoLabel)
        
        // === QUALITY SECTION ===
        let qualityLabel = createLabel(text: "QUALITY", fontSize: 11, bold: true)
        qualityLabel.textColor = .secondaryLabelColor
        qualityLabel.frame = NSRect(x: 20, y: 130, width: 100, height: 16)
        container.addSubview(qualityLabel)
        
        // Quality Segmented Control
        let qualitySeg = NSSegmentedControl(labels: ["Low", "Med", "High", "Ultra"], trackingMode: .selectOne, target: self, action: #selector(changeQuality(_:)))
        qualitySeg.frame = NSRect(x: 20, y: 95, width: 250, height: 24)
        qualitySeg.selectedSegment = 1  // Medium by default
        container.addSubview(qualitySeg)
        
        // Quality description
        let qualityDescLabel = createLabel(text: "Low: 200 sats | Med: 500 | High: 1000 | Ultra: 5000", fontSize: 10, bold: false)
        qualityDescLabel.textColor = .tertiaryLabelColor
        qualityDescLabel.frame = NSRect(x: 20, y: 75, width: 300, height: 16)
        container.addSubview(qualityDescLabel)
        
        // === EDUCATIONAL SECTION ===
        let eduLabel = createLabel(text: "EDUCATIONAL", fontSize: 11, bold: true)
        eduLabel.textColor = .secondaryLabelColor
        eduLabel.frame = NSRect(x: 20, y: 280, width: 100, height: 16)
        container.addSubview(eduLabel)
        
        // Info Density
        let densityLabel = createLabel(text: "Info Density:", fontSize: 11, bold: false)
        densityLabel.frame = NSRect(x: 20, y: 250, width: 80, height: 20)
        container.addSubview(densityLabel)
        
        let densitySeg = NSSegmentedControl(labels: ["Min", "Med", "Edu"], trackingMode: .selectOne, target: self, action: #selector(changeInfoDensity(_:)))
        densitySeg.frame = NSRect(x: 100, y: 248, width: 150, height: 24)
        densitySeg.selectedSegment = defaults?.integer(forKey: Keys.infoDensity) ?? 1
        container.addSubview(densitySeg)
        
        // Educational Facts Toggle
        let factsToggle = createCheckbox(title: "Show Educational Facts", state: defaults?.bool(forKey: Keys.educationalFacts) ?? true)
        factsToggle.frame = NSRect(x: 20, y: 220, width: 200, height: 24)
        factsToggle.target = self
        factsToggle.action = #selector(toggleFacts(_:))
        container.addSubview(factsToggle)
        
        // Discovery Mode Toggle
        let discoveryToggle = createCheckbox(title: "Discovery Mode (Achievements)", state: defaults?.bool(forKey: Keys.discoveryMode) ?? true)
        discoveryToggle.frame = NSRect(x: 20, y: 195, width: 230, height: 24)
        discoveryToggle.target = self
        discoveryToggle.action = #selector(toggleDiscovery(_:))
        container.addSubview(discoveryToggle)
        
        // Reset Button
        let resetButton = NSButton(title: "Reset to Safe", target: self, action: #selector(resetToSafe(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.frame = NSRect(x: 240, y: 90, width: 120, height: 28)
        container.addSubview(resetButton)
        
        // Done Button
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeSheet(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.frame = NSRect(x: 330, y: 20, width: 100, height: 32)
        container.addSubview(doneButton)
        
        // Version Info
        let versionLabel = createLabel(text: "v1.0.4", fontSize: 10, bold: false)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.frame = NSRect(x: 20, y: 28, width: 200, height: 20)
        container.addSubview(versionLabel)
        
        return window
    }
    
    // MARK: - Actions
    
    @objc private func toggleStarfield(_ sender: NSButton) {
        FeatureFlags.enableStarfield = (sender.state == .on)
    }
    
    @objc private func toggleToySats(_ sender: NSButton) {
        FeatureFlags.enableToySats = (sender.state == .on)
    }
    
    @objc private func toggleMetal(_ sender: NSButton) {
        FeatureFlags.enableSwarm = (sender.state == .on)
    }
    
    @objc private func toggleTrails(_ sender: NSButton) {
        FeatureFlags.showTrails = (sender.state == .on)
    }
    
    @objc private func toggleAudio(_ sender: NSButton) {
        FeatureFlags.enableAudio = (sender.state == .on)
    }
    
    @objc private func resetToSafe(_ sender: NSButton) {
        FeatureFlags.resetToSafePreset()
        // Reload the sheet to reflect changes
        if let window = sender.window {
            window.sheetParent?.endSheet(window)
        }
    }
    
    @objc private func changeQuality(_ sender: NSSegmentedControl) {
        // Save quality level preference (0-3 maps to QualityLevel.low-.ultra)
        defaults?.set(sender.selectedSegment, forKey: Keys.qualityLevel)
        defaults?.synchronize()
    }
    
    @objc private func changeInfoDensity(_ sender: NSSegmentedControl) {
        defaults?.set(sender.selectedSegment, forKey: Keys.infoDensity)
        defaults?.synchronize()
    }
    
    @objc private func toggleFacts(_ sender: NSButton) {
        defaults?.set(sender.state == .on, forKey: Keys.educationalFacts)
        defaults?.synchronize()
    }
    
    @objc private func toggleDiscovery(_ sender: NSButton) {
        defaults?.set(sender.state == .on, forKey: Keys.discoveryMode)
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
