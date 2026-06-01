# Waft palmtree trajectory — reqy migration + What transport

`Waft_spec.md` owns the design.  This doc owns the implementation slice.

---

## State as of this session

- NaviCado navigation working; active_dock override bug fixed (cursor parked
  on a %What was being stomped by the active_dock watch)
- `req:desire` / `req:completion` cleaned up: `desire_sig` indirection gone,
  replaced by `ave/%active_what` with a direct `c.completion` ref
- `Lies_desire_completion` and `Lies_desire_land_cursor` extracted as w-methods
- `Lies_what_has_points`, `LE_what_siblings` etc. remain frail low-level logic
  — see "What cursor model" section for the intended abstraction

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

A `What/Doc` is a distinct moment from the first `What/Doc/What` below it.
The viewer sees the doc in full (or birds-eye) before the first What takes
its turn.  Multiple `What/Doc/What` siblings are successive moments within
that doc; the cursor visits each one.

`What/Doc` with no `What` children is the same — one cursor stop, all Points
(if any) shown at once.

If something sits where a Point would be but isn't a Point, it's a nested
cursor destination — the cursor visits it, then returns to the parent What
when the nested thing's own children are exhausted.

**Consequence for the cursor API:** `LiesCurse` should not be the place that
knows about Waft tree shape.  The "what is a valid cursor stop" and "what is
the next stop" logic belongs in helpers on the Waft side — ideally close to
`LE_what_*` in LiesEnd, or a `Waft_cursor_*` family on Lies.  LiesCurse
should call them abstractly:

```
H.Waft_cursor_next(w, examining)   // advance to next stop
H.Waft_cursor_first(waft)          // first stop in a Waft
```

Currently `e_Lies_cursor_next` and `e_Lies_desire_step` both inline this
logic.  They should converge on the same helper.

---

## ave signals

```
ave/%examining         — cursor state; c.w → w:Lies
  /%What_Points        — sc.src ($C → %What or %Doc), sc.src_Waft
                       — also called %active_what in some comments; pick one

ave/%active_what       — transport state for NaviCado
  c.completion → req:completion   sc.playing:0|1

ave/%active_dock       — Lang-side active doc
  sc.path, c.dock → %Dock
```

The `%What_Points` child of `%examining` may be better named `%active_what`
to match the concept.  The two are distinct: `%examining` is the cursor host,
`%active_what` is the transport signal.  Leave the rename for later when
there's a clear migration moment.

---

## Architecture (current)

```
w:Lies
  /%examining
    /%What_Points,1   sc.src / sc.src_Waft — the cursor
  /%active_what       c.completion → req:completion (sc.playing)
  /req:desire
    /req:acquire      one-shot Waft lock
    /req:completion   open-ended; sc.playing drives NaviCado 4s timer
    /req:git          < Waftlet accumulator

w:Lang
  /%Languinio
    /%LE              same-object hold on workon/{LE:1}
    /%Dock,path       same-object hold on active dock
  /req:workon         sc.following:1
    /req:awaiting / /req:maneuvre
      /req:checkout / /req:load_doc / /req:graft / /req:encode
```

---

## Open faults

```
// < e_Lies_cursor_next and e_Lies_desire_step duplicate "next candidate" logic;
//   should converge on Waft_cursor_next(w, examining) helper.
// < LiesCurse active_dock watch: when src is %What, active_dock following is
//   suppressed.  But re-opening the same doc from CM doesn't re-arm the cursor —
//   you get stranded on the What until you click away.  Probably fine for now.
// < LE_what_siblings / LE_what_depth: frail, identity-based.  Works while the
//   tree is small; a Travel-based implementation would be more robust.
// < vanish: unaccepted clone goner fires push_dirty.  Fix deferred.
// < push_dirty not wired to reqy fault system.
// < Se_o as standing watch — call-driven for now.
// < e_Lang_LE_drop demote round-trip takes a full cursor-move cycle.
// < workon.sc.following stamped but not surfaced in UI.
// < Languinio dock hold: DocMinimap still reads lang_dock from sig.c.dock
//   directly; migrate to languinio.o({dock:1})[0].
// < req:git do_fn — flush Waftlets to disk/remote.
// < What_Points rename: %examining/%What_Points could be %active_what to match
//   ave/%active_what — pick one name.
```

---

## Waft visual — glow on the active What

The Waft** list should show a glowing blur in the left margin beside the What
(or Doc) that `%What_Points.sc.src` is currently pointing at.  This is the
visual answer to "where is the cursor right now" — analogous to how a
text cursor blinks at its line.

Implementation: Waft.svelte (and DocRow.svelte for Doc-level cursoring) reads
`examining.vers` and checks `wpt.sc.src === what` / `wpt.sc.src === doc`.
The `examining` prop already flows from Liesui → Waft → DocRow for the
DocRow glow; extend it to the What header row.

CSS: a `::before` pseudo-element on `.ls-what-hdr` with `box-shadow: -2px 0
0 4px #446a` or similar.  Class `ls-what-active` toggled by the check above.

---

## Chunk 4 roadmap

```
4a  cursor_next steps %What  ✓ (but see "cursor API" above — logic is scattered)
4b  req:desire playing loop  ✓
4c  ↘ / ↓  branch + dive     — write paths exist (e_Lang_LE_add/push); needs
                               +time carry-over heuristic design
4d  ghost + rescue + ◀◀ rwnd  — after 4c
```

---

## Style notes (standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async; `i()` always inserts.
- `watch_c` handlers are `async () =>` and the flush loop awaits them.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime.
