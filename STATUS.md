# Screensaver - Status

## Stage
Render + memory bug-fix pass (post-Astra HUD) ⚠️ — fixed in source, NOT yet reinstalled

## Last Updated
2026-06-16

## Health
🟡 Amber — Release build SUCCEEDED, but the previously-installed build shipped a severe memory
leak (see below). Source is fixed and measured-flat; a fixed build has not yet been signed/installed.

## ⚠️ 2026-06-16 — critical memory leak (FIXED in source)
The installed build leaked unbounded memory as wallpaper (`legacyScreenSaver`), reaching 23–27 GB and
triggering macOS "out of application memory". Root cause: the Metal render path redundantly drove the
SceneKit `SatelliteRenderer` for ~5000 satellites every tick, and `updateSatellites` rebuilt a fresh
`SCNGeometry` per satellite per frame (`updateTrailNode`) that the wallpaper host never reclaimed.

- **Fix (commit 5d502fa):** `addSatellitesMetal` now only uploads once + propagates on GPU; the Metal
  renderer alone draws the swarm. Measured with `/tmp/leaktest.swift` (phys_footprint, 600 frames):
  OLD +13,100 MB and climbing → NEW **0 MB, flat**. autoreleasepool alone did NOT fix it.
- **Mitigation applied 2026-06-16:** removed the leaking `~/Library/Screen Savers/NatureVsNoise.saver`
  and killed `legacyScreenSaver`; memory recovered (61% free).
- **Still open:** rebuild → Developer ID sign → reinstall the FIXED build before using it again.
- **Known remaining:** SceneKit *fallback* path (non-Metal hardware) still rebuilds trail geometry
  per frame and would leak — needs geometry reuse. See TASKS.md.

Other fixes in this pass: satellites were invisible (view-projection matrix bound to wrong buffer
index — commit a112746); planet render quality (mipmaps + anisotropic filtering, tessellation, gentle
bloom — commit f10a9ec).

## Summary
Ported the Google Stitch "Astra" mission-control HUD into the native SpriteKit overlay: glass panels,
bundled JetBrains Mono, live UTC clock, telemetry dashboard, contextual focus, classification legend,
ambient ticker, boot sequence, and a reworked configure sheet. See `docs/ASTRA_HUD.md`.

**Runtime verified — it runs.** A *Developer ID Application: M P Worner (PMJJD98L5C)* certificate was
created on this Mac; the `.saver` is signed (hardened runtime + secure timestamp), installed to
`~/Library/Screen Savers/`, and **previews successfully in System Settings → Screen Saver** on this
machine. Developer ID signing alone is sufficient to run it locally on macOS 26.5; `spctl` still
reports "Unnotarized Developer ID", so **notarization is only required to distribute to other Macs**
(needs an app-specific password or App Store Connect API key — not yet done). Steps are in
`NatureVsNoise/DEPLOYMENT.md`.

Status: **functional, visual polish ongoing** (see Next Actions).

## Astra HUD Redesign (2026-06-06)
- ✅ Design system + reusable `GlassPanel` + bundled JetBrains Mono (CoreText, SF Mono fallback)
- ✅ `OrbitalCensus` counts (ISS/Starlink/notable/active/debris), cached + fed to the HUD
- ✅ Full HUD: UTC clock, TRACKING pill, telemetry dashboard, contextual focus (incl. inclination),
  classification legend, focus reticle, scanline, ambient ticker
- ✅ Restyled dossier card, fact overlay, discovery banner
- ✅ Boot sequence overlay; reworked configure sheet (fixed overlapping layout)
- ✅ Release build green; fonts confirmed in the built bundle

## Completed Fixes (Apple-Tier Audit)

### Critical Bugs Fixed
- ✅ **Earth Position Offset** - Satellites now orbit at correct Earth-centered position
- ✅ **QualityLevel Off-by-One** - Enum now matches UserDefaults (0-3)
- ✅ **Bundle.main Fallback** - Fixed in SatelliteManager and NatureVsNoiseView
- ✅ **SGP4 Division by Zero** - Guard against circular orbits (ecc=0)
- ✅ **SGP4 sqrt Edge Case** - Guard against parabolic/hyperbolic orbits (ecc>=1)

