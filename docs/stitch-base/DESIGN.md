# DESIGN.md — Nature's Calm vs. Humanity's Noise (HUD)

> Semantic design spec for the screensaver's overlay UI. Mirrors `MissionControlTheme.swift`.
> Upload alongside `index.html` so Stitch builds variants on the *existing* system, not a generic one.

## Product
A cinematic macOS screensaver visualizing 23,000+ real satellites orbiting Earth. The UI is a
NASA mission-control telemetry overlay floating over a live SceneKit+Metal solar-system scene.
Thesis: **serene cosmos vs. chaotic human-made swarm** — keep UI calm and glanceable while the
satellite *data* feels dense and a little alarming.

## Constraints
- Overlay must stay legible over BOTH bright planets and black space → semi-transparent glass + blur.
- Glanceable, not a dashboard. Corner-anchored. Minimal chrome.
- Numbers update live → tabular/monospace figures, no layout jitter.

## Color tokens (exact)
| Token | Value | Use |
|---|---|---|
| primaryCyan | `#00D4FF` | orbital indicators, active elements, stats |
| secondaryAmber | `#FFB800` | notable satellites, info card, warnings |
| accentMagenta | `#FF00AA` | ISS / crewed |
| panelBackground | `rgba(10,20,40,0.75)` | glass panel fill |
| deepSpace | `rgba(5,10,20,0.85)` | deepest background |
| textPrimary | `#FFFFFF` | values |
| textSecondary | `rgba(255,255,255,0.70)` | readouts |
| textMuted | `rgba(255,255,255,0.50)` | labels |
| zone.LEO / MEO / GEO | cyan / yellow / magenta @60% | orbital zone coding |
| country USA/RU/CN/Other | `#3C78DC` / `#DC3C3C` / `#F0C828` / `#3CC878` | origin coding |
| gold/silver/bronze | `#FFD700` / `#C0C0C0` / `#CD7F32` | achievements |

## Type
- Family: **SF Mono** (monospace) throughout. Tabular numerals.
- Scale: header 14 bold · body 12 · small 10 · tiny 8.

## Spacing & shape
- Panel padding 12 · element gap 8 · corner radius 6.
- Decorative corner brackets (cyan @30%) on data panels; corner accent (amber) on the info card.

## Components (base objects in index.html)
1. **StatsPanel** 180×130 — title "MISSION STATS", big cyan count + "OBJECTS TRACKED", ALT/VEL readouts, zone dot+label. Cyan border @50%.
2. **InfoCardView** 220×100 — emoji, name (amber), "type • country", divider, description. Border = satellite type color. Top-right amber corner accent.
3. **FactOverlay** — category tag (cyan) + one-sentence educational fact. Bottom-center.
4. **DiscoveryBanner** — gold kicker "★ DISCOVERY UNLOCKED", name, description. Center.
5. **Zone legend** — color chips for LEO/MEO/GEO/HEO with altitude ranges.
6. **Country colors** — origin swatches.
7. **Mode label** — muted "MODE: CINEMATIC_AUTO", bottom-right.

## What to improve (the ask)
Keep the tokens and data fields; elevate hierarchy, glass treatment, legibility-over-scene, and
the sense of "live telemetry." Generate restrained variants — reject anything that reads as a busy
SaaS dashboard.
