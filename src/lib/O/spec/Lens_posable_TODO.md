# Lens as a posable UI-container — the torus vision + the near TODOs

Captured at a resting point from a design stream.  The far half (the torus / Decor hemispheres)
 is **design, not yet cooked** — written down so it survives, not so it gets built next.  The near
  half (Waft:Cluster layout-state, the Interest-Docs mini-list, three nav frictions) is concrete and
   anchored.  Companion to `Lens_handover.md` (the built Lens/%Aim seam) and `Upkeep` work
    ([[upkeep-errand-brink]]).

## DONE this pass

- **Brink is sticky, not absolute** (`ui/Lens.svelte`).  `.lens-brink` was `position:absolute` at the
   bottom of `.ls-ui`, so it scrolled out of view with a long waft list.  Now `position:sticky`
    (bottom at rest / top when Vexpandy-jumped), in normal flow, right-hugged via `margin-left:auto`
     on a `fit-content` width — the same trick `.ls-nokey` uses.  Always visible while any part of a
      Liesui is.

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

## Near TODO 1 — Waft:Cluster holds layout-state: persist Waft open|closed

Goal (user): `Waft:Cluster` carries a **basic layout-state**, starting with **which Wafts are
 open vs closed**, persisted across reload.

**The wrinkle (decide first):** `Waft:Cluster,Aim` is `dontSnap` (the endpoint layer — Runner/Relay/
 Errands must stay off the snap).  Layout-state needs the opposite: it must **persist**.  A snapped
  child under a dontSnap parent does NOT snap, so the layout-state can't live *under* the Aim Waft.
   Options:
  - **(A, recommended)** Split the cluster Waft: `Waft:Cluster` snapped, with a `dontSnap`-tagged
     `Aim` sub-section (endpoints) and a snapped `Layout` sub-section (open/closed).  `Lies_aim_setup`
      stops stamping `dontSnap` on the whole Waft and moves it onto the Aim child.
  - **(B)** A separate snapped particle (e.g. `Layout:1` on w:Lies) unrelated to Waft:Cluster — but
     the user explicitly wants Waft:Cluster to *be* the layout home, so (A) honours that.

**Shape:** record open Waft identity by name/key (`waft.sc.Waft`), plus `active`.  Wafts already live
 as `Waft:1` particles on w:Lies with `active`/`boring` flags (Liesui `all_wafts`), but there is **no
  LiesPersist / restore-the-open-set on boot** — the boot acquire path (`Lies.svelte` ~825) picks a
   single Waft to focus (`active ?? current ?? first`), it does not reopen a remembered set.  So this
    is two pieces: **(1)** write the open/closed set into the Layout particle on open/close/active-
     change; **(2)** on boot, reopen that set (drive the Waft-acquire path from the Layout list, not
      just focus one).  Piece (2) needs the acquire/open model mapped first — that is the real work.

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
      run_when/excite scheme noted in `Lens_handover.md` — also uncooked).

- **2b — What↔Doc-last tracking (the prerequisite).**  Track, **per Doc, the last What that
   contained it** — "beneath the level of `Aside:Ting`."  On opening a Doc from the mini-list,
    re-seat into that last-What context so you land somewhere coherent in the Waft**, instead of the
     current "scroll up and hunt for a What."  This is a small tracking hook (stamp `doc.c.last_What`
      / a `WhatDoc` ledger when a What is viewed with a Doc) feeding 2a's navigation.
   Same family as `Interest.md`'s **"Per-(Interest, Waft) cursor-memory"** TODO (an Interest remembering
    where its cursor sat on leaving a Waft) and its smart-click "land on that Doc's What" — build them
     together; both want the rename-surviving locator caretaking that gates Interest.md's "Rejoin the
      stack frame."

## Near TODO 3 — three navigation frictions (Interest/Aside/Trail)

These are in the delicate `Lang_set_interest` arbitration — the same seam `Interest.md` tracks (its
 Aside-kind/foreground election and the "Rejoin the stack frame" TODO).  Worth fixing **after** the
  Interest-Docs model (TODO 2) settles, since they're symptoms of the same seam.

- **3a — GhostList-Doc click is confiscated by the Trail.**  Clicking a Doc in the GhostList opens
   it for a moment **as an Aside**, then `Interest,active` is **snatched back by the Trail**.  Likely
    the eager-ActiveInterest arbitration: `Lang.svelte` ~754-778 — a giver **Trail foregrounds by
     real checkout and sets `%ActiveInterest` eagerly**, while a **Light kind (GhostList)** Aside does
      not, so the next re-checkout re-asserts the Trail over the just-opened Aside.  Fix = let a
       deliberate Doc-open hold `active` (stance-aware, cf [[aside-stance-aware-foreground]]) instead
        of yielding to the eager Trail re-checkout.
- **3b — dock→What navigation is sluggish / "taken over by the first What."**  Resolving a dock to a
   What sometimes lands on the **first** What rather than the intended one (cf the acquire fallback
    `… ?? wafts[0]` in `Lies.svelte` ~833 and the roster-epoch dance in `Lang.svelte` ~1548-1563).
- **3c — switching between Docs is unclear.**  Today you must scroll up and find a What.  TODO 2 (the
   per-Interest Doc mini-list + What↔Doc-last) is the intended cure; listed here so the symptom and
    the cure stay linked.  The Waft-tree-render half — cohering runs of sibling Whats so a Doc draws
     once and its boundaries read — is `Waft_styling_todo.md`.
