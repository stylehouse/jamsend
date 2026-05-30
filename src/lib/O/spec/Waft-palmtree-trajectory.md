# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design* of the What
tree and its transport semantics; this doc owns the *implementation slice*.



## Chunk U — the Understanding (precursor to Chunk 4)

*New prerequisite.  Chunk 4's navigation gestures all manipulate a checked-out
extent of the Waft; this chunk is that checkout.  Design here; build in an
isolated harness (see Sequencing) — it does **not** graft onto the live
Lies+Lang cluster yet.*

### The reframing

Lies owns the `/%Waft/%What**` graph.  It commissions Lang to **look at an
area** of that graph — Lang gets a grasp on it, navigates around inside it, and
manipulates it from that grasp.  The area we focus on is a `%What`'s immediate
`/%What/%Point` extent.

The checked-out area is an **Understanding** (`U`): a small, bounded clone of a
big graph.  Bounded size is the joke in the name — for now an Understanding is
deliberately tiny, one What's worth of Points.  A checked-out Point inside an
Understanding is a **UPoint**.  (This retires `%Pointo` — the wrapper-capsule
idea collapses into the U-sphere clone, below.)

### The two-sphere stitch

A `%Point` is resolved by the **D sphere** and understood by the **U sphere**.

- **D — `/%Demonstrations`** — mainkey|match|trace-based, like the rest of the
  reqy/Travel machinery.  Resolving a `C:Point` means tracing it into D.
- **U — `/%Understandable`** — hangs *under* D: `/%Demonstrations/%Understandable`
  is how a U lives in the graph.  The stitch identity is `D/U/U` ≡ `D/D/U` — a
  U reached through a U is the same node as a U reached directly through D, so
  the sphere has no seam where Understandings nest.

Every particle the checkout walk sees gets a treeing clone whose provenance is
stamped `n.c.U` ($C, an `%Understandable`).  The clone is where we hang our
**messy, local meanings** — written on the clone, never on the source Point:

```
C:Point//U/%showing      ← orb visible in this Understanding
C:Point//U/%accepted     ← curated into this What's set
```

These meanings imply *positivity* — inclusion, showing — and are kept **out of
the push encoding**.  The encoding we posit as "what to push back to the Waft"
is the pure `/%Point**` cluster: `$method`/`$label`/`$class` and structure.
So the durable identity rides on the Point; `accepted`/`showing` ride on the U
clone.  This is the answer to "is `%accepted` ok inside the stored Point" — no.
Storing the Point at all already models its existence; whether it's *accepted*
is a fact about an Understanding of it, and lives in U.

### Se_i / Se_o — pull and push

`Se/*` already exists as the local Selection's configuration and state.  Two
named faces of it carry the transport:

- **`Se_i`** — read the remote (Lies).  The checkout walk itself: pull the
  `%What/*Point` extent into an Understanding.
- **`Se_o`** — read our changes, continuously.  Diff the Understanding against
  what it was pulled from, so we always know what a push would carry.

Both are one `Se.process()` walk.  The walk builds a transient `Travel` ropeway
(`T**`) that Lang holds out-of-band — that ropeway *is* the grasp.  Its
`trace_fn` mirrors each `n.sc` into D; because D nodes `replace()` rather than
recreate, the `D/U` we build **persists across walks** (unlike a `match_sc:{}`
all-inclusive walk, which keeps nothing).  The walk's `resolved_fn` hands back
`(T, N, goners, neus)` — survivors, dropped-Ds, new-Ds — and that triple **is**
the diff.  Se_o is just reading `goners`/`neus` each walk; no diff-match-patch
needed, the resolve step already computed it.

`match_sc` bounds the walk to the `%What/*Point` layer so we don't trickle into
a nested What's contents — which is exactly the shallow-clone rule below.

### `%What_Points` — the checkout cursor

`%What_Points` stays.  Its job is sharpened: it names **where we check out** —
`{ src $C, src_Waft }`, the one `%What` whose `/%Point` extent the Understanding
mirrors.  It may be what Lang *just asked* to check out; we sanity-check that
each round with a req that **waits for the return-pull** after we navigate or
push, and after a push we expect to pull a **no-diff** (`goners`/`neus` empty).
A non-empty diff right after a push means the push didn't land cleanly — a real,
catchable fault, not a silent drift.

