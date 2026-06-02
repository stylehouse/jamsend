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

Currently `e_Lies_cursor_next` and `e_Lies_desire_step` both inline this
logic.  They should converge on the same helper.

---

## ave signals

```
ave/%examining         — cursor state; c.w → w:Lies
  /%Spotlight,1        — sc.src ($C → %What or %Doc), sc.src_Waft
                         written only via Lies_i_Spotlight

ave/%active_what       — transport state for NaviCado
  c.completion → req:completion   sc.playing:0|1

ave/%active_dock       — Lang-side active doc
  sc.path, c.dock → %Dock
```

---

## Architecture (current)

```
w:Lies
  /%examining
    /%Spotlight,1      sc.src ($C → %What or %Doc), sc.src_Waft
  /%active_what        c.completion → req:completion (sc.playing)
  /req:desire
    /req:acquire       one-shot Waft lock
    /req:completion    open-ended; sc.playing drives NaviCado 4s timer
    /req:git           < Waftlet accumulator

w:Lang
  /%Languinio
    /%LE               same-object hold on workon/{LE:1}
    /%Dock,path        same-object hold on active dock
  /req:workon          sc.following:1
    /req:awaiting,finished
    /req:maneuvre      reset on each cursor move
      /req:checkout,maz:3   LE_arm + LE_pull; installs spinner:stale if needed
      /req:load_doc,maz:2   re-fires Lies_roai_Open_req until dock appears
      /req:graft,maz:1      Lang_graft_points_once
      /req:encode,maz:0     LE_encode_compare; sets %State.changey
```

# subproject: Spotlight-Interest

afaik this is nearly all done, final bringing-it-all-together,
probably chasing tails until this whole doc is also nearly done.

this is a big chunk of another document now:


## 5. Sequencing against Chunk 4c

Before 4c.  4c's carry-over reads `clone.c.U?.sc.unaccepted` and stamps
`class:'ghost'` — U-sphere reads that only *mean* something once the graft (§3c)
and `req:Showing` (§3g) honour the U sphere.

```
4b.5  Spotlight↔Interest
        3a crux + src_Waft drop + waft_key_of
        3b %Interest                  3c graft reads clones      ← the unlock
        3d dissolve active_what/active_dock
        3e req:wants intake           3f desire thins, timemachine on cursor
        3g req:Showing                3h req:push                3i req:Furnishing RPC
        3j remove breadcrumb
4c    ↘ / ↓ branch + dive            class:'ghost' now renders (via §3c + §3g)
```

§3c + §3g are the keystone pair: clone-sourced graft + a Showing pass turn
`unshowing`/`unaccepted`/`class` from write-only flags into visible behaviour.

---

## 6. Open faults (carried + updated)

```
// < clone.c.waft is one scalar on the clone root; LE.sc.target.c.waft is the
//   fallback for any clone landing unstamped.
// < LE_what_* stay identity-based and frail; Travel-based when the tree grows.
// < graft fallback to src_C in the pre-pull window: one stale tick where
//   unaccepted/unshowing Points still paint.
// < req:wants never prunes; history grows unbounded until a sweep exists.
// < the wants resolver is newest-wins; a Lang-obsession want crossing in has no
//   weighing rule yet.
// < req:timemachine is a reqy particle under %examining (an ave signal);
//   tolerated — precedent: %Spotlight child + c.w back-ref.
// < req:Showing assumes pmirror.c.src_clone is stamped at graft time; wire it.
// < maz:0 in the existing maneuvre (req:encode) is out-of-spec; fold into graft
//   tail and confirm maz bottoms at 1.
// < req:push/%dirty needs surfacing in the reqy fault UI.
// < vanish: unaccepted clone goner fires push_dirty on the verify re-pull; §3c
//   makes unaccepted-invisible true on screen — the visible companion to the
//   pending suppress-the-goner fix (bD/was_disincluded).
// < clicking a Waft Doc ~7x loses the What glow; killing ave/%active_dock removes
//   one of the two ping-ponging signals — re-test after §3d.
```

---

## Style notes (inherited, standing)

- `// < …` marks a lack of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async; `i()` always inserts.
- Cross-domain refs are scalar `$C` pointers in `c.*`; no domain writes another
  domain's `sc`.  `%Interest.src`, `%Interest.c.LE`, `clone.c.waft`,
  `pmirror.c.src_clone` are same-object holds.
- `i_elvis_req` carries the req particle itself; `finish(reply)` pings `reqturn:1`.
- `i_req_ttlilt` holds the snap open (defers finalize); it does not poke a think.
- Read children-dependent derives with `.ob()`; chain on `vers`, not
  `$derived.by(void …)`.



# And now...

---

## Open faults

```
// < second Doc (Ghost/Peeroleum.g) doesn't load into CM — empty editor, no
//   spinner.  req:load_doc polls find the dock but Languish never completes for
//   that path.  The editorBegins storm (7 pairs in the snap) suggests the
//   active_dock watch is ping-ponging between the two docs on each tick.
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
// < stale spinner: req:encode should also clear spinner:stale after a clean
//   encode-compare, in case stale lingers past checkout.
```

---

## Chunk 4 roadmap

```
4a  cursor_next steps %What  ✓ (logic still scattered — Waft_cursor_next pending)

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
