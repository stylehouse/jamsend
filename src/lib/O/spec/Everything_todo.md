# Everything still moving

A cross-spec sweep of what is in motion and what is deferred-but-load-bearing,
 distilled from a parallel read of the spec corpus. Lies/Peeroleum is set aside
  at the bottom — this is the everything-*else* picture. Correct anything stale;
   this is a snapshot, not canon.

## Notes for whoever picks this up

- Stuff and Housing are the central two — everything orbits them; read them first.
    Stuff       the C substrate you CRUD: TheC, sc|c, o|i|oai, the X-indexes, Travel
    Housing     the machine on it: H/A/w, beliefs() think-loop (organise → attend → reqdo_sweep), the mutex, i_elvisto(), Stuffing, Dexie, Wormhole
    Hovercraft  sits between — negotiates more Housing out of Stuff; owns the transient %req level (the run-time work asking the House for capacity)

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
    cross-cutting questions asked in three dialects across Story/Wire/Waft.
     Answer each once as a shared primitive and three specs partly collapse.
- **Durable invariant worth a real home:** *the LE owns every Waft C manipulation
   from Lang* — Lang never writes Waft C directly. It's only in an elvis comment
    (`e_Lang_shoot_point`) and here; it belongs in `Waft_spec`. Now near
     exception-free (the pre-LE path errors rather than writing blind).

## Still moving — by subsystem

### Story runner
`Story_future.md` is the biggest live document by far. It frames the
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

