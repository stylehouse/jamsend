# Voro_todo shift annals, 2026-07-14 → 2026-07-17  (HISTORY)

> **Historicity notice (moved here 2026-07-18).**  This is the PART-by-PART shift archaeology that
>  accumulated in `Voro_todo.md` §0 — PARTs 1–11 (the honesty pass → craters → H/I/J/K rounds →
>   ϕ v1/v2 + the Attractor Ground), the 2026-07-14 live steer block (distiller-bows-to-Stuffing,
>    bamboo v2 = C-spaces, the tuples face), the style-explainer HUD spin-off sketch, and the FIVE
>     WAVES annals.  The LIVING map (current state + next arc + owed) is `Voro_todo.md` §0; the
>      knob/moment/face housing is `Attractor_todo.md`; the render faces ledger is
>       `voro_modes/README.md`.  Everything below is verbatim as it stood, newest first.

**WHAT LANDED THIS SHIFT, PART 11 (2026-07-17) — ϕ v2: the golden lettering re-laid.**  The
 human's steer, verbatim: *"I'm thinking the center of the sunflower is off the screen, and we're
  dealing with a gently curving phi grid, which we assign runs of dots on to chunks of UI we want to
   fit there… 'Artist   name:Vox' wants to be all in a line, Track** is below and indented. there may
    be inefficiencies (gaps) from laying out so… but dragging the Artist phi blobule should still
     move the cyto node for it, and blinklessly stream through the display layers… currently it likes
      to blink after a drag but otherwise very good. so yeah it gets small text too easily. we need
       more confidence about fitting the text, should be able to really max it out."*  Five changes
        to `phi_build` + its render block (render-only — no gen/toc/fixtures):
- **POLE OFF-SCREEN.**  The spiral pole = glass bbox centre displaced `phi.pole_dist` (2.5)
   half-diagonals at `phi.pole_ang` (90 = straight down), so every groove crossing the viewport is a
    gentle near-parallel smile-arc (big r everywhere → tiny angular spans, no tight turns).  Home
     (r,φ) recomputed from the new pole; the upright-flip is now robust (reverse the sampled points if
      the path runs right-to-left, `end.x < start.x`) not the old centred-pole `sin>0`.  The lattice
       draws ONLY the visible annulus × bearing-window (no miles of off-screen path).
- **C-BLOCK LAYOUT.**  A cell claims as ONE block: the TITLE whole on one groove (tag + name
   together, never split), the rest INDENTED below on adjacent grooves on the side that is screen-DOWN
    of the title (computed EMPIRICALLY per bearing — not hardcoded), each indented `phi.indent` (1.5)
     em.  The block is claim-tested WHOLE at each candidate anchor; if it won't seat, retry with fewer
      children (fold the tail into +N), down to title-only, else the cell folds entirely.
- **STABLE IDENTITY = THE BLINK FIX.**  Root cause: arc pathids were minted from a GLOBAL `seq`
   counter, so every rebuild renamed every arc → the keyed-each destroyed+recreated every DOM node
    (the blink).  Now pathids are DETERMINISTIC (`vphi-<cellid>-<slug>`, slug from the label's stable
     cls+key/text + a per-cell dedup counter), and a module `phi_prev` map re-seats each label at its
      previous interval first (if still free) — labels stay put, Svelte patches attrs.  So ϕ now
       rebuilds LIVE under drag (`phi.livedrag`=1; freeze at 0 or >400 labels).
- **DRAG THE BLOBULE.**  The title arc (`vsub-phit`) is a grab handle: `onpointerdown → vsub_grab(e,
   cellid)`, mirroring the pane identity; CSS opts it back into the pointer-events:none ϕ layer with
    `cursor:grab`.  Fact/member arcs stay non-interactive.
- **MAX THE TEXT OUT.**  Sizing INVERTED: fs is the LARGEST that fills the free gap on the groove
   (chars·GLY·fs ≤ gap), capped `phi.fsceil` (26), floored `phi.fsfloor` (9 → smaller FOLDS instead of
    shrinking).  Titles may span TWO grooves (`phi.titlegrooves`) for a ~1.8×pitch cap; children stay
     single-groove (0.92×pitch).  Wgt is now PRIORITY (claim order), no longer the size.  Wes-Wilson
      `stretch()` still fills the final room.
- **Telemetry + docs.**  The ϕ census gained `held`/`moved` (observable, but EXCLUDED from the
   change-signature so a drag frame never floods the log).  Knob table + arc live in `Attractor_todo`.
- **PIXELS STILL OWED.**  Verified svelte-check-clean only (3341/89 unchanged); the live runner is
   engaged elsewhere.  Eyeball: grooves gentle, 'Artist name:Vox' one line + Track indented, NO
    post-drag blink, big bold text with honest folds — not tiny text everywhere.

