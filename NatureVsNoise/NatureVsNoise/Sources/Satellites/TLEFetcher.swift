import Foundation

// MARK: - TLE Fetcher Errors

enum TLEFetcherError: Error, LocalizedError {
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int)
    case parsingError(category: String, reason: String)
    case cacheCorrupted
    case noDataAvailable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "Invalid server response: HTTP \(code)"
        case .parsingError(let category, let reason):
            return "Failed to parse \(category) TLE data: \(reason)"
        case .cacheCorrupted:
            return "TLE cache is corrupted"
        case .noDataAvailable:
            return "No TLE data available"
        }
    }
}

// MARK: - TLE Validation Result

struct TLEValidationResult {
    let isValid: Bool
    let satelliteName: String
    let line1: String
    let line2: String
    let errors: [String]
    
    static func invalid(errors: [String]) -> TLEValidationResult {
        return TLEValidationResult(isValid: false, satelliteName: "", line1: "", line2: "", errors: errors)
    }
}

// MARK: - Fetch Statistics

struct TLEFetchStatistics {
    let category: String
    let totalLines: Int
    let validSatellites: Int
    let invalidEntries: Int
    let fetchDuration: TimeInterval
    let timestamp: Date
}

// MARK: - TLE Fetcher

/// Fetches, validates, and caches TLE (Two-Line Element) data for satellites
/// Implements robust error handling, checksum validation, and statistics tracking
class TLEFetcher {
    
    // MARK: - Properties
    
    private let cacheDirectory: URL
    private let session: URLSession
    private var lastFetchStatistics: [TLEFetchStatistics] = []
    
    /// CelesTrak API endpoints for different satellite categories
    private let tleEndpoints: [(category: String, url: String, priority: Int)] = [
        ("active", "https://celestrak.org/NORAD/elements/gp.php?GROUP=active&FORMAT=tle", 1),
        ("starlink", "https://celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=tle", 2),
        ("stations", "https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle", 1),
        ("debris", "https://celestrak.org/NORAD/elements/gp.php?GROUP=1982-092&FORMAT=tle", 3),
        ("cosmos_debris", "https://celestrak.org/NORAD/elements/gp.php?GROUP=cosmos-2251-debris&FORMAT=tle", 3),
        ("fengyun_debris", "https://celestrak.org/NORAD/elements/gp.php?GROUP=fengyun-1c-debris&FORMAT=tle", 3),
        ("iridium_debris", "https://celestrak.org/NORAD/elements/gp.php?GROUP=iridium-33-debris&FORMAT=tle", 3)
    ]
    
    // MARK: - Initialization
    
