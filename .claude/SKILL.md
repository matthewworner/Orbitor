---
name: "NatureVsNoise"
description: macOS screensaver visualizing 23,000+ satellites orbiting Earth with real orbital data. SceneKit + Metal hybrid rendering. Use for 3D graphics, orbital mechanics, satellite visualization, and screensaver development.
---

# NatureVsNoise Skill

macOS screensaver contrasting cosmic serenity with the chaotic swarm of 23,000+ satellites orbiting Earth.

---

## PROJECT OVERVIEW

| Attribute | Details |
|:---|:---|
| **Type** | macOS Screensaver |
| **Platform** | macOS 13.0+ |
| **Language** | Swift, SceneKit, Metal |
| **Status** | Feature Complete - v1.0.0 |
| **Repository** | github.com/matthewworner/Orbitor |

### Key Features
- Solar System: Sun + 8 planets with 8K NASA textures
- 23,000+ satellites rendered from real orbital data (CelesTrak TLE)
- SGP4 propagation for accurate satellite positions
- NASA 3D Models: Hubble, TESS, TDRS, Juno
- Hybrid Rendering: SceneKit for planets/hero satellites, Metal for 5000+ swarm points
- Satellite Classification: ISS, Starlink, notable satellites, debris each render differently
- Visual Effects: Motion trails, material aging, thermal glow
- Cinematic Camera: 12-15 minute grand tour cycle

---

## TECH STACK

| Layer | Technology |
|:---|:---|
| **UI** | SwiftUI, ScreenSaver framework |
| **3D** | SceneKit, Metal |
| **Data** | CelesTrak TLE files, SGP4 propagation |
| **Assets** | NASA 8K textures, NASA 3D models |
| **Platform** | macOS Screen Saver framework |

---

## PROJECT STRUCTURE

```
Screensaver/
├── NatureVsNoise/
│   ├── NatureVsNoise.xcodeproj/      # Xcode project
│   ├── NatureVsNoise/
│   │   ├── Info.plist                # Screensaver config
│   │   ├── Resources/                # Assets, textures
│   │   └── Sources/
│   │       ├── NatureVsNoiseView.swift  # Main screensaver view
│   │       ├── FeatureFlags.swift       # User settings
│   │       ├── Planets/                 # Planet rendering
│   │       ├── Satellites/              # Satellite systems
│   │       ├── Audio/                   # Audio controller
│   │       ├── Camera/                  # Camera movements
│   │       ├── UI/                      # HUD overlay
│   │       └── CrossPlatform/           # Platform abstraction
│   ├── 8K/                            # 8K texture files
│   ├── tvOS/                          # tvOS variant
│   └── build/                         # Build outputs
├── docs/
│   ├── TROUBLESHOOTING.md
│   ├── TVOS_SETUP_INSTRUCTIONS.md
│   └── VERIFICATION_REPORT.md
├── plans/                             # Planning documents
├── archive/                           # Archived files
├── scripts/                           # Build scripts
├── prd.md                             # Full product requirements
├── CHANGELOG.md                       # Version history
├── STATUS.md                          # Current status
└── LAUNCH.md                          # Launch assets (HN, PH, etc.)
```

---

## KEY FILES

| File | Purpose |
|:---|:---|
| `NatureVsNoise/Sources/NatureVsNoiseView.swift` | Main screensaver view (36KB) |
| `NatureVsNoise/Sources/FeatureFlags.swift` | User settings/feature toggles |
| `NatureVsNoise/Sources/Planets/` | Planet rendering system |
| `NatureVsNoise/Sources/Satellites/` | Satellite classification & rendering |
| `NatureVsNoise/Sources/Audio/` | Ambient audio controller |
| `NatureVsNoise/Sources/Camera/` | Cinematic camera movements |
| `NatureVsNoise/Sources/UI/` | HUD overlay elements |
| `prd.md` | Full product requirements (1339 lines) |

---

## COMMANDS

