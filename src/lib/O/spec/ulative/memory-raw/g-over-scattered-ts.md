---
name: g-over-scattered-ts
description: "the human's doctrine: .g is the home for logic; a pure .ts primitive + spec + FlockCompile is a STAGED break-glass layer (no .go written), and ghost-compile is the commit. Don't scatter .ts; fold into .g, register, ghost-compile."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 50340a02-593e-4dac-9741-a6d37054aa5c
---

The human's stated working preference (2026-06-24): **don't scatter helper `.ts` files like `peeroleum_lossy.ts` — "it's got to be `.g` for the whole thing."** Logic that belongs to the machine lives in `.g` ghosts (House methods), not separate `.ts` modules imported in.

**The staged-layer model (their analogy to FlockCompile↔ghost-compile):** a pure `.ts` primitive + a headless vitest spec — and `FlockCompile` itself, which compiles in-memory and **does NOT write the `.go`** — are a *soft, non-committal staging layer*: fast, isolated, "avoid using EXCEPT when really expecting trouble." The real artifact is the `.g`; **ghost-compile is the commit** that writes the `.go` + HMRs it live so they can "immediately play with things when ready." Protocol: work in the soft layer only if a thing is genuinely tricky, then **FOLD into `.g` and ghost-compile**, deleting the `.ts`+spec.

**How to add a `.g` ghost so it actually runs:**
- register the path in **`CREDULER_GHOSTS`** (`LiesLies.svelte`) — the live acquire manifest the runner imports; AND
- add `Doc:` + `Point,method:` lines under a `What:` in the **Net/Easy Waft overlay** (`wormhole/Ghost/Net/Easy/toc.snap`) — the annotation/manifest. **Net/Easy is a PRISTINE landmark space, not a per-method index** (the human, 2026-06-25: "we really don't need most of these Easy Points if they're just to every method… what do we want to refer to in that pristine space of Easy"). Give a `What:` its Doc + only the 1–2 front-door Points worth jumping to — the Book to run, the ghost's entry method, the named concept; the compiler already indexes every symbol;
- a ghost MUST have a built gen `.go` BEFORE it's in `CREDULER_GHOSTS` — the acquire does `import('.../<gen>.go')`, so no file → the runner boot HANGS ([[g-authoring-gotchas]], [[creduler-runner-architecture]]).

**Why:** keeps the system in one medium (the `.g`/ghost machine), no parallel `.ts` shadow to drift; ghost-compile gives an immediate live-play loop. **How to apply:** when I build a pure `.ts` helper for the p2p/ghost machine, treat it as scratch — fold it into a `.g` and ghost-compile before calling it done; don't leave the `.ts`. Also: keep comments LEAN in `.g` (orientation + load-bearing gotchas + "feel of the place," not exhaustive prose). See [[g-import-ts-module]], [[peeroleum-reliability-arc]].
