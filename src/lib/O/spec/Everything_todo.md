# Everything still moving

A cross-spec sweep of what is in motion and what is deferred-but-load-bearing,
 distilled from a parallel read of the spec corpus. Lies/Peeroleum is set aside
  at the bottom — this is the everything-*else* picture. Correct anything stale;
   this is a snapshot, not canon.

**2026-07-29 addition:** **Snap depth limit — the `max_child_depth` scare, resolved.**
 The human never agreed to a snap depth limit, so the cap on the one snap/world view was
  **REMOVED**: `LiesFunk` `world_snap` (`runner_ask world`) now encodes the full tree
   uncapped. Recorded fixtures (`toc.snap` via `encode_toc_snap`, numbered `got_snap` via
    `snap_H`) were **never** capped — **no re-record needed** (full Story suite to be run
     once live to confirm empirically). The `max_child_depth` PARAMETER stays as a legit
      option; one deliberate cap survives — LangHold `Seem_toString` depth-0, the Lang
       push-state equality comparator (NOT a snap; uncapping breaks edit-detection),
        flagged for the human. Full blast radius in `spec/Snap_depth_todo.md`.

**2026-07-27 additions (doc-sweep + human triage):**
- **LakeSearch — review it.** The universal-search Story Book is *recorded*
   (`wormhole/Story/LakeSearch/001.snap`) but the human has **not seen it run** — verify it on a
    live runner. Search v1 is LIVE (`Lies_search` in `LiesFunk.svelte` + `Searchbar.svelte`); the
     owed follow-on is Stemdex v2 (region-partitioned scan + `%Errand` reindex, `Stemdex_spec §3-4`).
- **The Lies+Lang frontier is real but PARKED ("not the day for it" — human):** P7
   collapse-the-cursor (`Lies_handover §7`), Stemdex v2, and wiring the built `LangSion` IOing
    oracle into `LangCompiling`. Not this push — catalogued in `Frontier.md §5`.

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

