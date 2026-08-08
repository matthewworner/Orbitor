# Stitch base objects

Faithful HTML/CSS recreations of the screensaver's current overlay UI, so Google Stitch can
**build improved designs from them** via the `code-to-design` skill (Stitch reads frontend code,
not SpriteKit/Swift).

## Files
- `index.html` — full HUD composition + an isolated component sheet, using the real
  `MissionControlTheme` tokens and real data fields.
- `DESIGN.md` — semantic design spec (tokens, type, components) to upload with the code.

## Workflow
1. **Upload base objects** (`stitch-build` / `code-to-design`):
   > "Upload the frontend code at `docs/stitch-base` into a Stitch project named
   > `NatureVsNoise-HUD`, and apply the design system in `docs/stitch-base/DESIGN.md`."
2. **Generate improved variants** (`stitch-design` / `generate-design` + `generate-variants`) using
   the prompts in `../STITCH_PROMPTS.md`. They reference these exact components.
3. **Pick the most restrained variant**, export React/HTML.
4. **Port back to native**: translate spacing/type/color/hierarchy into the SpriteKit overlay
   (`Sources/UI/HUDOverlay.swift`, `Components/*`, `Themes/MissionControlTheme.swift`). Don't embed
   web output in the `.saver`.

## Note on the 3D satellites
Stitch only touches the 2D overlay. The 3D satellite models/textures are a separate art pipeline
(NASA 3D Resources, texture sources) handled in `SatelliteRenderer.swift` /
`SatelliteClassification.swift` — see the last section of `../STITCH_PROMPTS.md`.
