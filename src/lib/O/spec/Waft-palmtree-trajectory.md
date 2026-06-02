# Waft palmtree trajectory — reqy migration + What transport

`Waft_spec.md` owns the design.  This doc owns the implementation slice.

---

## What cursor model

A Waft is a tree of What, Doc, and Point — but **What is the base type**.
Doc and Point are refinements; when something sits in the position of a Point
but isn't one, it's another place the cursor wants to visit before returning.
It might stop and take in a Doc with no Points, even.

But for now it's quite strictly `Waft(/What/(Doc|Point*)*)*`, so we can clone
a simple flat list of What/* to manipulate...

```
Waft,Ghost/LakeNets
  What,label:foundations
    What,label:story
      Doc,path:Ghost/Story/Peeroleum.g
      Point,method:LakeNetherland
    What,label:peer
      Doc,path:Ghost/Peeroleum.g
      Point,method:Peeroleum
```

**Consequence for the cursor API:** `LiesCurse` should not be the place that
knows about Waft tree shape.  The "what is a valid cursor stop" and "what is
the next stop" logic belongs in helpers on the Waft side:

```
H.Waft_cursor_next(w, examining)   // advance to next stop
H.Waft_cursor_first(waft)          // first stop in a Waft
```

---

## Architecture (post Spotlight-Interest)

```
w:Lies
  /%examining
    /%Spotlight           sc.src ($C → %What | %Doc)
                          // < sc.accepted_entries / sc.accepted_push_id — pre-NaviCado; not yet
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
    /%LE                  the active one, primarily lives in a /dock
    /%Interest            sc.src = working clone root
    /%dock:$path           same-object hold → /docks/%dock:$path
    // /%spinner,stale / /%spinner,grafted
  /req:workon
    /req:push             encode → replace → verify; /%dirty fault child
    /req:maneuvre         reset on each cursor move
      /req:checkout,maz:3   LE_arm + LE_pull; (re)create %Interest at clones
      /req:furnish,maz:2    wait for dock (req:Furnishing mints it)
      /req:graft,maz:1      Lang_graft_points_once + open-ended req:Showing tail

  /docks/%dock:$path
    /%Compile → %methods, %Output
    /%Pmirrors
      /%Pmirror,$waft_key,$spec
          c.src_clone   → governing clone (for req:Showing to reach c.U)
    /%LE
      /%State           sc.armed | sc.changey | sc.stale
      // %push_dirty    fault child; not yet in reqy fault UI
      /%Seem:origin     Se:Selection, C:$src    — awareness; goners/neus = stale
      /%Seem:working    Se:Selection, C:clones  — editable clone tree
        /%Demonstrations:working
          /%Understandable   per-clone U sphere
              sc.unshowing|unaccepted
          //$C
              sc.class
```

Key structural facts post-SI:

- `src_Waft` is gone.  `waft_key_of(src)` walks `c.waft`/`c.up` — available on
  any Waft-linked node.  `Seem_clone_C` stamps `root.c.waft` so clone roots are
  also reachable.
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

The U sphere (`U%unshowing`, `U%unaccepted`) is that.

The consolidation: move the capsule strip and its state management from
DocMinimap into NaviCado, making the U sphere the single truth for
showing|accepted-ness and expressed in the negative.  DocMinimap keeps:
regions, def chips, scroll sync, nav history,
fold toggle.  NaviCado gains: the capsule `{#each}`, `in_group`/`showing`,
`push_what_point`, `reset_what_point`, `receive_what_point_from_lies`,
`collect_le_membership`.  The unsent bar goes with them.

This matters before 4c because 4c's carry-over seeding reads `clone.c.U?.sc.unshowing`
to decide what to copy forward, and stamps `class:'ghost'` via the U sphere.
Having two competing truths about showing/accepted would confuse that read.

**Glow fix (tiny, do first).**  The Waft row glow currently checks
`spot.sc.src === what` — only the directly-targeted `%What` lights up.  When
`src` is a `%Doc` nested inside a `%What`, or when the cursor is on a child
`%What`, the parent row stays dark.  The fix walks `src.c.up` until it finds
the `%What` being rendered:

```ts
{@const is_what_active = (() => {
    examining?.vers
    const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
    if (!spot?.sc.src) return false
    // glow any %What that is src itself, or an ancestor of src via c.up
    let node: any = spot.sc.src
    while (node) {
        if (node === what) return true
        node = node.c?.up
    }
    return false
})()}
```

Three lines in Waft.svelte.  `c.up` is stamped by `Waft_link_up` on every
`%Doc` and `%What` in the tree; the walk terminates at the `%Waft` ceiling.

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
4d  ◀◀ rwnd
```

---

## Chunk 4c — branch + dive %What** space

The two gestures create new `%What` particles from the current cursor position.
They look like the vector indented lines move when encoding this structure.

### ↓ onwards +time

Creates a new `%What` sibling immediately after the current one in the parent's
child list, which becomes the new cursor target.

### ↘ furthermore +time

Creates a new `%What` *inside* the current one.

1. User selects a split point (between which two Points the new What is
   inserted) — UI TBD; simplest is between the last accepted Point and the rest.
2. Points below the split move into the new child `%What`; Points above stay.
3. The new child What becomes the cursor target; the parent What retains the
   Points above the split.

The dive address (which Points delimit the pocket) is the Dip concept from
`Waft_spec.md` — deferred for now.  Initial implementation: ↓ always dives
after the last accepted/showing Point.

### +time: the carry-over heuristic

When a new `%What` is sprouted off another (both ↘ and ↓), seed its new What/*
with Points still accepted and showing. If one was `U%created_at` recently,
assume we are meant to take that from the old group. `U%created_at` is ephemeral.

The `Seem:workon` may be kept around and navigated back to, turning up with
unpushed state and the same C it checked out, if dige still matches.

If we +time away from one What/*, it may play a parent relation... Perhaps if we just
look around, the last few waves of things we have looked at kinda stay,
lurking ever smaller at the edges...
After +time, the prev What's uncarried Points appear in NaviCado below a horizontal line — smaller, fainter, secondary. Clicking one unretires it: `LE_add_clone(current_LE, pt.sc)` copies it into the current What's clone tree and it hides from the secondary strip (its spec is now in the current clone set). Orb-toggling it back to unshowing re-retires it: the clone is dropped from the current tree, its spec leaves the current set, and the Point reappears in the strip from the prev source — undisturbed throughout.

The secondary strip needs no container. It is a pure derived view:

```
prevWhat Points (direct + via Doc children)
    filtered to: spec not in current What's clone tree
```

`clone.c.from_prev = true` stamped at unretire time (on `c`, invisible to encode/push) tells the orb and × apart from freshly-created clones — for those, orb means `U%unshowing` and × means `U%unaccepted` as usual.

```
// < secondary strip looks one step back (LE_what_prev) for now;
//   ancestry depth is open.
```

So the old What/* lurks beneath the current ones, as a different but same-looking
UI, where they can be easily individually brought back from.

I suppose other paraphenalia might lurk longer than the so-ing machine is biting
it too, in ways that can transpire more involvement...

### handling

unshowing is just presentation-facing, for codemirror to do decorations. it'll need flushing to when that toggles?

we might be manipulated to show|unshow by some other system.

unaccepted tries (even if you leave the target, could nag to save|abandon) to push that disinclusion

Other changes to the C push more easily? And pushing Waft to disk or where-ever is a little slower?

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.

---

## Open faults

```
// < Waft glow walks only the direct %What identity check; should walk
//   src.c.up so any ancestor %What of the cursored node also glows.
//   Three-line fix in Waft.svelte (see §Where we are).

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
// < Doc > What rendering: Waft.svelte renders Doc > What children for
//   visibility; cursor candidates still don't reach them.  One-Doc-per-What
//   restructuring eliminates the nesting.

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
- Snap notation: `:1` suffix is suppressed by depeel, so always write
  `What,label:x` not `What:1,label:x`.  A key alone implies value 1.
- One-Doc-per-What: section Whats are pure containers (no Doc, no Points
  directly); leaf Whats have exactly one Doc.  Cursor candidates only surface
  Whats that have points (`Lies_what_has_points`).
- `oai` sync, `roai` async; `i()` always inserts.
- `i_elvis_req` carries the req particle itself; `finish(reply)` pings `reqturn:1`.
- `i_req_ttlilt` holds the snap open (defers finalize); it does not poke a think.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.
- UItime reactivity: always `void C.vers` (the `$state` signal), never
  `void C.version` (the Atime counter, not tracked by Svelte).  The
  double-click glow bug was caused by this.  Watch for it elsewhere.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime.
- `watch_c` handlers are `async () =>` and the flush loop awaits them.
