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
mainkey|match|trace-based.  U is `%Understandable`, hanging under one D node:
`/%Demonstrations/%Understandable`.

The `//` in `C:Point//U%showing` means: reach the D node for this C, then its
`/%Understandable` child, and read `%showing`.  Every particle the checkout walk
sees gets a D node (the D sphere), and the D node's `%Understandable` child is
where the local meanings live:

```
C:Point//U%showing     ← orb visible in this Understanding  (on the U node)
C:Point//U%accepted    ← curated into this What's set        (on the U node)

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
LE/%Seem:origin,Se:Selection(),C:$OC,topD         ← reads the remote OC**
  /D%Demonstrations:origin    ← is topD
  
LE/%Seem:working,Se:Selection(),C:$C,topD         ← holds the editable C**
  /D%Demonstrations:working   ← is topD
    /%Understandable           ← per-D U node, only when use_Understandable:1
```

`use_Understandable:1` on `i_Seem` switches on the U sphere for that Seem:
`traced_fn` stamps `C.c.D = D` and springs `D.oai({ Understandable:1 })`,
caching it as `C.c.U`.  Only `Seem:working` uses this; `Seem:origin` does not.
Callers navigate `C.c.U` directly to read or write meanings.

`H.i_Seem(LE, { Seem:'origin', ... })` embeds a Seem under LE.
```

- **`C`** — the tree root this Seem walks.  For `Seem:origin` this is the remote
  `%What` (the OC).  For `Seem:working` it is the fabricated clone (`Seem_clone_C`).
- **`topD`** — the D-sphere root (`process_D`), r()'d fresh each pull.

### `Seem:origin` — reading OC**

`match_sc:{}` wide, `trace_sc:{ Demonstrations:'origin' }`.  Walking it mirrors
the origin tree into D, tagged `Demonstrations:'origin'`.  This is the awareness:
re-walking `Seem:origin` gives `goners`/`neus` as **clues about when to pull** —
the remote changed, time to refresh working.  It is *not* the push-state diff.

### `Seem:working` — holding the editable C**

`Seem:working`'s `C` is **not** the remote.  It is a tree we **fabricate by
cloning from OC** at pull time (`Seem_clone_C`), and walk thereafter.  Editing
happens on C, the working clone; with `use_Understandable:1`, each D node gets a
`/%Understandable` child where the of-not-in-the-Point meanings live.

The fabricated clone is clean: strip the `Demonstrations:` trace tag from each D
node's sc and you have a faithful `%What/%Point**` tree ready to push back.

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

`Seem:origin` pulls for awareness; `Seem:working` walks the
fabricated clone.  Clones are read off `Seem:working`'s `C` tree; push replaces
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

  // working.sc.C is the fabricated clean C** — no D-sphere tags in C.sc —
  // so push is a straight copy.
  await target.replace({}, async () =>
    for C of working.sc.C.o({}):    // the working clones
      target.i(C.sc)                // C.sc is clean — no filter, no strip
      // local meanings on U (C.c.U) stay in the D sphere, invisible to push.
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
# U sphere — `use_Understandable` on `i_Seem`

## What it does

`use_Understandable:1` is an option to `i_Seem`.  When set, the Seem's
`traced_fn` does two things after the D node is established for each clone:

- stamps `C.c.D = D` — the clone knows its D node, re-set each walk.
- springs `D.oai({ Understandable:1 })` and caches it as `C.c.U` — the
  companion U node, ready for meanings.

Only `Seem:working` uses this.  `Seem:origin` does not get a U sphere.

Callers write and read meanings directly via `C.c.U`:

```
C.c.U.i({ showing: 1 })           // write
C.c.U.o({ showing: 1 })           // read
```

## Why U survives re-walks

A U node under D is out-of-partial in `D.replace` — `trace_sc` only covers the
`Demonstrations:` tag, not `Understandable:`.  So `resolve()`/`resume_X` carry
the U node across as the *same object* every time the working Seem re-walks.
`C.c.U` stays valid without re-springing.

Because U lives in the D sphere — hanging off D, not in the clone tree C — push
(`target.i(C.sc)`) and `enWaft` (`Seem_toString`) never see meanings.
The clone `C.sc` stays a clean pushable mirror.
