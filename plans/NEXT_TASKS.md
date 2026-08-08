# Next Tasks: Polish & Release Preparation

> ⚠️ **Historical snapshot (2026-02-21). Superseded by [`../TASKS.md`](../TASKS.md)** — use that for
> current open work. Kept for history.

**Date:** 2026-02-21
**Status:** Feature Complete - Ready for Testing

---

## Overview

Hybrid rendering implemented. Metal full-screen issue resolved. Satellite classification, motion trails, and material effects complete. Next phase is user testing and polish.

---

## Completed ✅

- [x] Fix Metal full-screen rendering (SceneKit delegate integration)
- [x] Implement satellite classification system
- [x] Add motion trails for orbital paths
- [x] Integrate NASA 3D models (Hubble, TESS, TDRS, Juno)
- [x] Add material aging and thermal glow effects
- [x] Migrate from Timer to frame-synchronized updates
- [x] Update documentation

---

## High Priority

### 1. User Testing
**Goal:** Verify stability across different hardware

**Test Matrix:**
- [ ] M1/M2 Mac - Full quality, all features
- [ ] M1 (base) - High quality
- [ ] Intel Mac - Medium quality
- [ ] Multiple display configurations
- [ ] Various screen resolutions

**Success Criteria:**
- 60fps sustained
- No black screens
- No crashes in 10-minute test

### 2. Performance Profiling
**Goal:** Identify and fix any remaining bottlenecks

**Steps:**
- [ ] Run Instruments to profile GPU usage
- [ ] Check memory usage with large satellite counts
- [ ] Verify Metal shader performance

---

## Medium Priority

### 3. Camera Enhancement
**Goal:** Expand to PRD's 12-15 minute cinematic tour

Current: 40-second loop
Target: Full solar system grand tour with Earth debris reveal

### 4. Additional 3D Models
**Goal:** Add more detailed satellite models

- [ ] Detailed ISS model (current is procedural)
- [ ] CubeSat variations
- [ ] Debris variations

### 5. Audio
**Goal:** Implement ambient audio

- [ ] Ambient space sounds
- [ ] Planet-specific audio cues
- [ ] Settings toggle

---

## Low Priority

### 6. tvOS Support
**Goal:** Verify and test tvOS build

- [ ] Build tvOS target
- [ ] Test on Apple TV
- [ ] Verify performance

### 7. Settings UI
**Goal:** Expose feature flags to users

- [ ] Satellite count slider
- [ ] Quality presets
- [ ] Trail toggle
- [ ] Audio toggle

---

## Known Limitations

| Limitation | Impact | Future Work |
|------------|--------|-------------|
| 40-second camera loop | Doesn't match PRD | Expand cinematic sequence |
| No audio | Silent experience | Implement audio system |
| Limited 3D models | ISS uses procedural | Add detailed ISS model |
| No user settings | Defaults only | Build settings UI |

---

## Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Build Status | ✅ Success | ✅ Success |
| Test Coverage | None | Basic tests |
| FPS (M1) | 60 | 60 |
| FPS (Intel) | 45-60 | 60 |
| Black Screen | Fixed | N/A |
| Features | Complete | Polish |

---

## Next Milestone

**User Testing Complete** - Verify stability across hardware configurations.
