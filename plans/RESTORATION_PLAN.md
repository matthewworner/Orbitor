# NatureVsNoise Screensaver - Restoration Plan

**Date:** 2026-02-13  
**Project:** Nature's Calm vs. Humanity's Noise - macOS Screensaver  
**Current Status:** Functional with critical full-screen black screen issue

---

## Executive Summary

This is an ambitious macOS/tvOS screensaver project that visualizes the contrast between serene solar system views and the chaotic swarm of 23,000+ satellites orbiting Earth. The codebase has substantial progress but has a critical **full-screen black screen bug** that prevents the full experience from working. This plan outlines the steps to fix what's broken and deliver a functional screensaver.

---

## Current State Assessment

### ✅ WORKING FEATURES

| Feature | Status | Notes |
|---------|--------|-------|
| Solar system rendering | Working | Sun + 8 planets with 8K textures |
| Earth with cloud layer | Working | Day/night textures, rotation |
| Starfield | Working | 5000 procedural stars |
| Toy satellite rendering | Working | 50 simplified cross/T shapes (SceneKit) |
| Cinematic fly-through camera | Working | 40-second loop |
| Feature flags system | Working | UserDefaults-based stability controls |
| Logging system | Working | ~/Library/Logs/NatureVsNoise.log |
| Thumbnail preview | Working | Shows planets correctly |

### 🔴 BROKEN / INCOMPLETE FEATURES

| Feature | Status | Priority | Root Cause |
|---------|--------|----------|------------|
| **Full-screen black screen** | Critical | P0 | Unknown - differs from thumbnail path |
| **Metal satellite rendering** | Broken | P1 | Causes black screen when enabled |
| **Audio playback** | Incomplete | P2 | Placeholder silent .wav files |
| **Settings UI** | Not implemented | P2 | No preference panel |
| **Satellite visibility** | Sub-optimal | P2 | Sats too small/dim during fly-through |
| **Swarm rendering** | Behind flag | P2 | Firefly mode not stable |

---

## Root Cause Analysis: Full-Screen Black Screen

### Symptoms
- Thumbnail preview: ✅ Works perfectly
- Full-screen preview: ❌ Black screen
- Safe preset (features disabled): ⚠️ Works sometimes

### What's Ruled Out
- ✅ Resource loading (textures load correctly)
- ✅ Camera position (same code works in thumbnail)
- ✅ SceneKit setup (scene has nodes, camera has pointOfView)
- ✅ Feature flags (problem exists even with all disabled)

### What Triggers the Issue
- `addSatellites()` - Enabling causes black screen
- `setupRenderers()` - Enabling causes black screen
- `addStarfield()` - May contribute but less severe

### Hypotheses (from DEBUG_SESSION_2026_01_03.md)

1. **SceneKit Metal backend issue** - Screensaver sandbox may restrict GPU access differently than preview
2. **View hierarchy issue** - SCNView may not be properly attached in full-screen mode
3. **Frame timing issue** - Scene may be set up before view is fully ready
4. **Resource loading race** - Textures may not be ready when first frame renders

---

## Phase 1: Fix Full-Screen Black Screen (P0)

### 1.1 Add Enhanced Diagnostic Logging
**File:** `NatureVsNoiseView.swift`

```swift
// Add to logToFile():
// - View hierarchy state: superview, window, layer
// - Screen dimensions and scale
// - Frame timing between init and first render
// - Metal device availability in full-screen context
```

### 1.2 Implement Deferred Scene Setup
**File:** `NatureVsNoiseView.swift`

```swift
// Move ALL scene setup to dispatch after view appears:
// 1. In setFrameSize(), dispatch to main queue with delay
// 2. Verify view is in window hierarchy before setup
// 3. Add viewDidMoveToSuperview() equivalent monitoring
```

### 1.3 Add Frame Render Callback
**File:** `NatureVsNoiseView.swift`

```swift
// Use SCNSceneRendererDelegate to log:
// - First frame render timestamp
// - Draw call status
// - Any Metal errors
```

