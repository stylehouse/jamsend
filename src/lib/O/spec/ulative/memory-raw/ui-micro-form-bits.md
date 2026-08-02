---
name: ui-micro-form-bits
description: "src/lib/O/ui/micro/ holds tiny reusable form scraps (Orb, DeleteX); reuse/extend instead of re-rolling"
metadata: 
  node_type: memory
  type: project
  originSessionId: e5c6fc86-1b60-411d-ada4-3aadee781a33
---

`src/lib/O/ui/micro/` is the home for tiny reusable bits of form. Reach for these
(or add to them) instead of hand-rolling a one-off button/CSS.

- **Orb.svelte** — the small border-circle edit/crud toggle. Props `active`,
  `onclick`, `title`. Was duplicated as PeelInput's `.pi-orb` and Waft's
  `.ls-funk-orb`; both now import it.
- **DeleteX.svelte** — a delete `×` deliberately hard to hit: first click ARMS
  (swells to a red "delete?" pill), second click confirms; pointer-leave or a
  ~2.2s timeout disarms. Props `ondelete`, `title`, `glyph`. Used in PeelInput's
  irow (the old easy-to-fat-finger delete).

**Why:** the user asked for a guarded delete and a shared place for these scraps.
**How to apply:** new micro-affordances (orb, delete, future toggles/pills) go
here as self-contained `.svelte` files; consumers import from
`$lib/O/ui/micro/`. Related: [[entropyarrest-spay-design]] form UI lives in [[story-books-catalog]]'s editor machine.

Bigger sibling (not micro, lives in `ui/`): **MiniWaft.svelte** — a short bounded
Travel into a C** subtree (props `roots`, `top`, `depth`, `width`). Shows the full
text compactly; `×N` chips = next level Travelled-but-not-shown (click to
deepen/widen). A single orb on the synthetic top node pings orbs onto every node;
every orb makes that node editable (inline depeel↔peel of its sc). First consumer:
CreduFunk's CreduCoherence** journal. Reuse it for any compact openable C** view
(PereStaple's face is the pending second consumer — location TBD).
