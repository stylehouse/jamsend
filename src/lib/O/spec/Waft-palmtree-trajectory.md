# Waft transport — Lies/Lang req map + open faults

`Waft_spec.md` owns the design and the Waft-gardening concept (What/Doc/Point grammar,
 +time branch/dive, carry-over, the cave metaphor).  This doc owns the implementation
  slice: the live `w:Lies`/`w:Lang` req map and the open fault list.  Anything about
   *the concept of a Waft* rather than its plumbing now lives in `Waft_spec.md`.

Pointers for material that moved out:
- Cursor model, What/Doc/Point grammar, Interest/LE design, NaviCado — `Waft_spec`
  §"Interests", §"The cursor the wire carries"; `Wire_spec` §5.
- Branch + dive (↓/↘ +time), Dip split-point, carry-over, secondary strip —
  `Waft_spec` §"`pause | rwnd | +time` transport", §"Carry-over heuristic".
- `req%mutated` engine semantics — `Hovercraft.design` §5 + Handover.
- `req:timemachine` placement — `Waft_spec` §"Open questions".
- Notation / verbs / ttlilt / Point class — `NOTATION.md`, `Hovercraft.design` §5,
  `Waft_spec` §"Point class".

---

## Architecture (post Spotlight-Interest)

```
w:Lies
  /%examining
    /%Spotlight           sc.src ($C → %What | %Doc)
    /req:timemachine      sc.playing:0|1 — playback engine; seeded by req:acquire
  /req:wants              cursor-intent accumulator
    /%want,$ts            c.src → wanted C; sc.kind: click|drag|step|next|cold
  /req:desire
    /req:acquire,maz:9    gate; holds until a Waft is locked
    /%Waft,key            c.src → locked Waft
  /req:Furnishing,path    doc-open RPC; seeded by wants resolver
  /req:Cortex,path        compile-and-settle workforce (LiesCortex)
                          sc.gen_path, sc.source_dige; c.write_t0 (transient)
                          parks on e_Lies_compiled; settles when LiesStore_write finishes
  /req:Store,eternal      all IO reqs live here; LiesStore_run rq.do() drives them
    /req:LuxuryLiesStore_write,path  source-file save with pull-before-push (noserial)
    /req:LiesStore_write,path,dige
    /req:LiesStore_read,rw_name
    /req:LiesStore_listing,rw_dir
    /known:path           last-known dige + kind (read|write) + at — Store impression
  /%Store:1               < known:path to move inside req:Store (deferred)
  /%Opt:1
    /%nogen:1             skip write + Pantheate notify entirely
    /%softgen:1           render %Output, don't write gen/ to disk

w:Lang
  /%Languinio
    /%LE                  same-object hold → /docks/%dock:$path/%LE
                          //   installed at Lang_plan; unarmed until first cursor move
    /%Interest            sc.src = working clone root; sc.in_What, in_Doc, in_Point
                          //   in_Doc keys req:ingredients; in_Point keys decoration
    /%dock:$path           same-object hold → /docks/%dock:$path
  /req:workon
    c.src                 latest cursored TheC (stashed by e_Lang_workon_update)
    //  do_fn = Lang_workon_drive — thin per-tick driver; roai's each stage with its
    //  input signature (un-finishes %permanent on drift), then pumps the pipeline.
    /req:understanding,maz:3,permanent   re-arm LE + flush; sets %Interest
      c.armed_src         identity-keyed re-arm gate (memoised)
      sc.what             cursored What|path label for the snap
    /req:ingredients,maz:2,permanent     the wanted %Goods, from %Interest.in_Doc
      /req:furnishing,path,permanent     one per wanted dock; gate + ttlilt +
                          //   dock_askies pull.  Finished when dock has content_dige.
    /req:instrumentation,maz:1,permanent compile + graft on the active dock
      sc.have_methods, sc.n_pmirrors     convergence markers (results live on dock)
    /req:push             encode → replace → verify; /%dirty fault child

  /docks/%dock:$path
    /%Text                sc.dige, sc.disk_dige, sc.disk_rev  — text metadata visible in snap
                          c.text: string  — source string, hidden from snap (moai to update)
    /%Compile             c.pending (transient) — in-flight flag; replaces old %Pending:1
                          → %methods, %Output (sc.gen_path, sc.source, sc.source_dige)
    /%Pmirrors
      /%Pmirror,$waft_key,$spec
          c.src_clone   → governing clone (for req:Showing to reach c.U)
    // req:Languish stages text_loaded → compile only;
    //   req:grafted removed — Lang_settle owns all grafting.
    /%LE
      /%State           sc.armed | sc.changey | sc.stale
      // %push_dirty    fault child; not yet in reqy fault UI
      /%Seem:origin     Se:Selection, C:$src    — awareness; goners/neus = stale
      /%Seem:working    Se:Selection, C:clones  — editable clone tree;
                        //   clones are shallow: sc copied, no children.
                        //   What/* cloned one level; Doc/Point sub-trees resume on push.
        /%Demonstrations:working
          /%Understandable   per-clone U sphere
              sc.unshowing|unaccepted
          //$C
              sc.class etc! culture space
```

