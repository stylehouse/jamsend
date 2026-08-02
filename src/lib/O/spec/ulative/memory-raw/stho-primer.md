---
name: stho-primer
description: prose primer for the stho/.g tile language (was example-only via LakeTiles.g)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 0a794ed3-a483-4570-aaa9-cfbe4b0a42c7
---

`src/lib/O/spec/stho_primer.md` is the prose orientation for the **stho / `.g`** tile
language — written because the canon was example-only (`Ghost/test/Story/Lake/LakeTiles.g`)
with rules scattered across handover heading L, the compiler, and memories.

Covers: method shape, the IO verb table (`i`/`o`/`oa`/`oai`/`doai`/`r`/`rm`/`&`/`H i`),
peels & paths, captures (`$`/`:$`/`.$`/`.$:`), `%req`+`doai` blocks, how a `.g` goes live
(compile→gen→Pantheate→Otro `eatfunc`; runner acquires via `Creduler_ensure` +
`CREDULER_GHOSTS` in `LiesLies.svelte`), and the **"language is still soft"** doctrine —
the open heading-L gaps as candidate extensions + how to change it (`io_tokens.ts`,
`stho.grammar`+regen, `lang/compile.ts`, verify with `npm run lang-compile`).

Builds on [[langtiles-peel-syntax]], [[dsl-over-raw-js]], [[lang-compile-cli]]. The worked
canon stays `LakeTiles.g`; this is the map to it.
