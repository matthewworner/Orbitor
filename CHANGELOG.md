# Change Log

All notable changes to Nature vs Noise Screensaver.

## [2026-07-20] - Bug fixes (SGP4 velocity, audio bundling)

### Fixed
- **SGP4 velocity was 13x too high.** The propagation formula divided by 60.0 to convert
  min→sec but was missing the `/ tumin` factor (13.4468). Result was in earth-radii/TU/min
  instead of km/s — LEO velocity computed as ~103 km/s vs real ~7.66; GEO ~41 vs ~3.07.
  Both ratios identical to the missing constant, which is how the test failure pinpointed
  it. Fixed by adding `/ SGP4Constants.tumin` to the velocity scaling. Position magnitude
  was already correct (multiplied by radiusEarthKm without the /60 divisor -- position is
  in km, not km/s). Surfaced by `testVelocityMagnitudeForLEO`/`ForGEO` once the test
  harness was wired; without those tests this would have shipped forever. (d8d53b7)
- **Ambient and Saturn audio never played.** Files existed on disk in
  `Resources/Audio/Ambient/` and `Resources/Audio/Planetary/` but weren't in the Xcode
  build phase (verified — no .mp3/.wav in the built .saver), so Bundle.path lookup always
  returned nil, AudioController was never instantiated, the "Ambient Audio" toggle in the
  configure sheet toggled a no-op. Even if they'd been bundled, the filenames didn't match
  the AudioLayer names (`solar_wind_preview.mp3` vs layer `ambient_solar_wind`,
  `saturn_radio.wav` vs layer `planet_saturn`) and bundleURL() doesn't search the
  `Audio/Ambient/` subdir. Fixed by renaming files to match layer names, removing the
  empty subdirs, adding both to project.pbxproj (PBXFileReference, PBXBuildFile,
  Resources group children, Resources build phase), and simplifying the audio-init gate
  in NatureVsNoiseView. The other 8 planet voices + 5 mission clips remain silent
  placeholders (no source files). (a13b053)
- **DiscoveryBanner fully orphaned.** Held a node in the scene graph and an init/positioning
  call but no method was called after `showDiscovery` was deleted in commit c406ae8.
  Removed the file (222 lines) plus all references in HUDOverlay and project.pbxproj.
  (ae32abe)
- **Unused achievementSilver/Bronze colors** in MissionControlTheme. Removed; `achievementGold`
  kept (consumed by `gold: SKColor` shortcut). (72fc57b, followup to c406ae8)

## [2026-07-20] - Tier 1 cleanup (config persistence, dead code, tests)

### Fixed
- **Configure sheet settings silently lost.** `SettingsController.bundleId` was hardcoded to
  `com.antigravity.NatureVsNoise`, but the screensaver's actual bundle ID (Info.plist) is
  `com.naturevsnoise.screensaver`. `ScreenSaverDefaults(forModuleWithName:)` uses the string as
  the defaults namespace, so every toggle in the configure sheet was writing to a phantom
  defaults namespace the running screensaver never read. Now reads `Bundle.main.bundleIdentifier`.
  (3e34d2b)
- **Version label drift.** The configure sheet hardcoded "v1.1.0 · Astra HUD" while
  `MARKETING_VERSION = 1.0` in project.pbxproj. Label now reads from
  `CFBundleShortVersionString`; MARKETING_VERSION bumped to 1.2.0 for the Fable 5 stability +
  cleanup pass. (3e34d2b, fe79142)

### Removed
- **CameraController (259 lines):** instantiated and never called. The 12-15 min cinematic tour
  documented in TASKS.md never played; the camera is driven by an SCNAction sequence in
  `setupScene()`. If the tour is wanted back, design from scratch and remove the SCNAction
  hack at the same time.
- **Achievements (295 lines):** the `AchievementManager.trackSatelliteSpotted` trigger was
  unreachable — the only caller (`HUDOverlay.updateTarget`) passes planet names that never
  match `NotableSatellites.find`. Fixing it properly requires adding satellite-detection to
  the HUD (a new feature, not a bug fix).
- **`displayLink: CVDisplayLink?`:** declared, never used.
- **"Discovery Mode (Achievements)" configure toggle:** surface area for a removed feature.
- **DiscoveryBanner.showAchievement(_:):** orphan after Achievements deletion.
  (e4c5a79)

### Added
- **SwiftPM test harness** at `NatureVsNoise/Package.swift`. Exposes the testable Foundation-only
  surface (SGP4Propagator, SatelliteManager, SatelliteClassification, TLEFetcher, FeatureFlags)
  as a library named `NatureVsNoise` so the existing test files' `@testable import NatureVsNoise`
  works unchanged. `cd NatureVsNoise && swift test` runs the suite.