- **Waft transport faults** (drained from the retired `Waft-palmtree-trajectory.md`;
   the *concept* now lives in `Waft_spec.md`, these are the live plumbing gaps).
    Verified still-open against code:
   - **Doc-close is a no-op** — `Lies_sync_waft_docs` (LiesStore.svelte:204) never
      GCs a `%Good` whose path left every Waft, so a removed Doc stays loaded,
       compilable, editable (#5).
   - **Waft/Doc rename are warn-stubs** — `e_Lies_rename_waft` / `e_Lies_rename_doc`
      (Lies.svelte:402,407) just `console.warn`. The hard half is the inclusion
       graph: a rename must reach every Waft that *includes* this one, and a stored
        locator must survive its target renaming — the SAME reference-caretaking
         blocker behind Interest.md's "Rejoin the stack frame" Point-carry (#6).
   - **`bookmark_vanished` re-anchor unbuilt** — `Lang_bookmark_vanished`
      (Lang.svelte:2142) warns + stamps `%vanished`; the re-anchor + copy-paste
       recovery passes are empty stubs (#8).
   - **push verify false-positives** — a dropped unaccepted clone reads as a goner
      on the origin walk, so `req:push/%dirty` stays open for a push that landed;
       fix = stamp `bD/was_disincluded` before `LE_replace_back` (LangHold:897, still
        comment-only) (#2).
   - **write-error stalls req:Codebit** — a write error never stamps `write_finished`,
      so the Codebit parks forever (LiesCortex write path) (#4).
   - **`LE_available_ops` not stamped** — computed (LangHold:1660) but never written
      to `%LE/%moves.sc.ops`, so NaviCado falls back to static ↑←→ buttons (#7).
   The rest of palmtree was cleanup-directions (req%mutated write-dedup, `req:desire`
    collapse, `req:Showing` as a real req) and resolved/vision items — let go with the file.

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
- **Click a Waft\*\*/Point to focus it** — a raw `%Point` sitting under a Waft→What→Doc should
   be clickable to focus *that Point of its What as if its Pmirror were clicked* — route through
    the existing Pmirror path (`e_Lang_point_navigate`: resolve → openness → scroll → report), not
     a parallel one, so a bare Waft-tree Point and a minimap Pmirror land the same way. Natural
      tenant of the `LiesPoint` ghost above (Waft-side Point activation); the Point-row onclick
       just calls the navigate seam. No urgency — joins the wave. **[low · cold]**
- **Ctrl-Z over Langos (attention-undo)** — when the **minimap/Lens has focus** (not CodeMirror),
   Ctrl-Z should undo *attention-moves* — the `%Lango`s — not text edits: pop the last landed
    Lango and re-land the one before it. Needs the `%Lango` source-terminal + its `/landing`
     reqyoncile trace (Backbone_plan P3) to exist first, so it's the natural undo-stack to walk.
      Focus-gating is the whole trick (CodeMirror keeps its own undo). **[low · cold]**
- **Relative locators (canonical Pointer)** — `method() / if something / etc =`
   name-paths, shortest-unambiguous, to disambiguate two `etc =` inside one
    method. TODO already squats in `LangPoint.svelte:78-99`; blocked on `%Map`
     regions carrying only the header-line span (needs region body extents).
- **Waft\*\* styling** — cohere continuous runs of Whats + present the doc's
   real name nicely without lying (full path stays copyable). Spun out to
    `Waft_styling_todo.md`.
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
             left out (Peeroleum rebuild). `LiesWorkup.svelte` no longer
              references the deleted reqy() (`Workup_git_of` reads `req:git`
               off the host directly) and its `Waft_dip` copy is gone (lives in
                LiesWaft); it stays shelved as a parked design — see Parked below.

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
Graduated to prod (gate LakeSurprise); the real Lang↔Lies channel is live.  The detailed status —
 implemented log, the surprise_read popover, the inspector, the Aside kind, gotchas, FUTURE, TODO —
  lives in its own doc; this is just the cross-subsystem pointer.
- **Canonical doc: `Interest.md`.**
- **Metromap** — pushed much later (2026-06-19 priority call); full description, the Svelvet eval, and
   its **cursoring gate** (good multi-view code cursoring first) now live in `Interest.md` FUTURE.
- **The Lens as a posable UI-container** (the old "generalissimo") — the torus/Decor vision is in
   `Lens_posable_TODO.md`; the Interest-strip-menu facet (per-kind menus, chip→PeelInput) stays in
    `Interest.md` FUTURE.  The Brink shipped (Rundar/Relay/Sound/Upkeep faces, sticky + 4-corner perch
     — `Lens_posable_TODO.md`), so the container now has a pulling consumer (no longer purely speculative).
- **Runner status panel out of Lang into Lies — DONE.** The old `.lte-health` minimap-hoverer is now
   the Brink in Liesui (Vexpandy + a side-button to perch left/right); see the Lens docs.
- Escalate-target tightening (DONE) and the self-arming havoc-limb race (parked on the Funkcion-pump
   fix) are tracked in `Interest.md` TODO.

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
     spec, and the Waft transport (timemachine→Funkcion). Answer it once.
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
    `Story_future.md` §16. Until it lands, the runner is a live browser tab
     (which is fine for v1 — the channel is identical either way).

## Parked (Lies / Peeroleum)
Editor→runner channel (version handshake → acquire-then-poll is "THE next edit";
 `active_transport` keystone reportedly still not live), dual-LE Sidetrack
  crossfade, and the Peeroleum spec items — all set aside here.

**`LiesWorkup.svelte` (shelved) — branch-awareness on top of the LE.** The most
 coherent way to read it: where LiesEnd gives one Understanding at one target,
  LiesWorkup gives that Understanding a *working branch* — touring the What**
   slope accumulates change across targets instead of shedding it on each
    retarget. park/resume pool a %Seemed clone tree per visited-and-modified
     What; a presented %leg + a move is the commit moment; commit replaces-back
      and files a soft (revertable | mergeable) %Waftlet on w:Lies' `req:git`,
       the last two staying soft before they harden into the spool. A small
        local VCS over the Waft, in other words. Interesting and self-contained,
         but unshipped — the open question is whether the branch model earns its
          surface over plain LE retargeting. De-noised (no dead reqy/Waft_dip),
           so it compiles if revived.

## Cluster-trust + ghost-compile — SHIPPED; residual TODO (low priority, parked)
The authenticated relay (signed `gen_write` + `this_dock_updated`, browser trust exposed) and the
 ghost-compile feedback loop are done — the loop closes at ~2–5s ("is ok"). The trust substrate brief
  `ClusterTrust_handover.md` has been **renamed + expanded into `Cluster_spec.md`** (the live cluster spec:
   trust substrate + runner flock + the dockerised real-isolation testbed toward remote `%Rungo`) — NOT
    deletable, it grew. `GhostCompile_feedback_handover.md` was sublated into these lines and has now been
     **deleted** (its §"swamp underneath" survives in git history). Nothing in the ghost-compile residuals below is wanted right now ("enough for atm"):
- **`remote-local-ghost-compile`** (rename of the editor's `this_dock_updated` refresh — the name makes the
   strangeness plain: the `.g` is already on the editor's shared `/app` disk when the CLI asks, so this is a
    *local* compile *triggered* remotely, not a content push. A *purely* remote form — CodeMirror carrying
     the edit over the wire, no shared disk — is the distinct, unbuilt variant. Low priority; the loop works
      as-is.) `this_dock_updated` is already gone from live code (only a comment vestige at `LiesLies:393`);
       the `ghost_compile`+ack loop superseded it.
   strange form legible: claude-cli compiles a `.g` ALREADY on this shared disk, then pings the editor to
    re-read it; a *purely* remote form would be CodeMirror carrying the changes in, not on the recipient's
     disk). Open hop: the editor inbox drops PRE-`%Ud` senders (`Peeroleum.g:308-310`), so claude-cli→editor
      is dropped until the spine accepts a cluster-trusted frame in the async recv window (`Peeroleum_deliver`
       post_do → verify payload sign → treat trusted as Ud-ok). Editor↔runner already works (both Ud-handshaken).
- **PereEditrogression test** — show claude editing + compiling `.g`→`.go` end to end. Not started.
- **Normalise the dige** — the CLI hashes disk bytes, the editor hashes the CodeMirror buffer (EOL differs),
   so the ground-truth `.go`-poll never agrees; the `done` ack is the only reliable confirm today. A canonical
    trailing newline on both sides restores the poll as a 2nd path.
- **`note()` `important` flag** in `Tribunal.g` (frozen spine — recompile + promote) so carrier CLOSE/reconnect
   log lines persist 60s not 5s.
- **Latency** parked as optional (`Editron.md` → THE LATENCY SWAMP): 2–5s is "is ok"; a bounded self-pump is the
   cheap win if it ever bites. The two framings live in that section (an Editron "big step" bracketing the whole
    AI-edit→landing round-trip; `reqyoncile` owning the return everywhere).
- *Done in this pass:* removed the temp ✅/⚠ `gc_ack` diagnostic tlogs in `LangCompiling`.

The CLI-as-Idento / identity-on-the-connection cluster redesign (briefly named "Proteer") is **deliberately
 dropped** — confusing, and nothing more is wanted from the cluster for now. The analysis survives in git
  history (the `GhostCompile_feedback_handover.md` §"swamp underneath" at its last commit) if ever revived.

## Where to actually start
Cleanest self-contained wins:
- **Finish the Hovercraft req-migration tail** — delete requesty_serial + Agency bits.

Biggest-leverage move: the Story **`req:Step` / `req:Drive` recast**, since it
 unlocks UIless test iteration — but that's a larger commitment.
