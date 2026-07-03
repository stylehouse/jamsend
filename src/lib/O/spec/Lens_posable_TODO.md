# Lens — the posable-container vision + what remains

The ONE Lens doc.  `Lens_handover.md` was finished and folded in here 2026-07-03 (deleted) —
 its seam is long built, its bombs defused or relocated; the still-live residue is §"The %Aim
  residue" below.  The far half (the torus / Decor hemispheres) is **design, not yet cooked** —
   written down so it survives, not so it gets built next.

## The built Lens layer (orientation, not TODO)

- **The seam:** a Lens particle is `Lens:<LensKind>,of_Funkcion:<kind>`; the Funkcion offers a
   face per slot (`FunkKind.comp_<LensKind>`, kinds.ts); `LensHost` mounts them; the bag lives
    off-snap on `top_House().ave.{Lenses:1}` via `Lies_lens_bag/suggest/dismiss/toggle`
     (LiesFunk.svelte).  Identity is `(LensKind, of_Funkcion)`; re-suggest = oai-merge + bump.
- **The Brink HUD** grew out of the old Runner-panel tenant: Rundar (fleet rack), Relay (the
   server log ring — the old "%Aim server-log stream" want, done), Sound (the AC grant beg, both
    roles), Upkeep (errands) + MiniBrink collapse.  The panel local-ticker bomb is fixed (Rundar
     keeps its own `now`); Liesui's inline runphase copy is retired.
- **The layout service is BUILT** (was the long §"layout service" here): `Lies_keep_layout_host/
   _get/_set` — the one `(scope, id, key) → value` door on the Keep (LiesKeep.svelte, "layout"
    region), plus `Lies_keep_cfg_*` per-Waft.  Wired clients: Langui `scroll_line` + minimap,
     DocTing, InterestStrip, DocGhostList, Waft `minimised`.  The surviving doctrine: **opt-in
      per state** — never persist input buffers, confirm-guards, DOM refs, geometry, or live
       selection; CM selection restores via its own EditorState.  (Old Near-TODO-1 — Waft:Cluster
        layout-state — was superseded by exactly this; the Keep is the home.)
