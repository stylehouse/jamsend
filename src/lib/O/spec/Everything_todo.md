# Everything still moving

A cross-spec sweep of what is in motion and what is deferred-but-load-bearing,
 distilled from a parallel read of the spec corpus. Lies/Peeroleum is set aside
  at the bottom — this is the everything-*else* picture. Correct anything stale;
   this is a snapshot, not canon.

## Notes for whoever picks this up

- **Stuff and Housing are the central two.** `data/Stuff.svelte.ts` is the C
   substrate — the light medium you CRUD with (`TheC`, `sc`/`c`, `o`/`i`/`oai`,
    the X-indexes, Travel). `O/Housing.svelte.ts` is the House machine built on
     it — the H/A/w levels, the `beliefs()` think-loop (organise → attend →
      reqdo_sweep), the `beliefs` mutex, `i_elvisto`/`i_elvis` targeting,
       Stuffing, Dexie persistence, Wormhole. Everything else orbits these two.
        **Hovercraft sits between them, negotiating for more Housing with Stuff**
         — it owns the transient `%req` level (reqyoncile/reqonce/reqy_recurse/
          ttlilt), i.e. the run-time *work* that asks the stable House for more
           capacity, spun out of Stuff particles. Read Stuff and Housing first;
            they're the load-bearing context for almost every item below.

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

### Step latency — the per-hop pump trickle (good automated-experiment fodder)
The near-permanent compile boomerang is fixed (unchanged-dige settle-wedge in
 `LiesCortex.e_Lies_compiled`; GhostList dirlist gated off test Runs via
  `dontSnapGhostList`). Steps now clear **causally** (the `quiescent:` trace label
   is not `timeout`), so the residual ~1-2s is *not* a ttlilt ceiling — right-sizing
    the 1.6s `LiesStore_write` ttlilt buys nothing here. The real cost is the genuine
     causal chain paid one beliefs-cycle at a time: compile → `Lies_compiled` →
      settle → (notify ‖ run_method) → `BlatDo`, ~10-15 `beliefs:begin/done` cycles,
       and `answer_calls` gates **50ms (`ANSWER_CALLS_TICK_MS`) between every todo
        item** — so a known-causal chain pays `N × 50ms` of pure latency floor.
 Two experiments, both automatable against the `Run_trace` beliefs-cycle count +
  the new `TimeSpool/{TimeTotal:'step'}` avg (surfaced in the Storui run bar as
   `~Xs/step`):
   1. **Burst-drain causally-chained todo without the 50ms gate** while in-step
      (Runtime) — collapse an in-step handoff chain toward one/two cycles instead
       of one-elvis-per-50ms. Closest to "one clean step per compile".
   2. **Sweep `ANSWER_CALLS_TICK_MS`** as a measurement knob — does halving it
      ~halve these steps? Confirms the hop-count diagnosis before touching the
       handoff spine. Blunt/global; a knob, not a fix.
 Instrument is in hand; the next move is to *count hops per step and see which are
  removable*, not to fiddle the ttlilt. (cf memory `compile-boomerang-latency`,
   `ttlilt-not-a-keepalive`.)

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
        fallback).
   *Also done:* fixed `wormhole/Ghost/Net/Easy/toc.snap` to the `What→(Doc|Point)`
    grammar (Points were nested inside their Doc; now siblings under the What).
     The Story recordings that embed this Waft (`Story/Editron/001`,`002`,
      `Story/PereStaple/toc`) still hold the old shape and will re-record on
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
      is barely sketched; gated on the taxonomy seam below. *(The old "display
       translation view" leftover in `Lang_compile_dock` — a dead `if(0)` emit of
        per-line `result:1` chunks with no consumer — was removed; the runner
         verdict strip reads `run_result:1` and the gen/ `.go` is the artifact.)*
- **Pmirror non-resolution is silent** (folded from the retired Lang_session4 handover).
   Lang doesn't notice or surface that some Pmirrors fail to resolve — they only emit
    console warnings. Give it a noticing/UI. Check once the channel refactoring settles. **[bug · deferred]**