**WHAT LANDED, PART 10 (2026-07-17) — the Attractor Ground + the zone_seat clip fix.**
 The ▦ layer became a competition ground: rival FACES draw the same live glass, a JUDGE tunes live
  KNOBS and flips between named MOMENTS on the same data.  The design + the full knob table + the op
   rails live in `Attractor_todo.md`; the shape in one line: the harness owns the data/geometry/
    plumbing, a face is just a builder `(cells,descs,knobs)→layers`, faces ADD never REPLACE.
- **`zone_seat` fixed (the 'Artist name:Palego' clip).**  It sized a row against the widest chord in
   a zone but PLACED it on a different, narrower chord → the row overran and the clipPath cut it
    mid-word.  Now SAME-CHORD sizing+placement (seat on the measured chord's own y), SPLIT-DON'T-SHRINK
     (a too-small identity breaks 'Artist' / 'name: Palegold', both big), and EXACT-OR-FOLDED (shrink
      the last atom to 7 then honestly fold — never a clipped glyph).
- **The spell runs under ϕ again.**  Blanking moved from build-time to RENDER-time (the markup gates
   the pane stats, the data survives), so the growth spell reads real sizes and GROWS small cells under
    ϕ too — craters/structure return to the small cells that ϕ used to freeze flat.
- **Crater why-not telemetry.**  The human: *"a couple of Artist lack subcells for their /Track — why is
   that a sometimes maybe kinda deal?"*  `crater_pane` now bumps a per-paint `crater_skips` reason
    (`small|header|geo|nofold`) and rides it on the `vsub` census, so `--why` says exactly why a crater
     didn't draw.

**WHAT LANDED, PART 9 (2026-07-17) — ϕ: the golden lettering layer (face `phi`) + zone_seat
 + gates opened.**  The human's steer, in full: *"I need the lettering positioned much more wonderfully.
  we absolutely must know if we're obscuring a part of the words and adjust to not do that, or simply
   decide we're out of space and increase vagueness (prevalence of click-for-more folds) … cast a phi
    sunflower grid onto the cells, assign continuous spaces across the grids with another bit of
     give+take basically ignoring cell boundaries, then we completely obscure what we have drawn so far
      with this other… labels stretched onto a phi spiral! with connective tissue showing expandy
       regions"* — and the design rationale: *"phi is easy to see kinks in but not overly griddy, we can
        probably communicate pretty well a warping data-landscape."*
- **The ϕ layer (`phi_build`, Cytui ~2090; face value `phi`, flip `--face=vsub:phi`).**  ONE Archimedean
   groove spiral (pitch `PHI_G=17`) over the WHOLE glass, pole at the glass centre.  Every label (built
    per cell from the SAME Vtuffing descs — title/facts/spreads/members, river-hushed claims skipped)
     claims a contiguous groove arc near its home cell: the ledger is **total-spiral-angle intervals**,
      so same-groove collision is an exact interval check, adjacent grooves are fs-capped below the
       pitch → **text can NEVER obscure text, by construction** (the human's "we absolutely must know").
        A label that finds no free arc within its distance budget FOLDS honestly into a `+N` chip at
         its cell — **click the chip = 3× reach budget for that cell** (`phi_expand`/`phi_boost`, the
          "expandy regions").  Displaced labels keep a dashed **tie** home; the faint full-spiral
           **lattice** renders as the flat reference the warps read against.  Text on `<textPath>` with
            the existing Wes-Wilson `stretch()`; arcs in the bottom half flip so words read upright.
- **Under ϕ the panes still build but their stats blank** — walls/craters/tints stay as the
   UNDERPAINTING ("completely obscure what we have drawn so far" = the lettering rides on top,
    unclipped, blind to cell boundaries).  The growth spell is GATED OFF under ϕ (blanked stats would
     read as global starvation → storm).  ϕ census rides the `vsub` vlog (`phi: {labels, placed,
      folded, boosted}`) so `--why` says how many labels landed vs folded.  Frozen mid-drag like the
       spell (a per-frame re-claim would jitter every label).
- **`zone_seat` (Cytui ~1766) — the tuples-face text host REPLACED** (same shift, before the ϕ steer):
   territory-first sizing — the polygon's height divides into weight-proportional zones, each zone's
    text sized to FILL its band (width×height), no flow/wrap/inflate.  Long member lists auto-split
     into groups of 5.  `tuple_pane` + both `crater_pane` seats now ride it; gates opened (crater
      `R<24` was 40, `mem≥1` was 2, degrade `area<900` was √area<88).  ⚠ 'tuples' face is UNSEEN
       live since the swap — if ϕ takes, zone_seat is the fallback face, eyeball it too.
- **Verify:** hard-reload a :9091 tab (see the BOMB below), `runner_shot --arm --face=vsub:phi`, then
   shot + `--why` (the vsub line should say `phi:` with placed≈labels, folded small; click a +N chip
    and the census should shift).  NOT yet live-eyeballed — pixels are the gate, this section is the map.

**WHAT LANDED, PART 8 (2026-07-15) — the K-round: the crater REDRAWN as an explicit nested
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
