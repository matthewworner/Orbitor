# Google Stitch Prompts — Nature's Calm vs. Humanity's Noise

> **Scope note.** Google Stitch turns prompts/images into **UI designs and frontend code**
> ([blog](https://developers.googleblog.com/en/stitch-a-new-way-to-design-uis/),
> [stitch-skills](https://github.com/google-labs-code/stitch-skills)). It does **not** generate
> 3D models, `.glb`/`.scn` files, or planet/satellite textures. These prompts therefore target the
> screensaver's **overlay UI layer** (HUD, panels, cards, legend, settings) — the design + code of
> which then gets reimplemented as the SwiftUI / SpriteKit overlay drawn on top of the SceneKit+Metal
> scene. For the actual 3D satellites and textures, see the last section.

**Workflow per the stitch-skills repo:**
1. **Upload the base objects first** so Stitch builds *from* the existing UI, not a blank slate:
   > "Upload the frontend code at `docs/stitch-base` into a Stitch project named `NatureVsNoise-HUD`,
   > and apply the design system in `docs/stitch-base/DESIGN.md`."
   (These are HTML/CSS recreations of the real `StatsPanel`, `InfoCard`, HUD, etc. — see
   `docs/stitch-base/`.)
2. Optionally run prompt **0** to formalize the design system (already captured in `DESIGN.md`).
3. Run each screen prompt below; they reference the shared design system + base objects.
4. Use `generate-variants` to get 2–3 options per screen, pick the most restrained one.
5. Export via `react-components` or `code-to-design`, then port the layout/spacing/type into the
   native overlay (`Sources/UI/HUDOverlay.swift`, `Components/`, `SettingsController.swift`).

**Aesthetic north star:** NASA mission-control telemetry × modern glassmorphism. Dark, cinematic,
high-legibility over a moving star/planet background. The product's thesis — *serene cosmos vs.
chaotic human swarm* — should read in the UI: calm typography, but the satellite/debris data is
dense, busy, slightly alarming.

---

## 0 — Design System (run this first)

```
Create a design system for "Nature's Calm vs. Humanity's Noise", a cinematic macOS screensaver
that visualizes 23,000+ real satellites orbiting Earth as a NASA mission-control telemetry overlay.

Aesthetic: dark, premium, glassmorphic mission-control HUD that sits on top of a live, moving
solar-system background. It must stay legible over both bright planets and black space.

Color: near-black/transparent glass panels (frosted, subtle 1px hairline borders at ~12% white).
Accent palette by satellite class — ISS amber/gold (#F5B642), Starlink cyan (#46D5E5),
notable/science green (#5CE6A1), generic active white (#E8ECF2), debris muted red/grey (#C2554E).
A single "calm" accent (soft astral blue #7FA8FF) for nature/ambient context.

Typography: a monospace face for telemetry numerals/readouts (altitude, velocity, counts) and a
clean geometric sans for labels and body. Tabular figures so numbers don't jitter as they update.

Components to define: frosted glass panel, hairline divider, telemetry stat (label + big mono value
+ unit), live counter, status pill/tag, color-coded legend chip, segmented control, slider,
toggle, and a small "ticker" line for rotating facts.

Motion: everything should feel like live data — counters tick, values ease, nothing pops harshly.
Output as a reusable design system / DESIGN.md with tokens for color, type scale, spacing, radius,
and the glass/blur treatment.
```

---

## 1 — Mission Control HUD (primary overlay)

```
Design the main heads-up overlay for the screensaver, using our design system. Full-screen 16:9,
mostly transparent so the 3D solar system shows through; UI anchored to the four corners.

Top-left: mission title "NATURE'S CALM vs. HUMANITY'S NOISE" in small caps, with a live UTC clock
and a "TRACKING" status pill underneath.

Top-right: a compact live telemetry block — total tracked objects (big mono counter, ~23,418),
and three smaller readouts: active satellites, debris, decaying this week.

Bottom-left: a focus readout for whatever the camera is near — object name, altitude (km),
velocity (km/s), inclination (deg), as labeled telemetry stats with tabular mono numerals.

Bottom-right: a small color legend of satellite classes (ISS, Starlink, notable, active, debris).

Keep it sparse and cinematic — this is glanceable, not a dashboard. Show it over a dark space
background so I can judge contrast.
```

---

## 2 — Stats Panel (the "nature vs noise" ratio)

```
Design a frosted glass stats panel that quantifies the screensaver's core message, using our
design system. It anchors to one corner of the screen.

Header: "ORBITAL CENSUS". A horizontal stacked bar broken down by satellite class with our class
colors (Starlink, other active, notable/science, debris/rocket bodies), each segment labeled with
a count and percentage.

Below it, a hero stat that makes the thesis land: "Objects launched by humanity in 60 years" with a
large mono number, and a quiet sub-line contrasting it with "Natural objects in this view: 1 (Moon)".

Footer: a thin live ticker that updates ("Starlink +12 since you started watching").
Calm typography, but let the density of the data feel a little overwhelming — that's the point.
```

---

## 3 — Satellite Info Card (camera focus on a hero satellite)

```
Design a detail card that appears when the cinematic camera focuses on a notable satellite (e.g.
ISS, Hubble, TESS), using our design system. It should slide in from the side and feel like a
mission dossier.

Contents: satellite name, operator, country (with a small flag/region chip), launch year and age,
current altitude (km), orbital velocity (km/s), orbit type (LEO/GEO), and a one-line "what it does"
description. Include a small status row: active / aging / debris, color-coded.

Layout: a slim vertical card, glass, with a thin accent edge in the satellite's class color.
Telemetry values in mono with units. Make a version for ISS (amber, detailed) and one for a generic
Starlink (cyan, minimal) so I can see the system flex.
```

---

## 4 — Classification Legend / Key

```
Design a compact legend that explains how each satellite type is rendered, using our design system.
A row or small grid of legend chips: each shows the class color, a tiny glyph hinting at its shape
(ISS = detailed model, Starlink = flat panel, notable = science craft, active = generic sat,
debris = dark irregular chunk), the class name, and its live count.

It should work as a persistent corner element AND as an expanded onboarding card shown briefly when
the screensaver starts. Keep chips small, aligned, mono counts, tabular figures.
```

---

## 5 — Educational Fact Ticker / Card

```
Design a rotating educational fact element for the screensaver, using our design system. Two
formats: (a) a single-line bottom ticker for ambient facts, and (b) a larger fade-in fact card for
deeper trivia.

The card has a small category tag (ORBITAL MECHANICS / SPACE DEBRIS / SATELLITES), a short bold
headline stat, and one sentence of context. Example: tag "SPACE DEBRIS", headline "~23,000 tracked
objects", context "and millions too small to track, each a collision risk at 28,000 km/h."

Quiet, elegant, science-museum tone. Design 3 example cards with different categories.
```

---

## 6 — Settings / Configure Sheet (macOS)

```
Design the configuration sheet for this macOS screensaver, using our design system. This is a
macOS-style modal panel opened from System Settings, ~520pt wide, light-on-dark glass.

Sections:
- PERFORMANCE: quality segmented control (Safe / Medium / High / Ultra), satellite count slider
  (100–23,000) with a live value, and a small "recommended for your Mac" hint.
- VISUALS: toggles for Satellite swarm (Metal), Motion trails, Material aging, Thermal glow,
  Mission Control HUD, Educational facts.
- AUDIO: enable ambient audio toggle + volume slider.
- DATA: "Update satellite data (TLE)" button with last-updated timestamp.
Footer: presets (Safe / Balanced / Cinematic) as pills, and a "Restore defaults" link.

Make it feel native to macOS but on-brand with the mission-control aesthetic. Group with clear
section headers and hairline dividers.
```

---

## 7 — Title / Boot Sequence Card (optional, high impact)

```
Design an opening title + boot sequence overlay shown for the first few seconds of the screensaver,
using our design system. Mission-control "systems online" feel.

Center: title "NATURE'S CALM vs. HUMANITY'S NOISE", subtitle "Real-time visualization of 23,000+
objects orbiting Earth · Data: CelesTrak · SGP4". Below it, a short telemetry boot log that types
out: "Loading TLE catalog… 23,418 objects", "Propagating orbits (SGP4)…", "Renderer: SceneKit +
Metal", "Tracking online." with a thin progress line.

Cinematic, restrained, fades out into the live scene. Show it over black space.
```

---

## Tips for better Stitch output on this project

- **Always feed it context of the background.** Add "shown over a dark moving star/planet field;
  must stay legible over bright planets" to every screen prompt — Stitch defaults to opaque app UIs.
- **Ask for variants** (`generate-variants`) and keep the most *restrained* one; screensaver UI
  should be glanceable, not a SaaS dashboard.
- **Lock the design system once** (prompt 0) and reference it everywhere for consistency.
- **Export to React/HTML, then port** the spacing/type/color decisions into the native overlay —
  don't try to embed the web output directly in the `.saver`.

---

## What Stitch can't do here — the actual 3D satellites & textures

The literal "better satellites" (3D geometry) and planet textures are **out of Stitch's scope**.
The right tools for those:

| Asset | Not Stitch — use instead |
|---|---|
| 3D satellite models (ISS, Hubble, Starlink, debris) | NASA 3D Resources (free `.glb`/`.obj`), or a 3D tool / 3D-gen model; convert to `.scn` |
| Planet / Sun / starfield textures | Solar System Scope textures, NASA SVS, or an image-gen model at 8K, equirectangular |
| Procedural debris look | Done in-engine via `SatelliteRenderer.swift` (material aging / thermal glow already exist) |
| Satellite shapes by class | In-engine geometry in `SatelliteClassification.swift` + `SatelliteRenderer.swift` |

Stitch makes the **interface around** the satellites look world-class; the satellites themselves are
an art/3D-pipeline task in the Swift/SceneKit code.
```
