# Tasks

## 🔴 2026-06-16 — render + memory bug-fix pass
- [x] Fix invisible satellites — view-projection matrix bound to buffer(1) in hybrid path (a112746)
- [x] Planet quality — mipmaps + 16x anisotropy, tessellation 64/96→128, gentle bloom (f10a9ec)
- [x] **Fix 23–27 GB memory leak** — stop per-frame SceneKit geometry churn in Metal mode (5d502fa);
      measured flat (0 MB growth) vs +13 GB before
- [x] Mitigation: removed leaking installed `.saver` + killed `legacyScreenSaver`
- [x] Removed stale installed experiments (Kubrick.saver, MinimalTest.saver) from `~/Library/Screen Savers/`
- [x] **Rebuild → Developer ID sign → reinstall the FIXED build** (2026-07-21): built Release,
      signed with `Developer ID Application: M P Worner (PMJJD98L5C)` + hardened runtime +
      timestamp, copied to `~/Library/Screen Savers/NatureVsNoise.saver`. Verified registered
      with `defaults read com.apple.screensaver` and `codesign -dv`. Bundle 38 MB.
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

## ✅ 2026-07-20 — Tier 1 cleanup (bundle ID bug + dead code + tests)
- [x] **Configure sheet settings not reaching the saver:** SettingsController used a hardcoded
      bundle ID that didn't match Info.plist, so the running screensaver read from a different
      defaults namespace than the configure sheet wrote to. Now reads `Bundle.main.bundleIdentifier`
      so they agree (3e34d2b).
- [x] **Version label drift:** hardcoded "v1.1.0 · Astra HUD" replaced with
      `Bundle.main.infoDictionary["CFBundleShortVersionString"]`; MARKETING_VERSION bumped to
      1.2.0 (3e34d2b + fe79142).
- [x] **Dead code removed:** CameraController (259 lines, never called), Achievements
      (295 lines, trigger path impossible), displayLink (declared never used), Discovery Mode
      configure toggle (backed by removed feature), DiscoveryBanner (222 lines, orphaned
      after the previous deletes) (e4c5a79 + c406ae8 + ae32abe).
- [x] **Test target wired:** SwiftPM Package.swift at NatureVsNoise/. `swift test` runs the
      existing XCTest files (a9fb932).

## ✅ 2026-07-20 — Bug fixes (SGP4 velocity + audio bundling)
- [x] **SGP4 velocity was 13x too high.** The propagation formula divided by 60.0 to convert
      min→sec but was missing the `/ tumin` factor (13.4468). Result was in earth-radii/TU/min
      instead of km/s — LEO velocity computed as ~103 km/s vs real ~7.66. Fixed by adding
      `/ SGP4Constants.tumin` to the velocity scaling. Tests now 17/17 pass (d8d53b7).
- [x] **Ambient and Saturn audio never played.** Files existed on disk but weren't in the
      Xcode build phase; layer names didn't match filenames; lookup didn't search
      `Audio/Ambient/`. Fixed by renaming files to match layer names (ambient_solar_wind.mp3,
      planet_saturn.wav), removing the empty subdirs, adding both to project.pbxproj (file
      ref + build file + Resources group + Resources build phase), and simplifying the
      audio-init gate in NatureVsNoiseView. "Ambient Audio" toggle now plays audio;
      approaching Saturn plays Saturn's radio. The 8 other planet voices + 5 mission clips
      remain silent placeholders (no source files) (a13b053).

## ✅ 2026-07-21 — Test improvements + commit audit prompt (final commits before parking)
- [x] **Regression test naming:** renamed `testVelocityMagnitudeForLEO/GEO` to
      `testVelocityUnitsAreKmPerSecondNotEarthRadiiPerMinute_LEO/GEO` and added a MARK comment
      block documenting the d8d53b7 fix (13x unit bug). Future grep for "km/s" or "units"
      lands on the regression test (4e0ab53).
- [x] **Bundle-ID fallback contract test:** added `testBundleIdFallbackContract` in
      FeatureFlagsAndTLETests.swift. Asserts the fallback string `"com.naturevsnoise.screensaver"`
      is well-formed. SettingsController is AppKit-only so it can't be imported in the SwiftPM
      library directly; this is a fallback-string contract test rather than a direct
      SettingsController test. MARK comment points at SettingsController.swift:13 as the
      source of truth (4e0ab53).
