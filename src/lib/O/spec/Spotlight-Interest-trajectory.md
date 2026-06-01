# Spotlight ↔ Interest — the cursor modernisation

`Waft_spec.md` owns the decoration design.  `Waft-palmtree-trajectory.md` owns
the reqy slice.  This doc owns the **cursor symmetry** slice: who holds "what is
being looked at" on each side, where playback lives, and how the LE clone tree
finally reaches the screen.

The thesis in one line: **Lies holds an intention (`%Spotlight`), Lang holds a
realisation (`%Interest`), and the second is derived from the first plus the
Understanding — not a third free-floating particle.**

---

## 0. Spec-vs-built drift (reconcile first)

Before proposing, three places where the running code has already moved past
the prose:

- `LiesEnd_spec.md` "Graft seam" still describes Lies owning `%LE` on its own
  `/%Dock/%LE` and handing the live particle across via
  `i_elvisto(Lang, 'Lang_LE_arm', {LE})`.  **The built code does not do this.**
  `Lies_i_Spotlight` fires `Lang_workon_update,{src}`; Lang arms *its own*
  `/req:workon/{LE:1}` in `req:checkout`.  `e_Lang_LE_arm` is gone.  So **LE is
  Lang's now** — Lies only ships `%src`.  Good change; the spec is stale, not
  the code.

- `Waft_spec.md` defines `/%active_what/sc:path/sc:what_keys/c:what` as the
  breadcrumb.  The built `%active_what` carries none of that — only
  `c.completion` and (through it) `sc.playing`.  It became a transport handle,
  not a breadcrumb.  Its name now lies.

- `Seem:working%C` (the clone tree, the whole reason the two-Seem model exists)
  is read by the **edit** paths (`e_Lang_LE_edit|add|drop` → `LE_clones`) but
  **not** by the **render** path.  `Lang_graft_points_once` reads
  `%Spotlight.sc.src` → `src_C.o({Point:1})` — the live source, never the
  clones.  The U sphere is stranded.

These three are the same shape of problem: **two notions of "what we're looking
at" that should be one notion seen from two ends.**  The modernisation collapses
them.

---

## 1. Catalogue — the cursor systems as they stand

### `%Spotlight` — the Lies cursor (the one real cursor)

```
w:Lies/%examining/%Spotlight,1
  sc.src              $C → %What | %Doc      ← the live Waft particle
  sc.src_Waft         waft_key (snap-readable; c.up chain also reaches it)
  sc.accepted_push_id Date.now() | 1(cold)  ← DocMinimap round-trip token
  sc.accepted_entries { spec, showing }[]
```

Written **only** through `Lies_i_Spotlight` (LiesCurse) — the atomic seam.  Every
cursor move (cold-start, `e_Lies_active_doc_changed`, `e_Lies_set_cursor`,
`e_Lies_cursor_next`, `e_Lies_cursor_what`, desire step) funnels here, and the
seam ends by firing `Lang_workon_update,{src}` across worlds.  `Waft.svelte`
glows the row whose `%What` is `===` `Spotlight.sc.src`.

This particle is healthy.  It is the model for everything below.

### `%Languinio` — Lang's signal particle (a half-built Interest)

```
w:Lang/%Languinio
  c.w                 back-ref
  /%LE                same-object hold → /req:workon/{LE:1}   (installed by req:awaiting)
  /%dock,path         same-object hold → docks/{dock:path}    (re-pointed by Lang_set_active_dock)
  /%spinner,stale     present while origin pull drifted
```

`%Languinio` is already "Lang's `%examining`" — enrolled in ave, parallel
signal.  But it has no single concept of *focus*; it is a bag of three
same-object holds (`%LE`, `%dock`, `%spinner`) that consumers reach into
individually.  Langui reads `languinio.o({LE:1})[0]`; DocMinimap still reads
`sig.c.dock` directly (migration `// <` pending).  This is the thing that wants
to *become* `%Interest`.

