# 🚀 PRD Implementation Plan: "Nature's Calm vs. Humanity's Noise"

**Based on:** prd.md (Product Requirements Document)
**Created:** December 26, 2025
**Updated:** January 7, 2026

---

## 📊 Project Status Dashboard

| Phase | Status | Progress | Reality Check |
|-------|--------|----------|---------------|
| Phase 1: Foundation & Camera | ✅ COMPLETE | 80% | Core working, some polish missing |
| Phase 2: Real Data Integration | ⚠️ PARTIAL | 60% | SGP4 done, Metal unstable |
| Phase 3: Polish & Features | ❌ STALLED | 30% | Audio stubbed, UI missing |
| Phase 4: tvOS Port & Launch | ❌ NOT STARTED | 10% | Basic files exist, not tested |

**Overall Progress:** ~45% complete (macOS prototype with stability issues)
**Estimated Time Remaining:** 4-6 weeks (debug black screen, implement safe launch)

---

## 📋 Executive Summary

This implementation plan outlines progress toward the PRD vision. Current status: functional macOS prototype with critical stability issues blocking launch.

**What's Actually Working:**
- ✅ Solar system with 8K textures (planets + Earth clouds)
- ✅ Basic camera fly-through (needs tuning for satellite visibility)
- ✅ SGP4 orbital propagation (core algorithm implemented)
- ✅ TLE data loading (bundled + cached from CelesTrak)
- ⚠️ Metal rendering (partially implemented, currently disabled due to crashes)
- ✅ Hardware detection (basic Apple Silicon check)

**What's Broken/Missing:**
- ❌ Full-screen black screen issue (thumbnail works, full-screen fails)
- ❌ Metal satellite rendering stability
- ❌ Audio system (files exist, integration incomplete)
- ❌ Settings UI (no user controls)
- ❌ tvOS port (basic files, not tested/functional)

**Key Implementation Decisions (Updated):**
- **Platform Priority:** macOS screensaver only (tvOS deferred)
- **Technical Stack:** SceneKit primary, Metal experimental
- **Stability First:** Feature flags + safe presets for controlled rollout
- **Performance Target:** 60fps stable with safe preset (800 satellites)

---

## ✅ Phase 1: Foundation & Camera — MOSTLY COMPLETE

**Duration:** Weeks 1-4
**Status:** ✅ 80% implemented (core working, needs polish)

### Deliverables

| Component | Status | Details |
|-----------|--------|---------|
| Xcode Project Structure | ✅ | `.saver` bundle, Debug/Release configs |
| SceneKit Scene Setup | ✅ | 60fps, 4X MSAA, proper lighting |
| Solar System | ✅ | Sun + 8 planets with 8K textures, Saturn rings |
| Camera Choreography | ⚠️ | Basic fly-through working, needs tuning for satellite visibility |
| Satellite Visualization | ⚠️ | Simplified to 50 toy satellites (was 40K, now stable) |
| Texture Loading | ✅ | 3-tier bundle-aware fallback system |

### Key Files
- `NatureVsNoiseView.swift` — Main screensaver view
- `PlanetFactory.swift` — Planet creation and texturing
- `CameraController.swift` — Cinematic camera sequences
- `SatelliteRenderer.swift` — SceneKit-based satellite display

---

## ⚠️ Phase 2: Real Data Integration — PARTIALLY COMPLETE

**Duration:** Weeks 5-7
**Status:** ⚠️ 60% implemented (SGP4 working, Metal unstable)

### 2.1 SGP4/SDP4 Propagation Engine

| Feature | Implementation |
|---------|---------------|
| Core Algorithm | Full Vallado reference (970+ lines) |
| Constants | WGS-72: `radiusEarthKm`, `xke`, `mu`, `j2`, `j3`, `j4` |
| Perturbations | J2, J3, J4 oblateness + B* atmospheric drag |
| Deep Space (SDP4) | Lunar-solar perturbations, resonance detection |
| Output | Position (km) + Velocity (km/s) in TEME frame |

**Files:**
- `SGP4Propagator.swift` — 970 lines, 35KB

### 2.2 TLE Data Pipeline

| Feature | Implementation |
|---------|---------------|
| Data Sources | 7 CelesTrak endpoints (active, starlink, stations, debris) |
| Caching | 24hr JSON cache with timestamp validation |
| Validation | Checksum verification, catalog number matching |
| Error Handling | `TLEFetcherError` enum with localized descriptions |
| Scheduling | Hourly refresh via `startUpdateScheduler()` |

