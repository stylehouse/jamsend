# Attractor_todo — the Attractor Ground

The ▦ layer of Cytui as a competition ground: rival FACES draw the same live glass, and a
 judge tunes + flips between them without a rebuild.  Written to be picked up COLD.  The
  render substrate is `Cytui.svelte`; the data model behind it is `Voro_todo.md` §0.

## 0 · Handover  (rewrite this section each handover)

**THE ARC.**  The Voronoi glass grew a pile of render experiments — tuples, star, ϕ (the
 golden lettering) — each a different way to SAY the same distilled particles.  They kept
  fighting over one code path.  The Attractor Ground makes that legible and cheap: the
   HARNESS owns the invariants (the data — Vtuffing descs; the geometry — hull/clip/chords;
    the plumbing — spell/telemetry/stash), and a FACE is nothing but a builder from
     `(cells, descs, KNOBS) → layers`.  Faces ADD, they never REPLACE the harness.  A knob
      is a live number; a MOMENT is a named (face + knob overrides) snapshot, so a judge can
       flip between entries on the SAME live data mid-session and decide with their eyes.
        DESTINATION: many faces on the ledger, each revivable, tuned against real music data,
         the winners promoted — a warping data-landscape the human can steer live.

**WHAT LANDED (2026-07-17).**  Knobs + moments + the render-time-blanking re-cleave (below).
 The zone_seat clip is fixed; the spell runs under ϕ again (crater structure returns to small
  cells).  Everything reachable over the existing face op (`runner_shot --arm --face=...`).

**ϕ v2 LANDED (2026-07-17, render-only).**  The golden lettering rebuilt to the human's steer
 (Voro_todo §0 PART 11): the spiral POLE moved OFF-SCREEN (`phi.pole_dist`/`phi.pole_ang`) so
  every groove is a gentle near-parallel smile-arc; a cell claims as ONE C-BLOCK (title whole on
   one line, children indented below on adjacent grooves — `phi.indent`); pathids went
    DETERMINISTIC (`vphi-<cellid>-<slug>`) + a `phi_prev` hysteresis map re-seats each label in
     place → the post-drag BLINK is fixed and ϕ streams LIVE under drag (`phi.livedrag`); text is
      now GAP-SIZED (biggest fs that fills the free gap, `phi.fsceil`/`phi.fsfloor`, two-groove
       titles via `phi.titlegrooves`) — "really max it out"; the title arc is the DRAG HANDLE for
        the cyto node (mirrors the pane identity).  Census gained `held`/`moved` (excluded from the
         change-sig).  EYEBALL when live: (1) grooves gentle not tight-turned; (2) 'Artist name:Vox'
          on one line, Track children indented below; (3) NO blink after a drag; (4) text bold/big,
           folds where it truly won't fit — not tiny text everywhere.  Pixels still OWED (runner
            engaged elsewhere; verified svelte-check-clean only).

**NEXT MOVES (a few vague candidates).**
- Face builders as SEPARATE modules — right now `phi_build`/`tuple_pane`/`crater_pane` are
   functions in one file; a face wants to be a registered `(cells,descs,knobs)→layers` entry so
    a new one is an ADD, not a surgery.  This is the real shape the harness is reaching for.
- An in-tab KNOB DRAWER — a small UI (O/ui/micro bits) to nudge a knob and watch the glass, so
   the human tunes without the ask rails.  Prototyping-only; keep it out of the streaming grid.
- Moments as COMMITTED JSON — export the winning `{face, knobs}` to a doc the human commits, so
   an entry survives past a browser's stash.  Today a moment lives only in `H.stashed`.
- Resurrecting a BURIED face = registering it as a NEW face off the ledger `spec/voro_modes/
   README.md` (commit anchors + SVG shots; `git show <commit>:src/lib/O/Cytui.svelte`).  A dead
    face is not gone, it's un-registered.

## The frame — harness vs face

- **The harness owns the INVARIANTS.**  The Vtuffing descs (what each cell says, mainkey-blind),
   the geometry primitives (`wide_chord`, `poly_chord`, `power_cells`, `clip_halfplane`,
    `chaikin`), the growth SPELL (grows starved cells — reads pane stats as DATA), the telemetry
     (`vlog('vsub')`), and the stash (per-tab prefs).  A face never re-implements these.
- **A face is a BUILDER.**  `(cells, descs, knobs) → layers` (walls, stats, arcs, ties).  `tuples`
   = snap-notation rows in each cell; `star` = the radial gem; `phi` = one groove spiral over the
    whole glass, lettering blind to cell walls (the glass beneath is underpainting).
