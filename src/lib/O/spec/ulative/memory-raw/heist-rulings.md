---
name: heist-rulings
description: "Heist rulings — PRODUCTION heist = SIMPLE directory grab (old ghost/Pirate reborn, RaHeist?), klepto PARKED post-prod; cp-landing (whole-dir cp, tags=metadata, kid-safe skip, bias-to-keep dedup), %Tombstone STRUCK (Mag cursors supersede), the Berth"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

The human's Heist rulings (durable — don't re-litigate). Home doc: `spec/Heist_design.md`.

**2026-07-27 — the shape flipped. PRODUCTION heist = the SIMPLE DIRECTORY GRAB**, not klepto. You're playing a track; "keep this" grabs the FOLDER it came from into your collection, via a **directory-structure chooser** (keep/skip each dir/collection/blob, rename, `only_categories`). This is the **old `src/lib/ghost/Pirating.svelte` / `lib/mostly/Pirate.svelte` reborn in `.g`** (reference behaviour, not code to revive — `%io:radiopiracy`, `%places` tree, backpressured `o_pull`/`i_pull` = today's `Ra_pull_beat`). Naming OPEN: **`RaHeist`** (Radio-scoped) vs a sub-region beside klepto — recommend a named `//#region raheist`. **klepto (point-at-a-Pier / take-everything / "communist-minding") is PARKED until after production** ("actively seeking the music is good for now"). The chooser face is the one genuinely-missing UI and is `[OWED]` — it is NOT HeistFace (that's the klepto/soft-wish UI). **recently-added-tracking is a WANT** (seed = the probation `newlyadded` log; grow into a collection-wide "lately added" surface — own thread).

**cp-landing, not rename (BUILT green×2).** A heist picks up WHOLE DIRECTORIES and does a `cp` — `Heist_rel_for` lands at `<dest-root>/<source-relative-path>` (`Heist_cp_path` sanitizes `..`/leading-slash for kid-safe security), NEVER re-files into `<genre>/<Artist>/<Album>/<Title>`. **Tags stay METADATA, never file-naming authority** (a mislabeled file keeps its bogus name on disk, catalogued by tags never renamed by them). `Heist_land_rel` (the old tag-tree) DELETED.

**Kid-safe / non-audio siblings NEVER copy.** A heist moves AUDIO only — never `cover.jpg`/`.nfo`/stray images. Visual bytes need an ORACLE authority (cover-art lookup/hash) before they ride the wire; v1 carries none. Census must PROBE bytes are really audio (container sniff) before minting a `%Record` — the extension gate lies.

**Dedup BIAS-TO-KEEP (the Muslimgauze problem).** An album of 12 `Muslimgauze - Untitled` share artist+title, so a thin `Heist_held` identity would eat 11. Fix, layered: (1) widen identity to artist+title+**album+disc+track** when tags carry them; (2) when those are absent, DO NOT dedup (a wrong drop loses music; a dupe costs one delete); (3) the **filename/path** is the reliable fallback axis — cp keeps the original name, and a same-path destination collision is the true-dupe/clash signal (skip + `clash` verdict). Dedup by rich-enough tag-identity ELSE by path, never drop on a thin tag-identity alone.

**%Tombstone STRUCK** (2026-07-27: "Tombstone is gone, please tidy up"; was CONDEMNED 2026-07-13). Remembered-taste-denials are removed, not just deprecated. **Mag cursors move us past needing them** (a heist re-digs from source; the cursor + `Heist_held` catalog-identity skip already dedup), and **there are no liked/disliked artists|tracks yet** for a tombstone to encode. The only load-bearing skip stays **`Heist_held`** (catalog identity of what you HOLD). The deny-drop gesture (delete + honest log) SURVIVES — needs no ledger. Distinct from [[revocation-tombstone-durable]] (`%UnGrant` = SECURITY tombstone, still never-drop). Rip sites: Heist.g `Heist_tombstoned`/`Heist_feel` mint/tally, Heistation.g retomb scene. **Booth/Ban taste organ VETOED** ("I hate Booth"). Tidy still owed in `Radio_todo`/`Radio_spec`(blessed — human's)/`Mag_todo`/`Sharing_design`/`Radio_multicast_todo`/`Follow_todo`/`Radio_lowlevel` (`history/` left as record).

**Persistence = the Berth** (§11.7): per-Pier Waft homes, `<root>/.jamsend/berth/<prepub>/<Waft>/toc.snap`, bound to enWaft/deWaft + the nav contract only (never Lies runtime). Verbs BUILT+green in Heist.g (`//#region berth`): `Berth_dir`/`Berth_open`/`Berth_save`/`Berth_reset`; the on-disk dir rides `waft.c.berth_dir` (runtime-only); save uses `write_file` (toc.snap is TEXT). Book **MusuBerth** proves the disk round-trip.

**2026-07-28 — WIRING REALITY (mapped by 3 readers; don't re-map).** The whole engine (`Ghost/M/Heist.g`,
 ~1357 lines: census→job→offer→vouch→beat→**land**, + soft wish→ask→match→leads→condense) is REAL and
  byte-faithful but driven ONLY by the test Book `Ghost/Story/Heistation.g` (MusuHeist/MusuSoft/MusuBay/
   MusuBreach). The live app's ONLY reachable Heist call is **`HeistFace` "take"→`Heist_condense`** (stamps
    `at`/`chose`, NEVER kicks a pull). `Sounditron`'s `%Heist` is a decorative MOCK (`Sounditron_heist`);
     its 4th Need "the pull itself" (`Sounditron_pulled`) latches on ORDINARY STREAMING (any friend chunk-0
      present), not a real grab. **The blocker:** the valuable half — LAND (keep-a-copy to disk, scope-A) —
       is gated by the dev-boot **disk-gate** (`H.c.disk_gated`, [[opfs-illegal-under-dev-boot]]); it needs
        an **FSA runner** ([[needsfsa-dispatch-gate]]), NOT the human's dev-boot BigSoundland tabs. Pull-to-
         memory (`Ra_pull_beat` over Repli/relay) already works and ≈ what streaming does. So the smallest
          REAL demonstrable land = census→job→drive-beat→land (the ~15-line `Swarm_share_loop` analogue,
           `Heist_design.md` frontier item 3) ON an FSA-granted runner. Same `Frontier.md §1` crossing.

**Standing discipline**: Heist_* realities are PROVISIONAL — what persists must be CONTENT (collection/magazine/log), RELATIONSHIP (grants/%Share match), or SECURITY (%UnGrant), never transfer-mechanism residue. See [[mag]], [[revocation-tombstone-durable]], [[check-package-json-first]], [[full-contract-no-subset-gaps]].
