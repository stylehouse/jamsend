# Seemables_todo.md — %Seem, and the campaign that got parked

`%Seem` is the machine's awareness primitive: a second tree that mirrors a first one and reacts to it,
 carrying identity across beats so survivors / arrivals / departures fall out for free (the
  `Selection.process()` the editor already thinks with). This doc used to be a campaign to hunt down
   every hand-rolled diff in the codebase and replace it with a Seem. That campaign is **parked**. The
    living plan is now at the top; the survey is kept below as reference.

---

## 0. What to get on with next

**The harvest is PARKED — don't go replacing Se-like code.** The human's call (2026-07-12): the future
 of `%Seem` is a **first-class interface for writing NEW algorithms**, not a broom for sweeping up old
  instances of hand-rolled diffs. "Distill a new interface for coding algorithms rather than run around
   replacing all these instances of Se-like stuff." So: no more converting §1–§8.

**What's live now** (proofs the organ composes, NOT certified): three read-only mirrors stand beside
 live code, each re-derived from an INDEPENDENT source so it can genuinely disagree with its twin —
  `Voro_census_mirror` (`Ghost/V/Voro.g:601`), `Stemdex_seem_mirror` (`LiesFunk.svelte:1527`),
   `Lang_graft_seem_mirror` (`LangGraft.svelte:422`). They stay in the tree. The human reports they
    "seem to work" live; none has a Book `%see` gating it yet. Leave them as standing proofs; don't
     flip any consumer to read them without a live gate.

**The real next move** is the Voro engine, where `%Seem`-as-interface is actually being built: the
 grasp becomes the thing that computes the render MODEL (membership / semantic order / loudness /
  drift), snap-testable in a Book without pixels. That work lives in `Voro_render_todo.md §0` (the
   three-layer engine) and the incoming VoroTest Book (`Ghost/Story/Voronation.g`, another agent). If
    you came here looking for "what to build with Seems," go there — this doc is now mostly the WHY and
     the reference survey.

**Two bombs that outlive the campaign** (true whatever you build on `%Seem`):
- **A mirror must diff an INDEPENDENT source, or it proves nothing.** The first three prototypes each
   read their target's OWN output — tautological, breaking in lockstep, unable to disagree. The fix was
    to stash the subject BEFORE the hand-rolled pass touches it and Seem over that. If a mirror's
     `pairs_fn` ends up consulting the very flag the twin sets, it is theatre — reject it. (This is what
      the 2026-07-12 adversarial pass caught before a runner cycle was spent.)
- **`Housing.organise()` and the req machine are NOT candidates — they are the EXEMPLARS.**
   `Housing.organise()` (`Housing.svelte.ts:1038`) already IS a Seem consumer; the req lifecycle
    (`finish`/`all_finished`) compares to no stored previous, so there is no diff to harvest. And raw
     `.c.*` COUNT is a false proxy for the smell — async-lifecycle scaffolding (IO memory, mount
      handles) WANTS to persist. The smell is *re-derived-each-beat* `.c.*`, not `.c.*` per se.

---

## The arc — Seem as an interface, not a broom

Three of the human's standing complaints are one gap: *"too much scattered `C.c.*`"* (transient flags
 smeared across particles, wiped and re-stamped every beat), *"you're not making large enough concepts"*
  (a fold, a diff, a census exists only as scattered bookkeeping, never a THING you can hold and name),
   and the same **last-beat-vs-this-beat** diff re-implemented in organ after organ. `%Seem` closes all
    three at once: the scattered flags come home to the D node, the concept becomes a sphere you hold,
     and the diff falls out of `resolve()`. That much has always been true and is not in doubt.

**Where the campaign went wrong, and where it landed.** The instinct was to treat that as a to-do list:
 find every place a diff is hand-rolled, and cash it in for a Seem, ranked by value ÷ risk. A survey
  found eight (below). But deep-designing and adversarially reviewing the top candidates taught the
   lesson that reframed the whole thing: **the survey nailed the SMELLS but oversold the WINS.** The two
    "big" targets shrank on contact — Story's `snap_H` seam turned out to be an additive DISPLAY-only
     win, not a gate conversion (the string gate is load-bearing forever); Cytui's `morph_voronoi`
      turned out to be reading a diff Cyto already resolved, so a Seem there would double-resolve. And
       the three read-only prototypes were tautological until rebuilt against independent sources. Every
        conversion cost a runner cycle to prove, and half of them proved "leave it alone."

