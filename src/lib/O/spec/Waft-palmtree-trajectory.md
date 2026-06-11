# Waft palmtree trajectory — reqy migration + What transport

`Waft_spec.md` owns the design.  This doc owns the implementation slice.

---

## What cursor model

A Waft is a tree of What, Doc, and Point — but **What is the base type**.
Doc and Point are refinements; when something sits in the position of a Point
but isn't one, it's another place the cursor wants to visit before returning.
It might stop and take in a Doc with no Points, even.

But for now it's quite strictly `Waft(/What/(Doc|Point*)*)*`, so we can clone
a simple flat list of What/* to manipulate...

```
Waft,Ghost/LakeNets
  What:foundations
    What:story
      Doc:Ghost/test/Story/Peeroleum.g
      Point,method:LakeNetherland
      Point,method:Something
    What:peer
      Doc:Ghost/test/Peeroleum.g
      Point,method:Peeroleum
```


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
  /req:git                Waftlet accumulator; < do_fn pending
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

## LE crux

```
  Spotlight%src = Lies Waft**, LE/Seem:origin $OC
  Interest%src = Lang, LE/Seem:working $C
```

...maybe LE, since it is %dock indifferent, should just be on w:Lang/LE ?

and that's what we have to watch, via every act on LE setting off an elvis to update some state in a controlled fashion (involved %req to watch it complete, etc.)

they've separated their navigation into cursoring the origin right? I suppose LE could abstract that too, presenting a manifold of C** you can read or write.

### LE operation

really unifying and clarifying what req:Languish vs req:workon is supposed to be doing... we need to realise how to reliably set our %Interest and other intentions.


does Seem:working C/* get put into Interest/* ? could be handy - they are invisible at the moment, we only snap the D** and its /U

so ~Interest resolves a %dock to contextify the Points with (which has to be found via the Waft** origin itself, because we may not have it in the cloned subset), may be at What/Doc or What(.c.up)+ (find_Doc_from_What() ?)

### LE clients (NaviCado)

NaviCado wants to know the full What/What/What C-path we're in...
  this is in the corner of the screen while talking through a series of caves full of information...
  it's important to regularly return to depth <3, for a good coherent show.
  having just the What** depth number (if > 1) and the latest What:$label showing 

   < by the way the label isn't appearing right now, just nav arrows (which work) with a blank space where the What label usually is. reactivity problem?

  is a LE feature, I think - knowing the remote....

getting the Interest%src:$C, finding C/* to pump at NaviCado... NaviCado would just be given prop LE from Languinio and talk entirely to it? and not even know it's in a Minimap or Codemirror? because LE knows the remote, it can be the channel of movement between the two. it's obvious really...

LE could take on scurrying around the origin Waft** for some What's relative something, eg. Lies_src_doc_path(), waft_key_of should be find_Waft_path_from_What()? and probably shouldn't exist... yeah, all the passing around waft_key looks like bad programming? we can analyse that...

### LE arrives

And w:Lang/req:workon - or something within it - takes charge! Perhaps req:Languish is a better term, as it is very central work... It provisions care, attention, or favorable conditions.

req:settle gives way to req:Showing... Lower-case (class, level, complexity) and upper.

`req:Showing` only exists as `Lang_show_pmirrors` so far.
`pmirror.c.src_clone` is set at graft time.
As a proper open-ended req it would survive cursor-absent ticks so U-edit
fold-toggles repaint without needing a cursor move.


There's also w:Lies's req:timemachine and req:wants we need to keep in mind when distributing the systemic load into mutable machinations.

any more isolations or interface togetherings we'd like to imagine...


# Future

It may slightly be here already.

---

## Chunk 4c — branch + dive %What** space

The two gestures create new `%What` particles from the current cursor position.
They look like the vector indented lines move when encoding this structure.

### ↓ onwards +time

Creates a new `%What` sibling immediately after the current one in the parent's
child list, which becomes the new cursor target.

### ↘ furthermore +time

Creates a new `%What` *inside* the current one.

1. User selects a split point (between which two Points the new What is
   inserted) — UI TBD; simplest is between the last accepted Point and the rest.
2. Points below the split move into the new child `%What`; Points above stay.
3. The new child What becomes the cursor target; the parent What retains the
   Points above the split.

The dive address (which Points delimit the pocket) is the Dip concept from
`Waft_spec.md` — deferred for now.  Initial implementation: ↓ always dives
after the last accepted/showing Point.

### +time: the carry-over heuristic

When a new `%What` is sprouted off another (both ↘ and ↓), seed its new What/*
with Points still accepted and showing. If one was `U%created_at` recently,
assume we are meant to take that from the old group. `U%created_at` is ephemeral.

The `Seem:working` may be kept around and navigated back to, turning up with
unpushed state and the same C it checked out, if dige still matches.

If we +time away from one What/*, it may play a parent relation... Perhaps if we just
look around, the last few waves of things we have looked at kinda stay,
lurking ever smaller at the edges...
After +time, the prev What's uncarried Points appear in NaviCado below a horizontal line — smaller, fainter, secondary. Clicking one unretires it: `LE_add_clone(current_LE, pt.sc)` copies it into the current What's clone tree and it hides from the secondary strip (its spec is now in the current clone set). Orb-toggling it back to unshowing re-retires it: the clone is dropped from the current tree, its spec leaves the current set, and the Point reappears in the strip from the prev source — undisturbed throughout.

The secondary strip needs no container. It is a pure derived view:

```
prevWhat Points (direct + via Doc children)
    filtered to: spec not in current What's clone tree
```

`clone.c.from_prev = true` stamped at unretire time (on `c`, invisible to encode/push) tells the orb and × apart from freshly-created clones — for those, orb means `U%unshowing` and × means `U%unaccepted` as usual.

```
// < secondary strip looks one step back (LE_what_prev) for now;
//   ancestry depth is open.
```

So the old What/* lurks beneath the current ones, as a different but same-looking
UI, where they can be easily individually brought back from.

I suppose other paraphenalia might lurk longer than the so-ing machine is biting
it too, in ways that can transpire more involvement...

### handling

unshowing is just presentation-facing, for codemirror to do decorations. it'll need flushing to when that toggles?

we might be manipulated to show|unshow by some other system.

unaccepted tries (even if you leave the target, could nag to save|abandon) to push that disinclusion

Other changes to the C push more easily? And pushing Waft to disk or where-ever is a little slower?

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.

---

# Open faults

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

# Open faults / futures — Lies · Lang · LiesStore · LiesCortex · LiesEnd

probably won't resolve these before moving on with other work.

Ordered roughly by severity and actionability.  The `< ` annotations in the source are the primary map; this document traces each one to its consequence and the minimal fix.

---

## Active faults — wrong behaviour today

### 1. surprise_read blocks the write but never resumes it  *(LiesStore:547)*

`req_LiesStore_writeCarefully` detects an external edit (disk dige ≠ base dige), stamps `good/%surprise_read` with the stashed text+dige, and finishes.  Nothing ever reads that stash.  The user's auto-save silently disappears.

The data is all present:
- `sr.sc.text` = the text we wanted to write
- `sr.sc.dige` = its dige
- `sr.sc.disk_dige` = what's on disk right now

What's missing: a UI seam (DocRow / Langui) that shows the conflict and a "push anyway" button that calls `LiesStore_write` directly with `sr.sc.text`, then drops `%surprise_read`.  The surprise detection path is solid; only the resume leg is absent.

---

### 2. push verify false-positives when clones were dropped  *(LiesEnd:308, 574)*

`e_Lang_LE_push` verify phase: after `LE_replace_back`, it re-pulls and re-encodes.  An unaccepted clone's absence looks like a goner on the origin walk and `LE_encode_compare` calls the push dirty.  `req:push/%dirty` stays open forever for a push that actually landed.

The fix the comment names: before `LE_replace_back`, iterate clones with `U%unaccepted` and stamp `bD/was_disincluded:1` on each of their D nodes.  Then in `resolved_fn` (inside `o_Seem` → `Se.process`) recognize a `was_disincluded` goner as expected and suppress it from the dirty count.

`LE_push` (the inline version used by test snaps) has the same hole at line 574.

---

### 3. snap bloat: rw_data and req_sent on sc  *(LiesStore:110)*

`LiesStore_write` parks `rw_data` (the full file content) and `rw_op` on `sc` of the write req, meaning every in-flight write carries its source text in the snap.  For large Ghost files this is significant.  The comment names the fix: make them oncelers (off-snap, on `.c`).  The req already uses `rw_data` only to send to Wormhole; once sent, holding it on `.c` is fine.

---

### 4. write errors silently discarded in e_Lies_compiled  *(LiesCortex:147)*

`e_Lies_compiled` calls `LiesStore_write` but never checks whether `reply.error` arrived on the finished write req.  Phase 1 in `req_Store` does check and `console.error`s, but `e_Lies_compiled` returns before that runs and has no recovery path.  A gen/ write failure leaves `req:Codebit` waiting on `write_finished` that never arrives — the Codebit stalls permanently.

Minimal fix: after `LiesStore_write` returns a req (not null), park a check in e_Lies_compiled that reads `req.sc.reply?.error` — though since Phase 1 handles it, the real gap is that `req_Codebit` should detect a write error and finish-with-error rather than waiting forever.

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

### 12. surprise_read diff view  *(Lies:113, LiesStore:547)*

The full pull-before-push story: detection works (fault 1 above covers the resume), but the intended UI is a diff view in DocRow/Langui showing `sr.sc.text` vs `disk_text`, a "keep mine" button (calls writeCarefully's inner write directly), and a "take theirs" button (`delete good.c.content` to force a re-read).  This wants a diff widget component.

### 13. Full doc-level Good lifecycle  *(Lies:113)*

The comment groups `%LiesStore_writeCarefully / %surprise_read / diff per Good,type:'text/Doc'`.  This is the whole per-file disk-awareness story: Good is the single carrier of disk state, and the missing pieces are (a) re-read on external change (TTL or watch), (b) the surprise diff UI above, and (c) the full close path (stub 5 above).

### 14. Good TTL re-read (req:refresh)  *(LiesStore:627)*

`Good` has `// < req:refresh — TTL-based re-read (not yet)`.  Currently the only way to force a re-read is `delete good.c.content`.  A `req:refresh,ttl:N` child would re-zero content after N seconds, triggering the read path again.  The `roai-corpse audit` is a prerequisite: you need to know a Good is still needed before refreshing it.

### 15. Multiple-ghosts-per-runner  *(LiesCortex:391)*

`req_Rundown` uses all Codebits as its input set.  The generalisation: each Rundown carries a filter (by path glob or explicit list) and computes its moment from only those Codebits.  Multiple Rundowns could then run different test methods over different ghost subsets.  The moment-id hash already uses sorted diges; the filter just changes which diges go in.

### 16. next_doc hierarchy traversal  *(LiesEnd:142)*

`e_LE_operate op:next_doc` steps flat `Waft_cursor_candidates`.  When a `%What` has children expanded via branch/dive, `next_doc` should descend into them.  The candidates generator would need a DFS walk of the What tree rather than a flat list.

### 17. Push on req:git / Waftlet commit path  *(LiesEnd:255)*

The spec intent: a push is a Waftlet commit on `w:Lies/req:git`, which then flushes via the git do_fn to disk/remote.  Currently push lives on `w:Lang` where the %LE and clone tree are.  The bridge (Lies reading Lang's clones without reaching into Lang's reqs) is the missing piece.

### 18. nested Waft save  *(Lies:114)*

A Waft can hold `%What` nodes which can be other Wafts logically.  The snap format and `enWaft/deWaft` protocol for a Waft-within-a-Waft is not designed.  Deferred until there's a concrete use case.

### 19. Lang compiler: async await injection, .$ capture, block verbs  *(Lang:56,70,87)*

Three deferred compiler features:
- **async/await injection** — `async` stamped on def entries but `await` never injected at call sites.
- **`.$ tight value-capture`** — parses as an error node; the grammar token + PeelItem tail rule needed first.
- **block verbs** — `r / roai / oai` with a trailing `{}` block; unresolved value-semantics for bareword args.

### 20. Graft mark vanishing  *(Lang:1494)*

When a full-span edit wipes a graft mark from CM's `graftMarkField`, `Lang_update_grafts` receives an empty update for that id and the Pmirror becomes unresolved.  Relies on a future re-anchor scan, same shape as bookmark_vanished (stub 8 above) but for Pmirrors.

### 21. workon.following diverged state  *(Lang:323)*

`workon.sc.following = 1` (track group cursor) is set at plan time and never cleared.  When a user manually navigates away from the group cursor, `following:0` should trigger a thought-balloon on the breadcrumb.  Needs a comparison between `workon.c.src` and the group cursor's current position, and a UI read of `following` in NaviCado/breadcrumb.

---

## Cross-cutting: req%mutated

Several faults and directions converge on `req%mutated` not yet being fully leveraged:
- LiesStore_write resend (direction 10)
- Codebit re-arm on re-compile (already works — this is the good example)
- req:include re-confirm on re-compile (also works)
- A future %want dedup (a second want for the same src could mutate the existing unresolved one rather than piling)

The pattern is established and working in the Codebit case; the remaining uses need the mutation to be cheap (no `.c` fields that are content-significant) and the do_fn to be idempotent on re-entry.

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

## req:git do_fn

The particle exists; `doai` is called; the do_fn that flushes committed Waftlets to
disk/remote is missing.

## Se_o as standing watch

`Se.process` (and the `o_Seem` wrapper) is call-driven — invoked explicitly by `LE_pull`
and `LE_encode_compare`.  A standing-watch form would re-run automatically when its
input C** changes, without needing a fresh pull.  Design not yet settled.

## req:wants never prunes

Wants accumulate indefinitely.  A sweep keeping the newest resolved + a bounded ring
of recent unresolved is the eventual shape; nothing reads the full history yet so the
accumulation is harmless but will eventually need a bound.

## req:timemachine placement

`req:timemachine` is a reqy particle under `%examining` — an ave signal.  This is
tolerated (precedent: `%Spotlight` child + `c.w` back-ref) but unusual; a particle
that drives time-stepped playback arguably belongs on `w:Lies` directly rather than
nested inside an ave-enrolled signal particle.

## survey fictional worth

`caving()`, `assail()`, `regroup()` in Lang.svelte are vision documents for
diving into expanding code spaces (Cyto-within-Cyto), sauntering into a codebase
(lexing/stemming/threads of inquiry), and the Map (Selection.process over function
calls + io expressions).  Worth reading when scoping what comes after the current phase.

---

## Style notes (standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars; `$C` for TheC refs in sc.
- Snap notation: `:1` suffix suppressed by depeel; a bare key implies value 1.
  `What` and `Doc` now use the value directly: `What:story`, `Doc:Ghost/Foo.g`.
  Unlabelled Whats remain bare `What` (value 1).  `Point,method:foo` unchanged.
- One-Doc-per-What: section Whats are pure containers (no Doc, no Points
  directly); leaf Whats have exactly one Doc.  Cursor candidates only surface
  Whats that have direct Points (`Lies_what_has_direct_points`).
- `oai` sync, `roai` async; `moai` async in-place mutate + bump (preserves C ref — use when Svelte holds a `$state` ref to the particle); `i()` always inserts.  `moai` bumps both the particle and its parent (`this`) when changed — a `bump_version()` on the parent immediately after `moai` is redundant.
- `i_req_ttlilt` holds the snap open (defers finalize); it does not poke a think.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
- UItime reactivity: always `void C.vers` (the `$state` signal), never
  `void C.version` (the Atime counter, not tracked by Svelte).  The
  double-click glow bug was caused by this.  Watch for it elsewhere.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime.
- `watch_c` handlers are `async () =>` and the flush loop awaits them.
