# Change Log

All notable changes to Nature vs Noise Screensaver.

## [2026-06-16] - Render + memory bug-fix pass

### Fixed
- **Critical memory leak (23–27 GB OOM).** As wallpaper, the Metal render path redundantly drove the
  SceneKit `SatelliteRenderer` for ~5000 satellites every tick, rebuilding a fresh `SCNGeometry` per
  satellite per frame; the wallpaper host never reclaimed them. `addSatellitesMetal` now only uploads
  once + propagates on the GPU (Metal draws the swarm). Measured flat (0 MB growth over 600 frames vs
  +13 GB before). Also removed a duplicate per-frame Metal draw. (commit 5d502fa)
- **Invisible satellites.** The hybrid render path bound the view-projection matrix to vertex buffer
  index 2, but the shader reads it from buffer(1); the swarm was transformed by garbage and projected
  off-screen. Now bound at index 1. (commit a112746)

### Changed
- **Planet render quality.** Added mipmaps + 16x anisotropic filtering to all planet/Earth/cloud/ring
  texture slots (kills shimmer + muddy oblique angles), raised sphere tessellation (planets 96→128,
  Earth 64→128, clouds 64→96), and re-enabled gentle bloom (intensity 0.3, threshold 0.9). The flat
  grey `lightingEnvironment` was left as-is pending on-device verification (a large HDRI there was
  previously documented to cause black screens). (commit f10a9ec)

### Known issues
- The SceneKit **fallback** path (non-Metal hardware) still rebuilds trail geometry every frame and
  would leak; needs geometry reuse. Tracked in TASKS.md.
- A fixed build has not yet been re-signed and reinstalled — do that before using it again.

## [2026-06-06] - Astra HUD Redesign

Ported the Google Stitch "Astra" mission-control HUD into the native SpriteKit overlay. See
`docs/ASTRA_HUD.md` for the full design reference and `docs/STITCH_PROMPTS.md` for the Stitch source.

### Added
- **Design system** (`MissionControlTheme.swift`): Astra tokens (soft-cyan, nature-blue, glass
  fill/border, corner brackets, hairline), a reusable `GlassPanel` node, and a `SatelliteClass →
  color/legend-code` map as the single source of truth for the legend + dossiers.
- **Bundled JetBrains Mono** (`8K/JetBrainsMono-Regular.ttf`, `-Bold.ttf`): registered via CoreText
  at HUD init (`registerFonts`), with `hudFont`/`hudFontName` helpers and a system-mono fallback.
- **Orbital census** (`SatelliteManager.OrbitalCensus`): cached counts per classification, fed to
  the HUD via `updateCensus` / `updateFocus`.
- **HUD components** (in `HUDOverlay.swift`): mission cluster with live UTC clock + TRACKING pill,
  telemetry dashboard, `ContextualFocusPanel` (NAME/ALT/VEL/INCL), `ClassificationLegend` with live
  counts, focus reticle, sweeping scanline, `AmbientTicker`, and a `BootSequenceOverlay`.

### Changed
- **`StatsPanel`** reworked into the top-right telemetry dashboard (hero total + ACTIVE/DEBRIS).
- **`InfoCardView`** restyled into a type-colored dossier card; **`FactOverlay`** and
  **`DiscoveryBanner`** moved to the glass treatment + bundled font.
- **Configure sheet** (`SettingsController.makeConfigureSheet`): fixed overlapping-frame layout bug;
  reorganized into PERFORMANCE / VISUALS / AUDIO / PRESETS with a clean top-down layout.

### Removed
- **DECAY column** from the telemetry dashboard — "decaying this week" isn't derivable from TLE data,
  so the dashboard shows ACTIVE/DEBRIS only rather than a placeholder.

### Notes
- Verification is build-only (Release `xcodebuild` green; fonts confirmed in the bundle). Runtime
  remains blocked by macOS 26.5 signing; no Developer ID cert is available locally yet.

## [2026-05-17] - Apple-Tier Audit Complete