So the human drew the line: **stop replacing instances; make the primitive a better place to WRITE
 algorithms.** The three mirrors that survived stay as proof the organ composes across three very
  different substrates (a Voro census, a search index, a compiler's Point set) — but the energy goes
   into `%Seem` as the interface the Voro engine's model is authored in, where the payoff is a NEW
    capability (a snap-testable semantic model of a data field) rather than a like-for-like swap of code
     that already works. The neighbourhood-read — judging a thing against its surroundings, not alone —
      is the heart of it: `resolved_fn(T, N, goners, neus)` hands you the whole sibling set AFTER the
       diff resolves, which is exactly what an algorithm that weighs a datum against its field needs.

**Destination:** `%Seem` as awareness-with-identity, the shared substrate the whole machine stands on —
 not by retrofitting it everywhere, but by being the natural way new organs (starting with the Voro
  grasp) are written. The harvest survey below is the reference for WHERE the pattern recurs; it is no
   longer the plan.

**Safety net for the churn ahead:** the Voro model work will re-record fixtures repeatedly.
 `Seen_split` (the human's parallel build of `%seen` latch + a `The/Assertions` roster,
  `Seen_split_todo.md`) is what makes that churn survivable — a declared assertion that silently
   vanishes now reds the run. Cross-reference it; don't plan it here.

---

## The primitive, precisely

`Selection.process({ n, trace_fn, traced_fn, resolved_fn, … })` (`Selection.svelte.ts:244`) walks a
 source tree `n**` and, through `Stuff.replace()` → `resolve()`, PAIRS this walk against last walk. Its
  `pairs_fn` (`:306-336`) is the engine: `a && !b` → a **goner**; `!a && b` → a **neu**; `a && b` → a
   **survivor**, stamping history `b.c.T.sc.bD = a` (`:326`) and forward `a.c.fD = b` (`:334`). The
    caller's `resolved_fn(T, N, goners, neus)` (`:351`) then receives the fully-classified sibling set.

`i_Seem(container, opt)` (`LangHold.svelte:930`) embeds one under a host particle: `Seem.sc.Se ??= new
 Selection({})`, the walk shape + hooks on `Seem.sc.opt`, and `use_Understandable` wires each D node
  back to its source C (`C.c.D = D; D.c.C = C`, `_Seem_CDUsive` `:963`). `o_Seem(Seem)` (`:980`) runs
   one walk and returns `{ goners, neus, topD }`, stamping `Seem/%News` with the counts. **Snap-hostile
    by construction** — a live `Selection` and functions never encode — so a Seem lives off-snap on a
     free `C**` and projects only a distilled clean reading. The proven exemplars to model a new Seem
      on: `Voro_grasp` (`Ghost/V/Voro.g:351`), the editor's two-Seem `%LE` clone, and Cyto's chained
       scan/id/wave Selections (`Cyto.svelte:346`/`:937`/`:1154`).

---

## Appendix — the harvest survey (PARKED — reference, NOT the plan)

Everything below is the original codebase survey: the eight places the last-beat-vs-this-beat pattern
 recurs, ranked by value ÷ risk, with two deep-design sections. It is kept as a MAP of where `%Seem`
  would fit if the pattern is ever wanted at one of these sites — but per §0 the harvest campaign is
   parked, and several entries were deep-designed to the conclusion "leave it alone." Read it as
    reference, not a to-do list. The per-section status blocks (BUILT/FIXED/OVERSTATED) are the state
     as of the 2026-07-12 adversarial pass and are frozen here; the three built mirrors are described
      live in §0.

**The three measuring hooks** a candidate was scored against: **(a) SCATTERED STATE** (transient `c.*`
 hand-wiped each beat), **(b) HAND-ROLLED DIFF** (code re-implementing `resolve()`'s
  appeared/vanished/changed), **(c) ISOLATION JUDGEMENT** (a thing judged alone when the verdict needs
   its neighbours or history).

---

## §1 — Voro_report (the flagship, one hop from proven) — smells (a)(b)(c)

**WHERE:** `Ghost/V/Voro.g:112` `Voro_report` (walker `Voro_report_walk` `:231`), rebuilding
 `w:Voronoiology` every beat.

**Evidence.** `for (const c of rw.o()) c.c.seen_beat = 0` (`:134`) at beat start; every found-or-created
 child re-stamps `c.c.seen_beat = 1` (`:143,150,162,181`); then the goner sweep drops the un-re-touched:
  `for (const c of rw.o().slice()) if (!c.c.seen_beat && …) c.drop(c)` (`:189`). A per-beat counter
   `w.c.report_beat` (`:135`) smears beat identity. The comment (`:128-133`) openly describes reinventing
    survivor-identity ("stale-mark every child… sweep only the ones this beat never re-touched"). And it
     special-cases the ONE row a real Seem already authors — the grasp's `%Se` — out of the sweep (`:186`).

**Why a Seem fits.** `Voro_grasp` (`:281`) already stands a `%Seem:scape` over the same `w`, and its
 `o_Seem` returns `news.goners`/`news.neus`/`news.topD`. `Voro_report` reads what changed from the
  sphere instead of hand-marking `c.seen_beat`; survivors keep their D across beats (identity the sweep
   throws away).

**Where its Seem lives / projects.** The grasp Seem already lives off-snap at `w.c.grasp_home`
 (`:301`). `Voro_report`'s rebuilt `w:Voronoiology` census IS the projection — read the fold-sphere,
  project the same clean rows, drop `c.seen_beat` and `report_beat` entirely.

**Risk.** Peripheral to the belief loop, but load-bearing to Voro fixtures (every `Voro*` `toc.snap`).
 Blast = a fixture re-record (`voronoi-cells-render`, `graph-of-music-scape`). Snap-noise gotcha:
  `MUNG-changes-rendering` (`lake-fleet-rerecord`) — the census rows are snapped, so a structural change
   re-records. Verify LIVE only (`runner_ask.mjs`), never headless.

**Slice 0 — BUILT 2026-07-12 (compile-clean; live proof + accept OWED on a Voro runner).**
 `Voro_census_mirror(w)` (`Ghost/V/Voro.g`, driven from `VoroMitosis_drive` after the grasp). REFINEMENT
  on the sketch above: the grasp's own `news.goners` are the wrong granularity — the grasp Seem walks
   `w`'s FOLD layer (cell departures = the born/died it already projects), while `Voro_report`'s
    `c.seen_beat` sweep diffs `rw`'s CENSUS ROWS. So Slice 0 stands a SECOND, direct Seem — `%Seem:census`
     over `rw` itself (off-snap home `w.c.census_home`, modelled exactly on the grasp's proven
      `i_Seem`/`o_Seem`) — and projects a `%Se:census` row `{goners,neus,rows}` BESIDE the live sweep,
       changing NO verdict. The proof (owed live): a Book `%see` that `census.goners` tracks the rows the
        `seen_beat` sweep drops, beat over beat; THEN flip the sweep to read `cnews.goners` and delete
         `c.seen_beat`/`report_beat`. Verify on a `?B=VoroMitosis` runner (none up now — tab is MusuHeist);
          `%Se:census` snaps, so it's a fixture re-record (the human's).

---

## §2 — Cytui `morph_voronoi` + `apply` (the biggest hand-rolled diff outside Voro) — (a)(b)(c)

