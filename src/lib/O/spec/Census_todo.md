# Census — the foggy map of the collection

The census is the lazy map the shuffle draws over: `{audio, open, subs, z, n}` per directory, learned one
 `expand()` per hop by `Crate_nav_meander` (Ghost/M/Crate.g), kept on `top_House().c.meander_learn`, saved
  as `%Dirtally,of:<path>` rows in the Berth Waft `<root>/.jamsend/berth/Census` by `Census.svelte`. Pure
   merge/evict/select/restore live in `census_codec.ts`. Live pages only (`humdinger`); Books never see it.

**The arc.** Shuffle the whole collection fairly without ever listing all of it: walk at random, remember
 what each walk saw, use the memory to aim later walks, and price the unseen part (the fog) honestly.
  Done looks like: every track about equally likely to come up, from the first press on a warm page, with
   the map readable by a person and not just by the code.

## 0. What to do next

**Landed 2026-10-04 (owner-reported as the "tiny place, huge berth" mess) — needs a live look:**
- **Berth: small documents don't append** (`Berth_append`, Heist.g). Before this, a 2-folder share had 63
   one-line Census parts and Newlyadded had one part per track of a 7-track album. Now a delta that brings
    the rows held in parts to ≥¼ of the base rewrites `toc.snap` instead, which also unlinks the old tail.
     Big documents still append. Covers Census, Newlyadded and KeepMemo. MusuBerth passed 7/7 with caveat 0.
      MusuHeist was ok_pct 1 with 17 caveats: unattributed (no baseline run), but no MusuHeist snap holds a
       Berth line.
- **`open` is no longer structural** (Census.svelte `moved_key`). It flips whenever a track shelves, so it
   now goes through the same 5%/4-unit drift gate as z|n. That was the `open:0`/`open:1` part per minute.
- **`t` is persisted** (was item 1), and re-lands monthly so a folder in regular use doesn't age out after
   a reload. Rows without `t` get today's date and one rewrite.
- **Unreachable spellings are pruned at restore** (was item 2): keys whose first segment isn't a directory
   at the share root are dropped and the census is rewritten once. An empty or failed root listing prunes
    nothing. `Census_diag().pruned` shows the count.
- **Dexie leftovers deleted** (was item 4): census_store.ts, encode/decode, CENSUS_FORMAT/MAX_BYTES.

**To verify live:** on the owner's Nopethings share, the first save should leave `berth/Census` as a single
 `toc.snap` (no NNN parts), and the next album landing should leave Newlyadded the same way.

3. **Price the fog by depth.** Unvisited folders all get one global PRIOR = mean subtree size of a random
    folder, about **24.8** on the real census. Real subtree sizes fall steeply with depth: depth 1 ≈ 646,
     2 ≈ 30, 3 ≈ 13, 4 ≈ 11, 5 ≈ 5. So an unseen genre leg is priced at 25 when it holds about 650, and an
      unseen album is priced at about 2× its size. That second case is the common one: 2953 of the 5736
       rows are stubs. Leave-one-out over the 2782 visited folders, mean absolute error:
        global prior 27.1, **depth prior 21.1**, depth prior plus sibling shrink 20.3. The counters are
         already there: bucket `meander_stat` by depth (`dirs/audio` per level, shrunk to the global value),
          then `est()` returns `PRIOR[depth]` for an unseen key. The sibling term adds little, so skip it at
           first. **Gate:** prediction error is not the shuffle metric. Before landing, re-run the
            coverage/KL/dry-tour simulation the Crate.g comments quote, using this real census as the
             shape. The real tree beats the synthetic ones we measured against before.
4. **Delete the Dexie leftovers.** `census_store.ts` has no importers. `census_encode/decode/pack`,
    `CENSUS_FORMAT` and `CENSUS_MAX_BYTES` are unused since the Berth move. The codec header still
     describes Dexie, and its "the ceiling that still binds is CENSUS_MAX_BYTES" line is false because
      nothing enforces that ceiling. Keep the pure merge/evict/select/restore functions and rewrite the
       header around the Berth.
5. **Make it legible.** `Census_diag`, `Census_flush` and `Census_forget` have no callers. The map is the
    only state in this area nobody can see, which goes against the one bet. Smallest useful step: a
     `runner_ask --player=<pub> census` op that returns `Census_diag()` plus a per-top-level-folder line
      (known tracks, unvisited folders, the share of recent draws that went there). The last column answers
       "is it random enough" in numbers instead of by feel. Later, a face could show the same rows.

**Measure before acting on.** The supervisor comment in Radio.g (≈1964) recorded a warm restore landing
 1465 folders at t+49s (2026-08-13). The Berth open reads the toc plus up to 64 parts in series and
  deWafts everything into C particles. The census is now 5736 rows / 519 KB plus 57 parts. Nobody has
   timed it since. Time it on a live player before changing anything; it may have been the disk queue
    that was later fixed per path.

## 1. What the real census looks like (`/music/.jamsend/berth/Census`, last write 2026-08-28)

- 5736 rows: 2783 visited, 2953 stubs (fog), 1924 folders holding music, 22601 tracks counted
   (including the double-counted 2990 from item 2), 100 confirmed barren (z≥2).
- Depth of visited folders: d1 36, d2 746, d3 1313, d4 507, d5 167, d6 13, d7 1.
- The biggest unseen areas: `0 themes/Music Rough Guides` has 12 visited children and 199 stubs; `0 Jazz`
   has 104 visited and 94 stubs; `0 folk` has 14 visited and 88 stubs.
- 703 of the rows are JSON-form lines (paths containing commas or quotes). They round-trip fine.
- The analysis script is in the session scratchpad. It's small: parse the toc, build subtrees from key
   prefixes, run leave-one-out per prior. Rebuild it from this description if needed.
- This copy is 5 weeks old. The owner's live tab may keep its census under a different root.

## 2. Ruled already, don't relitigate

- Persisted as a Berth Waft, not Dexie/stash (owner, 2026-08-08: "you can't just make up formats").
- `seen`, `p/q/pk` stay transient (census_codec.ts header has the reasons).
- Restored `z` is capped at 1: a restored barren folder needs one live confirmation before `dead()`
   prunes it.
- The materiality gate (5% / 4 units) on z|n drift stays (2026-08-21 churn fix).
