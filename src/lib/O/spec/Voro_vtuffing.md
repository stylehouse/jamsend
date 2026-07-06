# Vtuffing — the pane-content engine (what a big cell SAYS)

The microcosm cards (Voro_microcosm.md a+b) underexpressed: a VoroScape pane the size
 of a hand said "Track" three times, because the card text was the member's mainkey
  value and nothing else.  The molded Stuffings they replaced were rich.  Vtuffing is
   the owner's asked-for middle: **a Stuffing-grade data pipeline into a C\*\* that a
    dumb renderer fits into the cell shape** — the smarts .g-side and extensible the
     Waft way, the pixels staying pure.

## The split

- **Voro.g owns MEANING** — `Vtuff_build(src)` distils a fold|gang's members into a
   small layout tree; policy, grouping, wording all live there.
- **Cytui owns GEOMETRY** — it normalises the tree to row descriptors and chord-fits
   them into the convex cell polygon.  It never reads member sc itself (except the
    pre-reload fallback, below).

## The tree (a FREE C\*\*, metaphysics-clean)

Minted with `new TheC(...)` and reachable from nothing — snap inclusion is
 reachability in H\*\*, so no snap, no encode, no fixture can ever see a Vtuffing.
  Cached at `src.c.vtuffing` keyed by `src.c.vtuffing_sig` (member count + summed
   versions): a beat that changes nothing returns the same tree, per-frame render
    calls cost one sum.

    %Vtuffing,of:<fold kind>,n:<members>          (c.src → the fold|gang rep)
      /%Vrow,row:title,text:'Artist · Moonlit  ×5',wgt:2
      /%Vrow,row:fact,text:'artist: Neil Young'    a key EVERYONE agrees on, said once
      /%Vrow,row:spread,text:'title'               a key that varies
         /%Vbit,text:'Tide',n:2                    value chips, most-common first,
         /%Vbit,text:'+3',n:0                       capped at 4 with a visible tail
      /%Vrow,row:member,text:'Track · Halo'        per-member when the family ≤ 5
                                                    (c.member — the pop-out handle)
      /%Vrow,row:dip,text:'/*12'                   the surf handle (c.members)

`Vtuff_default` is the generic distiller (the Stuffusion|Stuffziad|Stuffziado
 compression re-said as rows).  A presence-only key everyone carries (the mainkey's
  `1`) says nothing and is skipped.

## Extending it — the Waft way

Define `Vtuff_of_<fold kind>(root, members, src)` on ANY ghost and that kind's panes
 author their own rows: `Vtuff_build` dispatches by `src.c.fold_kind` before falling
  back to the default.  A Track pane could emit duration bars; a Pier pane its
   liveness — no renderer change, ever.

## The fit (Cytui `micro_fit`)

The cells are half-plane intersections — CONVEX — so the widest horizontal chord at
 any height is one interval (`poly_chord`).  Rows stack down the cell; each row's box
  is the intersection of the chords at its band's top and bottom, so text follows the
   slanted walls instead of a bbox grid, and never clips.  Title rows run 1.35× the
    unit height; too many rows keeps title + head + dip and says `+K more` (no silent
     caps).  Overflow within a row ellipsizes.

Runs in **both cadences** — the tree is cached and the fit is pure math — so the rows
 track a drag live.  (They used to vanish: the swap dimmed the Stuffing to 0 AND hid
  the card layer during motion, leaving a blank pane mid-gesture.)

## Colour — the stained glass

