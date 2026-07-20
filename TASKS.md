# Tasks

## 🔴 2026-06-16 — render + memory bug-fix pass
- [x] Fix invisible satellites — view-projection matrix bound to buffer(1) in hybrid path (a112746)
- [x] Planet quality — mipmaps + 16x anisotropy, tessellation 64/96→128, gentle bloom (f10a9ec)
- [x] **Fix 23–27 GB memory leak** — stop per-frame SceneKit geometry churn in Metal mode (5d502fa);
      measured flat (0 MB growth) vs +13 GB before
- [x] Mitigation: removed leaking installed `.saver` + killed `legacyScreenSaver`
- [x] Removed stale installed experiments (Kubrick.saver, MinimalTest.saver) from `~/Library/Screen Savers/`
- [ ] **Rebuild → Developer ID sign → reinstall the FIXED build** before using as screensaver/wallpaper again
- [ ] On-device verify: memory stays flat over 30+ min as wallpaper; satellites visible; planets sharper

## ✅ 2026-07-05 — Fable 5 stability sweep fixes (audit: docs/qa/2026-07-05-fable5-stability-audit.md)
- [x] **Settings crash (Finding 4):** `satelliteRenderer?.` in `configureQualitySettings` so disabling
      "Hero Satellites (3D models)" no longer force-unwraps nil on next launch (5e712c7).
- [x] **Dead-after-restart (Finding 1):** `startAnimation()` mirrors what `stopAnimation()` tears down
      — delegate, isPlaying, HUD timer, SatManager timer (5e712c7 + 1c6ae10).
- [x] **Hourly refetch race (Finding 3):** `parseTLEData` parses into a local array and publishes
      `satellites` on main; `parseTLEContent` takes `inout` so both code paths route through the
      property setter; `lastFetchStatistics` capped at 50 (1423403 + af9a74b).
- [x] **Fallback trail churn (Finding 2):** SceneKit fallback path throttled to 2 Hz and shares
      one static `SCNMaterial` across all trails — this was a live sibling of the 23GB bug
      (fc23a85).
- [x] **Per-tick SGP4 alloc (Finding 5):** cached `SGP4Propagator` keyed by `catalogNumber` —
      the SceneKit fallback cap of 50 makes the cache naturally bounded (1423403).
- [x] **Fetch timer not paused (Finding 6):** `SatelliteManager.pauseUpdates()` / `resumeUpdates()`
      called from `stopAnimation()` / `startAnimation()` (1423403 + 5e712c7).
- [x] **GPU catalog never re-uploaded (Finding 7):** `catalogGeneration` counter on `satellites.didSet`;
      `addSatellitesMetal` re-uploads whenever it changes (1423403 + 5e712c7).
- [x] **Log unbounded (Finding 8):** `logToFile` truncates at startup if over 500 KB (5e712c7).


## Completed
- [x] Metal full-screen rendering fix
- [x] Satellite classification system
- [x] Motion trails
- [x] NASA 3D model integration
- [x] Material aging and thermal glow
- [x] Frame-synchronized updates
- [x] Documentation update
- [x] Project cleanup
- [x] Merge duplicate FeatureFlags (engineering)
- [x] Fix texture bundling paths
- [x] Add bundled TLE fallback data
- [x] Make Metal shader errors non-fatal
- [x] Create unit tests for SGP4

## Apple-Tier Audit (2026-05-17) ✅
- [x] Earth position offset fix (satellites orbit correctly)
- [x] QualityLevel enum fix (0-based to match UserDefaults)
- [x] Bundle.main fallback fix (SatelliteManager + NatureVsNoiseView)
- [x] SGP4 division by zero guard (ecc=0)
- [x] SGP4 sqrt edge case guard (ecc>=1)
- [x] Create DEPLOYMENT.md documentation
- [x] Update CHANGELOG.md
- [x] Update STATUS.md

## Build Status
- [x] Build SUCCEEDED (arm64 + x86_64)
- [x] All resources bundled (15 files, 69MB textures)
- [x] Unit tests exist (SGP4PropagatorTests, FeatureFlagsAndTLETests)
- [x] Documentation complete (README, DEPLOYMENT, CHANGELOG, STATUS)

## Astra HUD Redesign (2026-06-06) ✅
- [x] Design system + GlassPanel + bundled JetBrains Mono (MissionControlTheme)
- [x] OrbitalCensus counts wired into the HUD
- [x] Telemetry dashboard, contextual focus, classification legend
- [x] Mission cluster (UTC clock + TRACKING pill), focus reticle, scanline
- [x] Restyled dossier / fact / discovery; ambient ticker; boot sequence
- [x] Reworked configure sheet (fixed overlapping layout); DECAY column removed
- [x] Docs updated (ASTRA_HUD.md, README, CHANGELOG, STATUS, DEPLOYMENT)

## High Priority
- [ ] Performance profiling with Instruments

## Medium Priority
- [ ] Expand cinematic camera (12-15 min tour)
- [ ] Add detailed ISS 3D model
- [ ] Audio integration
- [ ] Add more TLE satellites to bundle

## Known Gaps
- [ ] No runnable unit-test target (test files exist but aren't wired; census/legend
      assertions added to FeatureFlagsAndTLETests.swift, ready to run once a target exists)
- [ ] DECAY metric not derivable from TLEs (column intentionally removed)

## Deployment
- [x] Obtain Developer ID Application certificate (M P Worner, PMJJD98L5C)
- [x] Developer ID sign the .saver (hardened runtime + timestamp)
- [x] Install + run in System Settings preview (works locally on macOS 26.5)
- [x] Runtime verified — screensaver loads and renders
- [ ] Notarization submission to Apple (only needed to distribute to other Macs)
- [ ] Staple notarization ticket
- [ ] Visual polish pass against docs/stitch-base/stitch-output/ screenshots

## Visual Polish (post-runtime review)
- [ ] TBD — capture issues seen in live preview

## Testing Needed
- [ ] Preview mode in Screen Saver preferences
- [ ] Full-screen mode in System Settings
- [ ] Different screen resolutions
- [ ] Multiple monitor configurations