**⟨GROUND-TRUTH CORRECTION 2026-07-12 (deep code read) — the MOST overstated section; the headline
 "collapse 7 maps + `shown_pts` into one D-sphere" is wrong. DESIGN, not built.⟩**
 - **`apply` is NOT a Seem candidate** — it's a MARKER EXECUTOR. The wave arrives from Cyto with the diff
    already resolved (`wave.o({upsert}|{remove}|{migrate})` = Cyto's `Ze.resolve()` output); the
     `cy.getElementById(id).length` probe is an upsert idempotency check, not an appeared/vanished diff.
 - **Six of the seven maps MUST STAY** — `node_src`/`overlays`/`stuff_mounts`/`overlay_bgs`/`gang_mirrors`/
    `wrap_applied` are render-caches, async DOM/component-handle registries, hysteresis memory (cy-node-id
     keyed, correct independent lifecycles, torn down through ONE path). They are EXACTLY the false-proxy
      §0's BOMB names (persist-legitimately, not re-derived-each-beat) — collapsing them fights
       DOM+Svelte+cytoscape lifecycles = a regression. Only `shown_pts`/`shown_color` (cell-id, per-
        generation) is a genuine `bD`, and it's co-opted as mid-tween scratch; `align_ring` (vertex
         correspondence) is a DIFFERENT axis from a node MOVE, so a Seem can't absorb it.
 - **Cyto ALREADY resolved this diff** — the cell set is a strict downstream of the wave's `upsert`/`remove`
    markers, so a Cytui Seem would DOUBLE-RESOLVE what `Cyto.svelte`'s `Ze` handed over. Honest move =
     "Cytui READS Cyto's diff," not "grows its own."
 **Honest Slice 0 (a legibility win, NO primitive needed):** in `morph_voronoi` after `dying` is built,
  count `born`/`died`/`survived` (already computed locally) into the existing `vlog('morph', …)` telemetry
   (+~4 lines, no state, no Selection, no animation change) so `runner_shot --why` NAMES the diff. Assert
    `born + survived === cells` on a live Voro runner. **Then DECLINE the Seem graduation** — if a diff
     source is ever wanted, feed `morph_voronoi` the wave's already-resolved born/died rather than a
      redundant second Selection. Value = telemetry legibility, NOT a 7-map collapse.

**WHERE (survey framing; superseded above):** `Cytui.svelte:2527` `morph_voronoi`; `:2603` `apply`
 (a marker executor, NOT a diff); ~7 id-keyed bookkeeping maps
 (`:316-2257`).

**Evidence.** Cyto.svelte itself is the SECOND proven Seem — its scan (`:346`), id-assign (`:937`) and
 wave (`:1154`) are three chained Selections, and the migration join (goner-`n` resurfacing as neu-`n`
  = a MOVE, `:1029`) is the killer demo. But the wave lands in **Cytui**, which re-diffs it BY HAND:
   - `morph_voronoi` (`:2527`) diffs this generation's cells against `shown_pts`/`shown_color` (a
      hand-rolled last-generation mirror): survivors `align_ring(pts, prev)` (`:2546`), arrivals "grow
       out of the seed" (`:2550`), departures collected into `dying` (`:2558`) — the neus/survivor/goner
        model coded by hand.
   - `apply` (`:2603`) reconciles the wave against the live cytoscape by probing `cy.getElementById(id)
      .length` (`:2669` etc) — the canonical "does this id exist?" hand-diff.
   - ~7 parallel id-keyed maps (`node_src`, `overlays`, `stuff_mounts`, `overlay_bgs`, `gang_mirrors`,
      `shown_pts`, `shown_color`, `wrap_applied`) all answer "what did this node have last beat," kept
       mutually coherent by hand.

**Why a Seem fits.** A Cytui-side Seem over cytoscape state gives survivors=update / arrivals=add /
 departures=remove out of `resolve()`, collapsing the 7 maps and `shown_pts` into one D-sphere.

**Where its Seem lives / projects.** Off-snap on the Cytui module (or `top_House().c`) — Cytui is a
 view, nothing here is snapped. Projects nothing to snap; it drives cytoscape element ops directly.

**Risk.** Medium-high — this is the live render reconciler; a wrong diff = flicker/leak. But it's a
 view (no snap, no fixture), so blast is visual, provable with `runner_shot.mjs --svg`. `morph_voronoi`
  is the cleanest single conversion (`shown_pts` IS a hand-rolled `bD`).

**Slice 0.** Stand a Seem over the cell set beside `morph_voronoi`, project its `{neus,goners}` into a
 telemetry row, and assert (a `--why` film-strip check) it matches the hand-computed born/died/moved —
  changing no animation. Then let the morph read the sphere.

---

## §3 — Lang Point re-anchoring on recompile (one hop from the working clone's two Seems) — (a)(b)(c)

**⟨Slice 0 mirror BUILT 2026-07-12 — `Lang_graft_seem_mirror` (`LangGraft.svelte:413`), guarded call at
 `:386`, additive (+89/-0), `npm check` clean. Live proof owed.⟩ Two refinements the survey missed:**
 (1) `points` is NOT a clean C tree — it's scattered live Points (the multi-Doc machinery,
  [[multidocwhat-chosen-doc]]); the granularity `pairs_fn` actually diffs at is the `%Pmirror` SET,
   identity `(src_Waft, spec)`. So the mirror syncs a distilled roster `C**` (one `%pm` per Pmirror,
    keyed by that identity), read back off the AUTHORITATIVE post-`replace` set so it can't drift.
 (2) `seem_goners ⊇ hand_goners` (SUPERSET, not equality): `gone_bm_ids` counts only goners that carried
  a graft mark; the Seem counts every departed identity. The proving `%see` must assert the SUBSET
   relation (`hand ⊆ seem`), NOT `==`. When this graduates, that's the exact seam to reconcile.

**WHERE:** `LangGraft.svelte:108-378` `Lang_graft_points_once`.

**Evidence.** This literally reimplements `o_Seem`. It runs `Pmirrors.replace({Pmirror:1}, …)` (`:297`)
 to rebuild the Pmirror set from this compile's Points, with a `pairs_fn(a,b)` (`:317-326`) that IS the
  goner/neu/survivor diff: `a && !b` → goner (`gone_bm_ids`, `:319`), `a && b` → survivor (its `%graft,1`
   child carried across via `resume_X`, `:322`), `!a && b` → neu (`:324`). Then drops goner CM marks by
    hand (`:330`). Dense `dock.c.*` cache cluster: `graft_cache_key`, `graft_map_dige`, `graft_map_v`,
     `graft_serial`, `show_fp`. And the resolver `Lang_resolve_spec` (`:433`) matches each Point's spec
      by name ALONE — no reference to where it anchored last compile or to sibling Points (smell c; the
       `< stack-path resolution` TODO at `:430` admits the gap).

**Why a Seem fits.** The working-clone tree ONE LEVEL UP already runs two real Seems (`origin` +
 `working`, `LE_arm`). A Point-re-anchoring Seem over old-vs-new Points would collapse `pairs_fn` +
  `gone_bm_ids` + the `resume_X` graft-child dance into `o_Seem`'s native `{goners, neus}` +
   survivor-keeps-`bD`. And `bD` is exactly the "where did this Point anchor last time" a re-anchor needs.

**Where its Seem lives / projects.** Off-snap under the dock (beside its `%Compile`), the way the LE's
 Seems park under `%LE`. Projects the surviving `%Pmirror` set + their graft children (already the
  persisted output).

