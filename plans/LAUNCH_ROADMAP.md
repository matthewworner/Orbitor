# Nature vs Noise — Launch Roadmap

## Current Status: 🔧 DEBUGGING — Logging Added for Black Screen Issue

**Last Updated:** 2026-01-07

---

## Executive Summary

The screensaver has a **critical full-screen rendering bug** where thumbnail preview works but full-screen shows black screen. Feature flags and comprehensive logging have been added to diagnose and control the issue. Safe preset (planets + starfield + 800 toy satellites) implemented as default to isolate problems.

---

## What Works ✅

| Component | Status | Notes |
|-----------|--------|-------|
| 8K Planet Textures | ✅ Working | All 13 textures load correctly from bundle |
| Texture Loading | ✅ Working | `ImageLoader` finds resources in bundle |
| SceneKit Scene | ✅ Working | Planets created with correct geometry and materials |
| Camera System | ✅ Working | Camera node + pivot structure correct |
| Thumbnail Preview | ✅ Working | Small preview in System Settings shows planets |
| Build System | ✅ Working | Xcode project compiles and bundles resources |
| Feature Flags | ✅ Working | User defaults control rendering options and presets |
| Logging System | ✅ Working | Lifecycle and FPS logging to ~/Library/Logs/NatureVsNoise.log |
| Safe Preset | ✅ Working | Default: planets + starfield + 800 toy satellites, Metal off |

---

## What's Broken ❌

| Component | Status | Notes |
|-----------|--------|-------|
| **Full-Screen Preview** | 🔧 DEBUGGING | Black screen despite identical code path; logging added to diagnose |
| Satellite Rendering | ✅ FIXED | Toy sats (50) + optional Metal swarm implemented with flags |
| Metal Renderers | ⚠️ GATED | Behind flag; safe preset disables; tuned for firefly swarm |
| Starfield | ✅ CONDITIONAL | Enabled in safe preset; can be disabled via flag |
| Cinematic Camera | ✅ WORKING | Fly-through sequence active and stable |

---

## Root Cause Analysis (Incomplete)

### Confirmed Issues Fixed:
1. **Resources not in bundle** — Fixed by adding files to `PBXResourcesBuildPhase`
2. **Texture naming mismatch** — Fixed `_8k` suffix in `PlanetFactory.swift`
3. **NSPrincipalClass wrong** — Changed to `NatureVsNoise.NatureVsNoiseView`
4. **pointOfView not set** — Added `sceneView.pointOfView = cameraNode`
5. **Zero-frame init** — Using `setFrameSize` for deferred scene setup
6. **Satellite rendering** — Simplified to toy sats + optional Metal swarm with feature flags
7. **Feature control** — Added user defaults for safe presets and conditional rendering

### Unresolved Issue (Now Diagnosable):
The **full-screen rendering path differs from thumbnail** in a way that causes rendering to fail. Comprehensive logging added to ~/Library/Logs/NatureVsNoise.log for lifecycle (init, setFrameSize, startAnimation, scene setup) and performance (FPS every 60 frames). Possible causes:

1. **SceneKit Metal backend issue** — The screensaver sandbox may restrict GPU access (now logged)
2. **View hierarchy issue** — SCNView may not be properly attached in full-screen mode (lifecycle logged)
3. **Frame timing issue** — Scene may be set up before view is fully ready (deferred setup logged)
4. **Resource loading race** — Textures may not be ready when first frame renders (scene setup logged)
5. **Metal renderer crash** — Gated behind flag; safe preset disables

---

## Files Modified This Session

| File | Changes |
|------|---------|
| `NatureVsNoise.xcodeproj/project.pbxproj` | Added 13 texture files to Copy Bundle Resources |
| `Sources/Planets/PlanetFactory.swift` | Fixed texture prefixes, added logging |
| `Sources/NatureVsNoiseView.swift` | Major refactor: feature flags integration, logging to ~/Library/Logs, conditional rendering, FPS monitoring |
| `Sources/FeatureFlags.swift` | New file: user defaults for rendering options and presets |
| `Sources/SatelliteRenderer.swift` | Simplified to 50 toy satellites with cross/T shape |
| `Sources/MetalSatelliteRenderer.swift` | Tuned parameters for firefly swarm (size 0.5, trails 1.5) |

---

## Recommended Next Steps

### Immediate (Debug)
1. **Test safe preset full-screen** — Run with default settings on Apple Silicon; check ~/Library/Logs/NatureVsNoise.log for issues
2. **Analyze logs** — Review lifecycle logs to identify where full-screen diverges from thumbnail
3. **Test feature flags** — Enable/disable Metal, starfield, satellites to isolate black screen cause

### Short-term (Fix)
1. **Fix identified issue** — Based on logs, address the root cause (GPU access, view hierarchy, timing)
2. **Enable Metal swarm** — Once stable, test toy sats + firefly swarm combination
3. **Tune camera fly-through** — Ensure satellites are visible during Earth pass

### Long-term (Polish)
1. **Add USDZ models** — Drop real satellite models for visual fidelity
2. **Implement audio MVP** — Ambient loop + planetary clips
3. **Settings UI** — Allow users to toggle features

---

## Project Health

| Metric | Value |
|--------|-------|
| Code Quality | Good — Well-structured Swift, proper separation, feature flags added |
| Documentation | Improving — Roadmap updated with reality; PRD needs revision |
| Test Coverage | None |
| CI/CD | None |
| Stability | Debugging — Safe preset implemented, logging added for black screen issue |

---

## Conclusion

Significant progress made with feature flags, safe presets, and logging infrastructure. The black screen issue is now diagnosable with logs. Safe preset should work for basic launch; full features can be enabled incrementally. **Test safe preset thoroughly before any launch attempt.**

---

## Engineering Checklist (work top to bottom)

### 1) Stability (must-pass)
- [x] Add feature flags/presets: safe default = planets + starfield + capped satellites, Metal off.
- [x] Gate heavy features behind flags: `useMetalSatellites`, `showLabels`, `maxSatelliteCount`, `enableStarfield`.
- [x] Delay scene population until after first `setFrameSize` tick; log lifecycle (init, setFrameSize, startAnimation, first draw).
- [x] Add lightweight FPS/frame-time logging to `~/Library/Logs/NatureVsNoise.log` on start.
- [ ] Verify safe preset full-screen on target hardware (Apple Silicon) with zero black-screen incidents.

### 2) Visuals (impact)
- [x] Simplified satellites: toy sats (50 cross/T shapes) + optional Metal firefly swarm.
- [ ] Tighten Earth fly-through: closer pass, slower near-Earth segment, ensure satellites are clearly visible in that window.
- [ ] Drop 2–3 real USDZ satellite models into `Resources/Models/` and ensure loader uses them.
- [x] Disable labels by default; if enabled, show only nearest ~50 and fade by distance.
- [x] Keep bloom off or minimal; keep panels emissive so colors read during the pass.

### 3) Audio (MVP)
- [ ] Ship a minimal audio bed: one ambient loop + 2–3 planetary clips; default off, toggle in settings.
- [ ] Crossfade on mode change (Nature → Noise and back) with a single mixer ramp.

### 4) Pre-ship verification
- [ ] Run saver full-screen for 10 minutes on primary hardware; confirm no stalls, no black frames.
- [ ] Test install/uninstall cycle from built `.saver` to catch bundle/Info.plist regressions.
