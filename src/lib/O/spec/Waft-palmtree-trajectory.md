# Waft palmtree trajectory — reqy migration + What transport

`Waft_spec.md` owns the design.  This doc owns the implementation slice.

---

## State as of this session

- `%What_Points` → `%Spotlight` rename complete (LiesCurse, LangGraft, Lies,
  DocMinimap).  `Lies_i_What_Points` → `Lies_i_Spotlight`.
  Snap now reads `ave/%examining/%Spotlight,src=%What:choice`.
- Waft `ls-what-active` glow landed: `::before` beam on `.ls-what-hdr` when
  `%Spotlight.sc.src === what`.  `examining` prop already flowed; derived
  per-`#each` in the What loop.
- `%State,stale` false-positive fixed in `LiesEnd.LE_pull`: first pull after
  `LE_arm` has an empty D sphere — all Points arrive as neus by definition,
  not remote drift.  `was_fresh` guard skips stale on the arm pull.
- `req:load_doc` `reqonce('fired')` gate removed: it was preventing retries
  after ttlilt expiry.  `Lies_roai_Open` is idempotent — re-firing safe.
  Poll interval tightened 5s → 0.5s.
- Stale spinner wired: `%State.stale` after `LE_pull` installs
  `spinner:'stale'` in `%Languinio`; DocMinimap shows amber `↻` at 0.8s.

### Still broken: Waft UI doc navigation

Clicking a `%What` whose doc differs from the current active doc navigates
the cursor (Spotlight moves, glow follows) but the CM doesn't switch.
Symptom: `dock:Ghost/Peeroleum.g` appears in the snap, `editorBegins` fires,
but `req:load_doc` stays stuck with `waiting:dock,timed_out`.

Diagnosis: `req_text_loaded` mints the dock inside `req:Languish`, which is
driven by `rq.do()` in the Lang tick.  `req:load_doc` polls `docks.o({dock:path})`.
Both should be in the same tick pass — Languish is older so runs first.
The dock should be present when `req:load_doc` re-enters.  Not confirmed why
it isn't; needs a fresh console trace with the `reqonce` fix applied.

Suspects in order:
1. `Lang_set_active_dock` in `req_text_loaded` fires unconditionally and
   triggers the `active_dock` watch in LiesCurse.  The `cur_is_what` guard
   should suppress the re-examine, but confirm it holds after the fix.
2. Timing: `Lang_open_dock` elvis from Lies may arrive after `req:load_doc`
   ttlilt fires; next re-entry (0.5s) should find the dock.  May just need
   a fresh trace to confirm the retry actually lands.
3. `req_text_loaded` `reqonce('opening')` is per-req lifetime.  If
   `e_Lang_open_dock` fires for an already-loaded path and the Languish is
   dropped+reminted, `opening` starts fresh — dock should be minted again.

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
// < Waft UI doc navigation stuck: clicking %What with different doc doesn't
//   switch CM.  req:load_doc fires, dock is minted, but poll misses it.
//   See "Still broken" section above.  Needs fresh trace with reqonce fix.
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
