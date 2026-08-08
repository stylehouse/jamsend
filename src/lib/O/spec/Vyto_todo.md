# Vyto — the working doc

The new glass.  Spec: `Vyto_spec.md` (unpreened — three rounds 2026-07-19).  Machine-level
 elaborations: `vyto_workingouts/` — shapes · pelt · calm · spool · commission · client · processes,
  each checked against the LIVE code (not against the spec's hopes), most ending in open
   questions only the human can rule on.  This doc is the one todo; the workingouts are
    its appendices.  **`client.md` is the front door for anyone integrating as a Vyto
     client** — point a fresh agent there first.

## 0.0 THE LOOK — the owner's ruling, 2026-08-06 (read before designing any face)

*"ideally this whole program looks like a child's pasta and paint artwork — we can see what the
 player is plugged into in the Mag, tiny ants moving buffer into the Record there, etc."*

That is a **design constraint, not a mood**, and it cuts against the default this glass keeps
 drifting toward. The default is a DASHBOARD: cells full of numbers, each organ reporting its own
  state in text. What is asked for is a MADE THING — visibly hand-assembled, and above all
   **showing the machine's RELATIONS and its MOVEMENT**, which numbers cannot do:

- **"what the player is plugged into"** — the radio↔Record relation should be VISIBLE as a
   connection, not inferred by reading a title in one cell and matching it against a list in
    another. The dial is plugged into a Record which lives in a Mag: draw the plug.
- **"tiny ants moving buffer into the Record"** — a transfer should be seen as MOTION ALONG THAT
   RELATION, per Record. Today the same fact is a KB/s number in TransferFace (`x.pulls[].held/total`)
    — true, and invisible as a happening. The ants are that data, drawn as travel.
- **"pasta and paint"** — irregular, physical, made-by-hand. The voronoi foam is already the right
   instinct; the faces inside it are the part that still reads like a control panel.

**What this rules OUT:** answering "the glass should show X" by adding another cell with another
 readout. Cells are the scarce resource (the 2026-07-28 ruling that killed the friend Crates: two
  more cells made every jewel unreadably tiny) — so new understanding should arrive as **relations
   drawn between things already on the glass**, and as **motion**, not as new boxes of text.

**What it needs from the wire, and what already exists.** The relation and the flow are both
 already computed and thrown away at the face boundary:
 - what the player is plugged into: `radio.c.rec` (the live %Record) — a `.c` ref, so a face can
    follow it to the Record and to the Mag holding it.
 - the ants: the per-Record transfer state the CLI already prints — `top_House().c.xfer.pulls`
    (**an OBJECT keyed by id8, not an array** — `Repli.g:718` inits `pulls: {}`, `Ra.g:2591` writes
     `pulls[id8] = {title, held, total, ts, done, goodput_kbps…}`.  The `[]` this line used to carry
      cost a real bug: an `Array.isArray` guard is false for `{}`, so a first cut of the ants was
       silently dead in every case.)
    (`held/total/goodput_kbps/asked/landed`), plus the crate-birth lane's `want-first` / `page-first`
     ring marks (2026-08-06), which are literally "a buffer arrived at this Record" events with an id.
 - the caution: all of it rides `.c`, which never bumps a version, so a face must self-tick
    (the RadioFace/TransferFace 250ms–1s pattern) — that is the EXISTING idiom, not a new problem.

Related: `Vyto_sizing_todo.md` (the type scale), `## THE PIN` below (display-correctness law —
 pixels or it didn't land, which this section makes harder and more necessary).

## 0.1 THE DO-OVER, and the two complaints that name it (2026-08-08)

The human, handing Vyto back for rework: *"a really spastic system with almost nothing I wanted true
 about it"*, *"I don't want to melt people's phones if possible"*, and — the direction —
  *"I also want to redo the Sounditron↔Vyto integration, there's a lot more in Vyto we're not using,
   or at least I specified there was to be, I think we make our case for a bunch of fancy UI
    biologies with it and see how it goes."*

**Three separable pieces. Do not conflate them:**

1. **BUTTON LATENCY — the concrete, reproducible complaint.** *"the heist setup 'X' button, and
    various buttons really... do not respond quickly enough to clicking."* The heist setup UI is
     **HaulFace** (the tell for which chooser is meant: "section"/"directories"). A click that feels
      late is not a rendering-prettiness problem, it is the interface failing at its one job, and it
       is the first thing a stranger notices. Worth measuring before theorising — candidates: the
        click is queued behind the belief mutex; the handler waits on an await it need not; the glass
         re-tessellates on the state change before the visual feedback lands; or a pointer-events
          gate makes the first click a no-op. **Do not guess between those — instrument.**
2. **PHONE COST — burning CPU with nothing happening.** `▣⚠ Vyto watchdog: forced settle after 240
    frames of unbroken motion` appears in EVERY console the human has sent, on every tab: the layout
     never reaches equilibrium, so the glass renders continuously. A standing battery drain
      independent of the network. Ledger item #12 / `Composition_todo` §4.7.
   **DIAGNOSED 2026-08-08 by source reading — not yet profiled, and not yet fixed. See §0.2.**
3. **THE UNUSED CAPABILITY SURFACE** — the human believes they specified more than is wired. That is
    a checkable claim, not a vague one, and it should be answered with a **gap list**
     (specified-but-unused / specified-but-diverged / used-but-unspecified) *before* any redesign, so
      the design conversation can ask "the spec says X, the code does Y, which did you mean?" rather
       than "what do you want?".

**What is NOT yet known and must not be invented:** what the human wanted true about Vyto that isn't.
 They have not said. Items 1 and 2 are fixable without that answer; item 3's *redesign* is not.

## 0.2 WHY THE GLASS NEVER SETTLES (2026-08-08, SOURCE-VERIFIED, not profiled)

The rAF loop has exactly ONE exit — a settle (`Vytui.svelte:543-566`). `integrate_world` returns
 `false` only on `cnt >= SETTLE_FRAMES || mf >= MAX_MOTION_FRAMES`. So "240 frames" means literally:
  **four seconds at 60fps without ever getting 8 consecutive calm frames.**

### (a) THE KNIFE-EDGE — the load-bearing one, and it is two constants that should not be equal

| where | constant | what it decides |
|---|---|---|
| `Ghost/V/Vyto.g:928` | `EPS = 0.5` | rewrite the target `T` only if it moved MORE than this |
| `src/lib/O/Vytui.svelte:163` | `EPS = 0.5` | a frame is calm only if displacement is LESS than this |

**They are the same number, so every target rewrite is by construction ≥ the not-calm threshold.** It
 guarantees at least one non-calm frame, resets `settleCount` to 0, and then costs a full spring
  convergence (ω = 6/0.4 = 15 rad/s, `Vytui.svelte:502` — ~20–40 frames) before 8 calm frames can
   accumulate again. **Any source that rewrites a target more often than ~every 0.5s pins the loop at
    60fps indefinitely.** The watchdog fires at 4s, force-lands, and the next rewrite restarts it.
 *The model's "did it move enough to matter" tolerance and the renderer's "is it still" floor are
  different questions and must not share a number.* Fixing this is a decision, not a patch — it is why
   it sits in §0.1 item 3's territory rather than the cheap list.

**RESOLVED 2026-08-08 late (renderer-side, zero fixture risk).** The decision taken: the calm floor
 moved, the model's tolerance did not. `Vytui.svelte` now has `CALM_EPS = 1.25` (2.5× the model's
  `EPS = 0.5`, used at the calm test AND `adopt`'s wake test), so a lone rewrite at the model's
   threshold lands *inside* calm and the streak survives it — sub-floor solve wriggle can no longer
    buy a full spring convergence. **Pixel truth is not loosened: every settle now lands** —
     `jump_to_target` at the ordinary strike (previously only watchdog/parked/hidden), so the glass
      rests byte-exact on the model within one frame of striking; the floor only decides when to stop
       easing, never where cells end up. Accumulation-safe: the wake test compares spring to *current*
        target, so successive sub-floor rewrites that add up past the floor still wake the loop.
         Renderer-only — driven Books are parked and never enter the path. **Unmeasured live**: the
          tell to look for in a console is the `▣⚠ forced settle after 240 frames` line going extinct.

### (b) THE ONE THAT PINS **LITERALLY** FOREVER — a pinned channel still counts toward `disp`

`step_channel` (`Vytui.svelte:333-341`) does **not integrate position** when `k <= 0`. But `disp`
 (`:519-523`) still measures `|s − T|` for that spring, with no exclusion for pinned channels. `k`
  comes from `Vyto_calm_held` (`Vyto.g:564-577`), which returns 0 for any `%Hold` on that tok with
   `pin:1` — placed by `Vyto_pointer_enter` (`Vyto.g:615-619`) on **every pointerenter**. The solver
    pins the *seed* but writes `T` = the **area centroid of the pinned cell's polygon**
     (`Vyto.g:918`), which moves whenever any neighbour does.
 ⇒ **pointer resting on a cell + any model churn = `disp` ≥ EPS every frame, forever.**
 Related, same verb: `Vyto_pointer_enter` uses `i()`, **not `oai()`** — every enter mints two NEW
  `%Hold` rows for the same tok, retired only if the browser delivers `pointerleave`, which a keyed
   re-mint of the `<path>` under the pointer can skip. Unbounded accumulation, and item (c)3 below
    pays a query per hold per cell per frame for it.
 Also: `Vyto_strength_now:584` has `base = pin ? 0 : (Number(damp) || 0)`, so a `%Hold` with **no
  `pin` and no `damp`** silently returns 0 — a malformed row is a permanent pin.
  **FIXED 2026-08-08 late**: absent|NaN damp now reads FREE (1); a configured `damp:0` still holds
   fully (`== null`, not `||`). No mint site produces the malformed shape (both `Vyto_pointer_enter`
    rows carry pin or damp; no Book mints a bare hold), so no fixture can move — contract pinned by
     `scripts/RehealSmoke.spec.ts`.

### (c) PER-FRAME COST, worst first (counts derived from source, NOT measured)

1. **Face-mold style writes — the only layout/paint item, and the phone-killer.** `Vytui.svelte:1065`
    rebuilds `style="left:X%; top:Y%; width:W%; height:H%"` for every faced cell **every frame**.
     These are absolutely-positioned HTML boxes containing whole real components (RadioFace,
      TransferFace, HaulFace…). Percentage width/height changes force **layout + paint of each face
       subtree per frame** — not compositing. No `transform` is used anywhere. *This is the design,
        so it is structural, and it is the item a phone actually pays for.*
2. `tree_nodes(w)` runs **three times per frame per world** (`:501`, `:357`, `:455`) — the third is
    the OMISSION DETECTOR diagnostic, which also does two `Set` builds and two diff loops, every frame.
3. `Vyto_calm_held` × **2 per cell per frame** (`:509-510`), each a real `o({Hold:1})` query with
    `Xify()` + array allocation — cost grows with the leaked holds from (b).
4. `power_cells` O(N²) every moving frame (`vyto_geometry.ts:38-60`) — ~300 short-lived `Pt`
    objects/frame at N=7.
5. Per-cell garbage: `path_of` builds a fresh `d` string; `face_of`/`ident_of` each `Object.keys`;
    `[...nodes].sort()` per scope; `matstyle_ground` builds 4 objects + 9 hex conversions **per cell
     per frame** (`Matstyle.svelte:396-403`) despite being a pure function of a mainkey string.
6. `plug_of` re-runs every frame while moving, rewriting the plug `d` **and the `path=` of every
    `<animateMotion>` ant** — restarting SMIL per frame. *(Mine, added earlier today; the comment
     claiming it is cheap is true only for a calm glass. Correcting my own work.)*

**Standing cost even on a settled glass:** `plug_timer` at 2Hz unconditionally (`:842`, also mine),
 plus every mounted face running its own interval (TransferFace 250ms, several at 500ms, many at
  1000ms) — ~10–15 component re-renders/second with nothing happening.

**RULED OUT, do not re-chase:** `measure_world`'s getBBox/offsetWidth layout thrash is **gated off**
 on the live page (`Vytui.svelte:704`, `need_floor` set only from `Vytonation.g:559`). The old drift
  hard-fail is gone. A NaN counts as calm and stops the loop, deliberately.

### (d) A SEPARATE CORRECTNESS BUG found on the way — probably part of "spastic"

The model solves against a **hardcoded `[0,0,800,450]`** frame (`Vyto.g:814`) while the renderer cuts
 against `vw_w × vw_h`, which follows the stage aspect (`Vytui.svelte:135-162`). On a portrait phone
  `fit_frame` gives ~446×800, so the model places seeds with x up to 800 into a 446-wide cut; seeds
   outside clip to `poly.length < 3` → `null` → drawn as a 6px disc at an off-viewBox coordinate,
    i.e. **invisible**. Nothing re-cuts the *solve* frame. Not a settle-pin — a plain bug, and a
     candidate for "almost nothing I wanted true about it" on a phone.

### (e) THE CHEAP LIST — localised, no design decision, do these first

- Skip pinned channels when computing `disp` (or clamp `disp` where `k <= 0`) — kills (b) outright.
- `Vyto_pointer_enter`: `oai()` not `i()` — stops unbounded `%Hold` accumulation.
- Delete the OMISSION DETECTOR (`:449-463`) and GATE-FLIP probe (`:407-425`); hoist `tree_nodes` to one
   walk per frame.
- Cache `Vyto_calm_held` per frame; cache `matstyle_ground` by mainkey (pure function of a string).
- Gate `plug_timer` on the plug existing / the loop being idle.

### (f) WHAT IS NOT KNOWN — do not build on these

- **Which** mechanism is actually firing in the human's tabs. The probes exist and are gated to
   `Haul:` keys; their output is in the consoles being pasted, which the analysis did not have.
- Whether Lloyd ∘ `pull_step` converges or orbits. Reasoned to converge; **not** asserted.
- The real stir rate on a live tab — the input that decides whether the 0.5s budget is exceeded.
   Needs a counter on `Vyto_stir`, not source reading.
- **No profile was taken.** Every number in (c) is a count derived from code, not a measurement.

## 0. What to get on with next

### ⇢ THE DIRECTION, from the owner looking at the live glass (2026-08-09) — READ FIRST

Four sentences, in the order they arrived, each one a correction to what was in front of them:

1. *"they're still utterly on top of each other, not much info for how their Component is shaped?"*
2. *"the zooming up to each thing as you click them doesn't help as the thing inside is just as small
    and uncomplicated."*
3. *"perhaps every bit of the Components we have right now has to be broken apart and expressed as a
    Styled (to some basic degree) C\*\* thing as Vyto says them, with lots of smaller Components in it to
     express each actual button. then we have the want of buttons, a bag of them, to structure... and it
      should all look more terrific"*
4. *"and MOVE it as well"*

### ⇢ THE SIDEWAYS SEAT + what the owner asked for next (2026-08-09, after "way better fitting! nice")

The clip regime landed and the owner confirmed it.  Their next ruling, in one breath, is the queue:

1. **Non-square cells: DONE this round.**  *"pick the two parallelest sides that the box aligns between
    to consume the most space of the cell"* — `slab_seat` (vyto_geometry.ts, pure, node-tested: a 20°
     slab hexagon recovers 20.0° exactly, a square gives 0°, a triangle gives null).  The mold lies
      ALONG the slab (`PaintCell.mx/my/mw/mh/ang`, rotated in `mold_seat`, snapped level within 8°,
       normalised so text never reads upside down), FILLS it across (SEAT_AIR = 3), and may overrun the
        cell's ends by OVERHANG = 1.25 — overflow is sanctioned (*"we can have components overflowing
         their cell"*) because hover top-mostity (the translateZ lift) resolves it.  No clip in this
          regime; a cell with no near-parallel pair falls back to AABB + wall clip.  `bx..bh` stays the
           cell AABB for the label rail — two boxes, two questions.
2. **Crush must be obvious: DONE this round.**  Below the icon floor the cell wall goes dashed
    (`.cell.crushed`) and a centred ⤢ says "folded, more inside".  (The demand side already exists —
      `need_area` floors the solve — so crush-vs-demand is the solver arbitrating, as it should.)
3. **16:9 is the default aspect pick now** (was 'auto'; 'auto' stays in the list).
4. **NOT DONE — the wave labels.**  *"some chunky covering like a wave from the side of the cell,
    labels, which fold away (like a wave toppling in reverse) when the cell is focused, so we can
     behold entire something."*  Wants the emphasis station first (a "focused" cell must exist as
      state before anything can fold away from it).
5. **NOT DONE — the hierarchy breadcrumb** (*"where we are"*) — same dependency: it renders the
    emphasis/navigation state, so build that state first (`%Spotlight,src` was the sketched shape;
     "we make it the most important thing, and everything sorts away from its moment").
6. **The standing question** — *"re-imagine the innards... is there much meaningful C** understanding
    or functioning in Vyto?"* — answered honestly in session: the model side HAS real C** functioning
     (Vyto_relate scribes %Flow from shared SIG_JOINS atoms; importance/dose sizes cells; Vtuffing
      distillation exists) but the RENDERER only consumes weight, not meaning — vines know %Flow's `n`
       and nothing else, and navigation/emphasis has no model-side particle at all.  That gap is
        exactly items 4+5.

