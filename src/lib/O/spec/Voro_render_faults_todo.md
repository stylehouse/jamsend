# Voro_render_faults — the render|animate pipeline fault catalog

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

**STATUS 2026-07-10 — the loop is closing.**  Built this round, ALL awaiting a live-tab verify (the
 runner tab must be RELOADED once so Cytui remounts + the cy stash lands):
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
- **`w:Voronoiology` enrichment BUILT** (owner licensed it by un-hiding the world 2026-07-09):
   generic census — `%cell` row per intended pane (kind/n/pop), `%bare` row per unfolded-leaf mainkey,
    `cells:` total on the head row.  Report world also GRAPHS now.  ⚠ shared-fixture change:
     every Voro* Book re-records (world line loses `dontGraph`, rows change shape).
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

### F2 — animation doesn't wait for the Voronoi to settle  *(timing)*
- **Owner:** "animation is poked as, doesn't wait anywhere near long enough for the Voro to get settled
   in… animation can be nice once you're seeking on your own (giving it enough time between moves to
    animate+compute+render+computemore)."
- **Chain [S]:** batched waves use `BURST_DUR ≈ 0.16s` for the fcose relayout, but fcose needs longer to
   converge; the voronoi is computed from unsettled positions, and the next wave fires after a fixed
    `pad` rather than waiting on fcose convergence.  Manual one-at-a-time seeking "feels nice" precisely
     because the human supplies the settle time the auto-cadence doesn't.
- **Note:** this is the #11 `waitVoro` cadence (Voro_todo §0 LANDED) not going far enough — it waits for
   the *morph tween* but not for *fcose convergence*.  Fix: sense fcose settle (layoutstop / a movement
    threshold) before starting the morph and before releasing the next wave; make the auto-cadence match
     the "seeking on your own" pace.
- **Auto-checkable?** No (timing/pixels) — eyes-on.

### F3 — cells flash / re-pop when nothing changed; can't tell a NEW node arriving  *(ROOT-B)*
- **Owner:** "everything acts like it's changing (cells flash like they're popping into existence when
   they're just sitting there)… hard to tell that a new track is coming in."
- **Chain [S]:** `paint_final()` rebuilds `vcells[]`/`vmicro[]` wholesale each call; no per-cell content
   diff, so every cell re-mounts/re-animates.  A genuinely-new arrival is drowned in the universal
    re-pop.
- **Fix:** diff cells; animate ONLY changed/new ones (and make "new" legibly distinct — a distinct
   arrival animation vs the settle jitter).  This directly serves the owner's "dribble in from a Pier"
    vision — a new track should visibly *arrive*, not be lost in noise.
- **Auto-checkable?** No (pixels) — eyes-on.

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
| **Vtuffing** | the *row-fitted* successor to the molded Stuffing — members distilled to rows chord-fit to the cell | same `c.stuff` particle, but drawn as `vmicro` rows when `vtuffing_on` (the ▤ toggle, Cytui:914) | `paint_final` vtuffing branch |
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
- [ ] auto play-through settles between beats like manual seeking does (F2) — 👁 eyes-on
- [ ] an unchanged cell does NOT re-pop each beat; a NEW track visibly arrives (F3) — 👁 eyes-on

## Anchors touched while diagnosing (verify if drifted)
`Cytui.svelte`: `voronoi_layout` 1416-1442 · `voronoi_on`/`saw_stuffy` 734 · `toggle_voronoi` 1337-1356 ·
 `stuff_mounts` seeds 1426 · `vtuff_rows`/`micro_fit` ~955/1012 · `paint_final` ~1724 · `process_queue`
  timing ~2306.  `Voro.g`: `Voro_stamp_fold` 295-304 · `Voro_gang_fold` 227-263 · `Voro_crushable` 339-354
   · `Voro_crush_walk` 139-212 · `Voro_report` 89-131 · `Voro_drift_tick` 845-877.