### `%active_what` — the identity-crisis particle

```
w:Lies/%active_what          (in ave)
  c.w                  back-ref
  c.completion         → /req:desire/req:completion
  // sc.playing read THROUGH completion, not stored here
```

Named for the breadcrumb (`Waft_spec`), used as a completion handle (NaviCado's
transport bar).  It carries no `path|what_keys|c.what`.  Its only readers are
NaviCado (`H.ave.ob({active_what:1})` → `c.completion` → `sc.playing`) and
`Lies_desire_step_once` (bumps it when playback hits the end).  **Everything it
is actually used for is either the playback (`req:completion`) or recomputable
from `LE.sc.target`.**

### The LE engine — push / pull (healthy, Lang-side)

```
/req:workon/{LE:1}                     stable for the Lang instance
  /%State          sc.armed|changey|stale
  // %push_dirty   fault child; present only when a push didn't land clean
  /%Seem:origin    Se:Selection, C:$src    — awareness: re-walk → goners/neus
  /%Seem:working   Se:Selection, C:clones  — the editable clone tree + U sphere
    .../%Demonstrations:working/%Understandable   per-clone meanings (c.U)
```

`LE_arm(LE,src)` → `LE_pull` (origin awareness walk, first-pull `Seem_clone_C`,
working walk, `%State`) → edits on `LE_clones` / `clone.c.U` →
`LE_encode_compare` (enWaft origin-slice vs working) → `LE_push` (replace-back
skipping `U%unaccepted`, re-pull, `%push_dirty` on fault).  This is the strong
part of the system and the modernisation leaves its internals alone.  The U
sphere — `unshowing`, `unaccepted`, and the coming `class` — lives on
`clone.c.U`, never in `clone.sc`, so enWaft never sees it.

### The graft — LangGraft (the stranded render path)

`Lang_graft_points_once(w, dock)` is what actually paints.  It reads the cursor
cross-world (`ave/%examining/%Spotlight`), takes `points = src_C.o({Point:1})`
**off the live source**, and `.replace()`s `dock/%Pmirrors/%Pmirror,$waft,$spec`
to mint CM marks.  It never touches `LE_clones`.  So:

- a clone marked `U%unaccepted` still grafts (it's still on the source);
- a clone's `class:'focus'` can't reach the Pmirror;
- `U%unshowing` can't fold a row out of CM.

The Understanding edits one tree; the screen renders another.

### desire / completion — the transport

```
w:Lies/req:desire
  /req:acquire        one-shot Waft lock
  /%Waft,key          c.src → the Waft particle
  /req:completion     open-ended; sc.playing:0|1; drains play/pause/step elvises
  /req:git            < Waftlet accumulator
```

`req:completion`'s do_fn lands the cursor (`Lies_desire_land_cursor` →
`Waft_cursor_first`), drains `Lies_desire_play|pause|step` elvises, and
auto-advances `Waft_cursor_next` while `playing`.  It is wired to NaviCado only
through `active_what.c.completion`.

---

## 2. The three faults, named

1. **Stranded U sphere.**  Render reads source, edits write clones.  The two-Seem
   model's payload (`clone.c.U`) cannot reach CM.  This blocks `unshowing`,
   blocks `class` decoration (the entire point of `Waft_spec`), and lets
   `unaccepted` clones keep painting.

2. **`%active_what` means two things and is named for a third.**  Breadcrumb in
   the spec, completion-handle in the code, and the genuine "active What" is
   actually `%Spotlight.sc.src`.  Three referents, one particle, wrong name.

3. **Lang has no single focus object.**  `%Languinio` is a bag of holds.
   Consumers reach `o({LE:1})`, `c.dock`, `o({spinner})` separately, and the
   breadcrumb (depth / siblings / parent) is recomputed ad-hoc in NaviCado from
   the LE prop.  No one place answers "what is Lang attending to right now."

---