Every cell is translucent glass tinted by KIND.  The colour resolves in order:
 an authored Matstyle swatch (`kind_color` — the purple you dotted, still the way
  to PIN a kind's colour) → else a deterministic per-kind HUE (`kind_hue`).  So an
   un-swatched kind earns its OWN colour instead of falling to the fold node's
    single default border `#79b` — that one grey-teal, worn by every un-styled
     fold, is *where the teal came from*.  `kind_glass` (saturated, the cell
      fill/stroke) and `kind_tint` (lighter, the pane row text) share the hue, so
       a member row wears its own kind's colour.

`kind_hue` is a GOLDEN-ANGLE registry, not a name hash — a raw hash clusters (the
 genera fell into five near-identical purples); instead each distinct kind takes
  the next 137.5° slot as it's first seen (the `fam_seq` pattern the hulls use), so
   even a handful of kinds land far apart on the wheel.  Order-dependent but purely
    cosmetic.

A SWAPPED (vtuffing) cell also takes the Stuffing's chrome — a dotted rim
 (`stroke-dasharray`) over a fuller fill — so a pane reads as a tabletty Stuffing,
  not a flat panel; plain cells keep the thin solid stroke.

Open: to PIN a kind's colour, author its Matstyle swatch (that wins over the hue);
 a Matstyle-seeded or perceptually-even palette is the eventual calibration.

## The /*N surf — pop out, never expand in

The Stuffzipper's `/*N` inside a pane expands nested Stuffings IN the pane.  The
 owner's call: at pane scale, digging should **locate|create nodes popping up in the
  graph around it, not in the Stuffing\*\* itself**.  So member|dip rows are buttons →
   `Vtuff_pop(src, member?)`:

- a **gang member** row pops that member out (`c.popped`): the crush walk leaves a
   popped leaf loose forever after — its own node, beside its old gang;
- the **dip on a gang** dissolves the whole gang the same way;
- the **dip on a container fold** unfurls it (`c.popped_open`): `Voro_crushable` and
   `Voro_swarmable` both refuse it from then on.

All c-side INTENT stamps: authoritative passes respect them, `Voro_crush_clear` (the
 ◈ un-imposition) forgets them.  After stamping, one `cyto_update_wave` re-scans, so
  the graph grows the nodes right where the pane sits.

## Toggles (the ▤)

Every modulation now has a bar toggle: ◈ voronoi, ❝ properCellable, ⬡ family hulls,
 🌀 gravity brush, **▤ vtuffing** (stash `Cyto_vtuffing`, default on).  ▤ off =
  molded Stuffings always, at every zoom.

## Fallback until the gen boots

Live runners hold the OLD gen until the tab reloads (LocalGen writes disk only).
 `vtuff_rows` falls back to a plain TS builder — title + member idents + dip — so
  panes say `Track · Tide` instead of `Track` even before the reload; the shared-fact
   and spread rows arrive with the new gen.

## The next moves — owner's demands, tuned up (the big-think agenda)

Captured from the live-tab review, in the owner's words + the intended behaviour +
 a mechanism sketch.  `[pane]` = Cytui/Voro.g render only, low risk.  `[scan]` =
  touches cyto_scan / the crusher descent — a core seam, so **prove in isolation
   first** ([[fight-back-on-core-changes]]).  This is the review artifact: beat it,
    then crank the big-think.

1. **Spill the deeper levels — `w/*/**` into the graph.**  *"there are no w/*/** on
    this graph — only the w/* … if we could have a reasonable amount of them spill
     out that'd be great."*  Today only the scan frame's DIRECT children become
      nodes; grandchildren hide inside crushed panes.  Want: a bounded descent that
       pops the top-K most-interesting children of each parent out as their own
        nodes (auto `popped_open`, capped per parent so the graph doesn't explode),
         the rest staying crushed.  This is the population the family hull wraps.
          `[scan]`

2. **The exploding edge — child↔parent through the graph medium.**  *"before we
    couldn't easily draw an edge from an expanded-within child `w/C/*` to its parent,
     but now we can lever it all through the graph medium!"* (the `/*1` lucida under
      the ×12 %Leptospermum).  When a child pops out (via #1 or the surf), draw a
       synthetic edge popped→parent so the unfurl reads as a family explosion, not
        orphan nodes.  The popped node already holds `c.up`; the edge is c-side
         (source_n backlink, no encode), coloured by family.  **Owner is keenest to
          pin this one.**  `[scan]` (edge injection) — the drawing is `[pane]`.

3. **The pop-out surf, under control.**  *"the svgStuffings pop back to being regular
    Stuffings when clicked huh? is that under control?"*  Half.  Only member|dip rows
     are hot: a **member** row pops ONE member out (`c.popped`) and the pane stays
      with the rest — good; the **dip** is all-or-nothing (dissolves the whole gang /
       unfurls the container via `c.popped_open`), which is what reads as "the whole
        pane reverted".  Pin: the dip should spill a *reasonable few* (tie to #1's
         cap), and there must be an **un-pop** (fold-me-back) gesture — today only ◈
          off (crush_clear) forgets the stamps.  `[pane]` + `[scan]`

4. **The list form — stop repeating the mainkey.**  *"`cell: Olearia x4` … then
    `Olearia:figaro` — repeating ourselves.  the whole thing should look like
     `Olearia: this | that | etc | tenuifolium` — we can figure out how many of a big
      list to pull out much better now."*  When members share a mainkey, hoist it
       once as a heading and list only the distinguishing values, pipe-joined and
        count-capped (`+N`).  A new `Vtuff_default` policy → a `row:list` kind
         (heading + inline pipe values); the renderer wraps the pipe text to the
          chord.  Supersedes per-member rows for a homogeneous family.  `[pane]`

5. **Family hull — touching, or roped, and per-family coloured.**  *"the voronoi
    cells that are supposed to be a hull aren't touching! could be a reason to run
     the layout some more, or it could need a rope connecting them to show their
      unity … multiple families of `*/**` need different coloured whatsits."*  The
       rope is built (two-pass 11px+4.5px) and `FAM_COLORS` already cycles distinct
        hues per family — so apart-but-roped is handled.  Remaining: a layout nudge
         (fcose intra-family gravity) that ATTRACTS same-family cells adjacent so the
          hull is a solid boundary, not a lasso across the board.  Gated behind #1
           (no families spill yet on VoroScape).  `[scan]`-adjacent (layout params)

6. **Fit-to-shape, refined.**  *"more fit-to-shape text columns, pretty good how it
    is."*  Keep tuning the chord fit; a wide cell could split into columns; `MICRO_Z
     = 300` and the 12–20px band are first guesses, live-eyes calibration owed.
      `kind_hue` collisions (see Colour).  `[pane]`

7. **Recursion** (was open c): a member row whose particle is itself a fold could
    host a nested fit — pixel-capped.  Lower priority than #1–#5.  `[pane]`

8. **Redirecting the real Stuffzipper** inside molded (non-swapped) panes to the same
    pop-out — a core-component change (Stuffzipper serves every Stuffing everywhere),
     so it needs the isolation-proof treatment, not a Voro-side patch.  `[core]`

9. **The single worked window** — cross-wall row alignment.  Today each pane fits its
    rows independently; the ambition is that two neighbouring panes' rows EDGE TOGETHER
     across their shared wall (matched tuple fields lining up across it), so the glass
      reads as one worked window, not panes-with-labels.  It rides ON this engine's row
       model (`Vtuff_build`) — the `edge_src` adjacency and the greedy per-wall matching
        solve are deep-designed in **`Voro_svg_stuffing.md`** (Voro_todo task 8).  The
         big-ticket `[pane]` item, gated behind #1 (needs neighbouring family panes to
          exist).
