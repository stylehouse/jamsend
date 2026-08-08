# pile.md — what the pile actually rests into, measured

A `vyto_workingouts/` elaboration (2026-08-09), written **while `Vyto.g` / `Vytui.svelte` /
 `Vyto_todo.md` were in flux under another hand** — so it is parked here rather than folded into
  `Vyto_todo`'s §0.  Fold it in when the flux settles; nothing here was written to the model.

Everything below is a **measurement** off the shipping `vyto_geometry.ts`, not a reading of it.
 Probes: `scratchpad/pile_probe.ts`, `pile_sweep.ts`, `pile_fill.ts` (node
  `--experimental-strip-types`, importing the real module — no reimplementation).

## The question

The owner's live capture (`Screenshot From 2026-08-09 06-58-31.png`) shows the glass as **one
 magenta disc carved into radial wedges** — a pie chart, not an orchestra of spheres — with the
  faces inside it crushed and roughly 60% of the stage empty black.  Two readings were possible:
   the pile is failing to separate the bodies (a solver bug), or it is resting correctly somewhere
    that happens to look like that.  A pie means *every wall passes through one point*, which is
     exactly what coincident seeds would produce, so the solver was the first suspect.

## What the probe found — the solver is innocent

7 equal balls, radii from a 12800px² need, 800×450 frame, gravity/spring/separation at the
 shipping constants:

| start | rests at | seed spread | closest pair | walls through the centre |
|---|---|---|---|---|
| near-coincident (all within 1px) | step 311 | 104px | 82% of rᵢ+rⱼ | 6 of 12 |
| spread on a wide ellipse | step 192 | 129px | 78% | 4 of 10 |
| spread + fully wired | step 81 | 110px | 64% | 6 of 12 |

**It separates, and it rests** — from a fully-degenerate start too, well inside the measured
 400-step cap.  There is no coincidence bug.

**The pie is the truth about seven equal balls piled around one heart.**  One in the middle, six
 around it, and about half the walls genuinely do pass near the centre.  The image is not being
  drawn wrongly; the image is what the configuration means.  Case D of `pile_probe.ts` (unequal
   radii — 2.2× down to 0.6×) is the tell: same solver, same constants, and the cell areas come
    out 58839 / 17946 / 8121 / 10597 / 6505 / 4897 / 2292.  That reads as a made thing.  Seven
     equal discs cannot, however they are arranged.

## The real defect: the balls are only worth a quarter of the frame

`Σπr²` at the shipping radii = **25% of the frame**.  Coverage measured live was 24.9%; the probe
 gets 20.5% after packing loss.  Those are the same number, and it is a *ceiling*: no solver
  setting can make a pile cover more frame than its bodies are worth.  The frame is never
   consulted when radii are chosen — `need_area` is an **absolute** area per particle.

The consequence is the screenshot's paradox, and it is one mechanism, not two:

> every cell is smaller than the component inside it asked for, **while more than half the stage
>  is empty**.  Worst cell rests at **76% of its own `need_area`** — the mutual pressing shaves
>   everyone below their measured need, and there is nothing to push back with, because nobody
>    knows there is room.

Normalising the radii so `Σπr² = pack · frame_area` before the pile runs (`pile_fill.ts`):

| radii | rests at | coverage | smallest cell vs its need |
|---|---|---|---|
| shipping (absolute need_area) | 192 | 20.5% | **76%** |
| normalised, pack 0.6 | 173 | 48.2% | 184% |
| normalised, pack 0.75 | 169 | **57.6%** | **192%** |
| normalised, pack 0.9 | 164 | 66.5% | 192% |

It rests *sooner*, not later.  `need_area` wants to be a **ratio** — a claim on the frame relative
 to its siblings — with the absolute value kept only as the floor that decides the fold register.

## Secondary, cheap, and real

`pile_step`'s `squeeze: 0.85` sets the resting overlap: bodies stop pushing back while still
 overlapping 15% past kissing.  Taking it to `1.0` is worth ~17 points of worst-cell area
  (76% → 93% of need) on the shipping radii, and ~5 points of coverage at every pack level.
   It does **not** touch the spoke count — it is not the pie's cause, just free room.

## What this does NOT say

- Nothing here was measured on a live tab.  The probe drives the pure geometry with plausible
   inputs; the real glass's radii come from `Vyto_express`/`need_area` against real measured
    faces, and the live distribution of those is unknown.  **The first thing to check on a live
     tab is the spread of radii** — if the organs' needs are near-equal, that is itself the
      finding, and it is a posing question (what is worth more room), not a geometry one.
- Whether normalisation is safe for driven Books is untested here.  It changes every position, so
   it wants the usual additive gate and a fleet run.
- The wall-through-centre metric (within 30px of the seed cloud's centroid) is mine, invented for
   this probe.  It is a useful tell, not a standing definition.
