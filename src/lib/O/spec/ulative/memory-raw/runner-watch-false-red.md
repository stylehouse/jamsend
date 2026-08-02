---
name: runner-watch-false-red
description: runner_ask --watch USED to declare RED after ONE 8s state-poll timeout while busy — FIXED 2026-07-05 (shared runner_liveness.mjs; tolerates silence to DEAD_MS=20s + resets on progress). Operational advice (never HMR mid-run, engaged-wedge recovery) still holds
metadata: 
  node_type: memory
  type: project
  originSessionId: f4eec47c-5092-4a7d-a304-39f88375f249
---

**FIXED 2026-07-05 (working tree, :9091-unverified):** the 8s bail is gone. `runner_ask.mjs` now imports the shared thresholds (`src/lib/O/runner_liveness.mjs` — the ONE home, also read by the ghost's reaper `Lies_runner_roster` + rack `Rundar` + keepalive `Lies_keepalive`), raises the per-poll timeout above SLUGGISH (9s), and the `--watch` loop only calls RED when the shared `liveness()` verdict is `dead` — i.e. DEAD_MS=20s of accumulated silence AND no forward progress (a run stepping resets the death-clock). The historical trap below is the WHY the fix exists; the operational rules (never HMR mid-run; the engaged-wedge recovery ladder) still stand regardless.

Historically: `scripts/runner_ask.mjs run <Book> --watch` treated a single "state: no reply in 8s" as run-went-RED and stopped watching. But the flock Chrome goes >8s unresponsive mid-run on heavy stretches (Peeroleum-spine Books especially), then recovers — PereStaple "went RED" this way and finished done 22/22; a MusuReplica "death" was the same illusion.

**Why:** a watch RED is not evidence the run failed — only that one poll timed out; acting on it (re-dispatching, editing, HMR-ing) can kill a run that was still going. A mid-run vite HMR/full-reload of a .svelte ghost DOES kill the run for real (the flock bot rebuilds the session, held rungos are wiped, the tab re-becomes its boot Book).

**How to apply:** after a watch RED, wait ~20s then `runner_ask.mjs state` / `rungos` — if the run is stepping or done/held, it survived. Never save an edit (HMR) while a run is in flight. Consider raising the watch timeout or retrying the poll in runner_ask if this keeps biting.

**Engaged rapid-redispatch wedge (2026-07-04, MusuReco accept flow):** dispatching a run ~5s after `accept`
 (the accept is async), then superseding the wedged run with more dispatches, left the ENGAGED tab wedging
  EVERY Book mid-stepping (even a proven one crawled at n:3 for minutes) — looked like tab-broken/reload
   territory. It wasn't: `runner_ask.mjs release` → the tab's self-driving rotation resumed and ran green
    14/14 on its own, and a fresh engaged dispatch then verified green 11/11. **Recovery ladder: release
     the engagement and wait a minute BEFORE reaching for the human tab reload.** And leave a beat (~15s+)
      between accept and the verification re-run.
