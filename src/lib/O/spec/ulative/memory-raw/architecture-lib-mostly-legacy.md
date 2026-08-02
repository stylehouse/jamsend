---
name: architecture-lib-mostly-legacy
description: src/lib/mostly/* (Modus/Modusmem etc.) is LEGACY and out of bounds for the futuristic direction; O/Otro is the toplevel and O/ui is the futuristic home for new display work
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 65e20774-d6b8-435a-a4a1-7d69fb977e72
---

`src/lib/mostly/*` (Modus, Modusmem, Selection/Travel, Structure, …) is **legacy / out of bounds** for the current "futuristic" direction — do NOT edit it or build new features that modify it.

**Why:** the user halted a mid-task edit to `lib/mostly/Modus.svelte.ts` with "lib/mostly is out of bounds and not included in the current futuristic direction. see O/Otro for the toplevel." It's foundational old-gen plumbing; the modern app is growing elsewhere.

**How to apply:**
- The toplevel composition root is `src/lib/O/Otro.svelte` — it boots H:Mundo and renders each House's UIs as `<svelte:component this={uiC.sc.component} H={house}/>` (a particle carrying a component), plus `<Lens>` and `<Ghost>`. Orient new UI/display work around this idiom.
- New display/UI components belong under `src/lib/O/ui/` (the futuristic home — e.g. a future `O/ui/Stu/` next-level Stuffing family), not `data/` or `lib/mostly/`.
- If a legacy `lib/mostly` type lacks something you need (e.g. Modusmem has no `.path`), work around it from the in-bounds side (read its `.keys` etc.) rather than editing it — that's how [[cyto-node-stuffings]] keyed Stuffing registration by `mem.keys.join('/')`.
- `data/` (Stuff/Stuffing) is reusable but is older-gen; reuse-in-place is fine, but new families grow in `O/ui/`.