### The checkout / replace-back mechanism *(crucial)*

The checkout always looks at a `%What/*Point`.

- **Clone `What/*` only** — the immediate child layer.  If a child is itself a
  `%What` (`/%What/%What`), we clone that What *node* but do **not** descend into
  or touch its contents.  Shallow, by `match_sc`.
- Modify the clones; decide they're modified via the Se_o encoding.
- **Push** = mutate the source `%What`, replacing everything within it with
  everything in our clone, right now.

The crucial trick: because we cloned `What/*` shallowly, replacing it back into
the Waft **resumes** `What/*/*`.  A nested `/%What/%What/%Point` we never cloned
was never detached; when the replaced `/%What/%What` node goes back, its old
contents resume under it.  We only ever owned the top layer; the deep layers
ride along untouched.

```
checkout:   What → [ Pa, Pb, What2 ]          clone the 3 children, shallow
            What2 → [ Pc ]                     ← NOT cloned, left in place

push-back:  replace What's children with our (possibly-edited) clones
            What2 resumes → [ Pc ]             ← deep layer never moved
```

`C.i(C)` is the same-object insert (not a copy): used where the *same* particle
should appear in two places — e.g. `/%Languinio` holding the active
Understanding is `C.i(C)` of the live U, not a snapshot of it.  Switching docs
or `%What_Points` re-points that same-object hold.

### Encoding / resumability

Dump the Se_o encoding regularly, and on any change.  Each dump is a resumable
description of the Understanding's push-state — so a reload, or a later "push
anyway", can pick the working set back up without re-deriving it from the live
ropeway.

### Open faults to chase *(not blocking the spec)*

- `e_Lies_export_point` (the `↑` button) still writes the **deprecated**
  `/%Doc/%Points,1/%Point,N` container via plain `.i()`.  The Point it makes has
  no `.c.up` (plain `.i()`/`oai()` don't set it — only `reqy.roai()` does, at
  Hovercraft `req.c.up = w`).  First concrete cleanup: write Points into the
  flat `/%What/%Point` shape, and decide whether Waft-tree particles need a
  `.c.up` pass or whether the D/U walk supplies the parentage instead.
- `// <` the no-diff-after-push check needs a home: probably a `reqonce` on the
  push req that arms a return-pull and raises a fault C if the diff is non-empty.

---

## Chunk 4 — What-level transport and navigation

*Depends on Chunk 3 **and Chunk U** — every gesture below manipulates an
Understanding and pushes it back.  Multi-reset sub-project; design here.*

### The overall desire

The system carries an intention that it pursues toward showing the audience
something.  Right now it goes dormant once the Waft is open.  It should want:

```
w:Lies
  req:desire,Waft:Ghost/Tour
    req_sent
    started:1
    req:open_What           ← reqonce: opened first What, cursor set
      ttlilt:1,until_ts:T,playing:1   ← armed only in auto-advance mode
    req:next_What           ← when advancing: step sibling, or exhausted
```

`reqonce(desire_req, 'open_What')` fires once: opens the first `%What` in the
Waft, sets the cursor to it, arms a ttlilt if playing.  When the ttlilt expires
Story wakes, `do_fn` mints `req:next_What` and steps.  In pause mode the ttlilt
is never armed — `→` advances manually.

End-of-Waft: when no further `%What` exists, `req:next_What` transitions to
`req:waft_exhausted` and fires an `o_elvis` for the UI (loop, stop, prompt
for `+time`).

### Navigation gestures

```
→   continue          step to next sibling %What at the same depth.
                      "keep going the way we were going."

↘   sibling +time     create a new %What sibling beside the current one
                      and step into it.  Branch-point is the current accepted/
                      showing set; both threads remain live.
                      "let's explore a parallel line from here."

↓   child +time       dive: create a new %What *inside* the current one,
                      positioned between two chosen Points.
                      "let's go deeper into this pocket."
```

`e_Lies_cursor_next` currently steps `%Doc` within a Waft.  Promoting it to
step sibling `%What` particles is the first gesture (4a).  `↘` and `↓` need
new `e_Lies_branch_What` and `e_Lies_dive_What` events.

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.  `→` walks the main
passage.  `↘` carves a side-tunnel from the current chamber.  `↓` drops into
a pit discovered between two Points in the floor.