    init() {
        // Create cache directory in app support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("NatureVsNoise/TLECache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }
    
    // MARK: - Cache Management
    
    /// Load cached TLE data if available and not too old
    /// - Parameter maxAge: Maximum cache age in seconds (default 24 hours)
    /// - Returns: Dictionary of category → TLE content, or nil if cache is stale/missing
    func loadCachedTLEData(maxAge: TimeInterval = 86400) -> [String: String]? {
        let cacheFile = cacheDirectory.appendingPathComponent("tle_data.json")
        
        guard let data = try? Data(contentsOf: cacheFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tleData = json["data"] as? [String: String],
              let timestamp = json["timestamp"] as? TimeInterval else {
            #if DEBUG
            print("📡 TLEFetcher: No valid cache found")
            #endif
            return nil
        }
        
        // Check cache freshness
        let age = Date().timeIntervalSince1970 - timestamp
        guard age < maxAge else {
            #if DEBUG
            print("📡 TLEFetcher: Cache expired (age: \(Int(age/3600))h)")
            #endif
            return nil
        }
        
        #if DEBUG
        print("✅ TLEFetcher: Loaded cache (age: \(Int(age/60))min, \(tleData.count) categories)")
        #endif
        
        return tleData
    }
    
    /// Get cache age in seconds, or nil if no cache exists
    var cacheAge: TimeInterval? {
        let cacheFile = cacheDirectory.appendingPathComponent("tle_data.json")
        
        guard let data = try? Data(contentsOf: cacheFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let timestamp = json["timestamp"] as? TimeInterval else {
            return nil
        }
        
        return Date().timeIntervalSince1970 - timestamp
    }
    
    // MARK: - Data Fetching
    
    /// Fetch fresh TLE data from CelesTrak with validation
    /// - Parameter categories: Optional filter for specific categories (nil = fetch all)
    /// - Returns: Dictionary of category → validated TLE content
    func fetchTLEData(categories: [String]? = nil) async throws -> [String: String] {
        var tleData: [String: String] = [:]
        var fetchErrors: [String] = []
        
        let endpoints = categories != nil
            ? tleEndpoints.filter { categories!.contains($0.category) }
            : tleEndpoints
        
        for endpoint in endpoints {
            let startTime = Date()
            
            do {
                guard let url = URL(string: endpoint.url) else {
                    fetchErrors.append("Invalid URL for \(endpoint.category)")
                    continue
                }
                
                let (data, response) = try await session.data(from: url)
                
                // Validate HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    guard (200...299).contains(httpResponse.statusCode) else {
                        fetchErrors.append("\(endpoint.category): HTTP \(httpResponse.statusCode)")
                        continue
                    }
                }
                
                guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
                    fetchErrors.append("\(endpoint.category): Empty response")
                    continue
                }
                
                // Validate TLE content
                let validationResult = validateTLEContent(content, category: endpoint.category)
                
                if validationResult.validCount > 0 {
                    tleData[endpoint.category] = content
                    
                    let duration = Date().timeIntervalSince(startTime)
                    let stats = TLEFetchStatistics(
                        category: endpoint.category,
                        totalLines: content.components(separatedBy: .newlines).count,
                        validSatellites: validationResult.validCount,
                        invalidEntries: validationResult.invalidCount,
                        fetchDuration: duration,
                        timestamp: Date()
                    )
                    lastFetchStatistics.append(stats)
                    
                    #if DEBUG
                    print("✅ TLEFetcher: \(endpoint.category) - \(validationResult.validCount) satellites (\(String(format: "%.2f", duration))s)")
                    #endif
                } else {
                    fetchErrors.append("\(endpoint.category): No valid TLE entries")
                }
                
            } catch {
                fetchErrors.append("\(endpoint.category): \(error.localizedDescription)")
                #if DEBUG
                print("❌ TLEFetcher: \(endpoint.category) failed - \(error.localizedDescription)")
                #endif
            }
        }
        
        // Cache the data if we got anything
        if !tleData.isEmpty {
            saveToCache(tleData)
        }
        
        // Report errors but don't fail if we have some data
        if tleData.isEmpty {
            throw TLEFetcherError.noDataAvailable
        }
        
        if !fetchErrors.isEmpty {
            #if DEBUG
            print("⚠️ TLEFetcher: Fetch completed with errors: \(fetchErrors.joined(separator: ", "))")
            #endif
        }
        
        return tleData
    }
    
    // MARK: - TLE Validation
    
    /// Validate a single TLE entry (name + line1 + line2)
    func validateTLE(name: String, line1: String, line2: String) -> TLEValidationResult {
        var errors: [String] = []
        
        let trimmedLine1 = line1.trimmingCharacters(in: .whitespaces)
        let trimmedLine2 = line2.trimmingCharacters(in: .whitespaces)
        
        // Length validation
        if trimmedLine1.count < 69 {
            errors.append("Line 1 too short (\(trimmedLine1.count) chars, need 69)")
        }
        if trimmedLine2.count < 69 {
            errors.append("Line 2 too short (\(trimmedLine2.count) chars, need 69)")
        }
        
        // Line number validation
        if !trimmedLine1.hasPrefix("1 ") {
            errors.append("Line 1 doesn't start with '1 '")
        }
        if !trimmedLine2.hasPrefix("2 ") {
            errors.append("Line 2 doesn't start with '2 '")
        }
        
        // Checksum validation
        if trimmedLine1.count >= 69 {
            let expectedChecksum1 = calculateChecksum(String(trimmedLine1.prefix(68)))
            let actualChecksum1 = Int(String(trimmedLine1.last!)) ?? -1
            if expectedChecksum1 != actualChecksum1 {
                errors.append("Line 1 checksum mismatch (expected \(expectedChecksum1), got \(actualChecksum1))")
            }
        }
        
        if trimmedLine2.count >= 69 {
            let expectedChecksum2 = calculateChecksum(String(trimmedLine2.prefix(68)))
            let actualChecksum2 = Int(String(trimmedLine2.last!)) ?? -1
            if expectedChecksum2 != actualChecksum2 {
                errors.append("Line 2 checksum mismatch (expected \(expectedChecksum2), got \(actualChecksum2))")
            }
        }
        
        // Catalog number match validation
        if trimmedLine1.count >= 7 && trimmedLine2.count >= 7 {
            let catNum1 = trimmedLine1.substring(2, 7).trimmingCharacters(in: .whitespaces)
            let catNum2 = trimmedLine2.substring(2, 7).trimmingCharacters(in: .whitespaces)
            if catNum1 != catNum2 {
                errors.append("Catalog number mismatch (\(catNum1) vs \(catNum2))")
            }
        }
        
        return TLEValidationResult(
            isValid: errors.isEmpty,
            satelliteName: name.trimmingCharacters(in: .whitespaces),
            line1: trimmedLine1,
            line2: trimmedLine2,
            errors: errors
        )
    }
    
