# Voro_render_faults — the render|animate pipeline fault catalog

> **Led by `Voro_todo.md §0`** — this catalog is subordinate detail.  STATUS at 2026-07-13:
>  F1/F2/F6/F7 are BUILT + live-proven (verified against the code this date); F3+F8 (cells
>   vanish/re-pop) are NOT a render bug — they share the identity-linearity root with the census
>    storm, and the fix HOME is now the landed **model layer** (`Voro_model` / the persistent
>     fold-sphere in `w:Voronoiology` — `Voro_todo.md §0` wave ①).  So this catalog is mostly
>      spent; keep it as the map if a fault regresses.

Owner's 2026-07-08 report on the live Voro render being brittle, plus a traced diagnosis.
 Written so each fault is **findable, fixable, and (where possible) auto-checkable**.  Companion to
  `Voro_vtuffing.md` (the render design) and `Voro_todo.md` (the crush + Book work).  The crush policy
   in `Ghost/V/Voro.g` is NOT the problem (proven below); the faults live in `src/lib/O/Cytui.svelte`.

Every claim is tagged **[V]** = I read the code and verified, or **[S]** = suspected from a trace,
 verify before relying.  Line anchors are as of this writing; grep the symbol if they drift.

## 0 · The verdict, and what to do next

**Do NOT fork Cyto+Voro yet.**  The owner asked "do we need to fork this Cyto+Voro complexity into
 its own thing? it fully seems to be hitting a tech ceiling?"  The evidence says the *ceiling is one
  file, not the architecture*:
- **The crush model (`Ghost/V/Voro.g`) is sound.** VoroScape's snap proves it: `Voro,…folded:5,count:3`
   means the crush **successfully folded 3 Artist containers** (`Voro_stamp_fold` does `count += 1` per
    container, `folded += n` per member — Voro.g:302-303; Moonlit 2 + Fernway 2 + Voxhall 1 = 5). **[V]**
     The Explore-agent's first read ("Artists fail to fold") was WRONG — they folded; they just don't
      render as cells.  So the data is NOT trapped by a crush failure.
- **The faults concentrate in the Cytui render|animate GATE** — one auto-retry race + a rebuild-all +
   a settle-timing miss.  All fixable in place.
- **The REAL ceiling is the already-documented one:** fcose is a black box we can only hint (metaphysics
   #1); the future re-home is the **owned-integrator** (`Voro_vtuffing.md` §next-moves #14 + §Owner
    vision seeds — dribble/swish).  That is the eventual "fork" (own the tick), but it is PREMATURE —
     fix the render gate first; a working pipeline is the thing #14 later takes the cage off of.

