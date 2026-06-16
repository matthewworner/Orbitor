# Documentation index

Map of every doc in the repo, grouped by purpose, with a freshness note. Start here when you're
looking for *anything* written down.

> **Conventions** — to keep this repo navigable, write:
> - **current state** → [`STATUS.md`](../STATUS.md) (the one source of truth for "where are we")
> - **open work** → [`TASKS.md`](../TASKS.md)
> - **history** → [`CHANGELOG.md`](../CHANGELOG.md)
> - **reference / design** → this `docs/` folder
> - **AI orientation** → [`CLAUDE.md`](../CLAUDE.md) and [`.claude/SKILL.md`](../.claude/SKILL.md)
>
> Anything dated and marked *historical* below is a point-in-time snapshot — read it for context, not
> for current facts. When a doc disagrees with the code, the code wins.

---

## 🚀 Start here (live, kept current)

| Doc | Purpose |
|:---|:---|
| [`../CLAUDE.md`](../CLAUDE.md) | AI navigation hub — repo map, source map, build commands, "where to look for what" |
| [`../.claude/SKILL.md`](../.claude/SKILL.md) | Auto-loaded skill — same orientation, condensed |
| [`../README.md`](../README.md) | Product overview, features, quick start |
| [`../STATUS.md`](../STATUS.md) | **Current project state & health** (single source of truth) |
| [`../TASKS.md`](../TASKS.md) | **Open tasks / next steps** (single source of truth) |
| [`../CHANGELOG.md`](../CHANGELOG.md) | Version history |

## 🛠️ Build, deploy & troubleshoot

| Doc | Purpose |
|:---|:---|
| [`../NatureVsNoise/DEPLOYMENT.md`](../NatureVsNoise/DEPLOYMENT.md) | Developer ID signing + notarization (required on macOS 26.5+) |
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Common build/runtime/signing problems and fixes |
| [`TVOS_SETUP_INSTRUCTIONS.md`](TVOS_SETUP_INSTRUCTIONS.md) | tvOS variant setup notes |

## 🎨 Design reference (Astra HUD)

| Doc | Purpose |
|:---|:---|
| [`ASTRA_HUD.md`](ASTRA_HUD.md) | HUD design reference — tokens, components, fonts, layout |
| [`STITCH_PROMPTS.md`](STITCH_PROMPTS.md) | Google Stitch prompts + base objects used to design the HUD |
| [`stitch-base/`](stitch-base/) | Stitch source/output assets (screenshots, base files) |

## 📋 Product spec

| Doc | Purpose |
|:---|:---|
| [`../prd.md`](../prd.md) | Full product requirements (large; the original vision incl. 12–15 min cinematic tour) |

## 🗂️ Historical snapshots (context only — not current)

These predate the current build. Kept for history; **do not treat numbers/status here as current.**

| Doc | Date | Note |
|:---|:---|:---|
| [`VERIFICATION_REPORT.md`](VERIFICATION_REPORT.md) | 2026-02-21 | Feature-complete verification. ⚠️ Pre-Astra; says "23,000+ rendered" and "40-sec camera" — superseded by current code (fetched-not-rendered; swarm capped at 5,000). |
| [`../plans/LAUNCH_ROADMAP.md`](../plans/LAUNCH_ROADMAP.md) | 2026-02-21 | Early launch roadmap |
| [`../plans/NEXT_TASKS.md`](../plans/NEXT_TASKS.md) | 2026-02-21 | Early task list — superseded by `TASKS.md` |
| [`../archive/`](../archive/) | various | `PRD_IMPLEMENTATION_PLAN`, `RESTORATION_PLAN`, `UI_ENHANCEMENT_PLAN`, `ASSETS_CHECKLIST`, `DEBUG_SESSION_2026_01_03` — superseded working docs |

## 🧪 Non-canonical projects (separate from the shipping screensaver)

| Doc | Purpose |
|:---|:---|
| [`../NatureVsNoise-Cinematic/README.md`](../NatureVsNoise-Cinematic/README.md) | "Cosmic Kubrick" experimental concept — separate Xcode project |
| [`../NatureVsNoise-Cinematic/DEVELOPMENT.md`](../NatureVsNoise-Cinematic/DEVELOPMENT.md) | Dev notes for the experiment |
| `../MinimalTest/` | Debug stub — no docs, just a minimal `ScreenSaverView` |

---

*Index reconciled with the codebase 2026-06-16. When you add a doc, add a row here and put it in the
right group.*
