# The Voro system — Vtuffing, the crush, the radio (system documentation)

What began as a pane-content note is the system doc now (owner's ask).  Bottom-up:
 the **crush** folds a world into stained-glass voronoi panes; **Vtuffing** decides
  what a pane SAYS; the **surf** pops things back out into the graph; the **radio**
   drives your attention around all of it.  The north stars come first — they are
    where this is going and every seam below should be read as rigging for them.

## ⭐ North stars

### 📻 The radio — attention as a supplied service

The owner, verbatim: *"automagically drifting towards some subset of stuff, and
 there's an algorithm that shifts your actual attention around that area as it wants
  to, as in supplying a radio listener."*  jamsend is a music app; a graph of music
   you must drive is a library, but one that plays YOU is a radio — the lean-back
    mode is the product.

**v1 IS BUILT** (`Voro_drift_tick`, 📻 on the ◈ bar, dwell ~7s): each tick it **ages**
 the oldest auto-opened locale shut (the trail behind the listener disincludes
  itself — the wandering-landscape answer), **chooses** the next focus (family size +
   freshness that starves revisits + nearness to the current focus for the "around
    that area" pull; a hash jitter as taste; every 4th hop a free jump — station
     drift, not a random walk), **opens** it a little (the bounded dip, stamped
      `popped_auto` so the tuner only ever ages its OWN openings — a human's pop is
       never touched), and the view **glides** the camera onto it.  Touching the dial
        (any grab|pan|zoom that isn't the glide) holds the tuner off 15s.
         Note: the radio SUBSUMES the old "auto-spill w/\*/\*\*" agenda item —
          open-a-little + age-behind IS the bounded spill governor.

**What the full radio still needs:**
1. **Taste beyond jitter** — score off real signals: VoroScape's hub weights (%Share
    counts), listen history, dose_drives-style decay; the hash stays as tiebreak.
2. **Dwell modulation** — linger where the listener lingers (pointer heat over a pane
    feeds back into dwell length; leaving early is a skip signal).
3. **Audio coupling** — in jamsend proper the tuner TUNES: the focus pane's tracks
    feed actual playback; graph drift = the playlist.  This is the product seam.
4. ~~**A Story Book**~~ — BUILT 2026-07-07: **VoroRadio** (9 steps, on the Credence
    board under What:Voro) beats the tuner 6 dwells on a fixed flora and %sees FOUR
     truths: motion, aging (first pick + whole gang stamp-free at the aging beat),
      the pool CYCLE (the aged locale re-gangs full-size and re-enters), and the hand
       outranking the tuner.  An adversarial audit of v1 found the aging claim was
        propped up by the very leak it claimed fixed — the popped-unstamp deleted
         `c.gang`, so Vtuff_unpop's sibling sweep was dead code and aged locales left
          permanently-popped orphans that silently shrank the pool.  Fixed at the seam
           (the popped-tiny unstamp now KEEPS the gang memory; unpop sweeps then
            retires it) and gated so the leak's return turns the Book red.
5. **Aging generalised** — beat-stamped intents + the gravity brush refreshing what
    it touches, so the governor folds the stalest attention first everywhere.

### 🕳 The tunnel — the graph on the wall of a tube (like a C) — v1 SKELETON BUILT

The owner: *"drifting down a tunnel... cytoscape computed not in 2d but around us on
 the wall of a tube we're drifting down... then the solidity (families, C\*\*) would
  be on the left... like a C."*

Design: cytoscape KEEPS computing 2D — we re-project the plane onto a cylinder wall.
 One axis becomes angle, the other becomes depth: `x → θ` over an OPEN arc (~250°, so
  the cross-section literally reads as the letter **C** — and everything here is a C),
   `y → z` down the tube.  **Solidity on the left**: order the 1D θ-axis by structural
    weight — families and the C\*\* spine take the left arc (the C's back), loose
     confetti scatters rightward toward the opening.  **Drifting down = the radio**:
      the tuner's dwell advance IS the z-motion; focus panes swell as you pass them.

**v1 skeleton (built 2026-07-07, 🕳 on the ◈ bar, stash `Cyto_tunnel`)** landed on a
 sharper seam than per-overlay CSS 3D: **project the SEEDS, not the paint**.
  `tube_project` (Cytui) remaps every seed onto the tube wall — θ by fold-mass rank
   (heaviest at π = the C's back, alternating ±Δ toward the lips), screen radius
    `R0/d`, content boxes scaled `NEAR/d` — right before the power diagram runs, so
     cells, molding, chips, hulls and the MORPH TWEEN all follow unmodified (toggling
      literally morphs the flat glass into the rosette).  Depth = layout y + a phase
       each radio dwell advances (wrap-around: past the camera → rejoins the far end);
        fog = per-cell fill|stroke fade by `NEAR/d`.  cy stays a 2D layout space.

**What the tunnel still needs:**
1. TUNING pass with eyes on it (arc span, NEAR|FAR, fog floor, dwell step 0.16).
2. A **true camera** = `{z, roll}` with continuous motion between dwells (the phase
    jump reads as a hop; an eased glide would read as drift) — and the wrap-around
     hop of a recycled pane hidden (fade through the fog, not a morph across the middle).
3. **Solidity-left refinement**: rank currently by per-pane fold mass; families should
    rank as WHOLES (hull mass) so a family's panes stay contiguous on the arc.
4. **Overlay fog**: cells fade but the molded Stuffings|rows keep full contrast —
    right for readability, wrong for depth; a gentle content fade past mid-tube.
5. **Pointer inverse-mapping** (screen → tube → plane) so the surf and the dial keep
    working inside the projection — v1 inherits plain screen hit-testing, which works
     because the tessellation IS in screen space, but the gravity brush's pinch
      direction no longer matches the model plane.

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
      /%Vrow,row:title,text:'Kunzea  ×14',tag:cell  NAME + TYPE-TAG, one shape always:
                                                     tag = the mainkey, drawn as a small
                                                     kind-coloured badge (the metaphysics
                                                     visible — mainkey ≠ other keys); a
                                                     gang has no name, so tag + ×N alone
      /%Vrow,row:list,text:''                      HOMOGENEOUS family: members as chips
         /%Vbit,text:'figaro',n:1                   of just their name (Vtuff_member_bit;
         /%Vbit,text:'tenuifolium',n:1,sub:3         c.member — each chip its own pop-out
         /%Vbit,text:'+2',n:0                         handle; sub = the lilac /*N glyph)
      /%Vrow,row:fact,text:'habit: vine'           a key EVERYONE agrees on, said once
      /%Vrow,row:spread,text:'year'                a key that varies (Vtuff_keyrows skips
         /%Vbit,text:'1998',n:2                     the family mainkey when homogeneous —
         /%Vbit,text:'+1',n:0                        no 'Olearia ×4' then 'Olearia:' stutter)
      /%Vrow,row:member,text:'Halo',tag:Track      per-member when a MIXED family ≤ 5
                                                    (c.member — the pop-out handle)
      /%Vrow,row:sub,text:'Coprosma',tag:cell      depth-1 openness: a tiny member's own
                                                    children indent under it (poppable too;
                                                    tag only when its kind differs)
      /%Vrow,row:dip,text:'/*12'                   the surf handle (c.members)

The property level is uniform `key: value` (facts|spreads); the TYPE level is always
 the tag badge; the NAME stands bare.  `Vtuff_name` is the splitter ({cell:'Kunzea'} →
  name Kunzea tag cell; {Artist:1,name:'Fernway'} → name Fernway tag Artist) — it ended
   the two-format stutter ('cell: Kunzea ×14' vs 'Artist · Fernway ×2').  `sub` counts
    children-to-dig, drawn as the dip-lilac `/*N` on rows AND chips: one consistent
     "there's more inside; it pops out with edges" affordance.

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

A **`list` row is a PHI SPIRAL** (the owner, specifically: "use a phi spiral like the
 seeds in a sunflower to grid things up").  The list claims the pane's LEFTOVER height
  (title|facts|dip take their bands; the spiral gets the belly) and each chip k sits at
   Vogel's sunflower point — r ∝ √(k+0.5), θ = k·137.508° — squeezed anisotropically to
    the row box.  The SAME golden angle the kind-hues step by: neighbours never queue
     up, so text chips scatter evenly with no grid to fight the slanted walls; the
      pane's clip-path trims any overflow.  The engine sends up to 25 members (+N tail
       beyond — "give it until we have problems fitting everything in"); each row's
        font-size rides the unit (`row.fs`), not the tall spiral block.

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

## Two modes of recursion (owner's carve, 2026-07-06)

**Mode A — into the SAME graph.**  Digging stays in the one cytoscape space: pop a
 few nodes out (the surf, bounded), and Travel the Vtuffing openness DOWN — a pane
  shows its members' own children as indented sub-rows before anything pops at all.
   One layout, one zoom, one camera; the crusher stays the single governor of how
    much is on the board.  **This is the mode we aim at first.**

**Mode B — a SUBGRAPH within a cell.**  A head|tails split: the cell keeps a title
 band (head) and hosts a whole nested layout in its body (tails) — a genuinely
  different node set laid out in the cell's own frame.  Honest feasibility: cytoscape
   will NOT nest layouts natively — one cy instance is one layout space, and compound
    nodes share the global layout rather than running their own.  Mode B therefore
     means either a second cy instance per open cell (heavy: its own canvas, events,
      camera — plus routing zoom between outer and inner) or a hand-rolled mini-force
       pass we run ourselves inside the polygon (feasible — the chord fit already
        owns the geometry — but it's a layout engine we'd be writing).  Deferred
         until mode A saturates; when it comes, the head|tails carve is right.

**The wandering-landscape problem** (real Music collections): dive in and in, and the
 trailing graph behind should DISINCLUDE.  Mode A's answer is the crusher as a
  focus-and-context governor: pop intents mark where attention is; what the surf left
   behind long ago is exactly what the escalating passes fold first.  The design
    sketch — intents age (a beat-stamp on c.popped), the gravity brush refreshes the
     stamps of what it touches, and the governor's escalation folds the STALEST
      intents back before anything else.  Nothing built yet (intents are currently
       immortal until un-pop|◈); the aging is the first thing to add when a real
        collection makes the board sprawl.

## The /*N surf — pop out, never expand in

The Stuffzipper's `/*N` inside a pane expands nested Stuffings IN the pane.  The
 owner's call: at pane scale, digging should **locate|create nodes popping up in the
  graph around it, not in the Stuffing\*\* itself**.  So member|dip rows — and list
   chips — are buttons → `Vtuff_pop(src, member?)`.  Brought UNDER CONTROL after the
    owner's "is that under control?" (v1's dip was all-or-nothing, and popping a
     single member of a FOLD pane was a silent no-op — the shut pane swallowed it):

- a **member** (row or chip, any depth) pops THAT node out: `c.popped` on it,
   `c.popped_open` up the container chain between it and the pane (`Vtuff_pop_stamp`
    — a grandchild's whole chain must unfurl for the scan to reach it);
- the **dip** spills a REASONABLE FEW — the top-K=3 by subtree weight — and the
   rest stays one pane: `Voro_crushable`|`Voro_swarmable` refuse a fold with a
    popped|popped_open child, so the container descends as a plain HUB node, the
     scan's own parent→child `/` edges draw the family explosion for free (the
      "exploding edge, through the graph medium"), and the remaining leaves re-gang
       at min 2 (the SPILL RELAX in `Voro_gang_fold` — "the rest stays one pane"
        must not depend on the mainkey being noisy).  A pane of ≤ K+1 opens whole;
- **un-pop** — right-click (`cxttap`) a popped node, or the hub of popped children,
   folds it back (`Vtuff_unpop` forgets the intents; the next pass re-folds by the
    ordinary rules).  The browser context menu is suppressed over the canvas only.

All c-side INTENT stamps: authoritative passes respect them, `Voro_crush_clear` (the
 ◈ un-imposition) forgets them wholesale.  After stamping, one `cyto_update_wave`
  re-scans, so the graph grows the nodes right where the pane sits.

Still floating: a popped GANG member directly under `w` gets no edge to its old gang
 (w is compound — the scan's `/` edges only leave plain parents).  The bond wants a
  tiny CORE seam — a generic `n.c.bond` ref that `cyto_scan_refs` draws as a blue
   edge — which is core-touch: isolation-proof first, not a Voro-side patch.

## Toggles (the ▤) — and ONE swap rule

Every modulation has a bar toggle: ◈ voronoi, ❝ properCellable, ⬡ family hulls,
 🌀 gravity brush, **▤ vtuffing** (stash `Cyto_vtuffing`, default on), **📻 radio**
  (stash `Cyto_radio`, default OFF — it moves the camera).

**▤ on = the engine owns EVERY fold pane; ▤ off = molded Stuffings always.**  v1
 swapped per-cell above a zoom threshold with per-cell hysteresis MEMORY — two
  same-size neighbours could differ purely by zoom history, and the board read as an
   arbitrary half-Stuffing half-Vtuffing mix (the owner: "weird").  Now the only gate
    is "can it say anything at all": a tiny floor (√area ≥ 70px) plus the fit actually
     returning rows; a sliver keeps its molded Stuffing, and the Stuffing only dims
      once rows really render (v1 could dim it then fit nothing — a blank pane).

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

1. **Spill the deeper levels — `w/*/**` into the graph.** — **SUBSUMED BY THE RADIO
    (2026-07-07).**  The tuner's open-a-little (`Vtuff_pop` bounded dip, auto-tagged)
     + age-behind (oldest auto locale folds back) IS the bounded spill governor the
      item wanted — 📻 on and the deeper levels breathe in and out of the graph as
       attention passes.  A manual always-spilled mode could still ride the same
        stamps later if wanted.  See §North stars.

2. **The exploding edge — child↔parent through the graph medium.**  *"before we
    couldn't easily draw an edge from an expanded-within child `w/C/*` to its parent,
     but now we can lever it all through the graph medium!"* (the `/*1` lucida under
      the ×12 %Leptospermum).  **MOSTLY FREE, 2026-07-06:** a fold that spills keeps
       its container as a plain HUB node, and the scan's own parent→child `/` edges
        (Cyto.svelte's non-compound-parent rule) wire hub→popped and hub→remainder-pane
         with no new code.  REMAINING: a gang directly under `w` has no hub (w is
          compound, no edges leave it) — the popped↔old-gang bond wants a tiny core
           seam, a generic `n.c.bond` ref drawn as a blue edge in `cyto_scan_refs`.
            Core-touch: isolation-proof first.  `[core]`, small

3. **The pop-out surf, under control.** — **BUILT 2026-07-06.**  Member pops now work
    at ANY depth (v1 silently no-opped on fold members — the shut pane swallowed the
     stamp; `Voro_crushable`|`swarmable` now refuse a fold with popped|popped_open
      children and `Vtuff_pop_stamp` unfurls the chain).  The dip spills the top-K=3
       by subtree weight, the REST re-gangs at min 2 (the spill relax) — "a few pop
        out, the rest stays one pane".  Un-pop = right-click the popped node or its
         hub (`Vtuff_unpop`).  REMAINS: eyes-on + intent AGING (see the
          wandering-landscape note above).

4. **The list form — stop repeating the mainkey.** — **BUILT 2026-07-06.**  A
    homogeneous family says the mainkey ONCE in the title ('Olearia  ×4' — and a gang
     titles by family name alone, not the rep's ident which read as one member) and
      lists members as `row:list` CHIPS of just their distinguishing bit
       (`Vtuff_member_bit`: mainkey value, else naming key), capped 6 with a `+N`
        tail — each chip its OWN pop-out handle.  `Vtuff_keyrows` skips the family
         mainkey so no spread repeats it.  REMAINS: "how many of a big list to pull
          out" is a flat 6 — could scale with the cell's chord budget.

5. **Family hull — touching, or roped, and per-family coloured.**  *"the voronoi
    cells that are supposed to be a hull aren't touching! could be a reason to run
     the layout some more, or it could need a rope connecting them to show their
      unity … multiple families of `*/**` need different coloured whatsits."*  The
       rope is built (two-pass 11px+4.5px) and `FAM_COLORS` already cycles distinct
        hues per family — so apart-but-roped is handled.  Remaining: a layout nudge
         (fcose intra-family gravity) that ATTRACTS same-family cells adjacent so the
          hull is a solid boundary, not a lasso across the board.  Gated behind #1
           (no families spill yet on VoroScape).  `[scan]`-adjacent (layout params)

6. **Fit-to-shape, columns.** — **list wrap BUILT 2026-07-07** (owner's "all this
    Stuffing data is one column!"): a `list` row now wraps its chips into a 2D grid
     sized to the cell's chord capacity.  REMAINS: fact/spread/member rows still stack
      one-per-line (a wide cell could flow THOSE into columns too); `MICRO_Z = 300`
       and the 12–20px band are first guesses, live-eyes calibration owed.  `[pane]`

   *Demo data (2026-07-07):* the panes had nothing but one repeated key to show, so a
    deterministic trait SPRINKLE now rides the Books (`Voro_hash`, no randomness —
     fixtures stay byte-stable): VoroMitosis taxa get `%woodystem` ~⅓, a `%habit` of
      tree|shrub|vine ~½ (intrinsic to the epithet), `%endemic` ~⅙; VoroScape tracks
       get a `%year` spread + `%live`/`%remaster` facts.  So the distiller has facts
        and spreads to speak, not just the list.  (Re-record picks these up.)

7. **Recursion** (was open c): see "Two modes of recursion" above.  Mode A's seed is
    BUILT (depth-1 `row:sub` openness for tiny mixed families); deepening it further
     (recursive fits, openness-per-pane memory) is `[pane]`; mode B (a subgraph in a
      cell) is deferred until A saturates.

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
