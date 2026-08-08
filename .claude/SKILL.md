---
name: "NatureVsNoise"
description: macOS screensaver visualizing Earth's satellite swarm with real CelesTrak TLE data and SGP4 propagation. Hybrid SceneKit + Metal rendering, SpriteKit "Astra" HUD. Use for 3D graphics, orbital mechanics, satellite visualization, and screensaver development.
---

# NatureVsNoise — AI Quick Start

macOS screensaver contrasting cosmic serenity with the chaotic swarm of satellites orbiting Earth.

> **Single source of truth for current state:** [`STATUS.md`](../../STATUS.md) (project state) and
> [`TASKS.md`](../../TASKS.md) (open work). This skill is a stable orientation map — when it disagrees
> with the codebase, the codebase wins. Verify specifics before relying on them.

---

## ⚠️ Read this first: the repo holds THREE projects

| Directory | What it is | Build it? |
|:---|:---|:---|
| **`NatureVsNoise/`** | ✅ **THE canonical macOS screensaver.** All active work happens here. | **Yes** |
| `NatureVsNoise-Cinematic/` | Separate *experimental* concept ("Cosmic Kubrick" — satellites as light events). Own Xcode project. Not the shipping product. | No (unless asked) |
| `MinimalTest/` | A ~15-line `ScreenSaverView` debug stub for isolating load/signing issues. | No |

Unless told otherwise, **"the screensaver" = `NatureVsNoise/`.**

---

## Project facts (verified against code, 2026-06)

| Attribute | Details |
|:---|:---|
| **Type** | macOS Screensaver (`.saver` bundle) |
| **Min OS** | macOS 13.0 (`MACOSX_DEPLOYMENT_TARGET = 13.0`) |
| **Language / frameworks** | Swift 5.9, `ScreenSaver.framework`, SceneKit, Metal, **SpriteKit** (HUD), AppKit |
| **Repository** | github.com/matthewworner/Orbitor — current branch `astra-hud-redesign` |
| **Status** | Code complete, Release build green, runtime-verified on this Mac (see STATUS.md) |

### Rendering architecture (hybrid)
- **SceneKit** — Sun, 8 planets (8K NASA textures), hero satellites, NASA 3D models (Hubble, TESS, TDRS, Juno).
- **Metal** — the satellite swarm, drawn as instanced points via a SceneKit render-pass delegate.
- **SpriteKit** — the "Astra" mission-control HUD overlay (glass panels, JetBrains Mono, telemetry).

### Satellite data — get the numbers right
- **Live fetch:** `TLEFetcher` pulls multiple CelesTrak GROUP endpoints (active, starlink, stations,
  and several debris fields) — tens of thousands of objects when online.
- **Offline fallback:** `NatureVsNoise/8K/active_satellites.tle` bundles **14** satellites.
- **Render cap:** the Metal swarm is capped at **5,000** points (`maxSatellites`, reduced from 50,000
  for stability; default also in `FeatureFlags`). Do not claim "23,000 rendered" — they're *fetched*, then capped.
- **Propagation:** `SGP4Propagator` (WGS-72 constants), with guards for circular/parabolic orbits.

---

## Source map (`NatureVsNoise/NatureVsNoise/Sources/`)

| Area | Path | Purpose |
|:---|:---|:---|
| Entry point | `NatureVsNoiseView.swift` | Main `ScreenSaverView`; wires scene, swarm, HUD, camera |
| Settings | `FeatureFlags.swift` | User toggles / quality / counts (UserDefaults-backed) |
| Planets | `Planets/PlanetFactory.swift` | Planet + Sun nodes, textures, rings |
| Satellites | `Satellites/` | `SGP4Propagator`, `SatelliteManager`, `TLEFetcher`, `MetalSatelliteRenderer`, `SatelliteRenderer`, `SatelliteClassification` |
| Camera | `Camera/CameraController.swift` | Cinematic camera moves |
| Audio | `Audio/AudioController.swift` | Ambient audio (wiring present) |
| HUD | `UI/HUDOverlay.swift`, `UI/Themes/MissionControlTheme.swift`, `UI/Components/` | Astra SpriteKit overlay, panels, banners, fact/info cards |
| HUD data | `UI/Data/` | `EducationalFacts`, `SatelliteDatabase`, `Achievements` |
| Cross-platform | `CrossPlatform/` | `TextureManager`, `MaterialFactory`, `OrbitalModels`, `ImageLoader` |
| Tests | `../NatureVsNoiseTests/` | `SGP4PropagatorTests`, `FeatureFlagsAndTLETests` (no runnable target yet — see TASKS.md) |

---

## Commands

```bash
# Build (Release) — run from the canonical project dir
cd NatureVsNoise
xcodebuild -project NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build

# Install
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver \
  ~/Library/Screen\ Savers/
```
Then select **"Nature vs Noise"** in System Settings → Screen Saver → Preview.

**Deployment gotcha:** macOS 26.5+ refuses ad-hoc-signed screensavers (AMFI launch-constraint). A
Developer ID Application signature is required to load locally; notarization is required to distribute
to other Macs. Full steps: [`NatureVsNoise/DEPLOYMENT.md`](../../NatureVsNoise/DEPLOYMENT.md).

---

## Where the docs live

Start at the documentation index: [`docs/README.md`](../../docs/README.md). Highlights:
`README.md` (overview) · `STATUS.md` (state) · `TASKS.md` (work) · `CHANGELOG.md` (history) ·
`docs/ASTRA_HUD.md` (HUD design) · `docs/TROUBLESHOOTING.md` · `prd.md` (full product spec).

---

## Common tasks

- **Change satellite visuals** → `Satellites/SatelliteClassification.swift` + `MetalSatelliteRenderer.swift`.
- **Change the HUD** → `UI/` (SpriteKit), design tokens in `UI/Themes/MissionControlTheme.swift`; reference `docs/ASTRA_HUD.md`.
- **Add/refresh satellites** → CelesTrak endpoints in `Satellites/TLEFetcher.swift`; offline list in `8K/active_satellites.tle`.
- **Tune the camera** → `Camera/CameraController.swift`.
- **Ship a build** → build Release, sign (Developer ID), bump Info.plist version, update `CHANGELOG.md`, zip into `dist/`.

---

*Orientation map — keep stable. For live state, read `STATUS.md`. Last reconciled with code: 2026-06-16.*