- **pinned_stable doctrine** (transport reliability lands in `p2p/pinned_stable/`, never O/*):
   Editron.md §3.

## The far vision — Lens becomes a posable container (NEEDS COOKING)

The idea: **a Lens is a pose-able UI-container**, and the whole editor floats together as a
 **two-hemisphere torus** joined by a bridge.

- **Lies hemisphere.**  `Lens:Decor` is the **back wall** the Waft gets *put into* — the
   Lies/Waft presentation stops being a bare list and becomes content mounted into a Decor Lens.
    A `Funkcion:Decoring` (itself riding `Lens:Brink`) is what places the Waft into its Decor.  The
     **Brink** is "what's shooting down" in front of that back wall.
- **Lang hemisphere.**  `Lens:Mapping` / `Lens:Interesting` are the **stem** of the torus on the
   Lang side (the minimap/Interest apparatus).
- **The bridge** is **Brink → Interest** — the two hemispheres connect there.

So the Lens-KIND vocabulary grows from {Panel, Brink, InterestSmall|Big} into a *layout grammar*:
 Decor (back wall) · Brink (foreground stream) · Mapping/Interesting (Lang stem).  `LensHost`
  already mounts `comp_<LensKind>` generically, so new kinds are mostly faces + poses, but the
   **posing/anchoring model** (how a Decor wall sizes, how Brink layers over it, how the bridge
    routes) is the unbuilt, uncooked part.  Don't build until the pose model is designed.
 The layout service's value model was kept general so poses can ride it later.

## The %Aim residue (folded from Lens_handover)

- **CreduFunk is still the duplicate journaler** (`credufunk_run` stamps `CreduCoherence`).
   Retire it → make it a *viewer* of `wormhole/Story/<Book>/Credulate/toc.snap` (Editron.md §7).
- **%Aim manifests as a Waft** (Waft:Aim) whose particles are *endpoints* the way Lies's are
   docks — a navigable toc.snap with embedded `Funkcion:Runner` per endpoint, so the fleet doc is
    editable like any Waft.  The Brink HUD covers the monitoring want today; the Waft form is what
     remains.  First slice when picked up: an `Aim` Funkcion whose face is the **overall traffic
      light** (green going-well / red failing / orange in-progress / flashing-orange still-going),
       aggregated from endpoint liveness (`Lies_channel_live` vs stale `%channel_peer` — two
        distinct signals), `run_phase` in-flight, and `%run_result` verdicts.
- **The excitement/awakeness scheme** (run_when floor + Interest-cursor excite level → lens-kind
   intensity + an MRU budget on the awake set) — designed, unbuilt, uncooked; TODO 2's
    "sufficiently excited" threshold wants it.

## Near TODO 2 — the Interest's Docs as a mini-GhostList in the Brink (+ What↔Doc tracking)

Goal (user): **any sufficiently-excited Interest (a Trail by default) shows a compact list of all
 its Docs**, sitting **above it in the Brink**, and **clicking a Doc lands you in the last What that
  had that Doc** — so flipping Docs feels like switching tabs between Whats, separated by Doc.
   (Aside already carries a GhostList of all its things; this is the same idea per excited Interest.)

Two parts:

- **2a — the mini-list.**  A compact GhostList-of-Docs scoped to one Interest's Docs (vs the full
   GhostList).  Lives in the Brink above the Interest.  Reuse the per-Interest `in_Doc` memory and
    `alpha_doc` already built ([[multidocwhat-chosen-doc]], `Lang_set_interest restores from per-
     Interest in_Doc`).  "Sufficiently excited" = an excitement threshold on the Interest (the
      excite scheme above — also uncooked).

- **2b — What↔Doc-last tracking (the prerequisite).**  Track, **per Doc, the last What that
   contained it** — "beneath the level of `Aside:Ting`."  On opening a Doc from the mini-list,
    re-seat into that last-What context so you land somewhere coherent in the Waft**, instead of the
     current "scroll up and hunt for a What."  This is a small tracking hook (stamp `doc.c.last_What`
      / a `WhatDoc` ledger when a What is viewed with a Doc) feeding 2a's navigation.
   Same family as `Interest.md`'s **"Per-(Interest, Waft) cursor-memory"** TODO (an Interest remembering
    where its cursor sat on leaving a Waft) and its smart-click "land on that Doc's What" — build them
     together; both want the rename-surviving locator caretaking that gates Interest.md's "Rejoin the
      stack frame."

## Near TODO 3 — navigation frictions (Interest/Aside/Trail)

These are in the delicate `Lang_set_interest` arbitration — the same seam `Interest.md` tracks (its
 Aside-kind/foreground election and the "Rejoin the stack frame" TODO).  Worth fixing **after** the
  Interest-Docs model (TODO 2) settles, since they're symptoms of the same seam.

- **3a — FIXED** ([[aside-stance-aware-foreground]]): the GhostList-Doc click confiscated by the
   Trail — `Lang_set_interest` is stance-aware now (aside→Interest:Aside, no duplicate Trail).
- **3b — dock→What navigation is sluggish / "taken over by the first What."**  Resolving a dock to a
   What sometimes lands on the **first** What rather than the intended one (cf the acquire fallback
    `… ?? wafts[0]` in `Lies.svelte` ~833 and the roster-epoch dance in `Lang.svelte` ~1548-1563).
- **3c — switching between Docs is unclear.**  Today you must scroll up and find a What.  TODO 2 (the
   per-Interest Doc mini-list + What↔Doc-last) is the intended cure; listed here so the symptom and
    the cure stay linked.  The Waft-tree-render half — cohering runs of sibling Whats so a Doc draws
     once and its boundaries read — is `Waft_styling_todo.md`.