**Risk.** CORE — the render end of every editable dock; DocMinimap and every CM mark depend on it.
 Isolation-first mandatory. Related: `multidocwhat-chosen-doc`, `lang-base-layer-handover`
  (`spec/Lang_handover.md`), `text-point-bridge`.

**Slice 0.** Stand a `%Seem:points` over (last compile's Points → this compile's) beside the live
 `pairs_fn`, project `{neus,goners,survivors}` to a telemetry row, and prove (a Book `%see`) it matches
  the hand-rolled classification on a real recompile — before letting the graft read it. The prize:
   survivor `bD` gives a Point its previous anchor, the seed of real re-anchoring the isolation resolver
    can't do.

---

## §4 — Story snap_H seam + the two string-diff engines (half-cut) — smell (b), some (a)

**⟨GROUND-TRUTH CORRECTION 2026-07-12 (deep code read) — this section OVERSTATED the win; read this
 first. The smell is real but smaller and further than "finish the half-cut seam" implies.⟩**
 - **`dm_correlate`/`Diffmaticui` are DORMANT** — grep finds NO runtime caller; `Diffmaticui` is imported
    nowhere (future UI, `Story_future.md`). So "TWO independent string diffs reconstruct what was thrown
     away" is FALSE — only `compute_diff` runs, and only as DISPLAY (`Storui.svelte:495-534,759`), never a
      verdict. Drop `dm_correlate` from the "tax being paid" claim.
 - **`snap_Se`'s diff is STEP-vs-STEP; the gate is LIVE-vs-RECORDED-FIXTURE — orthogonal axes.** `snap_Se`
    is minted once per Run and reused (`??=`, `:1118`), so its `{goners,neus}` = "what changed since the
     PREVIOUS STEP of this live run." The gate (`exp_dige === got_dige`, `Story.svelte:2213`) hashes the
      flattened string vs the RECORDED dige — it never has a live "expected tree" to resolve against. So
       `snap_Se` CANNOT feed the gate without re-materializing the fixture string into a tree + a NEW
        Selection — the very round-trip the seam was meant to delete.
 - **The flatten is LOAD-BEARING, keep it forever** — `dig()` hashes exact bytes; `depth_of` reads the
    2-space indent for depth; a loopy-stub pass (`:1178-1210`) rewrites lines; `entropy_forgive`
     (`Hovercraft.svelte:824`) re-parses got/exp as POSITIONAL aligned line arrays. A Seem here is an
      ADDITIVE explanation beside the string gate, NEVER a replacement.
 **Honest Slice 0 (step-vs-step, additive):** add a `resolved_fn` to the EXISTING `Se.process` call
  (`:1121`) collecting goners/neus, project `Run.c.snap_seem = {neus,goners,changed}` (`.c` runtime),
   touch the string path ZERO (verify NO `toc.snap` dige moves). Prove it COVERS `compute_diff`'s prev-step
    diff with a SUPERSET `%see` (`string ⊆ seem`) — G2: `resolve_strict` is OFF so content-edits are
     survivors with `.sc.changed`, not goner+neu; G3: identity keys differ (snap_Se ALL sc keys vs string
      mainkey+value). **Graduation target = the DISPLAY `prev`-diff panel (`Storui.svelte:759`), never the
       gate.** Reconcile-before-flip: G2 (resolve_strict), G3 (identity keys), G5 (`T.sc.not`/`boring`
        pruning), G4 (loopy stubs). Full G1-G6 gotcha list from the 2026-07-12 design read.

**WHERE (survey framing; superseded by the correction above):** `Story.svelte:1106` `snap_H`;
 `D/Diffmatic.svelte:84` `dm_correlate` (DORMANT); `Text.svelte:1161`
 `compute_diff`; consumers `D/Diffmaticui.svelte`, `Storui.svelte:36`.

**Evidence.** `snap_H` ALREADY runs a `Selection` (`Run.c.snap_Se`, `:1118`) and its `traced_fn(D, bD)`
 (`:1163`) reads each survivor's prior mirror `bD` to set `D.sc.changed`/`D.sc.is_new` — a genuine
  cross-beat identity read. Then it **flattens to a joined string** (`lines.map(D => D.sc.snap_line)
   .join('\n')`, `:1212`) and discards the D-sphere. `resolved_fn`/`goners`/`neus` are never passed
    (grep-confirmed). Downstream, TWO independent hand-rolled string diffs reconstruct what was thrown
     away: `dm_correlate` (`:84`) re-parses every line back to an identity (`deL` → `mainkey:value`),
      unions the id sets and classifies `added`/`removed`/`same`/`changed`; `compute_diff` runs a second
       LCS diff. The **fixture gate** (got_snap vs exp_snap, `Storui.svelte:36`) is the same string
        machinery with NO Selection. The UI CSS is literally `class:neu`/`class:gone`
         (`Diffmaticui.svelte`) — the `neus`/`goners` vocabulary, derived from string-diffing instead of
          from the Seem that had it.

**Why a Seem fits.** The seam is half-cut: keep the D-sphere instead of flattening, pass `resolved_fn`,
 and the fixture diff (recorded-vs-live) and step-vs-step diff fall out of `resolve()` per-particle —
  the verdict becomes "this node changed / arrived / departed" instead of an all-or-nothing dige hash
   (`:2213`) that then needs a string-diff to EXPLAIN what moved.

**Where its Seem lives / projects.** `snap_Se` already lives off-snap on `Run.c`. It would project the
 structural diff into the Storui view; the snap string can stay as the durable fixture (belt-and-braces
  during migration).

**Risk.** CORE — the fixture gate is the whole test machine's spine (`see-is-not-a-latch`,
 `see-assertion-layer`, `EntropyArrest.md`). The dige-string gate is deeply relied on. This is
  additive-first: build the structural diff ALONGSIDE, never replace the string gate until proven.
   Never load a snap mid-run on a runner (`entropy-samples-fuzzok`).

**Slice 0.** Pass `resolved_fn` to the EXISTING `snap_Se`, project `{neus,goners}` to a telemetry row
 next to the string snap, and prove (a Book `%see`) the structural set matches `dm_correlate`'s
  `added`/`removed` on a real step. Change no verdict. This is the cheapest first cut — the Selection is
   already there.

---

## §5 — Matstyle: isolation-judged swatches + dose band — smell (c) only

