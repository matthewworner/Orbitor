import Foundation

/// Educational facts about satellites, orbital mechanics, and space debris
struct EducationalFacts {
    
    /// All educational facts categorized by topic
    static let facts: [FactCategory: [EducationalFact]] = [
        .orbitalMechanics: orbitalMechanicsFacts,
        .spaceDebris: spaceDebrisFacts,
        .satellites: satelliteFacts,
        .history: historyFacts,
        .ISS: issFacts,
        .starlink: starlinkFacts
    ]
    
    // MARK: - Orbital Mechanics Facts
    
    static let orbitalMechanicsFacts: [EducationalFact] = [
        EducationalFact(
            text: "Satellites in LEO complete an orbit every ~90 minutes",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "GPS satellites orbit at 20,200 km - you use them every day",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "The Moon is ~384,400 km away - 10x further than GEO orbit",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Satellites in GEO appear stationary because they match Earth's rotation",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Orbital velocity at LEO is ~7.8 km/s (28,000 km/h)",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Geostationary satellites take 24 hours to orbit - matching Earth's spin",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Polar orbits pass over both poles, useful for Earth observation",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Sun-synchronous orbits maintain consistent lighting for satellite imagery",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "The International Space Station orbits at 408 km - within LEO",
            category: .orbitalMechanics,
            duration: 8
        ),
        EducationalFact(
            text: "Orbital decay causes satellites to slowly fall back to Earth",
            category: .orbitalMechanics,
            duration: 8
        )
    ]
    
    // MARK: - Space Debris Facts
    
    static let spaceDebrisFacts: [EducationalFact] = [
        EducationalFact(
            text: "Over 1 million objects >1cm orbit Earth (mostly untracked)",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "~140 million objects >1mm orbit Earth - most are paint flakes",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "The Kessler Syndrome could cause cascading collisions",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "~100 tons of space debris re-enters Earth's atmosphere annually",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "Most debris burns up on re-entry, but some survives",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "China's 2007 ASAT test created 3,000+ trackable debris pieces",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "Russia's 2021 ASAT test created 1,500+ debris fragments",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "The 2009 Iridium-Cosmos collision created 2,000+ debris pieces",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "ClearSpace-1 (2026) will test active debris removal",
            category: .spaceDebris,
            duration: 8
        ),
        EducationalFact(
            text: "Even a 1cm object impacts with the force of a hand grenade",
            category: .spaceDebris,
            duration: 8
        )
    ]
    
    // MARK: - Satellite Facts
    
    static let satelliteFacts: [EducationalFact] = [
        EducationalFact(
            text: "There are ~11,000 active satellites orbiting Earth",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "The oldest satellite still in orbit is Vanguard 1 (1958)",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Sputnik 1 broadcast for 3 months before battery death",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Satellites can be solar-powered or nuclear-powered",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Some satellites can be seen with the naked eye from Earth",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "The largest satellite constellation is SpaceX Starlink",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Weather satellites help predict hurricanes and save lives",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Communication satellites enable global phone and internet",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "Spy satellites can read license plates from orbit",
            category: .satellites,
            duration: 8
        ),
        EducationalFact(
            text: "CubeSats are tiny satellites often no bigger than a loaf of bread",
            category: .satellites,
            duration: 8
        )
    ]
    
    // MARK: - History Facts
    
    static let historyFacts: [EducationalFact] = [
        EducationalFact(
            text: "Sputnik 1 launched October 4, 1957 - beginning the Space Age",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "Laika the dog became the first Earth orbiter in 1957",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "Explorer 1 was the first US satellite, launched in 1958",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "The first communications satellite was Telstar (1962)",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "Landsat (1972) began continuous Earth observation",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "GPS became fully operational in the 1990s",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "The first commercial satellite constellation was Iridium (1998)",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "SpaceX launched the first Starlink satellites in 2019",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "OneWeb began launching satellites in 2019 to provide global internet",
            category: .history,
            duration: 8
        ),
        EducationalFact(
            text: "As of 2025, over 7,000 Starlink satellites have been launched",
            category: .history,
            duration: 8
        )
    ]
    
    // MARK: - ISS Facts
    
    static let issFacts: [EducationalFact] = [
        EducationalFact(
            text: "The ISS is the largest object ever built in space",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS travels at 7.66 km/s - orbit every 90 minutes",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "Astronauts on the ISS see 16 sunrises and sunsets daily",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS has been continuously occupied since November 2000",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS weighs about 420,000 kg - like a Boeing 747",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS orbits at 408 km above Earth",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS is visible from Earth without a telescope",
            category: .ISS,
            duration: 8
        ),
        EducationalFact(
            text: "The ISS has housed astronauts from 20 different countries",
            category: .ISS,
            duration: 8
        )
    ]
    
    // MARK: - Starlink Facts
    
    static let starlinkFacts: [EducationalFact] = [
        EducationalFact(
            text: "One Starlink launch adds 60 satellites to orbit",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Starlink satellites orbit at 550 km - relatively low LEO",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Starlink satellites use ion thrusters to deorbit at end of life",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Starlink aims to provide internet to remote areas worldwide",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Astronomers worry about Starlink affecting telescope observations",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Each Starlink satellite weighs ~260 kg",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "Starlink has over 4 million subscribers worldwide",
            category: .starlink,
            duration: 8
        ),
        EducationalFact(
            text: "SpaceX has permission for 12,000 Starlink satellites",
            category: .starlink,
            duration: 8
        )
    ]
    
    /// Get a random fact from all categories
    static func randomFact() -> EducationalFact {
        let allFacts = facts.values.flatMap { $0 }
        return allFacts.randomElement() ?? orbitalMechanicsFacts[0]
    }
    
    /// Get a random fact from a specific category
    static func randomFact(from category: FactCategory) -> EducationalFact {
        let categoryFacts = facts[category] ?? orbitalMechanicsFacts
        return categoryFacts.randomElement() ?? orbitalMechanicsFacts[0]
    }
    
    /// Get total fact count
    static var totalCount: Int {
        return facts.values.reduce(0) { $0 + $1.count }
    }
}

/// A single educational fact
struct EducationalFact {
    let text: String
    let category: FactCategory
    let duration: TimeInterval // seconds to display
    
    var emoji: String {
        category.emoji
    }
}

/// Categories for educational facts
enum FactCategory: String, CaseIterable {
    case orbitalMechanics = "Orbital Mechanics"
    case spaceDebris = "Space Debris"
    case satellites = "Satellites"
    case history = "Space History"
    case ISS = "ISS"
    case starlink = "Starlink"
    
    var emoji: String {
        switch self {
        case .orbitalMechanics: return "🛰️"
        case .spaceDebris: return "☄️"
        case .satellites: return "📡"
        case .history: return "📜"
        case .ISS: return "🏠"
        case .starlink: return "📡"
        }
    }
}
