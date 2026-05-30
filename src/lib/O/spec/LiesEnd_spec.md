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
# fab U** — fabricate-U-on-demand

## What changed (LiesEnd.svelte)

U is no longer collapsed onto the D node.

- `traced_fn` sets `n.c.D = D` — the clone learns its D node (re-set each walk).
- `U_of(C)` springs a genuine `%Understandable` node *under* C's D node
  (/%Demonstrations/%Understandable) the first time it's called, caching it on
  `C.c.U`.  A clone that never gets a meaning never grows a U.
- `LE_mean(C, sc)` writes a meaning (springs U); `LE_reads(C, sc)` reads without
  springing; `LE_topU(LE)` is `U_of(topn)` = `topD/%Understandable`.
- `U_of` is idempotent on a U node (a U's own D is itself), giving the no-seam
  stitch `D/U/U ≡ D/D/U`.

`Understandium.svelte` migrated to `H.LE_mean` / `H.LE_reads`.

## Why it holds together (the mechanism)

A U node hung under a D node survives every working re-walk: the D node object
is fresh per walk, but `resolve()`/`resume_X` carry its X across, and the U node
(mainkey `%Understandable`, not the `Seem` trace tag) is out-of-partial in the
D.replace, so it rides along as the *same object*.  `C.c.U` therefore stays
valid across pulls without re-springing.

Because U lives in the D sphere — identity-related to the clone tree C, not in it — push
(`target.i(C.sc)`) and enWaft (`Seem_toString`) of C never see
meanings.  The clone `C.sc` stays a clean pushable mirror. `U.sc` hovers above.

## Not done (still // <)

- push_dirty → reqy fault particle.
- the encode-compare steps (11–13) need enWaft (Text.svelte) to run; the U-side
  guarantee they rely on (meanings never reach the snap) is proved structurally
  in fab_U claim G without needing enWaft.

## todo or done

```
// i_Seem + two-Seem LE_pull: Seem:origin for awareness, Seem:working for the
//   editable C** and its U**.  fabricate working n (C) by cloning OC** at pull;
//   feed thereafter. make the C//U navigable via C.c.U = U.
// enWaft-of-a-Seem: encode origin slice and working state; compare for push.
//   retire resolve_strict from the diff path once this lands.
// < fab U** asap
```