The audience follows the spelunker.  The frame of reference is the chamber
they're in — its Points are the walls.  `→` is legible because the audience
knows where they came from.  `↘` is "we'll return to this junction."  `↓` is
"look what's down here" — a sub-thread that resurfaces to the parent when done.

`accepted:1` Points carry forward (Chunk 3) because the spelunker marks the
wall and that mark survives the return trip.

### `+time` carry-over heuristic

When a new `%What` is created (→ or ↘ or ↓), the heuristic seeds its in-group:

- Points with `accepted:1` AND `showing` → copied forward.
- Points created `< 30s` ago → moved forward (part of this thought).
- Everything else → ghost at 18% opacity, 10s rescue window, then fade.

`showing` is the DocMinimap capsule visibility (orb toggle).  Dormant Points
stay in the old chamber.  The rescue window: `reqonce(what_req, 'rescue_window')`
arms a ttlilt for 10s; after expiry, unrescued ghosts are dropped.

### `◀◀ rwnd`

Steps back through `%What` siblings in reverse, re-loading their showing set
into `%What_Points,1`.  Read-only — no mutations to accepted state.
The "you were here" marker.

### Sub-slices

- **4a** — `e_Lies_cursor_next` steps sibling `%What` (not just `%Doc`)
- **4b** — `req:desire` + playing/pause loop
- **4c** — `↘` / `↓` branch and dive gestures
- **4d** — ghost + rescue window + `◀◀ rwnd`

---

## Sequencing

- **1** first — graft ttlilt, ~ten lines, immediately visible.
  Needs `scheme:req` on `w:Lang` as a prerequisite (see `scheme-req-spec.md`).
- **2** — internal tidiness, one PR after 1.
- **3** — small, prerequisite for 4.
- **U** — the Understanding.  **Test-first, in an isolated harness** — do *not*
  graft it onto the live Lies+Lang cluster, that's too much too soon.  Stand up
  a `Se.process()` checkout over a fixture `%What/*Point` extent, assert the
  `resolved_fn` diff (`goners`/`neus`), assert the shallow-clone + replace-back
  resumes a nested `What/*/*`, and assert post-push pull is a no-diff.  Only once
  that harness is green does any of it touch Lang's real cursor.
- **4** — multi-reset, design sub-slices before each.  Now sits **on top of U**:
  each gesture is "re-aim `%What_Points`, re-pull, push".

Single-convo highest value: **1 + 3** — "Points resolve on open" and
"accepted set survives reload".  **U** is the next standalone piece of value
and the gate to 4; build and prove it in isolation before wiring.

---

## Style notes

- Keep comments that stay true on rewrite; drop dev-mumbling.
- `// < …` marks a *lack* of development.
- `%like,this` naming a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` sync, `roai` async.  `roai` from sync context returns a Promise and
  silently breaks the assignment — verify call-site async-ness when touching
  particle-creation code.
- `i_req_ttlilt(req, secs, sc)` sets `w.c.has_req_ttlilt` — Story's quiescence
  gate.  No separate `demand_time_to_think` needed.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime (via
  `req.c.oncelers`).  Gate one-shot setup inside `do_fn` with it.
- The `req` mainkey is the default; no need to customise it unless genuinely
  distinguishing different classes of request on the same host particle.
- `Se.process({ n, process_D, match_sc, trace_sc, each_fn, trace_fn,
  resolved_fn, done_fn })` walks `n` against a D, building a transient `Travel`
  ropeway (`T**`).  `trace_fn` mirrors `n.sc` into D; D nodes `replace()` so a
  kept `D/U` persists across walks.  `resolved_fn(T, N, goners, neus)` is the
  diff.  `match_sc:{}` is all-inclusive and keeps no D/U.
- Vocabulary settled this round: **Understanding** (`U`) the bounded checkout;
  **UPoint** a checked-out Point; **`/%Understandable`** the U-sphere clone
  hanging under **`/%Demonstrations`** (the D sphere); `n.c.U` the clone's
  provenance $C.  `%Pointo` is retired.  Local meanings live on the clone
  (`C:Point//U/%showing`), never on the source `%Point`.
