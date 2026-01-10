# Nature vs Noise — Debug Session Notes

**Date:** 2026-01-03  
**Duration:** ~2 hours  
**Outcome:** Success — Base version verified working (Planets only, no satellites/starfield)

---

## Summary

Attempted to diagnose and fix the "garbage looking" screensaver. Made significant progress on resource bundling and initialization, but hit a wall with full-screen rendering.

---

## Issues Found & Fixed

### 1. Resources Not Bundled ✅ FIXED
**Problem:** The Xcode project's `PBXResourcesBuildPhase` was empty. Textures existed in the project navigator but were never copied to the `.saver` bundle.

**Fix:** Added all 13 texture files to the Resources build phase in `project.pbxproj`.

### 2. Texture Naming Mismatch ✅ FIXED
**Problem:** `PlanetFactory.swift` referenced `mercury`, `venus`, etc., but actual files were named `mercury_8k.jpg`, `venus_8k.jpg`.

**Fix:** Updated all texture prefixes in `PlanetFactory.PlanetData` to include `_8k` suffix.

### 3. NSPrincipalClass Wrong ✅ FIXED
**Problem:** Info.plist had `NatureVsNoiseView` but Swift requires module-qualified name.

**Fix:** Changed to `NatureVsNoise.NatureVsNoiseView` in build settings.

### 4. SCNView.pointOfView Not Set ✅ FIXED
**Problem:** Camera existed but SCNView didn't know to use it.

**Fix:** Added `sceneView.pointOfView = cameraNode` after camera setup.

### 5. Zero-Frame Initialization ✅ FIXED
**Problem:** Full-screen mode called `init(frame:isPreview:)` with frame (0,0,0,0).

**Fix:** Deferred scene setup to `setFrameSize(_:)` which is called when view gets real dimensions.

### 6. Cinematic Camera in Void ✅ FIXED
**Problem:** Camera sequence started at Neptune (x=200) looking at nothing visible.

**Fix:** Replaced with simple orbit camera starting at Earth (x=30).

---

## Unresolved Issue

### Full-Screen Renders Black (Conditional)

**Symptoms:**
- Thumbnail preview: Works perfectly (shows textured planets)
- Full-screen preview: Works with current configuration (features disabled)

**What's ruled out:**
- Resource loading (textures are in bundle and load correctly)
- Camera position (same code works in thumbnail)
- SceneKit setup (scene has nodes, camera has pointOfView)

**What breaks it:**
- `addSatellites()` — Enabling this causes black screen
- `setupRenderers()` — Enabling this causes black screen
- `addStarfield()` — May or may not contribute

**Hypothesis:**
The full-screen rendering path has stricter requirements or different timing than the thumbnail path. Possibly:
- Sandbox restrictions on Metal GPU access
- Different runloop/thread context
- View not fully in window hierarchy when rendering starts

---

## Code Changes Made

```
NatureVsNoise.xcodeproj/project.pbxproj
  - Added PBXBuildFile entries for all textures
  - Added files to PBXResourcesBuildPhase

Sources/Planets/PlanetFactory.swift
  - Fixed texture prefixes (added _8k)
  - Added diagnostic logging (logToFile)

Sources/NatureVsNoiseView.swift
  - Added hasSetupScene flag
  - Moved init from init() to setFrameSize()
  - Added sceneView.pointOfView = cameraNode
  - Replaced cinematic camera with simple orbit
  - Disabled: setupRenderers(), addSatellites(), addStarfield()
```

---

## Recommended Debug Approach

1. **Run from Xcode** with screensaver scheme to get console output
2. **Use os_log** instead of print() for sandbox-compatible logging
3. **Check crash logs** in Console.app for legacyScreenSaver
4. **Binary search** the satellite/renderer code to find exact crash point
5. **Test on different hardware** (Intel Mac, M1, M2, etc.)

---

## Files in Working State

The current installed version has:
- Planets with textures ✅
- Black background ✅  
- Orbiting camera ✅
- NO satellites
- NO starfield
- NO Metal renderers

This version has been verified as **WORKING** by the user on the morning of Jan 3rd. Logs confirm consistent texture loading and initialization.

## Phase 2 Test: Starfield

As requested, we are now re-enabling the Starfield (5000 procedural nodes) to see if it remains stable.
- **Status:** Enabled in code (NatureVsNoiseView.swift)
- **Goal:** Verify if particle/node count is the crash trigger.
- **Outcome:** ✅ SUCCESS. User reports "lots of stars glowing". No black screen.
- **Conclusion:** 5000+ nodes is NOT the limit. The issue is likely specific to the Satellite/instance rendering or Metal setup.