### 1.4 Implement Safe Mode Auto-Detection
**File:** `NatureVsNoiseView.swift`

```swift
// Detect full-screen context and auto-apply safe preset:
// - Check if isPreview == false AND bounds > preview threshold
// - Force disable Metal, reduce satellites, simplify scene
// - Log which safe guards were applied
```

### 1.5 Test and Verify
- Build project
- Test thumbnail preview
- Test full-screen preview
- Check ~/Library/Logs/NatureVsNoise.log for diagnostics

---

## Phase 2: Stabilize Metal & Satellite Rendering (P1)

### 2.1 Fix Metal Satellite Renderer
**File:** `MetalSatelliteRenderer.swift`

Issues identified:
- Shaders may not be loading correctly in screensaver context
- Pipeline state creation may fail silently

```swift
// Fixes needed:
// 1. Add explicit shader compilation error logging
// 2. Implement graceful fallback to SceneKit on Metal failure
// 3. Add device capability verification before Metal init
// 4. Verify buffer allocation sizes
```

### 2.2 Improve Satellite Visibility
**Files:** `SatelliteRenderer.swift`, `NatureVsNoiseView.swift`

Current issues:
- Satellites too small (0.05 scale)
- Colors wash out against black space
- Not visible during fly-through

```swift
// Improvements:
// 1. Increase satellite scale 2-3x for visibility
// 2. Add emissive materials for self-illumination  
// 3. Add brightness boost when camera is close
// 4. Implement distance-based LOD (larger when near, smaller when far)
```

### 2.3 Optimize Satellite Count Scaling
**File:** `QualityLevel` enum

Current maxSatellites values are unrealistic:
- low: 5000 (too high for SceneKit)
- medium: 15000 (too high)
- high: 30000 (impossible)
- ultra: 50000 (impossible)

```swift
// Revised values:
// low: 200 (SceneKit safe)
// medium: 500 (SceneKit acceptable)  
// high: 1000 (Metal capable only)
// ultra: 5000 (Metal high-end only)
```

---

## Phase 3: Implement Audio System (P2)

### 3.1 Audio Architecture
**File:** `AudioController.swift`

Current state: Code exists, placeholder files are silent

```swift
// Implementation:
// 1. Use AVAudioEngine for low-latency mixing
// 2. Create audio layers:
//    - Layer 1: Deep space ambient (solar wind)
//    - Layer 2: Planetary tones (Jupiter, Saturn, Earth)
//    - Layer 3: Human noise (radio static, telemetry)
// 3. Implement crossfade between Nature and Noise modes
// 4. Add volume controls and enable/disable toggle
```

### 3.2 Replace Placeholder Audio Files
**Location:** `Resources/Audio/`

Current: Silent .wav placeholders (88244 chars each)

Need to source:
- Solar wind ambient loop
- Jupiter/Saturn/Earth radio emissions
- Radio static + telemetry layers

Sources (from PRD):
- NASA Voyager: https://voyager.jpl.nasa.gov/audio/
- NASA Space Sounds: https://www.nasa.gov/connect/sounds/

### 3.3 Audio-Visual Sync
```swift
// Crossfade audio based on camera mode:
// - Nature mode: Ambient + planetary sounds at 70%
// - Noise mode: Human noise layers fade in, planetary fade to 30%
// - Transition: 20-second smooth crossfade
```

---

## Phase 4: Settings UI (P2)

### 4.1 Implement Configure Sheet
**File:** `SettingsController.swift`

```swift
// macOS Screensaver Preferences Panel:
// - Mode selection: Balanced / Pure Nature / Human Footprint
// - Satellite count slider (Safe/Medium/Full)
// - Toggle: Metal rendering on/off
// - Toggle: Audio on/off  
// - Toggle: Show labels
// - Planet labels: None / Minimal / Educational
```

### 4.2 Wire to Feature Flags
```swift
// Connect UI to UserDefaults:
// FeatureFlags.swift already has the keys
// SettingsController writes to same UserDefaults
// NatureVsNoiseView reads at startup
```

