# Housing — one unfoldment, from stable to transient

This is the permanent account of why w/req** folds into beliefs(),
 why reqy() sublates,
  and where the hovering systems live.
Sections 1–9 are meant to stay here forever;
 the TODO and the how-from-now migration are at the very end,
  and those are the only parts expected to age out.

Notation is the house notation throughout:
 %req means {req:1}, Text%dige means the %dige on a %Text,
  this/written:is when structures, this|that when alone,
   and source -> e:type%x -> destination for a routed event.
Good naming earns its keep at runtime:
 the structure materialises as it runs,
  and the notation is how you climb into what is there, when it is there.


## 1. Stable and transient

Most decisions in here are a position on one axis: how transient a node is.

    stable ─────────────────────────────────── transient
    H          A           w        r|req

A slope into the minute and mundane. One big unfoldment, with some shunting when
White hole permanence to black hole vanishing mess.

It's a bit under construction, its name|key %req may become simply %r

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
                       bump, and schedule the handler.
                       This is the req preset, and it is what reqy()'s roai was.

reqy()'s roai sublates into this preset.
 There is nothing special left in reqy once on-change is a parameter:
  a req is roai with the mutate+stamp+run preset,
   which is the whole reason for folding reqy into the keyworkings.

Decision, fixed: the req side uses moai semantics — mutate-in-place + %mutated,
 merge-only, and it forgoes deletes.
A req must never be replaced, because a req carries c.up|on|do_fn|oncelers,
 and a new ref would orphan all of it;
  that is exactly why the req preset mutates rather than r()s.

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
    //  the mix rides the e and is applied at delivery, so state and work arrive together.
    async reqyoncile(req, mix = {}) {
        return this.i_elvisto(req, 'reqyonciliation', { mix })
    }

No %w climb in the poster, no e/%req smuggling, no special unpack at the w.
 The climb to find the w moves into targeting, where it belongs;
  the poster just names the req.

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


## TODO

Ordered so every beat stays green; each step is independently shippable.

1. do_fn_for extraction (§6a).
    Pure refactor of the two existing ladders (_Aw_think, do_one) into one.
    Lowest risk, no behaviour change, do it first to fix the shape.

2. something_oai change-detection (§5a).
    Swap the one-directional comparison for the hakd-with-functions-excluded form.
    Lock the req preset to moai + %mutated, merge-only, no deletes.
    Add the on-change parameter and name r | moai | mutate+stamp+run as presets.

3. req** as more-legs in get_next_levels|each_fn (§2, §4), behind a gate.
    Lay !finished req** into T.sc.more where the descend-here bit is set.
    Assert the T** req-filter gathers the identical %ttlilt set
     that i_Story_o_req_ttlilt does, for a few days of runs,
      then delete the visit+follow+has_req_ttlilt climb.
    Delete reqy_recurse once Runstepped_reqy_pageturning filters T** instead.

4. e%target in _e_targets_T, attend climb-down, %mix delivery (§6).
    Keep e_reqyonciliation as the at-node delivery body.
    Rewrite reqyoncile to the plain i_elvisto form.
    Delete the %w-climb poster path once Lies|Lang traces look the same.
    Keep an audible "targeted e landed nowhere" warn in attend,
     so a ref-targeted e to a since-reminted req does not fail in silence.

5. %initialdo from first walk-sight (§6a).
    Move it off req.c._had_initialdo onto i_visit first-sight.

6. reqdo wiring (§4).
    Phase the pump: reqdo first only walks|captures|settles,
     leaving do_one to the old reqy().do() while antiquated counts are nonzero;
      reqdo takes over do_one last, per host, once that host's antiquated hits zero.

7. Subscriptions unification (§7).
    Land %subscribe,target,on,wake; express Stuffing | watched | %Good as presets.
    Fire wakes from finito_fn. This can trail the rest.


## How, from now

Antiquated tagging is the migration's seam.
 The current reqy()'s roai marks what it returns req.c.antiquated=1.
 Old reqy() numbers from its %reqcon counter; new roai numbers on the Se first-sight (§6a).
  To keep them from colliding while both live, the Se reads an existing req%req_i if one is set
   and only assigns when it is absent — so an antiquated req keeps its old number,
    a new one gets a Se number, and neither double-counts.
 The fence: never let both pump the same req —
  that is why TODO 6 phases the pump rather than swapping it.
 A host is done migrating when its antiquated count hits zero;
  reqdo takes over its do_one then, and not before.

reqy() the closure sublates, and %reqcon goes with it.
 The serial moves to the Se (assigned at first-sight when %req is marked).
 The on-change behaviour becomes the moai preset (§5).
 The do_fn resolves by name (H.req_$name) or req.c.do_fn (§6a) — no protocol container left.
 reqcon.c.rq goes too; everyone who climbed req.c.on.c.rq.k
  now reads the %req value off the node directly — the key was always there.

The Agency migration:

 - obsoleted by Housing, delete —
    agency_think, Aw_think, procure_ways,
     the old setTimeout string-router i_elvis and Modus_i_elvis,
      o_elvis|elvised_completely|elvised_A_w|Aw_route|handle_elvising_to_Modus,
       requesty_serial.
 - hovers into Hovercraft (Housing calls these as this.X but must not define them) —
    self_timekeeping, reset_interval, w_forgets_problems,
     agency_officing and its parts (i_journeys_o_aims, i_unemits_o_Aw, Aw_satisfied,
      the KEEP_WHOLE_w replace), w_ambiently_sleeping, the needs_your_attention pre-main queue.
 - app domain, into the app ghost —
    rest, unrest, Areset, meander, is_meander_satisfied,
     ragate, raglance, out_of_instructions, the radiostock specifics.

The data language waits on a stable basis, so do not compile doai yet.
 The basis is TODO 1–2 landed: the keyworking verbs and their on-change presets fixed,
  plus reqs-as-nodes.
 Only then does w roai req:X {...body...}
  have a fixed thing to emit
   ((await w.roai({req:'X'})) with the body becoming req_X | req.c.do_fn),
    rather than chasing semantics still in flux.

Watch-items that will bite if forgotten:

 - the maz gate (§3) — keep the pump a per-host priority loop;
    never let lexical walk order stand in for maz priority.
 - the descend gate (§4) — gate req** descent on !finished && has_req,
    or every beat re-legs a thousand finished reqs.
 - snap-id churn (§1, §6a) — a req's serial req_i is conditional (only when %req is marked,
    assigned on the Se), so do not lean on it as an always-present id.
    The separate open question is the scan|Cyto id used for the snap diff,
     because things appearing and finishing each beat churn it.
    Decide deliberately whether a transient earns a scan-id or is summarised,
     rather than letting drop_finished froth the neus|goners counts by default.
