# Nature's Calm vs. Humanity's Noise

A macOS screensaver contrasting cosmic serenity with the chaotic swarm of 23,000+ satellites orbiting Earth.

## Current Status (2026-01-07)

**Working:**
- ✅ Solar system renders (Sun + 8 planets with 8K textures)
- ✅ Earth with cloud layer
- ✅ Starfield (5000 procedural stars, optional)
- ✅ Satellite rendering with multiple modes:
  - Toy satellites: 50 simplified cross/T shapes (SceneKit)
  - Firefly swarm: Thousands of glowing points (Metal, optional)
  - Combined rendering with feature flags
- ✅ Cinematic fly-through camera (40-second loop)
- ✅ Multi-display support
- ✅ Feature flags system for safe/stable presets
- ✅ Comprehensive logging to ~/Library/Logs/NatureVsNoise.log

**In Progress:**
- 🔧 Debugging full-screen black screen issue (logging added)
- ⚠️ Performance optimization and Metal stability
- ⚠️ Audio integration (ambient + planetary clips)
- ⚠️ Settings UI for user customization

## Quick Start

```bash
# Build and install
cd NatureVsNoise
xcodebuild -scheme NatureVsNoise -configuration Release build
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver ~/Library/Screen\ Savers/
```

## Feature Flags & Presets

The screensaver uses feature flags stored in UserDefaults for stability. Default "safe" preset:
- Planets + starfield + 800 toy satellites
- No Metal rendering, no labels
- Stable for most systems

Available presets:
- **Safe**: Basic features, maximum stability
- **Full**: All features enabled (may be unstable)
- **Toy Only**: Just simplified satellites
- **Swarm Only**: Just Metal firefly points

Check logs at `~/Library/Logs/NatureVsNoise.log` for debugging.

## Troubleshooting

- **Black screen in full-screen mode**: Check logs for lifecycle events and FPS
- **Performance issues**: Use safe preset or reduce satellite count
- **Metal rendering fails**: Feature automatically disabled on unsupported hardware

## Project Structure

```
├── prd.md              # Full product specifications
├── LAUNCH_ROADMAP.md   # Development roadmap and status
├── Assets/Raw/         # Source textures (8K) & TLE data
├── NatureVsNoise/      # Xcode project
│   └── NatureVsNoise/Sources/
│       ├── NatureVsNoiseView.swift  # Main screensaver view
│       ├── FeatureFlags.swift       # User defaults and presets
│       ├── Planets/                  # Planet factory
│       └── Satellites/               # Satellite rendering (SceneKit + Metal)
└── DEBUG_SESSION_*.md  # Development logs
```

## Tech Stack

- **Framework:** SceneKit + Metal (hybrid rendering)
- **Language:** Swift 5.9
- **Target:** macOS 13.0+, Apple Silicon preferred
- **Performance:** 60fps target, adaptive quality
- **Features:** Feature flags, presets, comprehensive logging

## License

Code: MIT | Textures: NASA (Public Domain) | Data: CelesTrak
