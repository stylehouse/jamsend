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
      Doc:Ghost/Story/Peeroleum.g
      Point,method:LakeNetherland
      Point,method:Something
    What:peer
      Doc:Ghost/Peeroleum.g
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
    /%Interest            sc.src = working clone root
    /%dock:$path           same-object hold → /docks/%dock:$path
  /req:workon
    c.src                 latest cursored TheC (stashed by e_Lang_workon_update)
    /req:settle           permanent, open-ended — Lang_settle do_fn
      /%checkout          c.armed_src, sc.what — identity-keyed re-arm gate
      /%furnish           sc.doc_path, sc.have_dock
      /%compile           sc.have_methods
      /%graft             sc.n_pmirrors
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

## Open faults

### important, check these out

```
// ── LiesCortex ──────────────────────────────────────────────────────────────

// < req:Cortex write_finished ordering — currently guaranteed by LiesStore_run
//   running before LiesCortex_run in the tick.  If that ordering shifts, have
//   Phase 1 stamp cortex.sc.write_finished directly instead.

// < push_dirty not yet wired to a req fault particle in the reqy system.

// ── Lang / compile ──────────────────────────────────────────────────────────

// < typing into the codemirror can overwhelm the backend with elvises
//    is it a reqyoncile() before the 400ms-batches-of-streams-of-typing enforcer?
//    There is also no guaranteed write every 9s when this queue of stuff is happening...

// < U%created_at session field needs wiring in LE_add_clone and the strip list.

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

// < does LiesPersist / LiesStore_read_good etc etc seem perfect? seems guts-hanging-out.
      It has to handle the above re-read shunt (might be an echo: a push then a pull)
       and how Store/Good is always there now, not just when loading...
       Actually LiesPersist looks like it was imagining the waits-for-req:Store,maz:7 we
       have now, so should we move to using that... with some kind of push-able end to it?
      and in Diffmatication / LiesStore_read_waft_good does not exist 

// < retargeting the LE away and back to mutated C** should resume as it was, not pull|reset.
     LE would need to target various perhaps unconnected bits of D** to resume, by path...
      Waft:$path (/namey-as-id)* is the whole locator of C**
       it needs the Se to decide how much is needed to be namey-as amongst its peers
        see also Stuffing
     so resuming C you tweaked while surfing around... have reset button.
      reset them if we reset all of Waft...
     having a generic read|writable with resettable client... indeed.

```

### others

```
// < survey the fictional worth of these concepts and playthings

// < req:Showing has no req particle yet — Lang_show_pmirrors is the body but
//   is called directly from the tick.  As a proper open-ended req it survives
//   cursor-absent ticks (U-edit fold toggles while settle returns early).

// < pre-pull fallback in Lang_graft_points_once (interest.c.LE absent path)
//   reads live Points off src_C directly — should be eliminated; ensure
//   interest.c.LE is always set before graft runs.

// < src_clone on Pmirrors should eventually become workingC — the whole
//   Seem:working C** — so Showing's path is unambiguous for all clone shapes.

// < e_Lang_LE_drop demote round-trip takes a full cursor-move cycle.

// < stale spinner: req:encode should also clear spinner:stale after a clean
//   encode-compare, in case stale lingers past checkout.

// < req:git do_fn — flush Waftlets to disk/remote.

// < Se_o as standing watch — call-driven for now.

// < req:wants never prunes; history grows unbounded until a sweep exists.

// < req:timemachine is a reqy particle under %examining (an ave signal);
//   tolerated — precedent: %Spotlight child + c.w back-ref.
```

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
