---
name: needsfsa-dispatch-gate
description: needsFSA = a Book capability flag (twin of needAC) routing disk-heavy/timing-sensitive Books to a LOCAL-FSA runner and REFUSING them on a remoteWormhole-proxy runner (each proxy read/write crosses a belief-loop beat → per-beat Books overrun budget)
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d992ead-6ef2-4f82-85d7-85669ab9454f
---

**`needsFSA`** is a Book capability flag added 2026-07-05, a faithful mirror of **`needAC`** (the AudioContext gate). WHY: the remoteWormhole proxy is a deliberate hack — each `bin_read`/`bin_write` crosses a belief-loop beat (`atime_async`, reply delivered BY the loop), so a per-beat disk Book (MusuGenerateTestsMusic's 8 writes, MusuCrate's one-read-per-beat rastock) overruns its `expecting()` budget. The fix (owner's call): run those Books on a runner with a real **local FSA share** (fast disk); the flock does abstract/slow tests over the proxy.

**The capability** = `Lies_has_fsa(w)` = `!!(top.o({A:'Wormhole'})[0].c.DL)` — a granted FSA DirectoryHandle (WormholeNav(DL)), NOT the RemoteWormholeNav proxy (is_remote) and not absent.

**The full mirror (~17 sites, 4 files, all parse-clean, :9091-UNVERIFIED):**
- DECLARE: `Funkcion:Storying,of_Book:<Book>,needsFSA:1` in `wormhole/Credence/toc.snap` (hand-authored board; NOT YET added to any Book — that's the next step). Reader = `Lies_book_needsfsa` (LiesFunk, twin of `Lies_book_needac`/`needmusic`).
- ADVERTISE: a runner beacons `fsa:1` when it has a local share (`Lies_advertise` fsa_now + sig; `Lies_advertise_recv` fsa; roster projection sets `r.sc.fsa`) — LiesLies.
- ROUTE: `Lies_dispatch_target(w, needAC, needsFSA)` — tier penalty `+8` for a non-fsa runner when needsFSA (outranks needAC's +4; bestTier ceiling raised 9→99) — LiesLies.
- GATE: `Lies_become_book_drive(w, book, needAC, needsFSA)` — FIRST check: `needsFSA && !Lies_has_fsa` → `fsa_blocked` phase, refuse cleanly (nothing tried), so the authority re-routes — LiesFunk.
- CARRY: `Lies_send_become_book(…, needsFSA)` (a `caps` obj), `become_book_recv`, `e_Lies_become_book`, `Lies_storytimes_dispatch`, `Lies_drain_runs`, the runner_ask handler + result; `Storying.svelte` strike(); `scripts/runner_ask.mjs` `bookNeedsFSA` + `run` carry + a 📁 surface line.

**DONE 2026-07-05:** `needsFSA:1` declared on **MusuGenerateTestsMusic** in `wormhole/Credence/toc.snap` (only that Book — owner: "see if it matters" for the other Musu* on a non-FSA runner before flagging them). **MusuCrate DELETED everywhere** (redundant + timing-fragile — its witnessed claims were a subset of MusuReco+MusuGlide): the crate region in `Musuation.g` + the sole-caller `Crate_rastock_*` helpers in `Crate.g` + `wormhole/Story/MusuCrate/` fixtures + the Credence cell + the Ality-Waft `What:MusuCrate` block + code comments; gen regenerated MusuCrate-free via LocalGen (compiles clean). **STILL :9091-UNVERIFIED** — verifying the routing needs both an FSA-share runner (takes it) and a proxy-only runner (refuses, `fsa_blocked`) live. Ties to [[always-register-book-in-credence]] (Credence is hand-authored).
