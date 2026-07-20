# Screensaver - Status

## Stage
Stability sweep + bug fixes complete in source (2026-07-05 sweep + 2026-07-20 cleanup) —
**fixed build not yet reinstalled**. Tests wired via SwiftPM, 17/17 pass.

## Last Updated
2026-07-20

## Health
🟢 Source / 🟡 Runtime — Release build SUCCEEDED with the fixes. Re-signed with Developer ID +
hardened runtime + timestamp, reinstalled to `~/Library/Screen Savers/NatureVsNoise.saver` (2026-07-21).
Signature and system registration verified. **30-min runtime / Instruments verification still pending
a manual wallpaper run** — can't be done from a chat session.

## What's solid now

- **8 audit fixes from the Fable 5 stability sweep** (`docs/qa/2026-07-05-fable5-stability-audit.md`)
  — lifecycle mirror, SceneKit fallback trail churn throttled to 2 Hz, hourly TLE refresh race
  resolved, settings crash fixed, fetch timer paused on stop, GPU catalog re-upload on change,
  log rotation, SGP4 propagator cached per satellite.
- **Tier 1 cleanup** (this branch): SettingsController reads the real bundle ID so configure
  sheet settings reach the saver; MARKETING_VERSION bumped to 1.2.0; dead code removed
  (CameraController, Achievements, displayLink, DiscoveryBanner).
- **SGP4 velocity units fixed** — was 13x too high (missing `/ tumin` factor); now LEO ~7.66
  km/s, GEO ~3.07 km/s as expected. Thermal glow on satellites now reflects actual orbital speed.
- **Audio bundling fixed** — ambient and Saturn audio files were not in the build phase at all;
  filenames didn't match layer names. Now bundled, rename to match, configure-sheet toggle
  actually plays.
- **Tests wired via SwiftPM** — `cd NatureVsNoise && swift test` runs 17 tests, all pass. The
  pre-fix SGP4 velocity failures (which would have shipped forever) are now CI-blockable.

## What's still open (real work, not polish)

1. **Rebuild + Developer ID sign + reinstall** the fixed build. Until this is done, the screensaver
   running on your Mac is the pre-fix binary with the 23 GB leak.
2. **30-min Instruments run** as wallpaper with the trail-throttle + race marshal in place —
   verifies the F2/F3 fixes under real memory pressure (correct-by-construction now, but not
   measured).
3. **Notarize** (only needed if you want to distribute to other Macs).

## Summary

macOS screensaver contrasting cosmic serenity with the chaotic swarm of satellites orbiting Earth.
Earth-centered SceneKit scene + Metal-rendered swarm driven by real CelesTrak TLE data + SGP4
propagation, with a SpriteKit "Astra" mission-control HUD.

- **Repo:** github.com/matthewworner/Orbitor
- **Min OS:** macOS 13.0 · **Stack:** Swift 5.9, ScreenSaver.framework, SceneKit, Metal, SpriteKit, AppKit
- **Version:** 1.2.0 (commit 013fba4 was the last "1.0" baseline; fe79142 bumped for this pass)

## Recent fixes (post-1.0 baseline)

- **2026-07-20 — Fable 5 stability sweep + Tier 1 cleanup + bug fixes.** See CHANGELOG.md for the
  per-commit detail. Net: ~3,000 lines deleted (dead code), 8 stability audit findings fixed,
  SGP4 velocity units corrected, audio bundling fixed, tests runnable, configure-sheet settings
  now persist, version bumped to 1.2.0.
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

## Build status
- **Build:** ✅ SUCCEEDED (Release, arm64)
- **Bundle Size:** ~1.3 MB binary + ~69 MB textures + 1.4 MB audio (ambient + Saturn)
- **Tests:** 17 / 17 pass via `swift test` from `NatureVsNoise/`
- **Runtime:** ⏸️ Blocked on reinstall of the current build (no code-side blockers)

## macOS 26.5 Code Signing

Required to install locally. Developer ID signing alone is sufficient; notarization is only
needed for distribution to other Macs. Steps in `NatureVsNoise/DEPLOYMENT.md`.

## Open tasks / next steps
See `TASKS.md` for the full punch list. Top three: rebuild + reinstall, Instruments 30-min
verification, notarization (only if distributing).
