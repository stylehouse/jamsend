---
name: g-import-ts-module
description: "a .g ghost CAN import a real .ts module — via a top-level IMPORT() magic pseudo-method whose body is emitted verbatim into the gen .go module header (in scope for all eatfunc methods); RENDER() is the tail twin for <Child {H}/>"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 50340a02-593e-4dac-9741-a6d37054aa5c
---

A `.g` is NOT limited to inline raw JS for things the DSL can't say. A top-level **`IMPORT()`** pseudo-method (capitalized, body indented under it) emits its body **verbatim into the generated `.go` module header** — above `let { H } = $props()`, so the imported bindings are in scope for every eatfunc method. **`RENDER()`** is the tail twin: its body becomes Svelte markup below `</script>` (e.g. `<Child {H} />`, how a `.g` names child-ghost components instead of a hand-kept include manifest). Both are "magic" — diverted OUT of the `H.eatfunc({…})` object, no stho translation, no `const H = this`, no `{`/`},` wrapper; **top-level only** (a nested `IMPORT()`/`RENDER()` falls through as a call).

```
IMPORT()
    import { inseq_new, inseq_admit } from "$lib/O/peeroleum_inseq"
```

Then `inseq_admit(...)` is a bare call in any method body — passes through the translator as raw JS, exactly like `String(...)`/`Object.assign(...)`/`crypto.subtle…` already do.

**This is a CAPABILITY, not the default.** The human's doctrine ([[g-over-scattered-ts]]) is to FOLD logic into `.g` as House methods, NOT keep a separate `.ts` and `IMPORT()` it — don't scatter `.ts` files. So `IMPORT()` is for genuine external deps a `.g` can't restate (`cluster_trust` crypto, a `.go` child component — LakeTiles.g's canon: `import Peeroleum from "$lib/gen/N/Peeroleum.go"` + `import {…} from "$lib/p2p/cluster_trust"`), not for moving your own primitive's logic. (The Peeroleum reliability primitives were briefly `IMPORT()`-ed, then folded into `Ghost/N/Reliable.g`/`Lossy.g` methods.) Mechanism: compile.ts §"IMPORT / RENDER — the two magic pseudo-methods" (~L837) + `Lang_split_compiled`/`Lang_compile_render_module`. Note `compile.ts` has UTF-8 em-dashes → grep it with `-a` ([[grep-binary-spec-docs]]).
