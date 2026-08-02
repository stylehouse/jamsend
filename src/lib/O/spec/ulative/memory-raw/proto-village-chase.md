---
name: proto-village-chase
description: "MusuRaChase proto-Village Book DONE: 56/56 green ×2, 15 %see, audit upgrades (src/cands/fanout_dark) in fixtures + sabotage-proven; owed = keep_ahead pin + mid-run revoke"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5208f8a1-b006-4307-96b3-31bdbb777ccb
---

2026-07-11: the proto-VILLAGE session (built on [[musurastream-real-streaming]]).

**Engines (all compiled via LocalGen; legacy Books re-ran green first):**
- Repli.g multi-caster: `Repli_register_caster(w,pier,lib)` / `Repli_register_rx(w,pier)` +
  `Repli_src_for`/`Repli_rx_ok`; `w.c.tx/rx` stays the legacy default. Consent hook is now
  `w.c.repli_allow(peer, at)` — `at` = serving prepub. Mirror %Records get `.c.from`/`.c.rx`
  breadcrumbs at recv (runtime-only).
- Ra.g: `Ra_seed/Ra_entropy/Ra_rand` (per-w PRNG: crypto-lazy live, Book-pinnable, stir-injectable);
  `Ra_keep_ahead(w)` + `Ra_restock_beat(w,mirror,budget)` (KEEP_AHEAD fan-out, clamped to preview —
  never ignites transcode); `Ra_dial_next(w,mirror,{id|skip_src})` — the dial, gated by
  `w.c.ra_source_live` presence hook (grants+carriers; also gates the fan-out); `Ra_stock` grew a
  `from` offset; `Ra_transcode_pump` serves every registered caster.
- radiostock pub = PREPUB always; MusuRaStock/MusuRaTerm re-recorded green on deterministic
  identity shelf keys ('DJ'/'raterm.player' literals swept by the one-time migration).

**Verification scoreboard:** Chase 56/56 ≈54 (green ×2 + post-revert green), Cast 12/12 ≈9,
Stream 40/40 ≈37, Stock 5/5 ≈2, Term 12/12 ≈0, Replica 14/14 ≈10, Reco 11/11 ≈3 — ALL green.

**Audit upgrades LANDED 2026-07-11 eve (fixtures committed in `e2bef100 tests`):** `src`+`cands`
on the chased AND skip rows (`chased,…,src:Duo,cands=2` — kills both PRNG-luck slip channels;
cands reads runtime-only `w.c.ra_dial_cands`), post-dark `fanout_dark,of,warm` row (of=1).
**Sabotage-proven:** deleting the `ra_source_live` gate in Ra_restock_beat → RED from step 20
(ok_pct 0.34, live `fanout_dark,of=3` vs pinned of=1; the untouched dial gate's `skip:B,…,src:Duo`
still matched — the kill is surgically the restock's), green again on revert.

**Still OWED:** the `keep_ahead=2` pin (belongs in a SINGLE-SOURCE Book — with a 3-candidate
catalog it falsifies the "kept EVERY other preview warm" sentence) and a mid-run revoke variant so
`repli_allow` refuses at least once in-Book.
**Term re-record lesson:** record from the STANDING-stock state, not the build run — the build run's
beats 2-5 differ (accept once, re-run, accept the standing run if red).
