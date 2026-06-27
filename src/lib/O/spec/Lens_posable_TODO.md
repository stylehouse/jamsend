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

## Near TODO 1 — SUPERSEDED by the Keep + a layout service

*(Original ask: `Waft:Cluster` holds basic layout-state, starting with which Wafts are open/closed,
 persisted across reload. The `dontSnap` wrinkle — and the proposed "split the cluster Waft into
  snapped-Layout + dontSnap-Aim" — is now **moot**: `Waft:Keep` is a real snapped, durable home of
   its own (`Cluster_design.md`), so layout-state lives in the Keep, not a split Cluster. The
    open/closed set is already the Keep's `WaftTimes` ledger — add an `open`/`minimised` flag.)*

## The layout service — bridge tiny UIs up to their Lens, backed by the Keep

**The pattern that wants extracting.** Tiny UIs and Lens panels each hold ephemeral local `$state`
 for their own layout — and a few already **hand-roll** persistence into `House.stashed`, scattered
  and ad-hoc:
- already-persisted (the proof the need is real): `Storui` → `stashed['Storui:'+book]`
   (`open_at/sticky_mode/expanded`), `Cyto` → `stashed.Cyto_layout_name`, `Otro` → `stashed.showC`.
- still LOST on reload: `Lens.svelte` Brink `jumped`/`lefted` (the corner pose), `Waft.svelte`
   `minimised`/`capped`/`sidebyside`, `Langui` `minimap_open`/`expanded`, `DocTing` `open`/`sort`,
    `MiniWaft` `orbed`, `InterestStrip` `show_cold`.

A **layout service** is the one bridge: a `(scope, key) → get/set` backed by the Keep that any tiny
 UI binds its local state to, instead of a bare `$state(false)` or a hand-rolled `stashed[...]`. The
  Lens stays a **hole** (ephemeral, `ave`, off-snap — `Lies_lens_bag`); durability lives in the Keep,
   projected into the live Lens at hoist and written back on a user gesture. This is the same doctrine
    as `Cluster_design.md` §3 ("a Lens is a hole; durability lives in the Funkcion") — here the
     durable home is the Keep, and the **Keep's own `Funkcion` (its agency) is the natural service
      host**: at hoist it reads layout from the Keep → suggests the Lens with it; on toggle it writes
       back + re-suggests.

**Three scopes, mapped onto the Keep:**
- **per-Waft** → the Keep's `WaftTimes,of_Waft:<path>` (minimised · capped · sidebyside · the dock's
   Vexpandy · scroll · in_Doc). *This is "the layout status of each %Waft."*
- **per-Lens** → keyed by the Lens identity `(LensKind, of_Funkcion)` — the Brink's `jumped`/`lefted`
   corner, a Panel's `altitude`/open. A `Keep/Layout,of_Lens:<id>` section beside the WaftTimes.
- **global chrome** → not tied to a Waft or Lens (`Langui minimap_open`, `DocTing sort`, `Cyto
   layout_name`). The Keep's own top-level layout, or plain `mem()`/`stashed` — the client picks.

**Gotchas to honour (caught while reading):**
- **Don't persist the transient.** Input buffers (`new_waft_path`, `peel_text`, `draft_*`),
   confirm-guards (`reset_confirm`, `confirming`), one-shot init guards (`setup_done`, `stash_loaded`),
    DOM refs, measured geometry (`anchor`, `beam`), and live selection/telemetry (`sel_from`,
     `status`) must STAY ephemeral. The service is **opt-in per state**, never blanket.
- **CodeMirror selection** restores via CM's own EditorState — don't duplicate it in the Keep.
- **ave (off-snap) ↔ Keep (snap) loop.** A write lands in the Keep (durable, pumped) AND must refresh
   the ave Lens (live). Coalesce / write-only-on-user-change (like `Lies_keep_push_cursor`) so
    Keep→re-suggest→ave-bump→re-render doesn't feed back into a write.
- **Snap churn.** Layout gestures are frequent; the 800ms `Lies_waft_save` throttle absorbs most, but
   keep only durable-worthy layout in the service (not fidgety affordances).
- **Identity / rename.** per-Waft keys on `waft.sc.Waft`; the rename-surviving locator caretaking is
   the same the cursor-resume wants — share it.
- **Far-vision headroom.** The posable-torus (Decor/Brink poses, below) would ride this same service;
   keep the value model general (not just booleans) so poses fit later — but don't build for it yet.

**Boot/restore (the open-set half).** Wafts live as `Waft:1` on w:Lies (`active`/`boring`), and the
 boot acquire (`Lies.svelte` ~830) now reopens the Keep's ledger — so "reopen the remembered set" is
  the Keep's `Lies_keep_reopen`, no longer unmapped. Adding per-Waft `open`/`minimised` to the
   WaftTimes + reading it on reopen completes the original Near-TODO-1.

**DEFERRED (user): the Vexpandy client.** Build the service + Keep backing first; wire the actual
 Vexpandy/minimise/Brink-pose clients onto it **once the service shape is seen** working. This note is
  the design caught from reading Lens; the client wiring waits.

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
