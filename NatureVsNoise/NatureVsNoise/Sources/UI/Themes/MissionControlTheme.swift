import SpriteKit
import AppKit
import CoreText

/// Mission Control inspired color palette and styling
struct MissionControlTheme {

    // MARK: - Colors

    /// Primary cyan - orbital indicators, active elements
    static let primaryCyan = NSColor(red: 0/255, green: 212/255, blue: 255/255, alpha: 1.0)

    /// Soft primary used by the Astra/Stitch HUD for titles & focus brackets
    static let primarySoft = NSColor(red: 168/255, green: 232/255, blue: 255/255, alpha: 1.0)

    /// "Nature" accent - calm astral blue (the serene half of the thesis)
    static let natureBlue = NSColor(red: 127/255, green: 168/255, blue: 255/255, alpha: 1.0)

    /// Secondary amber - warnings, notable satellites
    static let secondaryAmber = NSColor(red: 255/255, green: 184/255, blue: 0/255, alpha: 1.0)

    /// Accent magenta - ISS, crewed spacecraft
    static let accentMagenta = NSColor(red: 255/255, green: 0/255, blue: 170/255, alpha: 1.0)

    /// Deep space background
    static let deepSpace = NSColor(red: 5/255, green: 10/255, blue: 20/255, alpha: 0.85)

    /// Panel background
    static let panelBackground = NSColor(red: 10/255, green: 20/255, blue: 40/255, alpha: 0.75)
    
    /// Primary text
    static let textPrimary = NSColor.white
    
    /// Secondary text
    static let textSecondary = NSColor(white: 0.7, alpha: 1.0)
    
    /// Muted text
    static let textMuted = NSColor(white: 0.5, alpha: 1.0)
    
    // MARK: - Country Colors (for satellite origin)
    
    static let russiaRed = NSColor(red: 220/255, green: 60/255, blue: 60/255, alpha: 1.0)
    static let usaBlue = NSColor(red: 60/255, green: 120/255, blue: 220/255, alpha: 1.0)
    static let chinaYellow = NSColor(red: 240/255, green: 200/255, blue: 40/255, alpha: 1.0)
    static let otherGreen = NSColor(red: 60/255, green: 200/255, blue: 120/255, alpha: 1.0)
    
    // MARK: - Orbital Zone Colors
    
    static let leoCyan = NSColor(red: 0/255, green: 200/255, blue: 255/255, alpha: 0.6)
    static let meoYellow = NSColor(red: 255/255, green: 200/255, blue: 0/255, alpha: 0.6)
    static let geoMagenta = NSColor(red: 255/255, green: 0/255, blue: 200/255, alpha: 0.6)

    // MARK: - Glass / Panel Treatment (Astra HUD)

    /// Frosted glass panel fill (SpriteKit can't blur the live scene, so we use a flat translucent fill)
    static let glassFill = NSColor(red: 10/255, green: 20/255, blue: 40/255, alpha: 0.65)
    /// Hairline panel border ~12% white
    static let glassBorder = NSColor(white: 1.0, alpha: 0.12)
    /// Corner-bracket accent (soft cyan @ 30%)
    static let bracketAccent = NSColor(red: 168/255, green: 232/255, blue: 255/255, alpha: 0.3)
    /// Hairline divider between telemetry rows
    static let hairline = NSColor(white: 1.0, alpha: 0.15)
    
    // MARK: - Achievement Colors
    