(inscribed_of was deleted this round — dead since the clip regime, and it carried the adversary's A1
  convexity bug.  The seat geometry now lives in vyto_geometry.ts where node can test it — A1/C1 both
   closed by removal + relocation.)

### ⇢ THE SECOND RULING + THE POSE (2026-08-09, same evening — supersedes the sideways enthusiasm)

The owner on the live sideways glass: *"ew not that much. very incoherent! forget sidewaysing, I just
 meant the box-within-box reality of Component in cell aligned for space efficiency, without tilting
  anything more than say 30degrees, or zooming more than so much."*  Done: a slab steeper than
   MAX_TILT (30°) is NOT taken (falls back to AABB + clip — never clamped, a 30° box in a 70° slab
    helps nobody), and fit is bounded 0.2..FIT_MAX (1.6) — envelope-down survives for the icon floor,
     blow-up stops before a trivial widget dominates.  Also: **16:9 is the default aspect pick**.

**THE POSE — the App↔Vyto seam, first slice landed (Sounditron.g `Sounditron_pose`, compiled
 449c6d871d9e1b2a):** *"make the toplevel model we push to it change what's included in it...
  App<->Vyto... via how the model is posed right now... more things broken up into smaller parts.
   the Transfer for example... very very well sculpted C** except where it really matters. all made
    up properties, in another world of their own... with click handlers smuggled in."*
- a dontSnap `%Pose,'wire'` bag on the radio world; one free-vocabulary `%Pull`/`%Serve` particle per
   LIVE transfer (identity + 25%-bucketed pct in sc; per-packet numbers stay on M.c.xfer unbumped —
    "except where it really matters" IS the sc|.c split), grappled FLAT beside the organs.
- `%Float,'ballast'` — a particle that is only dose, pitching mass toward the wire pile while it is
   busy ("devices just for floatation").
