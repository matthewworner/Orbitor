# Astra HUD — Design Reference

The screensaver's overlay UI ("Astra" mission-control HUD) is a native **SpriteKit** layer drawn on
top of the SceneKit + Metal scene. It was designed in Google Stitch (project *Astra Telemetry HUD
Overlay*) from base objects we uploaded, then re-implemented natively. The Stitch mockups live in
`docs/stitch-base/stitch-output/`; the prompts and base objects are in `docs/STITCH_PROMPTS.md` and
`docs/stitch-base/`.

> Stitch outputs HTML/CSS — it can't read SpriteKit. So the HUD is a *visual re-implementation* of
> the mockups, not a code import.

## Design tokens

All tokens live in `NatureVsNoise/Sources/UI/Themes/MissionControlTheme.swift`.

| Token | Value | Use |
|---|---|---|
| `primaryCyan` | `#00D4FF` | active elements, stats, ticker |
| `primarySoft` | `#A8E8FF` | titles, focus brackets, hero count |
| `natureBlue` | `#7FA8FF` | calm/ambient accent |
| `secondaryAmber` | `#FFB800` | notable satellites, dossier |
| `accentMagenta` | `#FF00AA` | ISS / crewed |
| `glassFill` | `rgba(10,20,40,0.65)` | panel fill |
| `glassBorder` | `rgba(255,255,255,0.12)` | hairline panel border |
| `bracketAccent` | `rgba(168,232,255,0.30)` | corner brackets |
| `hairline` | `rgba(255,255,255,0.15)` | row dividers |
| text primary / secondary / muted | white / 70% / 50% | values / readouts / labels |

Type: **JetBrains Mono** (bundled), tabular numerals. Scale — hero 28 · headline 18 · body 12 ·
label 11/10 · caps 9 · meta 8. Spacing — panel padding 12 · gap 8 · corner radius 6.

## Classification map (single source of truth)

`SatelliteClass` → HUD treatment, defined as an extension in `MissionControlTheme.swift`. Drives both
the classification legend and the dossier card accents.

| Class | Color | Legend code |
|---|---|---|
| `.iss` | gold `#FFD700` | `ISS_STATION` |
| `.starlink` | cyan `#00D4FF` | `STARLINK` |
| `.notable` | green `#3CC878` | `NOTABLE_INT` |
| `.activeSatellite` | white | `ACTIVE_COMMS` |
| `.debris` | red `#DC3C3C` | `DEBRIS_HAZARD` |

## Components

All in `NatureVsNoise/Sources/UI/`. The in-scene nodes (`GlassPanel`, `ContextualFocusPanel`,
`ClassificationLegend`, `BootSequenceOverlay`, `AmbientTicker`) live **inside** `HUDOverlay.swift` /
`Themes/MissionControlTheme.swift` rather than separate files — the Xcode project lists every source
file explicitly, so co-locating avoids `.pbxproj` edits.

| Component | Location | Stitch source | Notes |
|---|---|---|---|
| `GlassPanel` | `Themes/MissionControlTheme.swift` | (shared) | reusable fill + hairline + corner brackets |
| Mission cluster | `HUDOverlay.swift` | astra-hud-overlay | title + live UTC clock + TRACKING pill + OS footer |
| `StatsPanel` (telemetry dashboard) | `Components/StatsPanel.swift` | orbital-census | hero total + ACTIVE/DEBRIS (DECAY omitted, see below) |
| `ContextualFocusPanel` | `HUDOverlay.swift` | astra-hud-overlay | NAME / ALT / VEL / INCL |
| `ClassificationLegend` | `HUDOverlay.swift` | astra-hud-overlay | color chip + code + live count |
| Focus reticle + scanline + grid | `HUDOverlay.swift` | astra-hud-overlay | low-opacity cinematic overlay |
| `InfoCardView` (dossier) | `Components/InfoCardView.swift` | iss/starlink-dossier | type-colored accent border |
| `FactOverlay` | `Components/FactOverlay.swift` | fact-* | glass card, cyan category tag |
| `AmbientTicker` | `HUDOverlay.swift` | ambient-ticker | slim rotating census stat / fact one-liner |
| `BootSequenceOverlay` | `HUDOverlay.swift` | boot-sequence | typed boot log, ~4s, fades into scene |
| Configure sheet | `SettingsController.swift` | config-sheet | AppKit, sections PERFORMANCE/VISUALS/AUDIO/PRESETS |

### Data plumbing
`SatelliteManager.OrbitalCensus` (in `Sources/Satellites/SatelliteManager.swift`) tallies counts per
class via `SatelliteClassifier.classify`. It's cached and invalidated when `satellites` changes. The
main view (`NatureVsNoiseView.swift`) feeds it to the HUD each frame via `updateCensus` /
`updateFocus`, alongside the existing `updateCamera` / `updateStats`.

### Density levels
`InfoDensity` (`.minimal` / `.moderate` / `.educational`) gates which elements show, via
`HUDOverlay.updateVisibility()`. Minimal keeps only core panels; educational adds the fact card.

## Font bundling

`8K/JetBrainsMono-Regular.ttf` and `-Bold.ttf` are bundled as Copy-Bundle-Resources (added to
`project.pbxproj`). `MissionControlTheme.registerFonts(in:)` registers them with CoreText
(`CTFontManagerRegisterFontsForURL`, `.process` scope) at HUD init and captures their PostScript
names (`JetBrainsMono-Regular` / `-Bold`). `hudFont(...)` / `hudFontName(...)` return those, falling
back to the system monospaced font if registration fails — so a missing font degrades gracefully
rather than breaking the HUD.

## Known gaps
- **DECAY column removed.** "Decaying this week" isn't derivable from TLE data alone, so the
  telemetry dashboard is ACTIVE/DEBRIS only rather than showing a fake value.
- **No unit-test target.** Test files exist on disk but aren't wired to a runnable target; census /
  legend assertions were added to `NatureVsNoiseTests/FeatureFlagsAndTLETests.swift` ready for when a
  target is created.
- **Runtime unverified.** macOS 26.5 blocks unsigned screensavers; verification is build-only until
  the project is signed with a Developer ID cert + notarized. See `NatureVsNoise/DEPLOYMENT.md`.
