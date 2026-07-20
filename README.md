# Nature's Calm vs. Humanity's Noise

A macOS screensaver contrasting cosmic serenity with the chaotic swarm of satellites orbiting Earth.
It live-fetches tens of thousands of satellites from CelesTrak (falling back to 14 bundled offline)
and renders an SGP4-propagated swarm — capped at 5,000 points — over an 8K Earth.

> **New here?** Read [`CLAUDE.md`](CLAUDE.md) for the repo map and [`docs/README.md`](docs/README.md)
> for the full documentation index. Current state lives in [`STATUS.md`](STATUS.md); open work in
> [`TASKS.md`](TASKS.md).
>
> **This repo holds three projects.** Only **`NatureVsNoise/`** is the canonical, shipping
> screensaver. `NatureVsNoise-Cinematic/` ("Cosmic Kubrick") is a separate experiment and
> `MinimalTest/` is a debug stub — don't build those unless asked.

## Features

- **Earth-Centered View**: Real-time SGP4 propagation from TLE data
- **8K NASA Textures**: Sun, 8 planets with high-resolution imagery
- **Hybrid Rendering**: SceneKit for planets/hero satellites, Metal for 5000+ swarm points
- **Satellite Classification**: ISS, Starlink, notable satellites, and debris each render differently
- **NASA 3D Models**: Hubble, TESS, TDRS, Juno integrated
- **Visual Effects**: Motion trails, material aging, thermal glow
- **Astra Mission Control HUD**: glass telemetry panels in bundled JetBrains Mono — live UTC clock,
  total/active/debris dashboard, contextual focus (altitude/velocity/inclination), classification
  legend with live counts, ambient ticker, focus reticle + scanline, and a boot sequence
  (see [docs/ASTRA_HUD.md](docs/ASTRA_HUD.md))
- **Educational Facts**: Orbital mechanics, satellite trivia

## Quick Start

```bash
# Build
cd NatureVsNoise
xcodebuild -project NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build

# Install
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver ~/Library/Screen\ Savers/
```

Select **"Nature vs Noise"** in System Settings → Screen Saver → Preview.

## Running the tests

```bash
cd NatureVsNoise
swift test
```

The Foundation-only testable surface (SGP4 propagation, TLE parsing, satellite classification,
FeatureFlags) is exposed as a SwiftPM library. 17 / 17 pass; the test suite catches unit-level
regressions in the orbital math and catalog handling — the same suite that surfaced the 13x SGP4
velocity bug. The SwiftPM package can't compile the AppKit / ScreenSaver surface (the .saver
bundle), so runtime / SceneKit / Metal paths are tested only by hand.

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Apple Silicon** recommended (M1/M2/M3)
- **Intel** supported with Metal

## Deployment (Code Signing Required)

macOS 26.5+ requires Developer ID signed binaries for screensavers.

See [DEPLOYMENT.md](NatureVsNoise/DEPLOYMENT.md) for:
- Developer ID certificate setup
- Signing commands
- Notarization instructions

## Project Structure

