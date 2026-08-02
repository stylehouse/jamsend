---
name: dsl-over-raw-js
description: In .g ghosts prefer the LangTiles DSL over raw-JS passthrough; extend the language to cover a seam
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7cdafa0d-e4d3-404c-a9b1-adecef5f6735
---

When writing `.g` ghosts (the p2p spine, wranglers), **prefer the LangTiles DSL over raw-JS
passthrough**. When a construct only works as raw JS, reach for a small LangTiles extension (heading L
in [[peeroleum-bootstrap]]) before settling for raw JS.

**Why:** the human is deliberately building this language; "use the language I designed more" is a
repeated, explicit ask. Each seam closed makes more of the spine live in `.g`. Style prefs surfaced
across a session: `%` optional on peels (write `i A:Bearing`), `&name,a,b` calls, `$` row-capture and
multi-assign two-legs, `H` receiver for actor-laying — all in [[langtiles-peel-syntax]].

**How to apply:** write the DSL form first; if it miscompiles, check whether a one-line grammar/translator
fix (`io_tokens.ts` / `compile.ts`) closes the seam (`npm run lang-compile -- <file>` to check). Genuine
seams that stay raw: object/`.c` payloads and closures (e.g. a mock-port's `send(){…}` capturing `H`).
`Lake_sides_up` in `Ghost/Story/Peregrination.g` is the worked example.