    static let achievementGold = NSColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
    static let achievementSilver = NSColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1.0)
    static let achievementBronze = NSColor(red: 205/255, green: 127/255, blue: 50/255, alpha: 1.0)
    
    // MARK: - Fonts
    
    static let headerFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
    static let bodyFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    static let smallFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    static let tinyFont = NSFont.monospacedSystemFont(ofSize: 8, weight: .regular)
    
    // MARK: - Spacing
    
    static let panelPadding: CGFloat = 12
    static let elementSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 6
    
    // MARK: - SKColor Conversions (SKColor == NSColor on macOS)

    static var cyan: SKColor { primaryCyan }
    static var amber: SKColor { secondaryAmber }
    static var magenta: SKColor { accentMagenta }
    static var deepSpaceColor: SKColor { deepSpace }
    static var panelBg: SKColor { panelBackground }
    static var white: SKColor { SKColor.white }
    static var textSec: SKColor { textSecondary }
    static var textMut: SKColor { textMuted }

    static var russia: SKColor { russiaRed }
    static var usa: SKColor { usaBlue }
    static var china: SKColor { chinaYellow }
    static var other: SKColor { otherGreen }

    static var leo: SKColor { leoCyan }
    static var meo: SKColor { meoYellow }
    static var geo: SKColor { geoMagenta }

    static var gold: SKColor { achievementGold }
    static var primarySoftColor: SKColor { primarySoft }
    static var natureBlueColor: SKColor { natureBlue }
    static var glassFillColor: SKColor { glassFill }
    static var glassBorderColor: SKColor { glassBorder }
    static var bracketColor: SKColor { bracketAccent }
    static var hairlineColor: SKColor { hairline }

    // MARK: - Fonts (JetBrains Mono, bundled — SF Mono fallback)

    /// Resolved PostScript names captured at registration time. Default to a system
    /// monospaced face so the HUD still renders if the bundled font is missing.
    private(set) static var monoRegularName: String = "Menlo-Regular"
    private(set) static var monoBoldName: String = "Menlo-Bold"
    private static var fontsRegistered = false

    /// Register the bundled JetBrains Mono faces with CoreText and capture their
    /// PostScript names. Safe to call repeatedly; no-ops after the first success.
    /// Falls back silently to the system monospaced font if anything fails.
    static func registerFonts(in bundle: Bundle) {
        guard !fontsRegistered else { return }
        fontsRegistered = true

        func register(_ resource: String) -> String? {
            guard let url = bundle.url(forResource: resource, withExtension: "ttf")
                ?? bundle.url(forResource: resource, withExtension: "ttf", subdirectory: "8K") else {
                return nil
            }
            // Register for this process; ignore "already registered" errors.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
                  let first = descs.first,
                  let psName = CTFontDescriptorCopyAttribute(first, kCTFontNameAttribute) as? String else {
                return nil
            }
            return psName
        }

        if let reg = register("JetBrainsMono-Regular") { monoRegularName = reg }
        if let bold = register("JetBrainsMono-Bold") { monoBoldName = bold }
    }

    /// Returns the HUD monospaced font at the given size/weight.
    /// Anything heavier than `.regular` maps to the bold face.
    static func hudFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let name = (weight == .regular) ? monoRegularName : monoBoldName
        if let f = NSFont(name: name, size: size) { return f }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    /// PostScript font name string for SpriteKit `SKLabelNode(fontNamed:)`.
    static func hudFontName(weight: NSFont.Weight = .regular) -> String {
        return (weight == .regular) ? monoRegularName : monoBoldName
    }
}

// MARK: - Satellite classification → HUD treatment (single source of truth)

extension SatelliteClass {
    /// Legend/dossier accent color. Matches the Astra HUD classification legend.
    var hudColor: SKColor {
        switch self {
        case .iss:             return MissionControlTheme.gold        // ISS_STATION
        case .starlink:        return MissionControlTheme.cyan        // STARLINK
        case .notable:         return MissionControlTheme.other       // NOTABLE_INT (green)
        case .activeSatellite: return MissionControlTheme.white       // ACTIVE_COMMS
        case .debris:          return MissionControlTheme.russia      // DEBRIS_HAZARD (red)
        }
    }

    /// Short uppercase code shown in the classification legend.
    var legendCode: String {
        switch self {
        case .iss:             return "ISS_STATION"
        case .starlink:        return "STARLINK"
        case .notable:         return "NOTABLE_INT"
        case .activeSatellite: return "ACTIVE_COMMS"
        case .debris:          return "DEBRIS_HAZARD"
        }
    }

    /// Stable ordering for the legend (most notable first).
    static var legendOrder: [SatelliteClass] {
        [.iss, .starlink, .notable(""), .activeSatellite, .debris]
    }
}

/// Info density levels
enum InfoDensity: Int {
    case minimal = 0
    case moderate = 1
    case educational = 2
    
    var description: String {
        switch self {
        case .minimal: return "Minimal"
        case .moderate: return "Moderate"
        case .educational: return "Educational"
        }
    }
}

/// Orbital zone definitions
enum OrbitalZone: String, CaseIterable {
    case leo = "LEO"      // Low Earth Orbit: 200-2000 km
    case meo = "MEO"      // Medium Earth Orbit: 2,000-35,786 km
    case geo = "GEO"     // Geostationary: ~35,786 km
    case heo = "HEO"     // Highly Elliptical
    
