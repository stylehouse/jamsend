# Housing — one unfoldment, from stable to transient

This is the permanent account of why w/req** folds into beliefs(),
 why reqy() sublates,
  and where the hovering systems live.
Sections 1–9 are meant to stay here forever;
 the migration tail — summarised right below, detailed in the Handover at the very
  end — is the only part expected to age out.

> Naming note (the verb shipped differently from this doc). The merge-in-place
>  find-or-create verb this doc calls `moai` shipped as **`oai`** — the old
>   birth-only `oai` is gone and `moai` is not a live method or a grammar token
>    (`IOness2` = `oai | roai | r | rm`). So throughout: read this doc's `moai` as
>     today's `oai`, and its `oai` (the birth-only one it contrasts against `moai`)
>      as gone. The `%req` overload and `doai` are on `oai` now. See
>       `reactivity_docs.md` for the live `oai`/`roai`/`doai` semantics.

Notation is the house notation throughout:
 %req means {req:1}, Text%dige means the %dige on a %Text,
  this/written:is when structures, this|that when alone,
   and source -> e:type%x -> destination for a routed event.
Good naming earns its keep at runtime:
 the structure materialises as it runs,
  and the notation is how you climb into what is there, when it is there.


## The migration tail (transient — will age out)

reqy() is fully sublated; what is left of the migration is small and stays in this
 doc because it is Hovercraft's, not the domain's. The leftover **Agency** pieces in
 particular read like app logic but are really hovering-hook plumbing: Pirating,
 Pirate, and Agency itself still ride the older **requesty_serial** queue engine (its
 duplicate copy in Hovercraft is now dropped — lib/O and Radios are migrated — leaving
 Agency.svelte's original as the only one, serving these pilferers), and the
 Agency-migration deletes (agency_think, Aw_think, procure_ways, the setTimeout i_elvis
 routers) are a hand-rolled out-of-time re-entry layer — both superseded by %req +
 reqyoncile. Folding them in is the last of the req consolidation; details are under
 "Remaining — migrate requesty_serial, then the Agency deletes" at the end. (The one
 future direction, §7 subscriptions, sits just above in Future Directions — Hovercraft's
 own too, but ahead of the code rather than behind it.)

Two leftovers that are NOT Hovercraft's moved out, so this doc can settle to its
 permanent §1–9 plus this thinning tail: the compiler-facing data language (the
 `req:X {…}` block → doai lowering) went to **LangCompiler_TODO.md** now that doai has
 a runtime, and the Pmirror UI-non-resolution deferral lives in
 **Lang_session4_handover.md** (Open threads).


## Future Directions

One designed-but-unbuilt direction, kept up here (and kept numbered §7) because it is
 ahead of the code rather than an account of it — promoted out of the permanent §1–9.


## 7. Subscriptions — the push dual of pull

i_elvis_req is pull: a req with a reply, one shot, it finishes.
 The push dual is a standing subscription:
  register interest in a C's changes, get a wake.

Three of these already exist, differing only in target-spec and wake-shape:

 - Stuffing      — targets a %C by path, wakes a handler,
                    version-diff sampled after each cycle plus a heartbeat.
                    This is the scanner that maps the backend a few times a second;
                     it is already the subscribe half, in service of the UI.
 - watched       — targets by channel name,
                    replicates Atime -> UItime on %version bump, debounced.
 - %Good/%subscribe,Aw,wake
                 — targets by address, wakes via elvis when content lands.

They are three spellings of one primitive.
 Unify them as one %subscribe,target,on,wake:
  target is C-ref | path | address,
   on is the change predicate (version | matrix | content-landed),
    wake is handler | elvis | channel-replicate.
The settle pass (finito_fn) that already detects changed|finished nodes
 is where subscribers' wakes fire —
  a tick-bounded cascade, not a storm,
   with req/%ttlilt as the backpressure a slow consumer arms.

So pull and push are the same delivery once reqs are elvisable:
 pull is a req with a reply, push is a subscribe with a wake,
  both are e's landing at a node with a c.up chain,
   both mutate via %mix, both captured by one walk and settled by one finito_fn.


## 1. Stable and transient

Most decisions in here are a position on one axis: how transient a node is.

    stable ─────────────────────────────────── transient
    H          A           w        r           req

A slope into the minute and mundane. One big unfoldment, with some shunting when
White hole permanence to black hole vanishing mess.

It's a bit under construction, its name|key %req may become simply %raaaaaaa

The point of the axis is that it is one axis, not many.
 Knowing how transient a node is settles several of its treatments at once —
  its lifecycle (persists vs does-its-work-and-goes),
   whether the walk always descends into it or only while !finished,
    and which file it lives in (the spine, or the hovering hooks of §8).

Two things the axis does *not* decide, despite first appearances:

 - identity. A req may carry a serial, req%req_i — but only when it is marked %req,
    and we are moving to requiring that mark on the piece itself
     rather than a reqy() call, to dislodge a piece of beliefs into transience.
    The number is assigned on the Se walk (first-sight, §6a), so %reqcon can be banished;
     a req is not inherently numbered, it is numbered because it was marked and then seen.
    Separate again is the scan|snap id (§6a, watch-items),
     because thousands of transients appearing and finishing each beat would churn the diff —
      a cost decision about the snap, not a property of the node.
 - addressing. Nodes are reached by ref|query at both ends.
    The Aw string-path is only elvis-routing legibility for the named top levels (§6);
     it is not how a node is addressed, and below w there is no such string at all.


## 2. beliefs() is the walk, and req** are just more legs

beliefs() is a Selection.process() over H/A/w,
 and req** join that same walk as extra legs off the w-leg,
  self-recursive because req** nest (req/*req, by the %req key itself, no declaration).

The mechanism is already present in Travel.dive_middle:
 children are found as T.sc.more || T.sc.n.o(T.c.match_sc),
  and the walk recurses into T.sc.more after each_fn has run.
So organise's each_fn, standing at a w,
 lays that w's not-finished req** (its /* carrying %req) into T.sc.more,
  and the same process() descends into them this beat, no second pass.
"More legged" is literal —
 req** are extra legs, in T** like everything else,
  stamped by the trace_fn like everything else.

The walk has three seats and each has one job:

 - each_fn (at $n)           — descend: lay the next legs, incl req** more-legs
 - the recursion (into $n/*) — visit the legs, deeper and deeper
 - finito_fn (after $n/*)    — settle upward: unify finishedness as the walk unwinds

each_fn descends, finito_fn settles:
 work descends as legs, settledness returns as the walk unwinds,
  and the four private walkers that used to do this by hand
   (reqy_recurse, the i_Story_o_req_ttlilt visit+follow, handler_of_last_resort's inner req read)
  all collapse into "filter T** where level%ark:req".


## 3. Capture is not the same pass as work

The walk over req** is for capture, not for working.
 Capture means: maintain H%Run so H:Story can read it from outside,
  gather req/%ttlilt,
   and settle finishedness up through finito_fn.
Capture is content in lexical|tree order; it has no priority concerns.

Work is a different pass — the maz-priority pump —
 run either inline by a w that wants its work now,
  or triggered at a req-host by the descent reaching it.
The pump keeps the priority loop and the gate it enforces
 (the eternal req:Store,maz:7,ok holding req:Cortex,maz:5 until IO settles this beat).

These two never merge.
 A tree-walk visits in lexical order;
  maz is a priority order;
   dissolving the pump into the walk would pump Cortex before Store
    just because Cortex sits earlier in /*,
   and the first thing to break would be that gate, silently.
So: the walk captures in lexical order,
 the pump works in maz order,
  and the "Se walkies alternativity" is exactly these two orderings
   over the same nodes for different jobs.

The snap is outside all of this.
 H:Story looks at H%Run; the Run does not snap itself.
  Capture only means the walk keeps H%Run honest enough that Story sees the truth.


## 4. reqdo() — placement, and self-announcement

A %req minted this beat is inside the w's reach this beat,
 so it should be tugged along now, not deferred to next,
  which would push it out of reach and waste a beat.
The natural seat is: think() runs at the w,
 the walk descends into that w's req more-legs in the same beat,
  finito_fn settles as it unwinds.

Two doors reach the pump and they do not conflict:

 - inline pump — think() calls this.reqdo(w) itself
    when it wants the work done before it returns
    (the pump|work|pump shape: pump a stage, do the realised work, pump again).
 - supervisory descent — the walk pumps any !finished req under w
    that nobody pumped inline.

The supervisory door is self-announcing, not remembered:
 roai stamping a fresh|mutated req sets the descend-here gate on the w
  (the widened has_req|has_req_ttlilt bit),
   and each_fn expands req more-legs only where that bit is set,
    clearing it when the level settles.
So creating a req is scheduling its supervision.
 You never have to remember to pump;
  the walk is the supervisor and think() is merely allowed to pre-empt it.

each_fn filters req%finished (and req%ok for the pass) out of the more-legs.
 Finished reqs are captured as a leaf — req%finished shows in H%Run —
  but never expanded into their /*, which bounds the walk to live work.


## 5. The keyworkings — one verb family, on-change is a parameter

The family is i | o | oai | r | roai | moai | place,
 and the on-change action of the oai forms is the one thing that varies.
something_oai takes the on-change as a parameter,
 and the named verbs are presets of it:

 - r-on-change      — replace the particle (new ref, /* re-resolved).
                       Wanted only where ref-identity drives a keyed render
                       (the one place in the app: the change strip's three legs,
                        change roai backend|storage|compile -> new ref -> Svelte re-renders).
 - moai-on-change   — bump_version in place (same ref, /* untouched).
                       Wanted where a watcher keys on %version
                       (eg Text moai, dock/%Text gets a new dige in place).
 - mutate+stamp+run — mutate sc in place, stamp %mutated, un-finish a permanent stage,
                       bump, and (re-)arm the handler.
                       This is the req preset, and it is what reqy()'s roai was.

Realised: this preset IS moai, overloaded on the %req mainkey.
 moai(c) with 'req' in c takes the req preset (serial + c.up + %mutated/un-finish);
  moai(c) on anything else keeps its bump-version-in-place meaning.  So there is no
   separate req verb — the family stays i | o | oai | r | roai | moai | place, and
    %req is just the one mainkey moai treats specially.  doai is moai-plus-a-do_fn.
 The two-verb rule for reqs: moai when you want the ref (named req_$name handler, or
  to read|finish it), doai when the handler is an inline closure.  oai|roai are NOT
   req verbs — oai ignores a re-key (drops driver invalidation), and roai's replace
    would orphan the req.

Decision, fixed: the req side uses moai semantics — mutate-in-place + %mutated,
 merge-only, and it forgoes deletes.
A req must never be replaced, because a req carries c.up|on|do_fn|oncelers,
 and a new ref would orphan all of it;
  that is exactly why the req preset mutates rather than r()s.

These verbs + the req machinery (do | finish | all_finished | doai | maybe_mutate_sc)
 live on the StuffAware wall of Stuff.svelte.ts (StuffIO → StuffAware → … → TheC):
  the asyncs in one place, with %req the one property the Stuff layer knows.

### 5a. The change-detection, and the delete it deliberately can't see

something_oai's old comparison walked only full = {...s,...c},
 so a key on existing.sc but absent from full — a goner —
  was invisible to it.
The fix is to detect with hakd (差), which is symmetric and sees both sides,
 while never letting a function count as a difference,
  yet still copying functions through so the latest closures land:

    // hakd finds goners too; functions never count as a diff,
    //  but ex() copies them anyway so the freshest closures always win
    const diffs = hakd(existing.sc, full)
        .filter(k => typeof existing.sc[k] !== 'function'
                  && typeof full[k]        !== 'function')
    ex(existing.sc, full)
    if (diffs.length) return await q.on_change(existing, s, full)

But a true delete-detection wants something we will not build.
 To know a key was deliberately removed rather than merely not mentioned,
  you must diff against the last supplied sc, not against the rolled-in state,
   which means keeping a stored base|ancestor alongside the live sc
    and versioning it per call.
That is a two-way diff becoming a three-way merge:
 base (last-supplied) vs state-now vs incoming.
 The base is a shadow of every prior call — a complication explosion —
  so we stay two-way, last-write-wins, merge-only,
   and the transient side simply never deletes a key.
Omitted keys persist; that is correct for a stage passing only its changed sig.


## 6. elvis is targeting, and reqs are elvisable

Below w, targeting is by ref, because transient nodes get dropped|reminted
 and the ref is their real handle.
So an e carries an object target, e%target, alongside the legibility Aw prefix,
 and _e_targets_T reads the ref:

    // 2 at the node itself, 1 anywhere on its c.up chain so attend keeps descending,
    //  0 elsewhere — a finished|reminted req stops matching, which is correct
    const tgt = e.c.target
    if (tgt) {
        if (T.sc.n === tgt) return 2
        for (let h = tgt.c.up; h; h = h.c?.up) if (h === T.sc.n) return 1
        return 0
    }

The Aw string-path is the legibility|routing half for the named top levels —
 it finds the House and reads down to a w —
  but it stops at w, and the ref is the truth below.

reqyoncile collapses to a plain elvis at the req:

    // re-entry for a req — Atime or out-of-time, always this.
    //  sc splits into a state-mix (folded at delivery) and the lifecycle signals
    //   see|finished, kept apart so the settle never rides through %mutated —
    //    state and work then arrive together.
    async reqyoncile(req, sc = {}) {
        const { see, finished, ...mix_sc } = sc
        return this.i_elvisto(req, 'reqyonciliation', { see, finished, mix_sc })
    }

No %w climb in the poster, no e/%req smuggling, no special unpack at the w.
 The climb to find the w moves into targeting, where it belongs;
  the poster just names the req.

e_reqyonciliation is the delivery body — the handler the elvis lands in, at the
 targeted req (e.c.target).  It applies the e, then drives the req from its host
  (req.c.up): the state-mix folds into req.sc through the %mutated path (so a
   mutated_fn sees it), finished settles the req through the host, and otherwise
    the host re-drives it — state first, then work, in one delivery.  This is the
     push dual of i_elvis_req's pull (§7): both are e's landing at a req with a
      c.up chain, both captured by one walk and settled by one finito_fn.

e%mix is a general verb, not req machinery:
 an e carrying %mix mutates its target's sc through the %mutated path.
 It only means anything where a mutated_fn watches —
  at a %req it un-finishes a permanent stage,
   at a plain w it is merely an sc merge —
  so it is "mutate-with-detection at wherever this e lands",
   harmless and pointless where nothing is watching.

### 6a. The do_fn generalissimo

One handler ladder serves every node receiving attention,
 keyed by the node's protocol:

    // k is the protocol key — 'w' for workers, 'req' for reqs —
    //  so %req:$ta means H.req_$ta, %w:Lang means H.Lang,
    //   and any future ark rides the same ${k}_${name} convention
    do_fn_for(n, T, e) {
        const k    = T.sc.level?.ark === 'req' ? 'req' : 'w'
        const name = typeof n.sc[k] === 'string' ? n.sc[k] : undefined
        const con  = n.c.on
        return e?.sc.elvis && e.sc.elvis !== 'think' && this[`e_${e.sc.elvis}`]
            || n.sc.mutated && (n.c.mutated_fn || con?.c.mutated_fn)
            || n.c.do_fn || con?.c.do_fn
            || name && this[k === 'w' ? name : `${k}_${name}`]?.bind(this)
            || this.handler_of_last_resort?.(n)
    }

Name-convention (H.req_$name, from a string %req value) is primary.
 req.c.do_fn — set one-shot via doai — serves anonymous reqs (%req:1 with no name).
  With %reqcon banished there is no protocol-level do_fn to fall back to;
   the climb-down plus the name convention resolve nearly everything,
    and handler_of_last_resort catches the rest.

First-sight does double duty on the Se.
 The walk's first sight of a marked %req is where it earns its serial (req%req_i)
  and where it is stamped %initialdo — one neu-detection, both consequences.
 The Selection machinery already computes neu-ness
  (i_visit|refx for revisits, the snap's neu-detection for fresh structural nodes),
   so neither the serial nor %initialdo needs a %reqcon counter or a private gate;
    i_visit tracks first-sight without minting a scan-id of its own,
     so both stay independent of whether a req is ever given one.


## 8. Where code lives — the spine, the hover, the domain

There are three homes and one test that sorts every system.

 - Housing is the stable spine.
    It is the walk and the structural plumbing,
     and it calls hooks it does not define.
 - Hovercraft is the hover.
    It is the per-beat systems around think() that work the transient level —
     reqdo and the keyworkings' req preset, ttlilt, Dip_assign,
      officing, timekeeping, satisfaction, subscriptions —
     ghost-injected so the spine stays clean.
 - The app ghost is the domain.
    It is the methods the hooks dispatch into (Lang, Lies, meander, and so on).

The test, so this can be applied without re-asking:
 a system belongs in Hovercraft iff Housing would call it as this.X
  but not define it,
   it runs per-beat around the walk,
    and it works the transient level rather than the structural spine.
 If it is the walk, it is Housing.
  If it is domain, it is the app ghost.
Making "more stuff hover" is then a single repeated move:
 write it as a hook Housing calls and Hovercraft provides, on the transient level —
  which is the same act as moving a system toward the transient end of the axis.


## 9. What req is

req is beliefs() run at the transient end —
 the same walk, the same dispatch ladder, the same settle,
  at nodes that finish and go rather than persist.
The level%ark abstracts the difference to nothing the walk cares about:
 ark:H|A|w are the persistent levels, ark:req is the transient one,
  and dive_middle treats them identically.
The r in HAwr was always a placeholder for req,
 the loose fourth level under a w,
  and as the two converge the r|req distinction can vanish.
So "req" stops naming a subsystem and names the transient level of one unfoldment,
 and req being a more demanding user of beliefs is what forced the abstraction honest:
  if the transient level works through the same spine, the spine is right.


────────────────────────────────────────────────────────────────────────
The sections above are the permanent account.
Everything below is expected to age out as the work lands.
────────────────────────────────────────────────────────────────────────


## Handover — what landed, what remains

TODO 1–6 are in. TODO 7 (subscriptions) is untouched, still as §7 describes.
Where reality diverged from the plan it is noted; trust this over the old plan.

### The new req engine (self-contained on the C — no reqy(), no reqcon)

A req is just a %req child of its host C; everything is methods on the StuffAware
 wall of Stuff.svelte.ts (StuffIO → StuffAware → TimeOffice → Stuff → TheC).
 StuffAware holds the async keyworkings (roai | moai | something_oai | place) AND
 the req machinery, and %req is the ONE property Stuff.svelte.ts treats as
 meaningful — a %req child is a unit of work this wall can pump | settle | re-key.
 There are two req verbs (oai/roai add nothing safe: oai ignores a re-key, roai's
 replace would orphan c.up | do_fn | oncelers | child reqs):

 - w.moai(c, sc)           — THE req verb (overloaded: 'req' in c → the req preset).
                              Find-or-create a %req child, return the ref.  Async.
                              Fresh: serial when anonymous (%req:1 → %req:$i), c.up
                              wiring, %initialdo at birth.  Existing: moai-re-merge sc
                              (差/hakd → %mutated = {key:old}); a re-merge that drifts a
                              %permanent+%finished stage un-finishes it (+ fresh
                              initialdo) so do() re-runs it — without that a re-keyed
                              permanent stage stays finished, do() skips it, and
                              %mutated never clears (the driver freezes; bit Lang).
                              Non-req moai is unchanged (bump_version on a sc change).
                              (Was the sync req_oai; folded into moai, so callers await.)
 - w.doai(c, sc)?.(do_fn)  — the req-with-handler verb: moai plus a one-shot do_fn
                              setter; returns null once wired, so re-entry never
                              re-wires, only do() re-runs.  A do_fn only belongs on a
                              req, so doai ALWAYS makes one — an anonymous c (no %req
                              key) gets the serial preset {req:1,...}, the autofill the
                              old reqy().roai gave (PortPlanet's order reqs rely on it).
                              moai stays overloaded (req vs bump-version); doai does not.
                              Use for closure handlers; use moai when the handler is a
                              named req_$name or you just need the ref.
 - w.do(fn?)               — the maz-priority pump over w's !finished|!ok reqs.
 - w.finish(child)         — settle a child req (yoinks oncelers, drops ttlilts, bump).
 - w.all_finished()        — roll-up.
 - reqdo(w) / reqdo_sweep() — the supervisory pump.  reqdo_sweep runs post-attend on
                              think beats (organise runs before think, so the walk
                              can't pump reqs think hasn't minted — hence post-attend,
                              NOT the walk's finito_fn as §4 imagined).  reqdo gates
                              per host on antiquated: pumps only where the host has no
                              antiquated reqs.  With reqy() now deleted, the only
                              antiquated reqs left are requesty_serial's — and those
                              aren't %req children, so reqdo never sees them anyway;
                              the gate is now effectively always-open.  A targeted
                              re-entry (reqyoncile) skips the sweep.
 - reqyoncile(req, sc) → e_reqyonciliation — out-of-time re-entry.  One path now:
                              the host (req.c.up) drives the req via _req_do_one / do()
                              (the old reqcon→rq branch went with reqy()).

Resolution is one ladder, H.do_fn_for(req,{ark:'req'}): %mutated→mutated_fn, then
 req.c.do_fn, then the req_$name convention.  _req_do_one climbs c.up to reach H
 (the tree is always wired at do-time).  No reqcon fallback do_fn — name it or
 self-attach it (§6a: name-convention primary, doai for anonymous one-shots).

Diverged from the plan, deliberately:
 - serial: assigned at doai-birth off w.c.req_serial (from 2), NOT on the Se.
    Anonymous %req:1 → %req:$i; a named req keeps its name, no serial.
 - %initialdo: birth-stamped in req.c (never snaps), exposed as %req%initialdo for
    the first do() then cleared — NOT from i_visit (needs no walk).  Same shape as
    %mutated: a within-beat signal, never persistent snap state.
 - e%target (§6): delivered by direct ref-dispatch in attend (_deliver_targeted),
    NOT by descending T into req nodes.  So it needs no V.req_legs and no attend
    rework; the _e_targets_T ref-branch was removed as dead.  Gated to req targets.
 - antiquated: req.c.antiquated=1 now stamped by requesty_serial only (reqy() is
    gone); new engine reqs are never antiquated.  requesty_serial reqs aren't %req
    children, so the mark no longer gates anything — it survives only until
    requesty_serial itself migrates.
 - moai identity + maz:1: maz:1 is implied and never identifying.  moai now strips
    maz:1 from the identity match (mirroring old roai), so a later moai({…,maz:1})
    re-finds the same req instead of minting a duplicate (the created req drops maz:1,
    so an un-stripped match would miss it).  Reqs roai'd|moai'd with maz:1 (eg
    MachPeerily watch_error, binary received) depend on this.

### Verification track (still gated, not the live pump)

V.req_legs (Housing) makes organise lay req** as walk more-legs and runs
 assert_req_legs (walk's req set vs the reqy_recurse %req-children scan).  This is
 the parallel check toward the eventual reqdo-via-walk cutover; the live work does
 NOT depend on it.  reqy_recurse + i_Story_o_req_ttlilt now scan %req children
 directly (both old + new reqs), so they need no flag.

### Done migrating

 - MachReqy tests: PortPlan, PortPlanet, PortPlant — fully off reqy().  PortPlanet
    exercises the lot (serial reqs, %mutated→rogue, req_$name, named children).
 - LiesStore.svelte — the IO pump.  req:Store via w.req_oai; req_Store pumps via
    req.do(); IO reqs via host.req_oai; req_LiesStore_writeCarefully uses host.finish.
 - LiesEnd.svelte — the 5: the push cluster (req:push on workon via workon.doai;
    encode|replace|verify on push via push.doai/push.do/push.finish, unify inlined)
    and the Funkcion req (funks.req_oai/funks.do).  workon itself stays reqy-hosted
    (its understanding|ingredients|instrumentation stages are still antiquated), so
    e_Lang_LE_push keeps the workon-level reqy(workon).do() pump — only the clean,
    antiquated-free push sub-host uses push.do().  funks is a plain container, so it
    gets funks.c.up=w stamped so _req_do_one can climb to the House for do_fn_for.
    The Funkcion behaviour is wired via funks.doai (an explicit do_fn reading host|
    funk|args off req.c), NOT the req_$name convention — a Funkcion isn't req-like,
    it's behaviour hung on a req host.  (GhostList provisioning was lifted out of
    req:Store's w-agnostic Phase 2b into LiesPersist, the w:Lies-only phase, so it
    no longer spins on w:Diffmatication; the Funkcion pump there is presence-gated.)
 - Lies.svelte — desire/git/wants via w.doai, acquire via desire.doai (desire.do()
    pumps it), timemachine via examining.req_oai (examining.do() pumps it, after
    examining.c.up=w is stamped), writeCarefully create via host.req_oai, and the
    wants/Store reads via plain w.o(...).  w:Lies still hosts antiquated req:Cortex,
    so the w-level pump stays reqy(w).do() until LiesCortex migrates.
 - D/Diffmatication — the first fully antiquated-free *app* w (cf the MachReqy tests):
    Twisto/cursor via w.req_oai, demand via cursor.doai, Step via dmd.req_oai,
    showing via cursor.req_oai; nested pumps cursor.do()/dmd.do(), unify inlined,
    req_Step/req_showing finish via their host (req.c.up) not q.  No inline w.do() —
    reqdo_sweep supervises the w-level pump (w's only other req is the C-native
    req:Store from LiesStore).
 - test/Mundane — both workers off reqy.  The shared rq.con.c.do_fn protocol handler
    becomes a local closure wired per-req with w.doai (no reqcon to hang one do_fn
    on); roai→doai, rq.do()→w.do() kept inline (each worker does synchronous post-
    pump work — i_Story_o_req_ttlilt / process_export — so it can't wait for reqdo_-
    sweep; any sweep re-pump is reqonce-gated).  reqyoncile unchanged: new reqs carry
    no reqcon, so e_reqyonciliation takes its host=req.c.up branch (Mundane only
    passes finished:1).  ALL test ghosts are now off reqy (MachReqy was already done;
    the rest never used reqs).
 - Lang.svelte — req:workon + its three stages (understanding/ingredients/
    instrumentation) and the per-dock req:Languish (text_loaded/text_mutated/compile)
    plus req:furnishing.  workon via w.req_oai; stages via workon.req_oai; the driver
    req_workon re-keys stages with workon.req_oai(sig) then pumps workon.do().  Nested
    hosts: ingredients hosts furnishing (req.req_oai + req.do(), unify inlined),
    Languish hosts its phases (dock.finish on unify; text_mutated is eternal so
    Languish stays open — same as before).  All req_$name handlers dropped their q
    arg; host derives from req.c.up; q.finish→host.finish.  reqyoncile unchanged.
    Lang() w-level pump kept inline as w.do() (the same tick reads Pmirrors + the
    change strip, so it can't wait for reqdo_sweep).  w:Lang is now antiquated-free
    → e_Lang_LE_push (LiesEnd) dropped reqy(workon).do() to workon.do().  The
    e_reqyonciliation new-req mix_sc fix (Object.assign → host.maybe_mutate_sc) landed
    here, since Lang is the first to pass mix_sc through reqyoncile (req_text_mutated
    gates on %mutated).  ALSO surfaced + fixed the engine gap that froze the driver:
    TheC.maybe_mutate_sc now un-finishes a %permanent+%finished stage on a drifting
    re-merge (reqy().maybe_mutate_sc always did; the C-native one didn't, and Lang is
    the first C-native %permanent user) — see the req_oai note above.
 - LiesCortex.svelte — req:Cortex (w:Lies foreman, the HARD one), Codebit, Rundown,
    BlatDo; req:include, run_method (w:Pantheate).  handler_of_last_resort became an
    explicit do_fn: req_Cortex (resolved by the req_$name convention) pumps its
    children with req.do() then sets %ok — the eternal-foreman shape (cf req_Twisto/
    req_Store).  Gave Cortex its documented maz:5 (the old roai omitted maz → it ran
    at maz:1; §3 always specified 5).  Codebit re-arm detected by pre-checking
    existence (no meta.existed in the C-native req_oai).  All handlers dropped q;
    host = req.c.up; q.finish→host.finish (cortex/pw).  reqyoncile unchanged.  w:Lies
    + w:Pantheate are now antiquated-free → Lies.svelte's two reqy(w).do() and
    LiesCortex's Pantheate reqy(w).do() all dropped to w.do() (kept inline; the tick
    reads results).
 - MachPeerily.svelte — the LAST host on reqy(), now off it.  Every reqy(w)/reqy(De)
    host became the C itself: roai→moai, roai+do_fn||=→doai closure, rq.do()→host.do(),
    rq.finish→host.finish, rq.unify_finished()→the inlined `if (host.all_finished() &&
    !host.sc.finished) (host.c.up).finish(host)`.  The dq/drq params were dropped from
    every PL_*/De_* helper (the host is w or De, already in hand or via De.c.up).
    eternal req:emit_corruption never unifies (as before).  No req_$name handlers —
    every De_* stays an inline closure wired via doai, matching the existing shape.
    reqyoncile untouched (new reqs carry no reqcon, so the host=req.c.up path runs).
    The w-level pumps stay inline w.do() where the tick reads results (manager step
    wiring; _PeeringLive_main listen/handshake); reqdo_sweep also supervises now that
    the host is antiquated-free.  Surfaced + fixed the moai maz:1 identity gap (above).

### Remaining — migrate requesty_serial, then the Agency deletes

reqy()/reqcon/handler_of_last_resort are DELETED (the reqy_spec doc + the reqy(w,q)
 factory went; e_reqyonciliation collapsed to its single host-drives path; req_diag /
 the ttlilt-poll trace dropped their req.c.on.c.rq reads).  reqy_recurse is KEPT — it
 scans %req children directly and still serves Runstepped_reqy_pageturning +
 i_Story_o_req_ttlilt for the live (new-engine) reqs.

 - requesty_serial(w,t) — a SEPARATE, older queue engine (NOT reqy): reqs carry a
    `requesty_$t` mainkey (not %req), a `requesty_$t_serial` counter, req%req_i, and
    %aim hoisting.  The lib/O/ users are DONE — Story (wh), LangLang + Auto (rw_queue),
    and Housing's Wormhole server (fs_op + rw_queue) all moved to %req on a plain
    OFF-PUMP queue container — `w.oai({name:1})`, a non-req mainkey that keeps its %req
    items out of the worker's supervised pool so reqdo_sweep won't pump them; the owner
    drives with q.do(fn) or iterates q.o({req:1}) and retires by hand.  (An earlier
    req_host(w,name) helper also wired q.c.up=w, but that wire is consumed only by a
    fn-less q.do() handler-climb or a reqyoncile'd queue item — which no caller does —
    so it was dropped; the container alone gives the isolation.)  Mapping:
    requesty_serial(w,t) → w.oai({t:1}); .oai(c,sc) → a NAMED req moai (%req:$name) or an
    anonymous moai({req:1, …identity}) — BOTH re-find now (moai leaves the %req:1 sentinel
    a numeric wildcard rather than exactly()-pinning it to "1"); a bare moai({req:1}) with
    no other identity keys mints a fresh serial each call (fire-and-forget writes); server wrappers
    hold the elvis req + finish in .c (.c.for/.c.finish), dedup by ref, and the queue
    is swept of finished reqs after do() (do() never drops).  Client/server are
    decoupled only by the elvis req's sc (wh_op/rw_op/… + reply), so the mainkey change
    is invisible across the wire — LiesStore (already %req) and the old requesty clients
    interoperate with the same Wormhole server.  This DOES churn snaps (requesty_wh →
    wh/req in toc/NNN.snaps) — regenerate via a Story Accept, do NOT hand-edit.
    Radios also migrated to a plain off-pump queue (its two load queues never pumped via
    do() — pure iterate-and-retire, payload C moved to .c).  With lib/O + Radios done,
    the duplicate requesty_serial() copy in Hovercraft.svelte (the "shown to AI" mirror)
    is DROPPED; Agency.svelte's original remains the only definition, still serving the
    ghost/mostly pilferers.  STILL on requesty_serial (deferred — the "Agency-pilfering"
    TODO): Pirating + Pirate (this|M.requesty_serial), and Agency's own internal use.
    Independent of reqy() — the antiquated mark no longer gates (only the dropped
    Hovercraft copy stamped req.c.antiquated; Agency's never did, harmlessly, since reqdo
    only scans %req children and a requesty_$t req is not one).

 skip: shelved/LiesWorkup.svelte (inactive; still references the deleted reqy() — make
    it compile or stays shelved).
 then: the Agency-migration deletes from the old plan (agency_think, Aw_think,
  procure_ways, the setTimeout i_elvis routers) — fold in with the Agency-pilfering TODO.

### Migration recipe

 - reqy(w).roai(c,sc)  → returns ref      → await w.moai(c,sc)   (moai is async now)
 - reqy(w).roai + .c.do_fn ||= fn         → (await w.doai(c,sc))?.(fn)
 - rq.do()             → host.do() ; rq.finish(req) → host.finish(req)
 - rq.all_finished()   → host.all_finished()
 - rq.unify_finished() → if (host.all_finished() && !host.sc.finished) owner.finish(host)
 - reqy(x).o({req:…})  → x.o({req:…})
 - named handler req_$name(req, q)  → (req); derive host = req.c.up, never use q
 - mutated_fn          → fold into the do_fn checking req.sc.mutated (PortPlanet)
 - handler_of_last_resort  → an explicit do_fn that pumps its children (host.do())
 - reqonce             → unchanged (works on any req)
 - inline top-level w.do() — keep it where the same tick reads the pump's results;
    otherwise reqdo_sweep supervises.  (With reqy() gone there is no reqy(w).do()
    fallback left; every host's pump is now plain w.do().)

### Watch-items

 - per-host flip: COMPLETE.  Every reqy() host (w:Lies, w:Lang, w:Pantheate, and
    finally MachPeerily's w:PeeringLive/Bearing/Nearing/Tearing) is antiquated-free;
    every pump is plain w.do(), kept inline where the tick reads results, with
    reqdo_sweep supervising the rest.  reqy() itself is deleted.
 - %initialdo / %mutated must stay within-beat (in .c or set+cleared inside _req_do_one);
    never let them persist into a snap (that churns the diff — bitten twice already).
 - e_reqyonciliation's new-req path now does host.maybe_mutate_sc for mix_sc (was
    Object.assign) so a reqyoncile carrying state stamps %mutated → a mutated-gated
    do_fn fires.  Landed with the Lang migration (req_text_mutated needs it).
 - async req-create: folding req_oai into moai made req-create async (await host.moai).
    The microtask gap is benign under the Atime mutex (Svelte effects are macrotasks) —
    confirmed by a Story run after the Lang/LiesCortex/StuffAware work (testing OK).
    Still, when migrating MachPeerily, watch any spot that read a just-created req
    synchronously — it now needs the await before the read.
 - svelte-check's total drifts run-to-run (incremental cache re-attributing the
    ~2900 ghost-method-on-House false positives); judge by per-region diffs, not the total.
    Note Stuff.svelte.ts is checked via two import paths (data/ + O/) so its errors
    double-count in a per-file grep.
 - the maz gate (§3) — keep the pump per-host priority; lexical walk order ≠ maz.
 - snap-id churn (§1) — a transient appearing/finishing each beat churns the diff;
    decide deliberately whether one earns a scan-id or is summarised.
 - deferred (not a req-migration blocker): the Pmirror UI-non-resolution item moved to
    Lang_session4_handover.md (Open threads, "Pmirror non-resolution is silent").
