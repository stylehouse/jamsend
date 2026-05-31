# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design* of the What
tree and its transport semantics; this doc owns the *implementation slice*.

---

## Lang/LE architecture

```w:Lies
  /%examining
    /%What_Points
        sc.src      $C → %What    ← checkout target (arm point)
        sc.src_Waft string

w:Lang
  /%docks
    /%Dock,path                    ← one per open file; carries CM state + compile
      /%Compile
        /%Output
      /%bookmark,N
      /%LE                             ← stable; not inside replace()
        /%State                        ← synthesised: armed/changey/stale (see LiesEnd_spec)
        // %push_dirty — fault; present when push didn't land clean
        /%Seem:origin
            sc.Se  Selection()
            sc.C   → live OC%What        ← the remote; never edited
            /D%Demonstrations:origin**   ← awareness sphere; neus/goners = stale signal
            /%News:origin
        /%Seem:working
            sc.Se  Selection()
            sc.C   → clone C%What        ← our editable tree
            /D%Demonstrations:origin**   ← awareness sphere (** means this stuff is recursive)
              /%Understandable           ← U node; unshowing/unaccepted live here
            /%News:working

  /%Languinio
    /%Change                       ← three-leg display strip (storage/backend/compile)
    // /%LE — same-object hold on whichever Dock/%LE is foregrounded
    //   re-pointed on active_dock change

ave/%active_dock                   ← reactive signal: which %Dock is foregrounded
  sc.path  string
  c.dock   $C → %Dock              ← direct ref; Langui reads for bookmarks

ave/%lang_dock,path                ← text sync; sc.text / sc.text_dige / sc.disk_dige
```

Key structural facts:

- `LiesEnd` methods run on the same House as `Lies` — `H.LE_arm`, `H.LE_pull`
  etc. are available from any Lies tick or LiesCurse callback without a
  cross-world round-trip.
- The Understanding is **Lies's checkout, Lang's read**: Lang reaches it through
  the `%Languinio/%LE` same-object hold (`C.i(C)` of the live `%LE`), so it
  can call `LE_clones()` and check `%State` without messaging.
- `Lies_set_examining` is the single seam: on a cursor move it calls
  `LE_arm(w.oai({LE}), what_C)` and re-points the Languinio hold.

---

## Chunk U — the Understanding ✓ done

*Chunk 4's navigation gestures all manipulate a checked-out extent of the Waft;
this chunk is that checkout.  Built and proven in an isolated harness
(Understandity → Understandium → Understandication); not yet grafted onto the
live Lies+Lang cluster.*

### The reframing

Lies owns the `/%Waft/%What**` graph.  It commissions Lang to **look at an
area** of that graph — Lang gets a grasp on it, navigates around inside it, and
manipulates it from that grasp.  The area we focus on is a `%What`'s immediate
`/%What/%Point` extent.

The checked-out area is an **Understanding** (`U`): a small, bounded clone of a
big graph.  Bounded size is the joke in the name — for now an Understanding is
deliberately tiny, one What's worth of Points.  A checked-out Point inside an
Understanding is a **UPoint**.  (`%Pointo` is retired — the wrapper-capsule idea
collapses into the U-sphere clone below.)

### The two-sphere stitch

A `%Point` is resolved by the **D sphere** and understood by the **U sphere**.

- **D — `/%Demonstrations`** — mainkey|match|trace-based.  Tracing a `C:Point`
  into D gives its durable resolved node.
- **U — `/%Understandable`** — hangs *under* one D node:
  `/%Demonstrations/%Understandable`.  The U node is where **local meanings**
  live — written on the U, never on the source `%Point`.

Absence is the positive case.  The meanings we know about so far are negative
flags:

```
C:Point//U%unshowing   ← opt this clone out of the Lang UI display
C:Point//U%unaccepted  ← virtual deletion: omit from next push and encode
```

The durable identity rides on the Point; `unshowing`/`unaccepted` ride on U.
The C** is clean — its entire `.sc` can be taken to replace the target's
children on push.

### The two-Seem model — origin and working

Two `Selection` walks hang off one `%LE`, each its own Seem:

```
w/{LE}
  /%Seem:origin,Se:Selection(),C:$OC,topD    ← reads the remote %What
    /%Demonstrations:origin                  ← topD; awareness sphere

  /%Seem:working,Se:Selection(),C:$C,topD   ← holds the editable clone tree
    /%Demonstrations:working                 ← topD
      /%Understandable                       ← per-D U node (use_Understandable)
```

`Seem:origin` walks the live `%What` for awareness — its `goners`/`neus` are
clues about when the remote moved.  `Seem:working` walks the fabricated clone
tree; its D nodes carry `/%Understandable` children where local meanings live.
Only `Seem:working` uses the U sphere.

`LE_arm(LE, what_C)` drops both Seems on re-arm so their D/U spheres start
empty — without this, `resolve()` pairs a fresh clone against a stale D node of
similar shape and `resume_X` bleeds old meanings across to an unrelated target.

### The checkout / replace-back mechanism

- **Clone `What/*` only** — the immediate child layer.  A nested `%What` child
  gets a D node but is never entered; its deep `%Point` children resume on push.
