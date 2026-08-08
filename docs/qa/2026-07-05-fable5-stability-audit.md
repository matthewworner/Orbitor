# NatureVsNoise — Fable 5 Focused Stability Sweep

- **Date:** 2026-07-05
- **HEAD:** `013fba4` ("Docs: record 23GB memory leak, fix, and remaining work")
- **Branch:** `astra-hud-redesign` (ahead of origin by 5) — **NOTE: the prompt specified `main`; this is the actual checked-out HEAD, audited as-is.**
- **Scope:** `NatureVsNoise/` only (canonical, per CLAUDE.md). Read-only sweep: long-run resource stability, GPU/render path, offline/fetch resilience, screensaver lifecycle.

---

## Findings

### 1. LIFECYCLE- `startAnimation()` never undoes what `stopAnimation()` tears down — saver is dead after a stop/start cycle
- **File:** `NatureVsNoise/NatureVsNoise/Sources/NatureVsNoiseView.swift:138-151`
- **What:** `stopAnimation()` sets `sceneView.isPlaying = false`, nils `sceneView.delegate`, and stops the HUD update timer. `startAnimation()` is `super.startAnimation()` only — it restores none of the three.
- **Why it matters:** The System Settings preview (and the wallpaper host) starts/stops the saver repeatedly. If the same view instance is restarted: no delegate → `renderer(_:updateAtTime:)` and `willRenderScene` never fire → no satellite updates and **no Metal swarm draw at all**; `isPlaying == false` → SceneKit stops ticking; HUD clock/panels frozen (timer never restarted). The saver appears as a frozen frame or black satellite-less Earth for the entire session.
- **Reproducer:** In System Settings, open the preview, close it, reopen it (same process, view reuse). Or programmatically call `stopAnimation()` then `startAnimation()` and observe `sceneView.delegate == nil`.
- **Fix direction:** Mirror the teardown in `startAnimation()`: `sceneView?.delegate = self; sceneView?.isPlaying = true; hudOverlay?.startUpdateTimer()` (make `startUpdateTimer` public/idempotent).

### 2. LEAK- SceneKit fallback still churns per-tick geometry — a live sibling of the 23GB bug
- **File:** `NatureVsNoise/NatureVsNoise/Sources/Satellites/SatelliteRenderer.swift:371-404` (driven from `NatureVsNoiseView.swift:703-749`)
- **What:** `updateTrailNode` builds a **new** `SCNGeometrySource`, `SCNGeometryElement`, `SCNGeometry`, and `SCNMaterial` for every visible satellite on every update tick (`node.geometry = nil` then reassign). At 50 nodes × up to 30 ticks/s that is ~1,500 GPU-backed geometry+material allocations per second, indefinitely.
- **Why it matters:** This is exactly the allocation class of the fixed 23GB leak (5d502fa): per-frame SceneKit geometry churn that the wallpaper host reclaims slowly or never. The fix commit removed the *call* from the Metal path but did not fix the churn itself — the fallback path (Metal unavailable, `enableSwarm` off, or pipeline creation failure) runs it for hours. The in-code comment at `NatureVsNoiseView.swift:852-855` even claims the fallback is "fixed separately by reusing geometry instead of rebuilding it" — the reuse was never implemented.
- **Reproducer:** Disable "Satellite Swarm (Metal)" in the configure sheet, run the saver; needs Instruments to confirm: Allocations track of `SCNGeometry`/`C3D*` objects climbing during a 20-min run.
- **Fix direction:** Reuse one mutable geometry per trail (update vertex buffer via `SCNGeometrySource` backed by a shared `MTLBuffer`, or simply rebuild at most every N seconds), and share a single static trail `SCNMaterial`.

### 3. LEAK-/RESILIENCE- hourly TLE refresh mutates `satellites` from a background task while the render thread reads it
- **File:** `NatureVsNoise/NatureVsNoise/Sources/Satellites/SatelliteManager.swift:176-201, 364-369`
- **What:** `fetchFreshTLEData()` runs in a detached `Task` (arbitrary executor) and calls `parseTLEData`, which does `satellites.removeAll()` then appends tens of thousands of entries. Concurrently, SceneKit's render thread iterates `satelliteManager.satellites` (`NatureVsNoiseView.swift:683, 719`) and the HUD reads `census`. `satellites` is a plain `var [Satellite]` with no synchronization; the hourly `Timer` (`startUpdateScheduler`) re-triggers this every 3,600 s for the life of the saver.
- **Why it matters:** A data race on a Swift `Array` being emptied/regrown while read is undefined behavior — over a multi-hour unattended run, each hourly fetch is a fresh roll of the dice for an out-of-bounds read or heap corruption crash inside the wallpaper host. It doesn't need to be likely per-event; the saver gives it hundreds of chances.
- **Reproducer:** Needs Instruments/TSan to confirm: run with Thread Sanitizer, force a fetch (`clearCache()` + relaunch) while animating.
- **Fix direction:** Parse into a local array, then assign to `satellites` on the main queue (`DispatchQueue.main.async { self.satellites = parsed }`), and read it only from main/render callbacks. Also cap `TLEFetcher.lastFetchStatistics` (`TLEFetcher.swift:191`) — it appends ~7 entries per hourly fetch forever (tiny, but unbounded).