**WHERE:** `Matstyle.svelte:164` `matstyle_get_or_create`; `:245` `dose_drives` (in `matstyle_apply`).

**Evidence.** A new mainkey gets `idx = existing.length` and `bg = MATSTYLE_PALETTE[idx]` (`:169-174`)
 — the next colour by FIRST-SEEN ORDER, blind to the field: it can't spread hues to maximise contrast
  among the mainkeys actually present, or de-emphasise a dominant type, because it never sees the
   population. `dose_drives` interpolates size against a HAND-AUTHORED constant `min/max` per mainkey
    (`%meta:dose`, `:256`), never the live min/max across the sibling particles this beat. Both are
     per-particle verdicts that a neighbourhood read would improve. (Clean on (a)/(b) — no last-vs-this
      state, no transient-flag walk.)

**Why a Seem fits.** A Seem's `resolved_fn(T, N, goners, neus)` hands the WHOLE sibling set — exactly the
 hook to choose a swatch relative to the field, or to size a dose against the beat's live range instead
  of a constant band.

**Where its Seem lives / projects.** Matstyle already stores swatches off-snap in `H.ave` beside `This`;
 a per-field pass would read `N` and project the chosen `%style:*`/`%meta:*` as it does now.

**Risk.** LOW-MEDIUM — swatches are cosmetic; a wrong colour is not a wrong verdict. But it touches the
 live Cyto styling every node reads (`matstyle_restyle` `:326`). Purely (c); the smallest, safest place
  to demonstrate the neighbourhood-read on non-critical output. `Waft_styling_todo.md` is the home doc.

**Slice 0.** A read-only pass that COMPUTES a field-aware palette + live dose range and logs it beside
 the authored one — prove the field-relative choice is sane before it drives a pixel.

---

## §6 — Stemdex universal-search scan — smells (a)(b)(c)

**WHERE:** `LiesFunk.svelte:1404` `e_Lies_stemdex_scan`; `:1348` `Lies_stemdex_scan_text`; `:1305`
 `Lies_stemdex_drop`.

**Evidence.** Hand-rolls the survivor/arrival/goner diff over the doc roster: survivor `if (!prior ||
 prior.dige !== dige)` skips re-scan on a dige match (`:1453`); neu/changed → re-index; goner `const
  gone = [...dex.docs.keys()].filter(p => !paths.has(p))` then drop per path (`:1468`) — textbook
   re-index churn. The whole index is a bag of hand-managed runtime Maps + pass flags on `w.c.stemdex`
    (`docs`, `post`, `defs`, `props`, `scanning`, `warmed`, `total`, `done`, `missing`, `pass`, `:1277`).

**Why a Seem fits.** An `o_Seem` over the doc roster gives survivor (keep the index)/neu (scan)/goner
 (drop) natively — the dige-gate becomes the survivor's `bD` compare, the roster filter becomes
  `goners`.

**Where its Seem lives / projects.** Off-snap on `w.c` (the index is already off-snap runtime state).
 Projects nothing to snap — it IS the search index.

**Risk.** LOW — search v1, not the data model. Self-contained. `universal-search-stemdex`,
 `Stemdex_spec.md`.

**Slice 0.** A Seem over the roster projecting `{neus,goners}` beside the existing dige-gate; prove they
 agree on a doc add/remove, then let the scan read the sphere.

---

## §7 — LiesStore IO settling (weaker — the "tree" is a queue) — (a)(b)(c)

**WHERE:** `LiesStore.svelte:399` `req_Store`; `:745` `req_LiesStore_writeCarefully`.

**Evidence.** In-flight-vs-settled tracking across 4 phases via hand-stamped `sc.finished` + a two-pass
 `sc.seen` latch (`:476`); a hand-rolled disk diff `if (base_dige && disk_dige && disk_dige !==
  base_dige)` (`:777`) branching silent-pull vs conflict-park, repeated per phase. A large cluster of
   off-snap `good.c.*` load-state flags (`content`, `asked_at`, `last_error`, `error_count`,
    `notfound_rounds`).

**Why a Seem is a LOOSER fit.** The "source tree" here is an IO request queue, not a `C**` subtree, and
 much of the `good.c.*` is legitimate async scaffolding that WANTS to persist (not re-derived) — the
  false-positive class the §0 bomb warns about. Convert only the base_dige-vs-disk_dige compare if
   anything; leave the queue mechanics.

**Risk.** CORE (the IO pump) with a loose Seem fit → LOW priority. `o-elvis-bootstrap-race`,
 `Lies_handover.md`.

---

## §8 — %Map / Mapule build (ADDITIVE, not a replacement) — smell (a), latent (c)

**WHERE:** `lang/compile.ts:198` `Lang_compile_collect`; `Lang.svelte:679` `Lang_Map_report`, `:733`
 `Lang_build_mapules`.

**Evidence.** The %Map is blown away and rebuilt EVERY compile (`Map_C.empty()`, `compile.ts:200`) —
 there is NO appeared/vanished/moved region diff; change-detection is a content-digest gate
  (`Map_dige`/`mapules_dige`). Per-region transient offset cache `e.c.abs_from`/`abs_to`/`region_path`
   recomputed each compile (`compile.ts:423`).

**Why a Seem would ADD (not replace).** A Seem over the region set would RECOVER the moved/appeared/
 vanished region identity that `empty()` discards today — feeding §3's Point re-anchoring the "this
  region is the same one that moved" signal it currently lacks. Not a straight conversion; a new
   capability.

**Risk.** CORE (every graft/minimap reads the Map), and it works — so this is a "later, if the
 re-anchoring win in §3 wants it" note, not a Slice 0. `map-rel-offsets`, `nong-pointing-todo`,
  `LangCompiler_TODO.md`.

---

## Ranking (value ÷ risk)