### Toplevels — BigQualand & what pours through it
The `/` root **is** the music scape now (`routes/+page.svelte` mounts `V/BigSoundland`,
 not redirects — an invite URL's `?I=…` must survive arrival untouched). Underneath sits
  **`BigQualand.svelte.ts`** — the *aufheben* of the two rooms: the ONE machine (construct
   H:Mundo → Auto activates a Book → pump `think`), with the OOM trap baked in (compute on
    local `h`, assign `$state H` once, never read H inside the construction `$effect`).

It **diversifies not by forking the machine but by the medium poured through the one
 substrate** — which is just the one-bet restated (*same legible living matter, pour music
  through it first*):
- **BigSoundland** (`V/`, served at `/` and `/BigSoundland`) — the music scape, Voronoi
   stained glass; identity `sound`, machine-role `runner`. Self-checks via the **Sounditron**
    Book (two valid outcomes: a track playing, OR no peers online).
- **BigWordland** (`L/`, `/BigWordland`) — the editor room, Lies+Lang in disguise; identity
   `word`, machine-role `editor`. Self-checks via the **Educarium** Book.
The finer `word|sound` rides `H.c.id_role` for the identity layer and NEVER reaches the
 machine, which stays two-valued (`editor|runner`). Each room's diagnostic Book **lurks in
  the background of a real end-user page** — a shortfall (no audio, no peers, a compile fault)
   surfaces as a coherent error so a real user becomes a reporting test-probe. That IS the
    verdict seam; there is no separate qual Story. A **third** toplevel would be another
     *medium* poured through BigQualand, not another machine.

**Educarium's latent ambition — parked (2026-08-28, the owner).** Today `L/Educarium.svelte`
 is the *thin* BigWordland diagnostic Book: it wires editor-flavoured Lies/Lang/Pantheate and
  opens one Waft (`?W=`, default `Ghost/Net/Easy`) — Editron's sibling recipe, nothing more.
   But its NAME carried a bigger intention: a **"fake toplevel for a nice code experience"** —
    a floaty, **searchbar-driven code-mining room** (mine / search / fluidly browse code as the
     primary surface), *never fully built on*. So Educarium marks the seam where BigWordland
      could grow from "the editor, opened on a Waft" into a genuine code-**exploration**
       toplevel. Relatives already in the tree it would stand on: `Lies_search` + `Searchbar.svelte`
        (search v1 LIVE), Stemdex v2 (region-partitioned scan), the **All method def|call index**
         TODO above, and the StemHive. Keep the Story stub (`wormhole/Story/Educarium/toc.snap`,
          unrun — no `NNN.snap`) as that room's placeholder self-check: it's **latent, not dead**.
   (Its twin AwFloat — a bare lie-dige stub with no such intention — was dropped 2026-08-28.)

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
- (vague, 2026-08-05, the owner: "maybe we've outgrown that") `replace()` is a
   whole-container transaction that `empty()`s the House's children AND bumps
    mid-transaction, so the House is visibly childless across two awaits. Atime
     shields tick-participants, but a `$effect` watcher is UItime — the
      mid-transaction bump invites it to re-read at the worst moment (the
       `reset_interval` fault, `Mag_v1_handover.md`: Vytui destroyed its whole
        subtree ~17×/min off exactly this window). Either `replace()` holds its
         bump until the children are back, or its surviving callers migrate to
          `oai` merge-in-place and `replace()` retires. NOTE the shaping-up
           pattern that may already be the answer (`reactivity_docs.md:71`,
            "same shape Langui uses"), stated by the owner 2026-08-05 as three
             stages: **reactive read → queue casual read at a sane time ASAP →
              unpacking into $state for the UI proper.** That is: (1) the
               `$effect` reads only `vers` — a cheap subscription, never the
                tree; (2) it queues the real read into `H.UItime()`, which
                 waits on the Atime mutex for settled state; (3) the settled
                  snapshot is unpacked into plain `$state`, and render code
                   reads ONLY that. Under this rule the childless-`replace()`
                    window becomes unobservable by construction (render never
                     touches transacting state) — the remaining cost is only
                      wasted wakeups from mid-transaction bumps. Vytui's sin
                       was collapsing the three stages into one. If this gets
                        blessed as the rule, it wants reconciling with
                         `Wire_spec.md`'s `%subscribe`/wake vocabulary.

Resolved (was a rumour): Stuffing no longer over-creates instances. One
 `Stuffing` per component lifetime (`Stuffing.svelte:30`); components
  `register_stuffing` into `H.stuffing_registry` for *unreactive* version-based
   updates. A ~0.33Hz heartbeat (`Housing.svelte:415`, `setInterval … 3000`)
    plus a 200ms throttle, a microtask kick on register, and a piggyback inside
     each `H.clear()` drive `check_stuffings()`, which content-diffs `stuff_matrix`
      per entry (`matrix_changed`) and notifies only changed ones, all in one
       flush. Throttle strategy settled.

## Not nailed down that should be

- **Story runner: a `release`→`run` standup RACE, measured 2026-09-04, LOCATED NOT FOUND.** Back-to-back
   `MusuHeist`: no gap wedged 2/6 (`phase:begun, n:null, steps=0`, console silent after `▶ Story subHouse
    created`), 6s gap wedged 0/6. Seam: `auto_reset_story`s teardown vs the posted `think`. Sharpest
     candidate: the previous run's `story_save` write still pending in the wormhole `rw_queue`/`LiesStore`
      when the next run's toc READ queues behind it and the House owning the write is dropped — the
       "begun/n:null + story_save jam" signature. Finding: `Story_hygiene_todo.md` §0a.2. Fix design:
        `Story_future.md` §8.3 + §15 (the drive/teardown as req-owned ttlilts). Another-day'd by the owner.

The decisions the specs *defer* but that gate real work:

0. **RE-RULE THE BOOLEAN ENCODING (owner 2026-08-31): stop banning Boolean — intelligise it.**
    The standing law ("a snapped boolean rides as `1` or absent, never `false`/`0`") makes every
     flag site contort (`x ? 1 : 0`, delete-not-false) when the tidiest normal code just wants
      honest booleans.  The ruling: a JS boolean in sc becomes LEGAL — `true`/`false` encode flat
       as the bare words, and the DECODER intelligises the bare strings `true`|`false` back into
        real booleans.  The one edge — a genuine STRING that happens to be the word "true" or
         "false" — rides the existing use-json trick: the ENCODER notices the collision and marks
          that line as needing JSON (exactly how objecties handles unclean scalars today), so
           string-ness survives the round trip and nothing is ambiguous on the way back in.
            enLines is the seam for both halves.  Open sub-rulings before landing: (a) query
             semantics — `{k:1}` stays the presence wildcard; decide whether `{k:true}` matches
              literally (probably yes — it's a value, not a probe) and what `exactly` does to it;
               (b) migration — old `1`-style flags keep decoding as before (no mass re-record);
                fixtures churn only where a mint site actually flips to booleans, so flip them
                 deliberately, subsystem by subsystem; (c) update CLAUDE.md's boolean law + the
                  Coding_guide when this lands.  Until then the `1`-or-absent law STANDS.

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

**Cluster addressing — `header.from` is not an address (well beyond v1.0).** Surveyed the whole
 ping|pong / send / deliver path 2026-08-08; the mess and its tells live in `ClusterAddressing_todo.md`
  §6. Short version: four "who sent this" channels, and the authoritative-looking `header.from` is the
   one field neither routed on nor verified — so runner acks mis-route to the role-slot Pier (dev emits
    strand), N runners share one editor inbox (reused-seq false collisions), and a from-less ping fans
     out to a false-live pong. The **production-facing** hole (an unauthenticated `become <prepub>`
      shadow-subscribing a verified identity's frames) is **already fixed** in `relay.ts` +
       `relay-test.ts`. The remaining fix — unify `header.from` onto the hello-bound prepub, delete the
        three body-`from` patches — is **spine surgery** (`Peeroleum.g` recompile → `pinned_stable`
         promotion → every wire Book re-baselines) and it lands dead-center in ClusterAddressing §4/§4.5's
          unresolved address-model decision. So it waits for a dedicated addressing session, not a
           go-live week. The end-user path (Swarm, `to:<prepub>` + signed voucher) never trusted
            `header.from`, which is why this is deferrable.

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

## 2026-09-05 — THE GAP AUDIT: promises in the docs and faces that the code does not deliver

A subagent's read-only sweep (specs' §0/NOT-built/deferred sections, the user-facing prose in Radio_circuit §A-C /
 SoundPooling §0 / Crew §0 / Swarm_spec §10, every face's sentence strings, the eight stash pillars, the revoke paths, the
  Door rows), verified against the `.g` verbs and their callers. Ranked by user impact. Known-and-excluded going in:
   the ♥ handoff (built 2026-09-05 as MusuHandoff), friend-Pier crew replication (next), the album widen, the encoder
    drift, the six stale tocs.

# "But we haven't built this" — audit of promise vs. delivery (2026-09-05, read-only)

Scope: spec `§0`/owed sections, the user-facing prose in the faces, the stash pillars, revocation caches,
the Door row actions. Excludes the five KNOWN items (♥ handoff frame §7.5, friend-Pier non-replication,
album widen §C, MusuOgg/MusuReap encoder drift, stale toc diges). Ranked by user-visible impact.

## Gaps

| # | the promise (quote + file:line) | what's missing | size | evidence |
|---|---|---|---|---|
| 1 | Link cell offers **"Captain — takes the helm"** and "mint a Captain link — … resume from backup" (`src/lib/O/ui/LinkDevice.svelte:739,744`; tooltip 734 "this device stands down to a Cave"); Cave side shows "Captain (resume)" (737) | The helm is **Book-proven, not live-walkable**: a promoted body signs as the soul but keeps advertising/binding its own name, so sealed friends refuse it; `Swarm_crew_standdown` (`Ghost/S/Swarm.g:398`) raw-writes the Identity mainkey, never `thang_put`s the fresh key nor re-homes stash/account dir, so a reload after a hand-over resurrects the old founder. Cave-minted "resume" (⏰ "resurrect my Captain") is untested. Only live caller of `Swarm_crew_captain` is the ferry-ACK seam (`Swarm.g:1763`). | L | `Crew_todo.md` §0 ⚑ "STILL OPEN … Book-proven and NOT live-walked — treat it as design-complete, implementation-owed"; A½.2 "⚠ 'Caves by default resume the Captain' is BROKEN under cert-crew as built"; A.5 "⏰ still untested". Not verified live. |
| 2 | A crewmate "keeps its own key, and serves the Captain's shared library" (`LinkDevice.svelte:577`); crew ⇒ Music grants both ways (`Crew_todo.md` A½.1 ✅) | A **friend's Cave body cannot pull from me**: `Swarm_share_granted(peer)` and `Swarm_share_present(from)` look up `Pier,pub:<from>` exactly (`Ghost/S/Swarm.g:4364-4367, 4383-4385`), no `Swarm_pier_of_body` fallback (which exists at `Swarm.g:6564` and the hear funnel uses). `Repli_allowed` is called with the frame's `h.from` — a body prepub — (`Ghost/N/Repli.g:954`) and answers "consent refused — grant revoked or wrong peer". | S | `Crew_todo.md` A½.1 "⚠ ONE BUG STILL BLOCKS A CAVE SERVING THE SOUL'S FRIENDS … one line each; do it with MusuPoolBytes" — still in the tree today. |
| 3 | Door ✕ on a friend: **"forget {name} — retires this friend (it can be re-invited later)"** (`src/lib/O/ui/DoorFace.svelte:701`) | Re-invite of the same keys stays dead: `Swarm_pier_forget` → `Swarm_revoke` mints a **permanent** `NotGrant:Music` (`Swarm.g:5286-5287`, log line 5295 says "permanent"); `Swarm_pier_live` matches NotGrant by `by`+`for` (`5316-5317`), and the tombstone-retire at a fresh redeem is "Scoped to MyCave: the friend %NotGrant:Music permanent-unfriend law is never touched" (`5340`). Device links (`5279-5283`) DO get the re-link path — only the friend half of the sentence is false. | S | Code read; `Swarm_pier_forget` has **no Book and no spec** (grep of `Ghost/Story/*.g`, `scripts/*.spec.ts` = 0 hits). |
| 4 | Ejecting a crewmate "travels to every crewmate and to friends of your soul" (`DoorFace.svelte:633`) — and by symmetry the user expects un-friending to be felt by the friend | **Unfriending never leaves the device.** `Swarm_revoke` writes the NotGrant under my Pier and settles the account (`Swarm.g:5219-5232`); no frame kind carries it (grep for a revoke/unfriend kind in `Swarm.g`/`Peeroleum.g` = none). The friend's Door keeps listing me, their radio keeps dialing me and gets "consent refused" (`Repli.g:954`). Contrast: crew ejection does travel (`NotGrant:Crew` on the ledger, `Swarm.g:213,259-260`). | M | `Swarm_spec.md` §12 lists no wire revocation; `Crew_todo.md` §12.3 "Revocation that travels" is design text only. |
| 5 | §A "forgetting, on your behalf, the things you shrugged past"; §3 "HOW IT FORGETS"; §7.7 "the dedup set … grows by `heard_ttl`" (`Radio_circuit_todo.md:210-218, 458, 738-739`) | **`Heard_gc` is Book-only.** Defined `Ghost/M/Heard.g:400`; `heard_ttl` is read only inside it (`Heard.g:403`); the only callers are `Ghost/Story/Heistation.g:6507,6517`. Live, a 30-day hearing mark never expires (a track heard once is never re-offered by the dial until a phone reload drops the un-stashed marks), and on a laptop the account snap's `Mag:heard` grows unbounded — the §6b hoard the doc forbids. | S | `scratchpad/bookonly.sh` sweep: `Heard_gc core=0 ui=0 story=2`. |
| 6 | "A phone keeps its pools across a reload with no folder anywhere" (`Crew_todo.md` §0 pools pillar); the pool "keeps rolling N MB of music in browser storage" (`PoolFace.svelte:87`); SoundPooling home holds "the material shelf" (`SoundPooling_todo.md` §0) | **The pooled CATALOG is not durable on a phone.** `Swarm_restash_pools` carries only `Pool` rows + `Consent` + `budget_mb` (`Swarm.g` `Swarm_restash_pools`, ~3560-3585); the Dexie thang holds only `{pub,key,prepub,born,friendly}` (`src/lib/O/Auto.svelte:384-390, 427-431`); no verb rescans OPFS `pool/` into `stock > Mag:shuffle` (grep `Ra_pool_(rescan|restock|scan|census)`/`pool/`+`dir(` in `Ra.g` = none). After a phone reload the compartments return but the `Record` rows do not: the chip reads `empty`, the steward re-pulls, the old OPFS files are orphans `Ra_pool_off` can no longer `unfile`. On a laptop the account snap covers it (the home hangs under `%Identity`). | M | Not verified live (no phone here). `SwarmReboot` swears compartments+policy only (`Ghost/Story/Swarmation.g:4693`). |
| 7 | Siphon destination: "tap tracks to SIPHON them entire … play them offline in a Radio that obeys you (next/prev/pick) … stamp TAGS … a tag IS a playlist" (`Siphon_todo.md` §0:3-7); ShuffleFace tells the user "flip pool_steward on, or **siphon a track**" (`ShuffleFace.svelte:226`) | No face lets a person siphon or tag: `Siphon_tag_def/_tag_apply/_tag_unapply/_playlist` are **Book-only** (`bookonly.sh`: core=0 ui=0); `Siphon_pull` is reached live only via the steward's fills (`Ra.g:4781,4819`), never a tap; `SiphonFace` "not yet built" (`Siphon_todo.md` §5.3 header, `SoundPooling_todo.md:689`); `Radio_prev`/`Radio_pick` do not exist (RadioFace has only `Radio_skip` "next", `RadioFace.svelte:157`). `Phone_instrument_todo.md` §0 tag gestures likewise unbuilt. | L | Explicitly future work in both docs, but the ShuffleFace sentence sends a user to a verb they cannot reach. |
| 8 | §B: "Under the download glyph a small line says *1 waiting*" (`Radio_circuit_todo.md:222-223`) | The Radio face has no waiting count (`RadioFace.svelte` — `waiting` appears only in the solo "waiting on X's music" line, :88). The count lives in the Haul cell only ("N waiting", `HaulFace.svelte:213`). | S | Prose vs. face. |
| 9 | PoolFace sentence — the owner's "how full is it" (`SoundPooling_todo.md` §0 "Next (in order)") | `pooled` is computed (`PoolFace.svelte:38-39`) but shown only in the small-bud tooltip (`:83`); the sentence (`:87-93`) shows budget + free GB, never used/pooled. | S | Listed as owed in the doc. |
| 10 | Door ledger: "a forgery or an `offline` is a fact about an event and is never forgiven; that is precisely what the door ledger exists to remember" (`Crew_todo.md` §0.0 item 3) | `%rebuff` rows are minted under the live `%Identity` (`Swarm.g:1972`) and are in **no stash pillar** (`Swarm_restash_all`, `Swarm.g` ~3560: piers/izzes/roots/roster/crew/reaches/pools/heard). On a phone (no account snap) the door's memory dies on reload. | S | grep `rebuff` × `stash|rehydr` in `Swarm.g` = 0. |
| 11 | Door row actions are the way back for every ceremony (`DoorFace.svelte:633,653,701`; Haul row ⏸ ↑ ✕, `HaulFace.svelte:243-250,272`) | **No Book gates them**: `Swarm_pier_forget` (✕ on friend/Cave, and the eject/resign dispatcher) and `Swarm_crew_leave` (Cave resigns) have zero callers in `Ghost/Story/*.g`; `Heist_keep_pause/_first/_cancel` and `Heard_untake` ("let this one go") are covered only by jsdom specs (`scripts/HaulFace.spec.ts`, `HeistUnity.spec.ts`) — never a live-runner Book. `Swarm_crew_eject`/`_captain` are Book-covered (SwarmHelm). | S | grep. Test debt, not a missing verb — every handler resolves to a defined verb. |
| 12 | "add another device … serves the shared library" + SoundPooling "crew (your devices, see Door)" (`PoolFace.svelte:91`) ⇒ the location pool: "shuffle this folder into my pool" / a folder browser over the crew's union catalog (`Crew_todo.md` A½.3) | Not built: no `take:dir` compartment, no folder browser; `Ra_pool_defs` offers `random`/`recent` only. | M | Doc-stated "decide, then build". |
| 13 | Swarm_spec §10 "The coming UI — designed-for, not built-yet": account page, friends list, per-friend grant management (`Swarm_spec.md:523-527`); 🪪 IdHatch listing every identity + snap in/out "still owed" (`:143`); phone QR scan on a PWA/HTTPS origin "owed" (`:627`); name-forfeit error surfacing "unbuilt" (`:660`) | As stated. The invite QR itself exists (`ui/micro/InviteQR.svelte`, `InvitePanel.svelte:24`) and `?Iz=` redeem is live; per-friend grant management has no face (grants are visible only as Door rows). | M | Doc-declared; not re-verified beyond the grep. |
| 14 | "A pool declaration change does not trigger an account write at all … still TRUE and still owed" (`SoundPooling_todo.md` §0 "Consequence 2") | Laptop-side: minting/changing `%Pool` bumps the shelf, not the identity, so the account file lags until something else bumps. Phone-side the pillar covers it. | S | Doc-declared, code not re-traced. |
| 15 | §C "The rule numbers in §2 are a fourth decision with no screen yet; say so rather than hide it" (`Radio_circuit_todo.md:262-265`) | No face for `heard_ttl`/`take_ttl`/mire rules — honest and admitted; listed for completeness. | S | Admitted in the doc. |
| 16 | `Crew_todo.md` §8 STILL OWED: `%Organ` on live bodies; Rung-2 restore (empty Dexie + populated FSA auto-resume); Repli self-lane (joined device fills from the Captain); roster gossip to friends + per-body presence; the `%Pier.sc.pub` holds-a-prepub lie | As listed. Note `Swarm_reach_crew` is Book-only (`bookonly.sh`), the B4 carry-out doer is unbound. | M | Doc-declared. |
| 17 | `Identity_persist_todo.md` §0: "FOUR GAPS FOUND … Re-verified unfixed 2026-08-08"; "Gap 4 is the one that touches every user" | Dated; `Auto.svelte:397-437` comments say `Clustation_pin` was fixed 2026-08-08, so at least part of this §0 is stale. | ? | Not verified; the doc's §0 should be re-read against the tree before anyone acts on it. |

## Promises verified as DELIVERED (coverage of this audit)

- **♥ is the heist button, un-pressable within a moment, durable at once**: `RadioFace.svelte:160` → `Radio_like` (`Ghost/M/Radio.g:3792`) → `Heard_take` with the `Heard_thumb()` window (`Heard.g:222-226`, returns −1 = un-press); stashed by `Swarm_restash_heard` (takes only, `Swarm.g` ~3590) and rehydrated at `Swarm.g:2151`.
- **The share beat turns takes into keeps, and re-arms after a reload from the durable takes**: `Heard_haul_beat` (`Heard.g:543-567`) walks `Heard_takes` and mints one live keep per holder; `Heard_clone_beat` copies verdicts (held/unvouched/landfail) so a wedged holder slot frees.
- **The Haul groups by who is bringing it, with waiting/gave-up/failed words and row verbs**: `Heard_haul_piers` (`Heard.g:571+`), `Heard_word` (`Heard.g:384-390`); ⏸ `Heist_keep_pause` (`Heist.g:2047`), ↑ `Heist_keep_first` (`:2070`), ✕ `Heist_keep_cancel` (`:4078`, arm-twice), "let this one go" → `Heard_untake` (`Heard.g:249`); "you can't lose a heart — only you retire one" holds (no auto-retire).
- **SoundPool = one sentence**: `Ra_pool_start/_off/_budget_set/_who/_recent_on/_recent_set` all exist (`Ra.g:1178-1282`) and are wired from `PoolFace.svelte:57-73`; 0 MB cleans out files via `Ra_pool_unfile` (`Ra.g:1273`); the steward runs live (`Radio.g:1433` `Ra_quarter_serve` + `Ra_pool_fill_wants`, consent = the fills switch); the Radio chip shows SOUNDPOOL / `setup` / `empty` and `setup` opens the cell (`RadioFace.svelte:171-187` → `Sounditron_focus('Pooling')`, `Sounditron.g:1411`). Declarations survive a phone reload (pillar 7, `Swarm_pools_rehydrate` `Swarm.g:3812`).
- **Crew ejection travels and closes every warm cache**: `Swarm_crew_eject` (`Swarm.g:335`) → `NotGrant:Crew` on the ledger, landed on friends' piers (`:259-260`) and crews (`:301-302`); `Swarm_crew_heard` clears `pier.c.voucher_ok` (`:268`); the door refuses "crew ejected" (`:1845`). ✕ semantics by presser (eject / resign via `Swarm_crew_leave` `:318` / bond-only) implemented in `Swarm_pier_forget` (`:5259-5273`). Gated by SwarmHelm.
- **Door "suggest the playing track … lands even if they're away"**: `Swarm_suggest` (`Swarm.g:3933`) stashes under the pier (`Swarm_suggest_stash` `:4006`, capped 24/friend) and `Swarm_suggest_resend` fires off `Swarm_heard_hi`; ▶ plays via `Radio_tune` (`Radio.g:3751`).
- **Now-playing provenance** (UI_seams S4): the "from {friend}" source chip (`RadioFace.svelte:176-178`); "no peers ever, [invite some]" opens the Door (`:197`).
- **Link ceremony**: mint with post choice (`LinkDevice.svelte:222` → `Swarm_ferry_link` `Swarm.g:7030`), keyless ferry folding the account into the Cave's identity, "done" screen, SAS triple ("these three must match"), spent/called-off/missing-code states; Books InvWalk/InvFerry/InvSeal/SwarmSpread.
- **Invite front door**: `InviteQR.svelte` + `?Iz=` redeem, ttl policy (SwarmPolicy), blotter + chain invites.
- **Crew ⇒ Music grants both ways** at the seal (Crew_todo A½.1 ✅) — only the body-prepub lookup (gap #2) stands between it and a Cave serving.
- **Eight stash pillars** exist and are boot-laddered: piers, izzes, chainroots, roster, crew, reaches, pools, heard (`Swarm_restash_all` ~3560; `Swarm_station_up` `Swarm.g:2139-2151`); gated by SwarmReboot.

## Method notes
- Verb sweep: `scratchpad/bookonly.sh` (defs in `Ghost/{M,S,N}` matching Swarm_crew_/Heard_/Ra_pool_/Heist_keep_/Siphon_/Radio_like|source_next …; a verb with 0 non-Story `.g` callers and 0 `src/lib/O` callers is flagged). Flagged: `Heard_gc`, `Heard_seed` (Book fixture helper, fine), `Siphon_playlist/_tag_def/_tag_apply/_tag_unapply`, `Swarm_reach_crew`, `Swarm_ferry_particle`, `Ra_pool_cap_of` (uncalled anywhere).
- Nothing was run on a runner; every "not verified" above means a live walk is still owed.