- **All method def|call index** — a global, queryable index of every method definition and
   call site (likely IndexedDB). Feeds goto / fork-the-What / the StemHive. **[mid · cold]**
- **GhostList polish** — prune goners (a deleted file lingers by design today); cascade-collapse
   deeper opened dirs when a parent collapses; a faster listings `ttlilt` (the ~1.6s beat before a
    newly-opened dir fills is the wormhole re-check interval). **[low · cold]**

### Hovercraft req-migration
Nearly landed. reqy() fully sublated; the engine is C-native and self-contained
 on the C. All hosts migrated (MachPeerily was the last off reqy).
**Tail remaining (reframed 2026-06-19):** not a migrate-in-place — **copy** the
 generic hovering machine out of legacy `Agency.svelte` into Hovercraft (which
  already owns the `%req` engine and, via Housing, the modern think-loop), and
   rewrite the `setTimeout(…,11)` re-entry onto `i_elvisto`/`reqyoncile`. Legacy
    Agency, Pirat\*, and `requesty_serial` are left as-is; the new code must
     contain no `requesty_serial`. Full kept|gone method list + what landed are in
      **`Agency_to_Hovercraft_plan.md`**.
       **Done 2026-06-19:** live helpers (self_timekeeping, reset_interval,
        w_forgets_problems, w_ambiently_sleeping, whittle_N, agency_officing)
         copied to a `//#region Agency machine` at the top of Hovercraft; the
          `%aim`/`%satisfied` machinery (i_journeys_o_aims, name_A, Aw_satisfied,
           out_of_instructions) kept in a quarantined `//#region relics` beside
            it; `prandle` moved to the House class in Housing; only `i_unemits_o_Aw`
             left out (Peeroleum rebuild). `LiesWorkup.svelte` is still shelved
              referencing deleted reqy() (compile-or-stays-shelved).

### Wormhole backends
OPFS-from-GitHub backend is coded and **runtime-verified in browser** (Library
 loads, book runs from seed, save survives reload into scratch/, marker
  idempotency holds — no second API hit on reload). Done.
Records-as-files for Identities ("switch who you are" = read a different record)
 is planned-not-started. `WhNav` shared interface still duck-typed across the
  three backends (browser / node / OPFS overlay).

**The `O`/`I` layout — the filesystem mirroring the particle split (deferred).**
 A standardisation of the whole `wormhole/` tree on directories that hold *only
  names*. A Story's step 001 becomes `wormhole/Story/O/LakeTiles/O/Step=001/I`,
   where **`I` is today's `toc.snap`** (the node's own content) and **`O/*` are
    pure name-containers** — the filesystem laid out as the C split itself:
     `o()` = children (the `O/` dirs), `i()` = the node (its `I`). The bytes
      decode identically to a `toc.snap` (same Lines codec, `decode_wh_lines`/
       `deWaft`); this is purely an *addressing* rework, so it supersedes any
        fixed `Such`-style path and the toc.snap promotion both. **Don't
         over-invest in bespoke paths anywhere in `wormhole/` until this lands**;
          shape new layouts knowing `O`/`I` is the horizon. A third axis the
           layout must accommodate: the **git seam** (group history by git rev —
            see the Editron `Credulation`-by-rev TODO). Extracted here from
             `Editron.md` §7 (was tangled into the Credu-storage handover); it is
              a general wormhole-storage concern, not Credu-specific.