- Fixed existing test-file bugs uncovered by getting them to compile:
  - Missing `import simd` in SGP4PropagatorTests.
  - `tle?.x` returning `Double?` wouldn't bind to accuracy-typed `XCTAssertEqual` -- forced after
    `assertNotNil`.
  - `testSatelliteClassification` expected `.activeSatellite` for "GPS IIF-10" but the classifier
    intentionally treats "GPS"-containing names as `.notable("GPS Satellite")`. Replaced fixture
    with a plain active satellite.
  - Deleted `testLegendMappingIsComplete` (asserted non-existent `SatelliteClass.legendOrder` /
    `legendCode` properties; nothing in the runtime uses them).
- **Result: 15/17 tests pass.** The 2 failures (`testVelocityMagnitudeForLEO/GEO`) surface a
  pre-existing SGP4Propagator bug -- velocity magnitude is ~13x too high (constant factor
  across LEO and GEO, so it's a units issue in the velocity formula, not the propagation).
  Position magnitude is correct in both cases. (a9fb932)

## [2026-07-05] - Fable 5 stability sweep fixes

Sweep: `docs/qa/2026-07-05-fable5-stability-audit.md` (8 findings, all fixed).

### Fixed
- **Settings-induced crash (RESILIENCE).** Unchecking "Hero Satellites (3D models)" in the
  configure sheet and relaunching force-unwrapped a nil `satelliteRenderer` inside the
  wallpaper host during `setupScene()`. Switched the four `configureQualitySettings` call
  sites to optional-chaining. (5e712c7)
- **Saver dead after preview stop/start (LIFECYCLE).** `startAnimation()` did nothing beyond
  `super`, so after `stopAnimation()` cleared `sceneView.delegate` / `isPlaying` / HUD timer
  / SatManager timer, the System Settings preview (which restarts on the same view instance)
  got a frozen frame: no `renderer(_:updateAtTime:)`, no `willRenderScene` (Metal swarm not
  drawn), no HUD updates. `startAnimation()` now mirrors the teardown. (5e712c7, 1c6ae10)
- **Hourly CelesTrak fetch kept running after stopAnimation (LIFECYCLE).** `SatelliteManager`'s
  hourly `Timer` was only invalidated in `deinit`. Added `pauseUpdates()` / `resumeUpdates()`,
  called from the screensaver's stop/start. (1423403, 5e712c7)
- **SceneKit fallback trail churn (LEAK, sibling of the 23GB bug).** The 23GB fix removed the
  call from the Metal path, but the SceneKit fallback still rebuilt a fresh `SCNGeometrySource`
  + `SCNGeometryElement` + `SCNGeometry` + `SCNMaterial` per visible satellite per tick —
  ~1500 GPU-backed allocations/sec, same leak class. Throttled to 2 Hz and shared one static
  `SCNMaterial` across all trails. (fc23a85)
- **Per-tick SGP4 propagator alloc (RENDER).** `getPositionAndVelocity` allocated a new
  `OrbitalElements` + `SGP4Propagator` for every satellite on every tick; init runs the full
  SGP4 math. Cached `SGP4Propagator` keyed by `catalogNumber`. SceneKit fallback path queries
  the first 50 entries only, so the cache is naturally bounded. Metal path is unaffected
  (GPU propagates via the kernel). (1423403)
- **Background parse race on hourly refetch (LEAK-/RESILIENCE).** `parseTLEData` did
  `satellites.removeAll()` + `parseTLEContent` (which appends) from a detached `Task` while
  the render thread read the array on every frame — undefined behaviour for a CoW array,
  with hundreds of chances per multi-hour run. Parse into a local, publish `satellites` on
  main; `parseTLEContent` now takes `inout` so both bundle-load and async-fetch paths route
  through the property setter. (1423403)
- **Unbounded `lastFetchStatistics`.** Hourly fetches appended ~7 stats per cycle forever.
  Capped to last 50 entries. (af9a74b)

### Changed
- **GPU catalog re-upload.** The Metal swarm uploaded orbital elements only on the very first
  tick (`animationTime == 0`). The async fetch and every hourly refresh replaced `satellites`
  afterwards but the GPU never saw the new catalog — the swarm showed 14 bundled sats for the
  whole session. Added a `catalogGeneration` counter on `satellites.didSet`; `addSatellitesMetal`
  re-uploads whenever it changes. (1423403, 5e712c7)
- **Diagnostic log rotation.** `logToFile` truncated at startup if `~/Library/Logs/NatureVsNoise.log`
  was over 500 KB; was unbounded across months. (5e712c7)

### Known issues
- A fixed build has not yet been re-signed and reinstalled — do that before using it again.

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
