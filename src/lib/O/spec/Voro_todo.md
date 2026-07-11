# Voro_todo — the stained-glass grind list

Task list for the Voronoi luxury layer. Written to be picked up COLD, one task at a
 time, by a session that has not read the whole arc. Read **The metaphysics** first;
  every task below must leave it intact — a pretty result that violates one of these
   rules is wrong work, not partial credit.
 The arc + bombs + frontier live in **§0 below** (rewritten each handover). The durable
  spec: `Radio_spec.md §8`; the system doc: `Voro_vtuffing.md`.

## 0 · Handover  (rewrite this section each handover; everything below stays current)

**THE ARC in one breath.**  The Voronoi layer turns the live Cyto graph into stained glass: the
 crusher (`Ghost/V/Voro.g`, c-side stamps only) folds MANY+homogeneous behind `%stuff`, and the
  ▦ engine (`Cytui.svelte`) makes every pane SPEAK its particle — honestly (nothing hidden, every
   fold annotated), generically (no data key special anywhere), in one grammar (the VStat
    statement), laid out radially (the kind-C at the core, its facts on the belt, its members
     around the rim — the owner: *"like a cell-wall around its nucleus"*).  DESTINATION: the
      radial rule RECURSES — cells within the cells, a popped member repeating the same core→rim
       slope one level down, asymmetric walls carrying the finer hierarchy cue, the `+N` fold
        marks becoming expandable DOORS — until the glass is the primary face of any C** at any
         depth.  The faces we evolve through are SAVED: `voro_modes/README.md` (a ledger of all
          six passes — commit anchors + live SVG shots; revive any face via
           `git show <commit>:src/lib/O/Cytui.svelte`).

**WHERE WE ARE (2026-07-11, committed `063fb214` — face 6, "the gem", owner-liked).**  Six ▦
 passes in one day, each an owner redirect; full records per pass in `Voro_vtuffing.md` §🎋 v2:
  flat cut → tuple regions + veins → nucleus + spokes → pipeline (crush BEFORE scan; ▤ deleted)
   → uniform glass (every pane speaks) → **honesty + radial**: loners tessellate their whole sc;
    `+N` corner marks count everything crowded out; `%` deleted from the render (it prefixes
     KEYS — hot dotted underline is the poppable cue now); the nucleus weight floors at 0.34·R
      so meaning hierarchy = visual hierarchy; members ring the rim from the kind's vein bearing
       under a radial kind-hue gradient (the slope made visible) with `Track ×N` engraved on the
        rim; one-value regions say `year: 2007` as a unit; the key is a SEED in many-value
         regions (overlap impossible by construction); every glass text is a VStat fitted by
          `fit_stat`/`fit_ident` (sheds grammar before the name) and rendered by ONE `vstat`
           snippet with per-line textLength stretch 0.9–1.45×.  Fleet green ×5: VoroScape 6/6
            c0 ×2, VoroMitosis 11/11 c10 (its norm), VoroRadio 9/9 c0, VoroClinic 9/9 c0,
             LeafFarm 30/30; SVG-verified zero text collisions.  Render-only — nothing snapped.

**NEXT MOVES.**
 1. **Owner eyes-on the gem:** does core→belt→rim read?  Gradient loudness, ring-engraving
     placement, the `+N` marks (annotation now — a DOOR/spill/zoom later, once Wes-Wilson is
      declared done), stretch taste at the 1.45× cap, and the transient mid-run `%see` pane
       (its wrap engine is the ported proven one, but its face went unshot — steps run ~1s).
 2. **🎋 v2 next layer — cells within the cells** (owner-announced): the radial rule IS the
     recursion rule.  Recurse it into popped members / large member cells; asymmetric WALLS as
      the finer hierarchy-slope cue (the gradient is the coarse version); expand-in-place;
       morph-stable sub-walls.  Don't skimp on thinking.
 3. **~~Re-add the rollback casualties~~ DONE 2026-07-11, live-proven:** F7 `diag_check` + `vlog`
     render telemetry re-grafted into Cytui from the parked WIP (secured to
      `spec/voro_modes/Cytui.wip.2026-07-10.svelte.txt` before /tmp could eat it).  VoroMitosis
       11/11 c10 + VoroScape 6/6 c0, fixtures untouched, and the `--why` film strip came back
        LIVE with `♒ diag cured ×1` — F7 fired and self-cured on the proving run itself.
         Details: `Voro_render_faults_todo.md` §STATUS.  Eyes-on the cure quality still counts
          as part of move 1's pass.

**OPEN ITEMS carried forward (older layers, still true).**
- **VoroRadioPier** (the Pier-fed radio Book, built 07-08): live-smoke-verified, all three
   `%see` fire, fixtures NEVER RECORDED — record with eyes on; busy at level:L2/visible=21,
    maybe dial station|track counts first.  Registered brand_new in Credence.
- **Seed→cell→mold agenda #13/#14/#12-rest** (`Voro_vtuffing.md` #10–14): #14 cell-quality
   relaxation is the pilot for the owned-integrator branch (fcose demoted to seeder) — the
    program-via-graph frontier.  #11 wave cadence, #12b HMR diagonal, #10 snake landed 07-08.
- **VoroMitosis extinction `%see` is LATENT** (never gates green — a later split reclaims the
   freed genus name); decide sticky-death vs drop, someday.
- **📻🕳 + bamboo-v1 schematica SHELVED** (`DRIFT_MODES_ON=false`; `Vtuff_bamboo_on()` hard
   false) — to be reimagined as their own endeavour; one flag reopens each lab.
- The fold is a VIEWER (`The/Opt/useVoroCyto`, imposed at snap time; Books stay Voro-blind;
   DATA vs FOLD Book taxonomy).  Design: memory `voro-imposed-from-above`.

**BOMBS.**
- Verify ONLY via the live runner (`runner_ask.mjs`); a headless Story_cli green is a bubble.
- A `--runner=` pin dies when the human closes that tab; NEVER accept/release a run you didn't
   start (client e63cdcca is the SHARED CLI identity — it proves nothing about whose run it is).
- git-diff a Book's toc.snap before dispatch (an orphaned save can collapse one to a skeleton).
- Never HMR mid-run; a wedged runner decodes EVERY Book total:1 (a Prep-only GREEN bubble).
- runner_shot `--runner=` takes a RAW relay addr — court via runner_ask first, use the sticky.
- The metaphysics below stand: pixels never push layout; nothing render-side snaps.

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
- Design notes: `Voro_microcosm.md` (task 6 — (a)+(b) built), `Voro_pinch.md` (task 7 —
   built), `Voro_vtuffing.md` (the microcosm cards grown into the pane-content ENGINE —
    Vtuff_build's layout C** + the chord fit + the /*N pop-out surf, built 2026-07-06),
     `Voro_svg_stuffing.md` (task 8 — the cross-wall alignment LAYER ON vtuffing, NOT a
      rival rebuild; Vtuff_build IS its row model, the unbuilt part is the shared-wall
       matching = vtuffing agenda #9; await agreement).

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

`Voro_microcosm.md` carved it; the owner's eyes-on verdict on the v1 card grid
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

`Voro_pinch.md`, built as designed after the owner's green light: 🌀 on the ◈ bar
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
