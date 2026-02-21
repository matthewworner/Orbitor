# Change Log

All notable changes to Nature vs Noise Screensaver.

## [2026-02-21] - Hybrid Rendering & Data-Driven Visualization

### Added
- **Metal Full-Screen Rendering Fix** (`MetalSatelliteRenderer.swift`)
  - Added `render(into:camera:)` method for SceneKit delegate integration
  - Metal now works in full-screen mode via `SCNSceneRendererDelegate`
  - Uses `currentRenderCommandEncoder` to share SceneKit's render pass
  - Eliminates black screen issue that previously forced Metal to be disabled

- **Satellite Classification System** (`SatelliteClassification.swift`)
  - New `SatelliteClass` enum: `.iss`, `.starlink`, `.notable`, `.activeSatellite`, `.debris`
  - `SatelliteClassifier` for data-driven visual treatment
  - `SatelliteLOD` for distance-based detail levels
  - Pattern matching for ISS, Starlink, and notable satellites

- **Data-Driven Satellite Rendering** (`SatelliteRenderer.swift`)
  - Different visual treatments per satellite class
  - Debris renders as dark irregular chunks
  - Starlink renders as flat "pizza box" panels
  - Active satellites use gold foil + solar panel template
  - Hero satellites (ISS, Hubble, etc.) use 3D models

- **NASA 3D Model Integration** (`SatelliteRenderer.swift`)
  - Loads existing `.glb` models from Resources/Models
  - Hubble, TESS, TDRS, Juno models now render for notable satellites
  - Procedural ISS and CubeSat placeholders when models unavailable

- **Motion Trails** (`SatelliteRenderer.swift`)
  - Implemented `addMotionTrails()` with line geometry
  - Fading trails show orbital path history
  - Trail positions tracked over last 10 frames

- **Material Effects** (`SatelliteRenderer.swift`)
  - `applyMaterialAging()`: Older satellites appear weathered
    - New (< 5 years): smooth, bright emission
    - Moderate (5-15 years): medium roughness
    - Old (15+ years): rough, dim
  - `applyThermalGlow()`: Velocity-based emission tint
    - Fast LEO satellites: warm orange glow
    - Slow GEO satellites: cool blue tint

- **Frame-Synchronized Updates** (`NatureVsNoiseView.swift`)
  - Removed `Timer.scheduledTimer` for satellite updates
  - Updates now happen in `renderer(_:updateAtTime:)`
  - Synchronized to display refresh rate (no micro-stuttering)

- **Feature Flags Update** (`FeatureFlags.swift`)
  - `enableSwarm` now defaults to `true` (Metal fixed)
  - Added `fullPreset` for all features enabled
  - Added `applyFullPreset()` method

### Fixed
- **Black Screen in Full-Screen Mode**
  - Root cause: Metal renderer had no connection to ScreenSaverView display
  - Solution: Use SceneKit's `currentRenderCommandEncoder` via delegate
  - Metal and SceneKit now share the same render pass

- **Timer Stuttering**
  - Timer was not synchronized with display refresh
  - Satellite positions now update in `SCNSceneRendererDelegate` callback

- **StatsPanel Closure Capture**
  - Fixed `self.` capture semantics in `SKAction.customAction` closure

### Changed
- **Hybrid Rendering Architecture**
  - SceneKit renders: Planets + 50 hero satellites
  - Metal renders: 5000+ swarm points
  - Both in same render pass for seamless integration

- **Satellite Manager API**
  - Added `classifySatellite()` method
  - Added `calculateAge()` method  
  - Added `getClassificationData()` for batch operations

### Technical Details

#### SceneKit-Metal Integration
```swift
// In SCNSceneRendererDelegate
func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    if useMetalRendering, let metalRenderer = metalRenderer, let cameraNode = cameraNode {
        metalRenderer.render(into: renderer, camera: cameraNode)
    }
}

// In MetalSatelliteRenderer
func render(into renderer: SCNSceneRenderer, camera: SCNNode) {
    guard let renderEncoder = renderer.currentRenderCommandEncoder else { return }
    // Encode draw commands into SceneKit's render pass
    renderEncoder.setRenderPipelineState(renderPipeline)
    renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: satelliteCount)
}
```

#### Classification Flow
```swift
// SatelliteManager provides classification data
let classifications = satellites.map { satelliteManager.classifySatellite($0) }
let ages = satellites.map { satelliteManager.calculateAge($0) }

// SatelliteRenderer applies visual treatment
satelliteRenderer.updateSatellites(
    positions: positions,
    colors: colors,
    velocities: velocities,
    names: names,
    classifications: classifications,  // NEW
    ages: ages,                         // NEW
    earthOffset: earthOffset
)
```

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
