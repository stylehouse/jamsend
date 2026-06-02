# Waft palmtree trajectory — reqy migration + What transport

`Waft_spec.md` owns the design.  This doc owns the implementation slice.

---

## What cursor model (the real design)

A Waft is a tree of What, Doc, and Point — but **What is the base type**.
Doc and Point are refinements; when something sits in the position of a Point
but isn't one, it's another place the cursor wants to visit before returning.

Types stack up positionally. Reading top-down through the tree:

```
What                   title-page / interstitial — valid cursor stop
What/Doc               a doc before any time-slice What arrives — its own moment
What/Doc/What          time-slices inside a doc; each is a cursor stop
What/Doc/What/Point    the full inhabited case
What/What              nested section — cursor recurses before returning
```

**Consequence for the cursor API:** `LiesCurse` should not be the place that
knows about Waft tree shape.  The "what is a valid cursor stop" and "what is
the next stop" logic belongs in helpers on the Waft side:

```
H.Waft_cursor_next(w, examining)   // advance to next stop
H.Waft_cursor_first(waft)          // first stop in a Waft
```

`e_Lies_cursor_next` and `e_Lies_desire_step` both inline this logic.
They should converge on the same helper.

---

## Architecture (post Spotlight-Interest)

```
w:Lies
  /%examining
    /%Spotlight,1         sc.src ($C → %What | %Doc)
                          sc.accepted_entries / sc.accepted_push_id  ← retiring; see §next
    /req:timemachine      sc.playing:0|1 — playback engine; seeded by req:acquire
  /req:wants              cursor-intent accumulator
    /%want,$ts            c.src → wanted C; sc.kind: click|drag|step|next|cold
  /req:desire
    /req:acquire,maz:9    gate; holds until a Waft is locked
    /%Waft,key            c.src → locked Waft
  /req:git                Waftlet accumulator; < do_fn pending
  /req:Furnishing,path    doc-open RPC; seeded by wants resolver

w:Lang
  /%Languinio
    /%Interest,1          sc.src = working clone root; c.LE → /%LE
    /%dock,path           same-object hold → docks/{dock:path}
    // /%spinner,stale / /%spinner,grafted
  /req:workon
    /req:push             encode → replace → verify; /%dirty fault child
    /req:maneuvre         reset on each cursor move
      /req:checkout,maz:3   LE_arm + LE_pull; (re)create %Interest at clones
      /req:furnish,maz:2    wait for dock (req:Furnishing mints it)
      /req:graft,maz:1      Lang_graft_points_once + open-ended req:Showing tail

  /docks/{dock:path}
    /%Compile,1 → %methods, %Output
    /%Pmirrors,1
      /%Pmirror,$waft_key,$spec
          c.src_clone   → governing clone (for req:Showing to reach c.U)
    /%LE,1
      /%State           sc.armed | sc.changey | sc.stale
      // %push_dirty    fault child; not yet in reqy fault UI
      /%Seem:origin     Se:Selection, C:$src    — awareness; goners/neus = stale
      /%Seem:working    Se:Selection, C:clones  — editable clone tree
        /%Demonstrations:working
          /%Understandable   per-clone U sphere
              sc.unshowing / sc.unaccepted / sc.class
```

Key structural facts post-SI:

- `src_Waft` is gone.  `waft_key_of(src)` walks `c.waft`/`c.up` — available on
  any Waft-linked node.  `Seem_clone_C` stamps `root.c.waft` so clone roots are
  also reachable.
- `%Interest` is Lang's one focus object: the clone root (`src`) plus a
  `c.LE` back-ref to the working LE.  NaviCado reads it for nav; the graft reads
  it for render.  Dropped and re-created on each checkout.
- `req:Showing` is the cache-key-independent repaint path: fold/glow effects
  without rebuilding Pmirror identity.  Each Pmirror carries `c.src_clone` so
  Showing reaches `c.U` without re-resolving by spec.
- `req:Furnishing` is the doc-open RPC.  The wants resolver seeds it; Lang drains
  it via `o_elvis_req`; `finish(reply)` pings `reqturn:1` so Lies re-thinks.
