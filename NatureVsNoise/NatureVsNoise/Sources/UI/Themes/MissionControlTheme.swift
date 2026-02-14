import SpriteKit
import AppKit

/// Mission Control inspired color palette and styling
struct MissionControlTheme {
    
    // MARK: - Colors
    
    /// Primary cyan - orbital indicators, active elements
    static let primaryCyan = NSColor(red: 0/255, green: 212/255, blue: 255/255, alpha: 1.0)
    
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
