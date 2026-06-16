# CLAUDE.md — AI navigation hub

This is the entry point for any AI (or human) working in this repo. It is a **map**, not a status
report. For live state, follow the pointers below — don't trust hard-coded status here.

> Mirrors the project section in [`/Users/pro/Projects/PROJECTS.html`](../PROJECTS.html). If they
> conflict, PROJECTS.html wins. Update both together.

---

## What this is

**NatureVsNoise** — a macOS screensaver contrasting cosmic serenity with the chaotic swarm of
satellites orbiting Earth. Earth-centered SceneKit scene + a Metal-rendered satellite swarm driven by
real CelesTrak TLE data and SGP4 propagation, with a SpriteKit "Astra" mission-control HUD.

- **Repo:** github.com/matthewworner/Orbitor
- **Min OS:** macOS 13.0 · **Stack:** Swift 5.9, ScreenSaver.framework, SceneKit, Metal, SpriteKit, AppKit

---

## ⚠️ The repo contains THREE projects — only one is canonical

| Directory | Role | Build it? |
|:---|:---|:---|
| **`NatureVsNoise/`** | ✅ **Canonical** macOS screensaver. All active work. | **Yes** |
| `NatureVsNoise-Cinematic/` | Separate experiment ("Cosmic Kubrick"). Own Xcode project. | No (unless asked) |
| `MinimalTest/` | Debug stub (~15-line `ScreenSaverView`) for load/signing isolation. | No |

Unless told otherwise, **"the screensaver" = `NatureVsNoise/`.**

---

## Repository layout

```
Screensaver/
├── NatureVsNoise/             ✅ canonical project (build here)
│   ├── NatureVsNoise.xcodeproj
│   ├── 8K/                    textures + active_satellites.tle (14 sats, offline fallback)
│   ├── NatureVsNoise/Sources/ Swift source (see source map below)
│   ├── NatureVsNoiseTests/    SGP4 + flags tests (no runnable target yet)
│   ├── tvOS/                  tvOS variant
│   └── DEPLOYMENT.md          code signing + notarization
├── NatureVsNoise-Cinematic/   experiment (non-canonical)
├── MinimalTest/               debug stub (non-canonical)
├── docs/                      reference + design docs — START at docs/README.md
├── plans/                     historical planning snapshots (Feb 2026)
├── archive/                   superseded plans/checklists (kept for history)
├── scripts/                   asset download / texture processing helpers
├── Assets/Raw/                raw source assets
├── dist/                      release zips (gitignored, not in source tree)
├── README.md                  product overview + quick start
├── STATUS.md                  ← single source of truth for CURRENT STATE
├── TASKS.md                   ← single source of truth for OPEN WORK
├── CHANGELOG.md               version history
└── prd.md                     full product requirements (large)
```

## Source map — `NatureVsNoise/NatureVsNoise/Sources/`

| Path | Purpose |
|:---|:---|
| `NatureVsNoiseView.swift` | Main `ScreenSaverView` — wires scene, swarm, HUD, camera |
| `FeatureFlags.swift` | User settings / quality / counts (UserDefaults) |
| `Planets/PlanetFactory.swift` | Sun + 8 planets, textures, rings |
| `Satellites/` | `SGP4Propagator`, `SatelliteManager`, `TLEFetcher`, `MetalSatelliteRenderer`, `SatelliteRenderer`, `SatelliteClassification` |
| `Camera/CameraController.swift` | Cinematic camera |
| `Audio/AudioController.swift` | Ambient audio |
| `UI/` | Astra **SpriteKit** HUD — `HUDOverlay`, `Themes/MissionControlTheme`, `Components/`, `Data/` |
| `CrossPlatform/` | `TextureManager`, `MaterialFactory`, `OrbitalModels`, `ImageLoader` |

## How the satellites work (don't misquote the numbers)

- **Live:** `TLEFetcher` pulls several CelesTrak GROUP endpoints (active / starlink / stations /
  debris) — tens of thousands of objects when online.
- **Offline:** falls back to **14** bundled TLEs (`8K/active_satellites.tle`).
- **Rendered:** the Metal swarm is **capped at 5,000** points (`maxSatellites`). Fetched ≠ rendered.

---

## Build / install / run

```bash
cd NatureVsNoise
xcodebuild -project NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver \
  ~/Library/Screen\ Savers/
# then: System Settings → Screen Saver → "Nature vs Noise" → Preview
```

**Signing:** macOS 26.5+ rejects ad-hoc-signed screensavers (AMFI launch-constraint). Developer ID
signature required to run locally; notarization required to distribute. See `NatureVsNoise/DEPLOYMENT.md`.

---

## Where to look for what

| I want… | Go to |
|:---|:---|
| Current state / health | **`STATUS.md`** |
| Open tasks / next steps | **`TASKS.md`** |
| Full doc index | **`docs/README.md`** |
| Product overview & quick start | `README.md` |
| HUD design (tokens, fonts, panels) | `docs/ASTRA_HUD.md` |
| Build/runtime troubleshooting | `docs/TROUBLESHOOTING.md` |
| Code signing & notarization | `NatureVsNoise/DEPLOYMENT.md` |
| Full product spec | `prd.md` |
| Version history | `CHANGELOG.md` |
| Real-time git state | `git status` / `git log` (don't trust dates written in docs) |

**Doc conventions:** put *state* in `STATUS.md`, *work* in `TASKS.md`, *history* in `CHANGELOG.md`,
*reference/design* under `docs/`. Don't scatter status across multiple files.