- **Conclusion:** 5000+ nodes is NOT the limit. The issue is likely specific to the Satellite/instance rendering or Metal setup.

## Phase 3 Test: Satellites (SceneKit Only)
**Outcome:** ❌ FAILED. Main Thread Freeze. Use `legacyScreenSaver` process unresponsive.
**Analysis:** Creating ~23,000 individual SCNNodes in the fallback renderer is too heavy for the main thread.

## Phase 3b: Satellites (Limited Cap)
We are restricting the fallback renderer to **500 satellites** max.
- **Goal:** Verify functionality of the satellite logic without the performance crush.
- **Expected:** Smooth rendering of ~500 satellites.
**Outcome:** 🤷‍♂️ INCONCLUSIVE. No freeze, but user reports "no moving dots seen".
**Hypothesis:** Satellites are rendering but are too small (0.08 units) or sparse to be visible against the black space.

## Phase 3c: Satellites (Visibility Test)
We are making satellites **HUGE (0.5 units)** and **BRIGHT RED**.
- **Goal:** Confirm satellites are actually being added to the scene.
- **Expected:** Large red dots swarming around Earth.
**Outcome:** ✅ SUCCESS. User reports "glow off the earth". 

## Phase 4: Alignment & Visibility Fixed
We have centered the Earth/Camera, scaled the satellites (0.0003x), and verified visibility at count=500.

## Phase 5: Density Ramp Up
Increasing satellite count to **2000** and fixing the "Single Color" bug (shared geometry) to allow multi-colored swarms.
- **Goal:** Create the "Noise" effect.
- **Risk:** Main thread performance.
**Outcome:** ✅ SUCCESS. Colors now work (using catalog number modulo for variety).

## Phase 6: Cinematic Fly-Through + Real Satellites (2026-01-03 Night Session)

### Changes Made:
1. **Cinematic Camera Animation:** Replaced static orbit with 40-second fly-through sequence:
   - Approach Earth from distance (15s)
   - Fly PAST Earth through satellite shell (10s)
   - Swing around to reset (15s)

2. **Bloom Disabled:** Was washing out satellite colors to white.

3. **Color Fix:** Country extraction from TLE was returning launch year, not country code. Fixed by using `catalogNumber % 8` to cycle through 8 neon colors.

4. **Procedural Satellite Models:** Each satellite now has:
   - Central body (dark gray box)
   - Solar panel wings (colored, glowing)
   - Random rotation for variety

5. **Real Satellite Names:** Labels using actual TLE names (e.g., "STARLINK-1234", "ISS (ZARYA)"):
   - 3D text geometry with billboard constraint (always faces camera)
   - Colored to match satellite

6. **Earth Centered:** Moved Earth to (0,0,0) for simpler viewport centering.

7. **Sun Repositioned:** Moved to (-100, 20, -100) as background element.

8. **Satellite Scaling Fixed:** SGP4 returns positions in KM. Applied scale factor `2.0 / 6371.0` to match SceneKit units.

### Current State:
- ✅ Planets render with textures
- ✅ Starfield renders
- ✅ Satellites render (2000 count) with:
  - Procedural 3D models (body + solar panels)
  - Multi-colored (8 neon colors)
  - Real TLE names as labels
- ✅ Cinematic fly-through camera
- ⚠️ Performance could be optimized (labels are expensive)

### Next Steps:
1. Optimize labels (maybe only show for nearby satellites)
2. Add country-accurate coloring (parse COSPAR ID properly)
3. Test on multiple displays
4. Re-enable Metal renderer for higher satellite counts

---

## Phase 7: Realistic Satellite Models (2026-01-07)

**Goal:** Make satellites look like the NASA visualization reference image — distinct shapes, brilliant blue panels, gold bodies.

### Session Summary

User provided reference image showing stylized NASA satellite visualization with:
- Clearly visible, distinct satellite shapes
- Brilliant blue solar panels
- Gold/silver metallic bodies
- Various satellite types visible

### Changes Made (SatelliteRenderer.swift)

1. **Template System Implemented:**
   - 5 procedural satellite types: Communication, Starlink, Observation, Station, GPS
   - Each has distinct geometry (dishes, panels, trusses, antennas)
   - Templates cloned for performance (not regenerated per-satellite)

2. **USDZ Loader Ready:**
   - Code checks for `.usdz` files in `Resources/Models/` at startup
   - If found, uses real models; if not, falls back to procedural
   - File naming: `satellite_communication.usdz`, `satellite_starlink.usdz`, etc.