    var altitudeRange: String {
        switch self {
        case .leo: return "200-2,000 km"
        case .meo: return "2,000-35,786 km"
        case .geo: return "35,786 km"
        case .heo: return "Variable"
        }
    }
    
    var description: String {
        switch self {
        case .leo: return "Low Earth Orbit"
        case .meo: return "Medium Earth Orbit"
        case .geo: return "Geostationary Orbit"
        case .heo: return "Highly Elliptical Orbit"
        }
    }
    
    var color: SKColor {
        switch self {
        case .leo: return MissionControlTheme.leo
        case .meo: return MissionControlTheme.meo
        case .geo: return MissionControlTheme.geo
        case .heo: return MissionControlTheme.amber
        }
    }
    
    var maxAltitude: Double { // km
        switch self {
        case .leo: return 2000
        case .meo: return 35786
        case .geo: return 35786
        case .heo: return 40000
        }
    }
}

// MARK: - GlassPanel (shared Astra HUD panel treatment)

/// Reusable frosted-glass panel: translucent fill, hairline border, and optional
/// corner brackets. Origin is bottom-left (matches existing SpriteKit HUD nodes).
/// Add content directly as children, or into `content` for clarity.
final class GlassPanel: SKNode {

    let panelSize: CGSize
    private let background: SKShapeNode
    let content = SKNode()

    init(size: CGSize,
         borderColor: SKColor = MissionControlTheme.glassBorderColor,
         showBrackets: Bool = true) {
        self.panelSize = size
        let rect = CGRect(origin: .zero, size: size)
        self.background = SKShapeNode(rect: rect, cornerRadius: MissionControlTheme.cornerRadius)
        super.init()

        background.fillColor = MissionControlTheme.glassFillColor
        background.strokeColor = borderColor
        background.lineWidth = 1
        addChild(background)
        addChild(content)

        if showBrackets { addCornerBrackets(in: rect) }
    }

    required init?(coder aDecoder: NSCoder) {
        self.panelSize = .zero
        self.background = SKShapeNode()
        super.init(coder: aDecoder)
    }

    /// Update the border accent (e.g., to a satellite class color).
    func setBorder(_ color: SKColor) { background.strokeColor = color }

    private func addCornerBrackets(in rect: CGRect) {
        let len: CGFloat = 8
        let inset: CGFloat = 1
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // each: (corner, horizontal end, vertical end)
            (CGPoint(x: inset, y: rect.maxY - inset),            // top-left
             CGPoint(x: inset + len, y: rect.maxY - inset),
             CGPoint(x: inset, y: rect.maxY - inset - len)),
            (CGPoint(x: rect.maxX - inset, y: rect.maxY - inset), // top-right
             CGPoint(x: rect.maxX - inset - len, y: rect.maxY - inset),
             CGPoint(x: rect.maxX - inset, y: rect.maxY - inset - len)),
            (CGPoint(x: inset, y: inset),                         // bottom-left
             CGPoint(x: inset + len, y: inset),
             CGPoint(x: inset, y: inset + len)),
            (CGPoint(x: rect.maxX - inset, y: inset),             // bottom-right
             CGPoint(x: rect.maxX - inset - len, y: inset),
             CGPoint(x: rect.maxX - inset, y: inset + len))
        ]
        for (corner, h, v) in corners {
            let path = CGMutablePath()
            path.move(to: h); path.addLine(to: corner); path.addLine(to: v)
            let bracket = SKShapeNode(path: path)
            bracket.strokeColor = MissionControlTheme.bracketColor
            bracket.lineWidth = 1
            bracket.lineCap = .square
            addChild(bracket)
        }
    }
}

// MARK: - HUD label helper

extension SKLabelNode {
    /// Convenience for an Astra-styled monospaced label.
    static func hudLabel(_ text: String,
                         size: CGFloat,
                         color: SKColor,
                         weight: NSFont.Weight = .regular,
                         hAlign: SKLabelHorizontalAlignmentMode = .left,
                         vAlign: SKLabelVerticalAlignmentMode = .center) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: MissionControlTheme.hudFontName(weight: weight))
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.horizontalAlignmentMode = hAlign
        node.verticalAlignmentMode = vAlign
        return node
    }
}