## 3. The modernisation — `%Spotlight` ↔ `%Interest`

Two particles, one per world, related as **intention → realisation**.

```
Lies (the showy end)                    Lang (the understanding end)
─────────────────────                   ────────────────────────────
%examining/%Spotlight   ───src──▶        %Languinio/%Interest
  the intention:                          the realisation:
    src ($What|$Doc)                        c.LE      → /req:workon/{LE:1}
    src_Waft                                c.dock    → docks/{dock:path}
    accepted_*                              c.what    → LE.sc.target  (the active %What)
    /req:completion  ◀── transport          (depth | siblings | parent: derived via LE_what_*)
                       (moved here)          c.spinner (folded in from the loose hold)
```

Lies owns intention because Lies is the commissioning, showy end — it decides
*what to light up* and *whether to auto-advance*.  Lang owns realisation because
Lang is the one that actually checked the thing out, holds the clones, and walks
the What tree.  Neither side reaches into the other's particle; the only wire
between them is the existing `src` on `Lang_workon_update` (and the same-object
`c.*` refs the holds already use).

### 3a. `%Spotlight` gains the transport — kill `active_what.c.completion`

Move `req:completion` to hang off `%examining` so the cursor particle carries
both *what is shown* and *whether it is advancing*:

```
w:Lies/%examining
  /%Spotlight,1            the lit target  (unchanged)
  /req:completion          sc.playing:0|1  (was reached via active_what.c.completion)
```

`req:desire/req:acquire/req:git` stay where they are (the *will* and the Waft
lock are desire's, not the cursor's).  Only `req:completion` — the live
play/pause/step state that the UI watches — climbs onto `%examining`, the
already-enrolled signal.  NaviCado then reads transport from the same particle
it reads the cursor from, and `active_what` loses its only real job.

`Lies_desire_step_once`'s end-of-playback bump retargets from
`active_what` to `examining` (or to `completion` directly — it already has the
ref in scope).

> Trade-off: `req:completion` is a reqy particle and `%examining` is an ave
> signal.  Hanging a req under a signal is slightly unusual, but `%examining`
> already mixes a child particle (`%Spotlight`) with a back-ref (`c.w`), so the
> precedent holds.  If that grates, the lighter-touch version is to keep
> `req:completion` under `req:desire` and add `examining.c.completion` — i.e.
> move the *handle* off `active_what` onto `%examining` without moving the
> particle.  That alone dissolves `active_what`; the full move is the tidier end
> state.

### 3b. `%Interest` — Lang's one focus object

Promote `%Languinio`'s loose holds into one `%Interest` child whose `c.*` are
the same-object refs that already exist, plus the derived active-What:

```
w:Lang/%Languinio/%Interest,1
  c.LE       → /req:workon/{LE:1}        (same-object; was Languinio/%LE)
  c.dock     → docks/{dock:path}         (same-object; was Languinio/%dock)
  c.what     → LE.sc.target              (the active %What — the breadcrumb anchor)
  c.spinner  → folded from the loose %spinner hold
```

`c.what` is *not* new state — it is `LE.sc.target`, the thing NaviCado already
derives `depth | has_prev | has_next` from via `LE_what_*`.  Putting it on
`%Interest` gives the breadcrumb a home that `Waft.svelte` and DocMinimap can
read (`languinio.ob({Interest:1})[0].c.what`) without each recomputing from a raw
LE prop.  `req:awaiting` (which already installs the `%LE` hold once) becomes
"install `%Interest` once"; `Lang_set_active_dock` re-points `Interest.c.dock`
and `Interest.c.spinner` instead of the loose holds, then bumps `%Interest`.

The breadcrumb *labels* (`what_keys`) the spec wanted are then a pure read:
walk `LE_what_parent` up from `c.what`, collecting `.sc.label`.  No stored
`what_keys` array to keep in sync — `// <` the spec's `sc.what_keys` is replaced
by a derivation, which is the more-elegant form the prompt is reaching for.