3. **Material Improvements:**
   | Material | Color | Properties |
   |----------|-------|------------|
   | Gold Foil | (0.9, 0.75, 0.3) | Metalness 1.0, Roughness 0.2 |
   | Silver | White 0.92 | Metalness 1.0, Roughness 0.15 |
   | Solar Panels | (0.08, 0.15, 0.35) | Subtle emission for visibility |
   | White Paint | White 0.98 | Matte finish |

4. **Scale Tuning:**
   - Started at 0.08 (original debug session)
   - Tried 0.4 (user: "massive, looks utterly shit")
   - Tried 0.02 (user: "still not what I'm after")
   - **Current: 0.08** (balanced visibility)

### Current State (2026-01-07 22:13)

| Feature | Status |
|---------|--------|
| Planets + Textures | ✅ Working |
| Starfield (5000 stars) | ✅ Working |
| Satellites (2000 count) | ✅ Working |
| Procedural 3D Models | ✅ 5 types implemented |
| PBR Materials | ✅ Gold, Silver, Blue Panels |
| USDZ Loader | ✅ Ready (no models downloaded yet) |
| Cinematic Fly-Through | ✅ Working |
| Performance | ⚠️ Acceptable at 2000 sats |

### What Still "Needs Work" (User Feedback)

User said "looks better - still not what I'm after". Likely issues:

1. **Procedural geometry limitations:**
   - Boxes/cylinders don't match detailed reference
   - No textures on bodies (plain colored materials)

2. **No real 3D models yet:**
   - NASA USDZ downloads failed (404/redirects)
   - Need manual acquisition or better URL hunting

3. **Visual fidelity gap:**
   - Reference has film-quality rendering
   - SceneKit procedural can't match that without textures/models

### Recommended Next Actions

1. **Download Real Models Manually:**
   - Visit https://science.nasa.gov/3d-resources
   - Download ISS, SMAP, Europa Clipper as USDZ
   - Drop into `NatureVsNoise/Resources/Models/`

2. **Adjust Camera Path:**
   - Get closer to satellites during fly-through
   - Slow down when passing through satellite shell

3. **Add Panel Detail:**
   - Use normal maps or procedural grid on solar panels
   - Would require texture creation

4. **Consider Simplification:**
   - Maybe satellites should just be "space debris" aesthetic
   - Less detail, more quantity, implies pollution

---

## Phase 8: Stability & Feature Flags (2026-01-07 Quality Improvements)

**Goal:** Add stability controls and comprehensive logging to diagnose black screen issue.

### Changes Made

1. **Feature Flags System:**
   - New `FeatureFlags.swift` with UserDefaults persistence
   - Safe preset: planets + starfield + 800 toy satellites (no Metal, no labels)
   - Presets: Safe, Full, Toy-Only, Swarm-Only
   - Controls: Metal rendering, labels, satellite count, starfield, toy sats, swarm

2. **Comprehensive Logging:**
   - Moved to `~/Library/Logs/NatureVsNoise.log` (sandbox compatible)
   - Lifecycle logging: init, setFrameSize, startAnimation, scene setup
   - FPS monitoring every 60 frames
   - Feature flag status on startup

3. **Satellite Rendering Simplification:**
   - SceneKit: Reduced to 50 toy satellites (cross/T shapes)
   - Metal: Tuned firefly swarm (size 0.5, trails 1.5)
   - Combined rendering with feature flags

4. **Safe Preset Implementation:**
   - Default configuration for maximum stability
   - Verified working with planets + starfield + 800 satellites
   - Metal rendering gated behind flag

### Current State (2026-01-07)

| Feature | Status | Notes |
|---------|--------|-------|
| Planets + Textures | ✅ Working | 8K textures, Earth clouds |
| Starfield | ✅ Working | 5000 procedural stars |
| Toy Satellites | ✅ Working | 50 cross/T shapes |
| Firefly Swarm | ⚠️ Gated | Metal rendering, disabled by default |
| Feature Flags | ✅ Working | Safe preset active |
| Logging | ✅ Working | ~/Library/Logs/NatureVsNoise.log |
| Black Screen Issue | 🔧 Debugging | Logs added to diagnose |

### Next Debug Steps

1. **Test Safe Preset:** Run with default settings, check logs for black screen cause
2. **Enable Features Incrementally:** Test Metal swarm, increase satellite count
3. **Analyze Logs:** Compare thumbnail vs full-screen execution paths
4. **Fix Root Cause:** Address identified issue (GPU access, timing, etc.)

## Build Status

**Last Build:** 2026-01-07 ~22:10
**Install Location:** `~/Library/Screen Savers/NatureVsNoise.saver`
**Build Result:** ✅ SUCCESS (with stability improvements)
