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

The `//` in `C:Point//U%unshowing` means: reach the D node for this C, then its
`/%Understandable` child, and read `%unshowing`.  Every particle the checkout walk
sees gets a D node (the D sphere), and the D node's `/%Understandable` child is
where local meanings live.  Absence is the positive case — C are showing and
accepted by default:

```
C:Point//U%unshowing   ← opt this clone out of the Lang UI display
C:Point//U%unaccepted  ← virtual deletion: omit from next push and encode

// meanings are OF the Point within this Understanding, not IN the Point.
// the durable identity rides on the Point; unshowing|unaccepted ride on U.
// the C** is clean — the entire .sc can be taken to replace the target/*.
```

---

## `%LE` — the housing

No JS classes.  Everything is methods on `this` (House mixin), operating on
`C**` particles.  `LE` is a `%LE` particle, stable for the lifetime of the
checkout — not inside a `replace()`, so `LE/*` and `LE.c.*` survive pulls.
Lives at `w/{LE}` under `w:Lies`; passed into every LE_* function.

`%What_Points` impulsing defines where we check out.  A req should check the
return-pull after we navigate or push.  After a push we should pull a no-diff.

---

## LE states

These are the states `%LE` can be in from the `Seem:working` perspective.
`%LE/%State` (replaced on each `LE_pull` / `LE_encode_compare` call) carries
the synthesised view; `%push_dirty` on `%LE` is the fault particle.

- **armed** — `LE_arm` called, `Seem:working%C` not yet fabricated.
  `LE_clones()` returns `[]`; call `LE_pull` before editing.
- **clean** — `LE_encode_compare` found equal snaps.  Working mirrors origin.
  Nothing to push.
- **changey** — working has diverged from origin (clone edits, additions, drops).
  The intended editing state; not a fault.
- **stale** — `Seem:origin` awareness pull returned non-zero goners or neus.
  The remote moved; working may be operating on an outdated picture.
  Can coexist with changey (local edits + remote drift simultaneously).
- **dirty** — fault: push happened but post-push `LE_encode_compare` is
  non-empty.  The push did not land cleanly.  Signalled by `%push_dirty` on
  `%LE` (not in `%State`).

Transitions: armed → clean (first pull), clean ↔ changey (edit / push),
clean → stale (remote moves), changey → dirty (push fault).

```
LE/%State
  sc.armed:   1 | undefined
  sc.changey: 1 | undefined   ← encode-compare found snap mismatch
  sc.stale:   1 | undefined   ← origin pull returned neus or goners
  // %push_dirty child on %LE is the fault signal — not inside %State
```

`Seem:working/%News` carries the raw structural counts (`goners`/`neus`) from
the last `o_Seem` walk.  `%State` is the synthesised view that `LE_pull` and
`LE_encode_compare` maintain together.  Liesui and Lang read `%State`.

---

## Workflows and Awarenesses — the two-Seem model

`%Seem` do the two things LE needs (read the remote, hold our
editable working set), and pull / clones / push below are a breakdown of what
it sets up.

The single-`Se` `LE_pull` we began with conflates two jobs that want separating:
reading the remote, and holding our editable working set.  The push bug that
motivated this makes it concrete — when the working clone's `.sc` carries the
D-sphere tagging (`U_clone:1`), pushing `D.sc` back leaks that tagging onto the
source.  The clone's identity sc and its D-sphere bookkeeping must not be the
same thing.

So: **two Seems**, each its own `Selection`, both hung off one `%LE`.

```
w/{LE}
  /%Seem:origin,Se:Selection(),C:$OC,topD    ← reads the remote %What
    /%Demonstrations:origin                  ← topD; awareness sphere

  /%Seem:working,Se:Selection(),C:$C,topD   ← holds the editable clone tree
    /%Demonstrations:working                 ← topD
      /%Understandable                       ← per-D U node (use_Understandable)

  /%State                                    ← synthesised: armed/changey/stale
  // %push_dirty child — fault; present only when push didn't land clean
```