---

# important todo

```
// ── Lang / compile ──────────────────────────────────────────────────────────

// < C|U-edit should cause encode: U mutations (unaccepted/unshowing) don't bump
//   Seem:working.version, so settle's encode gate never fires after e_Lang_LE_drop
//   / e_Lang_LE_edit, etc. To this end... hakd() shall be used by something used for
//   D/changelog,sphere:C|U,... which may be able to track value tweaks over time soon
//   but we shall just use it to know if anything changed, and for individual C revert,
//   as opposed to taking the LE_pull again to reset the C.

// < react to UI:Waft** mutations, via LiesPersist's:
            H.watch_c(waft, async () => {
                H.Lies_sync_waft_docs(w, waft)
                H.Lies_waft_save(w, waft)
                await H.Waft_link_up(waft, waft)
            })
     or maybe call a method to notify of such changes...
      So OC change may want pulling.
        It's a bit hairy... Incoming changing OC** might intersect the targeted OC**
          either way some refs have to change... we have to Selection.process seamlessly when
          new decodes of Waft emerge.
        Check our target.up chain is still valid... C.c.up.o().includes(C)
          Wind up|backward somehow? Our spot might suddenly be unpointable.
          TODO this, we'll just have to navigate ourselves...
        So OC** can spontaneously change via Waft reload, it becomes pullable...
        If C is cleanly pulled from the previous-OC, the new-OC is automatically pullable,
          even though it has a difference to it.
      So OC change may want pulling into C immediately, showing up into Pmirrors etc.

// < retargeting the LE away and back to mutated C** should resume as it was, not pull|reset.
     LE would need to target various perhaps unconnected bits of D** to resume, by path...
      Waft:$path (/namey-as-id)* is the whole locator of C**
       it needs the Se to decide how much is needed to be namey-as amongst its peers
        see also Stuffing
     so resuming C you tweaked while surfing around... have reset button.
      reset them if we reset all of Waft...
     having a generic read|writable with resettable client... indeed.

```

---

# Open faults / futures — Lies · Lang · LiesStore · LiesCortex · LiesEnd

probably won't resolve these before moving on with other work.

Ordered roughly by severity and actionability.  Fault numbers are stable; gaps
 (1, 3, 12, 17, 19, 20, 21) are items since resolved or dropped — see git history.

---

## Active faults — wrong behaviour today

### 2. push verify false-positives when clones were dropped  *(LiesEnd:308, 574)*

`e_Lang_LE_push` verify phase: after `LE_replace_back`, it re-pulls and re-encodes.  An unaccepted clone's absence looks like a goner on the origin walk and `LE_encode_compare` calls the push dirty.  `req:push/%dirty` stays open forever for a push that actually landed.

The fix the comment names: before `LE_replace_back`, iterate clones with `U%unaccepted` and stamp `bD/was_disincluded:1` on each of their D nodes.  Then in `resolved_fn` (inside `o_Seem` → `Se.process`) recognize a `was_disincluded` goner as expected and suppress it from the dirty count.

`LE_push` (the inline version used by test snaps) has the same hole at line 574.

---

### 4. write error leaves req:Codebit waiting forever  *(LiesStore:460, LiesCortex)*

`LiesStore` Phase 1 now logs a write `reply.error` (`LiesStore:460`), but on error it still does not stamp `write_finished` — so `req:Codebit` parks on a `write_finished` that never arrives and the Codebit stalls permanently.

Minimal fix: on write error, the Codebit should finish-with-error rather than wait; give Phase 1 an error path that wakes it instead of only `console.error`ing.

---

## Stubs with a clear next step

### 5. Doc close is incomplete  *(Lies:112, LiesStore:202)*

`Lies_sync_waft_docs` is the `%Good` GC hook — when a Doc path leaves every
Waft it should drop the `Good,type:'text/Doc'` slot.  It does not yet:
- drop the `%Good` (body is a no-op stub)
- fire anything to Lang to close the dock (the Languish req, the CM view, the
  `%dock` particle)