### 4. RESILIENCE- disabling "Hero Satellites" in settings crashes setup on next launch
- **File:** `NatureVsNoise/NatureVsNoise/Sources/NatureVsNoiseView.swift:344-368`
- **What:** `setupRenderers()` only creates `satelliteRenderer` when `FeatureFlags.enableToySats` is true, then unconditionally calls `configureQualitySettings()`, which calls `satelliteRenderer.setQualityLevel(...)` on an implicitly-unwrapped optional in every switch branch.
- **Why it matters:** The configure sheet exposes a "Hero Satellites (3D models)" toggle (`SettingsController.swift:127, 176`). Toggle it off → next saver launch force-unwraps nil → crash inside the wallpaper host during `setupScene()`. A settings-induced hard crash on every start is the worst resilience failure available.
- **Reproducer:** Configure sheet → uncheck "Hero Satellites (3D models)" → restart the saver.
- **Fix direction:** `satelliteRenderer?.setQualityLevel(...)` (one-character fix per branch), or create the renderer unconditionally.

### 5. RENDER- SceneKit fallback constructs a full SGP4 propagator per satellite per tick
- **File:** `NatureVsNoise/NatureVsNoise/Sources/Satellites/SatelliteManager.swift:381-403` (called from `NatureVsNoiseView.swift:722`)
- **What:** `getPositionAndVelocity` allocates a new `OrbitalElements` + `SGP4Propagator` (whose init runs the entire SGP4 initialization math) for every satellite on every update tick. In the SceneKit fallback that's up to `maxSatellites` × up to 30 Hz.
- **Why it matters:** Pure per-frame CPU/allocation waste — sustained heap churn and CPU burn for hours (heat, energy, GC-pressure in the host). Metal mode is unaffected (GPU propagates).
- **Fix direction:** Cache one `SGP4Propagator` per satellite (built once when the catalog changes) and only call `propagate(minutesSinceEpoch:)` per tick.

### 6. LIFECYCLE- hourly network fetch keeps running after `stopAnimation()`
- **File:** `NatureVsNoise/NatureVsNoise/Sources/Satellites/SatelliteManager.swift:364-369`, `NatureVsNoiseView.swift:142-151`
- **What:** `SatelliteManager`'s hourly refresh `Timer` is only invalidated in `deinit`. `stopAnimation()` doesn't release the manager, so as long as the host retains the view, CelesTrak fetches (7 endpoints, up to tens of MB) continue on schedule while the saver is "stopped".
- **Why it matters:** Per-cycle compounding is avoided (weak self, single timer), but it's background network + parse work the user believes is off; combined with Finding 3 it also races while nothing is rendering.
- **Fix direction:** Pause/resume the timer from `stopAnimation()`/`startAnimation()`.

### 7. INFO- fresh TLE data is never re-uploaded to the GPU
- **File:** `NatureVsNoise/NatureVsNoise/Sources/NatureVsNoiseView.swift:680-690`
- **What:** The Metal upload is gated on `animationTime == 0`, which is only true on the very first tick. The async fetch (and every hourly refresh) replaces `satellites` afterwards, but `uploadSatellites` never runs again — the swarm renders launch-time (cache or bundled-14) data forever.
- **Why it matters:** Not a stability risk (buffers are fixed-size, upload clamps to `maxSatellites`), but note: on a cold cache the swarm shows **14** satellites for the whole session, and the HUD census (live data) won't match the rendered swarm.
- **Fix direction:** Re-upload (on main/render thread) when the catalog changes, e.g. a `catalogGeneration` counter checked in `addSatellitesMetal`.

