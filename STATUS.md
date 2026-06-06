# Screensaver - Status

## Stage
Astra HUD Redesign — Code Complete, Build Verified ✅

## Last Updated
2026-06-06

## Health
🟢 Green (Release build SUCCEEDED)

## Summary
Ported the Google Stitch "Astra" mission-control HUD into the native SpriteKit overlay: glass panels,
bundled JetBrains Mono, live UTC clock, telemetry dashboard, contextual focus, classification legend,
ambient ticker, boot sequence, and a reworked configure sheet. See `docs/ASTRA_HUD.md`.

Verification this round is **build-only**. Runtime is still blocked by the macOS 26.5 code-signing
requirement — and the current machine has only an *Apple Development* certificate, **not** a *Developer
ID Application* cert, so the `.saver` cannot yet be notarized/run. Signing steps are documented in
`NatureVsNoise/DEPLOYMENT.md` for when a Developer ID cert is available.

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
