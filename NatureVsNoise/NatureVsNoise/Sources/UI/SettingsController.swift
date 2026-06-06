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
        let width: CGFloat = 460
        let height: CGFloat = 600
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nature vs Noise Settings"

        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = container

        // Top-down layout cursor (AppKit origin is bottom-left, so we descend from the top).
        let left: CGFloat = 24
        let contentW = width - left * 2
        var y = height - 36

        func addRow(_ view: NSView, height h: CGFloat, gap: CGFloat = 10, x: CGFloat? = nil, w: CGFloat? = nil) {
            view.frame = NSRect(x: x ?? left, y: y - h, width: w ?? contentW, height: h)
            container.addSubview(view)
            y -= (h + gap)
        }
        func addSectionHeader(_ text: String) {
            let l = createLabel(text: "▮ " + text, fontSize: 11, bold: true)
            l.textColor = .secondaryLabelColor
            addRow(l, height: 16, gap: 8)
        }

        // === Title ===
        let titleLabel = createLabel(text: "ASTRA · NATURE vs NOISE", fontSize: 20, bold: true)
        addRow(titleLabel, height: 26, gap: 2)
        let subtitleLabel = createLabel(text: "Mission Control Configuration", fontSize: 12, bold: false)
        subtitleLabel.textColor = .secondaryLabelColor
        addRow(subtitleLabel, height: 18, gap: 18)

        // === PERFORMANCE ===
        addSectionHeader("PERFORMANCE")
        let qLabel = createLabel(text: "Render Quality", fontSize: 11, bold: false)
        qLabel.textColor = .secondaryLabelColor
        addRow(qLabel, height: 16, gap: 6)

        let qualitySeg = NSSegmentedControl(labels: ["Safe", "Medium", "High", "Ultra"],
                                            trackingMode: .selectOne, target: self,
                                            action: #selector(changeQuality(_:)))
        qualitySeg.selectedSegment = defaults?.integer(forKey: Keys.qualityLevel) ?? 2
        addRow(qualitySeg, height: 26, gap: 14)

        let densLabel = createLabel(text: "Satellite Count", fontSize: 11, bold: false)
        densLabel.textColor = .secondaryLabelColor
        addRow(densLabel, height: 16, gap: 4)
        let densitySlider = NSSlider(value: defaults?.double(forKey: Keys.satelliteDensity) ?? 1.0,
                                     minValue: 0.0, maxValue: 1.0,
                                     target: self, action: #selector(changeDensity(_:)))
        addRow(densitySlider, height: 22, gap: 4)
        let recLabel = createLabel(text: "Recommended: High for Apple Silicon", fontSize: 10, bold: false)
        recLabel.textColor = .tertiaryLabelColor
        addRow(recLabel, height: 14, gap: 18)

        // === VISUALS ===
        addSectionHeader("VISUALS")
        func addToggle(_ title: String, _ state: Bool, _ action: Selector) {
            let cb = createCheckbox(title: title, state: state)
            cb.target = self; cb.action = action
            addRow(cb, height: 22, gap: 6)
        }
        addToggle("Satellite Swarm (Metal)", FeatureFlags.enableSwarm, #selector(toggleMetal(_:)))
        addToggle("Motion Trails", FeatureFlags.showTrails, #selector(toggleTrails(_:)))
        addToggle("Starfield", FeatureFlags.enableStarfield, #selector(toggleStarfield(_:)))
        addToggle("Hero Satellites (3D models)", FeatureFlags.enableToySats, #selector(toggleToySats(_:)))
        addToggle("Educational Facts", defaults?.bool(forKey: Keys.educationalFacts) ?? true, #selector(toggleFacts(_:)))
        addToggle("Discovery Mode (Achievements)", defaults?.bool(forKey: Keys.discoveryMode) ?? true, #selector(toggleDiscovery(_:)))

        let hudLabel = createLabel(text: "HUD Density", fontSize: 11, bold: false)
        hudLabel.textColor = .secondaryLabelColor
        addRow(hudLabel, height: 16, gap: 4)
        let densitySeg = NSSegmentedControl(labels: ["Minimal", "Moderate", "Educational"],
                                            trackingMode: .selectOne, target: self,
                                            action: #selector(changeInfoDensity(_:)))
        densitySeg.selectedSegment = defaults?.integer(forKey: Keys.infoDensity) ?? 1
        addRow(densitySeg, height: 26, gap: 18)

        // === AUDIO ===
        addSectionHeader("AUDIO")
        addToggle("Ambient Audio", FeatureFlags.enableAudio, #selector(toggleAudio(_:)))
        let audioInfo = createLabel(text: "Requires audio files bundled in the saver", fontSize: 10, bold: false)
        audioInfo.textColor = .tertiaryLabelColor
        addRow(audioInfo, height: 14, gap: 18)

        // === PRESETS / FOOTER ===
        addSectionHeader("PRESETS")
        let presetSeg = NSSegmentedControl(labels: ["Safe", "Balanced", "Cinematic"],
                                           trackingMode: .momentary, target: self,
                                           action: #selector(applyPreset(_:)))
        addRow(presetSeg, height: 26, gap: 16)

        // Done + version pinned near the bottom
        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeSheet(_:)))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.frame = NSRect(x: width - 24 - 100, y: 20, width: 100, height: 32)
        container.addSubview(doneButton)

        let versionLabel = createLabel(text: "v1.1.0 · Astra HUD", fontSize: 10, bold: false)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.frame = NSRect(x: 24, y: 28, width: 240, height: 18)
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

    @objc private func changeDensity(_ sender: NSSlider) {
        defaults?.set(sender.doubleValue, forKey: Keys.satelliteDensity)
        defaults?.synchronize()
    }

    @objc private func applyPreset(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: // Safe
            FeatureFlags.resetToSafePreset()
        case 2: // Cinematic — everything on
            FeatureFlags.applyFullPreset()
        default: // Balanced
            FeatureFlags.enableSwarm = true
            FeatureFlags.showTrails = true
            FeatureFlags.enableStarfield = true
            FeatureFlags.enableToySats = true
            FeatureFlags.enableAudio = false
        }
        // Reload the sheet so toggles reflect the applied preset.
        if let window = sender.window {
            window.contentView = makeConfigureSheet().contentView
        }
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
