# LiesEnd — spec / doc block

## What this is

Lies commissions Lang to look at an area in the `Waft/%What**` graph, which we
have the ability to navigate around and manipulate from our grasp on it.  We
focus on a `%What/*Point` extent.

An **Understanding** (U) is a small, bounded clone of a big graph — bounded
size is the joke in the name.  For now an Understanding is deliberately tiny:
one What's worth of Points.  A checked-out Point inside an Understanding is a
**UPoint**.

The replace-back-to-Waft trick is crucial.  We only clone the `%What/*`, but
replacing it back into the Waft resumes its `%What/*/*`.  If there was a
`%What/%What/%Point`, we'd clone `%What/%What` but not descend into it.  After
modifying our clones and deciding they're modified via encoding, we mutate
`%What` and replace everything within it with everything in our clone — and the
nested `%What/%What/%Point` resumes on our newly replaced `%What/%What`.

---

## The two-sphere stitch

A `C:Point` is resolved by D and understood by U.  D is `%Demonstrations` —
mainkey|match|trace-based.  U is `%Understandable`, hanging under D:
`/%Demonstrations/%Understandable`.  The stitch identity is `D/U/U ≡ D/D/U` —
a U reached through a U is the same node as one reached directly, no seam where
Understandings nest.

The `//` in `C:Point//U%showing` means: go through the D-sphere to the
U-sphere, and %showing.  Every particle the checkout walk sees gets a D node (the D sphere),
and the D node carries `T.sc.n` = the source C and `T.sc.U` = the U clone.
Local meanings are written on the U clone, never on the source `C:Point`:

```
C:Point//U%showing     ← orb visible in this Understanding  (on the U clone)
C:Point//U%accepted    ← curated into this What's set        (on the U clone)

// these meanings are OF the Point within this Understanding, not IN the Point.
// they imply positivity (inclusion, showing) and are kept out of the push
// encoding.  the durable identity rides on the Point; showing|accepted ride on U.
// the C** is clean — the entire .sc can be taken to replace the target/*.
```

---

## `LE%LiesEnd` — the housing

