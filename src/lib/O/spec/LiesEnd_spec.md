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

The `//` in `C:Point//U/%showing` means: go through the D-sphere to the
U-sphere.  Every particle the checkout walk sees gets a D node (the D sphere),
and the D node carries `T.sc.n` = the source C and `T.sc.U` = the U clone.
Local meanings are written on the U clone, never on the source `C:Point`:

```
C:Point//U/%showing     ← orb visible in this Understanding  (on the U clone)
C:Point//U/%accepted    ← curated into this What's set        (on the U clone)

// these meanings are OF the Point within this Understanding, not IN the Point.
// they imply positivity (inclusion, showing) and are kept out of the push
// encoding.  the durable identity rides on the Point; showing|accepted ride on U.
// the C** is clean — the entire .sc can be taken to replace the target/*.
```

---

## `LE%LiesEnd` — the housing

No JS classes.  Everything is methods on `this` (House mixin), operating on
`C**` particles.  `LE` is a `%LiesEnd` particle made for us — passed in to
every function.  State lives on `LE.c.*` and `LE.sc.*` rather than on `w/`
directly, so the Understanding doesn't interfere with `replace()` operations on
`w`.  `LE` is not itself inside a `replace()` so its `C.c.*` and `C/*` are
stable across pulls.

```
// LE.sc.Se carries the Selection object — on .sc so it can be initialised
// with parameters already set (remote target, match_sc, etc).
// LE.sc.topD is the D-sphere root; replaced each pull via Se.r() to get
// a fresh .c.T binding while D/** (U clones, their meanings) persist via resume_X.

LE_arm(LE, what_C):
  LE.sc.Se     ??= new Selection()
  LE.sc.target = what_C            // the source %What being checked out
  LE.sc.topD   ??= LE.i({ topD:1 }) // D-sphere root, lives on LE/*
```

---

## Se_i — pull

There must be a Se_i layer for reading the remote (Lies).  `%What_Points`
defines where we checkout — I'd like to sanity-check each round with a req that
waits for the return-pull after we navigate or push.  After a push we should
pull a no-diff.

```
LE_pull(LE, strict=0):
  Se = LE.sc.Se
  // replace topD each pull: fresh .c.T; D/** persists via resume_X.
  // pattern: Cyto does Se.r({...}) each tick for the same reason.
  Se.sc.topD = LE.sc.topD = await Se.r({ topD:1 }, {})

  await Se.process({
    n:          LE.sc.target,
    process_D:  Se.sc.topD,
    match_sc:   {},
    trace_sc:   { U_clone:1 },           // D children are tagged U_clone:1
    resolve_strict: strict || undefined,

    each_fn: (D, n, T) =>
      // top is depth 1; past its immediate children we stop.
      // a nested %What gets a D node (and a U clone) but is never entered.
      if T.c.d > 1: T.sc.no_further = 'shallow'

    trace_fn: (uD, n_child) =>
      // uD is the parent D node.  we make a child D, tagged with trace_sc.
      // the child D carries the source C and a U clone of it.
      D = uD.i({ U_clone:1, ...n_child.sc })  // trace_sc included in the D
      D.c.T.sc.n = n_child                    // D knows its source C
      D.c.T.sc.U = D                          // D is the U clone (D/U sphere)
      return D

    resolved_fn: (T, N, goners, neus) =>
      // goners/neus = entire C coming and going, not value diffs.
      // value changes (method rename etc) read as survivors unless resolve_strict.
      // push-state diff lives in the Waft encoding, not here.
      LE.i({ goners: goners.length, neus: neus.length })  // Se_o: snapshot on LE/*
  })
```

---

## Reading the working set (Se_o)

```
// the live U clones are topD/* filtered by U_clone:1.
// to get the source C from a D node: D.c.T.sc.n
// to write a local meaning onto a clone: D.i({ showing:1 })  (D is the U clone)
// to read back for push: D.c.T.sc.n.sc — the source C's .sc is clean,
//   entire .sc can be taken as-is to replace the target/*.

LE_clones(LE)  => LE.sc.topD.o({ U_clone:1 })   // the D nodes = U clones
LE_source_C(D) => D.c.T.sc.n                     // source C for a given D

// diff (structural — whole C in/out) is a snapshot on LE/*, stamped each pull.
// push-state diff (value changes) lives in the Waft encoding — not here.
```

---

## Push — replace-back

After modifying our clones and deciding they're modified via encoding, we mutate
`%What` and replace everything within it with everything in our clone right now
— such that if there was a `%What/%What/%Point`, it would resume on our newly
replaced `%What/%What`.