**Fix order (highest leverage first):** F1 (the render-gate race — one fix likely also cures F4 and the
 VoroScape "behind glass") → F3 (rebuild-all flashing) → F2 (settle timing).  See each below.
 **F1, F6, F2 are BUILT.  F3 was REDIAGNOSED (2026-07-12): it is NOT a paint_final bug** (the template is
  already id-keyed) **but the same identity-churn root as the new F8 (cells vanish/re-pop because `cyto_id`
   isn't linear across steps) — owned by the identity/`resolve` thread, not this catalog.**  F4/F7 ride
    F1's gate + F7's cure and are eyes-on-confirmable.  So: no independent render build is left standing —
     the remaining visible fault (vanish + re-pop) is upstream, in identity linearity.

**STATUS 2026-07-12 — F2 landed: the Run advances on the real settle now, not a blind timer.**
 The render tail finally feeds the pacing.  Cytui stamps `top_House.c.cy_settled = step_n` at the true
  morph-rest (guarded by no-flood-owed + not-mid-diag-cure), and `e_Cyto_animation_request` waits for it
   floored at the dwell, hard-ceiling'd.  `--why` proves it live: `landed step:N` before every next
    `wave`.  VoroMitosis 11/11 c10 ×3 + VoroScape 6/6 c0, fixtures unmoved (`.c`, not a `%key`).  The
     *blink-is-gone* verdict stays eyes-on (metaphysics #2).  **Next is NOT a render build** — chasing F3
      down showed the remaining visible fault (cells vanish + re-pop mid-animation) is **F8: `cyto_id`
       churn / identity non-linearity**, upstream in `resolve`, handled in another thread.  When that
        lands, re-verify vanish+re-pop are gone; only THEN weigh a distinct arrival animation.

**STATUS 2026-07-11 — ROOT-A closed at the true root; a rollback ate two instruments.**
- **F6 + the flooding-step lag FIXED — crush now runs BEFORE the scan.**  The mechanism, finally
   exact: per beat the order was *do → Cyto scan/wave → snap (story_snap's `Voro_crush_scan` per
    world)* — so the wave that ferried a newborn was computed BEFORE the beat's crush stamped it.
     Every newborn waved RAW and only the NEXT step's scan dressed it (the owner's "step 2 has all
      these nodes flood in but not cells; next step all is cells"), and the ARCHIVES baked that
       lag, so seeking replayed it forever.  Fix: `e_Cyto_commission` arms `Scannable.c.crush_wanted`
        when the commission carries `useVoroCyto`, and the pre-scan hook (`cyto_update_wave`) calls
         the new `Voro_crush_worlds(scan)` — per-world, skips `w:Voronoiology`, QUIET (story_snap
          stays the census author, so `beat=N` and fixtures are undisturbed).  The ◈ path rides the
           same helper.  **Baked proof:** VoroClinic's re-recorded `001.snap` cytowave now shows the
            wrangle upserting `overlay_kind:stuff,overlay_self` in its BIRTH wave (the old fixture
             recorded it as a classic labeled node — the fault, photographed).
- **The census stops walking machinery:** `%self` skipped like `%Opt` in both crush + report walks —
   a `cell:self` gang was a pane the canvas can never draw (classify hides self), and its transcript
    baked the self's wall-clock `%est` into fixtures (VoroRadio 4-5 red on EVERY re-run until this).
- **The flood layout under-run FIXED** (Cytui `apply()`): when newcomers outnumber settled 2:1 the
   pins are skipped (no rosette worth protecting) and a SECOND free relayout fires on layoutstop —
    the "run layout() extra times myself" the owner was doing by hand.
- **⚠ ROLLBACK CASUALTY (bisect 4add5244) — RE-ADDED 2026-07-11, live-proven:** the F7 `diag_check`
   auto-cure AND the render telemetry (`vlog`/`cy_render`, the film strip) were reverted with the
    Cytui WIP; both are back in the tree as the isolated slice (grafted verbatim from the parked
     WIP, now durable at `spec/voro_modes/Cytui.wip.2026-07-10.svelte.txt` — /tmp was volatile).
      The slice: the vlog ring + `render_snapshot` mirror, wave/armed/morph✗/morph/settle events
       + a new `flood` event (the under-run second pass, logged), `relayout` grew back its
        `randomize` third arg, `diag_check` off every settle.  LiesFunk's `op:'why'`/`'shot'` never
         left, so the rails just lit up.  **Proof on the first verification run:** VoroMitosis
          11/11 c10 (its norm) with `♒ diag cured ×1` on the `--why` reply — the satan appeared at
           exactly the Book the owner reported and was auto-cured; VoroScape 6/6 c0; fixtures
            untouched (toc diff = TimeSpool wobble only).  F7's cure-took is eyes-on-owed only.
- **All five Voro-family fixtures re-recorded green** (VoroScape 6/6, VoroMitosis 11/11, VoroRadio
   9/9 at caveat 0 — first time, the est poison is gone — VoroClinic 9/9, LeafFarm 30/30 untouched).

**STATUS 2026-07-10 — the loop is closing.**  Built that round; ⚠ the last three items below were
 since LOST in the 4add5244 rollback (see above) — kept for the designs:
- **📸 `scripts/runner_shot.mjs`** — the pixel loop CLOSED: `op:'shot'` on the runner_ask rails returns
   `cy.png()` of the live canvas, so the render checklist below is now REMOTELY runnable (run Book →
    shot → look).  Owner's "maybe I should get you a remote cli… take screenshot of the canvas".
- **F1 fix BUILT** (Cytui `apply()` tail): when a wave arms the voronoi (`saw_stuffy` flip) or first
   reaches ≥2 seeds, it now fires `reposition_overlays()` + `voronoi_soon()` — the exact sequence the
    manual ◈ off+on ran.  Expect F1, F4 and F6's render side to move together.
- **F7 (diagonal satan) detect+cure BUILT** (Cytui `diag_check`): post-settle principal-axis spread
   ratio < 0.1 ⇒ degenerate line ⇒ auto free-relayout (escalates to randomize on a stubborn repeat,
    rests after 3).  Tally rides `top_House.c.cy_diag_cures` and comes back on every `shot` reply —
     the satan is now REMOTELY detectable.
- **`w:Voronoiology` enrichment BUILT**: generic census — `%cell` row per intended pane (kind/n/pop),
   `%bare` row per unfolded-leaf mainkey, `cells:` total on the head row.  ⚠ shared-fixture change:
    every Voro* Book re-records (the census rows are new).  **The world SNAPS but is kept OUT of the
     Cyto graph layout** — it's our processing/debug C**, process-noise not data (owner, 2026-07-10:
      "that's gotta be kept out of the graph layout").  `%dontGraph` STAYS on the world line (a
       `Voro_report` re-set, corrected from an earlier mistaken strip) and `cytyle_classify` now skips
        a `dontGraph` world + its whole subtree, so enriching it can't clutter the data graph.  Snapping
         is orthogonal (the separate `%dontSnapVoronoiology` is what would hide it from fixtures).
- **RENDER TELEMETRY BUILT** (owner: "an over-time data dump of what's processing the graph into cells…
   a less minimal w:Voronoiology").  The catch it forced into the open: render processing is RENDER-side,
    so it can NEVER be the snapped w:Voronoiology (metaphysics #2).  So it's the **Cyto twin of reactap**
     — a bounded ring (Cytui `vlog`: wave / armed / remorph / morph / settle / diag, each stamped `dt` ms
      from the last layout settle) surfaced over the runner_ask rails: `op:'why'` + on every `shot` reply.
       `node scripts/runner_shot.mjs --why` prints the gate (voronoi_on/seeds/cells) + the film strip.
        A `wave stuff:0` every beat = an empty world (see below).
- **STALE-GEN BUG FOUND + FIXED** — the "w:VoroScape is just self" snap + the `!method: VoroScape`
   console flood were ONE bug: the regroup committed a PARTIAL `gen/Story/Voronation.go` (185 lines for a
    606-line source — no VoroScape/VoroClinic/Botany_plant), so the runner loaded a Voronation ghost
     missing VoroScape → the Book never drove → empty husk.  Recompiled → 675-line complete gen.  The
      residual `!method: Voronoiology` (an inert report world, no drive method by design) is now
       `V.beliefs`-gated in Housing (was the only ungated one).  Lesson: after a .g regroup, recompile
        EVERY moved .g; the render telemetry's `wave stuff:0` catches the husk faster than the console.

### 0.1 · "Does the crush need to complexify?" — the observability answer

The owner asked, adversarially, whether this algorithm really won't need to grow more sophisticated —
 whether the crush is *done*.  This turn is the answer, and it's not the one either of us reached for.

I built a "generic census" — `Voro_report` walking the crushed tree, emitting one `%cell` row per pane
 the crush intends — confident that the thing under doubt was *the model's mirror*.  It narrated an empty
  world.  Not because the census was wrong (it was correct), but because the real fault was **upstream in
   the gen**: a stale partial `Voronation.go` meant the Book never drove, so the crush ran on nothing, so
    the census dutifully reported `cells:0 bare:self`.  Every layer was truthful; the whole read as
     nonsense.  **A sound instrument pointed at a corpse is indistinguishable from a broken instrument.**

That is the load-bearing epistemics, and it's why the answer to "is the crush done?" was *unaskable*
 before this turn: from a single snap you cannot separate the three states that matter —
- the crush **ran and produced nothing** (a genuine algorithm gap — the case that would justify complexifying),
- the crush **never ran** (upstream/gen fault — the stale-gen husk),
- the **report itself is wrong**.
All three snap the same near-empty world.  The census can't tell them apart because the question isn't
 about a *state*, it's about a *process over time* — model → layout → seed → morph → settle → re-morph.
  And that process is **render-side, which never snaps** (metaphysics #2).  The census is model-side and
   single-beat; the entire dynamic half of the machine was dark to fixtures *by construction*.  No amount
    of census sophistication reaches it — you cannot snap your way to it.

So the render telemetry isn't a nicety; it's the flashlight for the half that can't snap.  It's the Cyto
 twin of reactap for exactly the reason reactap exists: an over-time, render-side, never-snapped signal
  that only a live tab can produce.  `wave stuff:0` every beat is the empty-world tell — it separates
   "the pipeline is churning but yielding no cells" (algorithm) from "nothing is arriving" (upstream) at
    a glance.  On the first `--why` poll it would have screamed *husk* and saved the census's blushes.

**The answer to the adversarial question, then, is neither "done" nor "it needs feature X."**  It's that
 the crush's sufficiency is now an **empirical** question I can finally ask — and that complexification
  must be *earned by the film strip, not guessed*.  Each catalog fault is a candidate "maybe it needs to
   be smarter," and each now has a signature in the strip: morphs firing but `cells:0` ⇒ the **gate**
    traps data (F1/F6), not the algorithm; morphs never firing ⇒ **upstream**; cells landing on a line ⇒
     **F7**, a layout degeneracy, not a crush one.  A future "the crush must complexify" claim now has to
      first produce a strip where the crush *ran, celled, and celled wrong* — otherwise it's the
       empty-world illusion again, a confident report on a dead pipeline.  The turn's real deliverable is
        that the debate has a referee.  It extends this repo's one law — *don't trust a green you can't
         see* — from the snap layer (fixtures, the headless-ban) to the render layer, the last dark half.

**Auto-checkability, honestly:** render pixels can NEVER be Book-gated (metaphysics #2 — nothing
 render-side snaps).  But the CRUSH INTENT is fully snappable (`w:Voronoiology`).  The plan (§Auto-check)
  is: (a) enrich `w:Voronoiology` so the snap says *what the crush intended to cell* (per-fold kind/n/
   would-be-seed); (b) a diagnostic Book asserting crush invariants; (c) the render's realization of that
    intent stays an **eyes-on** checklist (§Eyes-on gauntlet).  The snap-vs-eyes GAP is exactly the
     un-automatable seam — name it, don't pretend to close it.

## Shared roots (most faults are two bugs wearing six hats)

- **ROOT-A — the render-gate race (no auto-morph-retry).** Cells seed ONLY from `stuff_mounts` (nodes
   with a mounted Stuffing overlay) and need **≥2** of them: `voronoi_layout()` returns null if
    `seeds.length < 2` (Cytui:1442) or `!voronoi_on` (1417). **[V]**  `voronoi_on = voronoi_pref ??
     saw_stuffy` (734). **[V]**  On the AUTO path, `saw_stuffy` flips true DURING `apply()` as chunks
      upsert, but nothing re-runs the voronoi morph once seeds exist.  The MANUAL `toggle_voronoi()`
       (1337-1355) **[V]** does the missing work: it imposes the crush if `!saw_stuffy`
        (`i_elvisto Cyto_crush {on:1}`), then `relayout(300)` + `reposition_overlays()` +
         `morph_voronoi()` — forcing cells to appear.  **That gap IS "cells don't render until I toggle
          ◈".**  Fix: when `saw_stuffy` transitions false→true (or when `stuff_mounts` first reaches ≥2),
           auto-fire `voronoi_soon()`/`morph_voronoi()` the same way the toggle does.
- **ROOT-B — paint rebuilds everything every frame.** `paint_final()` rebuilds the whole `vcells[]`
   and `vmicro[]` arrays on every call (per morph frame AND per drag frame), keyed only by id, with no
    content-diff. **[S]**  So unchanged cells re-enter/re-animate — the "everything flashes like it's
     popping into existence when it's just sitting there."  Fix: diff by (id, content-sig, geometry) and
      skip untouched cells; only a genuinely new/changed source should animate in.

## The fault catalog

### F1 — cells don't render until you toggle ◈ off+on  *(ROOT-A)*
- **Owner:** "everything is Stuffing and the cells don't render… unless I switch off+on the cells-render
   button."
- **Chain [V for the gate, S for the auto-trigger]:** auto path stamps chunks → `saw_stuffy` true →
   but no re-morph → `voronoi_layout` either already returned null (had <2 seeds a beat ago) or was never
    re-run → no `vcells` → template renders nothing (Cytui ~2559 `{#if vcells.length}`).  Toggle forces
     `morph_voronoi()` (1354) → cells appear.
- **Auto-checkable?** No (pixels).  But ROOT-A's *seed count* is derivable: `w:Voronoiology` could report
   `would_seed:N` (chunks the render WOULD cell); a Book asserts N≥2 for a data Book, and if the render
    then shows 0 cells, the fault is localised to the gate.

### F2 — the Run advances on a fixed timer, not the render's real settle  *(timing — BUILT + live-verified 2026-07-12)*

**BUILT 2026-07-12 — the Run now advances on the render's REAL settle, floored at the dwell.**  The
 seam was exactly as diagnosed below.  What landed:
- **Cytui stamps `top_House.c.cy_settled = wave.sc.step_n`** the moment the render for that step is truly
   at rest — a new `mark_settled()` called from every morph-rest point (`morph_voronoi`'s three exits +
    the non-voronoi `show_overlays_soon` reveal + the diag heal).  It gates on *morph done AND no flood
     2nd-pass owed (`flood_pending`, set when the flood queues its 2nd relayout, cleared on that
      relayout's layoutstop) AND `diag_streak===0` (not mid diagonal-satan cure)* — the exact "I've
       landed" condition below.  Keyed off `step_n` (already on every wave, Cyto.svelte:245), so a stamp
        means "the render for *this* step landed."  Live `.c`, never snapped (metaphysics #2).
- **`e_Cyto_animation_request` (Cyto.svelte) awaits that stamp** instead of the bare `grawave+dwell`
   timer: `max(real-settle, dwell)` with a hard **ceiling** (`dur+DWELL+3000`) so a render that never
    stamps can't wedge the Run.  The dwell stays as a FLOOR — a calm step keeps its unrushed beat.
- **Live-verified** (per §0 laws, never headless): the `--why` film strip now shows a `landed step:N`
   event that lands BEFORE the next `wave` on every step (the win the diagnosis predicted — wave→landed
    ≈1.2s, then advance; no more advancing mid-morph).  VoroMitosis 11/11 c10 ×3 + VoroScape 6/6 c0,
     robustly green across re-runs (the timing-fix gate).  **Fixtures did NOT move**: zero VoroMitosis
      `NNN.snap` changes, toc diff = TimeSpool wobble only (`cy_settled` is `.c`, never a `%key`).
- **Still eyes-on-owed** (metaphysics #2 — a still can't see motion): the *blink is gone* judgement.  The
   strip proves the Run waits for the landing; only a human watching confirms the pane no longer shows
    Stuffing-first.  F3 (the paint_final `vsubs` wholesale rebuild) is the remaining half of the blink —
     unbuilt; see below.

--- *(the original diagnosis, kept — it's the map if F2 ever regresses)* ---

A self-contained slice for a fresh agent.  Diagnosed to the exact seam this turn; the crush already
 obeys the runtime, the render tail does not.

- **The human, framed exactly:** "doesn't wait anywhere near long enough for the Voro to get settled
   in… the text overlay blinks invisible at the end of the morph, and at step 3 they all show as
    Stuffings before becoming vtuffings + take extra time."  And the load-bearing hunch: *"H%Run isn't
     allowed to think while Story isn't having its runtime — is that understood by Voro?"*
- **The answer [V]:** the CRUSH understands it — it runs inside `cyto_update_wave`, awaited before
   `Cyto_wave_done`, so it thinks in-beat.  The render SETTLE does not.
   - `e_Cyto_animation_request` (`Cyto.svelte:1379`) releases the Run with `Cyto_animation_done` on a
      FIXED timer: `setTimeout(grawave_duration + DWELL_MS(750) + 100)` (1397-1401).
   - the render's morph (`MORPH_MS`), overlay reveal (`OVERLAY_QUIET_MS`), `diag_check` (1200ms) and —
      the killer — the FLOOD's second relayout (`setTimeout(relayout, 80)` on layoutstop, `Cytui.apply`)
       all run on their OWN clocks; NONE feed `animation_done`.
   - so on a flood step the Run advances mid-settle → every pane re-mounts Stuffing-first and blinks
      (paint_final rebuilds `vsubs` wholesale at morph end — F3).  The tail spills past the beat: that
       IS "thinking outside the runtime."
- **The fix:** the fixed dwell becomes a real settle SIGNAL.
   - the render tells Cyto "I've landed" = morph done AND no flood relayout pending AND `diag_streak`
      clear; THAT drives `Cyto_animation_done`.  A flood step then waits for its 2nd relayout, a calm
       step advances promptly, and the Run never advances into a blink.
   - KEEP the dwell as a FLOOR, not the gate (the unrushed-story pacing is deliberate — the `waitVoro`
      +2s history): wait for `max(real-settle, dwell)`, with a hard ceiling so the render never hangs
       the Run if it never settles.
- **The seam to build:**
   - Cytui already has the settle points — morph end (`settle_overlay_show()` ~2409), `layoutstop`, the
      `diag_check` quiescence — and already stamps `top_House.c.{cy,cy_render,cy_diag_cures}` (the
       op:'shot'/'why' channel).  Add a `render_settled` latch on the same channel, e.g.
        `top_House.c.cy_settled = story_step` (live `.c`, NEVER snapped — metaphysics #2).
   - `e_Cyto_animation_request` awaits that stamp (poll or a tiny event) instead of the bare timer,
      preserving its existing gates (`supports_takeTurns` @1383, `w.c.wants_animation_done` @1398).
   - compounding cleanup (F3, optional but it's the actual blink): stop paint_final rebuilding `vsubs`
      wholesale — diff by (id, content-sig) so an unchanged pane doesn't re-pop.  Kills the blink even
       before the timing lands; the two reinforce.
- **BOMBS:** verify LIVE only (a still can't see a blink) + fixtures MUST NOT move (the signal is
   `.c`/`$state`, never a `%key`).  Never HMR mid-run.  Do NOT delete the unrushed pace — a watched run
    must still read as a story, not a flipbook; the fix is "wait for real settle, floored at the dwell",
     not "advance the instant the morph ends".
- **Auto-checkable?** No (pixels/timing) — eyes-on; the `--why` film strip confirms the win: the last
   morph/settle event's `dt` should land BEFORE the next wave, not after `animation_done`.

### F3 — cells flash / re-pop when nothing changed; can't tell a NEW node arriving  *(REDIAGNOSED 2026-07-12 → F8, the identity root)*
- **Owner:** "everything acts like it's changing (cells flash like they're popping into existence when
   they're just sitting there)… hard to tell that a new track is coming in."
- **The [S] chain was WRONG — verified 2026-07-12.**  ROOT-B blamed `paint_final()`'s wholesale
   `vcells[]` rebuild ("no content diff → every cell re-mounts").  But the template is **already keyed by
    id** (`{#each vcells as cell (cell.id)}` Cytui:3083; same for vtips/vfams/vsubs) — Svelte reconciles
     by key, so a cell whose id PERSISTS is updated in place, never re-mounted, no matter how many fresh
      arrays `paint_final` assigns.  A `paint_final` content-diff would therefore fix **nothing**.  This
       is a §0.1 illusion caught in the act: a confident render-layer report on a defect that lives a
        layer up.
- **The real chain [V]:** the "pop" is `morph_voronoi` **birthing** — a cell whose `cyto_id` is NOT in
   `shown_pts` grows from its seed point (Cytui:2393-2396 BIRTH branch); one already there MORPHS from its
    prior shape.  So a cell re-pops **iff its id changed** — i.e. the SAME identity churn as the vanish
     (F8).  When `resolve` can't link a particle to its prior `cyto_id`, it dies under the old id (vanish)
      AND births under the new (re-pop): one root, two symptoms.
- **Fix:** NOT here — it's **F8 / the identity thread**.  Once `cyto_id` is linear across steps, a
   persisting cell keeps its key → morphs smoothly → the re-pop dissolves with the vanish.  DON'T build a
    `paint_final` diff (a non-fix that would collide with the identity work).  Re-assess any residual
     re-pop only AFTER F8 lands; only THEN is "make a genuinely-new arrival legibly distinct" (the
      dribble-in-from-a-Pier vision) a real, separable render task.
- **Auto-checkable?** The id-stability IS snappable off the archive (does a persisting particle keep its
   `cyto_id` step-to-step?) — that's the F8 gate, model-side.  The pixels stay eyes-on.

### F8 — cells VANISH mid-animation: the same entity dies + re-borns instead of morphing  *(identity linearity — ANOTHER THREAD 2026-07-12)*
- **The human (2026-07-12):** the vanishing problem "is exactly when cells are doing their vanishing
   animation… which doesn't really account properly for identity linearity or reidentity or
    `TheC.resolve()` — we're working on that in another thread."
- **Chain [V for the render seam, the root is upstream]:** `morph_voronoi` decides death purely on id
   presence — "a shown cell with no target shrinks to its own middle" (Cytui:2390-2396).  A cell's key is
    its `cyto_id = Dip_assign('cytoid', D)` (Cyto.svelte:961); Dip_assign **allocates a FRESH identity**
     when a particle's `D%*` trace is "ambiguous to `Stuff.resolve()`" (Cyto.svelte:438-439, in-code
      note).  So a persisting entity whose trace doesn't resolve back gets a new `cyto_id` each scan →
       old id has no target (DEATH/vanish) + new id has no `shown_pts` prev (BIRTH/re-pop = F3).
- **Why the render can't fix it:** the morph has no way to know a "death" is really a re-id — that
   linkage IS `resolve`/identity-linearity, upstream of Cyto.  A render-side heuristic (e.g. only vanish
    when the cyto NODE was actually removed, not merely re-keyed) is a palliative; the true fix is linear
     identity so the id never churns.  **Owned by the identity/resolve thread — not this catalog.**
- **The fix's home (the identity thread):** designed in `Voro_vtuffing.md §🎋 "Se — the grasp"` — a
   persistent fold-sphere resolved beat-to-beat, anchored to a durable source identity (container +
    family, not the volatile rep), living in `w:Voronoiology` (snapped, so `cyto_id` linearity is
     gate-able there).  The census storm in that doc is the SAME root, downstream in the snap instead of
      the render; the crush re-deriving its folds from scratch each beat is *why* resolve goes ambiguous.
- **F2 is orthogonal:** F2 fixed *when the Run advances* (it now waits for the morph — including the
   death tween — to land); it does not and cannot stop a spurious death from being queued.
- **Auto-checkable? YES, model-side:** assert `cyto_id` stability across a step for a particle known to
   persist (readable off the CytoStep archive, no pixels).  That invariant is the F8 gate; the smooth-
    morph *look* stays eyes-on.

### F4 — seeking backward → ⅔ Stuffings; seeking forward → breaks cells, all Stuffing  *(ROOT-A)*
- **Owner:** "seeking backwards produces 2/3rds Stuffings, seeking forwards breaks cell rendering and
   makes everything a Stuffing."
- **Chain [S]:** `apply()` resets `saw_stuffy=false` on an absolute wave; a seek to a wave whose crush
   footprint differs (or that arrives before the render-side crush re-stamps) leaves `<2` seeds →
    `voronoi_on` false → cells vanish, everything falls back to Stuffing/bare.  Same ROOT-A gap as F1:
     no auto-re-morph once the new wave's chunks exist.
- **Auto-checkable?** Partially — the crush footprint per step IS in `w:Voronoiology`; a Book can assert
   the fold count is stable across a seek.  The render fallback is eyes-on.

### F7 — the diagonal satan: the whole board collapses onto one line  *(fcose degenerate equilibrium)*
- **Owner (2026-07-08):** "VoroClinic animates full-on-one-thing violently, finally collapses in the
   diagonal satan, which we should be able to detect and delineate (because it seems perfectly balanced
    and doesn't disrupt when we layout()) and layout() away."
- **Chain [V for the mechanism class]:** fcose settles into a 1-D line — a symmetric saddle: every force
   cancels ALONG the line so nothing pushes a node off it.  The `fresh_ids` pins (the earlier "de-diagonal
    from lone adds" fix) prevent the classic *trigger* (late disconnected adds re-packing the board) but
     don't cure a collapse that forms anyway; it sat until a manual ⟳.
- **FIXED (built 2026-07-10, verify live):** `diag_check` on every layout settle — covariance
   minor/major spread ratio (√): ~0 = line, ~1 = disc, healthy rosette > 0.25, gate at 0.1.  Cure =
    the owner's own observation, a free `relayout()`; a repeat escalates to `randomize` (break the
     symmetry); 3 failed cures rest until the board changes.  Guarded off drags and mid-batch.
- **Auto-checkable? YES — the exception in this catalog:** geometry is readable off `cy` without
   snapping anything.  `diag_cures` rides every `shot` reply (`♒` in the CLI line); a Book-run-then-shot
    showing `diag_cures:0` = the satan never appeared; >0 = appeared AND was cured (eyes confirm the
     cure took).

### F6 — VoroScape data "trapped behind the glass" (only see+req cell)  *(ROOT-A, render-side)*
- **Owner:** the snap shows 3 Artists / 5 Tracks + `folded:5,count:3`, "yet only see and req are cells…
   all that legitimate data is just nodes trapped behind the glass."
- **Chain [V]:** the crush DID fold all 3 Artists (count:3/folded:5 — Voro.g:302-303).  So 3 `c.stuff`
   chunks were stamped.  `see` cells via the PROPER path (`PROPER_KINDS={'see'}`, separate from the
    crush); that path works.  The 3 Artist chunks are NOT reaching the render's `stuff_mounts`, so
     `voronoi_layout` never seeds them → behind-glass.  **[S] for the exact break:** the imposed crush
      runs at SNAP time (Story-side) and `c.stuff` is c-side (unsnapped), so it does not cross to the
       render tab; the render tab's own crush-commission apparently isn't stamping VoroScape's tree on
        the auto path (the ◈ toggle imposing the crush is the tell — it forces the render-side stamp the
         auto path skips).  Confirm by logging `stuff_mounts.size` on a VoroScape load vs after a ◈ toggle.
- **Auto-checkable?** The crush intent is (folded:5 is already in-snap).  The render realisation is not.
   The MISMATCH (5 intended, 0 celled) is the un-automatable gap — hence the enrichment + eyes-on split.

## The model — bare node vs Stuffing vs Vtuffing vs cell (owner's "what's what")

| What | Is | Earned by | Decided at |
|---|---|---|---|
| **bare node** | a plain Cyto node (dot + label) | any particle the walk keeps but doesn't fold/mount | `cytyle_classify` (Cyto.svelte) |
| **Stuffing** | a *molded* overlay skewed into a shape — "the glass"; occludes | a node with `c.stuff` (a fold chunk) OR a proper loner (`%see`) that gets an overlay mounted | `create_stuff_overlay`, `stuff_mounts` (Cytui ~574) |
| **▦ sub-graph** | the pane tessellating ITSELF — nucleus + tuple regions + member cells, speaking Stuffing's grammar | same `c.stuff`/`c.gang` particle when `subgraph_on` (the ▦ toggle; the old ▤ row-card face is DELETED 2026-07-11) | `paint_final` ▦ pass / `subgraph_build` |
| **cell** | a Voronoi polygon | a `stuff_mount` node, when `voronoi_on` AND `≥2` such seeds exist | `voronoi_layout` (Cytui:1416-1442) **[V]** |
| **🎋 bamboo** | a Vtuffing whose rows are a jointed `%Vseg` stalk + live Se emphasis | `Cyto_bamboo` stash on + a Vtuffing | `Vtuff_bamboo`/`Vtuff_se` (Voro.g); flatten in `vtuff_rows` |

**The load-bearing rule:** *a particle becomes a CELL only if it becomes a `stuff_mount`.*  A fold chunk
 (`c.stuff`) SHOULD, a proper loner (`%see`) does, everything else stays bare/behind-glass.  F6 is a
  particle that *should* be a stuff_mount (it's `c.stuff`) but isn't reaching the render as one.

## Auto-check plan (serving "check they're not happening automatedly… w:Voronoiology a bit more")

1. **Enrich `w:Voronoiology` — BUILT 2026-07-10** (`Voro_report`/`Voro_report_walk`, Voro.g; owner
    licensed by un-hiding the world + "feel free to expand it").  The census is GENERIC now (was
     Botany-locked — a music world's stations|Artists never made a row): one `%cell` row per pane the
      crush intends (`kind:pane|gang`, `n`, `pop`), one `%bare` row per unfolded-leaf mainkey, and
       `cells:N` on the head row — the snap SAYS "the crush wants N cells here"; a canvas showing fewer
        is render debt, F6 made legible in ANY world.  *(Shared-fixture change — every `Book:Voro*` +
         `useVoroCyto` Book re-records; owed on the next live-runner session.)*
2. **A diagnostic Book `VoroClinic` — BUILT + live-verified 2026-07-08** (`Ghost/V/Voro.g`, brand_new
    in Credence).  Stands up two folded libraries + a noisy gang, runs the crush, and asserts three
     crush invariants with `%see` — ALL FIRE GREEN on the live runner: (1) a container of four folds to
      one chunk carrying `fold_n===4`; (2) four scattered leaves gang behind one rep with three
       `represented`; (3) the crush intends ≥3 cell chunks "a render that shows fewer is trapping data
        behind glass."  This is the automated proof the CRUSH is sound → **F6 and friends are render-side.**
         (Fixtures brand_new/unrecorded — accept with eyes on.  A fresh-Book toc-expand race collapsed
          the toc to 1 step on first run; the SECOND run cleared it — a known `toc-clobber-expand-race`.)
3. **The render realisation stays the §Eyes-on gauntlet** (below) — a fixed manual checklist, because
    metaphysics #2 forbids the render from snapping.

## The gauntlet (now mostly SHOT-runnable — was eyes-only)
`runner_shot.mjs` closed the pixel loop: run a Book, `node scripts/runner_shot.mjs shots/<name>.png`,
 LOOK at the png.  Still-frames catch F1/F6/F7 and the F4 end-states; MOTION quality (F2 pacing,
  F3 flashing) stays genuinely eyes-on — a still can't see a flash.
- [ ] cells appear on FIRST load without a ◈ toggle (F1) — 📸 shot after `run <Book>`
- [ ] a data Book's folds each show a cell, not behind-glass (F6) — 📸 count panes vs the snap's `cells:N`
- [ ] no diagonal satan, or cured (F7) — 📸 `♒` tally on the shot line + the png isn't a line
- [ ] seeking ←/→ keeps the cell/Stuffing classification stable (F4) — 📸 shot at n, n-1, n again
- [~] auto play-through settles between beats like manual seeking does (F2) — 📊 `--why` PROVES the Run
   waits for `landed step:N` before the next `wave` (built 2026-07-12); 👁 the unrushed *feel* stays eyes-on
- [ ] an unchanged cell does NOT re-pop or vanish each beat; a NEW track visibly arrives (F3=F8, identity
   linearity) — 📊 assert `cyto_id` stable across a step (model-side, off the archive) + 👁 the smooth morph

## Anchors touched while diagnosing (verify if drifted)
`Cytui.svelte`: `voronoi_layout` 1416-1442 · `voronoi_on`/`saw_stuffy` 734 · `toggle_voronoi` 1337-1356 ·
 `stuff_mounts` seeds 1426 · `vtuff_rows`/`micro_fit` ~955/1012 · `paint_final` ~1724 · `process_queue`
  timing ~2306.  `Voro.g`: `Voro_stamp_fold` 295-304 · `Voro_gang_fold` 227-263 · `Voro_crushable` 339-354
   · `Voro_crush_walk` 139-212 · `Voro_report` 89-131 · `Voro_drift_tick` 845-877.