### 8. INFO- diagnostic log file grows without rotation
- **File:** `NatureVsNoise/NatureVsNoise/Sources/NatureVsNoiseView.swift:156-168`
- **What:** `logToFile` appends to `~/Library/Logs/NatureVsNoise.log` forever, opening a fresh `FileHandle` per line. Writes are event-driven (not per-frame), so growth is slow — but unbounded across months.
- **Fix direction:** Truncate at startup or cap at a few hundred KB. Low priority.

---

## Confirmed sound

- **The 23GB fix holds in Metal mode.** `addSatellitesMetal` uploads orbital elements once and only dispatches the GPU propagation kernel per tick (`NatureVsNoiseView.swift:677-700`); the SceneKit trail renderer is never touched on that path. The double-encode-per-frame bug is also gone — the swarm is drawn once, in `willRenderScene`. Its one live sibling is the fallback path (Finding 2).
- **Metal buffers are allocated once and reused.** All six buffers are created up-front in `setupBuffers()` sized to `maxSatellites` (5,000 cap); `uploadSatellites` clamps `satelliteCount = min(count, maxSatellites)`; per-frame work is two `memcpy`s into pre-allocated uniform buffers and two draw calls (`MetalSatelliteRenderer.swift:213-230, 402-450`). Trail draws are capped (`maxTrailInstances = 1000`). No per-frame pipeline or buffer creation anywhere.
- **Metal init failure degrades, doesn't crash.** Missing device/queue/pipelines all fall through to SceneKit-only mode with logging (`MetalSatelliteRenderer.swift:97-123, 283-295`); `render(into:)` guards on encoder, pipeline, buffers, and `satelliteCount > 0`.
- **Offline/fetch resilience is genuinely good.** The fetch is fully async off the main thread with 30 s request / 120 s resource timeouts (`TLEFetcher.swift:85-89`); a hung or offline CelesTrak cannot block setup or the render loop — the saver starts immediately from cache or the bundled TLEs and the fetch fails silently in the background. TLE parsing is defensive: length guards, `1 `/`2 ` prefix checks, mod-10 checksum validation, catalog-number cross-check, and per-field `guard let` numeric parsing that drops malformed entries instead of crashing (`TLEFetcher.swift:230-285`, `SatelliteManager.swift:258-292`).
- **SGP4 is numerically guarded for long runs.** Eccentricity bounds return typed errors instead of propagating garbage (`SGP4Propagator.swift:398-403`), negative semi-latus rectum is caught (`:458-460`), and the Kepler solver is iteration-capped (10) with a step clamp (`:435-448`) — no unbounded loop or obvious NaN source after hours of accelerated time. (Positions of error-cases come back as `.zero`, which renders a dot at Earth's center — cosmetic, out of scope.)
- **HUD is bounded.** All HUD nodes are created once in `setupUI`; the 0.5 s update timer only mutates label text; the ambient ticker rotates over fixed arrays (no history accumulation); the boot overlay removes itself; `stopUpdateTimer()` and `deinit` invalidate the timers (`HUDOverlay.swift:439-448`, `FactOverlay.swift:163-209`). Trail history in the SceneKit renderer is capped at 10 positions per satellite. The per-frame `updateTarget → showSatellite` call only fires when a planet name matches the notable-satellite database, which is effectively never — no per-frame SKAction spam observed in code.
- **No retain cycles found.** All closures capturing the view/HUD use `[weak self]`; `SatelliteRenderer.scene` and `MetalSatelliteRenderer.cameraNode` are `weak`; `stopAnimation` additionally nils the SCNView delegate. The declared-but-unused `displayLink` (`NatureVsNoiseView.swift:44`) is dead code, not a leak.

---

## Punch list (worst multi-hour degradation first)

1. **Finding 4 (RESILIENCE- settings crash):** change `satelliteRenderer.` to `satelliteRenderer?.` in `configureQualitySettings` — hard crash, one-line fix.
2. **Finding 1 (LIFECYCLE- dead after restart):** restore delegate/`isPlaying`/HUD timer in `startAnimation()` — the preview stop/start case is the saver's front door.
3. **Finding 3 (LEAK-/race hourly refetch):** marshal `parseTLEData` results onto the main thread before assigning `satellites`; cap `lastFetchStatistics`.
4. **Finding 2 (LEAK- fallback trail churn):** reuse trail geometry/material instead of rebuilding per tick — this is the 23GB class, still live on the fallback path.
5. **Finding 5 (RENDER- per-tick SGP4 alloc):** cache one propagator per satellite.
6. **Finding 6 (LIFECYCLE- fetch timer):** pause the hourly timer in `stopAnimation()`.
7. **Findings 7–8 (INFO):** re-upload swarm on catalog change; rotate the log file.