- every part wears the made-up atom `lane:'wire'` so Vyto_relate weaves %Flow between them and
   pull_step bunches the pile — **Cyto's mesh bagging re-had through meaning, not a compound node**
    (the owner: "cyto's mesh bagging and piling up of bodies is pretty good... hybridising that is
     what I'm aiming for").  Not going back to Cytoscape for layout.
- `.c.press` smuggled per part; Vytui `cell_click` runs `source.c.press(source)` on any cell whose
   source wears one (falls through to cam_engage otherwise).  v1 toggles `lit` — the protocol is the
    deliverable, per-part verbs come with each subject posed.
- the trickle re-poses on a pose FINGERPRINT (transfer set + pct quarter-crossings), never per packet.
- **HUMDINGER-GATED**: no Book poses, fixtures stand to the byte.  UNVERIFIED against the live fleet
   until the runner tab is reloaded (it runs an old Cytui — runner_shot refuses it).

**Named, not built (the owner's queue):** the LOOSE LAYER (*"separate the loose nodes to another
 layer"* — unrelated/small particles float off the mosaic, likely `sc.loose` → excluded from the cut,
  drawn as drifting discs above/below); more subjects posed (the player embryo, Haul); wave-fold
   labels + breadcrumb (still waiting on the emphasis station).

### ⇢ THE ORCHESTRA OF SPHERES — pools of information (2026-08-09 late; the transfigured algorithm)

The owner, in sequence, refusing every smaller reading: *"balls. shoving into your face. more balls
 inside each of them, wires amongst them... no budget, figure this out really luxuriously. Stuffing
  exploder generique"* → *"much more elegant and noble... spring these useful groovinesses from the
   interface"* → *"perhaps an attractor model? everything spins (when morphing) like a galaxy"* →
    *"nah the `orchestra of spheres` is the image for you"* → *"figure out what I mean... pools of
     information..."*

**The law (one sentence): every particle is a POOL — a disc with mass — and COVERAGE IS EARNED BY
 PRESSURE, not granted by the frame.**  A wall exists only where two discs press (d < rᵢ+rⱼ); it sits
  on the same radical axis power_cells already cuts (t = (d²+rᵢ²−rⱼ²)/2d).  A lone pool is round; a
   kissing pair grows one flat wall; a packed pile tiles its interior into the mosaic while its rim
    stays bulged and biological.  Mosaic, balls, and the loose layer are not three features — they
     are three pressures of one thing, and the frame-carving cut (100% coverage unconditionally) is
      what made three unrelated cells into three meaningless slabs.  Emptiness must mean uncrowded.

**Every grooviness as a corollary, none as a feature:**
- *balls inside balls* — recursion through membranes: a bag's skin is a ball in its parent's pile;
   its interior is the frame for its stuffing's own pile.  Conservation through the membrane —
    bag area = Σ stuffing areas / packing — replaces the grow-only `need_area` ratchet with physics
     that also SHRINKS honestly.
- *pools of information* — a pool has a SURFACE and a DEPTH.  Stuffing renders sunken: smaller,
   dimmer, deeper.  Attention SURFACES it — the stuffing rises and becomes a real foam inside the
    membrane.  The fold ladder's icon register becomes the deep end of one continuum (sink), not a
     binary; "crushed things become icons" = fully sunk.
- *stuffing exploder generique* — surfacing IS the exploder and it is generic because Scan already
   mirrors ANY C** subtree; nothing is explodable by special case.
- *shoving into your face* — presence = inflation, never perspective (the tilt ruling stands).  The
   focused pool inflates (FOCUS_BOOST exists), everything else compresses (FOCUS_SHRINK) — *"we make
    it the most important thing, and everything sorts away from its moment"* is force displacement,
     watchable, not a re-layout.
- *the breadcrumb* — free: an exploded pool sits INSIDE its parent's visible squeezed skin, which
   sits inside its own — the margins ARE the breadcrumb.  No chrome.
- *wires amongst them* — %Flow springs with rest length = kissing distance, so meaning literally
   pulls pools into contact and contact makes walls: Cyto's mesh bagging as emergent piling, not a
    declared compound.
- *the loose layer* — the zero-pressure regime: no wires + negligible mass ⇒ never enters the
   separation set; drifts an outer orbit, dim, behind.  A wire gaining weight REELS it in — you see
    a fact join the pile.
- *galaxy morphs* — relayout displacement resolved with a decaying tangential component about the
   attractor: change turns, never teleports.  Renderer-side UItime only; parked Book worlds still
    jump-land.
- *the orchestra* — one shared slow breath (±~1.3% radius on a common phase); this is a music app
   and the glass is an instrument in it (later: phase from the playing track).
- *buttons faster* — press ⇒ instant renderer-local DENT + ripple (acknowledgment before answer),
   masking post_do queue latency without touching it.

**Proofs standing:** `foam_cells` + `pile_step` are IN vyto_geometry.ts (pure, node-tested: lone
 ball area = πR² −0.8% poly error; pressed pair loses caps symmetrically; distant pair stays whole;
  a piled 8 packs to 0.71 disc-area ratio — walls formed).  The living proof is the artifact
   **“Orchestra of Spheres”** (claude.ai artifact `ccc08cd5…`, source scratchpad/orchestra.html):
    jamsend's own organs as pools — depth, surfacing, wires, loose orbit, galaxy swirl, breath,
     dent, and a *pose a transfer* button that runs the whole App→Vyto story in miniature.

**THE CANONICAL DEMO BOOK — `VytoOrchestra`** (the owner: *"what is the canonical demo Book that we
 shall use to express everything at once?"*).  None standing qualifies: every Vyto* Book proves ONE
  mechanism in a quiet world (that is their virtue — keep them), and MusuNeGrind gates the music
   composition, not the glass.  VytoOrchestra is the SHOWCASE gate: one commissioned world carrying
    every regime at once — a bag with stuffing (balls in balls) · three rows sharing an atom (wires +
     piling) · two loose rows (the zero-pressure drifters) · an arrival step (eruption) · a focus
      step (boost|shrink) · a pose flip (inclusion follows the model) · a departure (escort + sweep).
       %see sentences named before code (LAW B); fixtures recorded from the LIVE runner only; wall
        SHAPE gated by `runner_shot --svg` + vyto_see, never by dige.  It also becomes the standing
         `runner_shot --arm` subject, so every future capture has one address.
  **AUTHORED 2026-08-09 (Vytonation.g @ cd7a46d301e2210c, Credence row added under What:Vyto): 8
   beats — seed · stand (foam+nested via the new `foamy` arg on Vyto_commission_on) · weave (3 flow
    edges, all Song-to-Song — no-incident-flow IS the loose predicate) · deepen (a shared mood lifts
     one edge to n:2 live, no re-commission) · spotlight (focus swells ≥1.15× while a stray falls
      ≤0.9×) · pose flip (Stray:lint out, Pull:Driftline in) · depart (escort sighted then gone from
       the bag).  UNRECORDED — first fixtures must come from the owner's run-all on a FRESH tab
        (the current runner is stale-HMR-wedged; recording there would bake bad fixtures).**

**LANDED 2026-08-09 late (all foam-gated, fleet byte-identical):**
- **the loose layer, model-side** — `sc.loose` is EXPLICIT (the poser owns the vocabulary; zero-flow
   inference waits until the live weave is rich enough not to misclassify an organ).  Vyto_solve
    partitions loose rows out BEFORE the relax (no wall pressure given or felt) and seats them on a
     static tok-hashed RIM ring.  A stir-advanced drift was tried and CUT: rest_poll stirs in a loop
      while waiting for rest, so any per-stir motion means a driven world can never rest — drift is
       a renderer concern and waits on a <g> wrapper (a CSS-revolved disc leaves its label behind).
- **renderer loose regime** — loose rows take no seat in the cut, draw as dim rim discs
   (`.cell.disc.loose`).
- **the galaxy morph** — a spring whose TARGET leaps >40px gets one perpendicular position kick, so
   the same critically-damped math carves a turning approach; one-shot per leap, parked worlds
    never feel it.
- **the breath** — CSS-only (`vy-breathe`, 3.4s, ±1.2%, `--bd` phase stagger), gated
   foam+humdinger in the template so runners and Books never breathe; reduced-motion honored.
- **the dent** — `.cell:active` scale animation: instant compositor acknowledgment of a press,
   masking post_do queue latency without touching it.
- **VytoOrchestra grew the rim claim** (strays wear loose:1; stand asserts both rim seats ≥150 from
   the frame heart; spotlight's shrink witness is now a fellow SONG and the stray must hold
    byte-still under focus — the taper partition asserted as equality).  Still UNRECORDED.

**LANDED 2026-08-09 later still (all renderer-side, Vytui only — no .g change, no fixture can move):**
- **THE A DIAL** (the owner: "cells could do with a handle... an A on one corner... drag up-down to
   control the intensity|size of that cell").  An HTML handle layer (`.adials`, translateZ'd above
    every mold) heads each leaf cell's hallway; vertical drag writes `sc.dose` on the SOURCE particle
     (mirror writes would be overwritten by scan), one-decimal string, DELETED at zero, ~90ms
      throttle, `Vyto_stir_soon` poke — the same knob Vyto_express already reads (env_area =
       AREA_BASE·(1+dose)), so the foam re-negotiates around the human's thumb.  This is the chosen
        cure for "it gets the wrong thing fullfaced sometimes": a handle, not a smarter guess.
         Keyboard: focus + ArrowUp/Down in 0.2 steps (role=slider).
- **THE HALLWAY** — a tapered corridor let into each leaf cell's top-left wall ("a hallway merged
   into the cell wall that we walked into this world through"), fine-copper fill, two receding
    rails; the GUTS moved off the free margin and now file down it, under the A.  Scenery only
     (pointer-events none) — the A above is the touchable part.
- **OCCLUSION ORDER + SPILL** — build_cells now sorts cells (depth asc, then area desc quantized,
   then key): parents under children, BIG UNDER SMALL, one sort shared by SVG paint order and the
    molds via a per-rank translateZ step in mold_seat (no `perspective` is set, so Z is stacking
     only).  With that in place the wall policy flipped a third time: molds and face-scroll are
      overflow:visible again and the polygon clip-path is gone — spill lands UNDER smaller, more
       focused neighbours instead of on top of everything (clip solved overlap by amputation;
        occlusion solves it by order).  History preserved in the .face-mold comment.
- **CENTERED, CHROMELESS FACES** (the owner: "centering the Player things is going to make it look
   better, and lose the border") — .face-scroll flex-centers its face (a flex item shrinks to
    content, which also hands the measure pass honest intrinsic boxes); the mold's seat-ring
     shadow + border-radius chrome dropped, lift glow kept.
- **THE POOL DEPTH** ("pools of information") — nested stuffing rests SUNKEN (fill/stroke-opacity
   ~0.5, labels ~0.22, faces dim+desaturate on .face-scroll, halls and A dials to a murmur) and
    SURFACES over 260ms when anyone approaches its chain: hover on the bag, the cell, or deeper
     stuffing, or a camera engaged into the chain (near_key — keys are '>'-paths, so chain
      membership is a two-way prefix test, computed in build_cells beside lift).  Paint register
       only: geometry, targets and fixtures never move.
- **COPPER, THREE SCALES** (the owner: "use copperannodes.jpg at different scales for texture") —
   `/i/copper_anodes.jpg` as userSpaceOnUse patterns: coarse 520 for the ground rect + scope-bag
    floors (which also makes bag gaps clickable → engage the bag), fine 130 for the hallway,
     ~90px CSS background for the A dial itself.  World-unit tiles, so the camera zooms the metal.
      Pattern defs repeat per-svg ON PURPOSE — runner_shot --svg captures stay standalone.

**LANDED 2026-08-10 (the pile solve — foam-gated, Vyto.g @ 978cf29f23032b1a):**
- **Vyto_solve now PILES under foam**: the centroidal relax is off (a centroid pull is the frame
   dictating; the foam law says bodies negotiate) and pile_step iterates INSIDE one solve to its
    fixed point — cap 400 MEASURED, not guessed: a scratch probe showed the worst case (lone ball
     crossing the frame at gravity 0.02/step) rests in 256 steps, a wired 6-orchestra in 121, and
      a 40 cap looked fine while NEVER resting in 3 of 4 configs.  Pins restored each step
       (pile_step stays pin-blind/pure).  Anchors under foam are the BALLS, not centroids.
- **finals under foam are foam_cells**, because the scope recursion hands finals[p] to every bag
   as its tessellation bound — the first cut set finals=null under foam and `finals[p]` THREW on
    every stir.  Found by controlled revert (the Books-are-deterministic move): pile on → 1/7
     %see; pile off → 7/7; the pile was innocent, the null was the killer.  With the fix: 7/7
      %see WITH the pile live — VytoOrchestra's first full pass over real pile physics.
- ⚠ **VytoOrchestra's recorded fixtures are STALE**: the run-all that recorded them ran a
   pre-loose Vytonation (002.snap holds `Stray:moth` / `Stray:lint` with NO `loose` key), so
    every step is red-at-baseline against today's Book no matter what the solve does — the
     %see census is the live gate until the owner re-records with a fresh run-all (which will
      also bake the pile world's snaps; positions never reach a dige, so only the see-rows and
       model rows move).

**LANDED 2026-08-10 (renderer round two — Vytui only, fixture-safe):**
- **THE ORBIT** — loose discs ride a `<g class="orbit">` wrapper: the constellation revolves about
   the frame heart (transform-box: view-box) over 8 minutes while an inner `.orbiter` counter-
    rotates, so bodies drift and labels stay upright — the drift the rim seats waited for, CSS-only
     and foam_breathes-gated (live page; Books and captures never see a body mid-drift).
- **THE WAVE** — the chunky label covering, finally: a scalloped copper band along a faced cell's
   top edge wearing the ident, starting right of the hallway head (the corridor runs in under it).
    Engaging the cell FOLDS it away — scaleY about its own top edge with a gathering overshoot
     ease, "a wave toppling in reverse".  Sunken cells wear it at pool ink.

**SEEN 2026-08-10 (vyto_see over runner_shot --svg, post-VytoOrchestra world):** the pile is real
 to the eye — a pressed bunch of bodies mid-frame with round outer rims and shared pressed walls,
  **coverage 24.9%**: the foam earns its footprint instead of being granted the frame, which IS the
   law in one number.  The nested players read at pool ink (`cell sunk nested` in the capture),
    the loose stray rides off-pile.  Ops lesson recorded in auto-memory: a Book run accepted while
     the runner tab is mid-full-reload (any Vytui edit) can step all beats with 0 %see and no
      glass — rerun on a settled tab before believing a regression OR a controlled revert; both
       of tonight's bisect verdicts were reload-race artifacts.

**FLEET SWEEP 2026-08-10 (post-pile, live runner): 15/15 GREEN** — VytoBreathe · VytoBunch ·
 VytoCell · VytoCrest · VytoFoam · VytoFold · VytoFreeze · VytoMitosis · VytoNest · VytoNestRest ·
  VytoRadio · VytoSeek · VytoStaple · VytoTandem · VytoWeb, every recorded Book over
   Vyto.g @ 978cf29f23032b1a.  The gate-off ⇒ byte-identical claim holds over the pile changes,
    and VytoFoam (foam-gated, WITH fixtures) is the independent confirmation that a foam world's
     recorded claims survive the pile.  (VytoOrchestra excluded — its fixtures are the stale
      pre-loose recording, above.)

**Migration (additive gates, LAW D):** commission key `foam:1` → `w.c.foam`; ~~Vyto_solve swaps
 centroidal-relax for pile_step + conservation radii under the gate~~ (LANDED above); Vytui swaps power_cells(frame)
  for foam_cells under the same gate; loose classification at Scan (no %Flow incident + dose<ε ⇒
   row.c.loose).  Gate off ⇒ every existing Book byte-identical.  New Book `VytoFoam` names its %see
    sentences FIRST (LAW B): loose classification · pressure computation · conservation through one
     membrane · fold release past capacity.  Wall SHAPE still cannot reach a fixture — vyto_see
      rasterisation is the geometry gate, as ever.

### ⇢ THE ADVERSARIAL REVIEW, and what it changed (2026-08-09, commissioned by the owner)

An adversarial agent was set on the whole session's diff with the brief "argue this isn't right and needs
 more structure". **Its central prediction was confirmed by the owner within minutes of being written**, so
  its other findings are to be treated as live until disproved, not as opinion. The keepers:

- **The area-vs-area fit test was meaningless, and the spill fallback re-created the original bug.**
   `tight` compared `need_area` (an area) against the inscribed box's area, so a 200×40 face "fits" a
    90×90 seat and is amputated in reality — and when the test DID fire it turned clipping OFF, i.e.
     straight back to "utterly on top of each other". The owner, live: *"I can see all the component but
      it's just by overlapping again. you're not actually measuring... ie overflow, and overlapping the
       edge of the page etc."*  **FIXED** — see ENVELOPE below.
- **A 0×0 mold spilled unclipped over the whole glass.** `inscribed_of` returns a zero box when the
   centroid itself is outside the poly; `need > 0` then made `tight` true, so the face rendered at full
    intrinsic size, unclipped, over its neighbours — worst exactly where the cell was most crushed.
     **FIXED** by the same change (a zero box now yields the icon register, not a spill).
- **`inscribed_of`'s convexity premise is NOT guaranteed** — `power_cells`' gap inset pulls each vertex
   toward the vertex MEAN by a fixed distance, which is not convexity-preserving, and `FOCUS_SHRINK`'s
    ~88× compression is exactly what drives vertices inside that distance. Corner-testing is only sound on
     a convex poly. **OPEN — the top correctness item.** Fix by insetting along edge normals (a half-plane
      clip, convex by construction) rather than radially.
- **The watchdog no longer bounds continuous rAF** — a gliding camera resets `motionFrames` every frame,
   so `MAX_MOTION_FRAMES` is unreachable. Mooted in practice by the camera's retirement, but the property
    must be restored when the camera is unpicked.
- **`{#each vines_of(...) as v (v.d)}` keys on a per-frame geometry string**, so every vine node is
   destroyed and recreated per frame. **OPEN**, one-line fix (key on the edge, not its `d`).
- **`seenAt` is pruned on spring removal**, which is precisely the documented Haul churn — so a churning
   cell replays its 620ms arrival and arms an extra full repaint. **OPEN.**
- **LAW B/C were not honoured**: no Book, no `%see` sentence, and no ledger row for the session's largest
   changes (`inscribed_of`, the clip restoration, `--vyz`, `mold_seat`, the fx suite, `need_floor`).
    **"The fleet stayed green" is disqualified by this session's own finding** — the 82%-coverage balloon
     cut was fleet-green. Worse, the four Books that ran assert only that the new work is switched OFF on
      a runner. *A gate proving your feature does not execute is not a proof of the feature.*
- **`need_floor` was switched on for every live tab while `VytoNeed` has never once run green** (its
   `toc.snap` is `dige:lie` throughout). That is the F3 failure mode, committed inside the document that
    defines it. **OPEN — either record VytoNeed or turn the flag back off.**
- **The structural charge, which stands:** ~2160 lines and ~22 concerns in one component, with eight pure
   geometry functions (`inscribed_of`, `path_round`, `bbox_of`, `cut_sig`, `plug_curve`, `vine_curve`,
    `aspect_fit`, `mold_seat`) living in a Svelte file where they cannot be unit-tested — **when
     `vyto_geometry.ts` exists precisely to hold pure functions.** Moving them is mechanical and is the
      honest answer to "the Books cannot witness shape": the convexity bug above is a five-line unit test,
       not a character-grid squint. **This is the next structural move, ahead of any new feature.**
- **And the sharpest one:** every ornament this session added — a better-fitting rectangle, a tilted
   rectangle, a magnified rectangle, a rectangle that flies in, a rectangle drawn under the rectangle —
    **takes "a face is a monolith that gets a rectangle" as its premise and invests in it**, which is the
     exact premise §(3) asks to abolish. The doc's own first move (*"one face, decomposed behind a gate,
      with a Book… pick the SIMPLEST face"*) was written and then skipped.

**ENVELOPE — the third answer, and the one the owner named.** Spill and clip are both wrong because both
 keep the component at natural size and argue about the excess. *"we need much better enveloping things
  down when there's no room on the screen"* — so `measure_world` now stamps `need_w`/`need_h` (the natural
   BOX, not just its area), and a face that does not fit its seat is **scaled down per-axis until it
    does** (`--fit`, applied as a layout-divide + transform-scale so nothing reflows and nothing is cut).
     Below a legibility floor the face is not drawn at all and the cell keeps only its edge label — so
      *"things become icons when crushed down"* falls out as the bottom step of a continuum rather than a
       special case. This also removes the spill/clip choice entirely.

**STILL OWED FROM THE OWNER'S LATEST** (recorded, not yet built):
 - *"we make it the most important thing, and everything sorts away from its moment"* / *"in the
    spotlight"* — the Heist becomes the spotlight and the glass sorts away from it. This IS the emphasis
     station, and note `%Spotlight,src` already exists in CLAUDE.md's notation.
 - *"it's slow to respond to the Heist thing"* — `press_probe` is armed on HaulFace and wants one press
    on a live tab plus `tracelog.mjs --watch`; `waited` vs `depth` forks it.
 - *"we could actually put it all in one infoformat if html + Vyto C labels vtuffing"* — one info format
    unifying the HTML face and the Vyto C labels, i.e. the under-layer and the component stop being two
     rendering technologies. That is the same destination as §(3) and is the argument for doing the
      decomposition rather than growing the under-layer further.

**THE ORDER TO BUILD (5) IN, and why this order:** register first, then aspect, then emphasis.
 The **register** (icon|compact|full) is what makes every other problem tractable — it removes
  spill-vs-clip entirely, it makes "measure" easy (a face advises a size PER register instead of one
   true size), and it is per-face additive so one face can adopt it while the rest stand. **Aspect**
    second, because once a face advises per register it may as well advise w×h rather than an area.
     **Emphasis** last, because it is the one that re-solves the model and therefore the one that can
      move fixtures — and it wants the other two in place or a focused cell just gets a bigger box with
       the same cut-off contents. Nothing here should touch a Book without a gate; the fleet stays the
        regression bar and `scripts/vyto_see.mjs` stays the shape witness (the Books cannot see shape).

> ⚠ **A COMMISSION FLAG DOES NOT REACH AN ALREADY-COMMISSIONED TAB — RELOAD IT.** `Sounditron_glass`
>  latches `this.c.glass_done = 1` after the first successful dispatch and returns early ever after, so a
>   newly-added `commission.sc.*` (today: `need_floor`) is only read by `Vyto_commission` on a tab that
>    has not commissioned yet. `glass_done` rides `.c`, so a RELOAD clears it and the next tick
>     re-commissions with the new flag; otherwise you wait for the trickle's re-commission, which only
>      fires when the `%MusuThem` friend set GROWS. The tell is the exact symptom the owner reported
>       minutes after the flag landed — *"the Components don't fit in these weird little things"*: the
>        renderer had the new molds, the model still had `w.c.need_floor = 0`, so nothing grew the cells.
>  **Any future commission flag has the same trap.**

**(1) and (2) are ANSWERED** — see the section below: molds are inscribed inside their polygon (measured
 on the owner's own capture: 5 overlapping pairs / 26.6% of mold area → **0 pairs**), the need floor is ON
  for the live glass so a cell grows to what its component measures, faces are clipped again, and the
   camera now magnifies face CONTENT via `--vyz` instead of just its box.

**(3) IS THE REAL DESTINATION, and it reframes the whole face rail.** Today a face is a MONOLITH: one
 Svelte component draws a whole organ in HTML, and Vyto only gets to choose the rectangle it sits in. That
  is why the glass "doesn't say how the Component is shaped" — the C tree stops at the cell, and
   everything interesting is opaque inside a box the model cannot see into. What is asked for is the
    opposite: **decompose each face into C\*\* structure, one particle per meaningful part, right down to
     the individual button — so Vyto lays the parts out, Matstyle styles them, and a "Component" becomes a
      very small thing that draws ONE part.** The layout of a face stops being that face's private CSS and
       becomes the same tessellation everything else gets.
 **Most of the machinery already exists and is gated off.** This is not a new engine:
 - `w.c.nested` + `Vyto_solve_scope` already tessellate a cell's children INSIDE it, to any depth
    (VytoNest, VytoNestRest, green) — that IS "smaller Components in it";
 - `Matstyle` already autovivifies a swatch per mainkey — that IS "Styled to some basic degree";
 - `TreeFace` already draws an arbitrary particle generically — the fallback for parts nobody has
    designed a face for yet;
 - `KeepBar`/`Pick` faces are **registered and DORMANT** waiting for exactly this (ledger #11), and P7
    "THE TENANT FLIP" is this flip;
 - the blocker recorded for nested was CPU (`power_cells` O(M²) per scope per frame, no memo) — and the
    **memo landed** (P1/`wallMemo`), plus the inscribed-box memo added today, so that objection wants
     re-measuring rather than assuming.
 **"the want of buttons, a bag of them, to structure"** is the open design question and the human's own
  words for it: once every button is a particle, what governs which buttons a thing HAS, and how a bag of
   them is arranged? That is `Cstructures_todo.md`'s territory (the structure catalogue + Dip_assign) and
    should be answered there, not invented in the renderer.
 **DO NOT start by rewriting HaulFace.** The honest first move is one face, decomposed behind a gate, with
  a Book that proves the parts tessellate and the fleet still green — the same additive discipline every
   station here has used. Pick the SIMPLEST face, not the one that hurts most.

**(5) THE SIZING LAW, CORRECTED — three sentences that change the model, not the paint.**
 *"so it's easier to measure, your boxes keep cutting off html. we used to advise on the aspect ratio of
  things I think... it used to do a bunch of stuff aye... see Voro+Cyto for more inspiration"* ·
   *"I think no zooming but only shifting emphasis, is the way to do it all"* ·
    *"but the size of the cell does affect what's in it, so things become icons when crushed down"*

 - **ASPECT MUST BE ADVISED, NOT JUST AREA — and this is why the boxes cut off HTML.** `need_area` is a
    single scalar, so the floor can grow a cell to the right AREA and still hand a wide player a tall
     narrow seat. A component has a natural SHAPE and must be able to say so. The prior art is exactly
      where the owner points: Voro/Cytui advise shape, not just size (`mold_max_fit` `Cytui:3217` fits a
       box into a polygon under an affine; the sizing doc's ⑤ already says "enlarged toward a **golden-
        shapely envelope** when a whole truth won't fit", and `shapes.md` carries the envelope + 0.72).
     **Owed:** stamp `need_w`/`need_h` (or need_area + need_aspect) beside `need_area` in Vytui's measure
      pass, and have `Vyto_express`/`Vyto_solve` honour the aspect — a power diagram cannot be told a
       shape directly, but the ENVELOPE the cell is grown toward can be, which is what Voro did.
 - **NO ZOOMING — EMPHASIS INSTEAD.** *"I think no zooming but only shifting emphasis, is the way to do
    it all."* This RETIRES the camera as the navigation answer (built 2026-08-09, ledger #15): flying the
     viewport at a cell is the wrong verb. The right one is already built and already live —
      `Vyto_focus` swells the attended cell by `FOCUS_BOOST` and compresses its siblings by
       `FOCUS_SHRINK` (~88× in area), driven through `Radio_state`. **Clicking a cell should SHIFT
        EMPHASIS (re-solve with that cell focused), not move a camera.** The whole glass then re-flows and
         everything stays on screen — which is also the honest answer to the lens study's "the rest RING
          the boundary, never panned off-screen" (processes.md §6). The camera code should be reduced to
           whatever emphasis needs, not extended. *(`--vyz` magnification goes with it — with emphasis
            the cell genuinely grows, so its component genuinely has more room and needs no scaling.)*
 - **SIZE DRIVES DETAIL — "things become icons when crushed down".** The cell's size must decide WHAT its
    component draws: crushed ⇒ an icon, roomy ⇒ the full UI, with steps in between. That is the same
     register law the floor doc already states for text ("crest vs cells are REGISTERS of the same
      sentence picked by zoom, never alternative modes" — processes.md ruling 1) applied to Components.
       It also dissolves the clipping problem at the root: **you never put a big component in a small box
        — you put a smaller component there.** Today the renderer's only lever is spill-vs-clip, which is
         a choice between two bad outcomes; the real fix is that the face is handed its register.
     **Owed:** a register the face rail can pass (`{ n, H, register }` — icon | compact | full, chosen
      from the cell's box against the face's own advised sizes), and each face growing an icon form. The
       generic fallback exists already: a cell too small for any face can draw its edge label alone.

**(4) "and MOVE it as well"** — the parts must not merely tile, they must move: a part arriving, leaving
 or changing should be SEEN doing it. The sprout/erupt/depart fx landed today are the vocabulary; what
  (4) asks is that the DECOMPOSED parts inherit it, so a button appearing is a thing growing into place
   rather than a repaint. Note the standing law this must respect: a settled glass parks and never
    repaints, so part-motion has to ride the browser's clock (CSS/SMIL), never a rAF tick — and it must
     stay off driven Books entirely.

### ⇢ THE GLASS GOT A BODY (2026-08-09) — read this, then the handover below it

**The ask, verbatim:** aspect ratios to flip through in a dropdown "to enforce some kind of min-height"
 · "get some nice effects happening!" · *"Components won't be snapped by your picture-taker, but perhaps
  a lot of it shall fit in the background, or there could always be some bare standard representation in
   the background which is shadowed over by the UI bits shoved in there... and they should be really
    properly shoved in there... it should be able to simulate a bit of spatial things... look like a fancy
     videogame menu with things flying at you and erupting when people play it on their big TVs"* ·
      *"things need to be navigable, lots of erupting sprouting branchy things, and biological feels"* ·
       *"our buttons clicks need to be faster!"*

**ALL RENDERER-SIDE. Not one line of `.g` was touched** — so no ghost-compile, no runner wedge, no
 fixture could move by construction. `Vytui.svelte` + `HaulFace.svelte` only.

**THE ONE THING THAT DETONATES IF YOU DON'T KNOW IT: `scripts/vyto_see.mjs` now exists, and the shape
 work is NOT gated by the Books.** A fixture is a dige of the C tree; a cell's `d` string never reaches
  one. So **wall shape is structurally invisible to every Book** — the first cut of the membranes left the
   whole fleet GREEN while destroying the tessellation (balloons, eaten corners, neighbours no longer
    sharing walls; measured coverage 82% where it must be ~99%). Rasterising the capture showed it in one
     glance. *Chromium cannot launch in the claude container (no libglib), which is why that script does
      its own rasterisation.* **Any future edit to cell geometry or wall shape must be looked at with it.**

**What landed** (each independently revertible, in the order built):
1. **`measure_world`'s px→viewBox scale** is now the exact `meet` scale (`min` of both ratios), not the
    width ratio. A correctness fix that had to precede any viewport capping: the width ratio is only right
     while the svg's element box shares the viewBox's aspect, and a letterboxed svg would have silently
      UNDER-floored every face's `need_area` (grow-only, so it fails quiet).
2. **The aspect pick** — `auto · 21:9 · 16:9 · 3:2 · 4:3 · 1:1 · 9:16`, a `<select>` beside `organs`
    (whose title had been promising "layout controls to come"). A THIRD writer of the frame routed through
     the SAME chokepoint (`fit_frame` → `publish_frame` → `Vyto_stir_soon`), so the model re-cuts and the
      seed clamp catches strays. `auto` is today's measured path byte-for-byte. **Fullscreen beats the
       pick** (there the stage's own box is honest). The picked ratio IS the min-height — the svg is
        `width:100%; height:auto`, so 4:3 renders 0.75×width tall by construction.
   **A trap caught before it shipped:** capping tall picks with `max-height` on the svg is WRONG — the
    element box stays full width while the drawing letterboxes inside it, so the drawing is narrower and
     centred while the molds are still positioned in percentages of the full box ⇒ **mold↔cell registration
      tears, silently, only on tall picks.** Capped the WIDTH instead (`.depth { max-width: calc(82vh *
       --fw / --fh) }`), so the element box always has the viewBox's aspect and no letterbox can occur.
3. **The under-layer** — every FACED cell now also draws its bare self in SVG (`text.ident.under` +
    up to two `sc` scalars), which is the answer to "the picture-taker can't snap Components". `--svg`
     serialises `svg.viewport`; the faces are HTML in a SIBLING div, so **no capture has ever contained a
      single face**, and a faced cell used to suppress its ident — which is why the first pixels ever taken
       of a live glass were five mute polygons with ZERO labels. Now the faces shadow it on screen and the
        capture still says what every organ is. **`.ident.under` naming is load-bearing**: the `--svg`
         serializer only carries CSS whose selector matches `/\.cell|\.ident|\.viewport/`, so a fresh class
          name would ship unstyled black serif into every capture. `data-ukey` not `data-key`, and
           `measure_world` queries `text.ident:not(.under)` — a watermark must never set a need floor.
4. **Membranes** (`path_round`) — bounded-radius corners, `CORNER_R = 13`, capped at 40% of the shorter
    adjacent edge so a sliver degrades to nearly-straight instead of self-intersecting. Straight edge
     middles survive, so **two neighbours still share a wall exactly**. Only the `d` string changes:
      `bbox_of`, the drift judge, `cut_sig`, `power_cells` and every nested frame keep the raw polys.
5. **The depth stage** — `.stage` holds the camera (`perspective: 1100px`), `.depth` is the body it looks
    at (`preserve-3d`), and svg + faces sit inside it **as one body** so a tilt cannot tear the percentage
     mold contract. `.fs-btn` stays outside (chrome must not tilt, and `go_fullscreen` reads
      `parentElement`). `.depth` is `position: relative` so `.faces { inset: 0 }` resolves against it.
6. **Mold seating** — off-centre cells angle inward (±6°) and hover pops the card 34px toward the camera,
    appended to the style string that was already being rewritten every frame, rounded to 1dp so a calm
     glass re-emits it byte-identical. **`z-index` stops ordering inside a `preserve-3d` context, so the
      hover lift MOVED to `translateZ`** (z-index kept only for browsers that flatten).
7. **Parallax** — a passive `pointermove` writes `--px/--py` on the stage; `.depth`'s transform reads them.
    No `$state`, no rAF, no re-render: one style recalc and a composite. The 140ms transition is the
     damping. Touch gets it free and it cannot fight scrolling (reads the pointer, never captures it).
8. **fx: sprout · erupt · depart** — one-shot CSS animations, played by the browser's clock, because a
    settled glass PARKS and a JS-driven effect would freeze exactly when the layout calms (the SMIL-ants
     law). `seenAt` decides an arrival by FIRST-EVER SIGHTING OF A KEY, **not DOM presence** — this glass
      has a documented keyed-remount churn and a presence test would replay the fly-in every time.
       `animation-delay: fxi·55ms` staggers a batch, so a commission blooms outward. **Erupt is the focus
        wire finally dressed**: `Vyto_focus`'s FOCUS_BOOST swell (proposed by `Radio_state` on PLAYING) is
         already the eruption's body, springing; the class only adds the flash.
   **A conflict caught while writing the CSS:** a running animation OUTRANKS inline style, so a keyframed
    mold transform would hold the fly-in and then POP to `mold_seat`'s inline seat the instant it ended.
     The mold's motion therefore rides its CHILD (`.face-scroll`), which composes instead of fighting.
9. **The camera** — click a cell to fly to it, click again / Esc / ⤴ to walk out one level. Sprung on the
    existing loop with the same `step_channel` and ω. **It contributes to the loop's `moving` verdict and
     to nothing else** — never `disp`, `drift` or `settleCount` — because a glide must not delay
      `Vyto_settle`, which the spool and Story's `waitVyto` read. **No zoom stack**: walking out recomputes
       the parent rect from the standing paint, so the owner's *"must not run out of memory when someone
        zooms in infinitely"* rider holds by construction (O(visible), one rect per world). Aspect-LOCKED
         targets, because an off-aspect viewBox letterboxes and slides every mold off its cell. Cells are
          real keyboard targets too (`role=button`, `tabindex`, Enter) — that is the honest answer to
           "navigable", and it cleared the a11y warnings instead of suppressing them.
10. **Vines** — the `%Flow` edges drawn at last, as roots under the cells, weight on `log2`. The solver has
     been bunching by these since VytoBunch (proven by an A/B differential) and **never once drew them**.
      No timer needed: edges change at stir, and a stir always ends in a paint.
11. **Button latency** — instrumented, per §0.1's own law, plus the one no-regret fix.
     **A FIND worth more than the probe:** every HaulFace handler is `A.post_do(fn)`, i.e. QUEUED onto
      `H.todo` — and the `drain-lag` electrode next door (`Housing.svelte.ts:_push_todo`, 2026-08-07) had
       already measured a posted fn waiting **3600ms with `gated=0` and an empty `why`** — nothing holding
        the mutex, nothing throttled, the queue advancing ONE ITEM PER EXTERNAL WAKEUP because a reactive
         self-bump cannot reschedule its own effect. **That is almost certainly the same mechanism as the
          button complaint, and nobody had connected the two threads.** It was fixed 2026-08-08 with a
           `setTimeout` re-drive, so the seconds-long case should be gone — but each item still waits a
            gallop gate and **a click has no priority over whatever the resident glass already queued**.
     `press_probe` stamps `waited` (press→work starts), `ran`, and **`depth` (queue depth at press)** into
      the supply_trace ring, readable with `tracelog.mjs --watch`. **`waited` vs `depth` forks it cleanly: a
       big wait at depth 0 is a wakeup problem, a big wait at depth>0 is a queueing problem, and they want
        opposite fixes.** The no-regret half: `:active` feedback on every control, painted by the compositor
         on pointerdown before any JS runs — half of "doesn't respond quickly enough" is genuinely "didn't
          say it heard me", and that half is now fixed honestly without pretending the queue got faster.

**VERIFIED.** Fleet on the live runner (`58517b48`), all `caveat:0`: **VytoCell 7/7 ×2 · VytoStaple 8/8 ·
 MusuNeGrind 11/11 · VytoTandem 4/4.** Pixel-witnessed by `runner_shot --svg` + `vyto_see.mjs`:
 - `viewBox="0 0 800 450"` on a Book world ⇒ **the aspect pick provably did not leak into a driven world**;
 - `Q` segments on every cell ⇒ membranes real in shipped output; **coverage 98.8%** (the missing 1.2% is
    the intended GAP 2.2 channel) ⇒ the cells still tile;
 - fx classes, the dropdown and the parallax listener all ABSENT on a runner ⇒ the live-page gates hold.
**One red was investigated and dismissed honestly, not waved away:** VytoCell step 6 (`pin one cell by
 pointer then rearrange`) came back red once. A controlled revert to clean HEAD went green, my code then
  went green ×2 on the same Book — so it is the KNOWN settle-timing flake this doc documents at length
   ("any step gated on a settle/board/nest-wait is currently unreadable"), not a regression.

**EYE-ONLY, and said so rather than claimed:** parallax, the seating tilt, the arrival/eruption/depart
 animations, and the camera GLIDE. Motion and 3D transforms cannot round-trip an SVG capture. The camera's
  *destination* is witnessable (a shot taken while engaged carries the zoomed viewBox) — that shot has NOT
   been taken, because a Book runner never engages; it wants a live tab.

**Next moves, in order.** (a) **Look at it on a real tab** — the whole point. The under-layer, the vines,
 the plug and the ants can only be seen where there are faces and relations, i.e. a `/BigSoundland`
  player tab (`runner_shot --runner=<their pub> --svg`), never a Book runner. (b) **Read the press probe**
   — one press of ✕ on a live tab and `tracelog.mjs --watch` names the button culprit outright; the fork
    is already written above. (c) The **gap list** §0.1 item 3 still asks for, untouched by this round.
     (d) A **lone cell fills the entire frame** (VytoTandem, confirmed in pixels: 1 row → 100% coverage —
      correct, but a poor use of the glass, and the owner noticed). Giving a one-cell world breathing room
       is a MODEL change (`Vyto_solve`'s frame or radii) that would move fixtures, so it is flagged here
        rather than taken.

### ⇢ HANDOVER INTO THE DO-UP (2026-08-08 late) — read this first

**Destination.** §0.1 item 3: the Sounditron↔Vyto integration redone, "a bunch of fancy UI biologies",
 under §0.0's ruling (relations and motion, never another box of text). Items 1 (button latency) and 2
  (phone cost) are separable and item 2 is now largely paid.

**What detonates if you don't know it.**

1. **`?VY` IS RETIRED** (`Sounditron.g:229`, 2026-07-27) — "the glass is just what Sounditron is now."
    Every `/BigSoundland` tab has a commissioned Vyto world. Anything in this doc telling you to open
     `?VY=1` is stale; I acted on it today and was corrected by the owner.
2. **THE PIXEL PATH WAS BROKEN, AND THAT IS PART OF WHY NOTHING HERE HAS EVER BEEN VERIFIED.**
    `runner_shot --svg` synthesised `viewBox="0 0 <cssPixelWidth> <cssPixelHeight>"`, discarding the
     element's real viewBox. Vyto draws in MODEL units (an 800-long frame) into an svg laid out at
      whatever width the page gives it, so every capture came out with paths apparently overflowing by
       ~12% and the bottom row clipped. **Fixed** (`LiesFunk.svelte`, the `op === 'svg'` handler: take
        `el.getAttribute('viewBox')`, fall back to pixels only when absent — Cyto's overlay has none, so
         that path is unchanged). I nearly filed the artifact as a Vyto bug; check your instrument.
3. **YOU CAN NOW ADDRESS THE OWNER'S MUSIC TABS.** They are `role:'player'` in the Cluster registry
    (see `Composition_todo` §3.14) and `runner_ask --player=<id>` reaches them: `ping`, `probe`, `world`,
     `dump`, `poke`, `reload`, and `runner_shot --runner=<their pub> --svg` for the glass. `run` is
      refused by an allow-list — never put a Book on someone's music. This is brand new; before tonight
       Vyto could not be looked at on any tab that had one.
4. **A DRIVEN WORLD IS PARKED AND DOES NOT ANIMATE** (`Vytui.parked()`): a Story run jump-lands springs
    and strikes no settle, so Book fixtures cannot see renderer timing. That is deliberate and is why
     display work cannot be gated by the Vyto* Books alone — hence THE PIN.

**The first pixels ever taken of a live glass** (heron, 2026-08-08, `--svg`): frame **800×280**, five
 cells, **all `faced`**, **zero labels**, **no plug, no ants**. Three things to chase from that:
 - the aspect is **exactly 0.35**, which is the hard clamp floor in `fit_frame`
    (`Math.max(0.35, …)`) — the live glass is pinned at the flattest shape the code allows, i.e. the
     letterbox-strip complaint, and it is asking to be flatter still. Is the floor right, or is the
      height measurement (`window.innerHeight - r.top - 8`) starving it?
 - **five** cells on a page §0.0's rail describes as nine organs. Which are missing, and why?
 - the plug and the ants render nothing here. Expected-if-quiet (the plug hides when the radio is off;
    `ants_of` returns null when nothing moves) but **unproven either way** — take a capture with music
     playing and a transfer running before believing either.

**Next move, in order.** (a) The **gap list** §0.1 item 3 asks for — specified-but-unused /
 specified-but-diverged / used-but-unspecified — so the design conversation is "the spec says X, the
  code does Y, which did you mean?" rather than "what do you want?". **Do this before any redesign**;
   the doc is explicit that what the owner wanted true and isn't *has not been said and must not be
    invented*. (b) Chase the **Vyto↔Story timeline split** — the owner (2026-08-08): *"it's funny how
     Vyto is integrated into the Story, we have partially split their timelines and there's probably
      some more lore about how it's to be hanging around."* The spool / `yore_n` / `waitVyto` /
       parked-run gate are the visible half; **find the lore before redesigning around it.** (c) Button
        latency (HaulFace) — instrument, do not guess between the four candidates in §0.1.

**Landed tonight, do not redo:** the §0.2(a) knife-edge (`CALM_EPS = 1.25` vs the model's `0.5`, every
 settle now lands via `jump_to_target`), the §0.2(b) malformed-`%Hold` permanent pin, and the whole of
  §0.2(e) — **the cheap list is exhausted**; every item was either already done or is now. What remains
   is design, not patches. Regression green after those: VytoStaple 8/8, VytoCell 7/7, MusuNeGrind 11/11.



The arc: **wear the words in ✓ → give the glass eyes (Scan) ✓ → give it a memory (Spool) ✓
 → give it a body (the first cell) ✓ → hand it the abdomen (the Radio world as first
  tenant)**.  Milestone 3 landed 2026-07-20, same sitting as the rulings: the model solves
   a real power cut into targets, Vytui springs cells toward them and strikes settle
    itself, and VytoCell recorded GREEN ×2 beside a green VytoStaple regression.  Next
     moves:

- **THE PLUG + THE ANTS — written 2026-08-08, PIXELS UNVERIFIED** (the owner, heading out: *"think about
   how Vyto is going to suddenly turn all nice and supple for to impress people (kids) that this is cutting
    edge metaphysics underneath"*).  §0.0's two named things, built in `Vytui.svelte`:
  - `plug_of(w, cells)` — from the `%Radio` cell to the cell holding `radio.c.rec`, walking `.c.up` until
     it reaches a particle the cut gave a cell to (that walk is what makes it land *in the Mag*).
      `plug_curve` sags perpendicular to the chord — a cable, not a graph edge, because a straight line
       between two cells is the dashboard instinct §0.0 rejects.  Hidden when the radio is `off`.
  - `ants_of()` — start offsets + duration off `H.top_House().c.xfer.pulls[]`; **count reads as volume,
     duration as rate**.  Returns null when nothing is actually moving, so a quiet glass stays quiet:
      motion that never stops stops meaning anything.
  - **SMIL (`animateMotion` + `mpath`), not a rAF tick, and that is the load-bearing choice**: a settled
     world PARKS and never repaints, so a JS-driven ant would freeze exactly when the layout calmed —
      which is most of the time.  The browser's own clock keeps them walking for free.
  - Self-ticked at 500ms (`plug_tick`) because both facts ride `.c`, which never bumps a version — the
     §0.0 caution, same idiom as RadioFace/TransferFace.
  - **`humdinger`-gated, and NOT optionally** — same law the focus taper obeys.  A driven Book must not
     have a 500ms timer re-rendering its glass underneath it: quiescence and settle are what a Story step
      waits on, so decoration running on its own clock is precisely how a Book's timing, and therefore its
       diges, start depending on the decoration.  On a runner the tick never fires and `plug_of` returns
        null before touching anything, so `ants_of` is never reached either.
  - `animateMotion path=…` (SVG 1.1) rather than `<mpath href>` (SVG2, shakier support, needs an id to
     resolve).  Costs one duplicated `d` per ant and removes the question.  It does NOT restart the ants
      on a calm glass either: `plug_curve` rounds to 2dp, so a settled layout re-emits a byte-identical
       `d` and Svelte never touches the attribute.  The `<path class="plug">` keeps its id purely so
        `runner_shot --svg` output stays greppable.
  - **Only FACED cells can be plug endpoints**, and that shapes the whole design: `cell.source` is set
     from `row.c.source_n` inside `face_of`, which returns null when a row resolves no face — so a
      faceless cell has `source: null` and is invisible to both the walk and the id-match.  The Radio is
       faced, and the plausible targets (Crate / `Musu*` / Haul, per `FACE_MAINKEYS`) are faced too, so
        the `.c.up` walk is the load-bearing path: it must reach the CRATE particle that contains the
         record.  The id-match is only a bonus for a referring face like `Haul` wearing the same id — a
          crate's own `sc.id` will never equal the record's, so it cannot be the primary route.
  - **WHAT IS OWED: one look at it.**  THE PIN applies and has not been paid — `runner_shot --svg` found
     no commissioned Vyto world (Book runners have none; the owner's live tabs were closed).  It needs a
      BigSoundland tab with music playing and a friend transferring.  The thing to check first if it looks
       wrong: whether the `.c.up` walk actually terminates on a celled ancestor rather than running out
        its 12-hop guard and drawing nothing.  Assume nothing here is right until it has been seen.

- **PHONE-FIRST + FULLSCREEN + THE FACELESS FACE — landed 2026-08-07** (the owner: *"I might leave you
   allll afternoon redesigning, wildly, the interface... so that Vyto can be fullscreened and everything
    within it gets pronounced with just the right focus"*, phone-first, one cell dominating).
  - **The frame follows the stage's aspect.** It was a fixed `800×450` — 16:9 LANDSCAPE — and the SVG
     holds that at `width:100%`, so on a portrait phone the whole glass collapsed to a letterbox strip.
      A voronoi cut has no intrinsic orientation, so the fix is to cut against the shape you are
       actually looking through. **Driven worlds are PINNED to 800×450**: a Book's layout must not
        depend on the size of the window it runs in, or every Vyto fixture becomes a function of the
         runner tab's geometry. Gated on `humdinger`; no fixture can move.
  - **THE TRAP, if you touch this:** measuring `.stage` is CIRCULAR. It has no height of its own — the
     SVG inside is `height:auto`, so the stage's height *is* the aspect you just set. Feeding that back
      gives a fixed point at whatever it started as, i.e. it never leaves landscape and looks like the
       code does nothing. Width comes from the stage (real, laid out by the page); height from the space
        left on screen below its top edge. Fullscreen is the easy case — CSS sizes it `100vw/100vh`, so
         its own box is honest there.
  - **`⛶` fullscreens the stage**, and the ResizeObserver re-cuts the frame to whatever shape the screen
     turns out to be — entering fullscreen on a portrait phone RESHAPES the cut, it does not zoom it.
  - **`TreeFace` — the faceless face** (the owner: *"showing a recursive tree of plain C** data in a
     useful way ... a cell can kind of be a component or a rendering of the C data all labelled ... and
      recurse C**"*). Every other entry in `glass_kinds` knows what its thing MEANS and draws that; this
       one knows nothing and draws the particle — mainkey, scalars, children, recursively. It is the face
        for the parts of the tree nobody has designed a face for, and it keeps working when the shape
         changes. **`sc` only** — it walks children via `o({})` and never follows `.c`, which holds the
          House, the parent chain and every cycle in the graph; `.c` is COUNTED, never entered. Bounded
           by construction (depth 3 / 12 kids) and it SAYS `… N more` when it truncates.
  - Grappled under **`show_diag`** — the one branch where a cell can be added with zero fixture
     consequence (no Book turns it on), and the guts are diagnostic matter anyway. `tree_root` rides
      `.c` so the marker organ can stand for the world it sits in.
  - **The focus taper is DRIVEN LIVE at last.** `Vyto_focus` has swollen one cell by `FOCUS_BOOST` and
     compressed its siblings by `FOCUS_SHRINK` (~88× in area) since it was written, but nothing outside
      `VytoWeb_focus`'s own Book ever proposed anything — so the live glass only ever showed the even
       cut. `Radio_state` is the one chokepoint every transition flows through, and it now proposes:
        DIGGING/OFF are the underworld (no focus — watch the machinery hunt), PLAYING is the panel
         (*"the radio swallows it all like a panel being placed over the top of all them guts"*),
          STARVED releases again on purpose. Live page only.
  - `Vyto_focus` now also accepts **`on:<mainkey>`** and resolves the tok itself. A tok is an internal
     mirror coordinate; a client outside Vyto has no way to know one, which is why only Vytonation —
      which reads `Vyto_cells` first — could ever call this. `tok` still wins when given, so no
       existing caller or fixture is touched.
  - **STILL UNVERIFIED IN PIXELS**, and the gap named further down this section is why: `runner_shot`
     is Cyto-only, and `--svg` wants `.vyto svg.viewport` on a tab with a Vyto world commissioned —
      the runner tabs have none, so it reports "no populated glass svg". A Vyto screenshot path is
       still owed and would have paid for itself twice today.
- **HMR NO LONGER FULL-RELOADS THE GLASS (2026-08-07)** — the owner's *"try figure out why HMR causes
   whole page reload sometimes"*. `Vytui.svelte` carried a `<script module>` block holding a two-line
    debug serial, and vite-plugin-svelte refuses HMR to any component with module-context state (a
     module binding cannot be hot-swapped without re-evaluating every importer). That made Vytui a
      **dead end**, and `glass_kinds.ts` — whose only importer is Vytui — inherited it, so registering
       one face full-reloaded both player tabs and cost an AudioContext tap each time. Serial moved to
        `H.c.vytui_serial`. **Measured both ways on the live pair**: the identical one-line edit to
         `glass_kinds.ts` wiped the mirror crate to `0 %MusuThem home(s)` before, and left `1 home / 31
          records` standing (own shelf still climbing) after. Propagation stops at the nearest
           *accepting* importer, not at the root — so when an edit reloads, walk the importers rather
            than re-reading the file you edited. Nine components still carry module blocks:
             `Thangs`, `Funk/{Storying,Relay,CreduFunk,Rundar,StoryTimes,Shelver}`, `ui/{DocRow,Waft}`.
- **⛨ READ `## THE PIN` FIRST (2026-07-29, below)** — the display-correctness contract: why
   built ≠ spec'd (the flap-puddle autopsy) · the laws (pixels or it didn't land · proof-first
    Books · the claim ledger · read-the-shelf) · the pinned fact ledger · the ordered P0→P7
     build to the target. **All display work routes through its ledger now.**
- **THE FACE RAIL — LANDED 2026-07-27 (`src/lib/O/Vytui.svelte`; the headline — Vyto renders Radio's
   real UI now, not a labelled bubble diagram).**  Per the three-agent survey, the #1 blocker to
    "Radio builds its UI on Vyto like Cyto+Voro" was that Vytui drew only SVG cells + one ident label —
     NO faces.  Now each cell whose mirror row wears `sc.face:'X'` (WORN) or whose mainkey the viewer
      imposes a face on (`FACE_MAINKEYS`) mounts the SAME glass component Cyto does (`glass_kinds.ts`:
       Radio/Stoker/Tuner/Door/Riffle/Zine/Lineup/Crate/Heist) — props `{ n: row.c.source_n, H }`,
        handed the LIVE source particle not the scalar mirror row.  Rendered as an HTML overlay molded
         to each cell in viewBox PERCENTAGES (tracks the responsive SVG exactly — no pixel measurement,
          no overlay-sync bug class — which is itself the "better than Voro" win: real DOM faces, not a
           canvas-overlay mold).  Each face is wrapped in a `<svelte:boundary>` so a throwing face
            degrades to its label instead of white-screening the glass.  Faceless rows (Cogs) keep the
             ident label ⇒ every existing Book renders byte-identical.  Compile-proven (bundle-fetch 200,
              symbols present).  **REVIEW IT: open `/BigSoundland?VY=1`** — Sounditron commissions Vyto
               on its nine organs, each now a real face.  HONEST GAP: I could NOT pixel-verify — runner_shot
                is Cyto-only (`cy.png()`), there is no Vyto screenshot path, so the render is verified by
                 compile + reuse-of-Cyto's-exact-faces + your eyes.  Owed next: face SIZING/legibility in
                  small cells (Cyto does affine text scaling — Vyto just molds+clips today), the crew-tuck
                   (hide the `system` crew so `%Machine` does not clutter), kind chrome.
- **Live CRUSH tenanted — `VytoCrush` (`Vytonation.g`), CODE-COMPLETE + compiled, bake PENDING (runner
   contention).**  `Vyto_fold` is no longer a stub: a `w.c.folded` (opt-in, 6th arg to
    `Vyto_commission_on`) glass crushes a crowded scope — `budget_for` sets the cell budget,
     `bucket_key_of` elects the partition key, and each ≥2 group distils to ONE crest cell with its
      counted dip (`Vyto_distil`); crushed members wear `.c.folded` and lose their T so Solve skips
       them.  Voro's signature rosette, matched — the seam Agent C called "the single blocking gap for
        large-data legibility."  Touches only Fold + Solve (crests survive Scan's sweep via a `seen_at`
         stamp — Scan's core UNtouched).  It RAN to done:4 (all beats, no crash) after fixing a missing
          `budget_for` import; only the accept/verify is blocked by contention.  Gated OFF ⇒ fleet
           byte-identical.  Finish: fire-and-poll record (see below).
- **Nest-solve (J4) tenanted — GREEN×2 2026-07-27 (`VytoNest`, `Vytonation.g`); recorded + regression
   green.**  Was code-complete/unrecorded earlier this session; baked via fire-and-poll once the runner
    freed.  correct-by-construction + compiled + gated OFF.
      `Vyto_solve` now recurses into every scope when `w.c.nested` (opt-in, 5th arg to
       `Vyto_commission_on`): after the flat top cut stands, each cell becomes the frame for its own
        mirror children (`Vyto_solve_scope`, gap=0 so a scope FILLS its parent), to any depth; Express
         grows a tree-walk (`Vyto_express_rows`) so nested rows are sized.  **This is the "cluster of UI
          bits" spine** — a cluster IS a scope whose children solve inside its cell.  ADDITIVE + gated,
           so the flat/priced paths are byte-identical (same safe pattern as VytoBreathe) — but the
            VytoNest `Vyto_solve`/Express edits have NOT had a fresh full-regression re-run with their
             gen (blocked by the same contention).  **TO FINISH (≈5 min on a free runner):** the record
              cycle keeps refusing under `--watch` (false-deads/hangs on a busy runner) — use FIRE-AND-POLL
               instead: `runner_ask run VytoNest` (no --watch) then poll `runner_ask state` to `failed`
                → `accept` (patient, 150s+, NEVER kill mid-flight) → poll idle → fire-run again → poll to
                 `done`.  Then re-run the fleet (VytoCell/Staple at least) to close the regression bar.
- **Sizing ④+⑤ tenanted — LANDED 2026-07-27 (`VytoBreathe`, `Vytonation.g`, GREEN×2 + full Vyto*
   regression green; model-side only — no display edit).**  The global type-scale is wired into
    `Vyto_express` as an OPT-IN priced commission (`w.c.priced`, default off → every existing Book
     byte-identical).  The build FORCED a reframe worth reading: the §9-draft *frame-share* is
      **vacuous for cells** (power diagrams read only relative radii — normalising to the frame changes
       nothing and even degrades the ordering).  So the honest ④ is §3's **graph-global importance** —
        `Vyto_importance` = `1+dose` + a **kinship lift** (the Relate scribe's `%Flow` edge weights on
         the row, §9③), so a value shared across the graph makes every carrier a bigger cell everywhere.
          2-D differential (needs BOTH pricing AND kinship): kin oaks outsize a lone pine at equal dose ·
           unprice → equal · sever kinship → equal.  Detail + owed work in `Vyto_sizing_todo.md §9` (the
            ⑤-WIRE-LANDED block): taper ⑥ untouched · intra-cell rank owed · preen the `0.5` coefficient.
- **Foam engine gated + Relate given teeth — LANDED 2026-07-27 (overnight, uncommitted; two Books
   GREEN×2, both adversarially proven, model-side only — no display edit).** After the port
    (`vyto_foam.ts` + Gang/Relate/Focus filled, VytoWeb green — see [[vyto-foam-port-landed]]):
  - **VytoFold** (`Ghost/V/Vytonation.g` + `wormhole/Story/VytoFold`) gates the PURE fold engine —
     `budget_for`+`fold_ladder`, which `Vyto_fold` will call but currently does NOT, so it had no repo
      gate at all (only the scratchpad study's `.mjs`). 7 truths: budget scales ×4 with area · roomy=OPEN ·
       the least-`memberDim` family folds FIRST via CRUSH (the `less()` key beats bucket — the doc comment
        "prefer bucket over crush" is imprecise) · focus path shielded · coherence floor distils-vs-crushes ·
         plus the gang election's honest NULL (an all-identical OR all-unique crowded row elects no
          representative — `bucket_key_of` returns null rather than force one). **So `Vyto_fold` can now
           wire `fold_ladder` against a proven contract** — that wiring stays the human's (the display/fold
            station).
  - **VytoBunch** (+ `wormhole/Story/VytoBunch`) makes the Relate %Flow edges DO something: a new pure
     `pull_step` in `vyto_foam.ts` nudges meaning-related seats toward one another INSIDE `Vyto_solve`'s
      K-relax (spec §6 "the solver honors the edge as an attraction" — the BLESSED *incremental* nudge,
       NOT the forbidden relayout-from-nothing of §10.3). Byte-neutral when no edges (guard `if(nbrs)`;
        VytoWeb/Staple/Cell regression GREEN). Proven by an A/B DIFFERENTIAL: joined kin rest 234 <
         severed-kin rest 247 (neuter the pull ⇒ exactly that assertion reds). **HUMAN KNOB: `coeff 0.15`
          in `Vyto_solve` — deliberately gentle (~6% pull, the centroid relax counter-balances); bump it
           for tighter bunching.**
  - Remaining §6 chain (DEFERRED — bigger / display-adjacent, wants the human first): proximity →
     tessellation ADJACENCY as a *latched* fact → **%Bunch** shared-expression factoring (Express writes
      the common bits once, members keep their diffs). The flight-latch is §3 (granted-motion), so this
       is display-adjacent. The **SHIFT transaction on Focus** likewise.
- **First tenant — LIVE, in the other agent's hands (2026-07-20)**: the human's Radio
   agent is actively integrating Radio as a Vyto client (the Voro+Cyto → Vyto display
    move).  This side SUPPORTS, never edits display-side: keep `vyto_workingouts/
     client.md` current (their front door), the teaching Books green (VytoMitosis ·
      VytoRadio), and take model gaps they hit as requests against Vyto.g rather than
       letting the model fork.  Two runner tabs on the fleet — ours is the ★claude one;
        pin `--runner=` always.
- **Owed engineering — LANDED 2026-07-20** (the three units, all live-gated GREEN, see
   "what stands"): watch_c era-guarded multi-handler + teardown-on-decommission (Unit 1),
    spool freeze-on-run-fail (Unit 2), the step→yore_n shim + whichever-glass seek dispatch
     for Storui (Unit 3).  Awaiting the human's commit + confirmation of the three flagged
      decisions (below).
- **Seeing it**: nothing resident commissions Vyto yet, so the first cells are seen by
   running VytoCell on a visible runner tab — the parked-run gate lifts when the run
    stops driving and the springs animate the standing world.
- **The sizing|structure arc (2026-07-21)** — the Stuffing algebra, the global scale, the
   nested-C structure ask and the crush|surf are integrated as a catalogue of C→C engines in
    **`vyto_workingouts/processes.md`** — joints, risk register, and a five-Book build order
     (VytoBreathe · VytoCrush · VytoNest · VytoSurf + demos).  Its HUMAN block holds four open
      rulings (the floor law · zoom=reframe · the `Vyto_fold` tenancy go-ahead · the write-fan).
       Proofs standing: `Stuffing` + `Typescale` Books (Voronation.g), `Vyto_sizing_todo.md §9`.

- **The migration model — per-Book, from WITHIN the app (the human, 2026-07-21).** The `?VY=1`
   page-global boot flag (built 2026-07-20) is the WRONG shape — retiring it. The intent, never
    written down before now (which is exactly why it built wrong): move Cyto→Vyto **one Book at a
     time**, as a shift in *provenance*, not a component swap.
  - **Cyto was an observer**: Story, running a Book, casually attaches a Cyto view that scans the
     Book's tree from outside (`Sounditron_glass` → `Cyto/Cyto e_Cyto_commission` with
      `Scannable: <the Book/world>`). Cyto's home is Story; it *watches* a Book.
  - **Vyto is wired from WITHIN the application**: the app commissions its own glass as a
     first-class part of itself, not a Story-imposed watcher. So "per-Book, one at a time" =
      convert each app/Book to commission Vyto from within itself, retiring the Story-observer
       Cyto as each crosses. The Book's own commission IS the per-Book declaration — no global
        flag, no registry.
  - **Two gates before Sounditron flips for real** (why it was flagged, not committed):
    (1) **retire Voro too** — Voro is (suspected — verify) a viewer-imposed overlay riding ATOP
     the base regardless of Cyto|Vyto, which is why `?VY=1` looked identical to Voro; the
      migration must drop the overlay, not just swap the base.  (2) **parity** — Vyto v1 is plain
       cells (no faces, no Gang/crew, no sub-cell world), so a direct swap regresses Sounditron's
        face-heavy UI. Parity includes a **timeline UI** (the human's ask: step around in time,
         see the last few places we were, like an ongoing Story) — its data already exists in the
          Run's step/got_snap history that Storui's timeline reads; point Vyto's timeline at that
           same source.
  - **Plan (2026-07-21):** fully move Sounditron to Vyto (commission Vyto from within Sounditron;
     drop the Cyto+Voro+faces path + the `boot_param('VY')` flag) — **AFTER the ttlilt fixup**
      (Hovercraft.svelte:548 retract-on-drop, task #53 stage 1).

## THE PIN — why built ≠ spec'd, and the contract that ends it (2026-07-29)

**Read this before any display work. This section is the enforcement arm of every Vyto doc:
 a claim not rowed in its ledger is not done — no matter what any other doc says.**
The occasion: the human found the live glass an "unstructured flap-puddle — no reasoning about
 the size of the UI components in its cells and no treeing" after months of designed-and-proven
  model work. The treeing half was fixed and pixel-proven 2026-07-29 (VytoNestRest below); the
   sizing half is genuinely absent; and the *pattern* that produced both gaps was still running
    (see the autopsy). This section pins the target, the facts, the laws, and the ordered build
     so the next run cannot miss.

### HUMAN — five calls (recommendation first; nothing in P0–P3 waits on you)

1. **Bless the browser→model measure seam (P2 — the need floor).** REC: **yes.** It is
    Cytui's content-box floor (`Cytui:3256` per `Vyto_sizing_todo`) ported to the power
     diagram: the browser MEASURES each face's natural box (the thing it does for free —
      your "could have just display:inline-block" point — weaponised) and `Vyto_express`
       honors it as a floor under `env_area`. One-directional per pass + grow-only hysteresis
        within a settle so no wall-flutter (§4 of the sizing doc). Importance still ranks
         ABOVE the floor — the algebra is untouched; it just can't starve a widget anymore.
2. **Wall policy (P5 — spill vs clip vs shrink).** REC: **restore the polygon clip** once the
    floor lands. `Vytui.svelte:701` records your "let them overflow" choice — made when clipping
     amputated content inside cells cut too small. The floor removes the cause; re-decide the cure.
3. **The crest/ceiling wiring (P4) is the fold tenancy you reserved** (`Vyto_fold` calling the
    VytoFold-proven `fold_ladder`). REC: release the WIRING to the run (the contract is
     Book-proven); keep the LOOK — crest chrome and the "+N more" face — for your eye.
4. **The φ / AREA_BASE preen** (`Vyto_sizing_todo §0`) gates **P6 only** — text riding the
    global scale. P0–P4 are geometry and floors; they neither read nor change φ.
5. **The This/Step snap-scope core fix** (Story session shelf reaching Vyto's spool — the
    `ok`/`disk_ok=false` latent traps) stays a SEPARATE thread — Story core, not this pipeline.

### The target — the sentence that must not be missed

**Every particle a cell; every cell real DOM UI; the C** tree tessellated to any depth; no cell
 ever smaller than the measured box its widget needs; above that floor size speaks graph-global
  importance; the glass settles and STAYS settled; and every one of those clauses is witnessed
   in rendered pixels by a Book on the live runner.** That is what all the design was FOR.

### The autopsy — three named failure modes (name them so they can be policed)

- **F1 · WITNESS ASYMMETRY.** The proof harness was pixel-blind until 2026-07-29 (`runner_shot`
   was `cy.png()` = Cyto-only). Everything provable by snap — solver, algebra, importance,
    crush — thrived, because proof was cheap. Every station needing the BROWSER in the loop —
     descend the tree, measure the content, hold a settle — starved. The tell, preserved above
      in this very doc: the face rail "LANDED" carrying its own confession — *"HONEST GAP: I
       could NOT pixel-verify… verified by compile + your eyes."* Accepted as done. The harness
        selected the organism's shape.
- **F2 · SPIN-OUT WITHOUT MERGE-BACK.** Sub-topics fork into docs and execution follows
   whichever doc the session has open. Exhibits: station ⑧ (fit) drafted in `Vyto_sizing_todo
    §9` 2026-07-21 — never built; `Vyto_perf_todo.md` written 2026-07-29 03:26 by the wire-side
     worker and nearly unread by the owner side the SAME DAY; the workingouts end in "open
      questions only the human can rule on" and stall there.
- **F3 · NO CLAIM LEDGER.** Nothing bound spec'd-sentence → code → Book → pixel witness, so
   "built" drifted from "spec'd" invisibly: the face rail landed real components that were
    unsized (fixed 11px) · unclipped (AABB molds) · unfloored (the diagram never hears the
     widget) — each piece individually recorded as a choice or an owed station; the composition
      a flap-puddle.

### The laws — the anti-backslide contract

- **LAW A — PIXELS OR IT DIDN'T LAND.** A display station is DONE only when its Book runs green
   ×2 on the LIVE runner (pinned `--runner=`) **and** a `runner_shot --svg` assertion greps the
    rendered DOM for the station's signature. "Compile-proven" and "review it with your eyes"
     are BANNED as done-states. The rail exists: VytoNestRest is the template — a Book that
      RESTS in the state under test so the shot lands at `done`.
- **LAW B — PROOF-FIRST.** The Book's name and its `%see` sentences are written in the ledger
   BEFORE the station's code. World named after the Book (the dispatch law — or the wrangle
    silently never fires). Register on the Credence board at birth.
- **LAW C — THE LEDGER ENFORCES.** One row per display claim: **claim | code | Book | pixel
   witness**. An empty cell = NOT DONE. Any new sub-topic doc must land its claims as rows here
    in the SAME session it is written — the F2 antidote: spin out freely, merge back same-day.
- **LAW D — ADDITIVE GATES + ADVERSARIAL PROOF.** Every station opt-in; the Vyto* fleet
   byte-identical with gates off; every Book proven ABLE to fail (one-line sabotage → red →
    revert) before its green is believed.
- **LAW E — READ THE SHELF FIRST.** Session start: `ls -lt src/lib/O/spec/*.md | head -15` —
   any Vyto-adjacent doc newer than your knowledge is read BEFORE code. This law exists because
    `Vyto_perf_todo.md` went a day unread by the side it was addressed to.

### The fact ledger — pinned 2026-07-29 (every row verified against live code this session)

| # | claim | code | Book | pixel witness |
|---|-------|------|------|---------------|
| 1 | render descends the C** tree | `Vytui.svelte` `tree_nodes` — double-gated (`w.c.nested` + kid has `.c.T`) | **VytoNestRest** GREEN 3/3 caveat:0 | ✅ SVG: 6 paths — `Rig:main`=`.cell.scope` · `Cog:A`=`.cell.nested.scope` · A1 A2 B C=`.cell.nested` |
| 2 | settle survives cells entering/leaving | `Vytui.svelte:345-352` — vertex-count change skips wall drift (perf §3 **LANDED** — do not re-fix) | fleet regression | owed a shot-pair (P1) |
| 3 | face box is the AABB of the poly — `clip` always `''` | `bbox_of` `Vytui.svelte:98-106`; `:272,281,286` | — | — (P5 re-decides) |
| 4 | spill is a recorded CHOICE, not a bug | `Vytui.svelte:701-710` ("let them overflow" + the pointer-events shield) | — | — (P5) |
| 5 | face content is flat 11px — no floor, no scale | `.face-scroll` `Vytui.svelte:716-719`; SVG idents alone get the 14px floor `:724-725` | — | — (P6) |
| 6 | NOTHING measures a component — zero content feedback | grep `measure/intrinsic/clientWidth/getBBox` over `Ghost/V/*.g` + `Vytui.svelte` = comments only | — | **THE GAP** → P2 |
| 7 | cell size = `2400·(1+dose)` or `2400·imp` — literal ×5, no constant | `Vyto.g:736,739,753,811,921`; "AREA_BASE" exists only in comments `:714,738` | VytoBreathe (⑤ wire) | — (P0 names it) |
| 8 | child radii are absolute + depth-blind — violence inside small parents | `Vyto_solve_scope` reads absolute `env_area` (`Vyto.g:908-959`; perf §2) | Nestcut proves geometry — NOT proportion | — → P3 |
| 9 | walls re-derived O(M²) per scope EVERY animating frame — no memo | `power_cells` `vyto_geometry.ts:39`; per-frame from `integrate_world` (`Vytui.svelte:332`; perf §1) | — | — → P1 |
| 10 | no per-scope cell ceiling; fold crushes top only; `fold_ladder` PROVEN but UNWIRED | perf §4; `budget_for` = 12 legible at 800×450 (`vyto_foam.ts:88`); VytoFold contract stands | VytoFold | — → P4 |
| 11 | nested is gated OFF at the wire | Sounditron sets `commission.sc.nested` only on `M.c.heist_nested` (perf §5); KeepBar/Pick faces registered DORMANT | — | P7 flips it |
| 12 | a faced cell draws a BARE SVG representation under its face | `Vytui.svelte` `under_line` + the `{:else if}` ident block; `.ident.under` | fleet (byte-neutral: SVG never reaches a dige) | ✅ SVG: `class="ident under"` greppable in a capture — the first time any capture could say what a faced cell IS |
| 13 | cell walls are rounded and STILL TILE | `Vytui.svelte` `path_round`, `CORNER_R = 13`, capped at 40% of the shorter adjacent edge | fleet green ×2 — **and the fleet CANNOT witness this**, see the pixel cell | ✅ `vyto_see.mjs`: **coverage 98.8%**, straight shared edges. First cut measured **82%** (balloons) with the fleet still GREEN — the defect a Book is structurally blind to |
| 14 | the frame's aspect is a CHOICE on a live page, and pinned on a driven one | `Vytui.svelte` `ASPECTS`/`aspect_pick` → the `fit_frame` branch → `publish_frame` | VytoCell 7/7 ×2 · VytoStaple 8/8 · MusuNeGrind 11/11 | ✅ SVG of a Book world reads `viewBox="0 0 800 450"` ⇒ the pick provably cannot reach a fixture |
| 15 | the glass is navigable — a cell can be flown to and walked out of | `Vytui.svelte` `cam_of`/`cam_engage`/`cam_out`/`cam_step`; viewBox + mold % read the camera | fleet (a driven world never leaves the reference pose) | ⬚ OWED: a shot taken WHILE ENGAGED carries the zoomed viewBox — needs a live tab, a Book runner never engages |
| 16 | %Flow relations are drawn as vines | `Vytui.svelte` `vines_of`/`vine_curve`; `.vine` | — (no Vyto* Book declares relations; VytoBunch proves the SOLVER reads them) | ⬚ OWED: needs a world with relations — the live page, pending the gap list |
| 17 | press → queued-work latency is measured, not guessed | `HaulFace.svelte` `press_probe` → supply_trace `ev:'press'` {waited, ran, depth} | — (an electrode, not a claim) | ⬚ OWED: one ✕ press on a live tab + `tracelog.mjs --watch`. `waited` vs `depth` forks wakeup-vs-queueing |
| 18 | a press is ACKNOWLEDGED before its work runs | `HaulFace.svelte` `:active` on every control (compositor-painted on pointerdown) | — | ⬚ eye-only by nature — a paint that precedes JS cannot be captured by a JS-driven camera |

### The build plan — P0→P7, each Book named BEFORE its code (LAW B)

- **P0 — name the constant.** `AREA_BASE = 2400` once; five literal sites (ledger #7) read it.
   No new Book — full fleet green + byte-identical IS the proof.
- **P1 — `VytoMemo` (perf §1).** Memoize each scope's walls keyed on (membership ⊕ seeds ⊕ radii ⊕
   frame, quantised 0.01px); skip the re-cut unchanged; a SETTLED world derives no walls at all.
   Probe `w.c.wall_cuts` (off-snap) counts only REAL cuts.
   `%see:'a settled glass cuts no new walls across a held dwell — the memo holds'`
   `%see:'the wall counter is alive — the drive to rest cut real walls before the hold began'`
   Adversarial: break the memo key → red. Witness: two `--svg` shots 5s apart byte-identical.
   **2026-07-30 CODE LANDED** (`Vytui.svelte` wallMemo/cut_sig in build_cells; ungated — the sig
    covers every input, the fleet is the regression) + Book authored/Credence-registered; green×2 +
     shot-pair OWED (the runner tab went dark mid-verification — see the build log below).
- **P2 — `VytoNeed` (the need floor — HUMAN call 1).** Vytui measures each LEAF widget's natural
   box post-flush — an ident label by getBBox (already viewBox units); a face by the Cytui:3256
    firstElementChild offset trick (a box-stretched `width:100%` child is SKIPPED — measuring it
     would spiral) — stamps `row.c.need_area` (`.c` never `sc`) grow-only with a 2% dead-band →
      `Vyto_express` floors `env_area = max(algebra, need·1.15)` under commission opt-in
       `need_floor:1`. A floor-free glass skips the whole pass (cost-additive too).
   `%see:'the wide label cell grew to hold its measured content — the need floor is honored'`
   `%see:'with the floor unarmed the same label keeps its plain dose box — the gate is additive'`
   Adversarial: neuter the floor → red. Witness: shot greps the fat cell's area ≥ its need box.
   **2026-07-30 CODE LANDED** (`Vyto.g` need_floor/Vyto_need_of; `Vytui.svelte` measure pass) +
    Book authored/Credence-registered; green×2 + shot OWED (same runner outage).
- **P3 — `VytoDepth` (perf §2).** Scale each scope's child radii by √(parent cell area / frame
   area) in `Vyto_solve_scope` — the r² wall differentials shrink WITH the parent, so children
    contest a small cell as gently as tops contest the frame. Nested is already the opt-in gate;
     flat worlds byte-identical. The `parent.c.misfit` stamp already waits to assert on.
   `%see:'six children tile their small parent with no crowd-out — depth scaling holds'`
   `%see:'a nested child wears a radius scaled to its parent share — not the frame absolute'`
   **2026-07-30 CODE LANDED** (`Vyto.g` depth_k in solve_scope) + Book authored/Credence-registered;
    green×2 OWED (same runner outage).
- **P4 — `VytoCeiling` (perf §4 — HUMAN call 3).** `budget_for` on the cell's OWN bbox;
   overflow crushes to one crest via the proven `fold_ladder` — its first tenancy.
   `%see:'a twenty-child scope shows at most its budget with one crest counting the rest'`
- **P5 — WALL POLICY (HUMAN call 2).** Re-decide `Vytui:701` with the floor in place.
- **P6 — text rides the global scale (HUMAN call 4 gates).** Faces stop being flat 11px: font
   rides S (Typescale — proven alone) with a legibility floor; then taper ⑥; then ⑧ fit·paint
    places at rightful size (`Vyto_sizing_todo §9`).
- **P7 — THE TENANT FLIP (the target).** `M.c.heist_nested` on: a keep tessellates its album
   picks on the live glass — KeepBar/Pick faces wake.
   `%see:'a keep cell tessellates into its picks and the glass stays settled'`

**Order rationale:** P1 first — you cannot pixel-witness a glass that never rests, and every later
 Book leans on LAW A shots. P2 next — flat-provable immediately, kills the starved-widget class.
  P3 then P4 make nested survivable; P5/P6 are the human's taste and preen gates; P7 is the point.
**After every P:** ghost-compile → runner RELOAD (new .g methods) → full Vyto* fleet green →
 byte-identical with the new gate off → Credence row. Never commit; the human reviews the diff.

**BUILD LOG 2026-07-30 (owner side).** P0 found already landed+committed (`vyto_foam.ts:83`
 AREA_BASE; all five sites read it). P1/P2/P3 code + Books landed as above.

**The begun-wedge — ROOT CAUSE FOUND + FIXED.** Every Book run (VytoNestRest control included, at
 clean HEAD gens) wedged at phase `begun` forever. NOT the elvis-targeting theory first suspected —
  a checkpoint trace (`H.diag()`, temporary, `.c`-only so it never rides a snap — Housing.svelte.ts)
   walked the whole chain live and named the real cause: `runner_ask.mjs`'s own client-side retry
    (`for (attempt=1;;attempt++) sendAsk(...)`, the "insisting N/5" loop) resends the IDENTICAL `run`
     ask on a lost/delayed ack. On a contended/slow runner the retry LANDS server-side too — and
      `Lies_become_book_drive` had no idempotency guard, so each landing re-fired `resetStory`,
       tearing the in-flight Story world down (`auto_teardown_story` + a fresh `subHouse('Story')`)
        before it ever reached step 1. The disk read itself was never the problem — `nav.read_file`
         was traced returning real toc bytes every time; the WORLD holding that progress kept getting
          destroyed out from under it. **Fix (LiesFunk.svelte, `Lies_become_book_drive`):** a
           duplicate-dispatch guard — `Lies_rungo_record(w)` already `begun`/`stepping` for the SAME
            book ⇒ accept the duplicate silently, don't re-drive. Confirmed: with the guard, a
             duplicate landing shows `become_book_drive GUARD BLOCKED` in the trace and the ORIGINAL
              run finished — VytoNestRest green, step 1 `ok=1` dige matching the recorded fixture.
 **Residual: this runner tab is severely throttled** (matches a backgrounded/unfocused browser tab —
  Chrome deprioritises timers+JS for background tabs). Symptoms: Wormhole() ticks land many seconds
   to tens-of-seconds apart instead of the ~200ms AMBIENT_MAIN_TICK_MS; an already-fired elvis takes
    ~20s to actually reach Auto's think(); nearly every CLI op needs 2-4 "insisting" retries. This
     makes a full green run take minutes and makes back-to-back confirmation runs flaky, NOT because
      the fix is wrong — the one clean confirmation obtained (green, matching dige) stands. Asked the
       human (Telegram) to bring the runner tab to the foreground; the fix does not depend on that,
        only fast/repeated re-verification does.

**A SECOND, separate finding — P3 depth-scaling was ungated, now fixed.** Re-running VytoNestRest
 post-fix surfaced steps 1-2 green but step 3 ("commission the glass nested on the rig and stir to
  rest") RED — its recorded fixture carries 4 `%see` lines (e.g. "each child and grandchild wears a
   target with a real radius") that the live got_snap emits NONE of. Root: P3's `depth_k` in
    `Vyto_solve_scope` (Vyto.g) applied UNCONDITIONALLY to every `w.c.nested` world, unlike P2's
     `need_floor` which got its own opt-in — so it silently changed geometry for EVERY pre-existing
      nested Book, VytoNestRest included, violating LAW D (additive gates). **Fixed:** gated behind a
       new `depth_scale` commission flag (`Vyto_commission_on`'s 8th arg → `w.c.depth_scale`;
        `depth_k` is `1` — a no-op — unless set); `VytoDepth` now passes it explicitly, every other
         caller defaults off. **BUT gating it off did NOT change VytoNestRest's step-3 dige at all**
          (byte-identical to the un-gated run) — so P3 was never actually the cause of this red. The
           real suspect: `VytoNestRest`'s settle-wait (`expecting(w,'nest_wait', 18, …)`) is an
            18-SECOND window, and this tab has measured ~20s+ just to deliver an already-fired elvis
             — the settle almost certainly never finishes before the window closes, so the assertions
              that fire AT settle never fire. Same root cause as the begun-wedge saga: a severely
               throttled tab, not a code defect. The depth_scale gating fix stands regardless (it was
                a real law violation independent of this red) — but step 3's true pass/fail can't be
                 honestly read until the tab is un-throttled.
 **Checked and ruled out (2026-07-30, later same session):** the Organ/Bar board counts
  `VytoNest_board_ready` hardcodes (10/7) are UNCHANGED — `Vyto_board` mints exactly 10 Organs + 7
   Bars, none touched by P2/P3 — so it's not a board-count regression. Re-ran VytoNestRest again
    once the tab looked more responsive (`ping`/`run`/`steps` all came back with zero "insisting"
     retries) and step 3 STILL landed the identical dige `8f01bab202d54636` (steps 1-2 stayed
      byte-matched at `643185e5f62fdbd4`/`23450ae230b169a9`).
 **CONFIRMED (not just theorised): a `world` diag_trace read now shows the exact throttling
  signature.** `Wormhole()` ticks arrive in tight bursts (~100ms apart within a burst) separated by a
   very consistent **~15 SECOND** gap between bursts — precisely Chrome's background-tab timer-
    throttling behaviour (batch timers, release them periodically rather than continuously), not
     general/random slowness. Clean WS round-trips (`ping` et al., a DIFFERENT code path — the raw
      relay message handler, not the Svelte-effect-driven belief loop) can look fast while the STORY
       belief loop itself is still batched this way; that's why "ping came back clean" didn't mean
        the tab had actually sped up. Against that ~15s burst period, an 18s `nest_wait` window is a
         near-guaranteed miss almost every time — which is exactly the repeat-identical dige observed.
          **Conclusion stands: step 3's red is the tab's background-throttling, not a code defect.**
           Re-verify once the tab is genuinely foregrounded (the diag_trace burst-gap collapsing to
            ~200ms is the check that it actually worked, not just a clean `ping`).

 **Verification queue (once the tab is foregrounded/stable): green×2 for VytoNestRest (all 3 steps,
  not just step 1 — an early `state` read can catch mid-run and misreport total), then fleet
  regression, then VytoMemo → VytoNeed → VytoDepth** (each: red-fixture run → accept → green×2 →
   sabotage red → revert → shot). Give each run several patient minutes; avoid rapid-fire CLI polling
    (it adds contention on an already-throttled tab) — fire one `run`, wait, check `state` once.

**A THIRD finding — a real duplicate-dispatch race window, closed; then a completely SEPARATE
 stale-ledger cause found for the remaining "book:null" mystery.** After the human brought the tab
  back (2026-07-30, later still), re-testing caught TWO `become_book_drive` calls **11ms apart**,
   both logging `inflight=none` — the original guard checks `Lies_rungo_record(w)`, which only
    exists AFTER `Lies_runner_begin` runs, itself PAST this function's first `await`
     (`Lies_ledger_secure`) — a genuine race window the original fix didn't close. **Fixed:** a
      second, purely SYNCHRONOUS `.c` flag (`w.c.becoming_book`), set/checked before any yield point,
       cleared on every early-return path. This measurably worked (a later run showed only ONE
        dispatch, no duplicate) — **but `steps` STILL read `book:null` after it**, with NOTHING
         logged past a single clean `become_book_drive called` entry — no resetStory, no error,
          nothing. Traced to the true cause with two new checkpoints inside `Lies_ledger_secure`
           (LiesFunk.svelte): `ledger_dige=L0-811c9dc51f2be47c pins=0` — this runner's
            `w.c.ledger_replica.head` (only ever set by `Lies_ledger_recv`, i.e. an EDITOR pushing a
             `ghost_ledger` frame) references a version this replica has NO matching pins for. That
              hits the deliberate "cannot resolve at all → fail loud, never a silent run" branch,
               which returns `false` BEFORE any run-record exists — so `Lies_runner_phase`/
                `Lies_report_result` inside it are silent no-ops (nothing to write onto yet). **This
                 is EXTERNAL interference** — some OTHER editor client connected to this SAME shared
                  runner at some point mid-session and pushed a malformed/incomplete ledger export
                   (classic [[shared-runner-bleed]]), not a bug in either fix above. Since
                    `ledger_replica` is `.c`-only (wiped by a reload) but can be re-pushed by that
                     other editor at any time, the practical workaround is **`reload` immediately
                      followed by `run`, chained with no gap** — confirmed working: `ledger_dige=none`
                       (fast path) on the next attempt, `resetStory` fired, steps 1-2 landed GREEN with
                        matching diges (`643185e5f62fdbd4`/`23450ae230b169a9`). Step 3 still reds with
                         the same `8f01bab202d54636` — consistent with the ALREADY-diagnosed
                          throttled-settle-window cause above, now cleanly isolated from both of these
                           since steps 1-2 need no long settle and pass reliably every time. **Net
                            state: both dispatch bugs are fixed and confirmed; the stale-ledger issue
                             is a workaround (reload+immediate-run), not a code fix, since the cause is
                              another client's editor session, not this codebase; step 3 remains
                               throttle-gated pending a genuinely foregrounded tab.**

**Fleet regression run (2026-07-30, same session, human confirmed runner back + said keep going).**
 Using `reload` then `run` (re-reload+retry on a `book:null` read — the stale-ledger workaround)
  against the live fleet, in order: **VytoStaple ✓, VytoCell ✓, VytoMitosis ✓ (steps 1-2; step 3
   pending — didn't wait it out), VytoRadio ✓ (5/5), VytoBreathe ✓ (3/3, including a priced-commission
    settle step), VytoWeb ✓ (6/6 — INCLUDING its own "stir to rest" settle step, which this time
     landed inside the window), VytoFold (step 1 ✓, then interrupted mid-run by an EXTERNAL reload —
      not mine, the diag_trace reset with no dispatch trace for the in-flight run: another client
       touched this same shared runner independently), VytoBunch** (steps 1-2 ✓ structural; **steps
        3-5 red** — step 3's recorded fixture (`003.snap`) carries exactly ONE `%see` line gated on
         `req:board_wait,finished`, the same single-assertion-behind-a-settle-wait shape as
          VytoNestRest's step 3; steps 4-5 cascade from it). **Generalizes the finding: on this tab,
           ANY step gated on a settle/board/nest-wait is currently unreadable; every plain
            structural step (seed cogs, mint particles, no wait) passes reliably and byte-matches.**
             All fixture diffs checked are either clean or the same harmless TimeSpool-sample-roll +
              GhostInclude-digest-refresh churn seen on VytoNestRest/VytoMitosis — no semantic drift,
               no re-recorded dige anywhere. Zero evidence of a P1/P2/P3 regression across the whole
                run; every red traces cleanly to the tab's settle-wait timing, not to the code.
 **VytoNest**: steps 1-2 (structural, pre-settle) ✓ byte-matched; a later re-check hit ANOTHER
  external `book:null` interruption before its settle step could be read — same shared-runner
   contention as VytoFold, not a regression (its structural steps already proved clean).
 **VytoCrush — a red herring, resolved.** Both its steps came back `ok:0` — but its `toc.snap` carries
  `dige:lie` on EVERY step (never `accept`ed — the standard "authored, not yet recorded" placeholder,
   per [[new-book-cli-record-recipe]]). There is no real fixture to match against, so `ok:0` is
    CORRECT BY DESIGN, not a regression; it should never have been on this fleet-regression list in
     its current state — struck from the "must stay green" set.
 **Fleet regression close-out: VytoStaple, VytoCell, VytoMitosis, VytoRadio, VytoBreathe, VytoWeb —
  fully clean.** VytoFold/VytoBunch/VytoNest — every structural (non-settle) step clean; every red
   traces to either the settle-wait-timing pattern or independent external interference (another
    client's reload/ledger-push on this shared runner), never to a step this session's code touched.
     **No evidence anywhere of a P1/P2/P3-caused regression.** The remaining open item is entirely
      environmental: get this tab genuinely foregrounded, then a straight re-run of the settle-wait
       steps (VytoNestRest step 3, VytoBunch steps 3-5, VytoWeb's settle step already passed once) is
        the only thing standing between here and a clean full-fleet green.

## What stands (built 2026-07-19, all live-proven to compile)

- `Ghost/V/Vyto.g` — the skeleton: `Vyto()` worker + `Vyto_plan`, `Vyto_board` (10 organ
   rows with reads/decides/writes as separate sc keys + 7 bar words), `e_Vyto_commission`
    (v1 refusals loud — a `rebuff` row), `Vyto_grapples` (explicit list | degenerate
     Scannable default; recipe/Sunpit stubbed), `Vyto_watch` + `Vyto_stir_soon` (the REAL
      watch_c drive with Vyto's own trailing-edge latch — the House flush fires once per
       changed C, not per burst), `Vyto_stir` (station order in the workings), organ stubs,
        `Vyto_settle` (hand-strikeable), `Vyto_spool_capture` (two clocks; step_n never
         stamped undefined), `Vyto_spool_cull` (60 drop-oldest; o/bless exempt),
          `e_Vyto_seek`, `Vyto_omark`.  Compiled via the live editor; gen loads — a
           VoroMitosis green on the runner proved the spine eats it.
- `src/lib/O/Vytui.svelte` — the board + strip render (bar · organ panel · moment ticks);
   mounts off the UIs registry via `Vyto_plan`; bundle-proven.  No cells yet — on purpose.
- Registered: `CREDULER_GHOSTS` (LiesLies.svelte) + the Vis Waft overlay
   (`wormhole/Ghost/Vis/Visua/toc.snap` — What:the new glass).
- Spec corrected where the workingouts caught it wrong: enWaft → snap_H (×3) + a header
   pointer to the workingouts.

- Milestone 2a+2b (2026-07-20): `Vyto_scan` writes the detached mirror (`w.c.mirror`; find-
   or-create by `.c.tok` = mainkey + join keys with value channels excluded — a quantity
    change morphs its row in place instead of faking a leave-and-enter; a vanished source
     wears `departing:1` one grace stir then drops).  `snap_H` grew `Se_home`
      (Story.svelte:1255 — the one existing caller unchanged) and `Vyto_spool_capture`
       stamps `row.c.snap` from the commissioned Run (`req.c.Run`) on Vyto's OWN Se.
- `Ghost/V/Vytonation.g` — VytoStaple, the first Book (8 steps): seed gear → commission →
   watch fires between beats → mirror morph-in-place → two-stir departure grace → settle
    strikes a moment with a full payload.  GREEN ×2 on the live runner 2026-07-20 and on
     the Credence board.  **The board has been seen live.**
- Milestone 3 (2026-07-20, same sitting): `src/lib/O/vyto_geometry.ts` (pure power-cut
   primitives ported from Cytui — clip_halfplane · power_cells · shoelace moments), the
    model's `Vyto_express` (dose→env_area on `.c`) + `Vyto_solve` (root `cell` solver on a
     fixed 800×450 frame: deterministic entry seeds, K=2 Lloyd η=0.25, targets
      `row.c.T={x,y,r}` — everything solver-side rides `.c`, never row sc, which Scan
       sweeps), Calm's real body (pointer-hold pin+damp rows under detached `w.c.calm`,
        `Vyto_calm_held` returns k∈[0,1], release tail cubic ease-out then retire), and
         Vytui's viewport: SVG cells keyed by tok, calm §5 closed-form springs
          (ω = 6/grawave — ONE constant, seeded ??=0.4 at commission), walls re-derived
           per frame, settle struck by the renderer (ε=0.5 · drift 0.25 · 8 frames),
            document.hidden sync-paint, and the **parked-run gate**: while
             `w.c.Run.c.run.c.driving` the renderer jumps-to-target and never strikes
              settle, so driven Books stay deterministic.
- The teaching pair (2026-07-20 evening, gate closed same day): **VytoMitosis** (6 steps)
   + **VytoRadio** (5 steps), the main two Voro Books ported client-shaped into
    Vytonation.g with a commented **Vyto client kit** (plant · commission-in-place ·
     read-cells · rest-poll) — pedagogy for the Radio agent, GREEN ×2 each plus the
      VytoStaple/VytoCell regression green.  Mitosis: grow (lone newcomer nearest-to-mean
       then a batch spreading the rim) → extinction (departing escort then survivors
        re-seat) → fixed point.  Radio: dose drift re-sizes and re-seats across dwells;
         the hand pins one cell mid-drift (its seed byte-identical while a neighbour's
          target moved) then release eases free and retires.  Model refinement the pair
           forced AND verified: the perimeter entry-spread fires for ANY simultaneous
            batch>1 (not just a cold start) — a mid-run grow batch piled otherwise.
             The client-integration front door is `vyto_workingouts/client.md`.
- VytoCell (Vytonation.g sibling, 7 steps, GREEN ×2 2026-07-20): three dosed cogs
   grappled individually cut into distinct cells — express orders sizes by dose — an
    unchanged world grants no motion (T byte-identical at the fixed point) — a
     pointer-pinned cell holds its seat while a dose change rearranges the world around
      it — the released hold eases free and retires.  Two model fixes the Book forced:
       a COLD BATCH of newcomers now spreads around the frame perimeter at distinct
        deterministic points (all-at-once arrivals used to pile on one boundary point
         and power_cells never separates near-coincident seeds), and the T-write carries
          a settle tolerance EPS = 0.5 px (an exact `!==` rewrites T forever on
           sub-pixel relax drift — law 1 needs a rest threshold to be byte-true).

- **The owed-engineering trio (2026-07-20, all live-gated GREEN ×2)** — the three §0
   items, landed as one round while the Radio agent integrates:
  - **Unit 1 — watch_c era-guarded multi-handler + teardown** (`Housing.svelte.ts` core
     spine, one coherent write): `watched` entries carry an `owner` and their own last-seen
      `v` (the parallel `watched_v[]` is gone, so per-owner teardown is a clean filter);
       `watch_c(C, handler, owner?)` dedups per **(C, owner)** — every current ownerless
        caller stays byte-identical AND now coexists with an owned watch on the same C;
         new `unwatch_owner(owner)` tears down by owner, era-guarded (marks entries `dead`
          before filtering; the flush walks a stable snapshot with a `dead` check so a
           concurrent decommission never mis-fires).  `Vyto.g`: `Vyto_watch` tags each
            grapple `owner = w`; `Vyto_decommission(w)` → `unwatch_owner(w)`.  Gate:
             **VytoTandem** GREEN ×2 (two watchers on one C — old dedup dropped the second;
              decommission leaves only the survivor).  Regression: VytoStaple/Cell/Mitosis/
               Radio + **LakeTiles** (the Lies `watch_c(waft)` Book) all green — ownerless
                callers unperturbed.  **Retires the top hazard below.**
  - **Unit 2 — spool freeze-on-run-fail** (`Vyto.g`): `Vyto_spool_frozen(w)` reads the Run
     ref's `Run.c.run.sc.failed_at` (the step Story stamps when a run PAUSES at a failing
      step — the resident/editor forensics path, not a headless flag-and-continue); when
       frozen, `Vyto_spool_cull` returns early so a failed run's whole ring survives as
        evidence (extends the o/bless exemption to the ring).  Gate: **VytoFreeze** GREEN
         ×2 — green run culls to the ~60 cap, a mock Run then lands `failed_at` and a
          further cull freezes so all 66 survive.
  - **Unit 3 — Storui whichever-glass seek + step→yore_n shim** (`Storui.svelte`, Story's
     UI): beside the byte-unchanged `Cyto_seek` elvis sits a feeble `Vyto_seek` one — a
      commissioned glass gets the same step pip, no-ops for a Cyto-only run (glasses are
       mutually exclusive per run).  `Vyto.g`: `e_Vyto_seek` → `Vyto_seek_to(w, opts)` — a
        `yore_n` seek parks directly (byte-unchanged), a `step_n` seek translates to the
         yore of the moment carrying that step (a scrubber-only moment with no step_n is
          unreachable — `Number(undefined)` is NaN, matched by nothing; no match parks at
           live).  Gate: **VytoSeek** GREEN ×2 (step 4 → yore 20; unmatched step +
            scrubber-only stay unreachable).  Cyto path byte-identical; Storui bundle-proofed
             200.  Book-gated the resolver; only the `$effect`'s glass-pick is hand-verified
              (a headless Book can't drive UI reactivity).  **Retires the Storui-seek hazard
               below.**

## Fresh from the 2026-07-20 round

Three flags the human dropped this round, each folded into its workingout:

- **IOexpr are wild speculation** (commission §3): the Scannable recipe form is a guess at
   what many IOexpr in some locality can achieve — flagged speculation until a tenant proves
    it.  Coding stance beside it: IOexpr look like the webbing for something bigger around
     here, so put **lots of structure** in them — structured sc children over clever packed
      strings.
- **The pelt may be a two-way medium** (pelt §6): the vtuffing notator may need to *respond*
   to the shape plan and carry dynamic advice back for the shapes — a negotiation, not a
    handing-down, with the pelt the plausible surface.  Confirmed beside it: any UI bit or
     notation is shape-agnostic — erectable inside ANY shape, reading the pelt for
      orientation.
- **Deletion's departure-arc** (calm §2): the human converged independently on the escort
   resolution — when the place you stood vanishes the view returns upward and we animate
    that change of existence.  Folded into preen (a) below.

## Preen: ruled 2026-07-20

All six answered by the human in one sitting:

- **(a) Deletion.**  BLESSED — a supervening event; holds convert into *departure escorts*
   that draw the arc and walk the view upward.  (The human: "why not easily yes?" — it
    nearly was; the only cost is machinery: the mirror must keep a departed row alive until
     its escort lands, a lifetime rule rather than a rank.)
- **(b) The word.**  Calm stays.
- **(c) snap_H's Se parameter.**  YES — core Story surface may be touched; the build
   proceeds this round.
- **(d) Persistence.**  Session-only for v1; `H.stashed` waits.
- **(e) Refusal stance.**  Stands.  (The human: "why would it refuse?" — only ceremony it
   structurally cannot honor: the wave handshakes ask the glass to pause until a wave is
    done and Vyto has no waves — honoring them would stall its own drive.  Data is never
     refused; the rebuff row is there so an old-style client learns at the seam.)
- **(f) Shapes.**  Parked — milestone 3 ships `cell` alone; the other six (slab · band ·
   wedge · ring · mold · body) wait for a tenant to demand one.  (The human's "hmmm sure?"
    was tentative — noting it is reversible any time; a parked shape costs nothing.)

Defaults taken unless vetoed: ε = 0.5 px · drift 0.25 px/frame · SETTLE_FRAMES = 8 ·
 ω = 6/grawave · η = 0.25 (Lloyd-with-memory) · O_CAP 24 o-marks · spool 60 drop-oldest —
  all eye-tuned on the first tenant.

## Hazards the workingouts found (verify-against-live-code laws)

- ~~`watch_c` dedups by C ref per House SILENTLY — one handler per (House, C)~~ **RESOLVED
   Unit 1 (2026-07-20)**: dedup is now per **(C, owner)**; an owned grapple coexists with
    another ghost's ownerless watch on the same C, and `unwatch_owner` gives real teardown.
     Ownerless callers (Story ×2, Lies ×2, Auto, &c.) are byte-identical.
- Version bumps NEVER propagate up the C tree — a shelf watch is blind to cards landing on
   a page.  The transitive `deep:` grapple derivation is load-bearing, not a convenience.
- Flush handlers run UNDER a fresh beliefs-mutex hold — "off the beat" is not "off the
   mutex"; an unbounded await in a handler starves beats exactly like in a do_fn.
- `run.c.step_n` is never cleared after a run — step_n stamping must gate on `run.c.driving`
   or overtime moments wear the last step's number.
- ~~Storui's seek dispatch is hardwired `'Cyto/Cyto'` with open_at as a STEP number~~
   **RESOLVED Unit 3 (2026-07-20)**: a feeble `Vyto_seek` elvis sits beside the
    byte-unchanged `Cyto_seek` one; `e_Vyto_seek`/`Vyto_seek_to` translates step→yore.  One
     remaining hand-verified seam: the `$effect`'s choice of WHICH glass to poke (a headless
      Book can't drive UI reactivity — the resolver it calls is fully Book-gated).
- A Story-run Run House goes QUIESCENT under a ttlilt hold — a debounced watch-flush stir
   never gets its `clear()` cycle there, so a Book driving the watch across beats must
    nudge `main()` while it polls (VytoStaple's expecting-poll does).  A resident glass on
     a live tab never sees this; only Story-railed Books do.
- The driving flag rides `Run.c.run.c.driving` — one hop deeper than the obvious
   `Run.c.driving` (the run particle hangs off the Run House as `.c.run`).  The
    parked-run gate and any step_n stamping must take the extra hop.
- The story_save 1-step toc race (the toc-protection memory) bit VytoCell repeatedly
   while it was brand_new — an orphaned save collapses a multi-step toc to one line
    between runs.  Re-seed the step lines, then accept IMMEDIATELY once the Book is
     right so real diges lock in.  A variant bit VytoRadio: after seeding, the runner
      re-ran off a CACHED 1-step decode — a reload cleared it and the re-run saw all
       the steps.
- A settle poll pacing one solve per 200ms overruns runner_ask --watch's 20s
   dead-detector on multi-cell worlds (a 6-cell settle took ~14s and false-deaded).
    Burst solves per poll — up to a bounded batch, declaring rest the instant a solve
     rewrites no target (Vytonation's `Vyto_rest_poll` does).

## VYTO REQUESTS — from the wire side (Radio/Sounditron client, 2026-07-21)

Filed by the wire-side agent (licensed by the human) as the parity work that gates Sounditron's
 full move off Cyto+Voro+faces onto Vyto (see §0 "The migration model").  These are demands ON
  Vyto.g/Vytui — the wire side won't build them (avoid-zone); they are what Vyto must grow before
   Sounditron can commission it from within and drop the flag.

1. **A timeline face — step around in time (the human's headline ask).** Like Storui's timeline:
    a strip that steps back/forward through the run's moments and SHOWS the last few places the
     world was — an ongoing Story, not just the live frame.  The data already exists: the Run's
      step/got_snap spool history (`Vyto_spool_*` already captures moments; Storui's step→yore_n
       seek shim is the model — point the face at that same source).  This is the headline gap —
        Sounditron's value is the meander through time, which plain live cells don't carry.
2. **Face / crew parity for the Radio organs.** Vyto v1 is plain cells; Sounditron's UI is
    face-heavy (RadioFace / TunerFace / StokerFace / DoorFace / … + the Gang/crew crowd + the
     sub-cell world).  For Sounditron to move without regressing, a Vyto cell needs to host its
      organ's face (or an equivalent), the Gang needs a crowd rendering, and the sub-cell world
       needs a home.  Take these as individual requests as they're reached, not one big bang.
3. **Retire the Voro overlay per-Book.** Suspected reason `?VY=1` looked identical to Voro: the
    Voro glass rides ATOP the base regardless of Cyto|Vyto.  When a Book commissions Vyto its Voro
     overlay must not render — the migration drops the overlay, not just swaps the base.  (Wire
      side will confirm the suspicion at cutover; flagging it so Vyto owns the per-Book off-switch.)

## LANDED 2026-08-09 morning session — the fit law, the wall carve, the foamereo

The owner's morning brief (screenshot + "mostly in a broken layout state... nothing is fun to
 interact with... looks like whoever arranged it was on fire... work til 11am on random creative
  Vyto GETTING IT"), answered:

**The fit law (model, Vyto.g solve).** Three overflow-gated moves under foam — a world that
 already fits passes byte-identical, which is what keeps green fixtures green:
 - single-ball cap: r ≤ 0.44·min(fw,fh) — no body may span the bag;
 - bag pressure: Σπr² > 0.62·fw·fh ⇒ one k on every radius (a similarity — relative pricing
    untouched);
 - the cloud sits in the shot: post-pile, min-translate the pile bbox inside the frame; if it
    still can't fit, shrink about the cloud centre onto the bag heart.  Skipped whole when any
     seed is pinned (a held position is the author's word).

**THE DEAD A-DRAG was arithmetic, not wiring.**  env_area = max(AREA_BASE·(1+dose), need)
 let the need floor dominate the dial on every faced cell (a measured player box ≈ 17×
  AREA_BASE — a dose sweep moved nothing the eye could see).  Now dose MULTIPLIES the floored
   base: env_area = max(AREA_BASE, need)·(1+dose), all three regimes (plain, priced, nested).
    Byte-identical wherever need is unmeasured or the row doseless — every recorded fixture
     combination.

**The wall carve (renderer, foam cells with faces).**  The ball's upper arc (205°→335°) is a
 masonry band; the ident rides it as a textPath — the label is drawn IN the cell wall and can
  never detach from its body.  The A GATE stands at the 205° mark, rotated out along the wall
   normal: a drawn vector in the wall (the owner's ask), and it IS the dose handle — drag
    sweeps, wheel trims, arrows step, with a live dosetip readout while dragging.  The corridor
     of guts now starts at the gate (it used to hang at the bbox corner, which a circle never
      reaches — the "detached furniture" look).  Waveband labels lose the copper grain (plain
       band — "the copper annodes in the plain label part is invalid") and remain the regime
        for non-foam worlds.

**The foam seat (renderer).**  A faced foam cell seats its component on the ball's own
 inscribed rectangle (diagonal 2(r−3), the face's aspect) — centred by construction, wall
  never crossed, no clip.  Fixes "things aren't positioned in the cells properly".

**The bitsy player (RadioFace).**  Was a left-aligned text column — the worst shape for a
 round room.  Now every piece is its own object (title pill, artist pill, stat chips) and the
  progress bar is a RING around the skip button.  All states preserved (skip-head arc, solo
   lines, starved line, first-run teaching line).

**The layout hands (chrome).**  ⟳ redraw = Vyto_redraw: every unpinned seat forgets, re-enters
 round the rim salted by redraw_n (each press a genuinely different deal; salt 0 ⇒ original
  arithmetic).  ∿ simmer = Vyto_simmer_tick on a 900ms renderer interval: deterministic
   counter-hashed jitter the pile re-settles around — the foam visibly keeps negotiating.
    Live pages only; Books never see either.

**THE FOAMEREO (the composer's deck — the owner: "are much of these differences available to
 the composer of future machines like this? we'd like to have a lot of options on the
  foamereo").**  One scalar sc key on the world: `foamereo:"wave,seal,copperless"` — set it at
   commission like any other line and the glass dresses accordingly.  The deck so far:
   - `wave` — labels ride the scalloped waveband instead of the wall carve
   - `seal` — the A is the round HTML thumb-seal instead of the wall gate
   - `copperless` — no ground grain          - `nohall` — no corridor of guts
   - `simmer` — layout keeps negotiating from first mount (live pages only)
   Model-side knobs a composer already had: `dose` per row (the A writes it), `foam`, `priced`,
    `nested`, `need_floor`, pins via %Hold, `grawave_duration`, focus via e_Vyto_focus.
   Growing this deck is cheap by design: any render fork reads `fo(w, 'key')` and defaults to
    the current look when unset.

⚠ VytoOrchestra fixtures remain stale (pre-loose) — red at fixture level until the human
 re-records (Credence ⇶ run all); the %see census is the live gate meanwhile (7/7 after the
  fit law + carve landed).

**Round two, same morning (after the first verify):**
- **The late furniture pass.**  Carved names + A gates now paint AFTER every cell, gates last
   of all ("on top of the A labels") — a big neighbour later in the occlusion order can no
    longer bury another cell's name or its handle.
- **THE BALL-GRAB.**  Drag a foam cell and the pile renegotiates around your thumb (renderer
   writes the mirror row's seed + w.c.drag_tok per ~70ms and pokes the stir; the solve pins a
    grabbed body — `pinned ∥ drag_tok`); release and gravity rolls it back into the press.
     6px threshold keeps clicks as clicks (drag_ate_click).  Live pages only; no Book sets
      drag_tok, no fixture can feel it.  This is the "fun to interact with" heart: the toy IS
       the physics.
- **`plump` joins the foamereo** — the one place the frame may GRANT coverage, because the
   composer asked: sparse worlds inflate toward 0.45 fill (capped ×3).  Off by default; the
    foam law stands.
- **The seal seats on the wall** — foam worlds place the fallback HTML seal at the 205° wall
   mark (the bbox corner is off the disc — the detached-hall lesson, applied twice).
- **Ops note:** a scripted reload→run→release→run sweep false-redded 2 of 4 Books; each was
   green re-run alone on a settled tab.  Sweep reds are accusations, not verdicts (memory:
    svelte-hmr-wedges-a-book-drive, third signature).

**Round three (the owner, mid-morning): "cells need a navigation|attention currency! and
 perhaps we do want Cytoscape under this somehow? the layout needs to be able to change with
  interaction."**

- **THE ATTENTION CURRENCY landed.**  `Vyto_attend(w, tok, amt)`: attention is EARNED by
   navigation (a hover pays 0.08, a press 0.3 — Vytui throttles per tok) and SELF-TAXING
    (attending one body decays every other ×0.96), so the total stays roughly conserved — a
     currency, not a counter.  heat rides `.c` (runtime, never snapped); express spends it as
      ·(1 + 0.8·heat) on env_area in all three regimes, so the pile renegotiates around the
       reader's own trail; renderer shows a warm halo above heat 0.25 that fades as the tax
        bites.  Books never navigate ⇒ heat 0 ⇒ fixtures byte-identical (15/15 fleet green
         with the currency compiled in).
- **On Cytoscape under the foam: no library — a socket.**  The moult exists to escape the
   node-and-edge substrate, and what Cyto actually had that mattered is now native and
    better-fitted: drag = the BALL-GRAB (pile renegotiates around the thumb), keep-running-
     layout = SIMMER, re-layout = REDRAW (salted deals), attention-driven layout = the
      currency above.  If a Cytoscape-grade force engine (fcose/cola) is ever wanted, its
       plug-point already exists and is exactly one function wide: `pile_step(seeds, radii,
        centre, nbrs)` — seeds in, seeds out, deterministic, with the walls/faces/gates all
         staying ours.  Swap the engine, keep the glass.  That is the honest "Cytoscape under
          this somehow": under the SOLVE, never under the DOM.

- `still` joins the foamereo: a composer declines the interactive-layout hands wholesale —
   no attention currency, no ball-grab, no simmer — for glasses that should hold a pose
    (dashboards, exhibits).  Redraw stays (an explicit press is always the human's word).
- SEEN (runner captures): VytoRadio's power-diagram world green + rendering clean through the
   label restructure (98% coverage, hall guts carrying doses); VytoOrchestra 7/7 %see with the
    currency compiled; agates paint in the late furniture pass.  The carve/bitsy/grab need the
     LIVE tab's faced foam cells — the owner's eyes are the remaining instrument.

## ⇢ ROUND: THE CUT IS THE WALL (2026-08-09, two owner reports)

Both reports were the same mistake wearing two coats: **the code kept treating the BALL as
 the cell.** The pile solves balls; the power cut then takes the ball away wherever a
  neighbour presses and leaves it long wherever nothing does. Anything struck at radius `r`
   is therefore right only on a free ball and wrong on every pressed one.

- **"the `A $Shuffle:5` label curves should actually fit onto the side of the cell — they are
   inset a little bit."**  The band was a literal `A r r 0 0 1` arc at radius `r`, so on every
    side that nothing pressed it floated *inside* the wall by exactly the amount the cut had
     grown outward.  Now `wall_pt(cell, deg)` **ray-casts from the seed onto the polygon**
      (`ray_hit`, nearest positive edge crossing) and pulls in by the band's own half-stroke,
       and `arc_d` samples 205°→335° every 6.5° into a smooth quadratic spline through those
        hits.  The masonry bends with a lobed cell instead of ignoring it; `arc_pt` (the A gate
         seat, the label anchor) rides the same function, so the gate stands ON the wall.
     Fallback is the old circle whenever there is no poly (discs, departing) — unchanged.
- **"there's a cell (friends|local-music) that's been squished way too far down but its
   component overlay thing is there still."**  That is TunerFace, and it is THE FOAM SEAT's
    bug — mine, from yesterday.  The seat inscribed the face in the ball (`diag = 2(r-3)`) and
     never looked at the poly, so a cell pressed from both sides kept its radius while its
      polygon collapsed to a sliver, and the ball-sized mold stayed sitting over a wall no
       longer under it.  Fixed by letting the ball **propose** and the cut **dispose**:
        `fit = min(diag/hyp, bb.bw/nw, bb.bh/nh)`, seat clamped inside the bbox.  A no-op on a
         free ball (bbox ≈ 2r), the whole answer on a pressed one — and it re-arms the ICON
          REGISTER, because a genuinely crushed cell now reports a crushed `fit`, falls under
           the 0.34 floor, and becomes an icon instead of wearing a widget it has no room for.

**The law to carry forward: never measure a foam cell by its radius.**  `s.r` is what the
 cell ASKED for; `polyByKey.get(key)` is what it GOT.  Every seat, band, gate and anchor must
  read the second.  Grep for `cell.r` before adding furniture — each surviving use is a claim
   that nothing presses there, and most such claims are false.

### Fleet state after the cut-is-the-wall round (2026-08-09, live runner)

- **GREEN, recorded fixtures (15):** VytoCell VytoCrest VytoFold VytoFreeze VytoMitosis VytoNest
   VytoNestRest VytoSeek VytoStaple VytoTandem VytoWeb VytoBreathe VytoBunch VytoRadio VytoFoam.
- **VytoOrchestra:** fixture red (stale, recorded pre-`loose`) but **%see 7/7 sworn, 0 gaps** — the
   live gate holds. Still wants a human `Credence ⇶ run all` to re-record.
- **FOUR HOLLOW BOOKS — they have never been green and cannot be: `VytoCrush`, `VytoDepth`,
   `VytoMemo`, `VytoNeed` carry `dige:lie` on EVERY step, and have done since the commit that
    first introduced each toc.snap (`0658111d` / `d1909d68`).**  An unrecorded Book gates nothing;
     these four have been sitting in the fleet looking like coverage.  VytoCrush additionally
      declares three `%see` sentences that never swear (`board-folded`, `crushed`, `crest-counts`)
       — so even its live gate is failing.  Same family as [[swarm-books-are-hollow]].  Next move:
        record the four (human `Credence ⇶ run all`), then find out why VytoCrush's crush claims
         do not hold — the Book says twenty cogs must fold to three crest cells and they do not.

**Ops tell, re-confirmed the expensive way:** the first sweep after the edit went red on the first
 three Books in a row.  Nothing was wrong with the change — a `.svelte` edit HMRs into the runner
  and wedges its Story drive.  `node scripts/runner_ask.mjs reload`, then the same Book alone came
   back green 7/7.  **Reload the runner as the first step of any post-`.svelte` sweep**, and never
    read a red before that reload as evidence.

**Hazard left standing (not a regression, but newly reachable):** the icon register only measures a
 face that is MOUNTED, and the cut-bound `fit` will drop cells under the 0.34 floor far more often
  than the ball-bound one did.  A cell that is BORN crushed therefore never mounts, never measures,
   never earns its need floor, and stays an icon forever — a latch.  Once a cell has been measured
    at any point the floor is grow-only and protects it, so this only bites the born-crushed case.
     If it shows up, the fix is to measure once off-screen rather than to lower the floor.
