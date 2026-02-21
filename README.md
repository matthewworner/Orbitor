# Nature's Calm vs. Humanity's Noise

A macOS screensaver contrasting cosmic serenity with the chaotic swarm of 23,000+ satellites orbiting Earth.

## Features

- **Solar System**: Sun + 8 planets with 8K NASA textures
- **Hybrid Rendering**: SceneKit for planets/hero satellites, Metal for 5000+ swarm points
- **Satellite Classification**: ISS, Starlink, notable satellites, and debris each render differently
- **NASA 3D Models**: Hubble, TESS, TDRS, Juno integrated from NASA assets
- **Visual Effects**: Motion trails, material aging, thermal glow
- **Real Orbital Data**: SGP4 propagation from CelesTrak TLE files

## Quick Start

```bash
# Build
cd NatureVsNoise
xcodebuild -scheme NatureVsNoise -configuration Release build

# Install
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver ~/Library/Screen\ Savers/
```

Select **NatureVsNoise** in System Settings → Screen Saver.

## Requirements

- macOS 13.0+
- Apple Silicon recommended (Intel supported)

## Documentation

| File | Description |
|------|-------------|
| [CHANGELOG.md](CHANGELOG.md) | Version history and changes |
| [prd.md](prd.md) | Full product requirements |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and fixes |
| [plans/LAUNCH_ROADMAP.md](plans/LAUNCH_ROADMAP.md) | Development status |

## Project Structure

```
NatureVsNoise/
├── NatureVsNoise.xcodeproj
└── NatureVsNoise/
    ├── Info.plist
    └── Sources/
        ├── NatureVsNoiseView.swift    # Main screensaver view
        ├── FeatureFlags.swift         # User settings
        ├── Planets/                   # Planet rendering
        ├── Satellites/                # Satellite systems
        ├── Audio/                     # Audio controller
        └── UI/                        # HUD overlay
```

## License

Code: MIT | Textures: NASA (Public Domain) | Data: CelesTrak