> Reactivity note (`reactivity_docs.md`): readers use `languinio.ob({Interest:1})`
> (not `.o()`) so a re-point bumps them, and chain on `vers`
> (`$derived(Interest && Interest.vers && Interest.c.what)`) rather than
> `$derived.by(void …)`.  NaviCado collapses from "two particles (LE prop +
> `ave/active_what`)" to "one particle (`%Interest`)", and its `$derived.by(void
> …)` transport blocks become inline `vers &&` chains once `completion` is read
> off `%examining`.

### 3c. The graft reads clones — wire the U sphere at last

This is the load-bearing change.  `Lang_graft_points_once` stops sourcing Points
from the live `src_C` and sources them from the Understanding:

```
// before — renders the source, blind to the Understanding
const points = src_C.o({ Point: 1 })

// after — renders what Lang actually understands; U sphere included
const LE     = interest?.c.LE as TheC | undefined
const points = LE ? H.LE_accepted_clones(LE) : src_C.o({ Point: 1 })
//  LE_accepted_clones already drops U%unaccepted.
//  each clone.c.U carries unshowing | class for the Pmirror to honour.
```

Consequences, each closing one of today's `// <`:

- `unaccepted` clones drop out of CM for free (filtered by
  `LE_accepted_clones`) — same predicate `LE_push` and `Seem_toString` use, so
  screen, push, and encode finally agree on what exists.
- `unshowing` (`clone.c.U?.sc.unshowing`) skips minting a Pmirror — the
  `Waft_spec` fold-out behaviour, now reachable.
- `class` (`clone.c.U?.sc.class`, the coming `focus|caution|dim|ghost` set)
  rides onto the Pmirror so the CM decoration field can paint it.  The clone is
  where presentation meaning belongs; the source `%Point` stays clean.

The `src_C` fallback stays for the pre-pull window (cursor set, `LE_pull` not
yet run — `LE_clones` returns `[]`), so a freshly-armed cursor still grafts the
raw source until the Understanding catches up.  The Pmirror identity stays
`$waft,$spec`, so resolve()'s carry-over is unaffected by the source swap.

> Subtlety: the graft must read `clone.c.U`, and `c.U` is only wired after the
> first `LE_pull` (it's `_Seem_CDUsive`'s job).  `req:encode` already runs after
> `req:graft` in the maneuvre maz-order — but graft now *depends on* the pull's U
> wiring, which `req:checkout` (maz:3) does before graft (maz:1).  Order already
> holds.  The only new requirement: graft's cache key must include the working
> Seem's version (a clone edit should re-graft), so extend
> `dock.c.graft_cache_key` with `LE working.version` alongside
> `what_pts_C.version`.

### 3d. What dissolves

`%active_what` is removed.  Its two readers retarget:

- NaviCado transport → `%examining/req:completion` (3a).
- breadcrumb / "current What" → `%Languinio/%Interest.c.what` (3b).

Nothing else holds it.  `Lies.svelte`'s one-time setup drops the
`oai({active_what:1})` block; the desire cluster wires `completion` under
`%examining` instead of `active_what.c.completion`.

---

## 4. Change-set, file by file

