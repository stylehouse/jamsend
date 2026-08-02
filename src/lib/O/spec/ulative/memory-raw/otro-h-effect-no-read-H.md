---
name: otro-h-effect-no-read-h
description: "Otro's H-construction $effect must never read the $state H synchronously (it reassigns H) — self-retriggers → infinite new House() OOM"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 93f04598-315f-4a15-920f-30b1f2bbc861
---

In `src/lib/O/Otro.svelte` the H:Mundo construction `$effect` does `H = new House(...)` — it WRITES the `$state H`. Never read `H` synchronously inside that effect (e.g. `H.c.x = …`, `H.foo()`): set values on a LOCAL `const h = new House(...)` first, then `H = h`. Compute URL/static bits outside the effect entirely.

**Why:** Svelte 5 re-runs an `$effect` whenever a `$state` it *reads* changes. Reading `H` inside the effect makes the effect depend on `H`, which the effect also reassigns (`H = new House()`) → write → "H changed" → re-run → `new House()` again → infinite loop, allocating a fresh House (+ its readiness `$effect` + a full ghost re-mount) on every tick. The tab OOMs to multi-GB in ~20s. Symptoms are misleading: looks like a black page, a CPU spin, or `SIGILL` on Brave (stricter V8) — and it fires on EVERY load, independent of any feature. A deferred read (inside the `setTimeout(() => houses = [H])`) is fine — timeout callbacks don't track.

**How to apply:** Adding boot wiring to Otro's construction effect? Touch only the local `h`, assign `H = h` last, and keep any `H.*` reads out of the synchronous effect body. This bit during the ?toplevel work (`H.c.toplevel = …`); the corrected version computes `toplevel` outside the effect and sets `h.c.toplevel`.
