# Voro_todo — the stained-glass grind list

Task list for the Voronoi luxury layer. Written to be picked up COLD, one task at a
 time, by a session that has not read the whole arc. Read **The metaphysics** first;
  every task below must leave it intact — a pretty result that violates one of these
   rules is wrong work, not partial credit.
 The arc + bombs: `Radio_scape_handover.md`. The durable spec: `Radio_spec.md §8`.

## The metaphysics

1. **Cyto is the layout engine; Voro is an interpretation of its result.** fcose decides
    where the chunks sit; cells, walls, moldings are derived pixels. Pixel geometry never
     pushes back into the layout — ZERO exceptions. (The rack — equipment nodes
      column-packed at the right edge — used to be the one sanctioned exception; it is
       SHELVED behind `RACK_ON = false` in `voronoi_layout()`, kept as the seed of a
        future in|out-group process option. The oddballs just sit where fcose put them.)
       The cautionary tale is `size_stuff_node()`'s voronoi guard: growing a node
        from its own cell's size is a feedback runaway.
2. **Nothing render-side is ever snapped.** c-side (`n.c.*`) or component `$state` only;
    no `%keys`, no `sc` writes, no wave participation. A Book underneath must never be
     able to see the render (the Leaf* Books keep checking Cyto basically works). Free
      self-test: if any Story fixture diff appears from your change, you broke this rule.
       If your design seems to need a snapped flag — stop, the design is wrong.
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

## The tasks

Grades: **GRIND** = mechanical against this brief; **GRIND+** = needs local judgment;
 **DESIGN-FIRST** = write a short design note and get it agreed before code.

### 1. Wrap width from the cell — GRIND+

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

### 2. Angle: a long cell wants a long Stuffing — GRIND+

The molding T is symmetric today — a deliberate no-rotation choice so text never
 tilts. Relax it a LITTLE: rotate the Stuffing toward the cell's long axis φ with hard
  legibility caps — |angle| ≤ ~20°, snap to 0 below ~8°, never past vertical (text
   must never read upside-down).
- Where: fold the capped rotation into T (T11/T12/T22 stop being symmetric — that is
   fine, `box_support()` already takes a general T, so the fit stays correct for free).
- Do after task 1; angle without re-wrap just tilts a wrong-shaped box.

### 3. Fold colour by dominant kind + fold-count size — GRIND

The crusher already returns the dominant child mainkey (`kind`) and the fold count.
- Colour: a fold's cell should carry its dominant KIND's colour, not the fold node's
   own border colour (see the `color:` pick in `voronoi_layout()`). Look the kind's
    Matstyle colour up READ-ONLY (metaphysics §5) with a palette fallback.
- Size: let the fold count accentuate the seed weight (a bigger family claims a bigger
   cell) — a gentle log scale on the hw/hh floor, c-side only.
- Both stats are live returns from `Voro_crush_scan`; if they need to ride to Cytui,
   they ride on `.c`, never `.sc`.

### 4. Family outlines: the w/** hulls — GRIND+ (toggleable)

Outline all the cells of each direct child of w — e.g. everything under `Pier/**` gets
 one shared outer outline — but only for families with real structure: at least
  `w/*/*` depth, where a `%witnessed` child does NOT count as structure.
- Approach: cells know their particle; group by ancestor-directly-under-w. The union
   outline = the walls whose cutting neighbour (in the half-plane clip) is OUTSIDE the
    family or is the frame — extend `clip_halfplane` to tag each edge with its cutter's
     id, then trace the untagged/foreign-tagged edges per family into one faint second
      stroke (distinct colour per family, well behind the cell strokes).
- A ◈-bar toggle, stash-remembered (`Cyto_families`), metaphysics §4.

### 5. Crush harder: group the un-same — GRIND+ (crusher policy, .g work)

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

### 6. Composite shapes: layout WITHIN a cell + zoom-recursion — DESIGN-FIRST

Can the composite shapes be custom — i.e. lay a fold's members out INSIDE its cell (a
 microcosm: mini grid or mini force pass in the cell's own frame), instead of one flat
  Stuffing? And effortless zoom-recursion through any: zooming into a cell swaps its
   Stuffing for its microcosm, progressively, without the C tree ever changing (the
    crushed children are all still in C — the crush only suppressed Cyto's descent).
- Carve: (a) static grid microcosm in a cell, (b) zoom-threshold swap Stuffing ↔
   microcosm, (c) recursion (a microcosm member with its own fold gets its own cells).
- Write the design note first: coordinate frames, when the mini-layout runs (settle
   only), and how it stays inside the budget self-heal.

### 7. Scroll = pinch|spread the locale — DESIGN-FIRST (toggleable)

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

### 8. The SVG-native Stuffing rebuild — DESIGN-FIRST (the big one)

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