**Files:**
- `TLEFetcher.swift` — 330 lines, 15KB
- `SatelliteManager.swift` — 380 lines, 14KB

### 2.3 Metal GPU Rendering

| Feature | Implementation |
|---------|---------------|
| Compute Shaders | Parallel SGP4 with J2 perturbations (implemented) |
| Render Shaders | Point sprites with glow, motion trails (implemented) |
| Culling | Basic frustum culling (implemented) |
| Capacity | Up to 50K satellites (crashes with high counts) |
| Fallback | SceneKit path (currently used, Metal gated behind flag) |
| Status | ⚠️ Partially working, disabled by default for stability |

**Files:**
- `SatelliteShaders.metal` — 240 lines, 9KB
- `MetalSatelliteRenderer.swift` — 340 lines, 14KB

### 2.4 Hardware Auto-Detection

| Tier | Hardware | Max Satellites | Update Rate |
|------|----------|----------------|-------------|
| Ultra | M1 Pro/Max/Ultra, M2, M3 | 50,000 | 30 FPS |
| High | M1, A14+ | 30,000 | 20 FPS |
| Medium | A12, A13 | 15,000 | 10 FPS |
| Low | Older | 5,000 | 5 FPS |

**Types:**
- `HardwareCapabilities` — Device detection struct
- `HardwareTier` — Performance tier enum
- `QualityLevel` — Rendering quality settings

---

## ❌ Phase 3: Polish & Features — STALLED

  **Duration:** Weeks 8-10
  **Status:** ❌ 30% implemented (audio stubbed, UI missing)
  **Dependencies:** Phase 2 ⚠️ (blocked by stability issues)
 
 ### 3.1 Visual Polish (Week 8)

 - [x] Basic PBR materials (implemented)
 - [ ] Post-processing pipeline (bloom disabled for stability)
 - [x] Dynamic cloud layers for Earth (working)
 - [ ] Atmospheric effects (basic lighting only)
 - [x] Color grading (camera exposure settings)

 ### 3.2 Audio System (Week 9)

 - [ ] AVAudioEngine architecture (stubbed, not integrated)
 - [x] NASA audio files (present in bundle)
 - [ ] Planetary electromagnetic "voices" (not implemented)
 - [ ] Human noise layers (not implemented)
 - [ ] Crossfading between nature/noise modes (not implemented)

 ### 3.3 User Interface (Week 10)

 - [ ] macOS System Preferences integration (not implemented)
 - [ ] Comprehensive settings panel (missing)
 - [ ] Statistics HUD (`HUDOverlay` stubbed)
 - [ ] Educational overlays and labels (not implemented)
 - [ ] Mode switching (no UI controls)
 
 ---

## ❌ Phase 4: tvOS Port & Launch — NOT STARTED

**Duration:** Weeks 11-21
**Status:** ❌ 10% implemented (basic files exist, not functional)
**Dependencies:** Phase 3 ❌ (blocked)

### 4.1 tvOS Adaptation (Weeks 11-14)

- [x] Port SceneKit/Metal codebase to tvOS with UIKit integration
- [x] Optimize for 4K HDR output with bloom and cinematic effects
- [x] Implement Siri Remote controls (select/menu/play-pause)
- [x] Add living room-optimized defaults (audio ON, minimal overlays)

### 4.2 Advanced Features (Weeks 15-17)

- [ ] Historical timeline animations (Future enhancement)
- [x] Mission voice clips (Apollo 11, ISS, Voyager, Perseverance)
- [x] Spatial audio for headphones (3D positional with HRTF)
- [ ] Launch event notifications (Future enhancement)
- [ ] Collision detection and warnings (Future enhancement)

### 4.3 Testing & Launch (Weeks 18-21)

- [ ] Beta testing infrastructure (TestFlight setup pending)
- [ ] Performance optimization for 4K output
- [ ] Marketing materials and demo videos
- [ ] App Store submission preparation
- [ ] Launch both macOS and tvOS platforms

### Key Files Added
- `NatureVsNoiseViewController.swift` — Main tvOS view controller (UIKit)
- `AppDelegate.swift` — tvOS app delegate
- `ImageLoader.swift` — Cross-platform image utilities
- Enhanced `AudioController.swift` — Spatial audio and mission clips