`use_Understandable:1` on `i_Seem` switches on the U sphere for that Seem.
In `traced_fn`: `C.c.D` is stamped with the D node, then `D.oai({Understandable:1})`
is sprung and cached as `C.c.U`.  The U node survives re-walks because
`%Understandable` is outside the `trace_sc` partial in `D.replace` — `resolve()`/
`resume_X` carry it across as the same object.  Only `Seem:working` uses this;
`Seem:origin` does not get a U sphere.  Callers navigate `C.c.U` directly.

### How target and C arrive

`LE_arm(LE, what_C)` sets `LE.sc.target = what_C`, drops any prior Seems, then
creates both fresh.  `Seem:origin%C` is `what_C` immediately — it IS the remote
`%What`.  `Seem:working%C` is absent until the first `LE_pull`, which runs
`Seem_clone_C` to copy the source C** children directly (no strip — C.sc never
carried D-sphere tags).  Thereafter `Seem:working%C` persists across pulls as
the editable clone tree.

`LE_arm` drops both Seems on re-arm so their D/U spheres start empty — without
this, `resolve()` pairs a fresh clone against a stale D node of similar shape and
`resume_X` bleeds old meanings across to an unrelated target.

A typical session:

```
H.LE_arm(LE, target)            // aim at a %What; Seem:origin%C = target
                                // %State.armed = 1

await H.LE_pull(LE)             // walk remote → origin D sphere (awareness)
                                // first pull: Seem_clone_C → Seem:working%C
                                // walk Seem:working%C → working D/U sphere
                                // %State.armed cleared; .stale if neus/goners

H.LE_clones(LE)[0].sc.method = 'renamed'   // edit a clone → %State.changey
H.LE_clones(LE)[1].c.U.sc.unaccepted = 1   // mark for deletion

await H.LE_push(LE)             // replace-back skipping unaccepted
                                // LE_push re-pulls; %push_dirty if non-clean

const { dirty } = await H.LE_encode_compare(LE)   // snap-compare for push-state
```

### `Seem:origin` — reading OC**

`match_sc:{}` wide, `trace_sc:{ Demonstrations:'origin' }`.  Walking it mirrors
the origin tree into D, tagged `Demonstrations:'origin'`.  This is the awareness:
re-walking `Seem:origin` gives `goners`/`neus` as **clues about when to pull** —
the remote changed, time to refresh working.  It is *not* the push-state diff.

### `Seem:working` — holding the editable C**

`Seem:working%C` is **not** the remote.  It is a tree we **fabricate by cloning
the source C** children** at pull time (`Seem_clone_C`), and walk thereafter.
`Seem_clone_C` copies directly from `Seem:origin%C` — no strip needed since C.sc
never carries D-sphere tags.  With `use_Understandable:1`, each D node gets a
`/%Understandable` child where of-not-in-the-Point meanings live.

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
  working refresh and re-encode origin's slice.  Set `%State.stale`.
- `Seem:working` edit (UPoint mutated, meaning written) → schedule a working
  re-encode.  Set `%State.changey`.
- Compare the two latest encodes → that's `push would carry`.  Empty → clean.

Dump each encode on `LE/*` so a reload or "push anyway" resumes the push-state
without re-deriving it from the live ropeways (the resumability note, applied).

---

## Open / deferred

```
// < Se_o as a standing watch (fire on every source mutation) — call-driven for now.
// < push_dirty not yet wired to a req fault particle in the reqy system.
// < integration to Lang/Lies (Languinio/LE switching, wpt.sc.src = LE,
//   path-match guards) excluded — LE must be a being-for-itself first.
// < unaccepted carry-forward into a new %What (+time / ↘ / ↓)
//   reads clone.c.U?.sc.unaccepted at branch time — Chunk 4, not here.
// < vanish: when an unaccepted clone's absence lands as a goner on the post-push
//   awareness pull, push_dirty fires.  The fix: LE_push stamps bD/was_disincluded:1
//   before the replace-back; resolved_fn recognises that goner as expected and
//   suppresses push_dirty.  Needed before unaccepted is usable in production.
// < unshowing: C.c.U?.sc.unshowing opts a clone out of the Lang UI; no
//   effect on push or encode.  Lang reads it from each clone's U node when
//   building fold/decoration state.
```