### Build
```bash
cd NatureVsNoise
xcodebuild -scheme NatureVsNoise -configuration Release build
```

### Install
```bash
# Copy to Screen Savers folder
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver ~/Library/Screen\ Savers/
```

### Run
Select **NatureVsNoise** in System Settings → Screen Saver

---

## RENDERING ARCHITECTURE

### Hybrid Rendering
- **SceneKit**: Planets, hero satellites (ISS, Hubble, etc.)
- **Metal**: 5000+ swarm points for satellite debris field
- Integration: SceneKit delegate for Metal full-screen rendering

### Performance
- Target: 60fps
- Metal for high-volume point rendering
- Frame-synchronized updates (not Timer-based)

---

## SATELLITE SYSTEM

### Data Source
- CelesTrak TLE (Two-Line Element) files
- Updated regularly for current orbital positions

### SGP4 Propagation
- Accurate orbital position calculation
- Handles orbital mechanics (drag, perturbations)

### Classification
| Category | Rendering |
|:---|:---|
| ISS | Larger, detailed model |
| Starlink | Distinct visual style |
| Notable satellites | NASA 3D models |
| Debris | Small points, motion trails |

---

## VISUAL EFFECTS

- **Motion Trails**: Orbital path visualization
- **Material Aging**: Weathered satellite appearance
- **Thermal Glow**: Heat-based coloring
- **Country Colors**: Origin-based satellite coloring (optional)

---

## CAMERA SEQUENCE

### 12-15 Minute Cycle
1. **Act I: Grand Tour (8-10 min)** - Outer planets → Saturn rings → Jupiter → Mars → Earth approach
2. **Act II: The Reveal (4-6 min)** - Earth zoom-in, satellite swarm emergence, orbital dance
3. **Act III: Return (30-60 sec)** - Pull back to deep space, loop

---

## CODING CONVENTIONS

### Swift/SceneKit/Metal
- SwiftUI for configuration UI
- SceneKit for structured 3D objects
- Metal for high-performance point rendering
- Frame-synchronized updates

### Architecture
- Feature flags for user settings
- Modular systems (Planets, Satellites, Audio, Camera)
- Cross-platform abstraction layer

---

## COMMON TASKS

### Adding a New Planet Feature
1. Edit files in `Sources/Planets/`
2. Update textures in `Resources/` or `8K/`
3. Adjust camera sequence if needed

### Modifying Satellite Rendering
1. Edit files in `Sources/Satellites/`
2. Update classification logic
3. Adjust Metal shaders for visual effects

### Updating TLE Data
1. Download latest from CelesTrak
2. Update data files in Resources
3. SGP4 will use new orbital elements

### Building for Distribution
1. Build Release configuration
2. Create zip of .saver file
3. Update version in Info.plist
4. Update CHANGELOG.md

---

## REQUIREMENTS

- macOS 13.0+
- Apple Silicon recommended (Intel supported)
- GPU capable of Metal rendering

---

## DOCUMENTATION

| Document | Purpose |
|:---|:---|
| `prd.md` | Full product requirements |
| `CHANGELOG.md` | Version history |
| `docs/TROUBLESHOOTING.md` | Common issues |
| `plans/LAUNCH_ROADMAP.md` | Development status |
| `LAUNCH.md` | Launch assets (HN, Product Hunt, social) |

---

## PENDING TASKS

1. User testing on different hardware configurations
2. Performance profiling
3. Expand cinematic camera sequence (PRD 12-15 min tour)

---

## QUICK REFERENCE

| Need | File/Command |
|:---|:---|
| Build | `xcodebuild -scheme NatureVsNoise -configuration Release build` |
| Install | Copy `.saver` to `~/Library/Screen Savers/` |
| Main view | `NatureVsNoise/Sources/NatureVsNoiseView.swift` |
| Settings | `NatureVsNoise/Sources/FeatureFlags.swift` |
| Status | `STATUS.md` |
| PRD | `prd.md` |

---

*Last updated: 28 February 2026*