A removed Doc stays loaded in Lang, compile-able, and editable.  The watcher
wired in `LiesPersist` fires `Lies_sync_waft_docs` on every Waft change — the
hook is right, the body is incomplete.

Sequence needed: find the Good → drop it → if a dock is open in Lang, fire
`e_Lang_close_dock` (not yet written) that drops the dock particle, dispatches
CM destroy, and clears active_dock if it was that doc.

Note: `req:Open` no longer exists — Doc provisioning is now content-keyed on
`%Good` with the `dock_askies`|`dock_content` seam; no per-doc req to sweep.

---

### 6. Waft and Doc rename are stubs  *(Lies:115,191-197)*

`e_Lies_rename_waft` and `e_Lies_rename_doc` both `console.warn` and return.  The spec particle shape is already in Lies' header (`%waft_rename_job`, `%doc_rename_job`), so the crash-safe job concept is designed.  The implementation path for Waft:

1. `oai` the job particle (so a crash mid-rename can resume)
2. write the snap at the new path via `LiesStore_write`
3. move all `%Doc` children to the new Waft particle
4. delete the old snap (a new rw_op:'delete', or write '' and rely on the file system convention)
5. drop the job particle

Doc rename additionally needs a gen/ rename (delete old gen path, write new one) and a Lang dock re-path.

But the single-Waft path is only half of it: a rename has to reach **every other Waft
that includes this one**.  That wants a join table — the inclusion graph — the way
Creduler leaves `Story/Name/Credulation.snap`: keep, per Waft, a list of the Wafts that
include it, and distribute the rename to each includer.  This implies a Waft must be
**owned by some agent that can accept a rename job** — close to Lies, but its own
responsibility, not anything below it in the req tree.  Everything_todo-level work, not a
stub to knock off here.

---

### 7. LE_available_ops not wired to req:checkout  *(LiesEnd:879)*

`LE_available_ops(what)` computes the full reachable-move set from the current cursor position, with destinations and labels.  NaviCado falls back to static ↑←→ buttons because the result is never stamped onto `%LE/%moves.sc.ops`.

Wire in `Lang_settle` after the graft step: call `LE_available_ops`, write the result to `settle.oai({ moves: 1 }).sc.ops`, bump LE.version.  NaviCado then replaces static buttons with the computed chip set.

---

### 8. bookmark_vanished is a pure stub  *(Lang:1511)*

`Lang_bookmark_vanished` warns and stamps `%vanished`.  The re-anchor intent:

- scan the current parse tree for the nearest surviving node with the same `Line:N` or same `label` text
- re-dispatch `addBookmarkMark.of({ id, from: recovered_from, to: recovered_to })`
- update `bm.sc.from / bm.sc.to`

Copy+paste recovery (Lang:1516) is a second pass: compare paste-inserted text chunks against `bm.sc.label` of vanished bookmarks and re-anchor any match.  Both are feasible with `syntaxTree(state)` already imported; the hard part is the scoring function.

---

## Design directions — no behaviour change, cleaner code

### 9. req:desire wrapper could collapse  *(Lies:410)*

`req:desire` now holds only the Waft lock (`%acquire`) and seeds the timemachine.  The comment notes acquire could move to `w:Lies` directly, dropping the wrapper.  The snap benefit is a shallower tree; the main reason to do it is that desire's current shape makes it look like it does more than it does.  Leave until the timemachine and git slots are settled — they'll clarify the right home.

### 10. LiesStore_write dige-dedup dance → req%mutated  *(LiesStore:420)*

The existing approach: `drop_finished` on the old write req, scan in-flight for same dige, spawn fresh if needed.  The comment marks this as workable but not the right model.  `req%mutated` would let a stampede of writes land on one req that always carries the latest `rw_data`; Phase 1 would see only the final content.  Needs `req%mutated` to be implemented first.

### 11. e_Lang_workon_update → e:operate  *(Lang:656)*

The comment proposes merging this into `e:operate{ LE, op:'pull', src }`.  Low priority — the dedicated handler is 5 lines and `Lang_settle`'s `armed_src` identity check already makes re-entrant pulls cheap.  Worth doing only when the operate dispatch table gets a broader audit.

---

## Larger features

### 13. Full doc-level Good lifecycle  *(Lies:113)*