---

## Phase 5: Visual Polish (P2)

### 5.1 Improve Camera Fly-Through
**File:** `CameraController.swift`

Current issues:
- Fly-through too fast through satellite shell
- Satellites barely visible during Earth pass

```swift
// Improvements:
// 1. Slow down approach phase (20s instead of 15s)
// 2. Extend time in satellite shell (20s instead of 10s)
// 3. Add subtle camera shake when passing through debris
// 4. Add distance-based satellite brightness boost
```

### 5.2 Enhance Planet Rendering
**File:** `PlanetFactory.swift`

```swift
// Improvements:
// 1. Add normal maps for Earth and Mars (currently missing textures)
// 2. Implement Saturn ring shadows
// 3. Add Jupiter Great Red Spot (simple texture offset)
// 4. Implement moon rendering (Phobos, Deimos, Titan, etc.)
```

### 5.3 Improve Starfield
```swift
// Current: 5000 procedural spheres
// Improvements:
// 1. Add parallax effect (stars move slightly with camera)
// 2. Add occasional shooting stars
// 3. Consider using particle system for better performance
```

---

## Phase 6: Build & Verification (P3)

### 6.1 Build Verification Checklist

- [ ] Clean build with no errors or warnings
- [ ] Thumbnail preview shows planets + satellites
- [ ] Full-screen preview works without black screen
- [ ] Safe preset runs at 60fps for 10 minutes
- [ ] Logs show clean initialization
- [ ] Settings panel opens and saves preferences
- [ ] Audio plays (when real files added)
- [ ] No crashes or freezes

### 6.2 Performance Targets

| Scenario | Target FPS | Max Satellites |
|----------|------------|----------------|
| Thumbnail | 60 | 200 |
| Safe Preset (Full-screen) | 60 | 500 |
| Medium Preset | 30 | 1000 |
| Full Features | 30 | 5000 (Metal only) |

---

## Implementation Priority Matrix

| Priority | Task | Estimated Complexity | Files to Modify |
|----------|------|---------------------|-----------------|
| P0-1 | Fix full-screen black screen | High | NatureVsNoiseView.swift |
| P0-2 | Add enhanced diagnostics | Medium | NatureVsNoiseView.swift |
| P1-1 | Stabilize Metal rendering | High | MetalSatelliteRenderer.swift |
| P1-2 | Improve satellite visibility | Medium | SatelliteRenderer.swift |
| P1-3 | Fix quality level values | Low | NatureVsNoiseView.swift |
| P2-1 | Implement audio system | High | AudioController.swift |
| P2-2 | Source real audio files | Medium | Resources/Audio/ |
| P2-3 | Build settings UI | Medium | SettingsController.swift |
| P2-4 | Wire settings to flags | Low | FeatureFlags.swift |
| P3-1 | Polish camera fly-through | Medium | CameraController.swift |
| P3-2 | Enhance planet rendering | Medium | PlanetFactory.swift |
| P3-3 | Final verification | Low | All |

---

## Risk Mitigation

1. **If full-screen issue persists:**
   - Ship with safe preset as default
   - Document as known issue for certain hardware
   - Provide workaround (restart display)

2. **If Metal remains unstable:**
   - Disable Metal by default
   - Use SceneKit fallback with capped satellites

3. **If audio files unavailable:**
   - Ship with silent mode
   - Add clear instructions for users to add their own

---

## Success Criteria

1. ✅ Full-screen preview works without black screen
2. ✅ 60fps performance with safe preset
3. ✅ Feature flags control all major rendering options
4. ✅ Settings panel accessible and functional
5. ✅ Audio system implemented (even without real files)
6. ✅ Clean build with no errors

---

## Immediate Next Steps

1. **Switch to Code mode** to implement Phase 1 fixes
2. **First fix:** Add enhanced diagnostics to NatureVsNoiseView.swift
3. **Build and test** to gather diagnostic data
4. **Iterate** based on log analysis

---

*Plan created by Architect mode - ready for implementation in Code mode*