```
NatureVsNoise/
├── NatureVsNoise.xcodeproj
├── Package.swift                 # SwiftPM manifest for `swift test`
├── 8K/                           # Textures + TLE data
│   ├── earth_8k_day.jpg          # Planet textures
│   ├── jupiter_8k.jpg
│   ├── ... (14 total textures)
│   └── active_satellites.tle      # Bundled satellite data (14 satellites)
├── NatureVsNoise/
│   ├── Info.plist                # Bundle config (NSPrincipalClass)
│   ├── Resources/
│   │   ├── Audio/                # Ambient + Saturn audio (ambient_solar_wind.mp3, planet_saturn.wav)
│   │   ├── Data/                 # Educational facts, satellite database
│   │   ├── Models/               # 3D satellite models (.scn)
│   │   └── thumbnail.png         # Preview image
│   └── Sources/
│       ├── NatureVsNoiseView.swift    # Main ScreenSaverView
│       ├── FeatureFlags.swift         # User settings
│       ├── Planets/PlanetFactory.swift
│       ├── Satellites/
│       │   ├── SGP4Propagator.swift   # Orbital mechanics (incl. propagation, TLE struct)
│       │   ├── SatelliteManager.swift  # TLE data + satellite metadata
│       │   ├── MetalSatelliteRenderer.swift   # GPU swarm (5,000 points, Apple Silicon)
│       │   ├── SatelliteRenderer.swift         # SceneKit fallback (Intel / old hardware)
│       │   ├── SatelliteClassification.swift  # ISS / Starlink / notable / debris
│       │   └── TLEFetcher.swift                # CelesTrak fetch + cache
│       ├── Audio/AudioController.swift
│       └── UI/
│           ├── HUDOverlay.swift      # Mission Control overlay
│           ├── SettingsController.swift
│           ├── Components/          # StatsPanel, InfoCardView, FactOverlay
│           ├── Data/                # EducationalFacts, SatelliteDatabase
│           └── Themes/              # MissionControlTheme
├── NatureVsNoiseTests/           # XCTest files consumed by SwiftPM (not by Xcode)
│   ├── SGP4PropagatorTests.swift
│   └── FeatureFlagsAndTLETests.swift
└── DEPLOYMENT.md                 # Code signing instructions
```

## Astra HUD Redesign (2026-06-06)

The overlay UI was redesigned in Google Stitch and re-implemented natively in SpriteKit — glass
panels, bundled JetBrains Mono, telemetry dashboard, classification legend, ambient ticker, and a
boot sequence. Full design reference: [docs/ASTRA_HUD.md](docs/ASTRA_HUD.md). Stitch prompts and base
objects: [docs/STITCH_PROMPTS.md](docs/STITCH_PROMPTS.md), `docs/stitch-base/`.

## Bug Fixes (2026-05-17)

1. **Earth Position** - Satellites orbit at correct Earth-centered position
2. **QualityLevel** - Enum now 0-based (matches UserDefaults)
3. **Bundle.main** - Fixed in SatelliteManager and NatureVsNoiseView
4. **SGP4 Edge Cases** - Guards for circular and parabolic orbits

## Documentation

| File | Description |
|------|-------------|
| [docs/README.md](docs/README.md) | **Documentation index** — map of every doc, grouped |
| [ASTRA_HUD.md](docs/ASTRA_HUD.md) | HUD design reference (tokens, components, fonts) |
| [STITCH_PROMPTS.md](docs/STITCH_PROMPTS.md) | Google Stitch prompts + base objects |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common build/runtime/signing problems and fixes |
| [DEPLOYMENT.md](NatureVsNoise/DEPLOYMENT.md) | Code signing & notarization |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [STATUS.md](STATUS.md) | Current project status |
| [TASKS.md](TASKS.md) | Open work |
| [prd.md](prd.md) | Product requirements (original vision) |
| [docs/qa/2026-07-05-fable5-stability-audit.md](docs/qa/2026-07-05-fable5-stability-audit.md) | Fable 5 stability sweep — 8 findings, all fixed in this branch |

## Build Status

| Metric | Status |
|--------|--------|
| Version | 1.2.0 (MARKETING_VERSION in `NatureVsNoise.xcodeproj`) |
| Build | ✅ SUCCEEDED (Release, arm64) |
| Tests | 17 / 17 pass (`swift test` from `NatureVsNoise/`) |
| Code Signing | ⏸️ Requires Developer ID before reinstall |
| Textures | 14 files, 69MB |
| TLE Data | 14 satellites bundled (offline fallback) |
| Audio | Ambient + Saturn bundled (8 other planet voices still silent placeholders) |

## License

- **Code**: MIT
- **Textures**: NASA (Public Domain)  
- **TLE Data**: CelesTrak