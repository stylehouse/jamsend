---
name: perf-cliffs-latent
description: "the 5 latent perf cliffs (Sounditron_todo.md §PERF SWEEP) — all documented-not-patched; #1 power_cells crash-class but gated behind big/dynamic Vyto; #2 ra_wanted no-reask FIXED (starve-retry)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Source doc: `src/lib/O/spec/Sounditron_todo.md` §"PERF/RELIABILITY SWEEP" (~lines 66-88). Five cliffs
 of the bin_read-O(N²) class were DOCUMENTED not blind-patched (each a hot-path change wanting live
  verify). The two the human called "already fixed" are the FLAVOR, not the five: bin_read concat
   ([[sigill-bin-read-nsquared]], FIXED via concat_chunks Housing.svelte.ts:15) + Audiolet spent-node
    leak (FIXED Sound.g:277).

1. **power_cells O(N²)/frame — CRASH-CLASS** (`src/lib/O/vyto_geometry.ts:38-60`, driven per-rAF by
    Vytui.svelte integrate_world→build_cells). N seeds × N walls, fresh Pt[] alloc per clip. GC-OOM/SIGILL
     class. **Only small N (~8-12 organs) saves it.** → **DO NOT enable big/dynamic Vyto (task #22) — it's
      the trigger, and Vyto display is the human's zone anyway** ([[vyto-refactor-avoid-display]]).
2. **ra_wanted unbounded + no-reask** (`Ghost/M/Ra.g` set :782/:1637/:1692, read as CULL-PROTECTION
    :846-855). Two bugs: (a) no-reask correctness hole = a lost live-window want starved the playhead
     forever → **FIXED 2026-07-28**: Swarm_share_beat full-length leg now re-asks a still-missing
      live-window page every 4s via a NEW `w.c.ra_want_ts` stamp map beside the once-cursor (both cleared
       on rebirth reset Swarm.g:742). Safe vs Ra_stage: :851 only reads wanted[key] for map[off]==null
        (still-missing) offsets, so a landed/evicted key never affects staging. (b) unbounded growth
         leak = STILL LATENT (small/session-scoped; evict-on-land is provably safe but skipped tonight
          to avoid a blind core-wire change). See [[radio-friend-exclusive]].
3. **Repli_merge census re-walk O(catalog²)** (`Ghost/N/Repli.g:184/:198` Ra_rec_find → Ra_recs_deep
    Ra.g:682 double child-scan per node, per inbound fragment). Streaming throughput drag, worsens as the
     listener's mirror grows. Fix = memoize id→rec on mirror.c, invalidate on add/drop. LATENT.
4. **all_rows walked twice + rowByTok rebuilt twice/frame** (Vytui.svelte:262-263 then build_cells :192).
    O(N) redundancy, compounds #1. Fix = build once, pass in. LATENT (Vyto = human's zone).
5. **Radio_map rebuild per pump** (`Ghost/M/Radio.g` ~:1435, per 400ms Radio_pump). O(T) realloc/tick;
    doc itself rates "not a cliff". Cache on rec.c, invalidate on chunk land. LATENT, lowest.

Bottom line for a long production session: none is a hard blocker at small N. #2-leak + #3 touch the
 shipped radio path (throughput/slow-leak, not crash). #1 is the only crash-class and is GATED — keep
  big Vyto off. Everything ELSE swept clean (no .push(...spread) hot loops; JSON.stringify only on
   encode/wire; other .c accumulators keyed by pier/channel = bounded).