```
Lies.svelte
  - one-time setup: drop %active_what creation.
  - req:completion: hang under %examining (3a) OR set examining.c.completion (light).
  - Lies_desire_step_once: bump examining/completion at end-of-play, not active_what.

LiesCurse.svelte
  - Lies_i_Spotlight: unchanged seam; still fires Lang_workon_update,{src}.
    // < it may also stamp examining/req:completion.sc.playing=0 on a manual jump
    //   so a hand-move pauses the slideshow — small, optional.

LiesEnd.svelte
  - no engine change.  Add LE_what_keys(what): string[]  — parent-walk collecting
    .sc.label, so Interest's breadcrumb is a one-call read.  (Frail/identity-based
    like its LE_what_* siblings — // < Travel-based when the tree grows.)

Lang.svelte
  - %Languinio setup: create %Interest child.
  - req:awaiting: install %Interest once (folds in the old %LE hold).
  - Lang_set_active_dock: re-point Interest.c.dock / c.spinner + bump %Interest,
    instead of the loose holds.  Keep ave/%active_dock for Langui's EditorView
    switch (routing, not focus).
  - req:checkout: after LE_arm, set Interest.c.what = LE.sc.target.

LangGraft.svelte
  - Lang_graft_points_once: source points from LE_accepted_clones (3c), fall back
    to src_C only pre-pull.  Honour clone.c.U.unshowing (skip) and .class (stamp
    on Pmirror).  Extend graft_cache_key with the working Seem version.

NaviCado.svelte
  - read LE + breadcrumb from %Interest (one particle); read transport from
    %examining/req:completion.  Collapse $derived.by(void …) to vers && chains.

Waft.svelte / DocMinimap
  - breadcrumb row reads %Interest.c.what + LE_what_keys (Waft_spec's header).
  - // < DocMinimap dock read migrates to Interest.c.dock (the standing migration).
```

---

## 5. Sequencing against Chunk 4c

Do this *before* 4c (`↘`/`↓` branch + dive), not after.  4c's carry-over
heuristic reads `clone.c.U?.sc.unaccepted` at branch time and stamps
`class:'ghost'` on prior-What Points — both of which are U-sphere reads that
only mean something once the graft honours the U sphere (3c).  Branch/dive that
writes `class` onto clones whose `class` the screen ignores is untestable.  So:

```
4b.5  Spotlight↔Interest               this doc
        3a  completion → %examining     (dissolve active_what, half 1)
        3b  %Interest particle          (dissolve active_what, half 2)
        3c  graft reads clones          (wire the U sphere — the unlock)
        3d  remove %active_what
4c    ↘ / ↓  branch + dive             now class:'ghost' actually renders
```

3c is the keystone: it converts `unshowing`/`unaccepted`/`class` from
write-only flags into visible behaviour, which is the precondition for 4c being
demonstrable rather than merely coded.

---

## 6. Open faults (carried + updated)

```
// < Interest.c.what is LE.sc.target by ref — fine while one LE per Lang.  Multi-
//   Lang-per-Lies (out of scope) would need an Interest per dock.
// < LE_what_keys / LE_what_* stay identity-based and frail; a Travel-based
//   implementation is more robust once the What tree outgrows small.
// < graft fallback to src_C in the pre-pull window means a freshly-armed cursor
//   briefly renders unaccepted/unshowing Points until LE_pull wires c.U.  One
//   tick of stale; acceptable, but note it.
// < req:completion-under-%examining mixes a reqy particle into an ave signal.
//   Tolerated (precedent: %Spotlight child + c.w back-ref).  Revisit if reqy
//   lifecycle (finish/unify) ever needs the completion to live in a reqy tree.
// < DocMinimap still reads lang_dock from ave/%active_dock.c.dock; migrate to
//   Interest.c.dock (was: Languinio.o({dock})).  Standing migration, now with a
//   cleaner target.
// < push_dirty still not wired to a reqy fault particle.  Unchanged by this.
// < vanish: unaccepted clone goner fires push_dirty.  Unchanged; 3c makes the
//   unaccepted-is-invisible half true on screen, which is the visible companion
//   to the still-pending push fix.
// < clicking a Waft Doc ~7x loses the What glow (active_dock ping-pong).  The
//   cur_is_what guard in e_Lies_active_doc_changed should still catch it; a
//   single Interest object may make the storm easier to see, not fix it.
```

---

## Style notes (inherited, standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async; `i()` always inserts.
- Cross-domain refs are scalar `$C` pointers in `sc`/`c`; no domain writes
  another domain's `sc`.  `%Interest.c.*` are same-object holds, not copies.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
