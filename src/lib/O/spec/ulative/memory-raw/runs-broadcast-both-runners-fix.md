---
name: runs-broadcast-both-runners-fix
description: "the 'Rungos/become_book going to BOTH runners (to:runner)' regression — root = advertise gated on Clustation_self; FIXED + live-verified 2026-07-01"
metadata:
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

The "runs going to BOTH runners simultaneously / become_book with to:runner" regression. FIXED + **live-verified** 2026-07-01 (socklog showed the HMR transition: `↑ to:runner rungo` → `↑ to:<pub> rungo` sticking to one runner).

**Root cause** = one divergence: `Lies_advertise` gated WHO-we-are on `Clustation_self` (the `?I=` %Identity), which is **null for a runner booted `?B=` with only a stashed/env cluster key** (no `?I=`). Such a runner hello-binds + is fully addressable by `to:<pub>`, but never advertised → editor's `%Runner` roster stayed empty → `Lies_dispatch_target` returned `{}` → become_book **broadcast** to addr `runner` (every runner-bound socket). The runner ping reported `self:null, advertising:false` while being live — the tell.

**Fixes (all app-level, HMR-live, no spine re-pin):**
- `Lies_advertise` (LiesLies) WHO-we-are now `Lies_self` not `Clustation_self` — Lies_self falls back to `prepubOf(cluster_idento.pub)` = the EXACT hello-bind prepub. So stashed/env-key runners advertise their addressable pub. THE root fix.
- `Lies_send_rungo` now INDIVIDUATES too (was always `Peeroleum_send_consumer` broadcast). A rungo FIRES the run (`req_rungo`→`Lies_drive_run` off the demand path), and all runners share /app+HMR, so a broadcast rungo made ALL fire — the real double-run carrier for compile-driven runs. New `Lies_rungo_target` = STICKY (aim ▸ sticky `w.c.rungo_runner` ▸ deterministic latest-in-directory); `Peeroleum_send_to` (returns per-Pier seq, authority preserved). become_book sets `w.c.rungo_runner=to` so rungo follows the started-on runner.
- **HOLD, don't broadcast, when no LIVE runner (the real residual bug the watcher caught):** broadcasting to an UNPOPULATED roster sprays all runners — and the roster IS empty for ~1s after a reconnect (channel up, advertise arrived but not yet folded in-think into `r.c.last_heard`). `Lies_send_rungo` now HOLDS `w.c.pending_rungo` + `Lies_drain_rungo` ships it the instant the roster folds (hooked in `Lies_runner_roster` + heartbeat; drops after 60s, surfaced). `e_Lies_become_book` + `Lies_storytimes_dispatch` HOLD (`Lies_queue_run`) when runners are KNOWN but none live; broadcast ONLY when ZERO runners known (a lone/keyless/unregistered runner). VERIFIED: watcher 12/12 over ~9min spanning ~3 reconnect cycles = 0 broadcasts.
- ping carries `from:Lies_self.prepub`; editor `Lies_pong` refreshes that runner's `w.c.beacons[from].last_heard` (merge-safe, off-think) — liveness rides the 5s heartbeat, not only the 15s advertise. No 15s beacon was even visible in the socket log; ping/pong (5s, two-way) is the real heartbeat.
- become_book broadcast is now SURFACED (`Lies_relay_note` with live/known counts) — never silent.
- runner_ask `ping` diag `self`/`advertising` now read `Lies_self` (were `Clustation_self` → the misleading `self:null`); added `clustation_self` to spot a divergence.

KNOWN benign edge: a one-time seq-space jump (broadcast consumer-seq → per-Pier seq) at the individuation switch can transient-double-fire on the ONE runner; self-heals on reload. Steady state (always individuated from seq=1) is clean.

**Scaffold to REMOVE once confirmed** (see [[socklog-scaffold]]): `src/lib/O/sockcap.ts` + Otro `&watch=3` auto-reload + `Lies_dump_socklog`. Feeds [[runner-fleet-goal]]; the remaining §5 items (Cluster_runner_handover.md) = from:<pub> on run_phase/run_result demux, Pier culling, demote advertise.

**2026-07-07 CLI residue found + fixed:** the EDITOR path was fixed, but `scripts/runner_ask.mjs` (and story_repl.mjs) still DEFAULTED to `to:'runner'` — the relay fanned a CLI `run` to every runner tab (owner watched VoroMitosis land on BOTH; each tab minted its own uid, and state/steps polls flip-flopped between whichever tab acked first). Fix: **auto-court** — no `--runner=` ⇒ one broadcast ping, collect EVERY ack (self+engagement) over a 900ms grace, pick STICKY (`/tmp/runner_ask.target`, direct-pinged — a role broadcast reaches ONE arbitrary socket so it can't find a *specific* runner) ▸ our-lease ▸ free-for-run ▸ first; the real ask always rides `to:<prepub>` and the pick re-stashes. story_repl courts once at connect. Verified: run on one tab, other untouched, follow-up steps court back via sticky.