| # | Candidate | Smells | On a Seem today? | Value ÷ Risk | First slice |
|---|-----------|--------|------------------|--------------|-------------|
| 1 | §1 Voro_report | a b c | grasp Seem exists one fn over | **highest** — proven fix, low blast | ⚠️ prototype FLAWED — tautology + self-count (§0); fix + prove |
| 2 | §6 Stemdex scan | a b c | no | high — clean, non-core | ⚠️ prototype FLAWED — wrong diff-set + no driver Book (§0) |
| 3 | §2 Cytui morph_voronoi | a (b) | Cyto's `Ze` ALREADY resolves it | **downgraded** — telemetry legibility only; decline the Seem | 📐 DESIGNED; +4-line born/died `vlog` |
| 4 | §4 Story snap_H seam | b (a) | HALF — `snap_Se` step-vs-step | **corrected: additive DISPLAY only** (not the gate; dm_correlate dormant) | 📐 DESIGNED; `resolved_fn`→`Run.c.snap_seem` |
| 5 | §3 Point re-anchoring | a b c | working-clone Seems adjacent | high — clean `pairs_fn` twin | ⚠️ prototype FLAWED — `oai` collapses dup specs (§0) |
| 6 | §5 Matstyle | c | no | medium — cosmetic, low risk | field-aware palette, read-only |
| 7 | §7 LiesStore IO | a b c | no | low — loose fit, core pump | only base/disk dige compare |
| 8 | §8 %Map / Mapule | a (c) | no | later — additive, works | not a Slice 0 |

