# Vyto — the working doc

The new glass.  Spec: `Vyto_spec.md` (unpreened — three rounds 2026-07-19).  Machine-level
 elaborations: `vyto_workingouts/` — shapes · pelt · calm · spool · commission · client · processes,
  each checked against the LIVE code (not against the spec's hopes), most ending in open
   questions only the human can rule on.  This doc is the one todo; the workingouts are
    its appendices.  **`client.md` is the front door for anyone integrating as a Vyto
     client** — point a fresh agent there first.

## 0. What to get on with next

The arc: **wear the words in ✓ → give the glass eyes (Scan) ✓ → give it a memory (Spool) ✓
 → give it a body (the first cell) ✓ → hand it the abdomen (the Radio world as first
  tenant)**.  Milestone 3 landed 2026-07-20, same sitting as the rulings: the model solves
   a real power cut into targets, Vytui springs cells toward them and strikes settle
    itself, and VytoCell recorded GREEN ×2 beside a green VytoStaple regression.  Next
     moves:

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

### The build plan — P0→P7, each Book named BEFORE its code (LAW B)

- **P0 — name the constant.** `AREA_BASE = 2400` once; five literal sites (ledger #7) read it.
   No new Book — full fleet green + byte-identical IS the proof.
- **P1 — `VytoMemo` (perf §1).** Memoize each scope's walls keyed on (seeds ⊕ radii); skip the
   re-cut unchanged; a SETTLED world derives no walls at all. Probe counter on `w.c` (off-snap).
   `%see:'a settled glass cuts no new walls across a held minute — the memo holds'`
   Adversarial: break the memo key → red. Witness: two `--svg` shots 5s apart byte-identical.
- **P2 — `VytoNeed` (the need floor — HUMAN call 1).** Post-mount Vytui measures `face-scroll`
   natural `scrollWidth/Height` → viewBox units (×800/stage px) → `row.c.need_area` (`.c` never
    `sc`) → `Vyto_express` floors `env_area = max(algebra, need·1.15)`. Grow-only within a
     settle (no flutter).
   `%see:'the fat face cell grew to hold its measured content — the need floor is honored'`
   `%see:'a doseless label cell stays byte-identical while the floor is armed'`
   Adversarial: neuter the floor → red. Witness: shot greps the fat cell's area ≥ its need box.
- **P3 — `VytoDepth` (perf §2).** Scale child radii by √(parent cell area / frame area) in
   `Vyto_solve_scope` (or Σ child ≤ parent); the `parent.c.misfit` stamp (`Vyto.g:959`) already
    waits to assert on.
   `%see:'six children tile their small parent with no crowd-out — depth scaling holds'`
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
