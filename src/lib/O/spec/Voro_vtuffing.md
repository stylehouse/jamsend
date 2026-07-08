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

### 🏛️ A:Tunnel — the compute grows its own home (architecture, greenlit 2026-07-07)

Today the whole Voro layer is a **parasite on Story**: a feature-toggle on `A:Cyto`
 under `H:Run`, engaged from the toc — `Opt/useVoroCyto` imposes the fold at snap time (or a
  Voro demo drives it inline), the ◈ button imposes on the Cyto mirror.  It rides Story's
   step metronome because Story is the most robust timekeeper we have — and Story's
    process supervision (start-check a run, damn+restart it, or let it wander into
     entropic runtime) is real tech worth keeping.  But a plaything bolted to a finite
      test-runner can only ever run *inside a Book*.

**The compute is already substrate-neutral — that is the whole hinge.**  `Voro_crush_scan(w)`,
 `Voro_crush_walk`, `Voro_report(w, stats)` take **a world and nothing else**; they
  read|write c-side on `w` and never reach into Story.  The ONLY Story coupling in the
   layer is the one line that *calls* them each beat (`Musuation.g` do_fn,
    `if (n >= 2) this.Voro_crush_scan(w)`).  So **A:Cyto-now vs A:Tunnel-later is a
     re-home, not a rewrite** — whoever holds the metronome (a Story step now, a Tunnel
      heartbeat later) drives the identical code.

**Why Story is the birthplace but not the home.**  The real Radiological sound land is a
 **toplevel app** — BigSoundland (`src/lib/V/`, `boot_qualand`, no Auto→Story chain
  above it).  Compute that lives *on* Story cannot ship there.  So the layer must
   eventually own a home that doesn't require Story — and that home is **A:Tunnel**, a
    first-class actor under `H:Run`, mountable directly by a toplevel app.

**What A:Tunnel earns — and only then.**  Two capabilities Story structurally can't give:
1. **A cadence off the step-grid.**  Story runs N steps and halts with a verdict; a
    *gently-turning-over* ambient landscape has no `done`.  Tunnel's own req-heartbeat
     turns the crush over continuously.
2. **A durable owner for history** — the load-bearing one.  Waves are **discarded**
    today (`Cytui gn.sc.waves = []`) and camera|positions **never snap** (pure live
     cytoscape state).  To "walk back the waves + your position + all their positions so
      everything looks exactly as it was WITHOUT re-running layout," something must
       **retain** what those two seams throw away.  On a transient Cyto mirror under a
        halting Story there is no such owner; on A:Tunnel it is a natural history ring.

**Story stays — promoted, not evicted.**  When Tunnel exists Story becomes its
 **supervisor** (start-check, damn+restart, release into entropic runtime); A:Tunnel
  **owns** the compute + history + camera.  Ownership and supervision are two jobs fused
   today only because there is one House.

**The one rule that keeps the port free:** the Voro layer never learns Story's name — it
 only ever "runs on a world."  (Already true; keep it true.)

Renders as the **🕳 tunnel** north star above: A:Tunnel is the actor that HOSTS the
 gently-turning drift that vision draws on the tube wall — same word, two faces (the
  render is the wall you see, A:Tunnel is the engine turning behind it).

**Owner vision seeds (2026-07-08, dropped at the edge of sleep — the navigation over the endless
 Travel).**  Six facets of ONE picture: the scape as a *living, Travel-able river of stuff* you
  move through endlessly, with content flowing in and a scrubbable wake behind you.  They are
   north-stars (pixel + core layout + interaction — none Book-gateable, all eyes-on), captured here
    so the destination stays legible; a few have near-buildable seams noted.
