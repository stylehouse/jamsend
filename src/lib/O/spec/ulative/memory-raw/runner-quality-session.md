---
name: runner-quality-session
description: "The 2026-07-02 quality pass on the runner machine — packet-batching (belief-queue flood fix), click-preempt dispatch, %friendly killed, needAC-via-CLI. Brief folded into Cluster_spec.md §3.9 (Runner_quality_handover.md deleted 2026-07-06)"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

Full continuation brief folded into **`Cluster_spec.md` §3.9** (the runner-machine quality section);
`Runner_quality_handover.md` was deleted 2026-07-06. The load-bearing fixes (all uncommitted,
`:9091`-verify OWED — restart dev server + reload editor+runner):

**1. The belief-queue flood (THE perf bomb → now a Peeroleum principle).** `Tribunal.g on_message` wrapped
EVERY inbound frame in `H.post_do` → `H.todo`, drained one-per-`ANSWER_CALLS_TICK_MS`(50ms) under the beliefs
mutex → death-spiral (editor hit **117 todos**; ghost-compile timed out BECAUSE the editor couldn't drain).
Fixed 3 ways: (a) `relay.ts` `control:log` → `sendControlTo('editor')` only, not every browser (needs dev-
server restart); (b) `Tribunal.g on_message` control frames INLINE, envelopes → `Lies_deliver_soon` — a
**PINNED-SPINE change** (LocalGen-compiled + re-pinned to `p2p/pinned_stable/Tribunal.go`; ghost-compile-first
now that the editor breathes); (c) `LiesLies Lies_deliver_soon` COALESCES — per-w batch, ONE `post_do` drains
all in one Atime pass (reuses `Peeroleum_deliver` in order). Shipped as coalesced post_do, NOT the first-class
`req:handle_inbound`/reqyoncile "out-of-time type" the owner sketched (zero req-machinery risk under the
spiral; upgrade later). Principle folded into `Peeroleum_handover.md` top.

**2. Click-preempt dispatch (clicks were getting LOST).** A new `become_book` Story_resets the runner mid-run,
so a burst of clicks starved each other (socklog: 8 become_books → 2 run_results). `Lies_dispatch_target`
`{exhausted}` used to HOLD; now a single interactive click **preempts** the sticky runner (`Lies_preempt_target`
→ aim/rungo_runner) via `Lies_send_become_book` — its Story_reset cancels the prior run. Owner: "so much
snappier!" StoryTimes keeps hold/parallel-acquire.

**3. needAC via CLI, self-narrating (editor untouched).** `runner_ask run` reads Credence (`bookNeedsAC` →
`wormhole/Credence/toc.snap`) → passes `needAC` so the runner secures AC pre-run even if you never read
Credence; `--watch` narrates 🎤/⏳WAITING/✓granted/⚠blocked(untried,~60s fail-fast). KEY: `Lies_become_book_drive`
opens the run record only AFTER AC lands, so "record appeared = granted". `probe` stays the explicit fleet
audio-capability check, NOT a run pre-flight (owner rejected pre-emptive probe).

**Also:** `%friendly` KILLED (data model + UI; Rundar shows prepub CSS-truncated ~6ch via `.rp-pub`); the
EncodingSplatter empty-snap guard (blank backing file → not_found in LiesPersist + LiesStore_read_waft);
`Clustation_self(w)` arg bug fixed (5 sites — was `undefined` everywhere, incl inside Lies_self); socklog gate
fixed (sockcap_count not URL) + swept + OFF; gen-cluster-identos.ts DELETED.

**LOOSE ENDS:** ⚠ **remoteWormhole backending NEVER TESTED** (built "pt1" — %Grant/Lies_grant_wormhole,
&disk=proxy, RemoteWormholeNav — but zero evidence exercised; highest-value unknown). ~~needAC dispatch-match~~
**BUILT 2026-07-03**: advertise carries `ac:1` (probes `top_House().c.musu_gat.AC_ready`) → snapped `%Runner,ac`
facet → `Lies_dispatch_target(w, needAC)` prefers ac-live above every favour tier (PREFER never require — a
fresh no-AC fleet must still dispatch + beg); held/swept runs re-read the board via `Lies_book_needac(w, book)`.
:9091-verify: MusuTune at a two-runner fleet, only one AC-granted → ▶ lands there. Per-runner run_phase
`from:<pub>` demux flagged ~4× still undone (single `w.c.run_phase` slot → Brink can't say WHICH runner needs
AC). `Swarm_doc.md` RENAMED → `Swarm_spec.md`.