- **RENDER-TIME BLANKING (the 2026-07-17 re-cleave).**  Faces used to blank their rivals at BUILD
   time (ϕ nulled `pane.stats`), which starved the spell → cells never grew under ϕ.  Now every
    face BUILDS its data always; the markup gates which layers PAINT (`{#if vsub_face !== 'phi'}`
     round the pane stats).  So the spell reads real sizes on every face → structure survives.

## The knob table  (name = default — what it moves)

- `phi.pitch`     = 17    groove spiral pitch px (label fs capped below it)
- `phi.reach`     = 2.2   per-label distance budget factor in `reach*G + 70`
- `phi.cap`       = 9     labels a resting cell may claim (rest fold to +N)
- `phi.boostcap`  = 22    labels a boosted (chip-clicked) cell may claim
- `phi.pole_dist` = 2.5   spiral pole displacement OFF-SCREEN, in bbox half-diagonals (grooves stay gentle)
- `phi.pole_ang`  = 90    pole bearing deg from bbox centre (90 = straight down → smile-arcs stacked)
- `phi.indent`    = 1.5   child line indent under the title, in em of the title fs (a treeing indent)
- `phi.sticky`    = 1.6   a HELD label may sit this × its normal budget before it must re-seat (hysteresis)
- `phi.livedrag`  = 1     rebuild ϕ live under a drag (0 = freeze mid-drag, the old behaviour); >400 labels freezes anyway
- `phi.titlegrooves` = 2  grooves a title may span for a bigger fs cap (child lines stay single-groove)
- `phi.fsceil`    = 26    gap-sized fs ceiling (a line never grows past this)
- `phi.fsfloor`   = 9     gap-sized fs floor — a line that can't reach this FOLDS rather than shrink smaller
- `crater.rmin`   = 24    min cell radius R to draw a legible C-crater (below → flat)
- `crater.hfloor` = 9     min identity fs to crater (a tiny name reads flat)
- `zone.groupmax` = 5     max atoms per zone before it chunks into sub-zones
- `zone.fsfloor`  = 10.5  a splittable zone landing below this splits at its tag|name seam
- `zone.fsceil`   = 24    per-row font-size ceiling
- `zone.identw`   = 3     identity zone weight (its share of the cell height)
- `zone.roww`     = 1.5   a content row's zone weight
- `spell.floor`   = 12    load-bearing atoms below this read as starvation → grow
- `spell.grow`    = 1.18  per-beat grow multiplier on a starved cell
- `spell.decay`   = 0.93  per-beat shrink multiplier on a clearly-oversized cell
- `spell.cap`     = 3.0   ceiling on a cell's growth multiplier
- `spell.roomy`   = 0.42  content-fills-below-this fraction = "roomy" → the spell eases off

A knob registers its default on first read (`vknob('name', def)`), and an override rides
 `H.stashed.Cyto_knobs` across reloads.  Read a knob ONCE at the top of its function into a
  local — never per-iteration; the hot paint paths depend on it staying a single map read.

## The op rails  (extend the same face op — runner_shot `--face=` passes a JSON object)

- `--face=knob:phi.pitch=20`     set one knob (=default → deletes the override); unknown name is
                                  refused (a typo can't invent a knob), persisted, repaints.
- `--face=knobs:1`               return the whole table `{name: {def, val}}`.
- `--face=moment_save:cradle-v1` snapshot `{face, knobs}` under that name.
- `--face=moment_load:cradle-v1` restore face + knobs (missing name → error string), persist.
- `--face=moment_list:1`         return `{name: {face, nknobs}}`.
- `--face=moment_drop:cradle-v1` delete it.

Moments live in `H.stashed.Cyto_moments`; the normal face return gains `knobs: <n overrides>`.

## Crater why-not telemetry

`crater_pane` returns null "sometimes" — the human asked why.  It now bumps `crater_skips`
 (`{small, header, geo, nofold}`) at each null and `crater_ok` on success, reset per paint.
  The `vsub` census carries `crater: {ok, small, header, geo, nofold}` on the tuples/phi faces
   whenever a counter fired, so `--why` says exactly why an Artist lacked its /Track subcell:
    small = cell below `crater.rmin`; header = identity below `crater.hfloor`; geo = degenerate
     clip or a band that couldn't seat; nofold = no cross-kind fold structure at all.

## What is NOT built yet

- Faces as registered modules (still functions in Cytui).
- An in-tab knob-drawer UI (tuning is over the ask rails only).
- Moments exported as committed JSON (they live in the per-tab stash only).