- **Dribble in from the edge or center.**  The *seeding/entry* policy (the open half of #10/#13):
   a new node is BORN at a source — the container centroid, or an edge portal — and flows outward,
    so it never starts life as an isolated viewport-giant (the runaway cell #13 chases).  A one-shot
     seed-position hint (metaphysics #1-legal: set positions, fcose disposes), NOT a servo.  **A
      `%Pier` is exactly such a source** — "VoroRadio feeding music from a Pier" = music dribbling in
       from the Pier node.  (This is the concrete, watchable instance — being built now as
        `VoroRadioPier`; the Pier IS the dribble-source.)
- **Swished around.**  The *motion*: #14's Lloyd/relaxation, then the owned-integrator's per-tick
   force sum.  Discrete swish = the #14 cage; continuous swish = the cage off (see §next-moves #14).
- **Trans-cellular filamentation.**  Threads that CROSS cells — relationships drawn as filaments
   spanning the tessellation (VoroScape's Peer-shares=edges, or a chain of Se, threading BETWEEN
    panes rather than only reading as shared walls).  A render concept atop the cells; pairs with Se
     chains (the filament is the wire a verdict travels).
- **Endless Travel, saving the trail.**  The drift tuner is already an endless Travel over folds
   (`Voro_drift_tick`, no `done` — the A:Tunnel "ambient landscape has no done").  Today it keeps a
    WINDOW (`drift_opens`, cap 4) + `radio_picks`; "saving the trail" = a DURABLE breadcrumb of the
     whole path (a Storyrun-grade trail record, c-side).  **Near-buildable** — a down-payment on it
      rides the `VoroRadioPier` build (keep the full pick trail, not just the window).
- **A light cone of stuff from the current point.**  From the Travel head, render the cone of
   related stuff — behind (visited) and ahead (reachable/candidate), the drift's own family+sibling
    scoring already computes the neighbourhood (`Voro_drift_tick` scoring at :860).  Visualising it
     is the pixel step.
- **Wind forward | back.**  Transport controls over the trail/waves — scrub the attention walk (or
   the wave history) rewind/fast-forward.  The manual `←/→` one-wave-per-fire (#11 waitVoro) is the
    seed; winding the TRAIL (re-focus to pick k, replay the cone) is the extension.
Taken together these ARE the Tunnel made navigable: dribble (in) → swish (settle) → Travel (through)
 → trail+cone (wake) → wind (scrub).  The radio is the autopilot; the human can also take the wheel.

**Status & frontier.**  Parameterisation is SETTLED (2026-07-07): the projection world is
 `w:Voronoiology` (one handle across all `Book:Voro*`), and the fold is IMPOSED from above —
  `The/Opt/useVoroCyto` folds a *data* Book at snap time (twin of `useCyto`), the projection
   self-reports always and is pruned only by `dontSnapVoronoiology`; the per-worker "blast" and
    every fold gate are gone.  A Book whose subject is NOT the fold never touches it (VoroScape,
     MusuReplica); a Book whose subject IS the fold drives it inline (VoroMitosis, VoroRadio).
      **The active frontier is now 🎋 Bamboo schematica** (below).  A:Tunnel and the radio are
       north-stars, NOT the next move — parked until bamboo lands.  Live-record state + the full
        design: `Voro_todo.md` §0 + memory `voro-imposed-from-above`.

**`w:Voronoiology` is a growing, subject-agnostic process-trace — and that is the architecture
 that scales.**  It records what the *layout* did, never what the Book is about:
  `Voro,beat,level:L0,visible,gangs,folded,count` — the same row over music, flora, or replication
   traffic.  The Book stays pure; the viewer reports on its own working beside it.  So a whole
    pipeline of processing can pile in without touching a single Book: each analysis is IMPOSED
     from above (or driven inline by a demo whose subject IS that analysis), SELF-REPORTS into a
      sibling world, and Story decides RECORDING per-Book with a `dontSnap*` flag.  Today the trace
       is one terse governor row; to go long it grows a real per-gang / per-genus / what-the-radio-
        popped account that can *name* what it acted on (a Book particle by mainkey) while never
         *being* Book-centric.  You don't widen the Book's snap as processing multiplies — you add
          sibling analysis worlds, subject-agnostic, independently recordable.  (This is the seed
           A:Tunnel's "separable snap channels" grows from.)

The microcosm cards (Voro_microcosm.md a+b) underexpressed: a VoroScape pane the size
 of a hand said "Track" three times, because the card text was the member's mainkey
  value and nothing else.  The molded Stuffings they replaced were rich.  Vtuffing is
   the owner's asked-for middle: **a Stuffing-grade data pipeline into a C\*\* that a
    dumb renderer fits into the cell shape** — the smarts .g-side and extensible the
     Waft way, the pixels staying pure.

### 🎋 Bamboo schematica + Se — the text gets structural, the fold reads its surroundings

**← THE ACTIVE FRONTIER (2026-07-07).**  Parameterisation is settled; this is the next build.

The owner, verbatim: *"when we get more bamboo schematica going on to make the text more
 rockin' it's going to get Se going on about what to do given the surroundings probably."*
  Two moves that arrive together.  **Bamboo schematica** is the next grade of Vtuffing: a
   pane's text stops being a flat string and grows a *schematic* — jointed, segmented
    structure (the bamboo) that reads at a glance.  It rides the pipeline already named
     above — a Stuffing-grade `C\*\*` the dumb renderer fits — so the smarts stay .g-side.
  Once a pane can SAY something structured, the fold wants an **Se**: a surroundings-reactive
   sense (the owner's word, kept verbatim) that decides what to do *given the neighbourhood*,
    not just the local count.  Today `Voro_crushable|swarmable` judge a node in isolation;
     Se is that verdict widened to read its siblings, what is popped nearby, what the radio
      is lighting — a context-aware fold.  **Not built** — the hook is a neighbourhood pass
       feeding the crushable verdict.

### 🔊 Quiet ↔ rampage — a throttle on the fold's thinking

The owner, verbatim: *"have some way to quiet or rampage its thinking sometimes."*  The
 **intensity governor already exists** (`Voro_crush_scan` hovers around a sensible density
  via `crush_level` + hysteresis).  What is missing is an *external dial* on its target band:
   **quiet** = think less — fewer passes, hold the current fold, let the display settle;
    **rampage** = fold harder — deeper descent, tighter panes, chew everything.  It is the
     partner of the display law the owner named in the same breath — *watching how the display
      changes with minimal disruption as processings toggle is important* — so the dial must
       MORPH between bands (stable node identity across a re-fold), never blow the layout up.
  Mechanism: a bias on the governor's target, sourced from a `◈`-bar toggle (live) or the
   commission (per-Book default), read where `crush_level` is chosen.  **Not built.**

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

10. **The loose-node snake — a node never arrives disconnected.** — **BUILT 2026-07-08 (eyes-on tuning owed).**
     *Landed (Cytui `install_snake`, was `install_nuclei`):* the per-parent flower of radial star-hubs is
      replaced by ONE shared snake — a chain of invisible `nucleus-edge` scaffold through every free/edgeless
       leaf, ordered `(parent, id)` so same-parent leaves sit adjacent (fewest cross-wall seams) and each leaf
        keeps a STABLE neighbour wave-to-wave.  That stability is what lets `apply()`'s existing `fresh_ids`
         pins localise a splice: a newcomer chains onto an already-pinned member and settles in place instead of
          re-tumbling the board.  `SNAKE_MIN=2` (a chain needs a neighbour; a truly lone leaf just floats, held
           by the pins — not a jitter case).  No hub node today; the legacy `.nucleus` node style is kept for
            the tether knob.  Two open knobs left for a live eyeball (below).  Verify by eye on a VoroScape /
             VoroMitosis tab with `%see` claims arriving late — the board should NOT snap to a diagonal.
     Owner, verbatim: *"uniformitise it then explode its diversity within.  no threshold … we always add
      nodes with edges rather than dropping them straight into a situation … set their location to some
       low-density corner of the thing (or a corner with other randomer simpler C in it) … meaningless-edge
        a snake of the randomer C together so everything can come+go with something else for stability."*
     The disease (found this session): a late, EDGELESS add — the witness `%see` claims — is a fresh
      DISCONNECTED component, and fcose's packer discards the grown rosette to re-pack the board into a
       DIAGONAL (Cytui `apply()`, the `fresh_ids` pin-newcomers note at ~:2000).  The nucleus
        (`install_nuclei`, the hidden per-parent hub free children star-edge to) is the existing cure but
         GATES at `NUC_MIN=3`, so a lone pair of `%see` slips under it and floats.
     The principle: **every free|simple particle arrives already threaded.**  Instead of a per-parent star
      gated on a count, keep ONE shared **snake** — a chain of MEANINGLESS (layout-only, never-snapped)
       edges through the `randomer simpler C` (the `%see`, and any other standalone leaf), seated in a
        low-density corner (or wherever the other loose C already sit).  A newcomer splices onto the snake's
         tail; a departure splices out; because each always has a neighbour, an add|remove settles LOCALLY
          instead of triggering a global re-pack — "come+go with something else for stability."  `NUC_MIN`
           drops to 1 (no threshold — "it's okay if there's just one of them").  It generalises the nucleus
            from a per-parent flower to a single come-and-go backbone: pure cytoscape scaffold, invisible,
             off-snap, skipped by the tessellator + rack exactly as the nuclei already are.  Whether the
              snake stands alone in its corner or tethers into the main cluster is the one open knob (a
               stray-but-tidy blob vs one component) — decide with eyes on the first build.  `[scan]`-adjacent
                (Cytui layout / graph topology): view-only, no snap|fixture churn.  **Then** the big **🎋 bamboo**
                 — uniform engine panes, diversity exploded within.

11. **The wave cadence — animate every wave, and WAIT for the voronoi morph (waitVoro).** — **BUILT 2026-07-08.**
     The tell: manual `←/→` stepping always animated beautifully; only *auto play-through* fell apart (giant
      flashing panes, no coherent division).  Cause: the `$effect` drains a whole *batch* of waves at once
       (Lang emits them faster than Cytui reads — Cyto queues them), and `enqueue`'s **yoink** collapsed every
        wave after the first at `dur=0` — no animation.  Manual stepping sends one wave per fire, never batched,
         so it looked great: the batch-collapse, not the animation, was the fault.  Fix (`Cytui.svelte`
          enqueue/process_queue): no more yoink; each wave plays in full and the *next one waits* — **animCyto**
           (the cyto layout, `BURST_DUR` while a batch drains) runs, then **animVoro** (the voronoi morph) takes
            the stage, and only after the morph has had time to reach its settled paint does the next wave run.
             The old advance timer paid for the layout leg only, so the next wave's `hide_overlays_now` cut the
              morph short.  A `MAX_ANIM_BACKLOG` valve fast-forwards a genuine flood.  Owner's own model: *"a
               req:animCyto finishes after each animation, but before it does a %maz lets its /req:animVoro take
                on the task of responding"* — implemented as a settle-gated advance, not the belief-loop reqs
                 (frame animation is the wrong substrate; [[req-not-mandatory]]).  OPEN: it's a fixed budget
                  sized to the morph, not an event fired off the morph's real completion — make it event-driven
                   if the budget ever feels off; and `MORPH_MS`/`BURST_DUR` are the pace knobs.

12. **The diagonal — stop it firing involuntarily; then make it VOLUNTARY.**  The "diagonal reconfiguration" is
     fcose's component **packer** arranging ≥2 disconnected components — it fires on ANY *un-pinned full relayout*
      of a graph that HAS disconnected components.  Known triggers: (a) a late edgeless add — the `%see` claims —
       the original #10 disease; (b) **HMR of Cytui** — an `$effect` re-runs on hot-update and fired a bare
        `relayout(400)` — **FIXED 2026-07-08** (`Cytui.svelte:97` now relayouts only on a real engine switch,
         primed on the first wave, null-safe across HMR); (c) a **nav >1 step away** — a non-adjacent seek sends
          an `absolute` wave (`Cyto.svelte`: `adjacent = !absolute`), and `apply()`'s absolute branch wipes and
           re-adds every node FRESH → `saw_stuffy=false` (cells vanish until the stuff nodes re-arrive) AND no
            `fresh_ids` pins → the packer draws the diagonal.  So "cells vanish at step 6" was a *jump to* 6, not
             a play *into* it (the recorded step-6 wave is a plain incremental add).  (d) manual `⟳`.
     Cures share a root — **don't hand fcose a disconnected graph un-pinned**: thread/cluster the loose leaves
      (the star-not-chain seed fix, or the #11-cell relaxation which pulls an isolated seed back), and on the
       absolute-rebuild path either PIN what carries over or re-detect `saw_stuffy` before laying out.
     Owner wants the diagonal kept as a *deliberate* layout mode too (they admire it) — expose it as a chosen
      pack/scatter option rather than only ever an accident.  `[scan]`-adjacent, view-only.

13. **The star-not-chain seed fix** (immediate, precedes #14).  #10's snake threads *every* free leaf into a
     CHAIN, including the voronoi seeds (edgeless fold-chunks under the compound `w`).  A chain SPREADS seeds
      along a line; each cell starts as the whole container polygon and is only cut back by *near* neighbours, so
       an isolated seed keeps a viewport-spanning cell → a Stuffing "blown up larger than the viewport, clipped."
        The old per-parent flower CLUSTERED the same seeds into a rosette (good cells).  Fix: make the loose-leaf
         scaffold a **star** (one shared hub) not a chain — one component (keeps the diagonal fixed) but clustered
          (restores cell sizes).  ~10 lines in `install_snake`.  Cheap band-aid that #14 subsumes.

14. **Cell-quality relaxation — Voro proposes, Cyto disposes** (the general cure for bad cell shapes|sizes).
     The metaphysics (`Cyto is the engine, Voro interprets — pixels never push back, ZERO exceptions`) bans a
      *continuous servo*; it does NOT ban a *discrete, terminating* correction.  So: ONCE per structural graph
       change (a `layout_gen` latch; "or less" — skip when every cell already passes), **analyse** the cell layer
        (area vs median, frame-contact = the runaway giant, seed→centroid offset, sliver aspect), **decide** a
         Lloyd nudge for the flagged seeds only (`target = lerp(seed, centroid, λ)`, clamped to a max px kick),
          and **do** it as a *seed hint*: write the nudged positions and run ONE fcose pass with the good nodes
           pinned (the existing `fresh_ids`/`fixedNodeConstraint` path — "treat flagged seeds like newcomers, pin
            the rest"), then morph.  The relaxation's own re-layout does NOT bump `layout_gen` → it can't re-arm
             → it terminates; Lloyd is contractive so the single step is a guaranteed improvement, never an
              oscillation — exactly the property the ZERO-exceptions rule protects.  It subsumes #13 (an isolated
               giant cell pulls its own seed back toward the crowd) and softens #12 (fewer runaway components).
     `[scan]` (writes cyto positions) — prove in ISOLATION first ([[fight-back-on-core-changes]]).
     **#14 is the LAST feedback we can cleanly run THROUGH fcose — and the pilot for the one we can't.**
      Everything the current system affords is a ONE-SHOT hint fcose then *disposes* (set positions, pin,
       scaffold-edge, tweak params); it cannot host a *running* per-node program, because between passes fcose
        re-minimises its OWN objective and owns the state.  That is why metaphysics #1 ("pixels never push back —
         ZERO exceptions") is not merely taste: a *continuous* servo through fcose would RING — fcose is not our
          integrator.  #14's cell-quality metric is the FIRST **Se** in the geometry domain (§🎋): a node forming a
           verdict by reading its surroundings (its cell + its neighbours' cells) and acting — the geometry twin of
            `Voro_crushable`.  To CHAIN Se (Se₁ bad-shape? → Se₂ pull-to-family-or-centroid? → force) and to
             "program via the graph", a node must carry little verdict-programs on its `.c` and *something must run
              them each tick* — which fcose structurally cannot give (no per-node program, no owned tick).  So the
               deliberate BRANCH, when chains of Se are wanted, is a **Voro-native relaxation tick that owns the
                state**: fcose demoted to the initial *seeder*, our own loop integrating a SUM of per-node forces
                 (Lloyd + family-attract + repel + radio-pull + Se verdicts) — Mode B's "hand-rolled mini-force pass"
                  generalised from inside-one-cell to the whole board.  Don't branch for #14; DO build it as the
                   one-shot cage NOW (safe, contractive, terminating), because taking the cage off — the SAME
                    analyse→decide→do kernel, run every tick under our own integrator — IS that branch.  #14 de-risks
                     it: prove the metric + nudge with eyes on, and the hand-rolled substrate is "own the tick".

*Seed→cell→mold, for the record (surfaced 2026-07-08 chasing VoroScape).*  A node earns a **cell** only by being
 a `stuff` seed — either the crush emits `overlay_kind:stuff` (a fold chunk) or proper-mode mounts a Stuffing on a
  loner whose mainkey ∈ `PROPER_KINDS = {'see'}`.  On VoroScape the imposed crush is folding NOTHING (`folded:0`,
   snap `stuff=0`), so the only seeds are `req` (arrived as a wave stuff node) + `see` (proper loner) — "a bunch of
    nodes didn't make it to a cell" because they are neither.  Those two show as **molded Stuffings** (the Stuffing
     skewed/clipped into the cell — "skews into place kinda nice but often has bits occluded"), NOT the row-fitted
      **Vtuffing**, because Vtuffing needs a fold WITH MEMBERS to lay into the cell and a lone see/req has none.
       So the missing cells are really **missing folds** — open thread: why VoroScape's imposed crush produces no
        gangs.  (Vtuffing, the occlusion-free successor to the molded Stuffing, is the near frontier — see §🎋.)