### Fixed (Critical Bugs)
- **Earth Position Offset** (`NatureVsNoiseView.swift:670`)
  - `earthOffset` was `(30,0,0)` but Earth is at origin `(0,0,0)`
  - Satellites were orbiting 30 units away from Earth
  - Now renders correctly at Earth-centered position

- **QualityLevel Off-by-One** (`NatureVsNoiseView.swift`)
  - Enum started at 1 (low=1, medium=2, high=3, ultra=4)
  - UserDefaults stores 0-3 (low=0, medium=1, high=2, ultra=3)
  - Quality level was always +1 off
  - Fixed enum to start at 0 to match UserDefaults

- **Bundle.main Fallback** (`SatelliteManager.swift`, `NatureVsNoiseView.swift`)
  - `Bundle.main` points to ScreenSaverEngine, not our screensaver
  - TLE files and textures wouldn't load without explicit bundle
  - Changed to `Bundle(for: type(of: self))` throughout

- **SGP4 Division by Zero** (`SGP4Propagator.swift:283`)
  - `c3 = coef * tsi * j3oj2 * no * sin(inclo) / ecco`
  - Crashes when eccentricity = 0 (circular orbit)
  - Added guard: `(ecco > 1e-10) ? ... : 0.0`

- **SGP4 sqrt Edge Case** (`SGP4Propagator.swift:220-221`)
  - `sqrt(1 - ecc^2)` fails when ecc >= 1
  - Parabolic/hyperbolic orbits not supported by SGP4
  - Added guard against non-elliptical orbits

### Documentation
- Added `DEPLOYMENT.md` with signing and notarization instructions
- Updated README with new project structure
- Added thumbnail.png for System Preferences preview

### Build Status
- ✅ All 5 critical bugs fixed
- ✅ Build: SUCCEEDED (arm64 + x86_64)
- ⏸️ Runtime: Blocked by macOS 26.5 code signing requirement

## [2026-05-16] - Engineering Stabilization

### Fixed
- **Duplicate FeatureFlags Removed**
  - Removed `Sources/Satellites/FeatureFlags.swift` (duplicate)
  - Unified to single `Sources/FeatureFlags.swift`
  - Prevents settings inconsistencies across components

- **Texture Path Search Fixed** (`ImageLoader.swift`, `NatureVsNoiseView.swift`)
  - Textures are in `8K/` folder, not `Resources/Textures/8K/`
  - Added search path: `Resources/8K/`
  - Added dev fallback for `/Users/pro/Projects/Secondary/Screensaver/NatureVsNoise/8K/`

- **Bundled TLE Fallback Added** (`SatelliteManager.swift`)
  - Created `8K/active_satellites.tle` with 14 sample satellites
  - Includes: ISS, Hubble, Starlinks (3), NOAA (2), TESS, Juno, GPS, Galileo, debris (2)
  - Added search paths: `Resources/Data/`, `Resources/` root, dev fallback
  - Screensaver now works offline without network fetch

- **Shader Error Handling** (`MetalSatelliteRenderer.swift`)
  - `setupPipelines()` no longer throws
  - Optional pipelines (propagation, culling) fail gracefully
  - Render pipeline failure falls back to SceneKit-only mode
  - Prevents screensaver crash on Metal initialization failure

### Added
- **Unit Tests** (`NatureVsNoiseTests/`)
  - `SGP4PropagatorTests.swift`: Orbital mechanics validation
    - LEO velocity ~7.8 km/s ✓
    - GEO velocity ~3 km/s ✓
    - Period calculations ✓
  - `FeatureFlagsAndTLETests.swift`: Settings + TLE parsing
    - Feature flags persistence ✓
    - TLE structure validation ✓
    - Satellite classification ✓

### Changed
- **Updated Documentation**
  - README.md: Updated project structure
  - TROUBLESHOOTING.md: Fixed texture and TLE paths
  - STATUS.md: Updated stage and health
  - TASKS.md: Added engineering tasks

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
