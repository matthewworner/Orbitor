# Nature's Calm vs. Humanity's Noise

A macOS screensaver contrasting cosmic serenity with the chaotic swarm of 23,000+ satellites orbiting Earth.

## Features

- **Earth-Centered View**: Real-time SGP4 propagation from TLE data
- **8K NASA Textures**: Sun, 8 planets with high-resolution imagery
- **Hybrid Rendering**: SceneKit for planets/hero satellites, Metal for 5000+ swarm points
- **Satellite Classification**: ISS, Starlink, notable satellites, and debris each render differently
- **NASA 3D Models**: Hubble, TESS, TDRS, Juno integrated
- **Visual Effects**: Motion trails, material aging, thermal glow
- **Mission Control HUD**: Real-time satellite counts, altitudes, velocities
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
├── 8K/                           # Textures + TLE data
│   ├── earth_8k_day.jpg          # Planet textures
│   ├── jupiter_8k.jpg
│   ├── ... (14 total textures)
│   └── active_satellites.tle      # Bundled satellite data (14 satellites)
├── NatureVsNoise/
│   ├── Info.plist                # Bundle config (NSPrincipalClass)
│   ├── Resources/
│   │   ├── Audio/                # Ambient sounds
│   │   ├── Models/                # 3D satellite models (.scn)
│   │   ├── Textures/8K/          # Additional textures
│   │   └── thumbnail.png          # Preview image
│   └── Sources/
│       ├── NatureVsNoiseView.swift    # Main ScreenSaverView
│       ├── FeatureFlags.swift         # User settings
│       ├── Planets/PlanetFactory.swift
│       ├── Satellites/
│       │   ├── SGP4Propagator.swift   # Orbital mechanics
│       │   ├── SatelliteManager.swift  # TLE data management
│       │   ├── MetalSatelliteRenderer.swift
│       │   ├── SatelliteRenderer.swift
│       │   ├── SatelliteClassification.swift
│       │   └── TLEFetcher.swift
│       ├── Camera/CameraController.swift
│       ├── Audio/AudioController.swift
│       └── UI/
│           ├── HUDOverlay.swift      # Mission Control overlay
│           ├── SettingsController.swift
│           └── Components/            # StatsPanel, InfoCard, etc.
├── NatureVsNoiseTests/
│   ├── SGP4PropagatorTests.swift
│   └── FeatureFlagsAndTLETests.swift
└── DEPLOYMENT.md                 # Code signing instructions
```

## Bug Fixes (2026-05-17)

1. **Earth Position** - Satellites orbit at correct Earth-centered position
2. **QualityLevel** - Enum now 0-based (matches UserDefaults)
3. **Bundle.main** - Fixed in SatelliteManager and NatureVsNoiseView
4. **SGP4 Edge Cases** - Guards for circular and parabolic orbits

## Documentation

| File | Description |
|------|-------------|
| [DEPLOYMENT.md](NatureVsNoise/DEPLOYMENT.md) | Code signing & notarization |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [STATUS.md](STATUS.md) | Current project status |
| [prd.md](prd.md) | Product requirements |

## Build Status

| Metric | Status |
|--------|--------|
| Build | ✅ SUCCEEDED |
| Code Signing | ⏸️ Requires Developer ID |
| Textures | 14 files, 69MB |
| TLE Data | 14 satellites bundled |

## License

- **Code**: MIT
- **Textures**: NASA (Public Domain)  
- **TLE Data**: CelesTrak