- `e_Lang_LE_add`, `e_Lang_LE_edit`, `e_Lang_LE_drop`, `e_Lang_LE_push` are the
  write paths for clone-tree mutation.  All call `feebly_ponder()` so the
  maneuvre re-encodes on the next tick.

---

## Where we are — what's next

**Spotlight-Interest (4b.5) is done.**  The 3a–3j work landed: req:wants,
Lies_i_Spotlight called only from the resolver, %Interest, waft_key_of,
req:timemachine on %examining, req:desire as just the Waft lock, req:Showing,
pmirror.c.src_clone, req:push three-phase cluster, req:Furnishing RPC,
breadcrumb removed.  Known open faults remain (listed below) — none are
blockers for 4c.

**The pending integration: two systems for acceptance.**

`showing`/`accepted` on source %Point particles (old, persisted in the Waft snap)
still coexist with `U%unshowing`/`U%unaccepted` on the U sphere (new, session).
DocMinimap maintains local `$state in_group`/`showing`, pushes them to Lies as
`accepted_entries`, and receives them back as `accepted_push_id`.  The U sphere
already drives the graft and req:Showing correctly, but the persistence mechanism
still goes through `Lies_accept_What_Point`/`sc.accepted`/`sc.showing` on %Points.

The consolidation: move the capsule strip and its state management from
DocMinimap into NaviCado, making the U sphere the single truth for
showing/accepted.  DocMinimap keeps: regions, def chips, scroll sync, nav history,
fold toggle.  NaviCado gains: the capsule `{#each}`, `in_group`/`showing`,
`push_what_point`, `reset_what_point`, `receive_what_point_from_lies`,
`collect_le_membership`.  The unsent bar goes with them.

This matters before 4c because 4c's carry-over seeding reads `clone.c.U?.sc.unshowing`
to decide what to copy forward, and stamps `class:'ghost'` via the U sphere.
Having two competing truths about showing/accepted would confuse that read.

**Sequencing:**

```
next    NaviCado / accepted_entries consolidation
          capsule strip + in_group/showing state → NaviCado
          U sphere becomes the single truth for showing/accepted
          DocMinimap sheds the capsule block and its state
4c      ↘ / ↓ branch + dive
4d      ghost + rescue + ◀◀ rwnd
```

---

## Chunk 4 roadmap

```
4a  cursor_next steps %What  ✓ (logic still scattered — Waft_cursor_next pending)
4b  req:desire playing loop  ✓ (req:timemachine; 4s auto-advance stub)

4c  ↘ / ↓  branch + dive
4d  ghost + rescue + ◀◀ rwnd
```

---

## Chunk 4c — ↘ / ↓ branch + dive

The two gestures create new `%What` particles from the current cursor position.
Both live in NaviCado (`go_branch` / `go_dive`) and fire new elvistos on the
Lies side.  Write paths already exist: `e_Lang_LE_add`, `e_Lang_LE_push` for
clone-tree mutation; the Lies side needs `e_Lies_branch_What` and
`e_Lies_dive_What`.

### ↘ sibling +time

Creates a new `%What` sibling immediately after the current one in the parent's
child list, which becomes the new cursor target.

Lies side (`e_Lies_branch_What`):

1. Find the current `%What` from `Spotlight.sc.src`.
2. Run carry-over heuristic (below) — produces a `Point** sc[]` to seed.
3. Stamp `sc.class = 'ghost'` on source %Points not carried forward, in the Waft
   snap.  These will appear ghosted when you ◀◀ rwnd back.