**NOT candidates (state it so the next fork doesn't chase them):** `Housing.organise()`
 (`Housing.svelte.ts:1038`) — already a Seem consumer, the exemplar. The req machine
  (`Hovercraft.svelte` do()/finish/all_finished) — compares to no stored previous; `ttlilt` is a
   one-shot timing advisor, not a diff. `Stuff.resolve()`/`replace()` (`Stuff.svelte.ts:966`/`:897`) —
    the sanctioned hand-rolled diff that IS the primitive; the one place it belongs.

---

## Cross-references

- **Proven example:** `Voro_grasp` (`Ghost/V/Voro.g:281`); design in `Voro_vtuffing.md` §🎋 "Se as a
   `%Seem`" (the Slice 0-2 staging this doc generalizes) and `Voro_render_todo.md` §0.
- **The primitive:** `LangHold.svelte:922` (`i_Seem`/`o_Seem`); `Selection.svelte.ts:244`
   (`Selection.process`); `LiesEnd_spec.md` (the `%LE` two-Seem model).
- **Already-Seem organs:** Cyto (`Cyto.svelte:346`/`:937`/`:1154`); the belief loop
   (`Housing.svelte.ts:1038`).
- **Memory:** `voro-se-as-seem`, `see-is-not-a-latch`, `fight-back-on-core-changes`,
   `cyto-node-stuffings`, `oai-only-at-canonical-spot`.
- **Verify LIVE only** — `runner_ask.mjs` / `runner_shot.mjs` against a `:9091` runner; headless
   Story_cli is banned (`verify-via-live-runner`, `testing-is-story-books`). Every isolation proof is a
    Book `%see`, installed via a CHECK run + manual install, never CredRunner Accept (`see-assertion-layer`).

---

## §5-deep — Matstyle: the field-aware swatch + the beat-live dose band

*(Deep design 2026-07-12, appended below the thin §5 sketch above. DESIGN, not built. The §5
 headline "smell (c) only" was right but incomplete: there IS a latent (b), and it is the cleanest
  angle — read below. The truly-cosmetic nature makes this the safest place in the whole harvest to
   demonstrate the neighbourhood-read on live output.)*

### Ground truth (read live: `Matstyle.svelte`, `Cyto.svelte`)

`matstyle_get_or_create(stylesC, key)` (`Matstyle.svelte:164`) is the whole mechanism. On a new
 mainkey it takes `idx = existing.length` (`:169`) and `bg = MATSTYLE_PALETTE[idx]` (`:174`) — the
  next colour by **first-seen order**, from the 40-colour golden-angle palette. It is a
   find-or-create keyed on `matstyle:<key>` under `The/Styles`, called PER NODE PER BEAT from Cyto's
    classify: `Cyto.svelte:919` (default path) and `:741` (stuffy border). So every beat, every
     rendered particle asks "have I seen this mainkey?" and, on a miss, mints the next palette colour.

Two verdicts are each made in isolation:

- **(c) colour** — `idx = existing.length` is blind to the population. It cannot spread hues to
   maximise contrast among the mainkeys ACTUALLY present this beat, cannot de-emphasise a dominant
    type, cannot re-use a retired slot — because it never sees the field, only its own running count.
- **(c) dose size** — `matstyle_apply`'s `dose_drives` (`:245-263`) interpolates size against a
   HAND-AUTHORED constant `min/max` per mainkey (`%meta:dose`, seeded in `matstyle_seed_known:184`),
    never the live min/max across the sibling particles this beat. A dose of 8 looks "big" or "small"
     only against the constant band, not against what else is on screen right now.

**The latent (b) the §5 sketch missed — arrival IS a hand-rolled diff, it just has no departure.**
 `matstyle_get_or_create` is a `%Seem` waiting to happen: the `o({matstyle:key})[0]` miss-check is a
  per-beat "is this mainkey a NEU?" test, and `idx = existing.length` is a monotonic arrival counter.
   There is no goner concept at all — swatches NEVER retire (a mainkey that vanishes from the graph
    keeps its slot forever, and `idx` keeps climbing toward palette exhaustion, `:171`). That absence
     is the smell: the machine already computes "new mainkey this beat" by hand, one node at a time,
      with no memory of the SET of mainkeys present last beat.

### The Seem-ification

**What the Seem watches:** the set of mainkeys present in the live Cyto graph THIS beat — i.e. an
 `o_Seem` over a distilled roster `C**` with one child per DISTINCT mainkey found during
  `cyto_scan` (NOT over the nodes themselves — that is Cyto's own Seem; see the tautology guard
   below). The roster is projected from the scan's classify pass: as each node is classified, note
    its mainkey; the roster is `{ mainkey:<key>, dose_min, dose_max, count }` — the per-mainkey
     census OF THE FIELD.

**What it projects:**
- `neus` = mainkeys that appeared this beat → mint a swatch, but now choosing the colour RELATIVE to
   the field (spread the new hue maximally from the hues already in use, using the golden-angle
    stepping the palette already encodes — just seeded by "what's present" not "how many I've minted").
- `goners` = mainkeys that VANISHED → the thing the current code cannot do: retire (or grey-bank) the
   swatch, freeing its palette slot so a long-running graph never exhausts 40 colours.
- survivors carry `bD` = last beat's swatch + last beat's live dose band, so `dose_drives` can
   interpolate against the BEAT'S range (`bD`-tracked live min/max) with hysteresis instead of a
    frozen constant.

**What consumer flips:** exactly one. `matstyle_get_or_create` stops reading `existing.length` and
 reads the census Seem's `neus`/field to pick a contrast-maximising colour; `dose_drives` stops
  reading only `%meta:dose` constants and blends in the census row's live `dose_min`/`dose_max`.
   Nothing else changes — swatches still store off-snap in `H.ave` beside `This` (`Matstyle.svelte`
    header), still drive `matstyle_restyle:326`.

**Where its Seem lives / projects:** off-snap on the Cyto `w.c` (the census is per-graph-instance,
 like `w.c.Styles`), modelled on the proven `i_Seem`/`o_Seem` shape (`LangHold.svelte:930/980`).
  Projects only the census rows it needs; the swatches themselves stay where they are (they are
   authored/editable via `matstyle_update`, so they must NOT be blown away each beat — the Seem
    ADVISES the colour choice for NEW keys, it does not own existing swatches).

### Isolation-first Slice 0

A read-only census pass stood ALONGSIDE the live path: build the per-beat mainkey roster during
 `cyto_scan`, run an `o_Seem` over it, and `console.log` / project `{neus, goners, field}` beside
  the current `existing.length` choice — changing NO pixel. Prove (a Book `%see` — a `Leaf*` Book
   that Cyto "basically works" on is the natural probe, `Cyto.svelte:731` comment) that the census
    `neus` match the mainkeys that actually got new swatches this beat, and that `goners` names the
     ones that left. THEN flip `matstyle_get_or_create`'s colour choice to be field-aware, and prove
      the palette no longer climbs monotonically on a graph that churns mainkeys.

### The tautology trap (be adversarial — this is how the first three mirrors died)

**The trap:** the obvious census source is "walk the cyto_node particles and collect mainkeys." But
 Cyto's scan (`Cyto.svelte:346`) is ITSELF a Seem, and the swatch population is a strict downstream
  of it. A census Seem walking the SAME node set would have `neus` == "nodes Cyto's Seem already
   classed as neu" BY CONSTRUCTION — it would break in lockstep with Cyto's scan and never diverge,
    reading Cyto's own output back to itself. That is exactly the §1 Voro-census flaw (`§0`: "walks
     the POST-sweep `rw` so its goners == the sweep's output tautologically") and the §6 Stemdex flaw
      reborn.

**How this design avoids it:** the census is over a DIFFERENT granularity and an INDEPENDENT source.
 It does NOT diff nodes (Cyto owns that); it diffs the **distinct-mainkey SET**, projected from the
  source particles' `mainkey(n)` — a coarser identity that Cyto's node-level Seem never computes.
   Cyto's Seem answers "which NODES arrived"; the census answers "which TYPES are present", and a
    type can persist across beats while its individual nodes churn (10 leaves → 12 leaves = zero
     mainkey `neus`, but Cyto's node Seem reports neus). The two sets provably diverge, so the census
      is measuring something real, not echoing Cyto. Concretely: gate the proof on a beat where node
       count changes but the mainkey set does NOT (census `neus`==0, Cyto neus>0) — if the census
        reports `neus`>0 there, it is tautological and must be rejected.

### Honest risk assessment

- **Blast is VISIBLE IN EVERY CYTO RENDER** — swatch colour and node size are on-screen on every
   frame. A wrong field-aware colour is not a wrong verdict (no fixture, no gate — swatches are
    off-snap `H.ave`), so the machine stays green, but the human SEES churn immediately. That is
     actually the safety: the failure mode is cosmetic and instantly visible via `runner_shot.mjs`
      (`runner-shot-pixel-loop`), not a silent data corruption.
- **The specific breakage if the field-aware colour is unstable:** swatch CHURN — a colour that
   recomputes every beat as the field shifts, so nodes flicker hue. Guard: survivors keep their
    colour via `bD` (a mainkey that was present last beat keeps its assigned swatch; only genuine
     `neus` get a fresh field-relative pick). Never recolour a survivor. This is why the Seem's
      identity (survivor keeps `bD`) is load-bearing, not decorative.
- **Do NOT let the Seem own authored swatches.** `matstyle_update` (`:366`) lets the human hand-edit
   a swatch's colour/shape/dose; those are persisted and editable. The census advises the DEFAULT for
    a new mainkey only — an authored override must always win. If the Seem ever overwrites an authored
     `%style:*`, that is a regression the human will notice on the next edit.
- **HMR caveat (`hmr-remixes-ghost-methods`):** Matstyle methods re-mix on hot update, but a census
   `Selection` captured on `w.c` at construction holds the OLD function refs. Re-seat the census Seem
    on the version bump, or (safer for a view) accept a one-beat stale census after an HMR — cosmetic,
     self-heals next scan.

---

## §7-deep — LiesStore IO pump: the settled-vs-pending identity diff (RUNNER-IN-THE-LOOP, never blind)

*(Deep design 2026-07-12, appended below the thin §7 sketch. The §7 sketch's verdict stands and is
 REINFORCED here: the Seem fit is LOOSE and this is CORE — every dock write rides it. This section
  designs it properly anyway, because the two-pass `sc.seen` dance IS a real hand-rolled identity
   diff, but concludes with the honest guard: **never blind-build this; runner in the loop or not at
    all.**)*

### Ground truth (read live: `LiesStore.svelte`)

`req_Store` (`:399`) is the pump — `req:Store,maz:7,eternal` sitting on `w`, pumping itself each
 tick via its own `do_fn` (`:6-19` header). It settles finished IO in FOUR phases, and the
  bookkeeping is entirely hand-stamped `.sc` flags scanned linearly each pump:

- **Phase 1 — writes** (`:410`): `for (const wr of req.o({req:'LiesStore_write'})) if (!wr.sc.finished) continue` — scan for finished writes, stamp `Good/known` dige, hand off to `req:Codebit` by `gen_path` match, then `req.drop(wr)`.
- **Phase 2 — reads** (`:476`): the TWO-PASS DROP. `if (rd.sc.seen) { req.drop(rd); continue }` else land content onto the waiting `%Good`, drain to subscribers, then `rd.sc.seen = 1`. The comment (`:462-475`) explains why: a read dropped IMMEDIATELY re-dispatches every tick (the tailspin) because `LiesPersist` re-checks `req.sc.finished` after the drop; the `seen` stamp buys the caller one full `do()` cycle to read `reply` before the req disappears.
- **Phase 3 — listings** (`:515`): `if (ls.sc.finished) req.drop(ls)` — single-pass.
- **Phase 4 — writeCarefully** (`:524`): `if (wc.sc.finished) req.drop(wc)` — single-pass; a fire-and-forget save with no accessor.

Plus a per-`%Good` off-snap flag cluster: `good.c.content` (undefined=loading, null=absent,
 string=landed), and the load-state siblings the §7 sketch names (`asked_at`, `last_error`,
  `error_count`, `notfound_rounds`). And a hand-rolled disk diff `if (base_dige && disk_dige &&
   disk_dige !== base_dige)` (`:777`) branching silent-pull vs conflict-park in
    `req_LiesStore_writeCarefully` (`:745`).

### Where the identity diff actually is

**The two-pass `sc.seen` dance IS a survivors/neus/goners diff, hand-rolled.** Read it as:
 - a finished-but-unseen read = a **neu** this pass (first sight → land + drain);
 - a finished-and-seen read = a **survivor** from last pass (its one grace cycle) → **goner** this
    pass (drop);
 - an unfinished read = still in-flight (not in the diff yet).

That is exactly `resolve()`'s pairing (`Selection.svelte.ts:306`: `a && !b` goner, `!a && b` neu,
 `a && b` survivor) — the pump is re-implementing "which reqs are new-this-pass vs seen-last-pass vs
  gone" by stamping `sc.seen` and scanning, once per phase, four times over.

### The Seem-ification (designed, then bounded)

**What the Seem would watch:** the child-req set under `req:Store` — `LiesStore_write`,
 `LiesStore_read`, `LiesStore_listing`, `LiesStore_writeCarefully` — keyed by identity (path + kind).
  An `o_Seem` over that set gives per-pass: `neus` (reqs that just finished — do the Phase-1/2/3
   landing), survivors (finished last pass, this pass's `seen` grace → the two-pass drop falls out of
    survivor→goner transition), `goners` (dropped). The four linear scans + the `sc.seen` two-pass
     latch collapse into one `resolve()`.

**What it projects:** nothing to snap (the whole IO footprint is `req:Store`'s subtree; the Seem
 rides `w.c` off-snap like the `good.c.*` state already does). It DRIVES the landing/handoff/drop
  directly, the way Cyto's wave Seem drives cytoscape ops.

**What consumer flips:** the four phase loops in `req_Store` read the Seem's classified set instead
 of scanning `.sc.finished`/`.sc.seen`. The `%Good`/known stamping and the Cortex handoff
  (`write_finished`, `:447`) stay exactly as they are — they are the WORK, not the bookkeeping.

**Where its Seem lives:** off-snap on `w.c` (or on `req:Store.c`), modelled on `i_Seem`/`o_Seem`
 (`LangHold.svelte:930/980`). The req children are already particles under `req:Store`, so the
  walk source is a real `C**` subtree — a BETTER structural fit than §5's roster projection.

### The adversarial cut — the tautology AND the two deeper reasons to leave the queue alone

**The tautology trap:** an `o_Seem` walking `req:Store`'s child set, where `neu` == "a req whose
 `sc.finished` just flipped", is reading the SAME `sc.finished` flag the current scan reads — so a
  naive Seem here echoes the finished-flag rather than independently diffing identity. The
   `sc.finished` flag is set by the IO completion (Wormhole reply landing), and the Seem's neu/goner
    would be a strict function of it. **To avoid it:** the Seem must diff req IDENTITY across passes
     (was this (path,kind) req present last pass? did it leave?), NOT re-read `sc.finished`. The
      identity is the pairing signal; `finished` is orthogonal state the landing logic reads AFTER the
       Seem classifies. If the design ever ends up with the Seem's `pairs_fn` consulting `sc.finished`,
        it has become tautological and must be rejected — the same rule that killed §1/§6.

**Deeper reason 1 — much of `good.c.*` is legitimate async scaffolding, NOT the smell** (`§0` BOMB,
 `fight-back-on-core-changes`). `content`/`asked_at`/`error_count`/`notfound_rounds` WANT to persist
  across ticks — they are in-flight IO memory, not a re-derived-each-beat diff. Converting them fights
   the async lifecycle. The smell is ONLY the `sc.seen` two-pass latch and the phase scans, not the
    `%Good` state.

**Deeper reason 2 — the two-pass drop exists for a REAL timing constraint the Seem must not
 break.** The `seen` grace cycle (`:462-475`) is there because `req_Store` runs as a `do_fn` INSIDE
  `w.do()` and `LiesPersist` re-checks `finished` after — an immediate drop tailspins. A Seem that
   drops a read the pass it finishes reintroduces the exact tailspin the comment warns about. So the
    Seem's survivor→goner transition must preserve the one-cycle grace, which means the Seem's timing
     has to match the hand-rolled two-pass EXACTLY. Getting that wrong is not a cosmetic bug (§5) — it
      is a per-tick re-dispatch storm on the pump every dock write rides.

### Honest risk assessment + the standing verdict

- **This is LOAD-BEARING: every dock write and read rides `req:Store`** (`LiesStore.svelte:6-19`).
   A wrong diff = a stuck compile (write never hands off to Codebit), a lost read (content never
    lands on the `%Good`), or the tailspin re-dispatch storm. Blast is the whole editor + every
     runner's include pipeline.
- **No snap, but a live-behaviour gate:** the pump has no fixture of its own, so the failure is not a
   red verdict — it is a hang or a storm, only visible on a LIVE runner under real IO. That makes it
    the OPPOSITE of §5: §5 fails visibly-and-cosmetically, §7 fails invisibly-and-catastrophically.
- **HMR (`hmr-remixes-ghost-methods`):** the pump's `req_Store` re-mixes, but a `Selection` captured
   on `w.c` holds stale refs — and unlike a view, a stale pump Seem is not self-healing; it can wedge
    IO. This alone argues against a Seem here without a re-seat-on-version-bump discipline proven live.

**VERDICT (unchanged from §7, stated plainly): runner-in-the-loop territory, NEVER blind-built.** If
 anything is worth converting it is ONLY the `sc.seen` two-pass latch → a Seem's survivor→goner
  transition, in strict isolation, proven on a live runner doing real dock writes (open a dock, edit,
   save, watch the compile land) via `runner_ask.mjs` — with the two-pass timing verified byte-for-byte
    against the current behaviour before any flip. The `good.c.*` cluster and the disk-diff branch
     (`:777`) stay hand-rolled; they are not the smell. Lowest priority in the whole harvest, and a
      candidate for "never" if the isolation proof cannot match the two-pass timing exactly.