---

## 🔧 Technical Architecture

### Data Flow
```
CelesTrak API → TLEFetcher → SatelliteManager → SGP4Propagator
                                                      ↓
                              MetalSatelliteRenderer ← (GPU compute)
                                                      ↓
                                               SceneKit Display
```

### Rendering Pipeline
```
NatureVsNoiseView
├── SceneKit (Solar system, starfield)
│   └── PlanetFactory → SCNSphere + 8K textures
└── Metal (Satellites)
    ├── SatelliteShaders.metal (compute + render)
    └── MetalSatelliteRenderer.swift (buffer management)
```

### Audio Architecture (Phase 3 + 4)
```
AVAudioEngine
├── Spatial Environment (Phase 4 - HRTF 3D audio)
│   ├── Ambient Layer (solar wind)
│   ├── Planetary Layer (electromagnetic, positional)
│   ├── Human Noise Layer (communications)
│   ├── Mission Clips Layer (Phase 4 - Apollo, ISS, Voyager)
│   └── Events Layer (solar flares, launches)
```

---

## 📁 File Structure

```
NatureVsNoise/
├── Sources/
│   ├── CrossPlatform/
│   │   └── ImageLoader.swift       — Cross-platform NSImage/UIImage utilities
│   ├── NatureVsNoiseView.swift     (20KB) — Main macOS screensaver view
│   ├── Planets/
│   │   └── PlanetFactory.swift     — Planet creation (cross-platform)
│   ├── Camera/
│   │   └── CameraController.swift  — Camera choreography
│   ├── Audio/
│   │   └── AudioController.swift   — Audio engine with spatial audio (Phase 4)
│   ├── UI/
│   │   ├── HUDOverlay.swift        — SpriteKit HUD overlay
│   │   └── SettingsController.swift — macOS settings
│   └── Satellites/
│       ├── SatelliteManager.swift  (14KB) — Data management
│       ├── SGP4Propagator.swift    (35KB) — Orbital mechanics
│       ├── TLEFetcher.swift        (15KB) — TLE fetching/validation
│       ├── SatelliteRenderer.swift (6KB)  — SceneKit fallback
│       ├── MetalSatelliteRenderer.swift (14KB) — Metal renderer
│       └── SatelliteShaders.metal  (9KB)  — GPU shaders
├── tvOS/
│   ├── Sources/
│   │   ├── AppDelegate.swift       — tvOS app delegate
│   │   └── NatureVsNoiseViewController.swift (25KB) — Main tvOS view controller
│   └── Resources/
│       └── Info.plist              — tvOS app configuration
├── Resources/
│   ├── Textures/8K/                — 8K planet textures
│   └── Audio/                      — Audio files (ambient, planetary, mission clips)
└── Info.plist                      — macOS screensaver configuration
```

---

## 🎯 Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Frame Rate | 60 FPS | ✅ Achieved (with safe preset) | Stable |
| Satellite Count | 40,000+ | ⚠️ 800 stable (50K crashes) | Limited |
| RAM Usage | < 500 MB | ⬜ Not measured | Unknown |
| Load Time | < 100 ms | ⬜ Not measured | Unknown |
| TLE Fetch | < 30 sec | ✅ Achieved | Working |

---

## 📞 Next Steps

**Reality Check: Prototype with Critical Bugs**

### Immediate Actions (Next 1-2 weeks):

1. **Debug black screen issue** — Use new logging to identify root cause
2. **Test safe preset stability** — Verify 800 satellites work full-screen
3. **Fix Metal rendering crashes** — Isolate and resolve GPU issues
4. **Tune camera fly-through** — Ensure satellites visible during Earth pass
5. **Implement basic audio** — Add ambient loop for MVP

### Medium-term (2-4 weeks):

1. **Add settings UI** — Allow users to toggle features safely
2. **Performance optimization** — Profile and optimize safe preset
3. **Add USDZ satellite models** — Improve visual fidelity
4. **Test incremental features** — Enable Metal swarm, labels, etc.

### Long-term (Deferred):

- tvOS port (4K optimization, Siri Remote controls)
- Advanced audio (spatial, mission clips)
- Historical timelines and notifications
- App Store submission and launch

**Focus on stable macOS launch first. tvOS and advanced features can follow.**