    /// Calculate TLE line checksum (modulo 10 checksum algorithm)
    private func calculateChecksum(_ line: String) -> Int {
        var checksum = 0
        for char in line {
            if let digit = Int(String(char)) {
                checksum += digit
            } else if char == "-" {
                checksum += 1
            }
            // Letters, spaces, periods, and '+' count as 0
        }
        return checksum % 10
    }
    
    /// Validate all TLE entries in content and return statistics
    private func validateTLEContent(_ content: String, category: String) -> (validCount: Int, invalidCount: Int) {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var validCount = 0
        var invalidCount = 0
        
        var i = 0
        while i < lines.count - 2 {
            let name = lines[i]
            let line1 = lines[i + 1]
            let line2 = lines[i + 2]
            
            // Quick check: if line1 starts with "1 " and line2 starts with "2 ", it's a TLE triplet
            if line1.hasPrefix("1 ") && line2.hasPrefix("2 ") {
                let result = validateTLE(name: name, line1: line1, line2: line2)
                if result.isValid {
                    validCount += 1
                } else {
                    invalidCount += 1
                    #if DEBUG
                    if invalidCount <= 5 {
                        print("⚠️ Invalid TLE '\(name.prefix(20))': \(result.errors.joined(separator: ", "))")
                    }
                    #endif
                }
                i += 3
            } else {
                // Not a TLE triplet, skip this line
                i += 1
            }
        }
        
        return (validCount, invalidCount)
    }
    
    // MARK: - Cache Storage
    
    private func saveToCache(_ data: [String: String]) {
        let cacheFile = cacheDirectory.appendingPathComponent("tle_data.json")
        
        let cacheData: [String: Any] = [
            "data": data,
            "timestamp": Date().timeIntervalSince1970,
            "version": 2  // Cache format version for future migrations
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cacheData, options: .prettyPrinted)
            try jsonData.write(to: cacheFile)
            #if DEBUG
            print("💾 TLEFetcher: Cache saved (\(jsonData.count / 1024) KB)")
            #endif
        } catch {
            #if DEBUG
            print("❌ TLEFetcher: Failed to save cache - \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Clear the TLE cache
    func clearCache() {
        let cacheFile = cacheDirectory.appendingPathComponent("tle_data.json")
        try? FileManager.default.removeItem(at: cacheFile)
        #if DEBUG
        print("🗑️ TLEFetcher: Cache cleared")
        #endif
    }
    
    // MARK: - Statistics
    
    /// Get statistics from the last fetch operation
    var fetchStatistics: [TLEFetchStatistics] {
        return lastFetchStatistics
    }
    
    /// Get total satellite count from last fetch
    var totalSatelliteCount: Int {
        return lastFetchStatistics.reduce(0) { $0 + $1.validSatellites }
    }
}

// MARK: - String Extension for TLE Parsing

private extension String {
    /// Safe substring extraction for TLE parsing
    func substring(_ start: Int, _ end: Int) -> String {
        let startIdx = index(startIndex, offsetBy: min(start, count), limitedBy: endIndex) ?? endIndex
        let endIdx = index(startIndex, offsetBy: min(end, count), limitedBy: endIndex) ?? endIndex
        return String(self[startIdx..<endIdx])
    }
}