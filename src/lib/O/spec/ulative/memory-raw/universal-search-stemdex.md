---
name: universal-search-stemdex
description: "Stemdex (LiesFunk) scan|stem index over every Doc + the universal Searchbar (Liesui header) + Plank hang; built 2026-07-03; Book gate PLANNED 2026-07-20 as LakeSearch — full brief in spec/Stemdex_todo.md (Machinery.svelte mould, coined corpus, dontSnapGhostList lever)"
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

**The universal search layer (BUILT 2026-07-03, uncommitted, :9091-verify OWED).**

- **Stemdex** — `LiesFunk.svelte` region "Stemdex": `Lies_stem` (light suffix-strip stemmer; scan
   and query share it — consistency IS the contract), `Lies_stemdex(w)` handle on `w.c.stemdex`
    (off-snap Maps: docs/post/defs/props), `Lies_stemdex_scan_text` (one doc: stems + line-start
     def patterns + the particle vocabulary `sc.key`|`.c.key`|`%Notation` as props + .md headings
      as defs), `e_Lies_stemdex_scan` (a POLITE pass: indexes landed `%Good text/Doc` contents,
       requests ≤24 new reads — converges over repeated nudges; dige-gated per doc; skips
        gen/*.go and >400k blobs), `Lies_search(w, q, cap)` (pure sync: defs ▸ props ▸ texts,
         exact/prefix/substring tiers, AND-across-tokens freetext ranked by hit mass).
- **Why Lies-side only**: docks live on the LANG w — the index reads the `%Good` disk cache
   instead, so it covers docs nobody opened. Known drift: unsaved buffers unseen; the precise
    live layer (open docks' compiled `%Map` defs) is the NEXT step, not done.
- **Searchbar** — `O/ui/Searchbar.svelte`, mounted in Liesui's `.ls-header` (editor only, gated
   `!Lies_is_runner`). `/` summons (capture-phase, skips inputs/contenteditable so CM keeps its
    slash), Escape clears. While open it nudges scan passes every 900ms. Hit click =
     `Lies_ghost_pick {path}` + `Dock_open {path, point}` — point = def NAME or `text:<word>`
      (the Text-Point bridge, resolves pre-compile).
- **Plank hang** — Liesui holds `search_live` $state → Plank → DocWaftMap prop (`search`); hits
   whose Doc has a chip on the map hang under it (`.pm-hang`, ≤3 rows). UI-to-UI plumbing only,
    NO particle churn.
- **Waft height + cursor-follow** (`ui/Waft.svelte`): every `.ls-waft-body` now capped 55vh with
   internal scroll (capstate 'tall'▸'tight' 10em▸'free' ∞, cycle button, ephemeral by design);
    a $effect on `examining.vers` walks the Spotlight src up to its NEAREST Waft and
     `scrollIntoView({block:'nearest'})`s the `.ls-item-what-active` row.
- **Verify (owner, :9091)**: type `/`, search a method (e.g. `advertise`) → ƒ hit lands in
   LiesLies at the def; search a prop (`needAC`); watch the progress line converge; hits under
    Plank chips; big Waft scrolls internally and follows the cursor.
- **OWED**: the Book gate — now PLANNED as **LakeSearch** (2026-07-20): the complete
   execution brief lives in `src/lib/O/spec/Stemdex_todo.md` (name verdict — it's a Lake*
    Lies self-test in test/Machinery.svelte beside LakeLocate, NOT a Musu* .g; one-Prep
     gate-marker Book; coined collision-proof corpus seeded via %Good so no disk read;
      `Opt dontSnapGhostList` is the load-bearing entropy lever; Dexie-warm neutralized by
       the coined vocabulary; pure-isolation fallback via Lies_stemdex_scan_text). Build
        after the pending commit. Then the `%Map` live-defs layer; maybe persist capstate
         via [[lens-posable-layout]]'s layout service if it earns durability.

**Regressions caught by the owner same day (both fixed):** (1) cursor-follow used
 `scrollIntoView` → the WINDOW scrolled on every trickle think (examining bumps every tick) —
  fix = gate on Spotlight-src CHANGE + scrollTop math on the BODY ONLY (page must never move) +
   settled read under `H.clear` per reactivity_docs; (2) the scan floated un-awaited
    `LiesStore_read_good` promises (mutations outside Atime — the vanish-for-an-instant class)
     — fix = await + a SCAN_BUDGET (≤8 whole-file scans/pass); searchbar stops nudging once
      done==total.  **The roadmap doc is `spec/Stemdex_spec.md`** (track-all-change via the
       three dige feeds, REGION-partitioned rescan, %Upkeep errand scheduling, swap-don't-clear).
        NOTE: "WaftMap empty" — ROOT CAUSE FOUND (2026-07-03): the model $effect subscribed to
         `H.ave.vers`, but H.ave is NOT a per-beliefs beacon — it bumps ONLY when a %watched
          channel's own CHILD-SET changes (boot enrollment; the watched flush compares the
           source container's version, deep grandchild changes never propagate up).  So the
            effect ran once at mount, before any Waft landed, and never again.  FIX =
             `void ww.vers` on w:Lies itself (bumps every think; the fingerprint gate absorbs
              the churn).  The model itself was healthy all along.  Kept: the try/catch + ⚠
               error chip (a dead model must be seen) and the dirlist prune (deleted files +
                `.tmp.PID.HEX` artifacts no longer linger as phantom Docs).

**Cache + landing round (2026-07-04, uncommitted):** (1) **Dexie cache** — db `stemdex`,
 table `doc` (PK path), one projection ROW per doc ({dige, title, lines, post, defs_e,
  props_e} — the exact row `Lies_stemdex_scan_text` now returns); first scan pass WARMS the
   whole index from IDB (`dex.warmed`), dige-movers re-scan as %Goods land, pass-end
    bulkPut + roster-prune (guarded paths.size>50 so a half-booted GhostList can't empty
     it); factored `Lies_stemdex_drop`/`Lies_stemdex_adopt` so scan and cache-adopt share
      ONE insertion; strictly an accelerator (no indexedDB → old cold scan, all ops
       try/catch).  (2) **ƒ-hit "random place" landing FIXED** — a pick outran the fresh
        dock: no CM view mounted + no %Map compiled when Lang_point_navigate ran (silent
         return → doc shows resumed position).  Now bounded backoff retries (6×, ≈7s,
          drops if the user switched docks).  (3) hive order = ƒ defs THEN % props THEN
           ≈ texts (path-sorted within kind — the user: "functions first").  (4) Aside
            moments minted `What:<serial>` (max+1, never reissued) so %FromWhat
             `Waft:Aside/YMD/What:N` can address them — every moment being What:1 was the
              "totally wrong-looking Aside".

**StemHive round (2026-07-03, uncommitted):** the panel is now ONE flat hive — every matched
 name with its FULL path, sorted by path (cap 24/kind); rows GLOW when their Doc is a member
  of the Waft under the mouse (Liesui `hover_waft` $state ← ui/Waft roots (top-level
   `on_hover`) + DocWaftMap pm-waft/pm-stack chips (`onhover` via Plank); membership = settled
    Lies_walk_docs under H.clear).  Pick contract: ONE elvisto `Lies_ghost_pick{path, point}`
     — a pick WITH a point is a search DELIVERY: always into today's Aside, reusing the day's
      moment %What per Doc (Points accumulate — the day's research trail), Point as
       `{Point:1, method}` under the %Doc, then want + Dock_open.  Trail homes never get
        auto-Points (they'd feed the LE checkout extent).  Bare picks (GhostList) unchanged.