- Edit clones in place; detect edits via `LE_encode_compare` (enWaft snap
  comparison, not structural `goners`/`neus`).
- **Push** = `target.replace({}, ...)` inserting accepted clones back as the
  target's children.  Clones with `U%unaccepted` are omitted — virtual deletion.

The crucial trick: because we cloned shallowly, replacing back **resumes**
`What/*/*`.  A nested `%What/%What/%Point` we never touched was never detached;
it rides back in under the replaced stub.

```
checkout:   What → [ Pa, Pb, What2 ]     clone 3 children, shallow
            What2 → [ Pc ]               ← NOT cloned, left in place

push-back:  replace What's children with our (possibly-edited) clones
            What2 resumes → [ Pc ]       ← deep layer never moved
```

### The diff that matters — encode-compare

`goners`/`neus` from either Seem is the *structural* diff (whole-C in/out).
The push-state diff is:

```
enWaft( Seem:origin slice )   vs   enWaft( Seem:working state )
```

String-equal snaps → nothing to push.  This is `LE_encode_compare`.  Origin
encodes each top-level child shallowly (`max_child_depth:0`) to match working's
childless stubs; working encodes normally.  `U%unaccepted` clones are omitted
from working's snap.

### API surface (in LiesEnd.svelte)

Core: `LE_arm`, `LE_pull`, `LE_push`, `LE_clones`, `LE_encode_compare`,
`Seem_toString`.  Proven helpers now resident: `LE_add_clone`, `LE_drop_clone`,
`LE_accepted_clones`.

### `%What_Points` — the checkout cursor

`%What_Points` names where we check out — `{ src $C, src_Waft }`, the one
`%What` whose `/%Point` extent the Understanding mirrors.  After a push we
expect a no-diff on the return-pull.  A non-empty diff means the push didn't
land cleanly — a catchable fault.

### LE states

See `LiesEnd_spec.md` for the full state vocabulary (armed / clean / changey /
stale / dirty) and `%State` particle layout.

### Open faults

- `// <` the no-diff-after-push check needs a home: a `reqonce` on the push req
  that arms a return-pull and raises a fault C if the diff is non-empty.
- `// <` `U%unaccepted` vanish: the absent clone lands as a goner on the
  post-push awareness pull, firing `push_dirty`.  Fix: `LE_push` stamps
  `bD/was_disincluded:1` before replace-back; `resolved_fn` recognises that
  goner and suppresses `push_dirty`.
- `// <` integration to Lang/Lies (Languinio/LE switching, `wpt.sc.src = LE`,
  path-match guards) — LE must be a being-for-itself first.

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
      ttlilt:until_ts:T,playing   ← armed only in auto-advance mode
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

Accepted Points carry forward (Chunk 3) because the spelunker marks the wall and
that mark survives the return trip.

### `+time` carry-over heuristic

When a new `%What` is created (`→` or `↘` or `↓`), the heuristic seeds its
in-group:

- Points with `accepted:1` AND `showing` → copied forward.
- Points created `< 30s` ago → moved forward (part of this thought).
- Everything else → ghost at 18% opacity, 10s rescue window, then fade.

`showing` is the DocMinimap capsule visibility (orb toggle).  Dormant Points
stay in the old chamber.  The rescue window: `reqonce(what_req, 'rescue_window')`
arms a ttlilt for 10s; after expiry, unrescued ghosts are dropped.

### `◀◀ rwnd`

Steps back through `%What` siblings in reverse, re-loading their showing set
into `%What_Points`.  Read-only — no mutations to accepted state.
The "you were here" marker.

### Sub-slices

- **4a** — `e_Lies_cursor_next` steps sibling `%What` (not just `%Doc`)
- **4b** — `req:desire` + playing/pause loop
- **4c** — `↘` / `↓` branch and dive gestures
- **4d** — ghost + rescue window + `◀◀ rwnd`

---

## Sequencing

- **1** first — graft ttlilt, ~ten lines, immediately visible.
- **2** — internal tidiness, one PR after 1.
- **3** — small, prerequisite for 4.
- **U** ✓ — the Understanding.  Built and proven in isolation; harness is green.
  Not yet wired onto the live Lies+Lang cluster — that wiring is the next step
  before Chunk 4 begins.
- **4** — multi-reset, design sub-slices before each.  Sits on top of U:
  each gesture is "re-aim `%What_Points`, re-pull, push".

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
- Vocabulary: **Understanding** (`U`) the bounded checkout; **UPoint** a
  checked-out Point; **`/%Understandable`** the U-sphere node hanging under
  **`/%Demonstrations`** (the D sphere); `C.c.U` the clone's direct ref to its
  U node, `C.c.D` to its D node.  `%Pointo` is retired.  Local meanings live on
  U (`C:Point//U%unshowing`), never on the source `%Point`.
- Particle rename (Lang-side only): `docC` → `dock`, `{doc:path}` → `{dock:path}`,
  `lang_doc` → `lang_dock`, `active_doc` → `active_dock`.  `loaded_doc` keeps its
  full name (Lies-side loaded-file record, not a Dock).  Waft-side `%Doc` particles
  are unchanged — `%Doc` is a document in the tour; `%Dock` is Lang's docked-file
  particle (carries `/Compile`, `/Pmirror`, `/bookmark`).
