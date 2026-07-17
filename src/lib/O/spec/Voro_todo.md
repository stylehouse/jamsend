# Voro_todo — the stained-glass grind list

Task list for the Voronoi luxury layer. Written to be picked up COLD, one task at a
 time, by a session that has not read the whole arc. Read **The metaphysics** first;
  every task below must leave it intact — a pretty result that violates one of these
   rules is wrong work, not partial credit.
 The arc + bombs + frontier live in **§0 below** (rewritten each handover). The durable
  spec: `Radio_spec.md §8`; the system doc: `Voro_vtuffing.md`. Two subordinate detail docs,
   both led by §0: `Voro_render_todo.md` (the render-wave/three-layer detail) and
    `Voro_render_faults_todo.md` (the render|animate fault catalog).

## 0 · Handover  (rewrite this section each handover; everything below stays current)

> **NIGHTSHIFT?**  If you are the unattended agent: read this §0 for the arc, then execute
>  `## Nightshift orders` below EXACTLY — the shape order, the per-shape loop, the file fence.
>   The doctrine you build under is `## The Se process`; the shapes are `## The VoroTest roster`.

**THE ARC in one breath.**  The Voronoi layer turns the live Cyto graph into stained glass: the
 crusher (`Ghost/V/Voro.g`, c-side stamps only) folds MANY+homogeneous behind `%stuff`, and the
  ▦ engine (`Cytui.svelte`) makes every pane SPEAK its particle — honestly (nothing hidden, every
   fold annotated), generically (no data key special anywhere), in one grammar (the VStat
    statement), laid out radially (the kind-C at the core, its facts on the belt, its members
     around the rim — the owner: *"like a cell-wall around its nucleus"*).  The engine is now
      being re-cleaved into a **three-layer** shape (the human's 2026-07-12 decision): a
       *universal data clumper-sprawler* with ZERO mainkey knowledge in the code — the grasp/ghost
        decides WHAT (the Se model: membership, weight, order, loudness, drift — snap-testable in
         Books without pixels), pure derivations decide WHERE (geometry — hull/clip/tessellation/
          river spines), and **Cytui shrinks to WIRING + PAINT**.  DESTINATION: continuous washed
           REGIONS with big clean **letterform arcs (I/C/S/O)** drawn through them, the grasp's
            aligned tuples flowing as a *river of one kind of data threading through another*,
             Wes-Wilson poster lettering warped along the river tangents — landscapey, not
              panes-with-labels.  (The human's ~97% doctrine: **mainkey = type/provenance**;
               non-mainkey keys still matter as facets — don't overstate it.)  The render faces we
                evolved through are SAVED: `voro_modes/README.md` (a ledger — commit anchors + live
                 SVG shots; revive any face via `git show <commit>:src/lib/O/Cytui.svelte`).

**⚠ BOMB — "I'm not seeing any changes" = a STALE BROWSER CACHE, not your code (2026-07-15).**  A
 whole live session's Cytui edits appeared to "not land" in any tab.  The dev server was serving them
  FINE — proven by fetching the bundle directly: `node -e 'fetch("http://172.17.0.1:9091/src/lib/O/
   Cytui.svelte").then(r=>r.text()).then(t=>console.log(/vsub_grab/.test(t)))'` returned the current
    code.  Every browser tab (even a freshly-opened one) was pinned to an OLD cached copy — the tell is
     `runner_shot --arm` replying `no cy_face hook — this tab runs an old Cytui`.  `runner_ask reload`
      is a SOFT `location.reload()` and reuses the cache, so it can't fix it (and neither can HMR once
       its socket dies).  FIX is human-side, quickest first: (1) HARD reload the tab (Ctrl/Cmd+Shift+R);
        (2) DevTools → Application → Service Workers → Unregister (an OLD *caching* SW version can linger
         — the current `src/service-worker.js` caches nothing, pass-through); (3) restart the Vite dev
          server (re-versions every module).  Until a tab is hard-reloaded, NOTHING you ship is visible
           to anyone — don't chase a phantom bug in the code.  (RESOLVED 2026-07-15: the human hard-
            reloaded, the "Artist?" canary showed through, propagation confirmed, canary REVERTED.  Keep
             this note — the failure mode recurs every long session; reach for the bundle-fetch proof first.)