No JS classes.  Everything is methods on `this` (House mixin), operating on
`C**` particles.  `LE` is a `%LiesEnd` particle made for us — passed in to
every function.  LE` is not itself inside a `replace()` so its `C.c.*` and `C/*` are
stable across pulls. Tend not to use C.c.* though?


## ignore the context, but...

`%What_Points` impulsing defines where we checkout. A req should check the
return-pull after we navigate or push.  After a push we should pull a no-diff.

---

## Workflows and Awarenesses — the two-Seem model

`i_Seem` central — it does the two things LE needs (read the remote,
hold our editable working set), and pull / clones / push below are a breakdown of
what it sets up.

The single-`Se` `LE_pull` we began with conflates two jobs that want separating:
reading the remote, and holding our editable working set.  The push bug that
motivated this makes it concrete — when the working clone's `.sc` carries the
D-sphere tagging (`U_clone:1`), pushing `D.sc` back leaks that tagging onto the
source.  The clone's identity sc and its D-sphere bookkeeping must not be the
same thing.

So: **two Seems**, each its own `Selection`, both hung off one `%LiesEnd`.

```
LE/%Seem:origin,Se:Selection(),topn:$OC,topD        ← reads the remote OC**
  /D%Demonstrations        ← is topD
  
LE/%Seem:working,Se:Selection(),topn:$C,topD,topU   ← holds the editable C**
  /D%Demonstrations        ← is topD
  /U%Understandable        ← is topU
```

Both given `%Seem,(topn)` to hold (how?) but hosting their own `%Seem,(topD)` at `%Seem/D`, and maybe `%Seem/U`! That's a parameter on i_Seem, somehow.

`H.i_Seem(LE, { Seem:'origin', ... })` embeds a Seem under LE:

```
i_Seem(LE, opt):
  // opt: { Seem, match_sc?, trace_sc?, topn? }
  Seem = LE.oai({ Seem: opt.Seem })
  Seem.sc.Se      ??= new Selection()
  // < this needs to go in a Seem.sc.opt.*, to be mixed into Se.process({...})
  Seem.sc.match_sc  = opt.match_sc ?? {}              // wide open by default
  Seem.sc.trace_sc  = opt.trace_sc ?? { Demonstrations:Seem.sc.Seem }
  Seem.oai(Seem.sc.trace_sc)            // the D-sphere root for this Seem
  if opt.topn: Seem.sc.topn = opt.topn               // the first n — the target
  // < wanting to Seem%opt.each|trace|etc_fn here
  //    adding a bunch of Seem%opt.*_fn of our own?
  return Seem
```

- **`topn`** — the first `n`, i.e. the target.  For `Seem:origin` this is the
  remote `%What` (the `OC` — origin C).  For `Seem:working` it is the fabricated
  clone we feed as the second `n**` (see below).
- **`topD`** — the D-sphere root (`process_D`).  

### `Seem:origin` — reading OC**

`match_sc:{}` wide, `trace_sc:{ Seem:'origin' }`.  Walking it mirrors the origin
tree into `topU` tagged `Seem:'origin'`.  This is the awareness: re-walking
`Seem:origin` gives `goners`/`neus` as **clues about when to pull** — the remote
changed, time to refresh working.  It is *not* the push-state diff.

### `Seem:working` — holding the editable C**

`Seem:working`'s `n**` is **not** the remote.  It is a C** we **fabricate by
cloning from OC**** at pull time, and monitor for our own changes thenceforth.  The
working Seem walks *that* clone, not the origin.  Editing happens on C, the working
clone; `Seem:working`'s **U\*\***  is where some of-not-in-the-Point properties live,
and springs up where-ever **C\*\*** leads, as **D\*\*** does.

The C fabricated clone is nice and tidy, identical to the eg `%What/%Point**` it
pulled, `%Demonstrations` or `%Understandable` mainkey tag that the `Seem` spheres
have because they join one another D/U

### The diff that matters — Waft-encode compare

The structural `goners`/`neus` of either Seem is *not* the push-state.  The
push-state is:

```
enWaft( relevant slice of Seem:origin )   vs   enWaft( Seem:working state )
```

Both occasionally, on a watch.  `enWaft()` already returns `{ snap, errors }`;
two snaps compared string-wise (or particle-wise via a third resolve) tell us
exactly what a push would change.  This is why `resolve_strict` was a crutch in
the test suite — we were trying to read value-edits out of the *structural*
diff, which by design only carries whole-C in/out.  Value edits belong to the
Waft-encode compare, not to `resolved_fn`.  (The strict-fork test should become
an encode-compare test once `enWaft`-of-a-Seem exists.  Until then it stands as
a characterisation of the resolve primitive, not of LE's intended diff path.)

### When to encode

- `Seem:origin` re-walk fires `neus`/`goners` → remote moved → schedule a
  working refresh and re-encode origin's slice.
- `Seem:working` edit (UPoint mutated, meaning written) → schedule a working
  re-encode.
- Compare the two latest encodes → that's `push would carry`.  Empty → clean.

Dump each encode on `LE/*` so a reload or "push anyway" resumes the push-state
without re-deriving it from the live ropeways (the resumability note, applied).

---

## then: pull · clones · push

`i_Seem` sublates `LE_pull`.  We can still call `LE_pull()`, but it is now thin —
per Seem it is just `Se.process({ ...Seem.sc.opt, n: Seem.sc.topn, process_D:
Seem.sc.topD })`.  `Seem:origin` pulls for awareness; `Seem:working` walks the
fabricated clone.  Clones are read off `Seem:working`'s `topn` tree; push replaces
the target's children with them.

## Push — replace-back

After modifying our clones and deciding they're modified via encoding, we mutate
`%What` and replace everything within it with everything in our clone right now
— such that if there was a `%What/%What/%Point`, it would resume on our newly
replaced `%What/%What`.

```
LE_push(LE):
  working = LE.oai({ Seem:'working' })   // the editable Seem
  target  = LE.sc.target

  // Seem:working.topn is the fabricated clean C** — no D-sphere tags in n.sc —
  // so push is a straight copy and the U_clone strip is retired.
  await target.replace({}, async () =>
    for n of working.sc.topn.o({}):    // the working clones
      target.i(n.sc)                   // n.sc is clean — no filter, no strip
      // local meanings on U** (showing, accepted) stay in the U sphere.
      // nested %What resumes its deep Points via resume_X.
  )

  await LE_pull(LE)                  // post-push pull must be a no-diff
  if LE.o({ neus:1 })[0]?.sc.neus > 0 || LE.o({ goners:1 })[0]?.sc.goners > 0:
    LE.i({ push_dirty:1 })          // < fault C: push didn't land clean
```

you can't modify target.sc with this, you'd have to seek to the What above it
so it's a C we can replace.

---

## Open / deferred

```
// < Se_o as a standing watch (fire on every source mutation) — call-driven for now.
// < push_dirty not yet wired to a req fault particle in the reqy system.
// < integration to Lang/Lies (Languinio/LE switching, wpt.sc.src = LE,
//   path-match guards) excluded — LE must be a being-for-itself first.
// < accepted|showing carry-forward into a new %What (+time / ↘ / ↓)
//   reads clone.oa({ accepted:1 }) at branch time — Chunk 4, not here.
// < e_Lies_export_point still writes deprecated /%Doc/%Points,1/%Point,N.
```

---

## Lematch state that tumbles from above

Waft particles can be relied upon to carry `n.c.T` — the Travel ropeway node —
for the duration of a walk.  That gives a place to share **lematch state** that
descends from above: the Lies Waft protocol/advice (the matching rules that say
what a `%What`'s children mean, how Points resolve) is imposed on `Seem:origin`
by hanging it off the walk's `T`, where every visited node can read it via
`n.c.T` without it being baked into each `n.sc`.

```
// Waft protocol/advice = lematch rules, imposed on Seem:origin from above.
// they ride T (n.c.T), not n.sc — so the origin C** stays clean for push,
// and the rules don't have to be re-stated per particle.
// each_fn can read T.c.lematch (set on the top T before dive) and apply
// n.lematch(rules) to decide skip / munging / thence — privately encoding
// bits of the match-state as we go, without polluting n.sc.
```

This is the mechanism by which "private encoding of bits" works: the lematch
result (`skip`, `munging`, `thence`) is computed against rules carried on `T`,
and any derived tags we want are written on the **D/U** node (or on `T.sc`),
never on the origin `n`.  The origin stays a faithful, pushable mirror; the
understanding of it accumulates in the U sphere and on the ropeway.

---

## beware

What seemed jarring to you:
Seem.oai(Seem.sc.trace_sc) — that would create e.g. LE/%Seem:origin/%Demonstrations:origin as topD.
Seem%opt.*_fn — the spec notes // < wanting to Seem%opt.each|trace|etc_fn here. The cleanest approach is probably Seem.sc.opt = { trace_fn, each_fn, ... } so LE_pull does Se.process({ ...Seem.sc.opt, n: Seem.sc.topn, process_D: topD }). No need to particle-ify the functions — they're already on .sc.
The U_clone strip in LE_push — this is what the two-Seem model retires. In the two-Seem world Seem:working fabricates a clean C** with no D-sphere tags in n.sc, so push just does target.i(n.sc) directly off the working clone tree. The strip is an honest interim hack and the comment says so clearly.
One thing the spec doesn't yet say: how does Seem:working actually get its fabricated n tree populated on the first arm? It says "fabricate by cloning from OC** at pull time" but doesn't pin down the mechanics. I'd expect LE_pull to: walk Seem:origin first, then if Seem:working has no topn yet, walk the origin's D nodes and i clean copies into a fresh C** which becomes Seem:working's topn. That "clone from D nodes, strip D-sphere tags" is the same strip we're currently doing at push time — just moved earlier and made durable.

## todo

```
// < i_Seem + two-Seem LE_pull: Seem:origin for awareness, Seem:working for the
//   editable C** and its U**.  fabricate working n (C) by cloning OC** at pull;
//   feed thereafter. make the C//U navigable via C.c.U = U.
// < enWaft-of-a-Seem: encode origin slice and working state; compare for push.
//   retire resolve_strict from the diff path once this lands.
// < fabricate-U-on-demand in Seem:working — U** made when a meaning is first
//   written or a UPoint first edited, not eagerly at pull.
// < lematch rules carried on T (n.c.T) so Waft protocol tumbles down without
//   touching origin n.sc.  needs a place to stash T.c.lematch before dive.
// < better diagnostics for the structural-vs-encode diff distinction — the
//   strict-fork confusion shows we can't currently see which diff we're reading.
```