4. Insert a new `%What,N,label:''` particle after the current one in the Waft
   snap (parent's child list).  Populate it with the carry-over Point children.
5. Call `Waft_link_up` to stamp `c.up`/`c.waft` on the new subtree.
6. Save the Waft snap.
7. Emit a want for the new What (kind: `'branch'`) — the resolver funnels it
   through `Lies_i_Spotlight`; req:workon re-arms checkout at the new What.

Lang side: `req:checkout` arms the new (empty) What, pulls (gets an empty
clone tree), grafts (no Pmirrors minted), and waits.  The user adds Points via
the capsule strip; each addition goes through `e_Lang_LE_add` + `e_Lang_LE_push`.

### ↓ child +time (dive)

Creates a new `%What` *inside* the current one, positioned between two chosen
Points:

1. User selects a split point (between which two Points the new What is
   inserted) — UI TBD; simplest is between the last accepted Point and the rest.
2. Points below the split move into the new child `%What`; Points above stay.
3. The new child What becomes the cursor target; the parent What retains the
   Points above the split.

The dive address (which Points delimit the pocket) is the Dip concept from
`Waft_spec.md` — deferred for now.  Initial implementation: ↓ always dives
after the last accepted/showing Point.

### +time carry-over heuristic

When a new `%What` is created (both ↘ and ↓), seed its in-group:

- Points with `!clone.c.U?.sc.unshowing` (currently showing) AND `clone.sc.accepted`
  (in the capsule strip) → **copy** their sc into the new What as Point children.
- Points created `< 30s` ago (`created_at` in sc — session-only, stripped from
  snap writes) → **move** rather than copy; not ghosted in the old What.
- Everything else → left in the old What; `sc.class = 'ghost'` stamped in the
  snap.

`created_at` is appended to each clone at `LE_add_clone` time and stripped by
`Seem_toString` / `enWaft`.

### class:'ghost' and the U sphere

`sc.class = 'ghost'` lives on the source %Point particle in the Waft snap —
persisted, not session-only.  On the next `LE_pull` for that What, `Seem_clone_C`
copies `{ ...child.sc }` so the clone has `sc.class:'ghost'`.  The graft currently
reads `src_clone.c.U?.sc.class`; this means `Seem_clone_C` (or the traced_fn
walk) needs to seed `c.U.sc.class` from `clone.sc.class` when the source
carries a class.

```
// < Seem_clone_C: after building the root, walk children and for each
//   child.sc.class, stamp the corresponding U node's sc.class so the graft
//   reads the right decoration without extra lookups.
//   Alternatively: the graft falls back to (clone.sc as any).class when
//   c.U?.sc.class is undefined — simpler but less uniform.
```

Rescue (Chunk 4d) clears `sc.class` off the source particle and moves it
into the active What's clone tree; `LE_push` lands the change; `Waft_link_up`
re-stamps.

---

## Chunk 4d — ghost + rescue + ◀◀ rwnd

### Ghost decorations

`class:'ghost'` Points in the current Working clone tree render at 18% opacity
and 40% height via `ghostDecorationField` (a CM `StateField<DecorationSet>` at
lower precedence than `pointDecorationField`).  `req:Showing` dispatches
`setGhostDecorationsEffect` on each repaint alongside the normal fold/glow effects.

The 10s rescue window: when a `%What` is first branched, a `reqonce` on the
new What's req stamps a `req:rescue_window` with a ttlilt for 10 s.  After
expiry, unrescued ghosts (still `class:'ghost'` in the source snap) are dropped
from the old What's LE: `e_Lang_LE_drop` with `spec` matching the ghost clone.
This calls `LE_push` via the push cluster — the old What's snap loses those Points.

```
// < the rescue window needs a home: a ttlilt req under the old What's req:workon,
//   not the new one.  After branching, both Whats may have live LE instances
//   (NaviCado can navigate back).  The rescue timer belongs with the old What's
//   Understanding.
```

### Rescue gesture

Clicking a ghost capsule in NaviCado (it's shown dim, struck-through):

1. Clears `sc.class` from the clone's U sphere (`clone.c.U.sc.class = undefined`).
2. The source particle's `sc.class` is cleared on the next `LE_push` (the push
   writes back the clone sc which no longer carries class).
3. Optionally moves the clone into the new (active) What's clone tree —
   `LE_add_clone(active_LE, clone.sc)` — so the rescued Point lives in both
   Whats' snaps after the double push.
4. `feebly_ponder()` → req:Showing repaints immediately (ghost decoration drops).

### ◀◀ rwnd

Steps the cursor backward through sibling `%What` particles without mutating
anything.  A NaviCado button, already present as `go_prev()`.  `go_prev` already
emits `Lies_cursor_what` with the prior sibling via `LE_what_prev` — this IS the
◀◀ gesture.  What makes it rwnd-flavoured: when you ◀◀ into a What that has ghost
Points, those Points render ghosted in CM while the cursor is there.  No new
mechanics needed beyond the ghost decoration field above.

The "you were here" marker: `req:Showing` can light a dim indicator on the
`%What` header row when `any clone in working has class:'ghost'` — a visual cue
that this is a prior time-slice.

```
// < ◀◀ is therefore just go_prev() — the label and any distinct icon are
//   the only addition.
```

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.  `→` walks the main
passage.  `↘` carves a side-tunnel from the current chamber.  `↓` drops into
a pocket discovered between two Points in the floor.

The audience follows the spelunker.  `→` is legible because they know where
they came from.  `↘` is "we'll return to this junction."  `↓` is "look what's
down here."  ◀◀ is the lamp swinging back through chambers already explored.
Ghost Points are marks chalked on the wall — faint, still readable, erasable
by rescue.

---

## Open faults

```
// < Waft glow walks only the direct %What identity check; should walk
//   src.c.up so any ancestor %What of the cursored node also glows.
//   Three-line fix in Waft.svelte (see §Where we are).

// < accepted_entries / accepted_push_id on %Spotlight and DocMinimap's
//   in_group/$state — the old pre-U-sphere acceptance path.  Retiring:
//   capsule strip moves to NaviCado; U sphere becomes single truth.

// < DocMinimap still reads ave/%active_dock (sig.c.dock) for lang_dock;
//   migrate to languinio.o({dock:1})[0] in Languinio/%dock.

// < Seem_clone_C: seed c.U.sc.class from child.sc.class at clone time, or
//   fall back to clone.sc.class in the graft.  Needed before ghost rendering.

// < created_at session field on clones — stripped by Seem_toString / enWaft;
//   needs wiring in LE_add_clone and the strip list.

// < rescue window: ttlilt req lives under old What's Understanding, not the
//   new one.  Needs a home before ghost decay is safe.

// < vanish: unaccepted clone goner fires push_dirty on verify re-pull.
//   Fix: LE_push stamps bD/was_disincluded:1 before replace-back;
//   resolved_fn recognises that goner and suppresses push_dirty.

// < req:push/%dirty not yet surfaced in the reqy fault UI.

// < clone.c.waft is one scalar on the clone root; LE.sc.target.c.waft is the
//   fallback for any clone landing unstamped.

// < LE_what_* stay identity-based and frail; Travel-based when the tree grows.

// < graft fallback to src_C in the pre-pull window: one stale tick where
//   unaccepted/unshowing Points still paint.

// < req:wants never prunes; history grows unbounded until a sweep exists.

// < req:timemachine is a reqy particle under %examining (an ave signal);
//   tolerated — precedent: %Spotlight child + c.w back-ref.

// < maz:0 in the existing maneuvre (req:encode) is out-of-spec; fold into
//   graft tail and confirm maz bottoms at 1.

// < second Doc (Ghost/Peeroleum.g) doesn't load into CM — empty editor, no
//   spinner.  The editorBegins storm (7 pairs) suggests active_dock ping-pong.

// < e_Lies_cursor_next and e_Lies_desire_step duplicate "next candidate" logic;
//   should converge on Waft_cursor_next(w, examining) helper.

// < e_Lang_LE_drop demote round-trip takes a full cursor-move cycle.

// < stale spinner: req:encode should also clear spinner:stale after a clean
//   encode-compare, in case stale lingers past checkout.

// < req:git do_fn — flush Waftlets to disk/remote.

// < Se_o as standing watch — call-driven for now.
```

---

## Style notes (standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars; `$C` for TheC refs in sc.
- `oai` sync, `roai` async; `i()` always inserts.
- Cross-domain refs are scalar `$C` pointers in `c.*`; no domain writes another
  domain's `sc`.  `%Interest.src`, `%Interest.c.LE`, `clone.c.waft`,
  `pmirror.c.src_clone` are same-object holds.
- `i_elvis_req` carries the req particle itself; `finish(reply)` pings `reqturn:1`.
- `i_req_ttlilt` holds the snap open (defers finalize); it does not poke a think.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime.
- `watch_c` handlers are `async () =>` and the flush loop awaits them.
