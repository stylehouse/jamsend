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

---

## Open faults

```
// < clicking a Waft Doc repeatedly (~7x) loses the What glow until re-clicked.
//   Likely the active_dock watch firing Lies_set_examining with a %Doc src,
//   overwriting the %What cursor — the cur_is_what guard should catch it but
//   something's slipping through on rapid re-fires.
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