**WHAT LANDED THIS SHIFT, PART 8 (2026-07-15) — the K-round: the crater REDRAWN as an explicit nested
 lining, + VoroScape given real depth.**  The human, after PART 7: *"no, nothing like the Cradle effect
  I'd like is there"* — PART 7's rim only thickened the nucleus outline and still LEANED ON the flat cell
   background to imply the C.  New steer: *"the cratering effect having more depth, trying to get one
    around the Artist as well as Track … don't rely on the outer cell, draw a crater that lines it."*  And
     the north star: *"for now I want to reliably communicate C structure via vtuffing."*
 - **CRATER = EXPLICIT NESTED BASINS** (`crater_pane`, Cytui, paint-only).  Added the **Artist basin**:
    two stepped inset rim contours following `c.inset` (`poly_grow -3` / `-7`, `vsub-abasin`/`-abasin2`,
     `fill:none` via stylesheet beating the `fill=""` attr) + a soft top-edge inner shadow (`vsub-abasinsh`,
      the carved lip).  The Track nucleus (the old coag) now nests INSIDE it — **basin-within-basin draws
       the Artist⊃Track nesting** instead of relying on the background.  Insets are px, so they hold at
        every cell size (R≥40 leaves room for −7).  Type-clean (113 baseline, no new errors).  **NEEDS THE
         HUMAN'S EYES** — third crater attempt; if still not it, STOP guessing and align on the look (an
          ASCII/shot round) before a fourth.
 - **VoroScape DEEPER C** (`Voronation.g`, gen rewritten via LocalGen — editor was DOWN, ghost-compile
    couldn't reach it).  `VoroScape_track` now RETURNS the track; new `VoroScape_section(host,name,s,e)`
     mints `%What:<name>,start_at,end_at`; `VoroScape_library` deepens **Tide → What:the-spot(3–6) →
      What:cymbal(4–5)** — a genuine Track/What/What for the crush to fold (music-book twin of the depth
       VoroMitosis already has via `Botany_plant` forms).  **⚠ DRIFTS THE VoroScape FIXTURE** — its
        toc.snap needs the human's re-record (I did NOT run the Book or touch any toc).
 - **COPROSMA-LIE ORDER FIX LANDED** (the human chose this next; Cytui `tuple_rows`, PAINT-ONLY — no
    distiller change, so NO fixture drift / re-record).  The human quoted the exact render ORDER as the
     lie: `Coprosma / woodystem / habit:shrub|vine / propinqua / rhamnoides` — facets ABOVE the species,
      reading as genus content.  ROOT CAUSE (not the pooling I first guessed): the distiller ALREADY
       emits the honest order (`Vtuff_default`: title → member_rows → keyrows), but `tuple_rows` REVERSED
        it (facts led — a holdover from when they were the container's own).  FIX: a homo gang's bare
         members (its `%Genus:value` instances) now flow DIRECTLY under the identity; their shared|partial
          traits follow, reading as "across these".  Cross-kind folds untouched (members ride a lead
           tuple → `members` empty → order stands).  Type-clean (113 baseline).
    (i-next) **DEEPER Coprosma honesty (OWED):** the traits stay POOLED (shared across the species), not
        each-species-carries-its-own.  "Keep each member's value+facts together" fully = a sub-basin per
         species (the crater/C-spaces B1 path) — HELD because (deferred text-fit) per-member facts = more
          text that fights the current seat.
    (ii) **text-fit "import help?"** — see the fork below; the human leaned *"for now … reliably"* =
         reliability pass now (never drop to bare label, never clip past the wall, grasp the width), the
          heavy solver later.
    (iii) PART 7's (a)/(b)/(c) still want the human's confirmation once they're back at a live desk.

**WHAT LANDED THIS SHIFT, PART 7 (2026-07-15) — the AWAKE punch-list (human hard-reloaded, seeing it
 live, firing precise steers; all Cytui paint-only, gen unchanged).**  The J-round walked ALL the way
  home + the cradle made to actually read:
 - **KIND CHIP FULLY DE-BOXED** (the human: "the soft tinted field … I don't want it, just the regular
    colour-coded key visual would be better. standard!").  Dropped `box:true` at both mint sites, the
     `vsub-kindbox` rect, and the `vsub-kindlabel`/`vsub-kindbox` CSS.  The kind is now a plain
      colour-coded word (inline `kind_tint`), reads exactly like any key by its hue.  Canary `?` reverted.
 - **Both bottom badges GONE** (the human: "the +1 and /*3 … I'm not wanting").  `/*N` dip removed
    (`pane.dip` no longer assigned): it looked like a fold-OPEN control but `Vtuff_pop`'s stamp is
     ONE-WAY — "opens, no way back" — a trap, not an affordance.  `+N` crowd-out mark no longer PAINTED,
      but `sp.hid` still rides as DATA so the growth spell keeps swelling a cell until everything seats
       (the fold heals by GROWING, not by confessing a count).
 - **CRADLE MADE TO READ** (the human: "the C-cradle — I don't see at all … it's supposed to be around
    every C?").  Root cause: the nucleus rim was the nucleus's OWN hue, so the C only showed if the cell
     background happened to contrast.  FIX: rim the nucleus in the CONTAINER's tint (the Artist) at
      opacity 0.85 / width 2 — the wrapping level now draws its own wall regardless of hue family.
 - **HEADER NO LONGER DRIFTS TO A CORNER** (the human: "the Artist … renders nowhere / clipped / drifted
    down into a sharp corner").  Root cause: `pane_rows` rotated the identity baseline to the biggest
     wall, tilting it into a slanted slice's point.  FIX: new `norot` opt on `pane_rows`, set for the
      header arm — the identity reads LEVEL.  (Nucleus body still follows the wall.)
 - **TEXT BLOAT-UP** (the human: "just a bit more text bloat-up needed").  Spell legible floor 11→12,
    grow ceiling 2.4→3.0 — cells swell until load-bearing atoms clear 12px, which also floats more cells
     past the crater threshold (more cradles surface as a side effect).
 - **DRAG-BLINK FROZEN** (the human: "only occasionally after|during dragging … it blinks").  `spell_update`
    early-returns while `vdrag` is active, so a grow|shrink verdict can't land on a drag repaint frame.
 - **STILL OWED / needs the human's eyes (do NOT blind-tune further):**
    (a) **is the cradle on ENOUGH C's now?**  I HELD the `R < 40` crater gate — the beefier spell should
        float more cells over it, but if the human's cells are just small, that gate is the knob to drop
        (40 → ~32) once they confirm the rim+header look right on the ones that DO crater.
    (b) **did the rim + norot actually kill the corner-drift?** — reasoned, not shot-verified.
    (c) the residual **drag-blink** should be gone with the freeze; confirm.
    (d) the **academic text-in-polygon puzzle** (the human: "should we import help?") — the honest answer
        is our `pane_rows` chord-seat + inflate is a hand-rolled solver; a real library (e.g. a
        constrained text-layout / SAT-style fitter) is a genuine option if we want justified arcs.  Parked
        as a real fork in the road, not a bug.

**WHAT LANDED THIS SHIFT, PART 6 (2026-07-15) — the LIVE SESSION (the human firing steers over HMR;
 all Cytui paint-only, gen unchanged; UNVERIFIED-BY-SHOT — stale cache above; review on hard-reload).**
 - **DE-BUTTON the kind chip** (walks back J2/J3): `vsub-kindbox` lost its stroke + glyph-stretch → a
    faint tinted field hugging the word, not a button.  `vsub-kindlabel` natural width, weight 500.
 - **NAME-DROP fix** ("sometimes Artist only appears, no name:Riverine"): the narrower chip + (originally)
    a taller header floor; now moot under the C-cradle (identity owns the whole top arm).
 - **C-CRADLE crater** (the human picked it over artist-bowl / nested-craters): the coagulate is a
    NUCLEUS inset to the centre-right (`clip_halfplane` ×3), the cell's OWN Artist tint wrapping it on
     THREE sides — TOP arm holds the identity, LEFT spine + BOTTOM lip close the C, opens right.  "A
      cell-wall around its nucleus."  Replaced the header-band split + the chord huddle (identity sits
       at the top by construction → same-kind cells huddle for free).  Arms are cell-fractions → the C
        scales with the spell.  R<40.  OPEN refinement (not done): echo the name on the BOTTOM arm (the
         human's sketch showed it) — held back as speculative-blind until the cache clears.
 - **DRAG THE ARTIST** ("wire the drag to the cytoscape node underneath that cell"): the identity
    (`vsub-ntitle`) is a grab handle → `vsub_grab/move/drop` set `cy.getElementById(sp.id).position()`
     + `pan_zoom_motion()` (live re-tessellate, like the gravity brush); WINDOW listeners survive the
      re-render; yields to a running layout.  Moves the RIGHT node (a seed sits anywhere in its cell).
       The manual way to free a TRAPPED cell (the human's alt to an auto-repulsion spell — parked, #46).
 - **THE BLINK was `wants_crater`** (my grow-then-crater bug): flagging every readable flat fold to grow
    → a zero-sum re-paint STORM that flipped cells crater↔flat → toggled the Stuffing overlay opacity.
     REVERTED.  Kept the htitle<11 legibility gate (small folds stay FLAT-and-readable = the "text is
      very small" fix) + the existing `tiny()` spell (grows a genuinely-tiny flat fold until it craters).
 - **SPELL HYSTERESIS** ("turn itself off only once the cell becomes even bigger than the size — it was
    oscillating on+off"): wide HOLD band — grow while starved, hold once it seats, only LET GO once the
     cell is clearly oversized (`roomy` = content fills <42%, was 60%); gentle steps (1.15/0.95); never
      shrink a cell that grew this pass.  So too-small→grow, big-enough→hold, way-too-big→ease off.
 - **HOVER-ESCAPE** ("the hover effect can get stuck on … a catch to escape it"): a mid-hover
    re-tessellation strands the reveal (corr_hot lights by stable particle ref, ribbon by cell id, so a
     lost mouseleave sticks).  `corr_clear()` wired to Escape, to leaving the graph (wrap pointerleave),
      and to drag-start.
 - VERIFY LIST when a tab is finally hard-reloaded: (a) canary "Artist?" shows → REVERT it; (b) kind chip
    reads as a soft field not a button; (c) crater is a C — Artist tint wraps a pink nucleus, opens right;
     (d) grab the Artist name → the cell moves; (e) no blinking; (f) the spell settles (no on/off flutter);
      (g) hover a chip then press Escape / leave the graph → the highlight clears.

**WHAT LANDED THIS SHIFT, PART 5 (2026-07-15) — the FINAL steer: walking the J-round back.**  After
 seeing J2/J3 live, the human: (a) a research question — "someone has already built this fitting-text-
  exactly-into-polygons trick aye … what can I google?"; (b) a bug — "sometimes Artist only appears, no
   name:Riverine"; (c) a J2 walk-back — "the button-looking mainkey is more confusing and visual noisey,
    though that that's the start of a C (eg the inner Stuffing Track) is clear"; (d) a new ruling — "the
     crater should always be there! that'll communicate it better."  All Cytui paint-only, gen unchanged:
 - **P5.1 de-button the kind chip (walks back J2+J3)** — the pill was a filled+*stroked* rounded box
    with a `textLength` glyph-*stretch*: that chrome (border + pill + spaced-out label) is what read as a
     BUTTON.  Now: `vsub-kindbox` has **no stroke**, fainter fill (0.13), a small radius (`fs*0.16`),
      hugging the word; `vsub-kindlabel` drops the stretch + tracking and sits at natural width, weight
       500.  Still clearly "a C begins here" (tinted field, the TYPE) — just no button.  The J3 stretch
        is REMOVED, not iterated (the "Michaelangelo stretch text into place" want lives on for row
         justification / the polygon-fit research below, not the kind label).
 - **P5.2 the name-drop ("Artist only, no name:Riverine")** — the identity title is two atoms
    (`[kind-chip][name]`); in a header band only ~one line tall, the name WRAPS then hits the vertical
     floor and gets DROPPED (`flow` sets `dry`, counts it to `hid`), leaving a lonely kind.  Fix, two
      independent mitigations: the de-buttoned chip is **narrower** (`atom.len` box reserve 2.2→1.0, no
       stretch) so the title wraps less, AND the crater **header floor rises 26→42px** so a wrapped
        two-line identity ('Track' / 'name: Riverine') has a landing (honours H2 wrap).
 - **P5.3 crater ALWAYS for a fold** — the size/legibility self-gates are relaxed: `R<60`→`R<34` (only a
    sliver too small to draw a coagulate at all falls back) and the header `htitle<9 → flat` self-gate is
     **removed**.  A cross-kind fold now KEEPS its crater even a beat cramped; the growth SPELL (tiny<11)
      swells it legible over the next beats — communicating the fold beats waiting for room.  The
       `mem.length<2` gate stays (no fold structure = genuinely nothing to crater) and the pure-geometry
        gates (`!hres`, `coag.length<3`, `!bres`) stay (un-drawable → flat, and the spell still grows a
         flat cell toward a future crater).
 - **P5.4 the research answer (polygon text-fitting, for the human's google)** — the trick has names:
    **"pole of inaccessibility"** (largest inscribed circle → the label anchor) = Mapbox **`polylabel`**;
     **text-on-path / textPath warp** along a spine (SVG `<textPath>`, `opentype.js` glyph-path warp,
      `paper.js`, `Blotter.js`); **word/typographic packing in a shape** — search "wordcloud polygon
       mask" (`d3-cloud` + mask), "packing words into a shape", "shape-aware text layout"; **conformal /
        harmonic warp to a region** ("conformal text mapping", "as-rigid-as-possible text warp"); and for
         the Wes-Wilson river feel, "text warp along curve", "variable-font optical-size fit", "Skia
          paragraph shaping".  `polylabel` + `<textPath>` on the river spine is the closest ready pair.
 - **VERIFY: LIVE SHOT STILL OWED (blocked).**  The one idle machine-runner (`20e3476b`) is wedged on a
    STALE cached bundle — its `location.reload()` (via `runner_ask reload`) won't cache-bust, so it keeps
     reporting `no cy_face hook — old Cytui`; a shot of it wouldn't carry these edits anyway.  The only
      tab with the new Cytui is the human's ★editor (HMR-live — that IS the review channel), off-limits
       to a shot.  Type-clean (check: 0 errors in the edited ranges), paint-only + fixture-safe.  Shoot
        when a *fresh* idle runner frees (or the human hard-reloads `20e3476b` / restarts the dev server).

**WHAT LANDED THIS SHIFT, PART 4 (2026-07-15) — the J-ROUND: after "hover behaviour is really
 nice."**  Three asks, all Cytui paint-only: **J1 the gap** — the inline gkey ran "Track" into
  "title" ("Tracktitle:") because its separator was a bare SVG space (collapses); the kind is now
   its own atom (flow-spaced) + a non-breaking-space separator on the shared-atom paths.  **J2 the
    kind in a subcell** — Artist/Track "look like properties otherwise", so the kind label (header +
     gkey) is split into a `box:true` atom drawn as a tinted rounded pill (`vsub-kindbox` +
      full-size `vsub-kindlabel`), reading as the TYPE not a property; the badge-dedup still holds.
       **J3 Michaelangelo (first cut)** — the kind label STRETCHES (`textLength`/spacingAndGlyphs)
        to fill a min-width pill so kinds align (poster-lettering feel); fuller row justification is
         the continuing "stretch text into place" direction.  VERIFY: the idle runner fleet vanished
          mid-round (only the human's ★editor up) — no shot yet, but the edits HMR into their live
           tab; type-clean + paint-only (fixture-safe).  **LIVE SHOT OWED** when a runner frees.

**WHAT LANDED THIS SHIFT, PART 3 (2026-07-15) — the I-ROUND: the human live at the desk, over the
 H-round craters.**  Steer in pieces: "there's a year:2007 that looks like part of Artist but those
  ARE the Tracks" (grasp, from H) → "it still wants more maxing out the space … inline-text up against
   the ceiling" → "we say Track,title:… then also year:… the laters should just be eg year:" →
    "so many Artist cells, they should collaborate to huddle the Artist part up one end" → "the
     Stuffing blob is gradiented the wrong way … Artist says it's supposed to be Teal but it's pink
      like Track" → "put a spell on the cell to grow it, until the cyto gets it more than enough
       space and we remove the spell" → "the hourglass ribbons could be not there until you mouse
        over the cell they're in."  All Cytui-only, gen unchanged.  In order:
 - **I1 cell hue = what the cell IS** — `cell_color`/descmap tint: a GANG rep wears its members'
    `fold_kind`, a REAL container wears its OWN mainkey (Artist→teal `#298699`); the members' pink
     lives on the coagulate.  (Was: every fold preferred fold_kind → Artist cell went Track-pink.)
 - **I2 inner shadow** — a 2nd linearGradient over the coag (black 0.32→0 over 34px at the header
    seam) so the parent-facing edge reads sunk-in; the depth grad (transparent-from-parent) stays.
 - **I3 badge dedup** — the kind badge shows on the FIRST row of a tag run, the rest bare
    (`Track title:` then `year:` `remaster` `live`).
 - **I4 central unfoldment** — inflate ceiling 1.35→2.0 + a centering re-layout (drop by half the
    spare height, kept only if all atoms still seat) — text fills its room, centred not top-jammed.
 - **I5 huddle** — the header seats at the HIGHEST chord that holds the title (~full width), else
    the widest chord — same-kind cells align their container level at one end without starving.
 - **I6 the GROWTH SPELL** — `vspell` per-cell multiplier on the seed's content box (voronoi_layout
    reads it; the power walls do the growing, no cytoscape touch so the stream keeps flowing).
     spell_update at paint-end: STARVED (degraded | +N | a load-bearing atom <11px) grows ×1.18/beat
      cap 2.4; ROOMY (used<60% avail) decays ×0.93 to lift; SNUG holds.  Dead band = no flutter;
       re-paints rAF (visible) / queueMicrotask (hidden tab).
 - **I8 ribbons hover-gated** — H5 hourglass ribbons out of `walls` into `sp.ribbons`, drawn only
    while `ribbon_pane===sp.id` (enter/leave on the coag path); the resting glass is clean again.
 - **I9 self-gate on the MIN identity atom** — the badge can seat fat while the wrapped name floors
    to 7px; gate on the smallest ntitle (floor 9 — borderline keeps its crater + the spell grows it;
     below 9 → flat).  GATE (4 runs, runner 20e3476b, arm-first): Clinic + Scape + flora all green;
      teal cell / pink coag, badge-dedup, ribbons-0-at-rest, flora-0-coags hold EVERY run.  What's
       ENTROPY-VARIABLE and therefore eyes-gated on the live tab, NOT pinned by static shots: exact
        px (8–16 min as the spell settles vs a shifting layout), crater-vs-flat count (1–2), which
         cells crush (Scape went 4-teal↔5-teal run-to-run).  A flat cell reads every row fine, so
          flat is a fine outcome — don't chase the crater count through shots.

**WHAT LANDED THIS SHIFT, PART 2 (2026-07-14 later) — the H-ROUND: the human's correction of the
 orbs.**  The steer: "you've misunderstood the black blur thing — I mean mouseover|click handlers
  all over the tuple, any one of the v we click on shows what other $v and $k are involved in it …
   I didn't intend a crater per C (ie tuple) — an entire Stuffing+Stuffusion, just ONE in each cell
    … conserve Track,title: … hourglass-like edges between the year|remaster|live and the title …
     the Artist and Track should be fairly uniform size … you can wrap Artist\nname:Palegold …
      a background gradient on the subcell, going transparent from the parent side."  In order:
 - **H1 one coagulate per cell** — the per-member orbs (G3's misread) are GONE; a crater is now
    header strip (container level) + ONE smooth coagulate holding the member band's DISTILLED rows
     (`keyed_rows(memb)` — the lead list + tagged facts|spreads, 'title:' said ONCE).  member_rows,
      the key universe, the static blur rows, clip_to: deleted.
 - **H2 wrap at grammar seams** — the title is TWO atoms now (kind badge · name:value), so a narrow
    cell wraps '⟨Artist⟩ / name: Palegold' at full size instead of shrinking one long atom.
 - **H3 uniformity** — inflate zoom ceiling 2.4 → 1.35: titles top out ~21.6 instead of 38.4, and
    narrowness wraps (H2) instead of shrinking — all w/C/* cells converge on one voice.
 - **H4 correspondence** — Vtuff_keyrows stamps `c.members` on every fact|spread chip (c-side,
    fixture-safe; gen landed); paint: hover ANY claim chip → its carrier member chips + one-hop
     sibling claims LIGHT (corr-lit); hover a member chip → its claims light and every claim it
      LACKS takes the black blur (corr-dim — THIS is where the human's "black blurs over %remaster"
       lives, absence revealed on touch, not static rows); click PINS a claim chip (member click
        stays the pop).  Scoped per-pane via corr_pane_id.
 - **H5 hourglass ribbons** — `corr_ribbons`: a faint band from each claim chip to each member chip
    it speaks for, pinched to a waist (both edges through one midpoint), capped at 14, crater-only,
     R>90.  UNVERIFIABLE until the Clinic seed gen lands (title-only tracks have no value chips).
 - **The parent-side gradient** — the coagulate's fill is a per-pane linearGradient (userSpaceOnUse,
    hband → far wall): transparent at the parent seam, the members' tint deepening away — depth
     without a drawn shadow (VSubPane.lgrads + VWall.fillid channels).

**WHAT LANDED THIS SHIFT (2026-07-14 late, autonomous) — the G-ROUND: grasp levels + orbs.**  The
 human's steer on the live craters ("nice! there's a year:2007 here look like its part of
  %Artist,name:Palegold, but those ARE strictly part of the Tracks … some of these Artist,name bits
   are really small. they must be the biggest! … each C coagulate should have quite a smooth shape …
    overlapping orbs … it's got to be visually clearer where the individual groupings are … two
     different C/C levels cannot share data descriptions … but C/n/* and C/m/* can think about
      alignment of their tuples across the boundary of their cells").  Uncommitted: `Ghost/V/Voro.g`
       (+ gen), `Cytui.svelte`, `Ghost/Story/Voronation.g` (seed enrichment, **gen NOT landed** — see
        the wedge below), this doc.  In order:
 - **G1 model** — `Vtuff_keyrows` now stamps WHOSE LEVEL each fact/spread lives at: per-key carrier-
    kind attribution (all carriers one kind ≠ container kind → the row wears `tag:<Kind>`, same rule
     as B0.1's list tag).  A %year distilled off %Tracks can never again read as the %Artist's.
 - **G1 paint** — `subgraph_tuples` threads the tag; flat panes BAND by grasp level (title + container's
    own untagged facts / lead list / the members' tagged facts, each wearing the kind chip); a crater
     HEADER speaks the container's level ONLY (`!g.lead && !g.tag`) — the member facts show inside the
      craters, where they strictly live.  Nothing dropped; the boundary kept.
 - **G2 identity ceiling** — `pane_rows` gained `capfs` + the LEAD CAP: once the identity row lands,
    every later row is capped at its size ×0.92 (whatever shrinks the identity shrinks the rest under
     it); craters pass `capfs = header_title_fs × 0.9` so no %Track ever out-sizes its %Artist.
 - **G3 coagulate + orbs** — the member group wears ONE smooth shape (`chaikin(poly_grow(bodyPoly,-3))`,
    the STRONG level boundary, in the members' kind tint) and each member's power cell becomes an ORB
     (grown +4.5 past the power gap so neighbours OVERLAP — soft same-level seams — rounded, clipped to
      the coagulate); the mini pane flows INSIDE the orb (rounded corners are kinder to text than the
       acute power corners).  The header/body separator rule dropped — the coagulate boundary IS the line.
 - **G4/G5 absence blurs + alignment** — each crater builds the fold's KEY UNIVERSE in global vein rank
    (same key, same row, in every orb AND across cells — the licensed same-level alignment); a key a
     member LACKS renders as a black blur of the key word in place (`vsub-blur`, blur(1.6px)) — 'no
      %remaster' reads as loudly as 'remaster'.  Hover-highlight (the steer's "or" alternative) not built.
 - **LIVE-VERIFIED (runner 3c5238c6, 2026-07-14 late):** VoroClinic GREEN 9/9 ×3 + VoroMitosis GREEN
    11/11.  The glass (`/tmp/nightshift_gallery/g_clinic.svg`): Beta CRATERS — 1 coagulate + 4 orbs,
     header `Artist name: Beta` 28.3px, orb titles 8.4–13.1px (all under the ×0.9 ceiling); Alpha
      self-gates FLAT with the lead cap visibly binding (title 9.7 → every row 8.9 = ×0.92); the
       witnessed gang chips land at EXACTLY title×0.92.  Flora: 13 panes, titles clean, ZERO
        orb|coag|blur (craters never fire on a same-kind gang — the invariant held).  G1/G4 pixels
         wait on the seed gen (the wedge).  Orb-size wobble (8.4–13.1) is the standing evenness
          taste item — Lloyd is the lever, the human's eyes the judge.  GOTCHA learned: arm the
           faces BEFORE the run — an arm AFTER `done` re-morphs a torn-down world (seeds:0) and
            CLEARS the glass (the why-strip: `morph✗ von:1 seeds:0 need:<2`).
 - **THE WEDGE (needs the human):** the editor's compile dock for `Ghost/Story/Voronation.g` hangs on
    ANY real content change (byte-identical content no-ops fine; `Voro.g` compiles fine interleaved —
     bisected to the file, not the construct).  So the VoroClinic seed enrichment (tracks get
      VoroScape's year/live/remaster sprinkle, needed to SEE G1/G4 on the Clinic) is authored but its
       gen is NOT landed, and the Clinic re-record is owed behind it.  Likely cure: reopen/reload the
        editor tab (not done remotely — it's the human's live tab).

**WHAT LANDED THE PREVIOUS SHIFT (2026-07-14, autonomous) — the honesty pass + the craters.**
 (Committed by the human in `gust`.)  In order:
 - **The three taste-fixes** (inflate to fill · no top-wall clip · no >45° baseline) — LANDED, proven.
 - **B0 honesty** — the flattening lies from the first real-world (Artist/Track) read, all four fixed
    and LIVE-PROVEN on VoroClinic: kind chip + title key restored, sc order in-pane, ×N→/*N tail.
 - **B1 C-SPACE CRATERS** — a big cross-kind fold cell divides into per-member sub-cells (each %Track
    its own crater with its own mini pane); `pane_rows` (tuples flow on any polygon) + `crater_pane`
     (card: widest-chord header band + grid-split body via `power_cells`); SELF-GATES to flat tuples on
      small cells so the identity never drowns.  A/B via `runner_shot --face=craters:0|1`.  Structure
       proven; **member-evenness taste owed on real BIG-artist cells** (VoroClinic's cells too small/
        noisy to tune blind — the human's eyes + pixels; Lloyd relaxation is the noted lever).
 - **B2 probe** (code) — the slow /*N collapse pinned: `cyto_update_wave` re-crushes only if
    `crush_wanted` armed, which lapses after Story finishes.  Candidate fix noted, NOT shipped blind.
 - **B3 identity floor** — landed as the crater self-gate.
 Details for each are the B0/B1/B2/B3 bullets under **THE PLAN — bamboo v2** below.  The human's noted
  north-stars (not built): SHADOWS revealing the hierarchical landscape + TUNNELS between cells.

**THE 2026-07-14 STEER (the human, live — supersedes the wave-③ remainder + §Nightshift orders,
 which was the fill-out shift, done).**  Three rulings, one arc:
 - **The distiller bows to Stuffing** — the ALGORITHM (`Stuff.svelte.ts compute_groups`: group
    like rows → columns → value-chips-with-counts, `is_one` collapse), NOT the HTML component.
     **LANDED `bdc3d923` (typed claims, byte-neutral ×30 snaps, sabotage-proven, live-green 4/4).
      LANDED `ba581d99` (2026-07-14 night): the presentation rows go TYPED too — title|list|member|
       sub|dip carry name/nk/tag/k as their own keys, ALL display text composed at paint (Cytui
        vtuff_rows), only the `+N` overflow tail keeps a text (chrome).  `Vtuff_default` and
         `Vtuff_bamboo` stop duplicating ~50 lines of wording twice (already drifting) — the shared
          authors `Vtuff_title_row`/`Vtuff_member_rows`/`Vtuff_dip_row`/`Vtuff_kinds`/`Vtuff_skips`
           say a row ONCE, each stalk only decides WHERE rows land.  A member row's kind-tag rides
            ALWAYS now (honest data); the draw-the-chip decision is paint's (memberTag hush), held
             byte-equal to the old baked calls.  Claim set invariant (fact/spread/skips untouched);
              headless byte-neutral ×30 snaps ×4 Books.  **LIVE-GATED 2026-07-14** on VoroMitosis
               (flora world): facts render as separate typed tspans — key + lilac `: ` (vsub-colon)
                + value (`habit: …`), a presence claim as key + `×3` sup (`woodystem ×3`) — composed
                 at paint from typed k/v/n, NOT a re-parsed string; member chips (species), spreads,
                  `/*N` dips, `+N` tails all present.  Evidence: `/tmp/nightshift_gallery/mitosis_1b_cs.svg`.**
     Vtuff_default's bespoke row taxonomy (title/list/member/sub/fact/spread heuristics with the
      English naming list threaded through) is replaced by that one clean `((k:v+)+)+` slope:
       typed key/value bits end-to-end, display text derived only at paint.  Kills by construction
        the meaning→text→re-parse round-trip (the grasp's `Voro_grasp_kv` reading `'year: 2007'`
         back OUT of a display string it itself caused to be written).
 - **Vtuffing's real job is the VISUAL EXTENSION** — laying those bits out nicely in the cell
    **wrt how the neighbours lay theirs**, to compress the glass's visual noise (Se doctrine: a
     claim the neighbourhood shares QUIETS locally — its story promotes to family-level lettering,
      the Wes-Wilson river pass — while a claim that differs SHOUTS).  The grasp's TF-IDF wgt
       already encodes the contrast; the cut is layout-side suppression + promotion, not new
        analytics.  Head for really nice rendering FIRST — truer to reality, simpler.
     **LANDED `31a39949` (2026-07-14 night): region rivers speak every ∀-shared claim (chips
      Wes-Wilson-sized per station), member cells hush exactly those behind a `»N` receipt
       (≠ `+N` crowd-out), telemetry counts `promoted:N`.  Verified on live pixels via the NEW
        remote face-arm (`runner_shot --arm` → op:'face' → Cytui `cy_face` on top_House.c —
         per-tab ◈/▧/▦ prefs settable over the ask rails at last).  Evidence gallery:
          `/tmp/nightshift_gallery/` (mitosis_promo3.svg = rivers carrying '1998' 22px +
           'remaster ×2' + 'live ×2', five `»2` cells, 'remaster' NOWHERE in a cell).
            OPEN refinement — wall-adjacency quieting (analysed 2026-07-14, NEEDS THE HUMAN'S EYES
             before building).  Region promotion is the ∀ grain (a claim EVERY member shares → the
              river); the gap it misses is a claim shared by a CONTIGUOUS SUBSET (e.g. `remaster:2` on
               three cells that border each other but not the fourth).  `VCell.edge_src[k]` = the
                neighbouring seed id per wall, so per claim you can walk the adjacency graph, find
                 connected components ≥2, and write it ONCE on the shared border (hush in the members,
                  `»N` like today).  The OPEN QUESTION is taste, not mechanism: text-on-a-wall may
                   compress noise OR add clutter — decide on live pixels, so NOT buildable blind while
                    the runner's occupied.  Render-only + gated (like cs) when it lands.**
     **cs — LANDED `b2e8e965` (2026-07-14 night, the human's live steer): the ▧ region wash
      "wasn't making sense" (a calendar-grid glyph backing a meaningless hull).  Relabelled `cs`
       and given meaning — a region is a local COORDINATE SYSTEM for its member cells, and the
        family's river IS its axis (posable = the graph's layout axis; twisted to fit the voronoi
         landform).  Each member cell learns the river's local flow tangent where it passes through
          (`cs_frames`, from the ordered centroid walk); the ▦ sub-cell pass rotates that cell's
           whole compass by the frame, so downstream is a fixed local direction and a key sits the
            same way RIVER-relative in every cell — the space reads as aligned across them.  Render-
             side only (no .g/snap): frame filled only under region_on, defaults 0, cs-off byte-
              identical.  **EXERCISED LIVE 2026-07-14** on the same VoroMitosis capture — regions
               armed, 30 river chips rendering, 1 promotion `»`-receipt, no breakage; the cs
                compass-alignment is a subtle visual best judged by the human's eye (the ◈/cs/▦
                 faces were left armed on the runner).  **SUPERSEDED (2026-07-14, the human, live):
                  "the cs squiggles are retarded at the moment" and "it has no effect on subcell
                   structure yet which was the whole point".  The cs river-frame IDEA (align sub-cell
                    space across cells) was RIGHT; rotating the star compass by it was the wrong body.
                     Button relabelled `cs`→`∿` (it draws C/S letterforms), PARKED OFF (region_pref
                      default false; render byte-identical off).  The alignment intent moved to the
                       TUPLES FACE below ("something like but possibly not exactly cs").**

     **THE ▦ SUB-CELL NOW HAS TWO FACES via the `vsub_face` PARAMETER — LANDED 2026-07-14 night (the
      human's live steer, live-proven on VoroMitosis).**  "WHAT I REALLY WANT is ALL the info,
       arranged so I can read the notation that looks similar to snap but with multiple rows squished
        together … a parameter (not in the UI because we'll probably take all this away to another UI,
         it's prototyping) where we can make it this gem-like star formations, or the new default:
          somewhat more like a C structure, tuples … using something like but possibly not exactly cs
           to make those tuples aligned and hang in the same direction across places, but they should
            mostly favour the shape of their cell, to align text with the biggest top-left-est cell wall."
     - `let vsub_face: 'tuples' | 'star'` in Cytui — a PARAMETER, not a bar button (prototyping; the
        real UI comes later).  `subgraph_build` branches: tiny→nucleus_pane; **`tuples` (NEW DEFAULT)**
         →`tuple_pane`; else the radial **`star`** gem (the six-pass face, unchanged).  Flip live over
          the ask rails: `runner_shot --arm --face=vsub:star` (op:'face' now takes `vsub`); or the
           `Cyto_vsub_face` stash.
     - `tuple_pane` says the distiller's tree as SNAP-LIKE STACKED ROWS: title (kind badge · name · ×N),
        keyed rows in GLOBAL vein order (same key at the same RANK in every pane = "hang in the same
         direction across places"), `key:` + value chips, then the members flowing; wraps with a one-em
          TREEING indent; over-wide atoms shrink to a 7px floor, the rest folds to `+N` (never a clipped
           `…`).  Density beats the 14pt floor here — the notation wants all the info (rows 9–15px, the
            title stays loud).  `tuple_frame(poly)` picks the cell's biggest top-left wall (len ×
             top-left-weight × readability, upright-normalised, quantised 15°) and the whole pane's
              baseline rotates to it — "favour the shape of their cell".  Each atom is its own VStat, so
               a member chip keeps its click/pop.
     - **LIVE-PROVEN** (`/tmp/nightshift_gallery/tuples_clean.svg`): 13 panes, 141 labels, **0 ellipsis**,
        rotations −45…+30.  Reads e.g. `Metrosideros ×11 / habit: shrub ×3  tree  vine ×4 / woodystem ×3
         / propinqua rhamnoides grandifolia microphylla serrata …`.  The "venn/treeing" the human named is
          the distiller's ∀-intersection facts + variance-spreads (already there) laid out readably.
     - **BOMB found + fixed en route (`morph_voronoi` rAF-throttle):** the morph clears `vsubs`/`vtips`
        SYNCHRONOUSLY but restored them only inside a `requestAnimationFrame` loop — a background/unfocused
         runner tab PAUSES/THROTTLES rAF, so every `runner_shot --svg` showed CELLS but BLANK sub-cells
          (`0 vsub-groups` with `state_vsubs:13`).  NOT a tuples bug; a general headless-capture fragility
           the feature merely exposed.  Fix: `if (still || document.hidden)` paints the settled state
            synchronously (a hidden tab has no animation anyway) + a `setTimeout(MORPH_MS+150)` backstop
             for the visible-but-throttled case.  Also added `op:'reload'` to runner_ask/LiesFunk (runner-
              only remote `location.reload()`) — the fleet wedge-healer.  See memory [[raf-throttle-blank-subcells]].
     - **THREE TASTE-FIXES LANDED (2026-07-14, the human "yay … now it just needs inflating into its
        potential space … a line obscured by the cellwall above it, and a 150° down angle"):**
        (1) **inflate** — `tuple_pane` now lays out at 1× to MEASURE the natural stack height, then re-runs
         at a damped `zoom` (`min(2.4, 1+(availH/used−1)·0.7)`) to fill the cell's empty vertical space,
          kept only if the bigger pass still seats everything (never trade a shown row for size).  Sparse
           one-member cells now render 22–38px, dense cells stay 12px — verified `tuples_v2.svg`.
        (2) **no wall-clip** — `flow` seated lines on the CENTRELINE chord, so ascenders poked under a
         sloping top wall; now `line_span(ytop,lh)` = the INTERSECTION of the chord under the box's top and
          over its bottom, and a line steps down until its whole box seats inside both walls.
        (3) **no steep baseline** — `tuple_frame` REJECTS any wall >45° outright (was only soft-penalised;
         a +60° wall = the "150°-down" the human saw); no qualifying wall ⇒ horizontal.  Live shot now shows
          only 0/−15/+30°, **0 labels over 45°**.
     - **THE FIRST REAL-WORLD READ (2026-07-14, Artists|Tracks live) — the flattening LIES, and
        bamboo v2 IS C-SPACES.**  The human read the tuples glass on real music data ("this new graphic
         is great! but…") and caught it lying.  The root of every lie is ONE thing: the pane flattened
          all rows into a stack and FORGOT WHICH C EACH ROW CAME FROM.  The wants, each grounded:
        1. *"not indicating that the thing inside there is a %Track"* — a fold-container's title tag is
            the CONTAINER's mainkey (`Vtuff_title_row`: `tag = Object.keys(src.sc)[0]` = 'Artist'), and
             the homogeneous member list (`Vtuff_member_rows`, list branch) emits Vbits with `v:` ONLY —
              no `tag` on chips.  (The "tag rides ALWAYS — honest data" comment guards the MIXED branch;
               homo assumed the title spoke the kind, which is FALSE for a fold whose members are another
                kind — an %Artist holding %Tracks.)
        2. *"AND it loses its %title"* — the distiller DOES say which key the bits are values of
            (`row:'list', k: Vtuff_namekey(members[0])` = 'title') but Cytui `subgraph_tuples`' list
             branch reads `d.chips` and DROPS `d.key`.  The one honest key never reaches the glass.
        3. *"those two properties come before the %year|live|remaster — which we are also lying about"* —
            ORDER.  A C reads mainkey → title → year|live|remaster (its OWN sc order); the glass sorts
             keyed rows by GLOBAL vein rank and leaves by localeCompare.  Cross-pane alignment must not
              beat within-C truth (fix: sc order wins in-pane; vein rank becomes the cross-pane tiebreak,
               or is seeded FROM mean sc-index so both mostly agree).
        4. *"%Artist,name:Moonlit ×4 … ×4 there means four such %Artists (in a Stuffusion) … we mean
            /*4"* — the title's ×N is the member count off the tree root's n (`Vtuff_title_row`) but it
             READS as a count-of-such-Cs.  The honest mark is the FOLD TAIL: `/*4` at the end of the
              %Artist sub-cell when its inners are closed, bare `/` when open.
        5. **the /*N surf misbehaves:** clicked, it SPILLS top-K members into the cytoscape graph
            (Vtuff_pop) and the pane collapses to its bare title ('Artist:name:Voxhall') — surprising;
             the collapse lands SLOWLY (the human's hypothesis, probably right: Story finished → the
              world's beliefs() pump quiesced, so the re-crush waits for a random think — "needs a
               feebly_ponder()?"; trickle is off, so it isn't that); and once closed there is NO reopen
                (the inverse gesture is a right-click nobody can discover).
        6. *"ensure Artist,name:Moonlit isn't too small, it can often drift down into an acute corner"* —
            the title atom can shrink toward the 7px floor and seats at the first chord that fits, which
             in a pointy cell is deep in an acute corner.
     - **THE PLAN — bamboo v2 = C-spaces** (the human already redirected bamboo here 2026-07-11, written
        on the lab door: `Vtuff_bamboo_on()` hard-false "until bamboo v2: hierarchy expressed as
         sub-cells|sub-graph, not text stalks" — today's steer is that spec: *"we need a sense of where
          each C is … something needs to encapsulate where the %Artist/%Track subcell spaces are, and we
           need to lay them out sensibly, to max out space … we just need to anchor points in it, eg in
            the acute corners … but not with cytoscape, right? possibly other cytoscape worker instances
             though.  do we just voronoi that subcell structure?"*).  Phased for the long slog:
        - **B0 honesty — LANDED + LIVE-PROVEN 2026-07-14 (VoroClinic, gen ba725387).**  Read now:
           `⟨Artist⟩ Artist name: Alpha / ⟨Track⟩ Track title: a1 a2 a3 a4 / tail /*4`.  (1) Voro.g
            `Vtuff_member_rows` threads `src` + tags the homo list with the member kind when it differs
             from the container title kind; (2) Cytui `vtuff_rows` captures `d.key` for `list` rows (was
              fact|spread only — the title key died at the read); (3) `subgraph_tuples` routes a TAGGED
               (cross-kind) list to a keyed LEAD tuple, a same-kind list (flora genus) stays bare trailing
                members — GATE ON `d.tag` NOT `d.key` (d.key was too broad, regressed flora into a
                 redundant 'Metrosideros:' row); `tuple_pane` orders keyed lead-first stable (== sc order),
                  vein now hue-only; (4) title drops ×N (redundant with the /*N dip, same root.sc.n).
                   Flora (VoroMitosis, same-kind) unregressed.  X-kind verify Book = **VoroClinic**
                    (VoroTest builds the data but useVoroCyto=0 → no glass; VoroScape has a dirty toc).
        - **B1 C-SPACE CRATERS — BUILT + LIVE-PROVEN 2026-07-14 (VoroClinic, Cytui only).**  A big
           cross-kind FOLD cell divides into per-member sub-cells so you SEE where each C is.
            `pane_rows(poly,cx,cy,rows,opts)` = the tuples flow extracted to run on ANY convex polygon
             (its OWN best-wall rotation + line_span + inflate); `tuple_pane` = pane_rows on the whole
              cell; `crater_pane` = a CARD — a full-width header band placed BELOW the cell's WIDEST
               chord (a pointy top would drown the %Artist — the acute-corner starve), members
                grid-split the body via `power_cells` (even, vs a lopsided phi-spiral), each member its
                 OWN mini pane (its sc order) + wall; `member_rows` reads a single particle's sc direct.
                  SELF-GATES on an 11px identity floor → small cells fall back to flat tuples.  A/B via
                   `runner_shot --face=craters:0|1`.  Live: Beta (big) craters — 28px header + 4 Track
                    sub-cells; Alpha (small) flat 28px.  **OPEN taste (the human's eyes on real BIG
                     artist cells):** member evenness still wobbles (9px next to 22px); the human's
                      north-stars = SHADOWS revealing the hierarchical landscape + TUNNELS between
                       (noted, not built).  See memory [[tuples-face-snap-notation]].
        - ~~**B1 C-spaces (refined 2026-07-14, second steer):**~~ (design, now BUILT above) each member C gets an ENCAPSULATED
           sub-region of its cell, and the frame is the EXISTING series — *"the
            Stuffing/Stuffusion/Stuffziad series of cells-within-cells, that's what I'm going for.
             just compositioned into the cell"*.  That series is real code (`Stuff.svelte.ts`):
              **Stuffusion** (a group of rows) → **Stuffziad** (one key's k:v group) → **Stuffziado**
               (a single value), each `Stuffuzia` already carrying `innered`/`inner_sizing` recursion
                hooks; and `Voro_vtuffing.md` already names `Vtuff_default` "the
                 Stuffusion|Stuffziad|Stuffziado compression RE-SAID AS ROWS".  **B1 = say it as
                  SPACES instead of rows**: the cell's area divides into the compression's own
                   nesting — member sub-cells (Stuffusion grain), each holding its keyed sub-regions
                    (Stuffziad grain) down to values (Stuffziado grain), depth capped where the
                     pixels are.
           · **RULED: programmatic, not cytoscape.**  Pinning a second set of cy nodes into the cell
              and resolving the cell-full between them COULD be done (invisible pinned nodes, read
               positions, power-split between them) but it is a whole other layer — the human: *"we
                should try and do something programmatic"*.  We already own the machinery: the star
                 face's phi-spiral splitter divides a polygon into weighted sub-regions today, and
                  `poly_chord`/`line_span` seat text in any convex piece.  Headless cy workers stay
                   a maybe for BIG inner families only.
           · **VERIFIED architecture (the human's assumption is exactly true):** the model has the
              whole Artist+Track tree (`Voro_model_build` gathers fold children as `fam.members`
               with their facts) while cytoscape nodes ONLY the Artist (the crush stamps the fold;
                `Cyto.svelte` `no_further='stuffed'` suppresses descent) — a simpler first set of
                 cells, the full Artist/Track display rendered within each.
           · Geometry: seeds from the cell's own shape with ANCHOR POINTS AT THE ACUTE CORNERS
              (corners become useful — small members nest into them); the parent's venn band keeps
               the widest chord, said once above the member spaces.  Layout goal: MAX OUT SPACE.
                (The packing is a genuinely academic job — weighted division of an arbitrary convex
                 cell honouring corner anchors + a band reserve; start greedy: corner-anchored
                  power-split, judge on pixels, only then consider relaxation passes.)
        - **B2 the surf lifecycle + THE LEVER (verified):** the model-side lever the human asked for
           EXISTS — `c.popped`/`c.popped_open`, stamped by `Vtuff_pop`, read by `crush_walk` (a popped
            member STANDS ALONE as its own cy node) and `Voro_crushable` (null on popped_open = won't
             re-fold).  Today it is BINARY: folded ↔ spilled-to-graph.  B1 adds the missing middle,
              so the states become THREE, all model-driven:
                1. **folded-closed** — inners hidden, tail reads `/*N`;
                2. **open-in-glass** — inners rendered as sub-cells INSIDE the cell (no cy nodes),
                    tail reads bare `/`;
                3. **spilled** — popped out as real cytoscape nodes (the deliberate gesture — maybe
                    the right-click it already is; today's /*N click does this and surprises).
              /*N click toggles 1↔2; the click nudges a think so the toggle lands NOW.
           · **PROBE DONE 2026-07-14 (code, not a synthetic click — no headless-click path exists):**
              the human's "collapses really slowly … has Story shut off beliefs()?" intuition is
               CONFIRMED and pinned.  `Vtuff_pop` stamps `c.popped` then `await cyto_update_wave(w)` —
                so the wave fires on the click (not on a later think).  BUT `cyto_update_wave`
                 (Cyto.svelte:230) re-crushes ONLY `if (scan.c.crush_wanted)` — during a Book each step
                  arms it; after Story finishes it is not reliably armed, so the wave RE-SCANS but does
                   not RE-CRUSH, and the spill (popped members → standalone cells) waits for the next
                    think that re-arms `crush_wanted`.  That IS the "feebly_ponder" delay.  **CANDIDATE
                     FIX (small, but arm-then-verify with a live click — DON'T ship blind into the
                      human's live-used pop):** in `Vtuff_pop`, set `w.c.Scannable.c.crush_wanted = 1`
                       before `cyto_update_wave(w)` so the wave re-crushes immediately.  The B1
                        in-glass toggle (state 1↔2) sidesteps it entirely — no spill, just a re-render.
        - **B3 identity floor — LANDED (as the crater self-gate) 2026-07-14.**  `crater_pane` returns
           null when the header identity won't seat ≥11px → the caller renders flat tuples (readable
            small), so the %Artist name is NEVER drowned in an acute corner — the human's opening
             complaint.  The header band is also placed BELOW the cell's WIDEST chord (prominence).
              STILL OPEN for the FLAT `tuple_pane` title on a pointy-top cell: seat it on the widest
               chord band rather than the first-from-top (rare; not yet seen to drown live).
        - B1 also RETIRES the display-side namekey for members: a sub-celled %Track shows kind+title
           structurally, so Vtuff_name/Vtuff_member_bit shrink toward the model-anchor-only use (the
            parked deep cut, resolved by architecture instead of analytics).
     - **OPEN (bigger cuts, the human's call):** the model dumped **on a separate channel from the snap**
        (bigger than Voronoiology, NOT inside H%Run) + the namekey model-anchor remainder (see B1 above —
         the display half is retired by C-spaces).
 - **The naming-cut is DROPPED as filed; the bijective key is PARKED.**  region|axis|name are
    necessary-ish but fundamentally fallible analytics — do not grow them.  `Voro_model_namekey`
     keeps its code but is not threaded further (its spirit may resurface at the Stuffing-algorithm
      level: an identity column = distinct-per-carrier).  The eventual true shape is %dome-style
       INSTRUCTION — the data telling any Stuffing|Vtuffing|Voro|resolve() how to treat a key
        (`D%the_key,the_very_key` making a key meaningful on identity) — explicit over inferred;
         not now.  Identity-anchor direction likewise Se-side (Dip_assign persists across a Seem's
          replace via resume_X; `mem.further`-pathed stash for openness) — noted, not this shift.

**SPIN-OFF captured, not built — the STYLE-EXPLAINER HUD (the human, 2026-07-14).**  "tooltips, or
 part of the hud that explains the style of what you're pointing at (eg the %woodystem subcell) so
  users can learn to read our svg stylings (which should become more artistic, gradually… a world
   of stuff to spin off)."  The glass has grown a real vocabulary — lilac colon = k→v mark, violet
    ×N = count, `»N` = promoted to the region's river, `+N` = crowded out this beat, per-key VEIN
     hue (one golden-angle slot per key name, global), the cs frame's river-relative compass, the
      river LETTERFORM (O/I/C/S read from curvature), kind-tint tags.  Nothing tells a newcomer how
       to read it.  The ask: point at a sub-cell (or any glass element) and a HUD panel decodes the
        style under the cursor — teaching the language, and a seam toward the render becoming MORE
         artistic over time (the human owns that aesthetic direction — hence captured, not built).
   First-step sketch (when the human spins it up): the CSS already carries the legend in comments
    (`.vsub-colon`/`.vsub-sup`/`.vsub-com`/`.vsub-hid` each documented) — lift those into a data
     table `STYLE_LEXICON[className] = {glyph, meaning}`; the sub-graph tspans already class-tag
      every element (`vsub-colon`, `vsub-sup`, `vsub-com`, `vsub-gkey`, `vsub-label.hot`…), and
       `vsub-label.hot:hover` proves per-element hover is wired — so a mouseover reads the hovered
        tspan's class → lexicon entry → a Brink-style HUD face (memory [[lens-primitive]] Brink HUD
         is the home; a `Lens:Legend` face beside Rundar/Relay/Sound).  Keep it a READER (no snap,
          no model) — it explains what's drawn, it doesn't change it.  Verify via `runner_shot --svg`
           greps + live eyes.  NOT this shift; a whole area, the human's to shape.

**THE FIVE WAVES (the arc from here — model first, geometry later, pixels last).**
 - **① The Se-up model — LANDED (2026-07-13, honest-language round).**  `Voro_model` (Voro.g)
    computes the MODEL in the crush tail: an off-snap full tree on `w.c.voro_model` (%Model /
     %Family / %Member / %Loud + a `%Seem:model` drift organ) and a snapped distillation in
      `w:Voronoiology`.  **MAINKEY = PROVENANCE:** `Family:<name>,n,kind,order_by,axis,from,to`
       rows with `Loud:<key>[,v:<val>]` children (loudest-first = rank; weights stay OFF-snap)
        are computed census; an `Se:drift,neu,gone` child rides a %Family row ONLY on a beat the
         model Seem's resolve reported movement (absence IS the quiet reading).  `%Family`/`%Loud`
          are computed census; `%Se` is worn only by Selection-derived readings (Se:scape,
           Se:census, Se:drift).  The old `Se:family` row is GONE.  The Vtuffing snap-transcription
            is DELETED (`Voro_vtuff_transcribe` no longer exists) — pane words stay c-side on
             `f.src.c.vtuffing` (grasp scores, render draws); render chrome (×N titles, /*N dips,
              wgt) never crosses into fixtures.  One-fact-one-place: the order-axis key is excluded
               from Loud; a spread's `+N` overflow chip (structurally n:0) is skipped by the model.
 - **② VoroTest Book — LANDED + FILLED OUT (per-Example, Cyto-off; LIVE GATE OWED).**
    `Ghost/Story/Voronation.g`: now NINE datasets each an `%Example` holding its data world + its own
     `w:Voronoiology`; fixed crush level L2 (the `genus` Example alone crushed UNPINNED for #18); the
      original 10 `%see` PLUS 5 more (2026-07-13 fill-out: #6 swarm noisy-threshold, #14 fact-vs-spread,
       #18 unpinned governor clade discovery, #23 popped spill re-gang, #28 row-slot identity) across
        the same bench/mutate/quiet beats, all on the honest language.  **Headless CredRunner smoke only
         (all 15 `%see` fire; no live drift/ttlilt in the quiet beat)** — the LIVE runner gate + the
          human's re-record are OWED.  See §The VoroTest roster below for the rest of the fill-out plan
           (#19 region live-gated; #29 loner LANDED with a model cut — ALL [model] shapes now covered).
 - **③ Cytui consumes the model.**  Cytui shrinks to wiring + paint: it READS the grasp's model
    (membership, order, loudness, drift) instead of recomputing it.  Today `region_of` /
     `river_order` / `family_trait` (Cytui) still hand-roll it render-side — this wave makes them
      readers off `w.c.voro_model` (via `src.c.D` — see §The data-path crux).  // < wave ③ NOT
       started; the readers still recompute.  This is where **the Loud share-count inversion** lands:
        the model reads the rep's word rows, not the members, so a share count like `vein` 3-of-12
         is LOST — the fix is the model pooling member facts ITSELF instead of the rep's word rows.
      **The human's ruling (2026-07-13): the report becomes bits of the model — one elegant core.**
       "the model" = ALL data representation by Voro (recommended naming, pending the nod — Cyto's
        input needs no separate noun since it IS the model; Cyto is one consumer among consumers).
         ONE walk of the crushed world + ONE fact-extraction build the model; `w:Voronoiology` is
          nothing but the model's SNAPPED FACE (every row a projection of a model node — the
           `%cell`/`%bare` shapes are `%Family` rows worn thin); the %Seems are the model's MEMORY
            (D-spheres), never the model itself.  Kills by construction: the report/gather twin
             walks, the grasp-vs-model fact-walk divergence (the `'+9'` chrome chip tallied as a
              claim — found 2026-07-13), and Voronoiology's triple authorship.  The %Se choir the
               merge leaves standing: `%Se:input|scape|census|drift` — each phase an honest
                reading off one Selection-backed memory.  `%Se:attention` is STRUCK for now (the
                 human, 2026-07-13): the radio is a half-baked v1 placeholder — the real shape is
                  conveyor-ish (one end things get added to) and is to be led to GRADUALLY.
      **LANDED (2026-07-13, same day):** cut 1 — `Voro_fold_gather` is THE one walk (report_walk +
       model_gather folded in; the report PROJECTS its census from the same records the model
        families; `Voro_census_key` = one keyer for report + stash) — proven byte-identical on all
         4 Books' got.snaps.  cut 2 — `%Se:input,arrived,left` lives (only when the weather moved);
          the `'+9'` chrome chip no longer census-tallied nor trait-eligible (hushed wgt 20); empty
           `trait:` deleted not snapped.
      **LANDED (2026-07-13, `c970ceed`): the LOUD SHARE-COUNT INVERSION.**  A `%Family`'s Loud claims
       pooled from the fold's ONE distilled rep row, so a minority-but-loud trait (a gang's `%vein` on
        ~⅓ of the strata) could NAME the family but never say how many carried it — a count a single
         rep cell structurally can't hold.  `Voro_model_share(mem, key, val)` counts the MEMBERS
          carrying each claim, over the same per-member facts the axis + naming already read (presence
           claim → match the key alone; valued → key+val), and rides the model's `%Loud` node → the
            snapped row as `share:N`, snapped ONLY when PARTIAL (`0 < share < n`): universal (`share===n`)
             stays the family's default reading, a rep-only distillation (`share 0`) is never fabricated.
              The Boulder flock now reads `Loud:vein,share:3` at 12 strata, `share:5` at 15 — one of every
               three, exactly the `hsh % 3` seed.  Surgical: the ONLY snap change is partial Loud rows
                gaining `,share:N`; Loud selection|weight|order untouched.  **DECISION — `share:1` KEPT**
                 (44% of the shares): `Family:Kunzea,n:12` `Loud:endemic,share:1` — one of twelve is
                  endemic yet endemic is loud; suppress the `1` and it MIS-READS as universal.  The
                   relic-family `share:1` flood (a bare pair of unique-prop singletons) is the honest
                    price; if the human wants it gone it's a one-char tighten (`share > 1`), but that
                     re-hides the rare-loud singles.
      **RE-RECORD OWED (after `c970ceed`): VoroTest · VoroRadio · and AGAIN VoroMitosis · VoroScape**
       (the share commit landed AFTER the human's fresh Mitosis+Scape record, so it re-staled them —
        Loud rows gain `share:N`).  **VoroClinic is NOT owed** — it produces zero partial Loud rows, so
         the share cut is invisible to it (its only drift is a transient `Snap:cytowave` animation
          artifact, pre-existing timing noise); it's `%unusual` anyway.  (**VoroRadioPier RETIRED**
           `5f6b5d29` — the human: "this suite is about form not the Pier"; the roster is five Books now.)
      **LANDED (2026-07-13, `bb1c2ecf`): born|died vs folded|unfolded — THE OPENNESS SPLIT.**
       The reframe held exactly: fold-status rides each remembered subject as an ANNOTATION and one
        resolve separates the pairs.  One placement discovery: the mark lives on the SOURCE particle
         (`src.c.was_fold`), NOT the D — `o_Seem` REPLACES the topD every resolve (fresh D objects;
          survivor identity is content-paired), so a D-side mark dies with its beat; the flora
           persists, and a goner's D still holds its source object (`d.c.C`), so `died` reads our own
            last-beat mark off the departed — the "stale goner can't be re-read" problem dissolves
             (staleness IS the question).  `died` is now DIRECT (a goner that wore the mark), never
              the `prev+born−grasped` silhouette arithmetic (deleted, with `w.c.grasp_prev_folds`);
               `folded|unfolded` = a survivor whose mark flipped, snapped on `Se:scape` ONLY when the
                viewer moved (absence is the quiet reading, after `regions` so quiet rows keep their
                 byte-order).  **VoroTest #31** gates it at the popped Example's mutate beat — one row
                  reads `born:0,died:0,folded:1,unfolded:1` (the pop + the spill re-gang, zero
                   mitosis) — adversarially proven both ways (lose the annotation → dies; book
                    undressings as died → dies).  The old arithmetic's lies live on
                     demotion-without-redress beats: VoroMitosis fixtures show old `died:1` rows now
                      reading `unfolded:1` — the re-record diff carries that proof.
 - **④ Geometry folds into `Voro.g`.**  The pure maths (hull, clip, resample, PCA, river order,
    Catmull) folds into `Voro.g` — NOT a new `VoroGlass.ts` (the human decided AGAINST a .ts
     module).  A later wave; it will feel out the LangTiles parse-storm on closure-heavy raw JS.
 - **⑤ The graphical phase — TEXT RENDERING BEFORE WASHES.**  Region washes are DEFERRED (the
    human, 2026-07-13: *"that's after we sort out text rendering a bit better"*).  So: get the text
     rendering right first, THEN C2 (merge each family's washes into ONE filled region), chip
      thinning on long streaks, and the Wes-Wilson lettering pass (warp the big words along the
       river tangents).  Taste tuning throughout — all eyes-on via `runner_shot --svg`/`--why`,
        none Book-gateable (pixels never round-trip a fixture).

**WHAT'S OWED right now (top of the pile for a cold session).**
 1. **The LIVE gate for ① + ② (now incl. the 5 fill-out `%see`)** — re-prove the honest-language model
     + the VoroTest Book (all 15 `%see`, the 3 new Examples, the UNPINNED genus governor) on a LIVE
      :9091 runner (headless CredRunner is a bubble; [[verify-via-live-runner]]).  A runner WAS reachable
       2026-07-13 (`runner_ask.mjs ping` → up, idle) but the NEW gen must reach it first: `npm run
        ghost-compile -- Ghost/Story/Voronation.g` needs the editor tab open, then `runner_ask.mjs run
         VoroTest --watch --runner=<prefix>`.  If become_book stamps but no run mints, the tabs are
          wedged — host reload first.
 2. **The fleet re-record (human's job).**  All crush-Book fixtures (VoroTest, VoroMitosis,
     VoroScape, VoroRadio, VoroClinic — VoroRadioPier retired `5f6b5d29`) are STALED by the language cut — steps 2-4
      diff by design (the fixtures at HEAD predate the cut).  **VoroTest ALSO grew 3 Examples + 5
       `%see` this round** (CredRunner surprises [2,3,4]) — the re-record covers those too.  Re-record
        with eyes on, on a live runner; the human owns this.  `Seen_split_todo.md` (the human's parallel
         `%seen`-latch + assertion-roster build) is meant to make these re-records survivable — x-ref it.
 3. **Then wave ③ (part done)** — the **Loud share-count inversion is LANDED** (`c970ceed`,
     `share:N` on partial Loud rows).  What REMAINS of wave ③: turn `region_of` / `family_trait`
      (Cytui) into readers off `w.c.voro_model` instead of the old `the:family` D-stamp
       (render-only — byte-invariant on snaps, so un-gateable; verify by eyes via `runner_shot`),
        and thread the discovered `namekey` into `Vtuff_*` so the bijective-key naming reaches the
         glass, THEN delete `Voro_naming_keys`.  (`river_order` stays render-side by nature — it
          PCA-orders RENDERED centroid positions, which the model has no coordinates for; the model
           owns the DATA order via `order_by`/`from`/`to`, a different axis than the drawn arc.)
      **THE SEQUENCING TRAP on the naming cut (found 2026-07-13, the bomb for whoever tries it).**
       `Vtuff_name`/`Vtuff_ident`/`Vtuff_namekey` are PER-PARTICLE and run DURING the crush (they
        build `c.vtuffing`); `Voro_model_namekey` — the discovered bijective key — is a PER-FAMILY
         reading computed LATER, in the model build in the crush TAIL.  So at Vtuff time the family's
          namekey does not exist yet: you cannot just pass it in.  Three ways out, pick with the human:
           (a) the namers re-discover the bijective key LOCALLY from the fold's members (no model
            dependency, but duplicates the discovery — against "one core"); (b) compute the per-fold
             namekey during the crush and stash it on the rep for both Vtuff and the model to read;
              (c) re-stamp the vtuffing name AFTER the model.  And it is NOT purely render: `Vtuff_ident`
               feeds the model's pane anchor (`:721`) and the vtuffing feeds `Voro_model_facts`, so the
                cut ripples into `from`/`to`/`Loud` — byte-diffable, but broad.  This is why the comment
                 at `Voro.g:1557` calls it "its own cut" — do NOT fold it into a Cytui-reader wave.

**Two standing gotchas at the tab.** (1) RELOAD the runner tab first if its Vite HMR socket is
 dead ([[hmr-socket-dead-tell]]) — relay ops answer but `.svelte` edits silently don't land.
  (2) Any render round leaves the crush-Book fixtures stale; re-record is the human's.

**OLDER LANDED WORK (the six-pass ▦ gem — the current render face, still true).**
 Six ▦ passes in one day (committed `063fb214`, face 6 "the gem", owner-liked), full records in
  `Voro_vtuffing.md` §Relics: flat cut → tuple regions + veins → nucleus + spokes → pipeline
   (crush BEFORE scan; ▤ deleted) → uniform glass → **honesty + radial**: loners tessellate their
    whole sc; `+N` marks count everything crowded out; `%` deleted from the render; nucleus weight
     floors at 0.34·R (meaning hierarchy = visual hierarchy); members ring the rim under a radial
      kind-hue gradient; every glass text is a VStat fitted by `fit_stat`/`fit_ident` + one `vstat`
       snippet with textLength stretch 0.9–1.45×.  This is the face the three-layer re-cleave now
        rewires behind — the pixels stay, the recompute moves to the model.

**OPEN ITEMS carried forward (older layers, still true).**
- **~~VoroRadioPier~~ RETIRED** (`5f6b5d29`, 2026-07-13): the Pier-fed radio Book is gone — the human
   ruled the Voro suite is about the crush/model FORM, not the music source, and two of its three
    `%see` only duplicated VoroRadio.  The roster is five Books.
- **Seed→cell→mold agenda #13/#14/#12-rest** (`Voro_vtuffing.md` §next-moves #10–14): #14
   cell-quality relaxation is the pilot for the owned-integrator branch (fcose demoted to seeder)
    — the program-via-graph frontier.  #11 wave cadence, #12b HMR diagonal, #10 snake landed 07-08.
- **VoroMitosis extinction `%see` is LATENT** (never gates green — a later split reclaims the
   freed genus name); decide sticky-death vs drop, someday.
- **📻🕳 + bamboo-v1 schematica SHELVED** (`DRIFT_MODES_ON=false`; `Vtuff_bamboo_on()` hard
   false) — to be reimagined as their own endeavour; one flag reopens each lab.  // < GhoghoDrone
    Book DELETED (2026-07-13, human).
- The fold is a VIEWER (`The/Opt/useVoroCyto`, imposed at snap time; Books stay Voro-blind;
   DATA vs FOLD Book taxonomy).  Design: memory `voro-imposed-from-above`.
- **The render|animate fault catalog** (`Voro_render_faults_todo.md`, subordinate to this §0):
   F1/F2/F6/F7 BUILT + live-proven; F3+F8 (cells vanish/re-pop) are the SAME identity-linearity
    root as the census storm — owned by the identity/`resolve` thread, and the model layer (①) is
     the fix (a persistent fold-sphere resolved beat-to-beat).

**BOMBS.**
- Verify ONLY via the live runner (`runner_ask.mjs`); a headless Story_cli / CredRunner green is a
   bubble ([[verify-via-live-runner]]).
- A `--runner=` pin dies when the human closes that tab; NEVER accept/release a run you didn't
   start (client e63cdcca is the SHARED CLI identity — it proves nothing about whose run it is).
- git-diff a Book's toc.snap before dispatch (an orphaned save can collapse one to a skeleton).
- Never HMR mid-run; a wedged runner decodes EVERY Book total:1 (a Prep-only GREEN bubble).
- runner_shot `--runner=` takes a RAW relay addr — court via runner_ask first, use the sticky.
- The metaphysics below stand: pixels never push layout; nothing RENDER-side snaps — but the
   MODEL is allowed to snap (`w:Voronoiology` is its home).

## Nightshift orders — the VoroTest fill-out (written for a lesser agent, unattended)

MISSION: fill VoroTest (`Ghost/Story/Voronation.g`) with the owed [model] roster shapes below —
 one `%Example` + witnesses per shape, proven per-shape before moving on.  Everything you need is
  in this doc + `## The Se process` below; when unsure, prefer marking `// <` over guessing.

**FILES YOU MAY EDIT:** `Ghost/Story/Voronation.g`; `Ghost/V/Voro.g` ONLY if a shape needs a model
 feature (smallest possible cut); this doc (tick shapes, keep §0 honest).  NOTHING ELSE.  NEVER:
  any git command (no stage/commit/stash — the human reviews the tree); `src/lib/gen/**/*.go`;
   `Story.svelte`/`Hovercraft.svelte`/`Auto.svelte`; any `wormhole/` fixture (the human records);
    Radio/Heist territory (`Ghost/M/*`, `Radio_todo.md` beyond reading).

**PROGRESS (2026-07-13):** ✅ #6 (lack-mark resolved → noisy threshold), #14, #18 (unpinned governor),
 #23, #28 all LANDED + CredRunner-smoked (5 new `%see`, all fire).  #7 model-part marked COVERED (bond
  edge is [eyes]).  ✅ #19 (region / botanical families) LANDED + **LIVE-GATED** on the :9091 runner —
   the `sibling folds group by a shared property` see fired live (a secondary `clade` fact ropes four
    mainkey-distinct gangs into two regions, read off-snap via `VoroTest_model_of`).  ✅ #29 (loner /
     nothing-dropped) LANDED + **LIVE-GATED** with the smallest model cut — `Voro_model_loud_from` now
      returns `{list, over}` and the %Family row carries a `+N` overflow (two bare `%Relic` overflow K=4
       → `over:6`, computed live on a reloaded runner alongside the see; the first runner had wedged on
        the core Voro.go HMR).  ALL [model] roster shapes are now covered and BOTH new gates are live.
      Next: the human's fixture RE-RECORD (VoroTest reds only on the additive relics diff), then wave ③.

**THE ORDER** (roster numbers): #6 swarm — FIRST resolve its lack-mark (is same-mainkey-varying-
 value already mix's gang path? prove the difference with a dataset or mark it covered) → #7
  under-w gang census (model part only, no bond edge) → #18 genus/clade discovery — NOTE this one
   tests the GOVERNOR, so crush it UNPINNED (no `fixed` level) with ≥16 leaves so escalation is
    deterministic; every other Example stays pinned L2 → #19 botanical families ✅ (the `region`
     secondary property groups sibling folds; gate region equality across them — live-gated) → #29 loner
      nothing-dropped ✅ (a fat bare family overflows the K=4 loud cap → a `+N` `over` mark; the model
       cut returns the count it used to discard — gate `kept === 4 && over > 0` off the snap) → #28
        census-storm identity-stable emission
        (gate what is reachable live — row-slot persistence — and state intent; the full diff-size
         gate is fixture territory, the human's) → #14 verify facts-vs-spreads gates → #23 popped
          intent respected (set `c.popped` in the mutate beat, gate the spill).  SKIP unless the
           decision is already made: #21 extinction (lack-marked — %see never gates green today),
            #15/#22/#26 model-parts (need Pier/radio machinery — out of the pure-data lane).

**PER-SHAPE LOOP (do not deviate):**
1. Dataset via `VoroTest_example(w,'<name>')` (mints the %Example + data world, `c.up` hand-stamp
   included — a nested `w` without `c.up` silently never pumps).  Deterministic data only (no
    Date.now/random).  KEEP the 4-beat shape — new shapes ride the existing bench/mutate/quiet
     beats; do NOT add beats or touch the toc.
2. Witnesses = `%see:'sentence'` — NO commas in the sentence (use an em-dash), gated `n === K` +
   LIVE truth; a %see is a per-beat OBSERVATION that drops after its step, never a latch.  Read
    the off-snap model via `VoroTest_model_of(w,name)`, the snapped rows via `VoroTest_seen(w,
     name)` — drift is the `Se:drift` CHILD of a `%Family` row, and absence IS the quiet reading.
3. `.g` gotchas: pythonic defs; `} else {` never bare `else`; NO regex literals; prefer expression-
   body arrows (closure-heavy raw JS parse-storms); `let X = recv oai …` for oai captures (`$:cap`
    silently drops them); `oai` only at the creator spot, consumers read `o()[0]`.
4. Compile: `GFILES="Ghost/Story/Voronation.g" node_modules/.bin/vitest run -c
   scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts` (same for Voro.g if touched).
    A parse error is usually a bare `else`, a regex literal, or an Edit that swallowed the closing
     `}` of a raw `for {` (never end an old_string one line short of it).
5. Smoke: `BOOK=VoroTest node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs
   scripts/CredRunner.spec.ts`, then READ `/tmp/Story_cli/VoroTest/NNN.got.snap`: every new
    see-sentence present, every old one persisting, the new Example's Voronoiology speaking the
     honest language.  CredRunner green is a SMOKE CHECK, not the gate (§0 BOMBS).
6. LIVE gate only if the runner tabs were reloaded: `npm run ghost-compile -- <file.g>` per edited
   .g (needs the editor tab), then `node scripts/runner_ask.mjs run VoroTest --watch
    --runner=<prefix>`.  If become_book stamps its engagement but no run ever mints, the tabs are
     wedged again — STOP live attempts, continue on CredRunner, leave a note here.  NEVER HMR/save
      src mid-run; release only runs you started.
7. Adversarial pass: for each new %see name a one-line change that should redden it and confirm it
   would.  A see no mutation can redden is theater.
8. Tick the shape in the roster (✅ + date) and keep §0's owed-list current.  Do NOT re-record
   fixtures, register Books, touch washes/pixels, or start wave ③.

## The VoroTest roster — every shape the human has asked for

This is the FILL-OUT PLAN for the VoroTest Book (`Ghost/Story/Voronation.g`).  It collects every
 dataset shape and derivation the human has ever asked the Voro layer to handle, harvested across
  this doc, `Voro_render_todo.md`, `Voro_render_faults_todo.md`, `Voro_vtuffing.md` (north stars +
   next-moves + owner-vision seeds), and `voro_modes/README.md`.  Each entry: a NAME, the human's
    quote|paraphrase + source, and a CLASS TAG:
 - **[model]** — testable at the model step NOW (fixture-gateable off `w:Voronoiology`, no pixels).
 - **[contract]** — testable as the render-consumption contract (what Cytui reads from the model —
    deterministic, gateable once wave ③ makes those readers).
 - **[eyes]** — pixels only (runner_shot territory, never fixture-gated).
Six shapes are ALREADY in the bench (flock/mix/motley/gradient/groves/edges — noted ✅).  The rest
 are owed.  A shape can carry more than one tag (its model fact gates, its pixels don't).

### Structural fold shapes (the crush rules — mostly [model], already gateable)
1. **flock — the homogeneous gang** ✅. *"lots of instances of the different kinds of things"* (the
    VoroTest ask, `Voronation.g`); many leaves of ONE noisy mainkey gang behind a rep.  [model]
2. **mix — families beside loners** ✅. Two families that clear the gang threshold beside single
    loners each standing bare — *"two folds and three bare nodes in one neighbourhood"* (bench).  [model]
3. **motley — all-distinct, nothing folds** ✅. *"eight leaves of eight DIFFERENT mainkeys… NOTHING
    folds"* — the fold needs a population, not a lone instance (bench).  [model]
4. **groves — nested containers / mixed depth** ✅. *"three %Grove containers, each holding a small
    homogeneous sub-flock"* — the crusher folds the OUTERMOST container and stops (bench).  The
     honest answer to *"what does the crusher do with depth"*.  [model]
5. **edges — the smallest-that-folds vs the-thing-that-can't** ✅. a tiny %Pair (folds via the
    container fallback) beside an EMPTY %Void (refused, stands bare) (bench).  [model]
6. **swarm — the un-same folded as a GROUP** ✅ (2026-07-13, `swarm` Example). *"swarms of
    `%req:awaitbuf` and kin escape the fold and litter the graph. Fold them anyway, as GROUPS"* —
     same-mainkey-varying-value.  [model]  **Lack-mark RESOLVED:** the loose-leaf GANG mechanism IS
      mix's gang path (shared `Voro_gang_fold`; mix already proves Fern/Moss fold).  What mix does NOT
       isolate is the THRESHOLD — noisy families (req/witnessed/see/reached) gang at a LOWER min (2
        escalated) than ordinary mainkeys (3).  The `swarm` Example pins that: five varying `%req` gang
         behind one rep at L2 (noisy min 2) beside two `%Cairn` that stay BARE (ordinary min 3).  The
          gate reddens if the non-noisy floor drops to 2 (the Cairns would gang) — a regression mix
           can't catch.
7. **the under-w gang with no foldable parent** — MODEL PART COVERED (flock/mix/swarm all gang loose
    leaves directly under `w` electing a rep; `Voro_gang_fold` is the whole census).  What's OWED is the
     popped↔old-gang **bond edge** (`n.c.bond`, *"the exploding edge, through the graph medium"*): that
      is [eyes] — a drawn edge, not a model fact — so it belongs to the render wave, not this fill-out.

### The ordering / gradient / spread shapes ([model] for the axis, [contract]/[eyes] for the river)
8. **gradient — a smooth ordered run** ✅. *"ten %Stratum leaves whose %depth sweeps 1..10 smoothly…
    the shape a semantic ordering|trail reads best"* (bench); the model's `order_by,axis,from,to` +
     `Loud` rank is exactly this.  [model] for the axis/rank; [contract] for the ordered lay-out.
9. **the outlier — a member bending off the smooth run** ✅ (bench mutate: depth 10→99). the spread
    must SHOW the outlier.  [model]
10. **drift — the readings MOVE across beats** ✅ (bench mutate: arrivals swell flock, goners leave
     mix). the `Se:drift,neu,gone` child + the `%Seem:model` organ.  *"a taxon born (+), one dying
      (-), a count sliding"* (`Voro_vtuffing.md` census-storm).  [model]
11. **the zen-garden river — aligned tuples flowing** (`Voro_render_todo.md` §arc). *"zen-garden
     trails of lined up tuples … a river of some type of debris through another. landscapey."* the
      grasp's aligned `the_*` tuples on FIXED perpendicular lanes.  [contract] for the lane order;
       [eyes] for the drawn river.
12. **I/C/S/O letterform arcs** (`Voro_render_todo.md` Slice D). the family's ordered walk classifies
     to a letterform (`letter_of`); the region's folds lay as beads along the spine.  [contract] for
      the classification off ordered centroids; [eyes] for the arc pixels + Wes-Wilson lettering.

### The music-library shapes (the product data — [model] + [contract] + [eyes])
13. **Artist / Track hierarchy** (VoroScape; `Voro_render_todo.md` Risks 3). *"the Artist/Track
     hierarchy must be expressed… as sub-cells, and sub-graph"* (`Voro_vtuffing.md` bamboo-v2). a
      real 2-level container hierarchy with per-Artist family hulls.  [model] for membership/family;
       [contract] for the sub-cell nesting; [eyes] for the glass.
14. **Track facts + spreads** ✅ (2026-07-13, gated on `flock`). `%year` spread + `%live`/`%remaster`
     facts (`Voro_hash`, deterministic).  the distiller needs facts|spreads to speak, not just a
      list.  [model] for facts vs spreads classification.  **Gated:** the flock reads `grade` (12
       distinct) as the SPREAD it orders by (`order_by:grade`) while `stratum:Miocene` (the value all
        twelve share) rides as a shared `Loud` FACT — the model buckets a fact apart from a spread.
15. **a Pier-fed library dribbling in** (`Voro_vtuffing.md` owner-vision "dribble in"; its demo
     Book VoroRadioPier was RETIRED `5f6b5d29` — the shape is now UN-EXERCISED, kept here as vision).
      *"VoroRadio feeding music from a Pier" = music dribbling in from the Pier node* — a `%Pier` as
       the SOURCE a newborn is born at and flows outward from.  [model] for the source membership;
        [eyes] for the dribble entry animation.
16. **Peer-shares as cross-cell filaments** (`Voro_vtuffing.md` owner-vision "trans-cellular
     filamentation"). *"VoroScape's Peer-shares=edges… threading BETWEEN panes"* — relationships as
      filaments spanning the tessellation.  [contract] for the edge set; [eyes] for the filament draw.
17. **%Share hub weights** (`Voro_vtuffing.md` radio taste #1). the radio should score off *"VoroScape's
     hub weights (%Share counts)"* — a per-hub weight the Loud share-count inversion (wave ③) must
      surface.  [model] for the weight; [contract] for the radio's read of it.

### The flora shapes (the botany test world — [model])
18. **Genus / clade discovery from flat leaves** ✅ (2026-07-13, `genus` Example). a looser
     `w/*` of `{Genus:'epithet'}` leaves where the CRUSHER discovers the clades (governor escalates
      past 15 visible → genus gangs).  [model]  **Gated:** twenty loose taxa (5 genera × 4) crushed
       UNPINNED — the ONLY auto-levelled Example — overrun the 15-cell budget so the governor escalates
        to L1 on its own and the five genera each gang.  Gate is `crush_level === 1` (proves the density
         budget's own escalation, not a pinned level) + all five ganged.
19. **botanical families (multi-genus hulls)** ✅ (2026-07-13, `families` Example). Myrtaceae =
     Metrosideros+Kunzea; Asteraceae = Olearia+Brachyglottis — the grasp's `the:family` grouping;
      sibling folds share a region per family.  [model] for family membership.
     **Gated:** four genus gangs (3 taxa each) share a secondary `clade` sc-fact — Metrosideros+Kunzea
      carry `clade:Myrtales`, Olearia+Brachyglottis carry `clade:Asterales`.  `clade` is the
       dominant-SHARED sc key (all 12 leaves; each genus key only 3), so the grasp's `the:family` =
        each cell's clade VALUE, and `region = Voro_model_family(rep)` off-snap.  The gate (read via
         `VoroTest_model_of`) fires only when same-clade gangs share a region AND cross-clade gangs
          differ — a 3-way condition two mainkey-distinct gangs can satisfy ONLY by the shared fact,
           never by fold_kind.  Region kept OFF-SNAP (never projected — would churn genus fixtures).
            Live-gated on the :9091 runner (the `sibling folds group by a shared property` see fired).
20. **mixed-depth flora** ✅ (groves, #4). deep vs shallow containers in one world.  [model]
21. **extinction / a freed name reclaimed** (Voro_todo open item). VoroMitosis extinction `%see` is
     LATENT — a later split reclaims the freed genus name; sticky-death vs drop.  [model]  // < the
      %see never gates green today — decide before rostering it as a gate.

### The attention / radio / recursion shapes (mostly [eyes], some [contract])
22. **radio drift focus** (`Voro_vtuffing.md` §📻; VoroRadio Book ✅). *"automagically drifting towards
     some subset of stuff… shifts your actual attention around that area"* — age oldest / choose next
      / open a little / glide camera.  the `drift_focus`/`drift_opens`/`popped_auto` stamps.  [model]
       for the pick determinism (VoroRadio %sees it); [eyes] for the camera glide.
23. **popped / surfed states** ✅ (2026-07-13, `popped` Example). a member popped OUT into the graph
     (`c.popped` / `c.popped_open` chain); the dip spills top-K=3, the rest re-gangs.  [model] for the
      crush respecting the intent; [eyes] for the graph explosion.  **Gated:** three `%Ingot` gang at
       the bench (L2 min 3); the mutate beat pops one (`c.popped`) — it stands OUT (no stuff, not
        represented) and the remaining TWO re-gang at the spill min 2.  Two is below ordinary min 3, so
         the re-gang can only mean spill relax fired — doubly adversarial (also catches the popped-tiny
          branch sweeping the popped leaf back in).
24. **cells within cells — recursion** (§0 destination; `history/Voro_microcosm.md`). *"effortless
     zoom-recursion through any… a microcosm member with its own fold gets its own cells"*; the
      radial rule RECURSES one level down.  [contract] for the sub-model; [eyes] for the sub-glass.
25. **the tunnel — the graph on a tube wall** (`Voro_vtuffing.md` §🕳). *"cytoscape computed not in
     2d but around us on the wall of a tube… solidity on the left… like a C."* seed re-projection.
      [eyes] (pure projection, nothing model-side).
26. **the light cone + saved trail** (`Voro_vtuffing.md` owner-vision). *"a light cone of stuff from
     the current point"* (behind=visited, ahead=reachable) + *"endless Travel, saving the trail"* (a
      durable breadcrumb of the whole drift path).  [model] for the trail record (c-side / Storyrun-
       grade); [eyes] for the cone render.

### The pane-legibility shapes (the text-rendering wave ⑤ — [eyes], with [model] weight hooks)
27. **big text stretch-ups / 14pt floor** (`Voro_render_todo.md` Slice A; `Voro_vtuffing.md` §Se-grasp).
     *"big text stretch-ups"* with a hard 14pt font floor; loud properties bigger — species epithets
      tower, universal `woodystem` recedes.  [eyes] for the fit; [model] for the `wgt` weight (grasp).
28. **the census-storm shape — identity-stable emission** ✅ (2026-07-13, gated on `flock`, live-
     reachable part). a step that gains|loses a handful of taxa must diff as the real news, NOT a
      ~200-line churn.  the model's keyed-in-place emission.  [model] — THE gate that proves the storm
       collapsed.  **Gated (the live-reachable part):** the flock's `Family:Boulder` row NODE is
        captured at the bench (`w.c.census_id`); at mutate the gate asserts it is the VERY SAME node
         (`frow === w.c.census_id`) with `n` slid to 15 — a drop-and-rebuild storm would hand back a
          fresh node.  The full diff-SIZE gate (no ~200-line churn) stays fixture territory, the human's.
29. **a loner showing ALL its ugly bits** ✅ (2026-07-13, `relics` Example + a model cut). *"I want all
     ugly bits of eg %req included, no hiding stuff"* — a fold keeps its K loudest claims and marks the
      crowded-out tail with a `+N` `over` count.  [model] for "nothing dropped silently".
     **The model cut (smallest possible):** `Voro_model_loud_from` already computed the DISTINCT non-axis
      claim count (`order.length`) and threw it away — now it returns `{ list, over }` where `over` =
       claims crowded out beyond K=4.  The %Family node stamps `over` off-snap and the snapped row mirrors
        it (cleared with the sliding fields, so a family thinning back under the cap sheds it).  Behaviour
         is ADDITIVE — the K Loud rows are byte-identical; `over:N` appears ONLY on a family whose distinct
          loud pool exceeds 4 (rare: gang vtuffing pre-compresses, so it takes a fat BARE|pane family).
     **Gated:** two bare `%Relic` (a pair below gang min 3) with six distinct props each → one bare family
      of two whose loud pool is ten distinct claims → `over:6` beside four kept Loud.  A tray of three
       `%Coin` gangs beside them purely to WAKE the model (a gangs:0/folded:0 world gets no grasp — the
        `Voro_crush_scan ~:86` guard).  The gate reads the SNAP (over is projected) and fires only when
         `kept === 4 && over > 0` — reddens if the cap silently dropped the tail (over absent) OR the cap
          were removed (kept ≠ 4), so it asserts EXACTLY the invariant.  Headless-green + adversarially
           airtight + **LIVE-GATED** on a reloaded runner (`Family:Relic …,over:6` + the see computed live
            on a fresh-core tab — the first runner had wedged on the core Voro.go HMR).  Fixture re-record
             still owed (the run reds only on the relics diff — recorded fixtures predate this Example).
     **Blast radius:** every Voro model consumer (VoroScape/VoroRadio/VoroMitosis) now emits `over:N` on
      any fat family — re-record if one surfaces (none in VoroTest's other Examples; all ≤2 Loud).

**Coverage note (2026-07-13):** the bench now holds 11 shapes (✅: flock, mix, motley, gradient, groves,
 edges, **swarm**, **genus**, **popped**, **families**, **relics**); with #14/#28 gated on `flock`, the
  [model] fill-out landed #6 #14 #18 #19 #23 #28 #29 this round (#19 live-gated on :9091; #29 headless +
   the one small model cut, live gate owed on a runner reload).  #7 model-part is covered (its bond edge
    is [eyes]).  **Every [model] roster shape is now covered.**  The remaining shapes want Pier/radio
     machinery (#15/#22/#26) or are [eyes]-only —
     proven by `runner_shot`, never a fixture.  Add a shape by the `[testing-is-story-books]` +
      `[see-assertion-layer]` rules (a CHECK run then manual `%see` install, never a CredRunner ACCEPT).

## The lexicon — every load-bearing word, formally introduced (the human's ask, 2026-07-13)

New words get a line HERE when they enter the system; an ill-defined word is a bug.

- **claim** — one `key:val` a particle asserts about itself (`%Relic,metal:brass` claims its metal).
- **family** — who belongs together: the fold unit (a gang of one mainkey; sibling panes of one
   kind; same-mainkey bare loners merged).
- **fold / gang / pane / bare** — the crush's outcomes: a GANG of loose same-mainkey leaves behind
   one rep; a container folded as its own PANE; a leaf left standing BARE.  `c.stuff` marks a fold.
- **census** — the count of what stands (the `%cell`/`%bare` rows).  // < "census" ALSO names the
   grasp's claim-tally (the loudness corpus) — two senses, one word; rename candidate.
- **grasp** — the Se pass that weighs every claim against the neighbours and voices each fold into
   the sphere (`the:name|n|trait|family` on its D).
- **loudness** — a claim's earned type-size: how much it sets its cell apart.  Shared-by-all ≈ 20
   (recedes); unique ≈ 95 (towers); 96–100 reserved for identity, so a fact never out-shouts the
    name of the thing it describes.
- **%Loud** — a family's top-4 claims ranked by ACROSS-PILE rarity: what distinguishes this family
   from the OTHER cells of the world (often facts every member shares WITHIN the pile — the
    within-pile variation story belongs to spreads|axis, not Loud).  // < the word is opaque (the
     human may rename) AND the implementation has the known share-count inversion (wave ③).
- **trait** — a cell's single loudest claim (its epithet); `Se:scape`'s trait = the loudest cell's.
- **region** — the grasp's coarse grouping: each cell's value on the widest-SHARED key.
- **axis / order_by** — the widest-SPREAD key: what orders a family's members (`from`/`to` ends).
- **name** — DISCOVERED (`Voro_model_namekey`, 2026-07-13): the key (excluding the axis) that is a
   BIJECTION on its carriers — as many distinct values as members carrying it.  Missing data just
    lowers coverage (a 9-of-10 key still names those 9; the tenth falls to its anchor); a self-naming
     mainkey (`Fern:silver`) pre-empts it.  Completes the data-discovered trio: region = widest-shared,
      axis = widest-spread, name = best-identifying.  NAME (eyes) is SEPARATE from ANCHOR (drift
       identity, the join-of-values, frozen).  LANDED for the snapped ENDS (from/to lose the type
        prefix).  // < remnant: the render-side `Voro_naming_keys` English list still feeds
         `Vtuff_name`/`Vtuff_ident` (the pane titles the glass draws) — thread the discovered key
          there in wave ③ (eyes-verified), then delete the list.
- **model** — ALL data representation by Voro (the ruling); `w:Voronoiology` is its snapped face.
- **reading** — one row of testimony the machine writes about what it saw; mainkey = how it knows.
- **%Seem / %Se** — the memory organ (a live Selection off-snap) / a reading that REQUIRED memory
   (phase-level provenance: `%Se:input|scape|census|drift`).
- **weather / %Se:input** — arrivals|departures of the data itself, openness-blind.
- **openness** — the zoom state (crush level, pops).  Moves ON the remembered things (an
   annotation), never decides WHO is remembered (the born|died reframe — LANDED `bb1c2ecf`:
    the mark is `src.c.was_fold` on the SOURCE particle; `Se:scape` says `folded:N`/`unfolded:N`
     only on a beat the dial turned, while born|died stay pure mitosis).

## The Se process — %Seem the organ, %Se the reading (the doctrine, and how to build with it)

Vocabulary, binding across docs (`Radio_todo.md §9` says "the Se" for the organ — same thing,
 older name; a sync note sits there):
- **%Seem** is the ORGAN: a particle holding a live `Selection` on `sc.Se` (`i_Seem`/`o_Seem`,
   `LangHold.svelte`).  `o_Seem` resolves the subject tree against its D-sphere: survivors keep
    history (`bD`), departures come back as goners, arrivals as neus.  It is snap-hostile (live
     fns ride its sc) so it PARKS on a free off-snap C**, never in a snapped world.
- **%Se** is the small SNAPPED reading a Seem projects (`Se:scape`, `Se:census`, `Se:drift`).
   **Mainkey = provenance**: a row wears `Se` iff a `Selection.process()` produced it; computed
    census wears plain names (`%Family`, `%Loud`).  The ~97% rule (the human's calibration): the
     mainkey is the LEADING type and must not lie — but the other sc keys are real semantics too
      (facets), and each must be a FACT, not chrome.

**THE BUILD RECIPE** — the "new interface for coding algorithms"; every Voro organ is built this
 way now, and any organ that re-derives "what changed" per beat should be:
1. Working state = a free C** (`new TheC`), hung on `w.c.<name>`, reachable from nothing — churn
   is free there, no snap sees it, no encode can crash on it.
2. Stand a %Seem over it (`i_Seem` with your own `each_fn` if the diff must reach deeper than one
   layer).  The Seem node must SURVIVE your rebuilds — spare its mainkey in any drop loop; its
    D-sphere IS the cross-beat baseline (drop it and drift freezes: everything reads as new).
3. Never hand-roll a last-beat diff — `resolve()` gives goners|neus with identity.  Suppress the
   FIRST resolve (a fresh sphere makes everything trivially new; that beat is baseline, not news).
4. Resolve hands back DETACHED clones (no parent link) — attribution must ride ON the subject
   row's own sc (the `fam:` stamp pattern), never be reached by walking up.
5. Non-strict resolve pairs by content|position: a field EDIT reads as a survivor; only true
   arrivals|departures drift.  That is the wanted semantics (the bent-gradient test).
6. Project the reading into the snapped world under the honest language: computed rows plain-
   named; ONE FACT ONE PLACE (the axis key is excluded from Loud — `order_by`/`from`/`to` own that
    story); ABSENCE IS A VALUE (quiet = no drift child, never a field saying "nothing"); render
     chrome NEVER crosses (×N titles, /*N dips, wgt sizes are paint — a fixture that bakes chrome
      reads presentation as data); find-or-create durable slots so survivors keep their line (no
       census storm); self-sweep un-retouched rows, sparing what other organs author.

REACH FOR IT WHEN: per-beat `c.*` flags accumulate; a hand-rolled this-beat-vs-last-beat diff
 appears; a verdict judged in isolation should read neighbours|history.  `Seemables_todo.md` holds
  the parked harvest + the discipline: grow the mirror BESIDE the green thing, prove it on a live
   Book, only then flip a consumer — and a mirror must diff an INDEPENDENT source, never its
    target's own output (that mirror is theater).

## The metaphysics

1. **Cyto is the layout engine; Voro is an interpretation of its result.** fcose decides
    where the chunks sit; cells, walls, moldings are derived pixels. Pixel geometry never
     pushes back into the layout — ZERO exceptions. (The rack — equipment nodes
      column-packed at the right edge — used to be the one sanctioned exception; it is
       SHELVED behind `RACK_ON = false` in `voronoi_layout()`, kept as the seed of a
        future in|out-group process option. The oddballs just sit where fcose put them.)
       The cautionary tale is `size_stuff_node()`'s voronoi guard: growing a node
        from its own cell's size is a feedback runaway.
2. **Nothing RENDER-side is ever snapped.** c-side (`n.c.*`) or component `$state` only;
    no `%keys`, no `sc` writes, no wave participation. A Book underneath must never be able
     to see the render (the Leaf* Books keep checking Cyto basically works). The ONE sanctioned
      snap is `w:Voronoiology` — the fold's own PROCESS-trace (`Voro_report`), a sibling world,
       NOT render pixels, imposed/pruned Story-side (§0). So the self-test is narrower now: a
        fixture diff in the *flora* (the Book's own world) means you broke this rule; a
         `w:Voronoiology` row is the fold reporting itself, by design. If your design seems to
          need a snapped flag ON THE FLORA — stop, the design is wrong.
3. **The crusher is the only minter of `c.stuff` / `c.stuffy`** and it lives in
    `Ghost/V/Voro.g` (`Voro_crush_scan / _walk / _crushable / _clear`). Crush-policy work
     goes there, in the LangTiles DSL, not in raw TS. After a `.g` round:
      `npm run ghost-compile -- Ghost/V/Voro.g` (needs the editor tab open on :9091);
       NEVER edit `src/lib/gen/**/*.go`.
4. **Toggleables are workspace prefs**, remembered in the stash (the `Cyto_voronoi` /
    `Cyto_tall` pattern in Cytui) — never per-graph state, never snapped.
5. **Matstyle reads are free; Matstyle MINTS are writes** under `The/Styles` (snapped!).
    A render path may look a style up but must never cause one to autovivify — fall back
     to a palette colour when the style is absent.
6. **DOM-measure feedback must be damped.** Any `offsetWidth`-style measurement that then
    changes what the same overlay renders (wrap width, font, molding) re-enters
     `voronoi_layout()` as a seed weight. Measure at settle cadence (the
      `show_overlays_soon` / ResizeObserver rhythm, never per-frame) and add hysteresis
       (ignore sub-threshold changes) or the tessellation oscillates.
7. **Verify with eyes on a live :9091 runner.** `node scripts/runner_ask.mjs run
    VoroMitosis --watch` (then `VoroScape`), then WATCH the tab. Headless is banned
     (false greens). No Book can gate pixels — these tasks are verified by watching, and
      by fixtures NOT changing. Never save src mid-run (HMR kills in-flight runs).
8. **No one-off scripts, no vitest specs.** If a task ever grows a testable non-pixel
    seam, that seam becomes a Story Book (registered in Waft:Credence) — but the pixel
     work itself is watch-verified.

## Where things live

- `src/lib/O/Cytui.svelte` `#region voronoi` — `voronoi_layout()` (seeds → power
   walls → polygon moments → molding affine T → fit; the shelved rack rides a false
    flag here), `paint_final()` (walls, notch braces, tips; molds each Stuffing via
     left/top/size/clipPath + a child transform), `morph_voronoi()` (generation tween;
      birth from seed, death to centre), `box_support()` (the one support formula
       walls and fit share).
- Motion: `drag_frame()` (the shared live-repaint loop + per-frame budget self-heal),
   `pan_zoom_motion()`, `show_overlays_soon()` (the settle), `visor_guard` (capture-phase
    wheel steal over the right strip — pass-through for clicks/drags, stands down when
     the page can't scroll, so full-bleed toplevels wheel-zoom), `middle_pan_down`
      (middle-drag pans), `wrap_key` (←/→ walk the story pips from the focused canvas,
       riding Storui's `H.c.story_nav`).
- Overlays: `#region overlays` — `stuff_mounts` holds live mounted Stuffing components;
   `reposition_overlays()` deliberately SKIPS a cell-molded Stuffing (clipPath set):
    `paint_final` owns those. Preserve that ownership split.
- `src/lib/data/Stuffing.svelte` — the Stuffing component itself.
- `Ghost/V/Voro.g` — crush policy + the demo Books `VoroMitosis` / `VoroScape` (a Book's
   world and method share the Book's name EXACTLY, or dispatch silently no-ops).
- Toggles on the ◈ bar (all stash prefs, metaphysics §4): ◈ voronoi, ❝ properCellable
   (wordy loners — %see — get a self-row Stuffing and thereby a cell; default follows
    voronoi mode; rides `node_src`, the live particle now ferried on EVERY wave
     upsert's `.c`), ⬡ family hulls (`Cyto_families`, default on), 🌀 gravity brush
      (`Cyto_gravity_brush`, default off), ▤ vtuffing swap (`Cyto_vtuffing`, default
       on — off = molded Stuffings at every zoom), Vexpandy tall.
- Design notes: `history/Voro_microcosm.md` (task 6 — retired 2026-07-13, superseded by
   Vtuffing), `history/Voro_pinch.md` (task 7 — retired 2026-07-13, built), `Voro_vtuffing.md`
    (the microcosm cards grown into the pane-content ENGINE — Vtuff_build's layout C** + the chord
     fit + the /*N pop-out surf, built 2026-07-06), `Voro_svg_stuffing.md` (task 8 — STILL LIVE:
      the cross-wall alignment LAYER ON vtuffing, NOT a rival rebuild; Vtuff_build IS its row
       model, the unbuilt part is the shared-wall matching = vtuffing agenda #9; await agreement).

## The tasks

Grades: **GRIND** = mechanical against this brief; **GRIND+** = needs local judgment;
 **DESIGN-FIRST** = write a short design note and get it agreed before code.

### Round-2 fixes — LANDED 2026-07-06 (browser-unverified)

Two quick reaches off the owner's first eyes-on pass:
- **`%Opt` hidden in the graph.** `cytyle_classify` now `skip`s `%Opt` (Cyto.svelte) —
   the `Opt/*` nodes the owner still saw were config scaffolding (a Book's toc `Opt`, e.g.
    `useVoroCyto`, is a switch Story reads, not data). The crusher already ignored `%Opt`;
     the view hides it too now, universally. The model still carries the opt (it is the toc
      switch Story reads at snap time) — only the render drops it.
- **Stuffing width → max-width only.** paint_final forced `child.style.width`, so a
   short line measured as a full box and the affine scaled that wide box down → tiny
    text + dead gap (the owner's exact report). Now `width:''` (keeps `.cytui-stuff`
     max-content shrink-to-fit) + `maxWidth` as the wrap ceiling only, lowered 480→360.
      The mold scales the TEXT, not the padding.

### 9. Sensible intensity: hover around ~9 panes — BUILT 2026-07-06 (browser-unverified)

The owner's "too much in one screenful … aim for 9 families or so", built as an
 INTENSITY GOVERNOR in the crusher (the owner's own hunch — "hook into the underlying
  Cyto_scan process quite early" — landed one seam earlier still, in `Voro_crush_scan`,
   which already runs before every scan): each crush pass is now AUTHORITATIVE (stamps
    and unstamps, so level changes and shrinking graphs self-correct) and counts
     `stats.visible` — the nodes the Cyto walk will actually draw. Too dense (>15) →
      escalate the crush level and re-pass; too sparse (<6) → relax, never back past the
       ceiling. The level rides `w.c.crush_level` (c-side hysteresis across beats).
- Level 0: today's rules + noisy-leaf gangs (≥3). Level 1: gangs loosen (noisy ≥2, any
   mainkey ≥3). Level 2: `Peering`/`Pier` structural containers fold whole (≥2 kids).
- `{folded,count}` keep their RECORDED meaning (container folds only — MusuReplica's
   ratio `%see` reads them); gangs ride separately as `{gangs,ganged}` + `{visible,level}`.
- Still owed: live-eyes calibration of the 15/6 band and MICRO_Z once the tab reloads —
   the numbers are first guesses, judged only by watching.

### 1. Wrap width from the cell — GRIND+ — BUILT 2026-07-06 (browser-unverified)

Done as specified below: `paint_final` hands the child a 24px-quantised width off the
 cell bbox, >15% hysteresis (`wrap_applied`), settle cadence only. Watch for the §6
  oscillation check before calling it verified.

Today the Stuffing renders at its natural max-content width and `paint_final` scales
 that fixed box into the cell (fit·T). Invert it: the CELL should hand the content a
  wrap width, so the text re-flows to the cell's proportions and never touches the
   walls — how wide to make the Stuffing to wrap its contents appropriately.
- Where: `voronoi_layout()` already computes the cell's eigenframe (λ1/λ2, φ) and
   centroid; derive a target content width from the cell's extent along its long axis
    (minus a wall margin), set it as an explicit width/max-width on the overlay's CHILD.
- Danger: metaphysics §6 — the child's size feeds the next tessellation as seed weight.
   Quantise the target (say 24px steps) and only re-wrap when it moves by >15%, at
    settle cadence only. Watch a resting graph for a full minute: zero oscillation.

### 2. Angle: a long cell wants a long Stuffing — GRIND+ — BUILT 2026-07-06 (browser-unverified)

Done: the molding composes R(θ)·S — |θ| ≤ 20°, snapped to 0 below 8°, gated on real
 elongation (>1.18) so a round cell's φ noise never tilts text; `box_support` grew a
  T21 (defaulting to T12, so symmetric callers unchanged).

The molding T is symmetric today — a deliberate no-rotation choice so text never
 tilts. Relax it a LITTLE: rotate the Stuffing toward the cell's long axis φ with hard
  legibility caps — |angle| ≤ ~20°, snap to 0 below ~8°, never past vertical (text
   must never read upside-down).
- Where: fold the capped rotation into T (T11/T12/T22 stop being symmetric — that is
   fine, `box_support()` already takes a general T, so the fit stays correct for free).
- Do after task 1; angle without re-wrap just tilts a wrong-shaped box.

### 3. Fold colour by dominant kind + fold-count size — GRIND — BUILT 2026-07-06 (browser-unverified)

Done: the crusher stamps `c.fold_kind`/`c.fold_n` (`Voro_stamp_fold`, gen recompiled
 via LocalGen); Cytui's `cell_color` reads the kind's Matstyle READ-ONLY (o() query,
  border-colour fallback) and the seed floor lifts by `log2(1+n)·9`.

The crusher already returns the dominant child mainkey (`kind`) and the fold count.
- Colour: a fold's cell should carry its dominant KIND's colour, not the fold node's
   own border colour (see the `color:` pick in `voronoi_layout()`). Look the kind's
    Matstyle colour up READ-ONLY (metaphysics §5) with a palette fallback.
- Size: let the fold count accentuate the seed weight (a bigger family claims a bigger
   cell) — a gentle log scale on the hw/hh floor, c-side only.
- Both stats are live returns from `Voro_crush_scan`; if they need to ride to Cytui,
   they ride on `.c`, never `.sc`.

### 4. Family outlines: the w/** hulls — GRIND+ (toggleable) — BUILT 2026-07-06 (browser-unverified)

Done, via post-hoc edge attribution instead of a clip_halfplane rewrite: every cut's
 line is kept and each final wall midpoint-tested against them (`edge_src` on VCell —
  the SVG-Stuffing spec reuses it as free adjacency). Families = cells grouped by the
   compound ancestor one below the w root, ≥2 members; boundary walls stroked as
    disjoint faint segments (visually identical to a traced loop, immune to topology
     surprises). ⬡ toggle, stash `Cyto_families`, default on.

**RESOLVED 2026-07-06 via Route C (browser-unverified)** — neither the sub-world Route A
 nor the core Route B: `family_of` grew three answers in priority order, all render-side:
- 1) `c.vfamily` — an explicit c-side tag on the live particle (read via `node_src`).
   `VoroMitosis` now stamps each genus cell with its real botanical family
    (`Botany_family`: Metrosideros+Kunzea+Leptospermum = Myrtaceae, Olearia+Brachyglottis
     = Asteraceae…), and `Botany_genera` is REORDERED so both multi-genus families
      radiate into being within reach (one split per beat reaches ~index 9; Pseudopanax
       gave way to Brachyglottis). Model data changed → the owed re-record covers it.
- 2) the compound ancestor one below the outermost (the classic route, unchanged).
- 3) the MODEL parent (`c.up`) when it isn't w/H/A — sibling folds under one Pier or
   Artist hull together on ANY real graph, no tag needed (MusuReplica's inbox/outbox
    pairs hull per Pier for free).
The earlier diagnosis stands as the why: every genus cell sits directly under `w`, so
 the ancestor route alone could never fire there — the owner's "%Coprosma child notes"
  hunch was one level off (hulls group sibling CELLS, not one cell's interior).

**Restyled 2026-07-06 — the chunky rope.** The owner looked and saw no hull; two causes:
- the stroke (2.5px @ 0.38, UNDER the cell strokes, on the SAME inset walls) was a
   sub-pixel fringe — literally invisible even when a family grouped. Now a two-pass
    rope: 11px @ 0.30 body + 4.5px @ 0.55 core, rounded caps, same disjoint segments.
- data-side, the worlds on screen had no ≥2-cell family yet: VoroScape's folds sit
   directly under w BY DESIGN (no hull expected); VoroMitosis's `c.vfamily` stamps ride
    the NEW gen — the tab reload + re-run is the gate. Myrtaceae's trio radiates in
     around beat 7+.

Outline all the cells of each direct child of w — e.g. everything under `Pier/**` gets
 one shared outer outline — but only for families with real structure: at least
  `w/*/*` depth, where a `%witnessed` child does NOT count as structure.
- Approach: cells know their particle; group by ancestor-directly-under-w. The union
   outline = the walls whose cutting neighbour (in the half-plane clip) is OUTSIDE the
    family or is the frame — extend `clip_halfplane` to tag each edge with its cutter's
     id, then trace the untagged/foreign-tagged edges per family into one faint second
      stroke (distinct colour per family, well behind the cell strokes).
- A ◈-bar toggle, stash-remembered (`Cyto_families`), metaphysics §4.

### 5. Crush harder: group the un-same — GRIND+ (crusher policy, .g work) — PART-BUILT 2026-07-06

Built: `Voro_swarmable` in Voro.g — a STRUCTURAL container whose children are a
 homogeneous swarm (≥3, all one noisy mainkey: req|witnessed|see) folds as the
  group's chunk (w/H/A never fold); stamps ride `Voro_stamp_fold` like any fold.
   Gen recompiled (LocalGen; the editor path was down). STILL OPEN: leaf swarms
    directly under w/A with no foldable parent (a sibling GANG needs an elected
     representative + Cyto walk support — design that with task 6's microcosm, the
      machinery overlaps), and the ≥0.8-dominant loosening if strict homogeneity
       proves too shy on real traffic.

**BUILT 2026-07-06 — the gang co-crush (browser-unverified).** `Voro_gang_fold`
 (Voro.g): the walk gathers loose LEAVES per container by mainkey; a big enough gang
  (noisy `req|witnessed|see|reached` ≥3 at level 0, looser under the governor) ELECTS
   its first member as representative — the rep wears the fold stamps plus `c.gang`
    (live member refs, `.c` only) and the rest are `c.represented` (skipped by
     `cytyle_classify` — the one line of Cyto walk support, inert anywhere the crusher
      never ran). NOTHING is minted or reparented in the model: no synthetic particle
       ever enters the tree, so no snap and no fixture can see a gang.
- The rep's pane material is a Cytui-side MIRROR (`gang_stuff`): a free `_C` container
   (unreachable from H** → never snapped) rebuilt from the members' sc when the gang
    size changes; the mounted Stuffing keeps its ref and re-groups on the normal flush.
     Same-size membership swaps can lag a beat — acceptable for assertion confetti.
- Election is stable (first member; newcomers append) so the gang's cell identity —
   and its morph — survive growth. Rep death births a fresh cell (fine, it's a death).

`Voro_crushable` wants same-ish children, so `%witnessed:$different_stuff` (same key,
 different sentences — they aren't resolving as same) and swarms of `%req:awaitbuf`
  and kin escape the fold and litter the graph. Fold them anyway, as GROUPS:
- Loosen "same" to same-MAINKEY-varying-VALUE for designated noisy families
   (`%witnessed`, `%req` at minimum), each group folding behind its own chunk whose
    skin shows the spread (e.g. `witnessed ×14 · 9 distinct`).
- This is `Ghost/V/Voro.g` work (metaphysics §3), c-side throughout. Subgraphing them
   — one group-chunk with the members as its microcosm — is task 6's territory; here
    just get them folded and the graph tidier.
- Verify on VoroMitosis: the genus panes must still read; fixtures must not move.

### 6. Composite shapes: layout WITHIN a cell + zoom-recursion — (a)+(b) BUILT, then REBUILT as VTUFFING 2026-07-06

`history/Voro_microcosm.md` (retired) carved it; the owner's eyes-on verdict on the v1 card grid
 ("woefully underexpressing — they just say Track") turned it into an ENGINE —
  `Voro_vtuffing.md` is now the living note:
- CONTENT: `Vtuff_build` (Ghost/V/Voro.g) distils members into a free layout C**
   (title | shared facts | spreads-with-chips | member rows | the /*N dip) — cached
    by count+versions, extensible per fold-kind via `Vtuff_of_<kind>`.  Cytui only
     normalises + fits; a TS fallback speaks plainly until the new gen boots.
- FIT: rows chord-fitted to the CONVEX cell polygon (`poly_chord`/`micro_fit`) — text
   follows the slanted walls; overflow keeps title+head+dip and says `+K more`.
- (b) the swap is ONE RULE now (2026-07-07, owner: "weird how half are Stuffing half
   Vtuffing"): ▤ on = the engine owns EVERY fold pane that clears √area ≥ 70px AND
    fits ≥1 row (no zoom threshold, no per-cell hysteresis memory — that made
     same-size neighbours differ by zoom HISTORY); Stuffing dims only once rows
      really render.  BOTH cadences (cache + pure math) so rows ride a drag live.
- The /*N surf: member|dip rows are buttons → `Vtuff_pop` pops nodes OUT INTO THE
   GRAPH (c.popped / c.popped_open intent stamps, crusher respects, ◈-clear forgets)
    — never expands inside the pane.
- COLOUR (owner "restore the stained glass; where's this teal from?"): cell colour is
   `kind_glass` = Matstyle swatch → else a per-kind hue floor (`kind_hue`), never the
    single teal fold-border again; swapped cells wear a dotted rim; rows use `kind_tint`.
- ROUND 2 (2026-07-06, owner review): #3 surf UNDER CONTROL (any-depth member pop via
   Vtuff_pop_stamp chain-unfurl — v1 fold-member pop was a silent no-op; bounded dip
    top-K=3 + spill relax re-gangs the rest at min 2; un-pop = right-click, Vtuff_unpop)
     + #4 LIST FORM (homogeneous → title once + member-bit chips, each a pop handle;
      Vtuff_keyrows skips the family mainkey) + depth-1 row:sub openness + the fold-hub
       explosion edges arrive free from the scan's non-compound-parent `/` rule.
- ROUND 3 (2026-07-07, owner review): ONE swap rule (▤ owns all fold panes — no more
   half/half by zoom history); NAME + TYPE-TAG title split (`Vtuff_name`; 'Kunzea ×14'
    tagged `cell` ≡ 'Fernway ×2' tagged `Artist` — the two-format stutter dead); the
     lilac `/*N` `sub` glyph on rows AND chips; 2D list wrap; deterministic trait
      sprinkle on both Books' data (`Voro_hash` — %woodystem/%habit/%endemic,
       %year/%live/%remaster) so panes have facts|spreads to speak.
- ROUND 4 (2026-07-07, owner review): VoroMitosis FLATTENED — the cell:<genus>
   containers were technical vocabulary leaking into data ("why does it even say
    cell?"); flora now a bigger looser w/* of {Genus:'epithet'} leaves and the CRUSHER
     discovers the clades (governor escalates past 15 visible → genus gangs; beats 2-3
      run genuinely loose first).  Crusher: TINY all-leaf fronds (≤3) gang as chips
       instead of claiming panes (fallback: an ungangable tiny container still folds —
        lone artists keep cells).  List cap 9→25; chips seed a PHI SPIRAL (Vogel
         r∝√k θ=k·137.508° — the kind-hue golden angle) filling the pane's belly.
          vfamily rides every taxon now (hulls survive the flatten).  NOTE: MusuReplica
           crush-husk counts may drift from the tiny-gang evolution — check before Accept.
- Two modes of recursion carved (same-graph vs subgraph-in-cell; mode A first, intent
   AGING sketched for the wandering-landscape problem) — `Voro_vtuffing.md`.
- ROUND 5 (2026-07-07): 📻 THE RADIO v1 built (`Voro_drift_tick` + Cytui dwell clock,
   stash `Cyto_radio` default off) — ages oldest auto locale shut / scores next focus
    (size+freshness+nearness+hash taste, 4th-hop free jump) / opens it a little
     (`popped_auto` — a human's pop never aged) / camera glides; dial-touch = 15s
      holdoff.  SUBSUMES the auto-spill agenda item.  `Voro_vtuffing.md` retitled THE
       SYSTEM DOC — §North stars (radio + the C-arc TUNNEL projection design) leads it.
- ROUND 6 (2026-07-07, overnight): 🕳 THE TUNNEL v1 skeleton built — NOT per-overlay
   CSS 3D but ONE remap at the seed-gather (`tube_project` in Cytui): seeds onto the
    tube wall (θ by fold-mass rank, solidity-left at π; depth from layout y; boxes ×
     NEAR/d) BEFORE the power diagram, so cells/molding/chips/hulls/morph all follow
      free — toggling morphs flat glass ↔ rosette.  Per-cell fog; radio dwells advance
       the drift phase.  Stash `Cyto_tunnel`, 🕳 on the ◈ bar.  UNTUNED — needs eyes.
  + VoroRadio Book (9 steps, Credence What:Voro, brand_new): the radio determinism
     gate — FOUR %sees (motion / aging / pool-CYCLE / hand-immunity).  An adversarial
      audit of v1 caught the aging claim green OFF the very bug it claimed dead: the
       popped-unstamp deleted c.gang → Vtuff_unpop's sibling sweep was dead code →
        aged locales leaked permanently-popped orphans (pool shrank silently).  Fixed
         at the unstamp seam (gang memory survives a popped unstamp; unpop sweeps then
          retires it) + the cycle %see now reddens on any regression.  RE-RECORD OWED
           (engine + witness changed after the first recording; runner busy overnight).
  + runner_ask.mjs auto-courts ONE runner (role-broadcast run fanned to every tab —
     the double-dispatch the owner watched); sticky /tmp target; story_repl same.
- NOT built — `Voro_vtuffing.md` §"next moves": #2 the under-w gang bond edge (core
   seam, small), #5 hull layout-nudge, #6 fit refine, #7 deeper recursion, #9 the
    single worked window; §North stars: radio taste/dwell/audio-coupling, tunnel
     camera/solidity-wholes/overlay-fog/pointer-inverse.

Can the composite shapes be custom — i.e. lay a fold's members out INSIDE its cell (a
 microcosm: mini grid or mini force pass in the cell's own frame), instead of one flat
  Stuffing? And effortless zoom-recursion through any: zooming into a cell swaps its
   Stuffing for its microcosm, progressively, without the C tree ever changing (the
    crushed children are all still in C — the crush only suppressed Cyto's descent).
- Carve: (a) static grid microcosm in a cell, (b) zoom-threshold swap Stuffing ↔
   microcosm, (c) recursion (a microcosm member with its own fold gets its own cells).
- Write the design note first: coordinate frames, when the mini-layout runs (settle
   only), and how it stays inside the budget self-heal.

### 7. Scroll = pinch|spread the locale — BUILT 2026-07-06 (browser-unverified)

`history/Voro_pinch.md` (retired, built as designed after the owner's green light): 🌀 on the ◈ bar
 (stash `Cyto_gravity_brush`); while armed, a plain wheel over the graph sculpts the
  locale (gaussian σ=140 rendered px, cutoff 0.05, k≈±0.06/notch scaled by delta,
   MODEL-position writes through cy so strength is zoom-independent) and Ctrl/Cmd+wheel
    passes through to the camera zoom. Guards: never while a layout runs
     (`live_layout`), compounds and nuclei never move, soft 40px frame clamp so a
      spread can't fling slivers off-screen. Every burst rides `pan_zoom_motion` — the
       brush is just another motion, live re-tessellation + settle for free. The visor
        keeps stealing its strip first. fcose's next wave undoes the sculpt, by design.

A mode where the wheel does not zoom the camera but contracts|spreads THAT LOCALE of
 nodes — wheel toward pulls the neighbourhood under the cursor together, wheel away
  spreads it apart (a gravity brush).
- Position writes here are LAYOUT-side input (like a user drag), so they're allowed —
   but only while no layout is running, and they must go through cy positions so the
    normal motion loop re-tessellates.
- Stash-remembered mode toggle; the visor keeps owning the right strip either way.
- Design note first: the falloff curve, the radius, and how it coexists with fcose
   (does the next wave undo the sculpting? probably yes — say so, and decide whether
    that is fine for a play-mode).

### 8. The single worked window: cross-wall row alignment — a LAYER on Vtuffing — DESIGN-FIRST

**Reframed 2026-07-06:** this is NOT a separate "SVG-native rebuild" — the Vtuffing
 engine (task 6, BUILT) is now the substrate.  `Vtuff_build` already emits the rows;
  task 8 is the unbuilt NEXT layer that makes NEIGHBOURING panes' rows EDGE TOGETHER
   across the shared wall (= vtuffing agenda #9).  `Voro_svg_stuffing.md` re-headed to
    say so; its deep design (tuple model with stable rids, per-shared-wall greedy match
     over task-4 `edge_src`, band placement, SVG-text paint, settle budget) all stands.
      Await agreement before any build.

Rebuild Stuffing rendering in SVG with graph-native neighbour awareness: rows/tuples
 as SVG text the tessellation itself places, so shared-wall neighbours can EDGE
  TOGETHER — corresponding tuple fields aligning across the wall, matched rows
   gravitating to the shared wall and lining up; a subgraph to compute, involving the
    microcosms of several adjacent (or not) cells.
- This obsoletes the HTML-molding path (tasks 1-2 are still worth doing — they teach
   the geometry and survive as the fallback renderer).
- Requires: a tuple model of Stuffing content (key:value rows), a per-shared-wall
   matching solve (which rows correspond), a placement solve (nudge both sides' row
    order/offsets), then the SVG paint. Do NOT start this as a grind task — write
     `Voro_svg_stuffing.md` (problem, tuple model, solver sketch, budget story) and
      get it agreed first.

## Standing verification loop (every task)

1. Edit; typecheck by grepping `npm run check` output for YOUR line ranges only
    (~3k baseline noise; `cy`-typed-as-void errors are the file-wide disease, ignore).
2. `.g` touched? `npm run ghost-compile -- Ghost/V/Voro.g` with the editor tab open.
3. `node scripts/runner_ask.mjs run VoroMitosis --watch`, then `VoroScape` — green, and
    the diges/fixtures UNCHANGED (a fixture diff = metaphysics §2 violated).
4. Eyes on the tab: drag a node, wheel-zoom, middle-drag pan, click the canvas and
    ←/→ through the pips, run a wave — the Stuffings stay seated and glidy
     throughout; no oscillation at rest.
5. Leave everything uncommitted; the human reviews and commits on the host.
