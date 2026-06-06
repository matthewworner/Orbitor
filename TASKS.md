# Tasks

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

## Deployment Blocked
- [ ] Obtain Developer ID Application certificate (machine has only Apple Development)
- [ ] Developer ID signing required for macOS 26.5+
- [ ] Notarization submission to Apple
- [ ] Staple notarization ticket
- [ ] Runtime visual verification against docs/stitch-base/stitch-output/ screenshots

## Testing Needed
- [ ] Preview mode in Screen Saver preferences
- [ ] Full-screen mode in System Settings
- [ ] Different screen resolutions
- [ ] Multiple monitor configurations