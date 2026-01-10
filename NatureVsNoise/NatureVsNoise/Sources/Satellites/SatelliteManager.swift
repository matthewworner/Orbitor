import Foundation

/// Enhanced satellite manager with SGP4 propagation and metadata
class SatelliteManager {

    // MARK: - Satellite Data Structures

    struct Satellite {
        let name: String
        let catalogNumber: Int
        let classification: String
        let internationalDesignator: String
        let epoch: Double
        let meanMotionFirstDerivative: Double
        let meanMotionSecondDerivative: Double
        let bStar: Double
        let ephemerisType: Int
        let elementSetNumber: Int
        let inclination: Double
        let raan: Double
        let eccentricity: Double
        let argumentOfPerigee: Double
        let meanAnomaly: Double
        let meanMotion: Double
        let revolutionNumber: Int

        // Derived properties
        var country: String {
            // Extract country code from international designator
            let designator = internationalDesignator
            if designator.count >= 2 {
                let countryCode = String(designator.prefix(2))
                return countryCode
            }
            return "UNK"
        }

        var isDebris: Bool {
            // Classify as debris based on name patterns
            let lowerName = name.lowercased()
            return lowerName.contains("debris") ||
                   lowerName.contains("fragment") ||
                   lowerName.contains("slag") ||
                   lowerName.contains("shroud") ||
                   lowerName.contains("bolt") ||
                   lowerName.contains("cap") ||
                   lowerName.contains("clamp") ||
                   lowerName.contains("lens") ||
                   lowerName.contains("cosmos") && lowerName.contains("debris")
        }

        var organization: String {
            // Map country codes to organizations
            switch country {
            case "US": return "NASA/DoD"
            case "RU", "SU": return "Roscosmos"
            case "CN": return "CNSA"
            case "EU": return "ESA"
            case "JP": return "JAXA"
            case "IN": return "ISRO"
            case "KR": return "KARI"
            case "CA": return "CSA"
            case "AU": return "CSIRO"
            case "BR": return "INPE"
            case "AR": return "CONAE"
            case "IL": return "ISA"
            case "TH": return "GISTDA"
            case "TR": return "TUBITAK"
            case "ZA": return "SANSA"
            case "NG": return "NASRDA"
            case "KE": return "KARI"
            default: return "Private/Other"
            }
        }
    }

    // MARK: - Properties

    var satellites: [Satellite] = []
    private weak var bundle: Bundle?
    private let tleFetcher = TLEFetcher()
    private var updateTimer: Timer?

    // MARK: - Initialization

    init(bundle: Bundle? = nil) {
        self.bundle = bundle
        loadTLEData()
        startUpdateScheduler()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: - TLE Loading and Parsing

    private func loadTLEData() {
        // First try to load from cache
        if let cachedData = tleFetcher.loadCachedTLEData() {
            parseTLEData(cachedData)
            #if DEBUG
            print("✅ SatelliteManager: Loaded \(satellites.count) satellites from cache")
            #endif
            return
        }

        // Fallback to bundled files if cache is empty
        loadBundledTLEData()

        // Start async fetch for fresh data
        fetchFreshTLEData()
    }

    private func loadBundledTLEData() {
        // Load multiple TLE files for comprehensive coverage
        let tleFiles = [
            "active_satellites",
            "starlink",
            "iss",
            "debris"
        ]

        for fileName in tleFiles {
            if let content = loadTLEContent(named: fileName) {
                parseTLEContent(content)
            }
        }

        #if DEBUG
        print("✅ SatelliteManager: Loaded \(satellites.count) satellites from bundle")
        #endif
    }

    private func fetchFreshTLEData() {
        Task {
            do {
                let freshData = try await tleFetcher.fetchTLEData()
                parseTLEData(freshData)
                #if DEBUG
                print("✅ SatelliteManager: Updated with \(satellites.count) fresh satellites")
                #endif
            } catch {
                #if DEBUG
                print("❌ SatelliteManager: Failed to fetch fresh TLE data: \(error)")
                #endif
            }
        }
    }

    private func parseTLEData(_ data: [String: String]) {
        satellites.removeAll()

        for (category, content) in data {
            #if DEBUG
            print("📡 Parsing \(category) TLE data...")
            #endif
            parseTLEContent(content)
        }
    }

    private func loadTLEContent(named name: String) -> String? {
        let bundle = self.bundle ?? Bundle.main

        // Priority 1: Bundle resources
        if let bundlePath = bundle.path(forResource: name, ofType: "tle") {
            return try? String(contentsOfFile: bundlePath)
        }

        // Priority 2: Bundle Resources/Data subdirectory
        if let resourcePath = bundle.resourcePath {
            let dataPath = "\(resourcePath)/Data/\(name).tle"
            if FileManager.default.fileExists(atPath: dataPath) {
                return try? String(contentsOfFile: dataPath)
            }
        }

        // Priority 3: Development fallback
        let devPath = "/Users/pro/Projects/Screensaver/Assets/Raw/Data/\(name).tle"
        if FileManager.default.fileExists(atPath: devPath) {
            return try? String(contentsOfFile: devPath)
        }

        return nil
    }

    private func parseTLEContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        var i = 0
        while i < lines.count - 2 {
            let name = lines[i]
            let line1 = lines[i+1]
            let line2 = lines[i+2]

            if let satellite = parseTLE(name: name, line1: line1, line2: line2) {
                satellites.append(satellite)
            }

            i += 3
        }
    }