The comment groups `%LiesStore_writeCarefully / %surprise_read / diff per Good,type:'text/Doc'`.  This is the whole per-file disk-awareness story: Good is the single carrier of disk state.  The remaining pieces are (a) re-read on external change (TTL or watch — fault 14) and (c) the full close path (stub 5).  (b) the surprise diff UI is done — `ui/DocDiff.svelte`.

### 14. Good TTL re-read (req:refresh)  *(LiesStore:627)*

`Good` has `// < req:refresh — TTL-based re-read (not yet)`.  Currently the only way to force a re-read is `delete good.c.content`.  A `req:refresh,ttl:N` child would re-zero content after N seconds, triggering the read path again.  The `roai-corpse audit` is a prerequisite: you need to know a Good is still needed before refreshing it.

### 15. Multiple-ghosts-per-runner  *(LiesCortex:391)*

`req_Rundown` uses all Codebits as its input set.  The generalisation: each Rundown carries a filter (by path glob or explicit list) and computes its moment from only those Codebits.  Multiple Rundowns could then run different test methods over different ghost subsets.  The moment-id hash already uses sorted diges; the filter just changes which diges go in.

### 16. next_doc hierarchy traversal  *(LiesEnd:142)*

`e_LE_operate op:next_doc` steps the flat result list of `Waft_cursor_candidates`.  The candidate generator already DFS-walks the What tree, but the result is flattened; when a `%What` has children expanded via branch/dive, `next_doc` should descend into them rather than skip across the flattened siblings.

### 18. nested Waft save  *(Lies:114)*

A Waft can hold `%What` nodes which can be other Wafts logically.  `enWaft`/`deWaft` serialise a single Waft, but the snap format and protocol for a Waft-*within*-a-Waft is not designed.  Deferred until there's a concrete use case.

---

# Other todo

Probably won't resolve these before moving on with other work.

## req:Cortex write_finished ordering

Currently guaranteed by `LiesStore_run` running before `LiesCortex_run` in the tick.
If that ordering shifts, Phase 1 should stamp `cortex.sc.write_finished` directly
instead of relying on call order.

## push_dirty not yet wired to req fault particle

`push.oai({ dirty: 1 })` exists in the push cluster; nothing reads it for display or
surfaces it in the reqy fault UI.

## req:Showing has no req particle yet

`Lang_show_pmirrors` is the body but is called directly from the Lang tick.  As a
proper open-ended req it would survive cursor-absent ticks — fold-toggle / class
changes from a U-edit need a repaint even when `Lang_settle` returns early because
there's no armed src.

## pre-pull fallback in Lang_graft_points_once

The `interest.c.LE` absent path reads live Points off `src_C` directly — a pre-LE
fallback that should be eliminated.  `interest.c.LE` should always be set before graft
runs; ensure `Lang_settle` wires it before calling `Lang_graft_points_once`.

## src_clone on Pmirrors → workingC

`src_clone` on Pmirror particles should eventually become the whole `Seem:working C**`
so `Showing`'s decoration path is unambiguous for all clone shapes, not just the
single-clone case.

## e_Lang_LE_drop demote round-trip

Demoting a clone (drop → unaccepted) currently takes a full cursor-move cycle before
the encode re-runs and the UI reflects the change.  Should be immediate on the next
think after `e_LE_mark op:drop` — which the U_serial fix (important todo 3) also
addresses; these are the same gate.

## stale spinner: req:encode should clear spinner:stale

`spinner:stale` is set in `Lang_settle` checkout when `%State.stale` is present.  It's
cleared on the next checkout (cursor move), but if no cursor move happens after an
encode-compare that comes back clean, the spinner lingers.  `LE_encode_compare` (or
the encode gate in `Lang_settle`) should also drop `spinner:stale` when `!dirty`.

## Se_o as standing watch

`Se.process` (and the `o_Seem` wrapper) is call-driven — invoked explicitly by `LE_pull`
and `LE_encode_compare`.  A standing-watch form would re-run automatically when its
input C** changes, without needing a fresh pull.  Design not yet settled — this is the
same shape as `Wire_spec`'s standing wire / `%subscribe`.

## req:wants never prunes

Wants accumulate indefinitely.  A sweep keeping the newest resolved + a bounded ring
of recent unresolved is the eventual shape; nothing reads the full history yet so the
accumulation is harmless but will eventually need a bound.

## survey fictional worth

`caving()`, `assail()`, `regroup()` in Lang.svelte are vision documents for
diving into expanding code spaces (Cyto-within-Cyto), sauntering into a codebase
(lexing/stemming/threads of inquiry), and the Map (Selection.process over function
calls + io expressions).  Worth reading when scoping what comes after the current phase.
