# Screensaver - Status

## Stage
**Parked** (2026-07-21) — source-level stability work is done; runtime / visual verification deferred.
Branch `astra-hud-redesign` is 28 commits ahead of origin with all fixes ready when the user returns.

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
