import Foundation

/// Database of notable satellites for discovery system
struct NotableSatellites {
    
    /// All notable satellites with their details
    static let all: [NotableSatellite] = [
        // ISS and Crewed
        NotableSatellite(
            name: "ISS",
            noradId: "25544",
            type: .crewed,
            country: "International",
            description: "International Space Station - largest object in orbit",
            emoji: "🏠"
        ),
        NotableSatellite(
            name: "Tiangong",
            noradId: "48274",
            type: .crewed,
            country: "China",
            description: "Chinese Space Station",
            emoji: "🇨🇳"
        ),
        
        // Hubble and Telescopes
        NotableSatellite(
            name: "Hubble Space Telescope",
            noradId: "20580",
            type: .telescope,
            country: "USA",
            description: "Legendary space telescope launched 1990",
            emoji: "🔭"
        ),
        NotableSatellite(
            name: "James Webb",
            noradId: "50463",
            type: .telescope,
            country: "International",
            description: "James Webb Space Telescope - newest旗舰",
            emoji: "🕳️"
        ),
        
        // Starlink
        NotableSatellite(
            name: "Starlink",
            noradId: nil,
            type: .constellation,
            country: "USA",
            description: "SpaceX constellation - thousands of satellites",
            emoji: "📡"
        ),
        
        // GPS
        NotableSatellite(
            name: "GPS BIIR-2",
            noradId: "24876",
            type: .navigation,
            country: "USA",
            description: "GPS satellite - you use it every day",
            emoji: "📍"
        ),
        NotableSatellite(
            name: "Galileo",
            noradId: nil,
            type: .navigation,
            country: "EU",
            description: "European navigation constellation",
            emoji: "🗺️"
        ),
        
        // Russian
        NotableSatellite(
            name: "Kosmos 2542",
            noradId: "44710",
            type: .military,
            country: "Russia",
            description: "Russian inspection satellite",
            emoji: "👁️"
        ),
        
        // Weather
        NotableSatellite(
            name: "GOES-16",
            noradId: "41866",
            type: .weather,
            country: "USA",
            description: "Weather satellite - watches hurricanes",
            emoji: "🌀"
        ),
        NotableSatellite(
            name: "Meteosat",
            noradId: nil,
            type: .weather,
            country: "EU",
            description: "European weather satellite",
            emoji: "🌤️"
        ),
        
        // Communications
        NotableSatellite(
            name: "Intelsat",
            noradId: nil,
            type: .communications,
            country: "USA",
            description: "Commercial communications satellite",
            emoji: "📱"
        ),
        
        // Chinese
        NotableSatellite(
            name: "Beidou",
            noradId: nil,
            type: .navigation,
            country: "China",
            description: "Chinese GPS competitor",
            emoji: "🧭"
        ),
        
        // Other notable
        NotableSatellite(
            name: "Landsat 8",
            noradId: "39084",
            type: .earthObservation,
            country: "USA",
            description: "Earth observation satellite",
            emoji: "🌍"
        ),
        NotableSatellite(
            name: "Sentinel-1",
            noradId: "39634",
            type: .earthObservation,
            country: "EU",
            description: "European Earth radar",
            emoji: "🛰️"
        )
    ]
    
    /// Get satellite by NORAD ID
    static func satellite(noradId: String) -> NotableSatellite? {
        return all.first { $0.noradId == noradId }
    }
    
    /// Get satellite by name (partial match)
    static func find(name: String) -> NotableSatellite? {
        let lowercased = name.lowercased()
        return all.first { $0.name.lowercased().contains(lowercased) || 
                         $0.noradId?.lowercased() == lowercased }
    }
    
    /// Get all satellites of a specific type
    static func satellites(of type: SatelliteType) -> [NotableSatellite] {
        return all.filter { $0.type == type }
    }
    
    /// Get all satellites for a specific country
    static func satellites(from country: String) -> [NotableSatellite] {
        return all.filter { $0.country == country }
    }
    
    /// Check if a name matches a notable satellite
    static func isNotable(_ name: String) -> NotableSatellite? {
        return find(name: name)
    }
}

/// A notable satellite definition
struct NotableSatellite {
    let name: String
    let noradId: String?
    let type: SatelliteType
    let country: String
    let description: String
    let emoji: String
    
    var countryColor: String {
        switch country {
        case "USA": return "usa"
        case "Russia": return "russia"
        case "China": return "china"
        default: return "other"
        }
    }
}

/// Satellite types for categorization
enum SatelliteType: String, CaseIterable {
    case crewed = "Crewed"
    case telescope = "Telescope"
    case navigation = "Navigation"
    case communications = "Communications"
    case earthObservation = "Earth Observation"
    case weather = "Weather"
    case military = "Military"
    case constellation = "Constellation"
    case scientific = "Scientific"
    case other = "Other"
    
    var defaultColor: String {
        switch self {
        case .crewed: return "magenta"
        case .telescope: return "cyan"
        case .navigation: return "amber"
        case .communications: return "white"
        case .earthObservation: return "green"
        case .weather: return "blue"
        case .military: return "red"
        case .constellation: return "cyan"
        case .scientific: return "purple"
        case .other: return "white"
        }
    }
}

/// Country of origin helper
enum SatelliteCountry: String, CaseIterable {
    case usa = "USA"
    case russia = "Russia"
    case china = "China"
    case eu = "EU"
    case japan = "Japan"
    case india = "India"
    case international = "International"
    case other = "Other"
    
    var color: String {
        switch self {
        case .usa: return "usa"
        case .russia: return "russia"
        case .china: return "china"
        case .eu, .japan, .india: return "other"
        case .international, .other: return "white"
        }
    }
    
    var flag: String {
        switch self {
        case .usa: return "🇺🇸"
        case .russia: return "🇷🇺"
        case .china: return "🇨🇳"
        case .eu: return "🇪🇺"
        case .japan: return "🇯🇵"
        case .india: return "🇮🇳"
        case .international: return "🌍"
        case .other: return "🛰️"
        }
    }
}
