# Snappy_todo.md — the interface feels slow; it has drifted from Vyto; it wants a simple cell-based rebuild

A **capture doc** (the Atheory pattern — an itch given an address). Owner, 2026-08-29, live-using the
 device-link flow: *"crikey, this feels like about the worst interface I've ever played with… it's so slow
  to change cells and the `copy link` thing is unclickable for a while… it's very much not Vyto anymore,
   this could be rebuilt nice and simply huh? some cell-based simplicity to get us started on cell-based
    complexity."*

## 0. What this is about

The authored machine on top of the app (the test/story runner, the Cyto view, the compile pipeline, and
 now the Link ceremony) has grown a **cell UI that feels sluggish and heavy** — the opposite of what the
  bet promises (legible living matter you can see and rewrite *while it runs*). Two concrete tells the
   owner hit just by trying to USE it:

- **Cells are slow to change.** Switching the focused cell (Radio ↔ Door ↔ Link …) has visible lag — the
   commission/fold path is doing too much per switch, or re-deriving/re-rendering more than a switch needs.
- **`copy link` is unclickable for a while.** A control renders but isn't live yet — the button exists
   before the state/handler behind it is ready, so an early tap does nothing. (Same shape as the historical
    "Join button doesn't vanish" and "no feedback, invited a second tap" bugs: the UI shows an action before
     the machine can honour it.) A control must not appear enabled until it will actually work.

The owner's read: **it's "not Vyto anymore".** `Vytui.svelte` (the Vyto renderer) was the clean, simple
 visual core; the cell layer has accreted weight and lost that snap. The appetite is explicit — **rebuild
  it nice and simply: "cell-based simplicity to get us started on cell-based complexity"** — i.e. a small,
   fast, obviously-correct cell primitive that the richer behaviours compose onto, rather than more branches
    bolted to the current one.

## Where the slowness likely lives (to measure, not assume)

Candidates worth instrumenting before any rewrite (measure first — a rebuild justified by a guess is a trap):
- **The commission/fold path** (`Sounditron_commission`, `Lang_apply_openness`, the glass cell switch) —
   how much runs per focus change; is it re-commissioning worlds or re-deriving whole subtrees per switch?
- **`H.version`-driven `$effect` fan-out** — many cells `void H?.version` and recompute on every bump; a
   coarse global version bump on a hot path (pulses every ~5s, frame pumps, the new 3s ferry ask) can storm
    re-renders across every mounted cell. Snappiness may be as much about *what re-runs on a bump* as layout.
- **Cyto / Matstyle** redraws piggybacking on the same version.
- **Controls gated on async state** rendering enabled-but-dead (`copy link`, the old Join button): the fix
   is a `ready` gate per control, not a rebuild — cheap win, do it regardless.

## The bigger move (owner's appetite): a simple cell primitive

"Cell-based simplicity to get us started on cell-based complexity" reads as: define the **minimal cell**
 (a focused/unfocused box that renders one particle-view and switches instantly) as a clean, fast core —
  the way `Vytui` was clean — and let Radio/Door/Link/Heist be *thin renderers* over it, not bespoke heavy
   faces. The complexity (the ceremonies, the graph, the compile) then composes ONTO the simple cell rather
    than being woven THROUGH it. This is the same "faces become renderers of a decision" idea the
     `Focus_todo` §3 authority proposes for the fullscreen layer — the belly-cell twin of it.

## Not yet (design owed)

- **Measure** the cell-switch cost and the per-bump re-render fan-out before committing to a rebuild.
- The **cheap wins now** (do without a rebuild): a `ready` gate so `copy link`/action buttons can't be
   tapped before their handler is live; a snappier fold/commission; scope `$effect`s so a hot version bump
    doesn't re-run every cell.
- What the **minimal cell primitive** is, exactly, and how Radio/Door/Link re-express as renderers of it.
- The **boot splash** (see `Focus_todo`, and the sibling job landing now) covers the *perceived* boot slowness;
   this doc is about the *actual* in-app cell latency, a different axis. Keep them distinct.

## Neighbours

- **`Vytui.svelte`** — the Vyto renderer the owner wants to get back to the spirit of.
- **`Focus_todo.md`** — §3 the fullscreen focus authority (faces as renderers of a decision); the boot splash.
- **`Cellsizing_todo.md` / `Cstructures_todo.md` / `Composition_todo.md`** — prior cell/Vyto design docs to
   mine before proposing a new primitive (don't reinvent what these already settled).
