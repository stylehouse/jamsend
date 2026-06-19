# Everything still moving

A cross-spec sweep of what is in motion and what is deferred-but-load-bearing,
 distilled from a parallel read of the spec corpus. Lies/Peeroleum is set aside
  at the bottom — this is the everything-*else* picture. Correct anything stale;
   this is a snapshot, not canon.

## Notes for whoever picks this up

- **Verify against code before believing a difficulty.** Every item touched so
   far shrank on contact: the Stuffing "over-creation" was already solved, the
    "Point nesting reconciliation" was a misread (snap and memory agree), and the
     "blind bookmark export" was real but fixed by one elvis through an existing
      seam (`e:mark` `op:add` → `LE_add_clone`). The doc *overstates*; the real
       gap is usually narrower and a seam usually already covers it. Read the
        live code, then size the work.
- **The decision-list is the spine; the status bullets rot.** Trust "Not nailed
   down that should be" over the per-subsystem prose, which drifts run-to-run.
- **Highest-leverage move latent here:** items #2 (where standing things live —
   `H.ave` vs `Run.c`) and #3 (what counts as "the same change") are the *same*
    cross-cutting questions asked in three dialects across Story/Wire/palmtree.
     Answer each once as a shared primitive and three specs partly collapse.
- **Durable invariant worth a real home:** *the LE owns every Waft C manipulation
   from Lang* — Lang never writes Waft C directly. It's only in an elvis comment
    (`e_Lang_shoot_point`) and here; it belongs in `Waft_spec`. Now near
     exception-free (the pre-LE path errors rather than writing blind).

## Still moving — by subsystem

### Story runner
`Story_next_level_spec.md` is the biggest live document by far. It frames the
 work as **13 sequential stages, ordered for shippability** (not logical
  dependency), with one explicit parallel track that should ship *first*:
   recasting the test drive as `req:Step` (one-shot, rest = step done) /
    `req:Drive` (eternal, survives ticks) so test iteration can run
     **UIless / agent-driven** (§15–16). That de-risks every stage below it.

Doctrine of the whole doc: *"the measure of a good change here is how much
 bespoke machinery it removes"* — unification/deletion, not feature-add.

Concretely open:
- Fold Story's third tree-walk into Text's `enWaft` two-pass; verify the
   ref-count pass sees the same tree Story's `process_sc:{snap_root:1}` selects (§1.1).
- Probe-declaration syntax and the trace-point hook API are unspecified;
   `trace_enable`/`trace`/`trace_drain` is the substrate (§2.5).
- Cyto replay direction undecided — does Diffmatication decode snaps back to C
   (needs loopy-decode), or does Cyto learn to wave off a decoded snap (§7).
- UIless boot needs context shims (no WebRTC, no `/music`, no secure context);
   scope the bundle to the ghosts a Story run actually touches (§16).
- Lifetimes in the req-based drive: intra-step ttlilts must expire against
   *their* `req:Step`, never leak into the next (§15.4).

### Lang / Waft / Wire
Three overlapping forward designs:

- **`Waft-palmtree-trajectory.md`** — the What-cursor + branch/dive (`↓`/`↘`
   +time) model. ~10 "faults" still open; the meaty ones: Doc-close is a no-op
    so removed Docs stay editable (#5); Waft/Doc rename are warn-stubs (#6);
     `bookmark_vanished` re-anchor unbuilt (#8).

**Point work (bookmark → Point).** *Done:* the ↑ on a ripe bookmark now shoots
 it into the active Interest's LE as a Point — `DocPoint.export_to_doc` →
  `e_Lang_shoot_point` (Lang.svelte) resolves `Lang_active_LE`, sanity-checks the
   dock against `Waft_src_doc_path`, then routes through the existing `e:mark`
    `op:add` → `LE_add_clone` seam so the Point lands in the What we're at (Trail
     or Sidetrack) and the push cluster writes it back. The Point comes out
      method-only (a `label` equal to the method is dropped as redundant). Lang
       never writes Waft C directly; with no armed Interest it errors (no blind
        fallback), which orphans the old `e_Lies_export_point` (dead now — it did
         the wrong `doc.i({Point})` grammar; delete or leave parked).
   *Also done:* fixed `wormhole/Ghost/Net/Easy/toc.snap` to the `What→(Doc|Point)`
    grammar (Points were nested inside their Doc; now siblings under the What).
     The Story recordings that embed this Waft (`Story/Editron/001`,`002`,
      `Story/Peregrination/toc`) still hold the old shape and will re-record on
       next run, or want a hand-fix. *TODO cloud:*
- **LiesCurse cull → LiesPoint** — cull unused LiesCurse, then refactor the
   locating + waking/activating of Points in Waft\*\* into a `LiesPoint` ghost
    (the Lies-side sibling of LangPoint), once Interests are fully landed.
- **Relative locators (canonical Pointer)** — `method() / if something / etc =`
   name-paths, shortest-unambiguous, to disambiguate two `etc =` inside one
    method. TODO already squats in `LangPoint.svelte:78-99`; blocked on `%Map`
     regions carrying only the header-line span (needs region body extents).
- **Waft\*\* styling** — cohere continuous runs of Whats + present the doc's
   real name nicely without lying (full path stays copyable). Spun out to
    `Waft_styling_handover.md`.
- **`Wire_spec.md`** — generalizes Interest into one `%subscribe,target,on,wake`
   primitive spanning Atime (req/Stuffing/watched) and UItime (`$effect`).
    Staged 1–6; steps 1–3 are no-ops, step 4 ("one recursive boot wire", new
     Otro) is first-visible, 5–6 are the payoff.
- **`LangCompiler_TODO.md` / `LangSolver_report.md`** — most line items now DONE
   (auto-async rewrite, `doai %req:` lowering, esbuild+lezer validate gates).
    What remains: the **LangSion query-planner-over-the-flock horizon** (batch
     IOings, ark-grouping `@name`, shared resultsets, sleeping-optimiser inlining)
      is barely sketched; gated on the taxonomy seam below. Display translation
       view (`LangCompiling.svelte:238`) is a leftover wire-up TODO.

### Hovercraft req-migration
Nearly landed. reqy() fully sublated; the engine is C-native and self-contained
 on the C. All hosts migrated (MachPeerily was the last off reqy).
**Tail remaining:** migrate `requesty_serial` (the *older*, separate queue still
 serving Pirating / Pirate / Agency's own use), then delete Agency's hand-rolled
  pieces (agency_think, Aw_think, procure_ways, setTimeout i_elvis routers) —
   "fold in with the Agency-pilfering TODO." `LiesWorkup.svelte` is shelved,
    still referencing deleted reqy(). Clean, well-scoped finish-the-job.

### Wormhole backends
OPFS-from-GitHub backend is coded but **never runtime-verified in browser** —
 needs a :9091 test with no local dir open (Library loads, book runs from seed,
  save survives reload into scratch/, no second API hit on reload via marker
   idempotency). **Requires the repo be public** or unauth GitHub API 404s.
Records-as-files for Identities ("switch who you are" = read a different record)
 is planned-not-started. `WhNav` shared interface still duck-typed across the
  three backends (browser / node / OPFS overlay).

### StemHive / Langui fold UX
Fold work uncommitted (human commits on host). Open:
- `↦` handle on every region from the start (today only after a region's first fold).
- Ctrl+Q targeting via real Lang region/Mapule ranges, not indentation blocks.
- **Fold-into-chunks** (raised, not started): auto-cluster a method's internals
   into ~3 chunks — peer of stem clustering. Granularity/trigger unspecified.
- **"Scribbles"** (raised, undefined): an annotation/marginalia layer.
- Layout knobs to tune by eye (stem position, cell widths, `FOLD_UP_UNDER`).

### Interest
Graduated to prod (gate InterestLive); the real Lang↔Lies channel is live.
Post-graduation work is mostly the **metromap vision** — animated SVG:
 Interestily → activeWhat (obscured network) → Points, with folded-away
  "elsewheres"; the surprise_read popover was the first proof. **Blocked on a
   human call**: confirm metromap shape, drum-sequencing, priority.
Smaller threads: self-arming havoc limbs parked on a known race (fix = host in
 the Funkcion pump so it runs after the dock reads); PeelInput × dismissal CRUD
  merge dangles; escalate target lands on the whole Lang/Lies House, not the
   Liesui sub-element.

### reactivity
One low-priority unknown (`reactivity_docs.md`):
- Sub-particle `vers` gating bypasses the flush gate (Atime bumps `exa.vers`
   directly); whether it causes mid-cycle re-reads is untested.

Resolved (was a rumour): Stuffing no longer over-creates instances. One
 `Stuffing` per component lifetime (`Stuffing.svelte:30`); components
  `register_stuffing` into `H.stuffing_registry` for *unreactive* version-based
   updates. A ~0.33Hz heartbeat (`Housing.svelte:415`, `setInterval … 3000`)
    plus a 200ms throttle, a microtask kick on register, and a piggyback inside
     each `H.clear()` drive `check_stuffings()`, which content-diffs `stuff_matrix`
      per entry (`matrix_changed`) and notifies only changed ones, all in one
       flush. Throttle strategy settled.

## Not nailed down that should be

The decisions the specs *defer* but that gate real work:

1. **"Which legs are plural" taxonomy seam** — stho annotation (collector decides
    locally) vs compile-time Lies/Understanding fact. Gates the entire LangSion
     fan-out / ark design.
2. **Where standing continuity / wires live** — `H.ave` (session-scoped,
    graph-clean) vs `Run.c` (per-run). Asked identically in Story §8.5, Wire
     spec, and palmtree. Answer it once.
3. **Delta-shape equivalence relation** — what counts as "the same change" for
    covariance folding (Wire §12) and fuzz classification (Story §4.2). Too loose
     folds real divergence; too tight folds nothing. Likely a `%fuzz,kind` ladder
      but unspecified.
4. **Ordering non-determinism** — sort it away deterministically in the encoder,
    or label it as fuzz (Story §4.2)? Affects every snap re-record.
5. **Ting Waft name determinism** — `Ting/<date>/<time>` re-churns every run;
    recommended fix (teach `Lies_spawn_ting_waft` a fixed name under the Story
     runner) noted but not decided.
6. **Cyto diff source** — live C vs decoded snap text; both want the same `bD`
    primitive but the spec leaves a wedge.

The earlier "Point nesting reconciliation" entry was a misread — the snap and
 memory shapes agree (`Waft→What*→(Doc, Point*)`); the real gap was the blind
  bookmark→Point export, now addressed (see Point work below).

## Parked (Lies / Peeroleum)
Editor→runner channel (version handshake → acquire-then-poll is "THE next edit";
 `active_transport` keystone reportedly still not live), dual-LE Sidetrack
  crossfade, and the Peeroleum spec items — all set aside here.

## Where to actually start
Cleanest self-contained wins:
- **Finish the Hovercraft req-migration tail** — delete requesty_serial + Agency bits.
- **Runtime-verify the OPFS Wormhole backend** (needs the repo public).

Biggest-leverage move: the Story **`req:Step` / `req:Drive` recast**, since it
 unlocks UIless test iteration — but that's a larger commitment.
