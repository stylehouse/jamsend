# HISTORICITY NOTICE (filed 2026-08-05)

This is the ORIGINAL `Heist_todo.md` — nine months of build compressed into dated strata, each
 newer entry opening with some version of "read THIS first, the rest is stale". The human asked for
  it "straight without all the revisions", so the living content was rewritten as a single coherent
   statement and lives at **`src/lib/O/spec/Heist_todo.md`**.

Kept here for the REASONING the rewrite necessarily drops: why the census went metadata-only, why
 `Heist_root`/`music/` was torn out, the seven adversarial-review bugs of 2026-07-28, the %Stream
  32s starve, the Vyto split, and the two live-verification arcs. Nothing below is current behaviour;
   read it as history. Vocabulary note: everything below says **%Keep** — that particle is **%Haul**
    now (2026-08-05), and its `at:` field is `pub:`.

---

# Heist_todo.md — the keep-what-you're-hearing build (2026-07-28)

## 0. Next move (read first)

### 2026-08-05 — the snap-shut bomb is DEAD (root cause was not ours), plus a KeepFace batch. One ruling owed.

**The "snaps shut" bug was never a Heist bug** and Evening 8's freeze (below) was not what fixed it. Root
 cause: `replace()` publishes the empty half of its own transaction, and `agency_officing`
  (`Hovercraft.svelte:133`) replaces every actor's `w:` children every tick — so Vytui's
   `{#each vyto_worlds() as w (w)}` got a 0-length list once per tick and destroyed every face in the glass,
    KeepFace included. Fixed at the reader (`ui/micro/hold.ts` + both Vytui structural gates);
     `reactivity_docs.md` § "The transacting-empty render" has the chain and the three cures. **Confirmed
      live by the human**. Evening 8's dirs-freeze stays — it was a real second hazard, just not this one.

