# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design*; this doc
owns the *implementation slice*.

---

## State as of this session

Design problems 1–4 and 6 from last session closed.  4b (`req:desire` playing
loop + NaviCado transport bar) landed.  Languinio-as-bus wired for active dock.

### Files touched this session

- `DocMinimap.svelte` — `void LE?.vers` in rebuild `$effect` (problem 6 reactivity);
  `collect_le_membership` mirrors `Lang_point_spec` spec resolution (problem 2)
- `LiesEnd.svelte` — `LE_what_siblings` handles `%Doc` nodes (problem 4);
  `LE_what_depth` / `LE_what_parent` generalised for any node type
- `Lies.svelte` — `Waft_link_up` in `watch_c` handler (problem 1 c.up latency);
  `ave/%desire` signal enrolled at setup; `e_Lies_desire_play/pause/step` handlers;
  `req:completion` do_fn stamps `desire_sig.c.completion`
- `NaviCado.svelte` — transport bar (‖/▶, →); UI-side 4s play timer;
  reads `ave/%desire` for playing state
- `Lang.svelte` — `Lang_set_active_dock` pushes same-object dock hold into
  `%Languinio` (Languinio-as-bus first wire)

---

## Lang/LE architecture (current)

```
w:Lies
  /%examining
    /%What_Points
        sc.src      $C → %What or %Doc
        sc.src_Waft string
  /%desire             reactive signal for NaviCado transport bar
        c.desire    $C → req:desire
        c.completion $C → req:completion (sc.playing:0|1)

  /req:desire
    /req:acquire         one-shot Waft lock
    /req:completion      open-ended; sc.playing drives UI timer in NaviCado
    /req:git             < Waftlet accumulator; deferred

ave/%active_dock
  sc.path  string
  c.dock   $C → %Dock

w:Lang
  /%docks
    /%Dock,path
      /%Compile / /%Output
      /%bookmark,N
      /%LE
        /%State           sc.armed / sc.changey / sc.stale
        // %push_dirty — fault; present only when push didn't land clean
        /%Seem:origin     sc.Se / sc.C → live OC%What
        /%Seem:working    sc.Se / sc.C → clone C%What
          /%Demonstrations:working
            /%Understandable   C.c.U; unshowing/unaccepted live here

  /%Languinio
    /%Change              three-leg display strip
    /%LE                  same-object hold on workon/{LE:1}
    /%Dock,path           same-object hold on active dock ← NEW

  /req:workon             sc.following:1 (default — tracks group cursor)
    /req:awaiting         one-shot; installs Languinio/%LE
    /req:maneuvre         reset on each cursor move
      /req:checkout / /req:load_doc / /req:graft / /req:encode

ave/%lang_dock,path       sc.text / sc.text_dige / sc.disk_dige
```

---

## Open faults

```
// < vanish: unaccepted clone lands as goner on post-push awareness pull,
//   firing push_dirty.  Fix: LE_push stamps bD/was_disincluded:1;
//   resolved_fn suppresses that goner.  Needed before unaccepted is usable.
// < push_dirty not yet wired to a req fault particle in the reqy system.
// < Se_o as a standing watch (fire on every source mutation) — call-driven for now.
// < e_Lang_LE_drop demote vs Lies-side accepted: takes a full cursor-move cycle
//   to reconcile.  Faster path: LE_push fires e_Lies_What_Point_changed.
// < workon.sc.following = 1 stamped but not read; thought-balloon needs a
//   UI hook in NaviCado breadcrumb when following:0.
// < Languinio dock hold: DocMinimap still reads lang_dock from ave/{active_dock:1}.c.dock
//   directly; migrate to languinio.o({dock:1})[0] to complete the bus wire.
```

---

## Chunk 4 — What-level transport and navigation

### 4a — cursor_next steps %What ✓ done
### Chunk U — Understanding ✓ done + grafted
### 4b — `req:desire` playing loop ✓ done

Transport bar renders in NaviCado when `req:desire` is active.  Auto-advance
fires every 4s when playing; pauses at Waft end.

### 4c — `↘` / `↓` branch and dive gestures

```
↘   sibling +time     create a new %What sibling beside the current one
↓   child +time       dive: create a new %What inside the current one
```

Both gestures use `e_Lang_LE_add` / `LE_push` now that the write paths exist.
Carry-over heuristic (accepted+showing → forward, recent → move, rest → ghost)
needs `+time` semantics nailed down first.

```
// < unaccepted carry-forward reads clone.c.U?.sc.unaccepted at branch time
// < vanish fix must land before unaccepted is usable here
```

### 4d — ghost + rescue window + `◀◀ rwnd`

Ghost decorations and `rwnd` (step backward, read-only).  Depends on 4c.

---

## Architecture: Languinio as display bus — remaining wires

1. DocMinimap `lang_dock` source — migrate from `sig.c.dock` to
   `languinio.o({dock:1})[0]` now that `Lang_set_active_dock` inserts the hold.
2. `/%Languinio/{cursor:1}` — What label, depth, sibling count for NaviCado,
   so NaviCado doesn't need to call `LE_what_*` helpers directly.

---

## Navigation gestures summary

```
→   continue     step to next %What — e_Lies_cursor_next ✓
↑←→  NaviCado   up/prev/next via c.up chain — ✓
‖/▶  play/pause  req:desire transport — ✓ 4b
→    step        manual advance — ✓ 4b
↘   sibling +time   e_Lies_branch_What — 4c
↓   child +time     e_Lies_dive_What   — 4c
◀◀  rwnd         reverse step        — 4d
```

---

## Style notes (standing)

- `// < …` marks a *lack* of development.
- `%like,this` naming a lone C object; `/%like,this/written:is` for structures.
- `oai` sync, `roai` async.
- `i()` always inserts — never deduplicates by identity.
- `watch_c` handlers are `async () =>` and the flush loop awaits each one.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime.