### StemHive / Langui fold UX
Fold work uncommitted (human commits on host). Open:
- `↦` handle on every region from the start (today only after a region's first fold).
- Ctrl+Q targeting via real Lang region/Mapule ranges, not indentation blocks.
- **Fold-into-chunks** (raised, not started): auto-cluster a method's internals
   into ~3 chunks — peer of stem clustering. Granularity/trigger unspecified.
- **"Scribbles"** (raised, undefined): an annotation/marginalia layer.
- Layout knobs to tune by eye (stem position, cell widths, `FOLD_UP_UNDER`).

### Interest
Graduated to prod (gate LakeSurprise); the real Lang↔Lies channel is live.
Post-graduation work *was* mostly the **metromap vision** — animated SVG:
 Interestily → activeWhat (obscured network) → Points, with folded-away
  "elsewheres"; the surprise_read popover was the first proof. **Priority call
   made 2026-06-19: metromap pushed much later** (still the destination, not the
    next move); when revisited, evaluate **Svelvet** (github.com/open-source-labs/
     Svelvet) as the node/edge substrate. The **Lens "generalissimo" is low
      motivation** — a UI-nester whose need isn't proven; parked until a concrete
       consumer pulls for it.
Smaller threads still live: the runner status panel (the unclickable
 minimap-over-hoverer `.lte-health` in Langui) is moving **out of Lang into Lies**
  (Liesui, bottom-right absolute, with a Vexpandy) — the more natural home; self-
   arming havoc limbs parked on a known race (fix = host in the Funkcion pump so it
    runs after the dock reads); PeelInput × dismissal CRUD merge dangles; escalate
     target lands on the whole Lang/Lies House, not the Liesui sub-element.

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
7. **Wheel-vs-page-scroll arbitration (the "whole-page traffic jam")** — a small
    in-panel control that wants the mouse-wheel (the EntropyArrest fuzz sliders;
     any `<input type=range>` we let the wheel nudge) must NOT steal a wheel event
      that is really the user scrolling the page past it. Wanted rule: the wheel
       adjusts the control only when the page itself hasn't scrolled very recently
        (a short cooldown after the last window scroll), so a fast flick down the
         page glides over the slider instead of getting snagged and dialing it. One
          shared "last page-scrolled at" signal, read by every wheel-grabbing widget.
           Until it lands, the fuzz sliders take the wheel unconditionally (drag
            always works).

The earlier "Point nesting reconciliation" entry was a misread — the snap and
 memory shapes agree (`Waft→What*→(Doc, Point*)`); the real gap was the blind
  bookmark→Point export, now addressed (see Point work below).

## TODO — real UIless includes of `.go` (the runner-side blocker)

A compiled `.g` becomes a `gen/**.go` that is a **Svelte component**: its `eatfunc`
 (the deposit of the ghost's methods + `Ghostmeta_<name>()`) runs in `onMount`. So
  "loading" a ghost today = enrol the component in `H/{watched:UIs}` and let Otro
   **mount** it (`Lies_transport_up` and Pantheate both do exactly this). A UIless run
    renders no UIs → `onMount` never fires → no `Ghostmeta` → `req:include` / the
     runner's acquire (`Lies_ghost_live`) park at `waiting:ghostmeta` forever. This is
      now the load-bearing blocker, not a someday-nicety: it's what stops the
       runner-Lies bootstrap (`Perebootstrap`) from being headless, and it's the
        prerequisite for the Creduler running a real verdict off-DOM.

**The ask:** a way to run a `gen/**.go`'s `eatfunc` (deposit methods + `Ghostmeta`)
 **without a DOM mount** — evaluate the component's deposit path directly, or a headless
  Svelte-component instantiation that runs `onMount`-equivalent. See `Editron.md` §3 + TODO
   ("UIless-include"), `Peeroleum_handover.md` heading 1b, and
    `Story_next_level_spec.md` §16. Until it lands, the runner is a live browser tab
     (which is fine for v1 — the channel is identical either way).

## Parked (Lies / Peeroleum)
Editor→runner channel (version handshake → acquire-then-poll is "THE next edit";
 `active_transport` keystone reportedly still not live), dual-LE Sidetrack
  crossfade, and the Peeroleum spec items — all set aside here.

## Where to actually start
Cleanest self-contained wins:
- **Finish the Hovercraft req-migration tail** — delete requesty_serial + Agency bits.

Biggest-leverage move: the Story **`req:Step` / `req:Drive` recast**, since it
 unlocks UIless test iteration — but that's a larger commitment.
