# Screensaver - Status

## Stage
**Active** (2026-08-08) — satellite rendering fixed end-to-end (Metal → SceneKit switch, colors,
count, sun brightness, camera). Branch `astra-hud-redesign`. Verified live via System Settings →
Screen Saver → Nature vs Noise → Preview (this environment has no Screen Recording permission for
automated screenshots, so verification was interactive with the user, not scripted).

## 2026-08-08 — Satellite swarm was never rendering; full render pipeline pass

**Root cause (the actual one):** the Metal satellite swarm hooked into SceneKit via
`SCNSceneRenderer.currentRenderCommandEncoder`, called from `willRenderScene`. That API is
deprecated on every OS version (iOS 8–26, macOS 10.8–26 per Apple's docs) and returns `nil` on
this SDK (macOS 27), so `MetalSatelliteRenderer.render(into:)`'s guard failed silently every
frame — the swarm could never draw, regardless of shader correctness. An earlier fix in this
same session (indexing `satelliteVertex`/`trailVertex` by `instance_id` instead of `vertex_id`,
which *was* a real bug — the swarm collapsed onto satellite #0) was correct but could never be
observed because of this deeper issue.

**Fix:** disabled the Metal swarm path (`effectiveUseMetal = false` in `setupRenderers()`,
NatureVsNoiseView.swift) and made the native SceneKit satellite renderer
(`SatelliteRenderer.swift`) the primary path instead of a 50-object "hero satellites only"
fallback. Re-enable Metal only if Apple ships a supported custom-Metal-into-SceneKit hook.

**Follow-on fixes found while getting the SceneKit path production-quality:**
- `logToFile` wrote to `NSHomeDirectory()/Library/Logs/`, which doesn't exist in the app
  sandbox container — every write silently failed via `try?`. Now creates the dir first.
  (This is *why* runtime logs were empty all through the 2026-07-21 park — worth knowing if
  `~/Library/Logs/NatureVsNoise.log` looks stale again.)
- `applyThermalGlow` overwrote every satellite's emission color with a red-dominant tint
  whenever emission intensity > 0.3 (true for almost all of them) — deleted, it was fighting
  the classification coloring with no one asking for it.
- Satellite color now comes from `SatelliteClass.hudColor` (MissionControlTheme.swift) — the
  same source of truth the HUD's classification legend already used, so swarm colors finally
  match the on-screen key (gold=ISS, cyan=Starlink, green=notable, white=active, red=debris).
- `heroModels` (ISS/Hubble/TESS/TDRS GLB/procedural models) was populated but never read —
  every satellite rendered as the generic gold template regardless of class. Wired in via
  exact TLE-name lookup in `updateSatellites`, marker-guarded so pooled nodes only swap
  geometry when their hero identity actually changes.
- `satellites.prefix(50)` landed entirely inside one contiguous Starlink block in the TLE
  source data (CelesTrak lists Starlink as one large run) — every visible satellite was
  Starlink. Swapped for a stride sample across the whole catalog.
- `SatelliteRenderer.maxSatellites` was hardcoded to 50 (a leftover from "Metal owns the
  swarm, SceneKit only does hero satellites") — now 500, matching `QualityLevel`'s own
  documented "SceneKit acceptable" tier. Template scales for active/debris/starlink halved
  twice over the session (0.15/0.1/0.08 → 0.035/0.025/0.02) per user feedback on size.
- Sun was blowing out the whole scene: `bloomIntensity` turned off entirely (was 0.3, tuned
  down twice before that was recognized as the wrong lever), `sunLight.intensity` 5000→600,
  sun material `emission.intensity` 2.0→0.3, fake-bloom glow/corona shell opacities cut
  repeatedly, `exposureOffset` -0.3→-0.6.
- `cameraPivot` existed specifically for orbital rotation (per its own code comment) but
  nothing ever rotated it — the cinematic fly-through only translated the camera near Earth
  and never swept round to reveal the Sun/planets. Added a continuous 90s pivot rotation plus
  widened the fly-through's farthest point (z:15→25) per user request for "more movement and
  sweeping."

Rebuilt, Developer ID-signed (`Developer ID Application: M P Worner (PMJJD98L5C)`), reinstalled
to `~/Library/Screen Savers/NatureVsNoise.saver` after every change above. 18/18 tests pass
throughout (none of this touched code the test suite covers — it's all rendering/lighting).

**Known follow-ups, not yet requested:**
- No guarantee the stride sample includes at least one of every `SatelliteClass` — fine in
  practice at 500/catalog-size, but not proven.
- `.medium`/`.high`/`.ultra` `QualityLevel.maxSatellites` (500/1000/5000) assume Metal; only
  `SatelliteRenderer`'s internal 500 cap protects against a hardware tier requesting more.
- Metal swarm code (`MetalSatelliteRenderer.swift`, `Shaders.metal`) is now fully dead code —
  not deleted, in case Apple ships a working custom-Metal hook later.

## Previous stage
**Parked** (2026-07-21) — source-level stability work is done; runtime / visual verification deferred.

## Last Updated
2026-07-21

## Health
🟢 Source / 🟡 Runtime (untested) — Release build SUCCEEDED, Developer ID-signed + installed to
`~/Library/Screen Savers/NatureVsNoise.saver`. Tests 18 / 18 pass via SwiftPM. Runtime behavior
under wallpaper has NOT been measured — the 30-min Instruments verification, audio playback
confirmation, and any visual regressions are still pending a manual session.

## What was done in this push

- **8 audit fixes from the Fable 5 stability sweep** (`docs/qa/2026-07-05-fable5-stability-audit.md`)
  — lifecycle mirror, SceneKit fallback trail churn throttled to 2 Hz, hourly TLE refresh race
  resolved, settings crash fixed, fetch timer paused on stop, GPU catalog re-upload on change,
  log rotation, SGP4 propagator cached per satellite.
- **Tier 1 cleanup:** SettingsController reads the real bundle ID so configure sheet settings
  reach the saver; MARKETING_VERSION bumped to 1.2.0; dead code removed (CameraController,
  Achievements, displayLink, DiscoveryBanner, orphaned achievement colors).
- **SGP4 velocity units fixed** — was 13x too high (missing `/ tumin` factor); tests now assert
  km/s. Thermal glow on satellites reflects actual orbital speed.
- **Audio bundling fixed** — ambient + Saturn audio files were not in the build phase at all,
  filenames didn't match layer names. Now bundled; "Ambient Audio" toggle actually plays.
- **Tests wired via SwiftPM** (`NatureVsNoise/Package.swift`) — 18 / 18 pass. SGP4 velocity
  regression test now has a name + comment that grep the bug class.
- **Rebuild + Developer ID sign + reinstall** to `~/Library/Screen Savers/`. Bundle signed
  `Developer ID Application: M P Worner (PMJJD98L5C)` + hardened runtime + timestamp.

## What is still open (deferred until you come back)

1. **30-min wallpaper + Instruments verification.** This is the single biggest gap. Source-level
   correctness is verified; runtime correctness is not. The 23 GB leak that started this whole
   audit was a runtime discovery — exactly the class of bug tests + build don't catch.
2. **Audio playback confirmation.** `~/Library/Logs/NatureVsNoise.log` should show
   `🔊 Audio enabled and initialized` after a 5-min run. If it doesn't, the audio init path
   is broken despite the bundle fix.
3. **Visual regressions.** Did the throttled trail rebuild (2 Hz) look noticeably choppier?
   Did the configure-sheet settings actually persist on the running saver? Did SGP4 thermal
   glow look noticeably different after the velocity fix?
4. **Notarize** (only needed if distributing to other Macs).

## What was tried and not adopted

- **Xcode test target** (PBXNativeTarget in project.pbxproj) was attempted three different
  ways and reverted. The .saver bundle isn't a framework, so `BUNDLE_LOADER` + `TEST_HOST`
  doesn't reliably resolve symbols at link time, and compiling source files into the test
  target hit path-resolution problems because the PBXGroup structure doesn't model the
  nested source dirs. **SwiftPM remains the working test path.** A real Xcode test target
  would require refactoring the screensaver into a framework + thin `.saver` shell —
  ~half a day's work, deferred.
- **Runtime verification via screensaver launch from chat.** Blocked by macOS: the
  screensaver only activates on idle display, and headless `open -ga ScreenSaverEngine`
  exits before instantiating the view. `NSClassFromString` from a separate test harness
  also can't load the screensaver bundle's classes — known screensavers behavior.

## Resuming the project (when you're back)

The branch is in a self-consistent state. To resume:

```bash
cd /Users/pro/Projects/Screensaver
git checkout astra-hud-redesign
git pull  # in case anything moved upstream

# verify source-level health
cd NatureVsNoise
swift test                                  # 18/18 should pass
xcodebuild -project NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build

# runtime verification (the actual unknown)
# 1. open System Settings -> Screen Saver -> Nature vs Noise
# 2. enable Ambient Audio in the configure sheet
# 3. set as active screensaver; let it run 30 min
# 4. open Activity Monitor; screensaver process RSS should stay flat
# 5. tail -f ~/Library/Logs/NatureVsNoise.log
#    expect: === SCREENSAVER INIT START ===, 🔊 Audio enabled and initialized
# 6. optional: launch Instruments -> Attach to Process -> ScreenSaverEngine
#    watch Allocations + Leaks for 30 min
```

If the runtime verification fails (memory growth, audio silence, or visual issues), the fixes
to revisit first are: the SGP4 velocity calculation (commit d8d53b7), the SceneKit fallback
trail rebuild throttle (commit fc23a85), and the AudioController init path (commit a13b053).

## Summary

macOS screensaver contrasting cosmic serenity with the chaotic swarm of satellites orbiting Earth.
Earth-centered SceneKit scene + Metal-rendered swarm driven by real CelesTrak TLE data + SGP4
propagation, with a SpriteKit "Astra" mission-control HUD.

- **Repo:** github.com/matthewworner/Orbitor
- **Branch:** astra-hud-redesign (28 commits ahead of origin at park time)
- **Min OS:** macOS 13.0 · **Stack:** Swift 5.9, ScreenSaver.framework, SceneKit, Metal, SpriteKit, AppKit
- **Version:** 1.2.0 (commit 013fba4 was the last "1.0" baseline; fe79142 bumped for this pass)

## Recent fixes (post-1.0 baseline)

- **2026-07-20/21 — Fable 5 stability sweep + Tier 1 cleanup + bug fixes + tests + rebuild.**
  See CHANGELOG.md for the per-commit detail. Net: ~3,000 lines deleted (dead code), 8 stability
  audit findings fixed, SGP4 velocity units corrected, audio bundling fixed, tests runnable,
  configure-sheet settings now persist, version bumped to 1.2.0, fixed build signed + installed.
- **2026-06-16 — Render + memory bug-fix pass.** 23 GB memory leak fixed (commit 5d502fa:
  stop per-frame SceneKit geometry churn in Metal mode). Planet quality bumped (mipmaps +
  anisotropic, tessellation, gentle bloom). SceneKit fallback was still leaking at this point —
  addressed in the 2026-07-20 pass (throttled to 2 Hz in commit fc23a85).
- **2026-06-06 — Astra HUD Redesign.** Ported the Google Stitch mission-control HUD into native
  SpriteKit. See `docs/ASTRA_HUD.md`. Configurable sheet has since been reworked to fix
  overlapping layout.
- **2026-05-17 — Apple-Tier Audit.** 5 critical bugs fixed (Earth position offset, QualityLevel
  off-by-one, Bundle.main fallback, SGP4 edge cases for circular/parabolic orbits).

## Astra HUD Redesign (2026-06-06)
- ✅ Design system + reusable `GlassPanel` + bundled JetBrains Mono (CoreText, SF Mono fallback)
- ✅ `OrbitalCensus` counts (ISS/Starlink/notable/active/debris), cached + fed to the HUD
- ✅ Full HUD: UTC clock, TRACKING pill, telemetry dashboard, contextual focus (incl. inclination),
  classification legend, focus reticle, scanline, ambient ticker, boot sequence
- ✅ Restyled dossier card + fact overlay
- ✅ Reworked configure sheet (fixed overlapping layout); DECAY column removed (TLE-derived, not
  derivable)
- ✅ Release build green; fonts confirmed in the built bundle
- 🗑️ Removed 2026-07-20: DiscoveryBanner (orphaned after Achievements deletion); the HUD now uses
  FactOverlay for "DID YOU KNOW?" facts and InfoCardView for satellite dossiers.

## Build status (as of park)
- **Build:** ✅ SUCCEEDED (Release, arm64)
- **Bundle Size:** ~1.3 MB binary + ~69 MB textures + 1.4 MB audio (ambient + Saturn)
- **Tests:** 18 / 18 pass via `swift test` from `NatureVsNoise/`
- **Installed:** `~/Library/Screen Savers/NatureVsNoise.saver` (signed, registered with system)
- **Runtime:** ⏸️ Blocked on a manual wallpaper run; no code-side blockers

## macOS 26.5 Code Signing

Required to install locally. Developer ID signing alone is sufficient; notarization is only
needed for distribution to other Macs. Steps in `NatureVsNoise/DEPLOYMENT.md`.

## Open tasks / next steps
See `TASKS.md` for the full punch list. The single critical-path item when you come back is
the **30-min wallpaper + Instruments verification** — until that's done, nothing about runtime
is actually proven. Everything else (notarization, the Xcode test target refactor, Tier 4
polish) is non-blocking.
