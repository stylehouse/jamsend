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

- **The fog is priced by depth** (was item 3; Crate.g `Crate_depth_fold` + the PD table in
   `Crate_nav_meander`). Per depth d: visited dirs V, audio A, child count C. Solve S_d = A/V + (C/V)·S_{d+1}
    from the deepest level up, then shrink toward the global PRIOR with 8 pseudo-dirs. A branching-process
     estimate, so unvisited children count. The simulation (meander ported to node, 5 seeds) measured KL of
      picks-per-top-level against the true track share. Real tree, cold start: 0.634 → 0.151 at 200 tours,
       0.278 → 0.052 at 800. Warm: 0.259 → 0.050. Synthetic: 0.829 → 0.031. Coverage didn't change. Cost:
        synthetic dry tours went from 2–3% to 4–5%; real tree unchanged. Live pages only; Books are
         untouched (MusuStock ok_pct 1; its 5 caveats are not attributable to this, since a runner is
          not humdinger).
- **`runner_ask census`** (was item 5): `node scripts/runner_ask.mjs census --player=<pub>` prints
   `Census_diag` (now with `restore_ms` and `pruned`), the depth-prior table, and one row per top-level
    folder: known · dirs · fog · est · est% · picks · pick%. **est% vs pick% is the "random enough" check.**
     `picks` counts from page boot (`meander_picks_top`, .c-only).

**To verify live (owner):**
1. Nopethings share: after the first census save, `berth/Census` is a single `toc.snap` with the 63 parts
    gone. After the next album lands, Newlyadded is the same.
2. `runner_ask census --player=<pub>` on a music tab: `restore_ms` answers the old 49 s question,
    `pruned` should be ~2100 on the big /music share (the `music/…` spelling), and after a while of
     playing, pick% should track est%.
3. If the shuffle seems to linger in barren structure more than before, the depth prior is the suspect.
    Compare dry tours in the Radio trace.

**Next candidates:** a face for the census table (the glass, not just the CLI); exclude the fog estimate
 for a folder whose root has gone (today it just stops being walked); and decide whether `n` (the φ
  cursor) needs persisting at all.

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
