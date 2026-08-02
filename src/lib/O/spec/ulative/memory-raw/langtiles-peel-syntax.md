---
name: langtiles-peel-syntax
description: "LangTiles peel values — reserved chars, loose values (dashes), and n%such→n.sc.such"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 51f86304-44ce-4ef1-9acf-fe500af86b9e
---

LangTiles `.g` peel/value syntax (grammar: `src/lib/O/lang/grammars/stho/`):

- **Reserved chars** at the data layer are only `, : =` (`peel()` in `Y.svelte.ts:660` — `,`=sep,
  `:`=string-value, `=`=number-value). LangTiles adds path `/` and **whitespace** (paths are
  whitespace-tight). Everything else is fair game in values.
- **Loose bare values**: a value may contain non-word chars like `-` (`reason:no-direct-route`) — via
  the external `PathVal` token. Word-only stays a string, numeric (`3`, `3.6`) stays a Number. For
  spaces/commas/colons in a value, **quote it** (`reason:'no-direct route'`). Keys are still
  `Name`-only (dashes in keys → quote/`{"k":..}` not yet supported).
- **`n%such` → `n.sc.such`** (the `%` scalar-child accessor, CLAUDE.md's `Text%dige`). Tight `%` only
  (no spaces): `a % b` stays modulo, `%Foo` at a group start stays PuddleSigil. Chains: `n%a%b →
  n.sc.a.sc.b`. String-safe.
- **`%` is OPTIONAL on a leading peel** — `i A:Bearing` == `i %A:Bearing`. Prefer no-`%` (user pref).
- **`H` receiver** lays a sibling actor on the House: `H i A:Bearing` → `this.i({A:"Bearing"})` (`H`
  normalises to `this`; gen has no `H` var). The receiver is now also parsed in the **assignment form**
  `let bw = bA i w:Peeroleum` (a lone bareword between `=` and the verb).
- **`const H = this` is now FABRICATED** by the compiler at every method body top (so raw-JS `H.x`,
  `H.c.y`, closures, inline `if (n===2) H.foo(w)` all resolve — never hand-write it). Parameterised by
  `RECEIVER_ALIAS = {name:'H', inject:true}` in `compile.ts`. Reserve-slot-then-resolve: injected only
  if the *compiled* body keeps a bare `H` (an stho receiver `H i …` lowers to `this`, needs none);
  skipped when `H` is a param (shadow) or already declared (no double).
- **`&name,a,b`** → `this.name(a,b)`; **`recv&name,a,b`** → `recv.name(a,b)` (tight `&`; receiver is the
  identifier just before it). `pier&do`→`pier.do()`, `req&bump`→`req.bump()`, `await pier&settle` ok.
  Spaced `a & b` stays bitwise-and (tight-vs-spaced, like `%`). `bump()` is the new C alias for
  `bump_version()` (Stuff.svelte.ts). Nested object args ok: `&send,wB,{header:{…}}`.
- **Inline IO atoms now translate inside a control body** (`if (n===4) i %reached:x` → `w.i({reached:"x"})`),
  not just at top level — `sthoParser` is threaded into method-body recursion (`inner_ctx`, compile.ts).
  Inline atoms with an EXPLICIT receiver mid-expression now work too (`if (a && !(w oa %x))`) — fixed by
  Lang_io_in_text splicing `keep_before` (not the raw prefix) + a buried-receiver case in
  Lang_io_before_split (`[^\w.$]`-bounded trailing word, so `.prop` isn't mistaken for a receiver).
- **Auto-async**: a method with a *method-level* `await` (a user `await pier&do`, or an emitted r|roai)
  but no `async` decl gets `async` prepended at compile (else it's `await` in a sync fn — invalid JS that
  `lang-compile` PASSes since it only checks translation, not JS validity — bit me once). Awaits inside a
  nested async arrow (an `oai`|`r` BLOCK do_fn) are the arrow's, not the method's, so they're EXCLUDED
  (`arrowRanges` in compile.ts) — `reqTiles`/`LakeNetherland` stay sync. Comment lines are skipped too.
- **Obtain verb family compiles**, not just `i|o`: `oa ob o1 oa1 bo boa bo1 boa1` (all share o's `(sc,q)`
  sig → single-leg `recv.verb(sc)`; drills|captures stay i|o-only). `oa %x`→`w.oa({x:1})` (presence probe).
  `drop`/`empty` are grammar tokens but still UNBUILT (C-arg|no-arg, not sc-path). The pre-filters
  (`IONESS_VERB_RE` in compile.ts) drive detection; `Lang_compile_IOness` returns the verb, `IONESS2_VERBS`
  ({r,rm,oai,roai}) route to the 2-arg emitter.
- **Captures**: `name$`=row C (auto-name), `name$var`=row→var, `name.$`/`name.$var`=value (`?.sc.name`).
  PREFER the **`$:` out-spelling**: `Pier$:pier` (row-out), `wither.$:ang` (value-out) — `$:` reads "out
  comes name", the visual mirror of `:$` value-IN (`A:$side`). `$:name` is sugar (additive, same compile;
  the `:` is a `CaptureColon` token consumed before `CaptureName`). Multi-leg → `_i_drill_caps`/`_o_drill_caps`.

Check any `.g` with `npm run lang-compile -- <file.g>` (see [[lang-compile-cli]]). Editing
`stho.grammar` makes the generated `stho.grammar.ts` stale → `resolve()` live-builds (correct, flagged
stale); regen the artifact in-app when convenient. **Editing `io_tokens.ts` needs NO regen** (the
generated parser imports it at runtime).