**Landed alongside, in `KeepFace.svelte`** (live-testing owed on all four): ✓ now COMMITS whatever is in the
 boxes instead of only closing the editor (typed-but-not-ENTERed text was being silently dropped — the
  human's report); each directories chunk is EDITABLE in place rather than remove-and-retype; directories
   chunks break inside a name so one long source folder stops setting the cell's width; and group labels in
    the track tree no longer restate the directories row — the prefix match is now MARKER-BLIND, so
     `- chill` / `0 chill` / `chill` are one directory and the strip actually happens.

**MARAUDING WAS A LIE, AND IS NOW A SEAM (2026-08-05).** `Heist_marrauding(runid, nick)` builds
 `.jamsend/test-marrauding-of-<runid>/<nick>` and its header claimed *"the APP passes a real run uid"*.
  **It did not** — both live landing calls passed a literal `''`, so the namespace was test-only and a heist
   run from a live tab landed indistinguishably in the real collection, unsweepable. There is also no
    "sweep machinery" to inherit, whatever an earlier note may have implied: it is three small things —
     `Heist_meta_dir()` (returns `'.jamsend'`), `Heist_marrauding()` (string builder), and `Heist_sweep()`
      (14 lines: recurse, `deleteEntry` every file, keep the dir skeleton). Books hand-call the sweep at
       start and end; nothing schedules anything.
 **FIXED:** `Heist_mardir(w)` — `w.c.mardir` or `''`. Every live landing / newlyadded / resume-sync call now
  routes through it. Production is byte-identical (nothing set ⇒ `''` ⇒ the collection root); anything
   wanting a sweepable namespace — a test tab, a probe, a Book driving the LIVE path — sets one runtime
    knob and inherits landing + newlyadded + `Heist_sweep` unchanged. Runtime-only (`.c`), so no snap moves.
 **Spelling:** `marrauding` is a typo (double-r), living in the on-disk dir name, the verb, and literals in
  `Heistation.g` / `Berthation.g`. **No recorded fixture contains the string** (verified), so the rename is
   safe whenever wanted — left alone only because those Book files are open in another thread.
 *(A `0 spawn` → `0 heisted-<from>-<to>` path-rewrite hack was built for this and then removed: the mardir
  seam is the same result done properly, and the human called the hack silly — correctly.)*

**OWED, and bigger than heists — a general `Dexie/$somewhere ↔ .jamsend/$somewhere` sync.** Haul persistence
 is currently SPECIAL-CASED: `Heist_keep_persist` writes `%HeistSeed` + real `%Pick` children into the Berth
  at `.jamsend/berth/<prepub>/Heists`, and `Heist_keep_rehydrate` replays them on boot (straight into
   `pulling`). It works, and it is one bespoke pipe. The identity side has its own bespoke half
    (`Identity_persist_todo.md` steps 3-4, `Swarm_spec.md §171`, both `[want]`). The human's read
     (2026-08-05): these want to be ONE general mechanism — a named store on each side, synced — rather than
      a pipe per feature. Not started; likely the next drift.

**THE ONE RULING OWED — automatic `- ` → `0 ` at land time.** A folder whose name starts with a dash cannot
 be handed to a shell command as a non-flag, so `0 ` is the marker we write (as `Heist_keep_set_genre`
  already does for categories, `Heist.g:1877`). KeepFace now shows and commits the shell-safe form, which
   makes the rename real **for any keep whose directories are ticked** — opening the editor and pressing ✓
    with no other change is enough, because the dirs/dirs_auto substitution in `Heist_rel_for` lands it. An
     UNTOUCHED keep still lands the source's own `- name` folder. Making it automatic means a leading-dash
      rule in `Heist_cp_path`, which bends the explicit cp-landing ruling — *"the source's own filename and
       folder layout survive UNCHANGED"* — and would churn every Book fixture that asserts a landing path.
        **That is the human's call, not a display edit's.** If yes: put it in `Heist_safe_seg` (the one
         chokepoint, already the home of the `/`-and-NUL rule) and budget the Accept.

### 2026-07-30 EVENING 8 — the directories-editor "snaps shut" bomb from the entry below has a fix, UNVERIFIED
###  LIVE (solo session, no browser click access). Full root-cause reasoning + the safe nice-ups landed
###   alongside it: `Download_stall_handover.md` § "Evening 8". Short version: `dirsSegs` fell back to a
###    LIVE-recomputing auto-prefix whenever `sc.dirs` was unset, and the non-keyed chip `{#each}` destroyed
###     trailing DOM nodes (incl. a focused input) whenever that prefix narrowed mid-edit — froze it at
###      `openDirs()` time instead. Also fixed a dead-code bug (`n.c.cat_editing`/`dirs_editing`, leftover
###       from a reverted earlier attempt) that silently zeroed the known-category/known-dirs datalist
###        suggestions. **NEXT: the human needs to actually click into directories on a still-materialising
###         keep across a few trickles and watch — mount/destroy console instrumentation is in place if it
###          still breaks.**

### 2026-07-30 LATEST — the real Heist UI: chip+gap breadcrumbs, directories WIRED into landing, marker is
###  `0` now, a reset button, LIVE-VERIFIED on the human's own real tab. Read this before touching
###   KeepFace.svelte or anything category/directory-shaped.

`KeepFace.svelte`'s old free-text category field + destination-preview line + nab-album/nab-track buttons are
 GONE, replaced per the human's direction — corrected TWICE this round after live-testing on their own real
  BigSoundland tab caught what the first pass got wrong (a single blob input instead of segments):
- **section** (mine) and **directories** (theirs) are two separate, never-merged, never-enclosing hierarchies.
   At rest each is a calm `/segment/segment/` breadcrumb (neutral slashes, accent segment text). Click to
    edit: NOT one text field — a row of small chips, one per segment with its own × to remove it, and a tiny
     "+" gap before/between/after every chip (N segments ⇒ N+1 gaps) that grows as you type and inserts a new
      segment at exactly that position on Enter. `section` stamps the category marker automatically (never
       typed by the user); `directories` is the shared source-folder prefix across the described tracks
        (commonPrefix of the husks' folders, computed in the Svelte face).
- **directories IS wired into landing now.** Editing it calls `Heist_keep_set_dirs(keep, v, auto)`, which
   freezes BOTH the override (`keep.sc.dirs`) and the auto-detected value AT EDIT TIME (`keep.sc.dirs_auto`)
    onto the keep. `Heist_job` stamps both onto the minted job; `Heist_rel_for` substitutes dirs_auto → dirs
     at the FRONT of each pick's cp-path only, and ONLY when the record's own path still starts with that
      frozen dirs_auto — never a blind rename, so a multi-disc keep's CD1 vs CD2 divergence (and filenames)
       below the shared prefix survive untouched. Re-verified MusuHeist live after this change (still 22/22
        green, ok_pct 1.0) — the substitution is a pure no-op for any job that never set dirs, so nothing
         that doesn't use this feature can be affected by it.
- **category marker migrated `-` → `0`.** `Heist_keep_set_genre` now stamps `0 <name>` on every write; both
   `-` and `0` still READ as a category everywhere (nothing on disk needs touching for old folders), but any
    category that passes back through editing normalizes to `0` on the spot — a collection migrates one
     touched category at a time, not a background file-rename job.
- **"discover what we already have."** `Heist_known_categories(own_lib)` / `Heist_known_dirs(own_lib, artist)`
   scan the library's own `%Record.sc.path` for existing category prefixes / matching artist folders, feeding
    each breadcrumb's datalist while editing — so a near-duplicate folder is a visible choice, not an accident.
     Only works because `%Record.sc.path` rides on EVERY record now (`Ra_record_from`), not just heist-landed
      ones — the old "comma in a path is a snap hazard" reasoning was wrong (`Text.svelte`'s `enLine` already
       JSON-falls-back on any unsafe value).
- **single-track mode is GONE.** `Heist_keep_pick_all`/`_none`/`_seed` (the old nab-album/nab-track buttons)
   are deleted outright — `Heist_keep_default_pick` already keeps the WHOLE described folder the moment it
    describes. Per-track fine exclusion still works (`Heist_keep_pick_toggle`, click a track chip to skip it).
- **global remembered defaults.** `Heist_defaults_get/_set/_rehydrate` in Heist.g: the category a heist gets
   set to becomes the default the NEXT heist opens with (`Radio_keep` seeds `keep.sc.genre` from it). Dual-
    homed like `Swarm_pier_stash` — `H.stashed.Heist_defaults` (Dexie) mirrored to a
     `.jamsend/berth/<prepub>/HeistDefaults` Waft for durability. `directories` deliberately does NOT feed
      this — source-specific, means nothing as a default for a different friend's structure.
- **reset heist state button.** `DiagFace.svelte`, behind the 🔧 diagnostics toggle (destructive action, opt-
   in gate): a real confirm-before-delete (`O/ui/micro/DeleteX`) that calls `Heist_keep_reset_all(w)` —
    cancels every standing `%Keep` through the same `Heist_keep_cancel` path a single ✕ already used.
- **track tree**: a folder group with more than 5 tracks collapses by default (a real `<details>`); 5 or
   fewer stays expanded inline, every real track shown, no "… N more" placeholder.
- **LIVE-VERIFIED, twice.** The runner was flaky most of this session (ping answering, run/state timing out)
   but came good — ran MusuHeist for real, it went red, diffed the actual mismatch with `story_repl.mjs diff`
    instead of stopping at "red": all 16 `%see` assertions fired, the whole story arc completed, and the red
     was pure fixture staleness (the already-known non-deterministic Grant timestamps + a belief-loop pacing
      shift from the `Swarm_share_loop` reentrancy fix). `accept`ed fresh, reran: 22/22 green. Separately
       discovered the runner I'd been driving via plain `runner_ask`/`story_repl` (no `--runner=`) IS the
        human's own real BigSoundland tab (`world` showed real supply-pipeline + Peering state) — Story Books
         run there ALONGSIDE the resident session in an isolated `H:<Book>,Run` world, not inside it, so this
          is safe, but worth knowing: a `run <Book>` on the un-targeted default reaches their live tab, not a
           dedicated sandbox. The chip/gap UI itself got corrected live, in real time, off the human's own
            testing on that exact tab — first the whole-blob-field bug, then the visual too-busy pass.

### 2026-07-30 — `music/` prefix REMOVED FOR GOOD. Every `/music`, `Heist_music_root()`, `job.sc.root` mention
###  below this point is STALE. Read THIS first, then skip past them.

`Heist_root` / `job.sc.root` / `Heist_music_root()` / the never-wired `M.c.heist_root` test hook — ALL DELETED
 (the human: "the entire Heist_root thing is bullshit and distracting... FUCK YOU. not heist_root! remove all
  of that"). It was scar tissue: `M.c.heist_root` was never set anywhere, and Book isolation already runs
   through each Book's own explicit `mardir` param, never through this. A heist now lands at the TRUE FSA
    root directly (`''`), unconditionally, in dev AND prod — no `music/` prefix, no per-job root field, no
     getter. Every `/music`-prefixed landing path described further down this doc (SHIP 1, SHIP 2, the
      Superseded section's "Landing dir = `/music` directly" ruling) is describing a design that no longer
       exists — read those as history, not current behavior.

**If a dev-only "prefix downloads so I can find them" convenience is wanted again**, it does NOT go back into
 this backend plumbing. The human's ruling: it's a small, explicit, untickable-like-any-other-suggestion block
  living entirely inside the Heist setup UI flow — see the Categories work below (§ "the staircase"). Nothing
   backend-side should ever again default-prepend a folder onto a landing path.

### 2026-07-29 EVENING (overnight solo) — downloads FIXED, nested GATED OFF, Heist UI polished. Read THIS first.

Everything below is NOT committed (working tree). All Book-verified GREEN on the FSA runner (MusuHeist 22/22,
 Sounditron 1/1). The human left me on overnight with a pile of feedback; here's the arc.

**THE BIG WIN — peer downloads were fully wedged; FIXED.** The human's console showed a `repli_want` STORM
 (wants ≫ lines) and "neither can download anything". Root cause: `Ra_pull_beat` (Ra.g) was an unbounded,
  backpressure-free pull — every beat it fired a want for EVERY missing page of the WHOLE record, gated only by
   a set-once latch (never re-asked → a dropped/parked want = permanent hole → record never completes). FIX:
    client-driven backpressure copied from the proven siblings — per-beat budget `B`(6) + `LEAD`(32) window +
     4s `ra_want_ts` re-ask (self-heal). Knobs `w.c.heist_want_budget`/`heist_want_lead`. See
      [[heist-pull-want-storm-fix]]. **Owed:** the SERVE side still drains under the beliefs mutex — the
       prototype ran the source reader DETACHED + self-gated; that's the deeper follow-up. LIVE two-tab repro
        of the storm needs two connected tabs (not a Book).

**BRANCHY (nested) Vyto CRASHED → GATED OFF.** My nested-Heist (task done last turn) turns `w.c.nested` on when
 a keep opens — but the renderer's `power_cells` is O(M²)/scope recomputed EVERY frame with no memo, so a
  whole-album keep (12-20 picks, over the 12-cell budget) pegs CPU → OOM. Also never settles + overlaps + too
   small. Gated: `Sounditron_commission` now `if (anyKeep && M.c.heist_nested)` — DEFAULT OFF ⇒ flat KeepFace
    (works). The four renderer fixes are the **Vyto owner's** — written up with line refs in
     **`spec/Vyto_perf_todo.md`**. Flip `M.c.heist_nested` to test nested once those land. Also cut the
      per-beat keep-root re-stir churn (progress bumps only when `landed` advances). See [[vyto-nested-is-global-grapple]].

**HEIST UI polish (the human's feedback, all done):** "file under"→**category** (a `- <name>` sort-topward
 folder, nests via `/`, `Heist_cat_path`); **two buttons nab-album/nab-track** (new `Heist_keep_pick_seed`) not
  all/none; **field snaps-shut FIXED** (local `$state` + commit-on-blur — the reactivity_docs/UI:Waft bug);
   **no `music/Unfiled/` prepend** — source folders land as-is (the `Heist_music_root`/`M.c.heist_root` test-
    isolation param this leant on is GONE now — see the 2026-07-30 note at the top of this file, landing is
     the true root unconditionally, no param needed); **pause sticks** (`radio.c.ever_played` latch stops the trickle re-pressing play). See
     [[heist-ui-category-pause]].

**NEXT (needs the human / live tabs):**
1. **Fullscreen HeistSetup rebuild** to the Peerily prototype (`src/lib/mostly/Pirate.svelte`): path broken into
    slash-separated places, a `nab` on the album-dir place vs the track-blob place, per-segment category toggles
     + existing-check. `HeistSetup.svelte` is currently ORPHANED (nothing raises it). Prototype spec fully captured.
2. **Vyto owner** lands `spec/Vyto_perf_todo.md` → then flip `M.c.heist_nested` on and watch a keep nest.
3. **Live-verify the download fix** on two connected tabs (`world --runner=<source>` should show the storm gone).
4. Branchy Vyto to SHOW a friend's live download (the human's ask) — unblocked once #2 lands.

### 2026-07-29 UPDATE — nested render is LIVE; %Stream reframed. Read THIS first (supersedes stale bits below).

**Nested Vyto render SHIPPED by the Vyto agent** (`VytoNestRest` green; Vytui descends the tree). The "Nesting
 is NOT shipped yet" line below is now stale. BUT nesting the Heist is a **coordinated change, not a flip** —
  `w.c.nested` is GLOBAL, every grapple's whole subtree draws, and a nested parent renders BARE (face suppressed).
   The `%Keep`'s `%Pick` children + the grappled `Heist` organ's `constraint/Lead/filing` children would surface
    as stray/grey cells. Full contract + the safe 4-step plan (decouple picks → move controls to a `%KeepBar`
     child → guard the flip on `anyKeep` + drop the `{Heist:1}` grapple → prove in isolation) is in memory
      `vyto-nested-is-global-grapple.md`. **DO IT WITH A LIVE SOUNDITRON** (the pick-decouple has reload-semantics
       to verify) — deferred this session because only Book runners were up, no live BigSoundland tab.

**%Stream "takes a minute" REFRAMED — it is NOT the source decode.** Instrumented the friend-serve producer
 (which had zero trace marks) with `pcm-decode-start/read/decode-done/stream-first-chunk` (Ra.g+Radio.g, compiled
  Ra.go @2db4814 / Radio.go @a9d763c5; marks live on `M.c.supply_trace`, `.c`-only so snap-safe). Ran MusuRaStream
   live: want→first-stream-chunk ≈ **334–415ms** (decode ~160–206ms). The source producer is FAST. So the live
    minute is the **WIRE** (friend across the relay; the Book source was local) or **Vyto mutex-contention**
     (the churn-cut targets this). NEXT: when a real Sounditron is up, `world --runner=<source>` and read the new
      marks — fast there ⇒ chase the wire (`ra_wanted`/park/serve timing, `Swarm_share_present`); slow ⇒ source.
   ALSO: MusuRaStream steps 13–40 go RED = fixture DRIFT (snap diff, `error:null`; the lead pass makes more chunks
    ahead than the old fixtures) — streaming is healthy; **re-record owed on a live runner** (confirm with human).

### THE VYTO SPLIT (ruled 2026-07-28 night by the human + the Vyto agent). Read this before any glass work.

**The Vyto agent owns the renderer (Vytui core); the Radio agent (me) feeds C** trees + builds faces.** Two
 agents in Vytui all night = the HMR wedges — so it's a hard seam, no clobbering. **Nesting is NOT shipped
  yet** — Vytui paints top-level cells only (`all_rows` = `mirror.o()`); `Vyto_solve_scope` computes child
   `.c.poly`/`.c.T` that nothing draws. The Vyto agent hardens the base first (live-green, the clip-vs-inscribe
    overlap decision, layout convergence, HMR) THEN owns the nested render. Until then: **ship FLAT (Option 3)**,
     keep building the Heist C** tree + KeepTree/KeepList/diagnostics faces so they light up the moment the
      nested draw lands — but DON'T gate any feature on the renderer.

### SHIPPED FLAT this turn (compiled, NOT committed):
- **Name self-pier bug** — `Radio_lineup_errors` + `Radio_reason` skip the self-pier ("no music coming across
   from Righto" on Righto is gone). Bug still open: a friend with no `friendly` name shows its prepub (needs a
    friendly, or the small nick the Vyto agent is adding — left alone to avoid colliding).
- **Attention dimming** — a live `%Keep` shrinks the always-on secondary organs (Tuner·Riffle·Lineup·Heist) via
   a negative `sc.dose`; Radio (now-playing) + the Diag toggle stay full; the Keep doses itself up; clears when
    the last keep leaves (Sounditron trickle).
- **Diagnostics toggle** — the three diagnostic-flavoured organs (Beat·Uptime·Door — a GUESS, easy to change)
   are hidden by default and grapple back only when the `🔧 diagnostics` cell (`DiagFace`) is opened
    (`w.c.show_diag`, `Sounditron_diag_toggle`). Flat; the true nested "diagnostics cell CONTAINING the three"
     waits on the Vyto renderer.
- **Deferred (needs the nested renderer or a dose-conflict fix):** opening diagnostics dis-enlarging the Heist;
   the Heist as a real hierarchy-cell + tracks-cell under one parent (the single `KeepFace` shows dir-grouped
    hierarchy + tracks in one cell for now).

### THE %STREAM 32s STARVE — FIXED (2026-07-28 night, compiled, NOT committed). The blocker.

Chasing "still fails at 32s" past the census fix turned up the REAL cause (a separate, same-class bug in the
 core streaming producer, reproduced with no heist): the friend-track continuation transcode (a) whole-file
  DECODED on the beat under the beliefs mutex (seconds of freeze at the seq-16 seam) and (b) produced at
   break-even 2-chunks/beat (~0.5 chunks/s = the consume rate — zero margin). FIX in **Ra.g**: non-blocking
    detached decode (`Ra_transcode_ensure`) + a lead-ahead pump (`Ra_transcode_pump` runs the frontier ~48s
     ahead of the served offset). **Reload both tabs, play a friend track past 32s; re-run `runner_ask.mjs
      world --runner=<listener>` — the seq-16 `starve` line should be gone.** Full detail + residual suspects:
       memory `stream-continuation-starve-fix.md`. THIS is the thing to verify first — music must play through.

### SHIP 2 — the Heist as tidy Vyto cells (2026-07-28 night, compiled, NOT committed).

The human's UI vision, built: ⇊ mints a %Keep that appears as its OWN Vyto cell (`KeepFace.svelte`, registered
 in glass_kinds/glass_faces) grappled into the resident `Sounditron_commission`. While PRIMED it sits in the
  clutter, dose-boosted (`sc.dose='2'`), showing the folder NODULATED by directory (not right-aligned filenames)
   with a genre datalist to tweak the filing dir + per-track un/keep (seed marked ♪); at end-of-track it auto-
    starts, FOLDS DOWN (dose deleted) to a progress strip, pulls each %Pick's original into `music/<genre>/`,
     then the done keep drops itself. `Sounditron_trickle_look` re-commissions on the keep fingerprint so cells
      appear/leave. RadioFace ⇊ no longer opens the Panel (HeistSetup dormant — retire later). ⚠ Sounditron.g is
       the human's Vyto-refactor zone — additive, may need reconcile; the visual is a FIRST DRAFT (pixel-blind).

### SHIP 1 — the perf + one-click rewrite (2026-07-28 night, compiled, NOT committed). RELOAD BOTH TABS.

**The whole heist was throttling live playback.** `Heist_rummage_folder` → `Heist_census` read+hashed the
 WHOLE source folder (twice: body_hash + per-chunk cid) INSIDE `Swarm_share_beat`, holding the tick mutex for
  seconds and starving the same beat's `Ra_transcode_pump` (Swarm.g:1474) — so the listener's continuation
   wants parked unanswered and **playback ran out at the 32-chunk preview ("runs out at 32s")**, the source tab
    sat at **30% CPU**, and a folder of bytes pinned in RAM. The continuation mechanism itself (Swarm.g:1483,
     the head+16 live-window pull) is SOUND; it was being starved. One cause, three symptoms.

**The fix — census is now METADATA-ONLY; bytes read once, on demand, at pull:**
- `Heist_census_heads(w, lib, nav, base, me)` — walks paths only (Crate_nav_paths already audio-gates), mints
   chunkless husks (`husk:1`) under a **keep-id** = `Heist_keep_id(me, base, path)` (sha256 of pub+path,
    DISTINCT from the streaming content-id so a materialised original never upserts onto the seed's opus rec —
     that was the old review's collision blocker, now dissolved by construction, seed exclusion GONE). ZERO reads.
- `Heist_materialise_one(w, nav, me, ref)` — the ON-DEMAND single-file inflate: resolve `ref` (a stocked
   content-id → Ra_stock_ls→card→path, or a describe husk's keep-id → its path), read that ONE file, chunk it
    with a SINGLE incremental-hash pass (body_hash + per-chunk cid), stamp total, `re:<ref>` back-ref. Idempotent.
- `Heist_rummage_ask(...,want)` / `Heist_rummage_answer` gained a **`want:<ref>`** mode = "materialise + offer
   me the ORIGINAL of this one ref" (vs the describe mode = metadata heads). The answer offers the FULL head
    (total present) so the asker's `Ra_pull_beat` (which bails on total==0) can pull.
- The serve-lib sweep now **DETACHES** an aged lib (`(rl.c.up||w).drop(rl)`) so its %Body bytes GC — not just
   filters the list (the retained-RAM half of the 30% CPU).

**The state machine is now ONE-CLICK + DEFERRED** (`Radio_keep` mints `state:'primed'`; ⇊ no longer opens the
 Panel — RadioFace is a clean one-click, the ✓ tick is the only feedback):
- `primed` → while the seed is STILL the playing track, LINGER (no ask, no pull — never fight the live stream).
   Once the seed stops playing → `pulling`. (Legacy `wanted`/`asking` keeps route here too.)
- `pulling` → materialise-ask the seed DIRECTLY (`want:<seed>`, no folder census on the default path), then
   `Ra_pull_beat` the arriving original + `Heist_land` into `music/<genre>/<source-path>` → `done` (job drops).
- The **default keep is the seed track only**; the folder-browse (describe) machinery stays wired but DORMANT
   (no describe asks are sent on the default path) — it becomes SHIP 2's tidy-cell "add more from this folder".

**HUMAN VERIFY (needs two live BigSoundland tabs — reload BOTH, esp. the source, for the new gen):** play a
 friend's track past 32s (continuation should now flow — CPU on the source should be near-idle), click ⇊, let
  the track END, and confirm the original lands in `/music/<genre>/` while the next track plays. If 32s STILL
   cuts after a clean reload, the starvation hypothesis is wrong and it's a separate %Stream bug to chase.

**KNOWN v1 edges (follow-ups, not blockers):** the one-file materialise (source) + the land read-back-hash
 (asker) still run on the beat — a bounded ~100-300ms hitch per kept track at a track boundary (time-slice
  off-mutex later if noticed). A source `path` with a COMMA is a latent encode hazard (Ra_record_from omits
   path for exactly this reason; the heist NEEDS it for cp-landing — the old census had the same exposure).

### SHIP 2 — the tidy on-screen cell (the human's vision, NOT YET BUILT)

"we show the Heist on screen, it has to be tidy" + "group the same bits of the filenames" (as the prototype did).
 The Vyto renderer is FLAT (one cell per top-level grapple; sub-cells are solved but never painted — extending
  that is the human's Radio→Vyto refactor zone). So: ONE `KeepFace` cell (the HeistFace-renders-its-children
   pattern), the `%Keep` grappled into the resident radio commission, `sc.dose` space-favouring it while active,
    tracks GROUPED by common filename prefix (album-ish). Retire the Panel (`HeistSetup`) once the cell renders.

---

## Superseded — the earlier Panel-Lens build (kept for the engine history below)

**The whole ⇊ keep→choose→pull arc is now BUILT end-to-end (2026-07-28 evening) and compiled green.**
 What's left is the human's two-tab live verify (an agent can't seal two tabs, `Frontier §3.1 R1`) and
  reacting to what that shows. The three OPEN questions the earlier handoff parked were RESOLVED by the human:
1. **Landing dir = `/music` directly** (the human's ruling, overriding the earlier `.jamsend/kept/` rec):
    "SHOULD be writing into /music directly — with the directory structure agreed upon." → `Heist_music_root()`
     returns `'music'` (the nav base the stoker digs), landing at `music/<genre>/<source-file>` via the
      existing `Heist_rel_for` = `<filing-genre>/<cp-path>`. A kept folder is picked up by the next census
       (`Crate_nav_paths` walks `/music` RECURSIVELY, dot-dirs skipped) — so it just appears in the radio.
        Every landed byte is still cid + body_hash gated; `Heist_held` (artist+title) dedups already-owned.
2. **Mirror-scoping = a `rummage:<seed>` TAG** (not a routing change, not a separate manifest). The source's
    `Heist_rummage_folder` stamps each folder husk `rec.sc.rummage = seed`; it crosses the husk head like
     title/artist/genre. The husks land MIXED in the friend's `%MusuThem` mirror (live routing is sender-keyed),
      but the chooser filters `o({Record:1, rummage:seed})` and the pull drives ONLY the chosen `%Pick` recs
       (each keeps its own `c.rx`/`c.from`). No invasive `Repli_merge` change.
3. **Chooser home = the Panel Lens, NOT Vyto** (display-neutral, sidesteps the Vyto refactor zone). It's a
    face-only `Lens:Panel` Funk — `src/lib/O/Funk/HeistSetup.svelte` + one line in `Funk/kinds.ts`, hosted by
     the global `<Lens kind="Panel">` already mounted in `BigSoundland.svelte`. ⇊ opens it via
      `Lies_lens_suggest('Panel','HeistSetup',{altitude:88})` (RadioFace.svelte); it closes via
       `Lies_lens_dismiss`. Copied the `IdHatch.svelte` pattern (FaceSucker fullscreen).

**The live state machine** (`%Keep,state`): `wanted` → (driver asks the source to describe the folder,
 throttled 4s) → `asking` → (folder husks land tagged) → `choosing` (HeistSetup shows them) → (human picks
  genres + tracks, commit writes `%Pick` children) → `committing` (driver pulls + lands each) → `done`.
   Both roles ride `Swarm_share_beat` → `Heist_keep_beat` (SERVE friends' asks + GO my keeps).

**Adversarial-reviewed (2026-07-28 eve) — 1 blocker + 6 real bugs found and FIXED:**
- **#1 (blocker) the pull was served from the wrong library.** `Ra_pull_beat`/`Repli_serve_want` serve from the
   route's caster = the source's OPUS radio stock (`Ra_home_self`), but a rummage husk promises the ORIGINAL
    file bytes off the source's scratch `RummageLib` — so an unstocked folder track found nothing (spin) and a
     stocked one served opus that breached `Heist_land`'s hash gate. FIX: `Heist_rummage_folder` registers its
      census in `w.c.rummage_libs`; `Repli_find_record` searches those FIRST (additive — empty for every Book /
       idle app); a 120s sweep bounds the window where a served-original id could shadow the radio opus.
- **#2** lost answer-frame → keep stuck in `asking` (one-shot latch). FIX: re-answer ≤3×, ≥5s apart.
- **#3** two ⇊-keeps of the SAME folder clobbered each other's `rummage` tag. FIX: multi-valued comma tag +
   `Heist_rummage_recs` membership filter.
- **#4** paged mirror records (incl. the seed) invisible to the flat `o()` gate/chooser. FIX: `Heist_rummage_recs`
   walks `Ra_recs` (Mag-aware); the chooser EXCLUDES the seed (streaming it live — pulling mid-stream fights the
    radio for the same record/want-cursor).
- **#5** `committing` had no abandon. FIX: Abandon button + `Heist_keep_cancel` drops the job too.
- **#6** reload mid-`committing` double-minted the job. FIX: find-or-create `shop.o({Heist,at})`.
- **#7** landed rows vanished from progress. FIX: progress list reads the `%Pick` children, not the husks.

**Next move for the next session:** human seals two BigSoundland tabs, plays a friend's track, clicks ⇊, watches
 the chooser fill, commits, confirms files land in `/music/<genre>/`. Suspects if it stalls: `%Rummage` not
  landing where SERVE looks (`Ra_home_them(rw,asker).o({Rummage:1})`) — trace with the `world` runner_ask op.
   Known-but-parked: literal same-path clashes at `music/<genre>/<file>` only guarded by `Heist_held` identity
    dedup (add a disk-exists 'clash' verdict if overwrites happen, Heist.g Heist_held ~178); snap litter
     (answered `%Rummage` + bay asks not dropped); the 120s rummage-lib shadow window (a rare radio-vs-heist
      byte glitch for the same track pulled two ways from one source — self-heals on sweep).

## What shipped this session (compiled, in the working tree, NOT committed)

- **Boot speed** (`Sounditron.go 43695c`, `Radio.go 73981c`): the ~20s-to-relay hang was `Sounditron_
   stock_settled` waiting for the stoker to reach `idle|spent` while an era-race left `st.sc.stock == null`
    (the first look returns before its census). Fix: settle on `stock>0` (census now stamped SYNCHRONOUSLY
     at first resurrect-stand, before any await can interrupt); ceiling 30→15; peer_wait 20→2 when no
      **Music**-granted friend. **⚠ RE-RECORD the Sounditron fixtures on a live runner + run twice** — the
       early settle makes the `%Record` shelf count a race (structural drift EntropyArrest won't forgive);
        the 4 contract assertions still latch. (Adversarial-reviewed; see Findings 1-5 in the session notes.)
- **Starve self-heal** (`Swarm.go 108977c`): the live cross-relay pull re-asks a still-missing live-window
   page every 4s (`w.c.ra_want_ts` beside the once-cursor) instead of never-reask — a want lost to the wire
    (dropped reply / reused-seq collision) used to starve the playhead until a full peer rebirth. This is
     LIVE-crossing hardening (the human's "both go into 'next piece hasn't arrived' after a little while").
- **Heist Move 1 (gesture)** (`Radio.go`): `Radio_keep(n)` mints `%Keep,seed,at,state:wanted` under the
   asker's `Ra_home_shop`; the ⇊ button on RadioFace (friend tracks only, `face.by`) shows ✓ once kept AND
    opens the chooser (`Lies_lens_suggest('Panel','HeistSetup',...)`).
- **Heist Move 2 (inflate)** (`Heist.go`, `//#region raheist`): `Heist_rummage_folder` resolves a heard
   track's content-id → its SOURCE FOLDER (only the source can — a %Record carries no path; `Ra_stock_ls`+
    `Ra_stock_peek` read the card's base+path), censuses it, and TAGS each husk `rummage:<seed>`. `Heist_
     rummage_ask`/`Heist_rummage_answer` are the wire verbs (%Heistlet request→reply, reply = folder husks).
- **Heist Moves 3-4 (choose + pull → /music)** (`Heist.go`, `Swarm.go`, `HeistSetup.svelte`, `kinds.ts`,
   `RadioFace.svelte`): `Heist_keep_beat` (pumped from `Swarm_share_beat`, guarded) SERVEs friends' asks and
    GOes each `%Keep` through wanted→asking→choosing→committing→done; `Heist_keep_commit`/`_cancel` are the
     chooser's verbs; `Heist_keep_pull` mints the job once + pulls each `%Pick` + `Heist_land`s into
      `music/<genre>/<file>` (`Heist_music_root()='music'`). `HeistSetup.svelte` is the fullscreen chooser
       (per-artist genre with a datalist, per-track keep/skip + `Heist_held` collision badge, live progress).
- **Genre capture** (`Crate.go`): `Crate_meta_from_tags` now reads `common.genre[0]` and `Heist_census`
   stamps it (guarded) so the chooser's default filing is the source's own tag.

## The klepto engine (scope B) stays BUILT + PARKED (Heist_design.md §"Scope B"). Production = scope A above.