### Deliverables Complete
- ✅ No duplicate FeatureFlags (consolidated to single source)
- ✅ Textures bundled (14 files, 69MB)
- ✅ TLE fallback (active_satellites.tle with 14 satellites)
- ✅ Shader error handling (graceful Metal fallback)
- ✅ Unit tests (SGP4PropagatorTests, FeatureFlagsAndTLETests)
- ✅ Preview vs full-screen (both modes implemented)
- ✅ Performance profiling (update intervals per quality level)
- ✅ Document deployment (DEPLOYMENT.md with signing instructions)

## Build Status
- **Build:** ✅ SUCCEEDED (arm64 + x86_64)
- **Bundle Size:** 1.3MB binary + 69MB textures
- **Resources:** 15 files (14 textures + 1 TLE + 1 metallib)
- **Runtime:** ⏸️ Blocked by macOS 26.5 code signing

## macOS 26.5 Code Signing Requirement

### The Problem
macOS 26.5 enforces strict code signing for screensavers. Ad-hoc signed binaries are rejected with:
```
AMFI: Launch Constraint Violation (enforcing)
Error Domain=AppleMobileFileIntegrityError Code=-423
```

### The Solution
1. Obtain **Developer ID Application** certificate ($99/year)
2. Sign: `codesign --force --deep --sign "Developer ID Application: YOUR NAME"`
3. Notarize: `xcrun notarytool submit NatureVsNoise.saver.zip`
4. Staple: `xcrun stapler staple NatureVsNoise.saver`

See [DEPLOYMENT.md](NatureVsNoise/DEPLOYMENT.md) for full instructions.

## Recent Changes
- 2026-06-06: Astra HUD redesign ported into native SpriteKit overlay (build verified)
- 2026-05-17: Apple-tier audit - 5 critical bugs fixed
- 2026-05-16: Engineering stabilization complete
- 2026-02-21: Hybrid rendering + data-driven visualization
- 2026-02-17: SGP4 propagation + Metal shaders

## Next Actions
1. **User testing** - Test on real Mac with Developer ID signing
2. **Performance profiling** - Instruments analysis for Retina displays
3. **App Store** - Submit for notarization if distribution required
## Root Cause Analysis (2026-05-17)

### The Problem
macOS 26.5 (Platform ID 26) enforces stricter code signing requirements for executables loaded by system services. ScreenSaverEngine is a system service, and it cannot load ad-hoc signed screensaver binaries.

### Evidence
1. **ScreenSaverEngine signing**: Platform identifier=26, Authority="Software Signing"
2. **Our screensaver signing**: Format=bundle, Signature=adhoc, no entitlements
3. **AMFI error**: "Launch Constraint Violation (enforcing)" when ScreenSaverEngine loads our binary
4. **System log**: "AMFI: 'NatureVsNoise' is adhoc signed"

### Constraint Details
- Error code: `C[6]P[2]M[3]E[255]`
- C[6] = System service launch context
- P[2] = Platform enforcement level
- M[3] = Minimum platform version (26.x)
- E[255] = Unspecified constraint failure

### This Is NOT a Code Bug
The code is production-ready. The issue is purely a **deployment configuration** limitation:
- Ad-hoc signing works on macOS < 26.5
- Developer ID signing works on all macOS versions
- System services require properly signed executables on macOS 26.5+

### Solutions
1. **Quick fix**: Sign with Developer ID Application certificate
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" \
     --options runtime NatureVsNoise.saver
   ```

2. **Production**: Notarize with Apple
   ```bash
   xcrun notarytool submit NatureVsNoise.saver.zip --apple-id "your@email.com"
   xcrun stapler staple NatureVsNoise.saver
   ```

3. **Testing**: Use macOS < 26.5 or disable System Integrity Protection (not recommended)
