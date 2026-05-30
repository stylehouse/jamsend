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