    private func parseTLE(name: String, line1: String, line2: String) -> Satellite? {
        // Parse line 1
        guard line1.count >= 69 else { return nil }
        let line1Chars = Array(line1)

        let classification = String(line1Chars[7])
        let internationalDesignator = String(line1Chars[9..<17]).trimmingCharacters(in: .whitespaces)
        let epochYearStr = String(line1Chars[18..<20])
        let epochDayStr = String(line1Chars[20..<32]).trimmingCharacters(in: .whitespaces)
        let meanMotionFirstDerivativeStr = String(line1Chars[33..<43]).trimmingCharacters(in: .whitespaces)
        let meanMotionSecondDerivativeStr = String(line1Chars[44..<52]).trimmingCharacters(in: .whitespaces)
        let bStarStr = String(line1Chars[53..<61]).trimmingCharacters(in: .whitespaces)
        let ephemerisType = Int(String(line1Chars[62]).trimmingCharacters(in: .whitespaces)) ?? 0
        let elementSetNumberStr = String(line1Chars[64..<68]).trimmingCharacters(in: .whitespaces)

        guard let catalogNumber = Int(String(line1Chars[2..<7]).trimmingCharacters(in: .whitespaces)),
              let epochYear = Int(epochYearStr),
              let epochDay = Double(epochDayStr),
              let meanMotionFirstDerivative = Double(meanMotionFirstDerivativeStr),
              let elementSetNumber = Int(elementSetNumberStr)
        else { return nil }

        // Parse line 2
        guard line2.count >= 69 else { return nil }
        let line2Chars = Array(line2)

        let eccentricityStr = String(line2Chars[26..<33]).trimmingCharacters(in: .whitespaces)

        guard let inclination = Double(String(line2Chars[8..<16]).trimmingCharacters(in: .whitespaces)),
              let raan = Double(String(line2Chars[17..<25]).trimmingCharacters(in: .whitespaces)),
              let argumentOfPerigee = Double(String(line2Chars[34..<42]).trimmingCharacters(in: .whitespaces)),
              let meanAnomaly = Double(String(line2Chars[43..<51]).trimmingCharacters(in: .whitespaces)),
              let meanMotion = Double(String(line2Chars[52..<63]).trimmingCharacters(in: .whitespaces)),
              let revolutionNumber = Int(String(line2Chars[63..<68]).trimmingCharacters(in: .whitespaces))
        else { return nil }

        // Convert epoch to Julian date
        let epoch = calculateEpoch(epochYear: epochYear, epochDay: epochDay)

        // Parse derivatives and B*
        let meanMotionSecondDerivative = parseDerivative(meanMotionSecondDerivativeStr)
        let bStar = parseBStar(bStarStr)

        // Parse eccentricity (remove leading decimal)
        let eccentricity = Double("0." + eccentricityStr) ?? 0.0

        return Satellite(
            name: name.trimmingCharacters(in: .whitespaces),
            catalogNumber: catalogNumber,
            classification: classification,
            internationalDesignator: internationalDesignator,
            epoch: epoch,
            meanMotionFirstDerivative: meanMotionFirstDerivative,
            meanMotionSecondDerivative: meanMotionSecondDerivative,
            bStar: bStar,
            ephemerisType: ephemerisType,
            elementSetNumber: elementSetNumber,
            inclination: inclination * .pi / 180.0, // Convert to radians
            raan: raan * .pi / 180.0,
            eccentricity: eccentricity,
            argumentOfPerigee: argumentOfPerigee * .pi / 180.0,
            meanAnomaly: meanAnomaly * .pi / 180.0,
            meanMotion: meanMotion,
            revolutionNumber: revolutionNumber
        )
    }

