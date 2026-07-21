# NatureVsNoise — Fable 5 Focused Stability Sweep Prompt

> **How to use:** Copy the fenced block below into Claude (Fable 5 enabled), run on the
> current `main` HEAD. READ-ONLY — writes ONE report file, nothing else.
>
> **Why this is deliberately small:** NatureVsNoise is a low-priority, working macOS
> screensaver — "no loss" if it breaks. A full multi-domain audit isn't worth the Fable
> budget here. The only failure modes that actually matter for a screensaver (it runs
> unattended for HOURS) are **long-run resource stability** and **graceful offline
> behaviour** — and the git log confirms it (a 23GB memory leak was just fixed). So this
> sweep is scoped to exactly that. Everything else is cosmetic and out of scope.
>
> **Cheaper alternative first:** run the saver under Instruments (Leaks + Allocations) for
> ~20 minutes — a screensaver leak surfaces fast and Instruments pinpoints it better than a
> static read. Use this Fable prompt only if you want the code-level root-cause pass too.

---

```
You are running a FOCUSED STABILITY SWEEP of the NatureVsNoise macOS screensaver on Fable 5.
Repo: /Users/pro/Projects/Screensaver, branch main (verify with `git status -sb`, put the HEAD
SHA in your report header). READ-ONLY — audit + report only, no code/git/config changes, create
no file except the ONE report at docs/qa/<YYYY-MM-DD>-fable5-stability-audit.md. Run `ls`,
`date +%F`, and read the real source first — don't assume paths.

ONLY audit the canonical project: NatureVsNoise/. IGNORE NatureVsNoise-Cinematic/ and
MinimalTest/ (per CLAUDE.md — separate experiment + debug stub, not shipping). Read CLAUDE.md,
STATUS.md, TASKS.md, and the recent commits first (a 23GB memory leak was fixed in 5d502fa —
"stop per-frame SceneKit geometry churn in Metal mode"; resource churn is the known risk class,
hunt for siblings of it).

A screensaver runs UNATTENDED FOR HOURS and is started/stopped repeatedly by the System Settings
preview. The only failure modes that matter:

1. LONG-RUN RESOURCE STABILITY (highest) — hunt the leak/churn class the 23GB bug belonged to:
   - Per-frame allocation in the render/update loop: SceneKit geometry/material/node churn, Metal
     buffer/texture/pipeline re-creation that should be created once and reused.
   - Retain cycles (closures/delegates/timers capturing self strongly), unbounded growth
     (trail/history/telemetry arrays, caches, the HUD ticker) with no cap or eviction.
   - Timers, display links, KVO/NotificationCenter observers, and Combine subscriptions that are
     never invalidated/removed. Anything that grows without bound over a multi-hour run.

2. GPU / RENDER PATH — the Metal swarm (5000-point cap) + SceneKit hybrid:
   - Buffers/textures sized and allocated once, not per-frame; no runaway draw calls.
   - The 8K textures + NASA 3D models loaded once and released properly; no reload per cycle.
   - Metal device-loss / command-buffer error handling gaps.

3. OFFLINE / FETCH RESILIENCE — the CelesTrak TLE live-fetch (tens of thousands of sats):
   - Does fetch failure fall back cleanly to the 14 bundled offline sats?
   - Is the network call OFF the main thread, with a timeout? A screensaver that hangs on a
     network stall (slow/hung CelesTrak) is the worst case — verify it can't block or crash the
     saver, and can't hang the System Settings preview.
   - Is any fetched data parsed defensively (malformed/partial TLE → no crash)?

4. SCREENSAVER LIFECYCLE — startAnimation() / stopAnimation() / deinit actually tear EVERYTHING
   down (the preview starts/stops the saver repeatedly; a leak or un-torn-down resource per cycle
   compounds). SGP4 propagation numerically stable over long elapsed times (no drift/NaN after
   hours). No work continues after stopAnimation().

Output: docs/qa/<YYYY-MM-DD>-fable5-stability-audit.md
  1. Header — date, HEAD SHA, branch.
  2. Findings — numbered, each: SEVERITY-PREFIX title / file:line / What / Why it matters over a
     multi-hour run / Fix direction. Severity scale:
       LEAK-       unbounded memory/resource growth over time (the 23GB class).
       RENDER-     per-frame GPU/CPU waste or a render-path resource bug.
       RESILIENCE- offline/fetch/parse failure that can hang or crash the saver.
       LIFECYCLE-  start/stop/deinit doesn't fully tear down; per-cycle compounding.
       INFO-       observation, no action.
  3. Confirmed sound — what you verified is genuinely stable (esp. that the 23GB fix holds and
     has no siblings).
  4. Punch list — findings ordered by "what degrades a multi-hour session worst", one-line fix
     direction each.

Skip cosmetics, features, and App Store concerns entirely — this is STABILITY only. Every finding
cites file:line + a reproducer (or "needs Instruments to confirm: <what to watch>"). No fabricated
claims.
```