- [x] **Committed audit prompt template:** `docs/qa/FABLE_5_STABILITY_AUDIT_PROMPT.md` (the
      spec template, previously untracked) is now tracked so future re-runs have a known
      starting point (7c678d3).
- [x] **Test count:** 18 / 18 pass via `swift test` from `NatureVsNoise/`.

## 🚗 2026-07-21 — PARKED (user out of time)
- [ ] **30-min wallpaper + Instruments verification** — the single critical-path item when
      you come back. Source-level correctness is verified; runtime is not. Set the screensaver
      as active, let it run 30 min, watch `~/Library/Logs/NatureVsNoise.log` and Activity Monitor.
      Memory should stay flat at ~150-300 MB; CPU should idle 5-15% on Apple Silicon. If anything
      grows, the most likely suspects are: SGP4 velocity calculation (d8d53b7), SceneKit fallback
      trail rebuild throttle (fc23a85), AudioController init path (a13b053).
- [ ] **Audio playback confirmation** — `tail -f ~/Library/Logs/NatureVsNoise.log` after a 5-min
      run should show `🔊 Audio enabled and initialized`. If absent, audio init is silently
      failing despite the bundle fix.
- [ ] **Visual regression check** — does the throttled 2 Hz trail rebuild look noticeably
      choppier? Do configure-sheet toggles actually persist on the running saver? Does SGP4
      thermal glow look noticeably different now that velocity is in km/s instead of
      earth-radii/TU/min?


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
- [ ] **No Xcode test target in project.pbxproj.** SwiftPM (`swift test` from `NatureVsNoise/`)
      is the only path. Attempted three ways to add a proper PBXNativeTarget (app-host pattern,
      standalone without BUNDLE_LOADER, compiling source files into the test target) and reverted
      each — the .saver bundle isn't a framework, so symbols don't resolve cleanly without
      refactoring the screensaver into a framework + thin `.saver` shell (~half a day of work,
      not blocking).
- [ ] **No actual runtime verification.** Source-level correctness is verified; runtime
      correctness under wallpaper has NOT been measured. This is the biggest remaining risk
      (see "PARKED" section above).
- [ ] DECAY metric not derivable from TLEs (column intentionally removed)

## Deployment
- [x] Obtain Developer ID Application certificate (M P Worner, PMJJD98L5C)
- [x] Developer ID sign the .saver (hardened runtime + timestamp)
- [x] Install + run in System Settings preview (works locally on macOS 26.5)
- [x] Build signed and installed (2026-07-21): rebuilt with all fixes, re-signed with Developer
      ID + hardened runtime + timestamp, installed to `~/Library/Screen Savers/NatureVsNoise.saver`.
      Signature verified (`codesign -dv`), system registration verified (`defaults read
      com.apple.screensaver`), bundle resources verified (`ls Contents/Resources/`).
- [ ] **Runtime verification under wallpaper** (single critical-path item — see "PARKED" section)
- [ ] Notarization submission to Apple (only needed to distribute to other Macs)
- [ ] Staple notarization ticket
- [ ] Visual polish pass against docs/stitch-base/stitch-output/ screenshots

## Visual Polish (post-runtime review)
- [ ] TBD — capture issues seen in live preview

## Testing Needed (post-resume)
- [ ] Preview mode in Screen Saver preferences
- [ ] Full-screen mode in System Settings
- [ ] Different screen resolutions
- [ ] Multiple monitor configurations
- [ ] Audio playback verification (log file check for init line)
- [ ] 30-min wallpaper memory profile (Instruments)

## Resuming the project
The branch `astra-hud-redesign` is in a self-consistent state. To resume:

```bash
cd /Users/pro/Projects/Screensaver
git checkout astra-hud-redesign

# verify health
cd NatureVsNoise && swift test
cd .. && xcodebuild -project NatureVsNoise/NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build
```

Then the runtime verification (single critical-path item) is described in the "PARKED"
section above.