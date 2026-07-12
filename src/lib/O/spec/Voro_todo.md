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
           (#19 region NOW LANDED + live-gated; #29 loner still lack-marked — needs a model cut).
 - **③ Cytui consumes the model.**  Cytui shrinks to wiring + paint: it READS the grasp's model
    (membership, order, loudness, drift) instead of recomputing it.  Today `region_of` /
     `river_order` / `family_trait` (Cytui) still hand-roll it render-side — this wave makes them
      readers off `w.c.voro_model` (via `src.c.D` — see §The data-path crux).  // < wave ③ NOT
       started; the readers still recompute.  This is where **the Loud share-count inversion** lands:
        the model reads the rep's word rows, not the members, so a share count like `vein` 3-of-12
         is LOST — the fix is the model pooling member facts ITSELF instead of the rep's word rows.
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
     VoroScape, VoroRadio, VoroRadioPier, VoroClinic) are STALED by the language cut — steps 2-4
      diff by design (the fixtures at HEAD predate the cut).  **VoroTest ALSO grew 3 Examples + 5
       `%see` this round** (CredRunner surprises [2,3,4]) — the re-record covers those too.  Re-record
        with eyes on, on a live runner; the human owns this.  `Seen_split_todo.md` (the human's parallel
         `%seen`-latch + assertion-roster build) is meant to make these re-records survivable — x-ref it.
 3. **Then wave ③** — turn `region_of`/`river_order`/`family_trait` into model readers + land the
     Loud share-count inversion.

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
- **VoroRadioPier** (the Pier-fed radio Book, built 07-08): live-smoke-verified, all three
   `%see` fire, fixtures NEVER RECORDED — record with eyes on.  Registered brand_new in Credence.
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
    mainkey-distinct gangs into two regions, read off-snap via `VoroTest_model_of`).  ⏸ #29 (loner)
     STILL LACK-MARKED — needs a small model cut (persist member-facts / +N overflow), NOT guessed.
      Next cold session: the #29 model cut, or re-record the batch-1/batch-2 fixtures live (owed).

**THE ORDER** (roster numbers): #6 swarm — FIRST resolve its lack-mark (is same-mainkey-varying-
 value already mix's gang path? prove the difference with a dataset or mark it covered) → #7
  under-w gang census (model part only, no bond edge) → #18 genus/clade discovery — NOTE this one
   tests the GOVERNOR, so crush it UNPINNED (no `fixed` level) with ≥16 leaves so escalation is
    deterministic; every other Example stays pinned L2 → #19 botanical families ✅ (the `region`
     secondary property groups sibling folds; gate region equality across them — live-gated) → #29 loner
      nothing-dropped (off-snap model holds EVERY sc fact of a bare loner — gate member-facts
       count vs sc keys via `VoroTest_model_of`) → #28 census-storm identity-stable emission
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
15. **a Pier-fed library dribbling in** (`Voro_vtuffing.md` owner-vision "dribble in"; VoroRadioPier).
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
29. **a loner showing ALL its ugly bits** (six-pass sixth, owner). *"I want all ugly bits of eg %req
     included, no hiding stuff"* — a loner tessellates its whole `sc`; folds are annotated + a `+N`
      fold mark counts everything crowded out.  [model] for "nothing dropped silently"; [eyes] for glass.
     **// < NOT gated — needs a model feature (2026-07-13):** the off-snap model does NOT persist a
      member's raw facts — it uses them for axis/loud then discards, and `Voro_model_loud_from` CAPS at
       K=4, so a loner with >4 facts silently drops the tail.  A family of one is also not projected to
        the snap (n<2).  So "nothing dropped" isn't gateable off the model as-is; it needs a small model
         cut (persist a loner's facts + a `+N` overflow marker) before a `%see` can prove it.  A bare
          loner also grows no Vtuffing (the "tessellate its whole sc" is [eyes], Cytui's properCellable).

**Coverage note (2026-07-13):** the bench now holds 10 shapes (✅: flock, mix, motley, gradient, groves,
 edges, **swarm**, **genus**, **popped**, **families**); with #14/#28 gated on `flock`, the [model]
  fill-out landed #6 #14 #18 #19 #23 #28 this round (#19 live-gated on :9091).  #7 model-part is covered
   (its bond edge is [eyes]); #29 alone stays lack-marked (needs a model cut, see above).  The roster
    totals 29; the remaining [model] shapes want Pier/radio machinery (#15/#22/#26) or the deferred #29.
     The [eyes]-only shapes are
     proven by `runner_shot`, never a fixture.  Add a shape by the `[testing-is-story-books]` +
      `[see-assertion-layer]` rules (a CHECK run then manual `%see` install, never a CredRunner ACCEPT).

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