```
LE_push(LE):
  target = LE.sc.target
  Ds     = LE_clones(LE)             // topD/*%U_clone — these are the D nodes

  await target.replace({}, async () =>
    for D of Ds:
      C = LE_source_C(D)             // navigate from D to its source C
      target.i(C.sc)                 // C.sc is clean — no filter needed
      // local meanings on D (showing, accepted) stay in the U sphere.
      // nested %What resumes its deep Points via resume_X.
  )

  await LE_pull(LE)                  // post-push pull must be a no-diff
  if LE.o({ neus:1 })[0]?.sc.neus > 0 || LE.o({ goners:1 })[0]?.sc.goners > 0:
    LE.i({ push_dirty:1 })          // < fault C: push didn't land clean
```

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

## Workflows and Awarenesses — the two-Seem model

The single-`Se` `LE_pull` above conflates two jobs that want separating: reading
the remote, and holding our editable working set.  The push bug that motivated
this makes it concrete — when the working clone's `.sc` carries the D-sphere
tagging (`U_clone:1`), pushing `D.sc` back leaks that tagging onto the source.
The clone's identity sc and its D-sphere bookkeeping must not be the same thing.

So: **two Seems**, each its own `Selection`, both hung off one `%LiesEnd`.

```
LE/%Seem:origin   /Se:Selection()  /topU  /topn        ← reads the remote OC**
LE/%Seem:working  /Se:Selection()  /topU  /topn        ← holds the editable U**
```

`H.i_Seem(LE, { Seem:'origin', ... })` embeds a Seem under LE:

```
i_Seem(LE, opt):
  // opt: { Seem, match_sc?, trace_sc?, topn? }
  Seem = LE.oai({ Seem: opt.Seem })
  Seem.sc.Se      ??= new Selection()
  Seem.sc.match_sc  = opt.match_sc ?? {}              // wide open by default
  Seem.sc.trace_sc  = opt.trace_sc ?? { Seem:'origin' }
  Seem.oai({ topU: 1 })            // the D-sphere root for this Seem
  if opt.topn: Seem.sc.topn = opt.topn               // the first n — the target
  return Seem
```

- **`topn`** — the first `n`, i.e. the target.  For `Seem:origin` this is the
  remote `%What` (the `OC` — origin C).  For `Seem:working` it is the fabricated
  clone we feed as the second `n**` (see below).
- **`topU`** — the D-sphere root (`process_D`).  Named `topU` not `topD` because
  the whole point is that D *is* the U sphere here (`D/U/U ≡ D/D/U`).

### `Seem:origin` — reading OC**

`match_sc:{}` wide, `trace_sc:{ Seem:'origin' }`.  Walking it mirrors the origin
tree into `topU` tagged `Seem:'origin'`.  This is the awareness: re-walking
`Seem:origin` gives `goners`/`neus` as **clues about when to pull** — the remote
changed, time to refresh working.  It is *not* the push-state diff.

### `Seem:working` — holding the editable U**

`Seem:working`'s `n**` is **not** the remote.  It is a C** we **fabricate by
cloning from OC**** at pull time, then feed as the second `n` thenceforth.  The
working Seem walks *that* clone, not the origin.  Editing happens on the working
clone; `Seem:working`'s own `topU` is where the **U** particles get fabricated,
when they happen — on demand, not eagerly at pull.

The fabricated clone is the clean identity-sc tree (`%What/%Point**`, no
`U_clone`, no `Seem` tag — those live on the D/U nodes, never in `n.sc`).  This
is what fixes the push leak: the working `n` we push back from is clean by
construction, because the D-sphere tagging is on the D nodes, and the `n` tree
is separate from them.

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

## Revised open / deferred

```
// < i_Seem + two-Seem LE_pull: origin-walk for awareness, working-walk for the
//   editable U**.  fabricate working n by cloning OC** at pull; feed thereafter.
// < enWaft-of-a-Seem: encode origin slice and working state; compare for push.
//   retire resolve_strict from the diff path once this lands.
// < fabricate-U-on-demand in Seem:working — U** made when a meaning is first
//   written or a UPoint first edited, not eagerly at pull.
// < lematch rules carried on T (n.c.T) so Waft protocol tumbles down without
//   touching origin n.sc.  needs a place to stash T.c.lematch before dive.
// < better diagnostics for the structural-vs-encode diff distinction — the
//   strict-fork confusion shows we can't currently see which diff we're reading.
```