    private func calculateEpoch(epochYear: Int, epochDay: Double) -> Double {
        // Convert TLE epoch to Julian date
        let year = epochYear < 57 ? 2000 + epochYear : 1900 + epochYear
        let dayOfYear = epochDay

        // Simplified Julian date calculation
        let a = (14 - 1) / 12
        let y = year + 4800 - a
        let m = 1 + 12 * a - 3

        let term1 = Double(dayOfYear)
        let term2 = Double((153 * m + 2) / 5)
        let term3 = 365 * Double(y)
        let term4 = Double(y) / 4
        let term5 = Double(y) / 100
        let term6 = Double(y) / 400
        let julianDay = term1 + term2 + term3 + term4 - term5 + term6 - 32045

        return julianDay
    }

    private func parseDerivative(_ str: String) -> Double {
        guard !str.isEmpty else { return 0.0 }
        let sign = str.hasPrefix("-") ? -1.0 : 1.0
        let magnitude = Double(str.trimmingCharacters(in: CharacterSet(charactersIn: "-+ "))) ?? 0.0
        let exponent = str.contains("e") ? 0.0 : -5.0 // TLE format implies ×10^-5
        return sign * magnitude * pow(10.0, exponent)
    }

    private func parseBStar(_ str: String) -> Double {
        guard !str.isEmpty else { return 0.0 }
        let sign = str.hasPrefix("-") ? -1.0 : 1.0
        let magnitude = Double(str.trimmingCharacters(in: CharacterSet(charactersIn: "-+ "))) ?? 0.0
        let exponent = str.contains("e") ? 0.0 : -5.0 // TLE format implies ×10^-5
        return sign * magnitude * pow(10.0, exponent)
    }

    // MARK: - Update Scheduler
    
    private func startUpdateScheduler() {
        // Schedule hourly TLE data updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.fetchFreshTLEData()
        }
    }
    
    // MARK: - SGP4 Propagation
    
    /// Time acceleration factor (PRD specifies 50-500× real-time, default 100×)
    var timeAcceleration: Double = 100.0

    /// Calculate satellite position and velocity using complete SGP4 algorithm
    /// - Parameters:
    ///   - satellite: The satellite to calculate position for
    ///   - animationTime: Animation time in seconds since app start
    /// - Returns: Position (km) and velocity (km/s) in ECI frame
    func getPositionAndVelocity(for satellite: Satellite, at animationTime: Double) -> (position: SIMD3<Double>, velocity: SIMD3<Double>) {
        let elements = OrbitalElements(
            epoch: satellite.epoch,
            inclination: satellite.inclination,
            raan: satellite.raan,
            eccentricity: satellite.eccentricity,
            argumentOfPerigee: satellite.argumentOfPerigee,
            meanAnomaly: satellite.meanAnomaly,
            meanMotion: satellite.meanMotion,
            bStar: satellite.bStar,
            revolutionNumber: satellite.revolutionNumber
        )

        let propagator = SGP4Propagator(elements: elements)
        
        // Convert animation time (seconds) to simulated minutes since TLE epoch
        // Apply time acceleration factor (default 100× real-time per PRD)
        let realSecondsElapsed = animationTime
        let simulatedMinutes = (realSecondsElapsed * timeAcceleration) / 60.0
        
        let result = propagator.propagate(minutesSinceEpoch: simulatedMinutes)
        return (position: result.position, velocity: result.velocity)
    }

    // MARK: - Country Coloring

    func colorForSatellite(_ satellite: Satellite) -> SIMD4<Float> {
        // NEON COLORS for maximum visual impact
        switch satellite.country {
        case "US":
            return SIMD4<Float>(0.0, 0.5, 1.0, 1.0) // Electric Blue
        case "RU", "SU":
            return SIMD4<Float>(1.0, 0.0, 0.0, 1.0) // Pure Red
        case "CN":
            return SIMD4<Float>(1.0, 1.0, 0.0, 1.0) // Bright Yellow
        case "EU":
            return SIMD4<Float>(0.0, 1.0, 0.3, 1.0) // Neon Green
        case "JP":
            return SIMD4<Float>(1.0, 0.4, 0.0, 1.0) // Hot Orange
        case "IN":
            return SIMD4<Float>(1.0, 0.0, 1.0, 1.0) // Magenta
        default:
            return SIMD4<Float>(0.8, 0.8, 0.8, 1.0) // Bright White
        }
    }

    func velocityColor(intensity: Float) -> SIMD4<Float> {
        // Color based on orbital velocity (red = fast, blue = slow)
        let clamped = max(0.0, min(1.0, intensity))
        return SIMD4<Float>(
            x: clamped,      // Red increases with speed
            y: 0.5,
            z: 1.0 - clamped, // Blue decreases with speed
            w: 1.0
        )
    }
}