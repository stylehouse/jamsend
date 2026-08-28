# Cellsizing_todo.md — the time-domain cell-guts measure loop that keeps letting us down

The owner has hit this same wall repeatedly (2026-08-28, escalating):
- *"what's our time domain aware approach to cell guts sizings? it seems to always be letting us
   down, do we still not have the proper way to do it"*
- *"MEASURE THE THING IN THE CELL AND MAKE SURE ITS ZOOMED|POSITIONED PROPERLY"*
- *"clicking the cell background DOESN'T re-measure its guts, AGAIN failing to do that"*
- *"the title is way up in the top left, 1/4 of the cell space is used"* (the Link cell)

This doc COLLECTS every instance and frames the real fix.  It is the "amaze a subagent with the
 complexity" doc — the investigation + design live here; the fix, once designed, is delicate
  (touches Vytui, a straggler that is IN FLUX — do NOT edit it blind; propose the patch and let the
   owner land it).

---

## 0. The symptom, said many ways

A face is a Svelte component with its own layout and its own natural size.  A cell is a voronoi
 region the solve hands it.  The two are reconciled by a MEASURE: the render measures the widget's
  natural box (`need_w`/`need_h`/`need_area`, stamped on `row.c` by Vytui's measure pass), and the
   size algebra floors the cell at that box (`Vyto_need_of` → need×1.15).  When it works, a cell
    grows to hold its guts.  When it doesn't, the guts render at their measured box in a CORNER of a
     bigger cell (the Link "¼ of the cell, top-left"), or a face priced below its box is crushed to
      an icon and never climbs out.

The recurring failure is TIME-DOMAIN: the measure is a one-shot that happens (or doesn't) at first
 draw, and **nothing re-runs the express+settle after a measure changes a row's need** — so a cell
  that is new to the glass, or whose guts changed size, is solved and framed while unmeasured (fit
   defaults to 1, "the right size initially") and only converges if some UNRELATED gesture happens
    to stir a re-solve.  The owner's instinct — *click the cell to re-measure* — is exactly the
     missing manual trigger, and it currently does nothing.

## 1. What already exists (the half-loop) — VERIFY each against the live tree

- `Vyto_need_of` (Ghost/V/Vyto.g ~:1180) — the need FLOOR: reads `row.c.need_area`, returns
   need·1.15, gated on `w.c.need_floor`.  Space-domain half: present and armed on the live glass.
- The measure PASS in Vytui (`need_w`/`need_h` stamped after a flush — Vytui ~:2028) — measures a
   face child by the Cytui offset trick / an ident label by getBBox.
- The per-axis fit: `fit = min(bbw/nw, bbh/nh)` (Vyto.g need_of header ~:1189) — a tall face
   (nh≫nw) lands fit≈0.70 ⇒ 49% of the area asked for; the exact "some faces render small" arithmetic.
- A **re-measure-on-tap hint armed at the STAGE level in `reg_stage`** (Vytui ~:124) — THE LEAD.
   Investigate: what does it arm, what consumes it, and WHY does a cell-background click not reach
    it?  The owner's "clicking the cell doesn't re-measure" is almost certainly this hint not being
     wired to the cell-click, or the click being eaten (see the pointer-events note below).
- The camera/zoom is RETIRED as a navigation verb (Vyto.g ~:1433) — "zoom = reframe" but clicking
   shifts EMPHASIS (the belly), it does not fly a camera.  So "zoomed properly" now means "the belly
    cell is sized and the face fills it", NOT a camera move.  Keep that framing.

## 2. The poses, and where they fail (the Link cell, just fixed as a special-case)

`big` = draw everything, keep own aspect.  `small` = a bud.  `stretched` = take the whole rectangle,
 give up aspect (right for a form/list).  The Link cell rendered its measured box top-left under
  `big`; the 2026-08-28 fix special-cased it to `stretched` (Sounditron_commission `bellyLink`).
   **That is a patch, not the cure** — every faced belly that is "a surface to work through" wants
    to fill, and hard-coding mainkeys does not scale.  The real question: should `big` itself fill
     the belly when the face declares it has no meaningful aspect (a `fill` hint on the face /
      glass_kinds), so the renderer stops rendering a small measured box inside a large seat?

## 3. The pointer-events tangle (adjacent, and a live footgun)

The glass_kinds contract: a face root is `pointer-events:none`, interactive descendants re-arm
 `auto`, because face-molds are rectangles at the cell bbox and voronoi bboxes overlap — an `auto`
  root shields neighbours' controls (and a departing mold lingers through its fold, shielding after
   the visit).  BUT `none` also kills SCROLL and TEXT-SELECTION, so a face that overflows needs its
    scroll/select region re-armed as a bounded, centered column (LinkFace/LinkDevice, 2026-08-28).
     This intersects sizing: if the measure floored the cell to the guts' full height there would be
      no overflow and no scroll tangle at all — the scroll freeze is downstream of the measure not
       flooring tall content.  A proper measure loop shrinks this problem.

## 4. The work (for the subagent — investigate, then DESIGN, do not edit Vytui blind)

1. Trace the measure lifecycle end to end on the LIVE glass: when is `need_w/h` first stamped, what
    consumes it, what (if anything) re-runs express+settle when it changes.  Name the exact gap.
2. Find the `reg_stage` re-measure-on-tap hint; determine why a cell-background click does not fire
    a re-measure (wiring? the click eaten by pointer-events? the hint consumed only at stage mount?).
3. Design the CLOSED LOOP: draw → measure → (need changed?) → re-express → re-settle, deterministic,
    convergent, with a dead-band so it cannot oscillate.  Plus the manual trigger the owner wants
     (click/tap a cell → re-measure its guts).  Respect: Books are byte-identical (humdinger / the
      need_floor gate is already the discipline), and the loop must terminate.
4. Deliver a PROPOSED patch set (Vyto.g is fair game to draft; Vytui.svelte is a straggler IN FLUX —
    write the Vytui half as a diff in this doc for the owner to land, do not apply it).

## findings (2026-08-28 subagent trace — file:line evidence)

The measure loop is TWO half-loops that never join. The AREA half closes; the BOX half does not; and
 the render's fit is a one-shot read at paint that the model can never trigger. Three concrete gaps:

### GAP 1 — `stamp_box` (need_w/need_h) does NOT poke the model. `stamp_need` (need_area) DOES.
This is the root time-domain gap and it is one missing line.
- `stamp_need` (Vytui `src/lib/O/Vytui.svelte:2879`) writes `row.c.need_area` and ENDS with
   `;(H as any).Vyto_stir_soon?.(w)` (`:2884`) — so a changed AREA re-runs the MODEL: `Vyto_stir_soon`
    → `Vyto_stir` → `Vyto_express` → `Vyto_solve` (`Ghost/V/Vyto.g:244,253,259-260`). The cut re-floors.
- `stamp_box` (`Vytui.svelte:2920`) writes `need_w`/`need_h` via `gauge_box` and, on a real change,
   arms ONLY render-side latches — `react_soon()`, `settle_ladder(w)`, `gauge_again(w)` (`:2922,2931,
    2945`). **It never calls `Vyto_stir_soon`.** So a changed BOX (same-ish area, new aspect — the exact
     "tall narrow face" case the doc names) re-paints but never re-EXPRESSES: `Vyto_need_of`
      (`Vyto.g:1205`) now reads `need_w`/`need_h` to compute the aspect-aware floor `round = π/4·d²·1.15`
       (`:1213-1216`), and NOTHING re-runs express when only the box moved. The floor that finally
        understands aspect is starved of the trigger that would apply it. → the cell is floored to a
         stale aspect and only re-floors if some AREA change or unrelated gesture also stirs the model.

### GAP 2 — the render's `fit` is computed at PAINT from `need_w`/`need_h`, and the model can't re-run it.
Even when the model re-solves, the actual face-vs-cell fit is decided render-side, per paint, off
 `paint_tick`:
- `nw/nh = row.c.need_w/need_h` are read at `Vytui.svelte:2028-2029`; the ray-seat computes
   `fit = byray` (ray-to-wall / half-diagonal), clamped `0.2 .. fitMax` (`:2191-2192`), and the mold is
    `mw=nw*fit, mh=nh*fit` (`:2193`). This whole block only re-runs when the template re-pulls, i.e. when
     `paint_tick` bumps — and `paint_tick` bumps ONLY when geometry MOVED (`adopt`, `:2736,2789`).
- So a cell whose guts changed size but whose SEAT did not move is measured (stamp_box), re-paints
   nothing (paint_tick idle), and sits at the old fit. The whole file is scarred with workarounds for
    exactly this — `gauge_again`, `settle_ladder`, `measure_soon/lately/pair`, the arrival ladder,
     `sizewatch`'s ResizeObserver — every one is "look again because paint_tick won't." They paper over
      GAP 1+2 with timers instead of closing the loop deterministically.

### GAP 3 — `big` MAGNIFIES a small measured box; it does not LAY IT OUT to fill. (the Link ¼-cell)
- Pose `big` (Sounditron `Ghost/Story/Sounditron.g:866`) means "face keeps its own aspect"; the belly's
   `fitMax = BELLY_FIT_MAX = 4.5` (`Vytui.svelte:843,2040`). A `big` face is drawn at its NATURAL box
    and SCALED by `fit` (a CSS `transform:scale` via `--fit`, `:1276`) — the layout width is never
     reassigned. So a face authored as a top-left column with intrinsic whitespace renders that same
      small shape and is scaled up as a picture: text balloons/blurs and the whitespace scales with it,
       i.e. "the title way up in the top-left, ¼ of the cell used." A LinkFace measuring a tight natural
        box gets a large `byray` and could hit 4.5×, but 4.5× of a small top-left column is still a small
         top-left column, now magnified — never a filled surface.
- `stretched` cures it the RIGHT way and the machinery already exists: it ASSIGNS the layout width via
   `--lay` (`:1272-1275`) so `--fit` becomes a pure output scale and the face's OWN flow fills the
    rectangle (`fill_body_memo`, `:2313-2340`). The 2026-08-28 fix just forced Link → `stretched`
     (`Sounditron.g:865-866` `bellyLink`). That is a per-mainkey patch, not a cure — every "surface to
      work through" face has to be hand-listed.

### What is NOT the gap (ruled out)
- The model belief loop is fine: `stamp_need→Vyto_stir_soon→express→solve` is a real closed loop and
   `Vyto_need_of` already reads the box for an aspect-aware floor. The AREA half works.
- The reg_stage retap IS wired (below) — the owner's "clicking does nothing" is a lever problem, not a
   missing handler.

### The reg_stage re-measure-on-tap hint (the owner's literal complaint), pinned
- It IS wired: `reg_stage` adds `el.addEventListener('pointerdown', retap, true)` in the CAPTURE phase
   on the whole stage (`Vytui.svelte:2872-2873`), precisely so a mis-seated overlay can't eat the tap and
    `cell_click`'s pointer-events tangle is bypassed. `retap = () => { kick(w); paint_tick++; settle_ladder(w) }`.
- WHY it still under-delivers, two reasons, both real:
  1. `retap` re-measures the WHOLE WORLD, not the tapped cell (`settle_ladder`→`measure_world(w)`,
      `:3037-3041`), and it bumps `paint_tick` so the seats re-pull — but the re-measure still flows
       through GAP 1: `stamp_box` finds the new box and STILL does not re-express, so a cell whose FLOOR
        (not just its seat) is wrong is not re-floored by the tap. The tap re-seats within the current
         cut; it cannot re-CUT to a corrected floor. (This is the owner's "clicking DOESN'T re-measure its
          guts" — it re-measures, but the measurement dead-ends at the model boundary.)
  2. The tap gives no CELL-LOCAL force: there is no "re-measure THIS cell's guts and drop its remembered
      box so a shrunk face can climb back," only the world-wide grow-biased gauge.

## proposed fix

### Design: the closed loop (draw → measure → need-changed? → re-express → re-settle), convergent
The loop already terminates on the AREA side because every stamp is dead-banded (`stamp_need` 2% at
 `:2882`; `gauge_box` BAND at `vyto_gauge.ts:61`) and `Vyto_express`/`Vyto_solve` are pure functions of
  the stamped needs (EPS-tolerant law-1 cut, `Vyto.g:1670`), so a re-express off an UNCHANGED need
   re-emits byte-identical env_area → identical cut → no further stir. The fix is to let the BOX half
    ride the same rails:
1. **Join the box half to the model.** Make `stamp_box`, on a real verdict (`first|grew|fell`), ALSO
    call `Vyto_stir_soon(w)` — the same poke `stamp_need` already does. Now a changed aspect re-runs
     `Vyto_express`→`Vyto_need_of` (which reads need_w/need_h) → a re-floored, re-solved cut. The
      dead-band in `gauge_box` guarantees the poke only fires on a box that actually moved beyond
       tolerance, so it converges and cannot oscillate: box settles → no verdict → no poke → quiescent.
2. **Manual trigger = cell-local, floor-dropping re-measure.** On the reg_stage retap, in addition to
    the world re-look, DROP the tapped cell's remembered box so a face that shrank can be re-learned from
     scratch, then `Vyto_stir_soon(w)`. The delete set already exists INLINE inside `gauge_pose`
      (`vyto_gauge.ts:85-89`: `need_w/need_h/need_area`, `gauge_w/gauge_h/gauge_at`,
       `stretch_col/stretch_h/stretch_rect/stretch_prev`); the clean move is to EXTRACT it as an exported
        `gauge_reset(c)` and have `gauge_pose` call it, so the tap and the pose-change share one reset
         (no drift). The tap thus forces exactly "re-measure THIS cell's guts and re-fit" — the owner's
          ask — and because the reset only clears `.c` render mirrors (never `.sc`), no fixture can see it.
3. **Terminates:** every write is dead-banded; the poke chain is idempotent on an unchanged need; the
    manual reset is a one-shot the next measure refills. No timer keep-alive, no relaxation-then-
     discovery.

### Design: `big` should FILL when a face declares no meaningful aspect (kill the per-mainkey patch)
Add a face-level `fill` capability so `big` stops magnifying a small box. A `fill` face under `big`
 takes the `--lay` path `stretched` already uses (assign layout width, `--fit` = pure scale), so its own
  flow fills the seat — no aspect hard-coded, no mainkey list. Two clean ways to declare it, pick one:
- **(preferred) a parallel registry in `glass_kinds.ts`** — `export const GLASS_FILL: Record<string,1> =
   { Link:1, Heist:1, Tree:1, Crate:1, ... }` beside `GLASS_KINDS`. Vytui reads it where it computes the
    pose so `big + fill ⇒ treat as stretched`. Faceless/aspect faces (Radio) stay `big`. This retires the
     `bellyLink` special-case entirely.
- (alt) a `pose_want` default from the face component itself. Heavier; the registry is the lighter seam
   and matches how `GLASS_KINDS` is already the one place a face's glass behaviour is declared.

### Concrete patch

**A. Vytui.svelte — PROPOSED DIFF (owner to land; do NOT auto-apply, straggler in flux).**

`stamp_box` (~:2920) — join the box half to the model (GAP 1, the single highest-leverage change):
```diff
         else if (v === 'first' || v === 'grew' || v === 'fell') {
             react_soon()
+            // A CHANGED BOX MUST RE-EXPRESS, not just re-seat.  need_area pokes the model
+            //  (stamp_need); need_w/need_h feed Vyto_need_of's aspect-aware floor and had NO poke,
+            //   so a new aspect re-painted but never re-floored.  Same coalescing latch, same
+            //    dead-band upstream (gauge_box), so it converges and no fixture moves (need_floor-gated).
+            ;(H as any).Vyto_stir_soon?.(w)
             if (v === 'grew' || v === 'first') settle_ladder(w)
```

reg_stage retap (~:2872) — cell-local, floor-dropping manual re-measure (GAP 3 of the tap):
```diff
-        const retap = () => { kick(w); paint_tick++; settle_ladder(w) }
+        const retap = (e: PointerEvent) => {
+            // the tapped cell, if the press landed on a mold/cell path carrying a data-key
+            const el2 = (e.target as Element | null)?.closest?.('[data-key]') as Element | null
+            const key = el2?.getAttribute('data-key') ?? ''
+            const cell = key ? (paintMap.get(w) ?? []).find(c => c.key === key) : null
+            if (cell) {
+                // drop this cell's remembered box so a shrunk face can be re-learned from scratch,
+                //  then re-express: "re-measure THIS cell's guts and re-fit" (the owner's ask).
+                gauge_reset(cell.row.c as any)     // NEW export extracted from gauge_pose:85-89 —
+                                                   //  clears need_w/h/area + gauge_* + stretch_* on .c only
+                ;(H as any).Vyto_stir_soon?.(w)
+            }
+            kick(w); paint_tick++; settle_ladder(w)
+        }
```
(import `gauge_reset` from `./vyto_gauge` alongside `gauge_box`, `:2909` region.)

pose→fill (GAP 3, retire bellyLink): where `poseNow`/`stretchPose` are derived (~:2037-2039), let a
 `fill` face under `big` take the stretched path:
```diff
+        // a face that declares it has NO meaningful aspect (GLASS_FILL) fills its seat under `big`
+        //  the same way `stretched` does — assign the layout width, let the face's own flow fill it —
+        //   instead of magnifying a small measured box top-left.  Retires the per-mainkey bellyLink patch.
         const poseNow = String((((row.c as any).source_n) as any)?.c?.pose ?? '')
         const smallPose = poseNow === 'small'
-        const stretchPose = poseNow === 'stretched'
+        const srcMk = (() => { const s:any = (row.c as any).source_n?.sc; return s ? Object.keys(s)[0] : '' })()
+        const stretchPose = poseNow === 'stretched' || (poseNow === 'big' && !!GLASS_FILL[srcMk])
```
(and `stretch_cell` at `:1154` should read the same `GLASS_FILL` so measure/`--lay` agree with paint.)

**A′. vyto_gauge.ts — extract the reset (pure, gated by VytoGauge.spec) so the tap and pose-change share it:**
```diff
+// gauge_reset — forget a cell's remembered box AND its stretch search.  Shared by a pose change
+//  (a different face now draws here) and a manual re-measure tap (re-learn a shrunk face from scratch).
+export function gauge_reset(c: GaugeBag & Record<string, any>) {
+    delete c.need_w; delete c.need_h; delete c.need_area
+    delete c.gauge_w; delete c.gauge_h; delete c.gauge_at
+    delete c.stretch_col; delete c.stretch_h; delete c.stretch_rect; delete c.stretch_prev
+}
 export function gauge_pose(c: GaugeBag & Record<string, any>, pose: string): boolean {
     if (c.gauge_pose === pose) return false
     if (c.gauge_pose == null) { c.gauge_pose = pose; if (!pose) return false }
     c.gauge_pose = pose
-    delete c.need_w; delete c.need_h; delete c.need_area
-    delete c.gauge_w; delete c.gauge_h; delete c.gauge_at
-    delete c.stretch_col; delete c.stretch_h; delete c.stretch_rect; delete c.stretch_prev
+    gauge_reset(c)
```

**B. glass_kinds.ts — PROPOSED DIFF (Vytui's only importer; owner lands with A):**
```diff
+// GLASS_FILL — faces with NO meaningful aspect: a surface to work THROUGH (a form, a list, a device
+//  ceremony), not a player with a shape to keep.  Under pose `big` these fill their seat like
+//   `stretched` does (Vytui assigns --lay, --fit stays a pure scale) instead of rendering a small
+//    measured box top-left.  Retires Sounditron's per-mainkey bellyLink special-case.  A face absent
+//     here keeps `big`'s aspect-preserving magnify (Radio, the players).
+export const GLASS_FILL: Record<string, 1> = {
+    Link: 1, Heist: 1, Tree: 1, Crate: 1, Riffle: 1, Zine: 1, Lineup: 1,
+}
```

**C. Sounditron.g — retire the bellyLink patch once A+B land (proposed, not applied):**
`Ghost/Story/Sounditron.g:865-866` `bellyLink` and its branch can drop back to
 `fmain.c.pose = fmain.c.pose_want || (bellyForm ? 'stretched' : 'big')`, since `big + Link` now fills
  via GLASS_FILL. Leave in place until A+B are landed and verified on the live runner (a Vyto* Book run,
   robustly green across N, per Coding_guide "verify by re-running").

### Why NO Vyto.g edit was applied
The entire fix lives render-side (Vytui + glass_kinds). `Vyto_need_of` already reads need_w/need_h and
 already re-floors when stirred — the model half is correct and complete; it is merely never TRIGGERED
  by a box change, and the trigger (`Vyto_stir_soon`) is called from Vytui, the straggler. There is no
   Book-neutral model-side change that closes the loop, so applying a Vyto.g edit would be motion without
    leverage and risks a fixture move for nothing. Everything is left as a proposed diff.

### Highest-leverage single change to land first
**Patch A's one-line `stamp_box → Vyto_stir_soon` addition.** It closes the time-domain loop for EVERY
 face (join the box half to the express/solve the area half already drives), is dead-band-protected so it
  cannot oscillate, and is `need_floor`-gated so no Vyto* fixture can move. The `big`-fill work (B + the
   pose diff) is the second landing and cures the Link ¼-cell class without hard-coding mainkeys.

## 5. Related: the multi-device / multi-person graph → Voromay_todo.md

The owner (2026-08-28): *"this new multi-device multi-person reality needs graphing with… Vyto?
 Vyto is in flux a bit.  perhaps Voromay may do better."*  That is its own plot — see
  `Voromay_todo.md`.  It shares this doc's root question (how does living matter get sized and
   placed legibly) but at the topology scale (souls, caves, devices, grants) rather than the cell
    scale, and the owner is explicitly open to a DIFFERENT renderer (Voromay) for it.
