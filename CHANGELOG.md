# Change Log

All notable changes to Nature vs Noise Screensaver.

## [Unreleased]

### Added
- **Metal Compute Shader** (`Sources/Satellites/Shaders.metal`)
  - Added `propagateSatellites` kernel function for GPU-accelerated SGP4 propagation
  - Implements simplified Kepler equation solver on GPU
  - Pre-allocates GPU buffers for 50K satellites
  
- **Motion Trails** (`Sources/Satellites/SatelliteRenderer.swift`)
  - Implemented velocity-based motion trails using SCNTube geometry
  - Updates periodically for performance (every 3 frames)
  - Renders 100 max trails with semi-transparent materials

- **Animation Loop Integration** (`Sources/NatureVsNoiseView.swift`)
  - Fixed `startAnimation()` to call `setupAnimationTimer()`
  - Timer was never being initialized, causing no animation
  - Added `stopAnimation()` override to properly clean up
  - Added frame counter for logging animation progress

- **Audio Integration** (`Sources/NatureVsNoiseView.swift`)
  - AudioController now instantiated in `setupScene()`
  - Updates in `animateOneFrame()` based on camera position
  - Audio crossfades based on nearest planet

- **Cinematic Camera Sequences** (`Sources/NatureVsNoiseView.swift`)
  - Changed from simple fly-through loop to full 12-15 minute tour
  - Now calls `cameraController.startCinematicSequence()`
  - Replaces manual SCNAction sequence with sophisticated choreography

- **Settings UI** (`Sources/NatureVsNoiseView.swift`)
  - `configureSheet` now returns `SettingsController.shared.makeConfigureSheet()`
  - Settings UI is now accessible from System Preferences

### Fixed
- **Bundle Identifier Consistency**
  - `SettingsController.swift`: Changed from `com.antigravity.NatureVsNoise` to `com.naturevsnoise.screensaver`
  - Now consistent with project.pbxproj build settings
  - Fixes UserDefaults not persisting between screensaver and settings

- **Duplicate FeatureFlags**
  - Removed `Sources/FeatureFlags.swift` (static version)
  - Kept `Sources/Satellites/FeatureFlags.swift` (instance-based)
  - Resolves Swift ambiguity and UserDefaults conflicts

- **Country Code Extraction Bug**
  - `SatelliteManager.swift`: Changed from extracting year from international designator
  - Now maps NORAD catalog numbers to actual countries (US, RU, CN, etc.)
  - Based on historical launch data ranges

- **Hardcoded Development Paths**
  - `NatureVsNoiseView.swift`: Removed `/Users/pro/Projects/Screensaver/` fallback paths
  - Now uses only bundle resource paths
  - Fixes deployment issues on other machines

### Removed
- **Old Animation Loop** - Replaced simple SCNAction sequence with cinematic camera controller
- **Static FeatureFlags** - Removed duplicate static version in favor of instance-based
- **Development Fallback Paths** - No longer checks for project directory paths

### Technical Details

#### Motion Trails Implementation
```swift
// SCNTube geometry for trails
// Updates every 3 frames for performance
// 100 max trails with fading
func addMotionTrails(positions: [SIMD3<Float>], ...) {
    // Velocity-based trail direction
    // Semi-transparent emissive materials
}
```

#### Animation Timer Fix
```swift
override func startAnimation() {
    super.startAnimation()
    setupAnimationTimer()  // This was missing!
}
```

#### Country Code Mapping
```swift
// Before: Extracted "20" from "2025-123A" (year, not country)
// After: Maps catalog 40001-50000 to "US"
switch catalogNumber {
case 40001...50000: return "US"
case 25001...27000: return "RU"
case 12001...13000: return "CN"
// ...
}
```

## [2026-01-23] - Initial Assessment Session

### Identified Issues
1. Missing Metal compute shader (propagateSatellites)
2. Animation timer never starting
3. ConfigureSheet not wired (always returns nil)
4. Bundle identifier mismatch
5. Duplicate FeatureFlags files
6. Country code extraction bug (gets year instead of country)
7. Audio controller never instantiated
8. Cinematic sequences never called
9. Motion trails is no-op
10. Hardcoded development paths

### Analysis Completed
- Deep dive of all Swift source files
- Identified 10 major issues blocking functionality
- Reviewed PRD vs actual implementation gaps
- Assessed performance bottlenecks and architectural issues
