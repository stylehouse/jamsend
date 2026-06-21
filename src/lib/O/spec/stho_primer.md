# stho / `.g` — a primer

The tile language the machine is increasingly written in. A `.g` ghost file compiles
to a `gen/**.go` (a Svelte component whose `eatfunc` deposits the ghost's methods +
`Ghostmeta_<name>()` onto `H`); the methods then exist on the House. **stho** is the
language; **LangTiles** is its tile set. This is the orientation; the worked canon is
`Ghost/test/Story/Lake/LakeTiles.g` (read it — every form below is exercised there).

- **Compiler:** `src/lib/O/lang/compile.ts` (`LANG_COMPILE`, the pure translator) +
   `src/lib/O/LangCompiling.svelte` (orchestration). Grammar: `stho.grammar` (→ the
    generated `stho.grammar.ts` artifact) + `io_tokens.ts` (the value/capture tokens).
- **Self-check any `.g`:** `npm run lang-compile -- <file.g>` (prints the gen module or
   the first compile error; `--write` writes the real `.go`). Use it on every `.g` edit.
- **How a `.g` goes live:** compile → `gen/**.go` → Pantheate `import()` → Otro mount →
   `eatfunc` runs (`onMount`) → methods on `H`. A runner **acquires** its spine via
    `Creduler_ensure(w)` (gated by `%Creduler_pending`), which loads every ghost in the
     `CREDULER_GHOSTS` manifest (`LiesLies.svelte`). The `.g` IS the Book.

## Method shape

```
Name(A, w):                  // a method on H; pythonic indentation is the body
    w i %see:'hello'
async Other(A, w):           // `async` is hand-written (no auto-async yet — see gaps)
    await pier&settle
```
`w` is the default IO receiver. `H` resolves to `this` (the compiler injects
`const H = this` at the top of any body that keeps a bare `H`, unless `H` is a param).

## The IO verbs (the core)

A leading bareword (or `recv verb`) is the receiver; the peel/path is the argument.

| form | means |
|---|---|
| `i %k:v` | `w.i({k:'v'})` — find-or-create a child (insert) |
| `o %k:v` | `w.o({k:'v'})` — obtain matching children |
| `oa %k` | `w.oa({k:1})` — presence probe (boolean) |
| `oai %k...%p` | `w.oai({k:1},{p:1})` — find-or-create-or-**mutate** (sync) |
| `r %a...%b` | `await w.r({a:1},{b:1})` — replace (async); `rm %a` removes |
| `roai` / `o1` / `oa1` / `ob` / `bo` / `boa…` | the rest of the IOness family, same `(sc,q)` shape |
| `A i …` / `pier o …` | receiver before the verb |
| `pier&do` / `&name,a,b` | call: `pier.do()` / `this.name(a,b)` (tight `&`; spaced `&` = bitwise) |
| `H i A:Alice/w:Peeroleum` | lay a sibling **actor** on the House (H-receiver) |

## Peels & paths

- `%Text` = `{Text:1}`; `%k:v` = `{k:'v'}`; `%a,b:2` = `{a:1,b:2}`. The mainkey is first.
- `%` is **optional** on a peel (`i A:Alice` works); prefer omitting it.
- Multi-leg path with `/`: `i hut/toot:3` = insert `hut`, then its child `toot:3`.
- **Loose values** carry non-word chars: `reason:no-direct-route`. A word stays a string,
   a number stays a number (`3`, `3.6`); quote for spaces/commas (`'two words'`).
- `n%such` → `n.sc.such` — the scalar-child accessor (tight `%` only; chains `n%a%b`;
   spaced `a % b` stays modulo, `%Foo` stays a sigil).

## Captures (pull a C or a value out of a leg)

```
o hut/toot$              // row-out: bind the toot C (bare $ → the C)
A o wither$vish          //   …into a named var (vish = the row C)
A o prefixy,wither.$ang  // value-out: ang = the %wither .sc value (the dot takes the value)
A o prefixy,wither.$:ang // value-OUT spelling (mirror of :$ value-IN); both name the let
H i A:Bob$:AB            // row-out into AB on an i; A:$side is value-IN
let {AB, wB} = H i A:..$AB/w:..$wB   // multi-assigning two-leg
```

## `%req` and `doai` (the data language's heart)

`oai %req:…` seeds-or-mutates a `%req` in place (same ref, `%mutated` flagged on drift).
`oai %req:…` **with an indented block** lowers to `doai()` — the block becomes the req's
do_fn, handed the req as the implied arg `req`:

```
oai %req:waft_roster,eternal      // eternal = never finishes; self-settles via req.sc.ok=1
    i %roster                     //  the do_fn body
    req i %seen
oai %req:desire                   // nesting: a child req inside the parent's do_fn
    req oai %req:acquire,maz:9     //  maz orders leaves (highest runs first); `req` re-binds
        req i %got
```
(See `LakeTiles.g` `reqTiles`/`looseScTiles`/`ampTiles`/`captureOutTiles` for the full set.)

A leaf that must wait for wall-clock time arms a one-shot `%ttlilt`
(`H.i_req_ttlilt(req, secs)`) — but **only a req that finishes** can carry one: the ttlilt
holds the snap open until that req reaches `finished` and is dropped on `finish()`. An
`eternal` req (never finishes, self-settles via `req.sc.ok=1`) uses none. See
[[ttlilt-not-a-keepalive]].

## The language is still soft — extend it before dropping to raw JS

Doctrine ([[dsl-over-raw-js]]): when a `.g` keeps reaching for raw JS for the same kind
of thing, that is a signal to **grow the language** (heading L), not to keep escaping —
*"we can still change this language if it makes sufficient sense to."* The gate is
"sufficient sense": a recurring seam earns a tile; a one-off stays raw.

**Open gaps (current raw-JS escapes — candidate extensions):**
- auto-`async` on a body with a bare `await`-verb (`r`/`rm`/`roai`/`await x.do()`).
- `drop`/`empty`/`oa` verbs; deep/wildcard `drop Pier/protocol/**`.
- drilled paths on `oai`/`r`/`rm` (seed a `%req` under a nested host without pre-resolving).
- object / `.c` payloads (`c.connection`, `stashed:{…}`, frame objects off the wire).
- list fan-out (one `%req:dial` per peer over a thang list).

**Genuinely stays raw JS:** live handles on `.c` (mock-port pairing, a `WebSocket`), and
values that are objects-off-the-wire — `.sc` is scalars only.

**To change the language:** edit `io_tokens.ts` (value/capture tokens) and/or `stho.grammar`
(then regen the `stho.grammar.ts` artifact via the in-app gen action — the registry falls
back to a live `buildParser` until you do, so it works but is flagged stale) and/or
`lang/compile.ts` (the translator). Verify with `npm run lang-compile -- <file>` against
the corpus (`LakeTiles.g`) — its output should be unchanged for everything but the new form.

## Gotchas (durable)

- **Nested-req `c.up`:** a `%req` hosted below `w` (under a `Pier`/`Peering`) silently never
   pumps unless the host chain's `c.up` is hand-stamped — the belief walk wires `A`/`w` only.
    See [[nested-req-needs-cup-stamped]].
- **`<script module>` needs `lang="ts"`** or Vite's optimizeDeps esbuild scan breaks
   ([[module-script-lang-ts]]).
- **Grammar artifact staleness:** editing `stho.grammar` makes `stho.grammar.ts` stale (live
   `buildParser` fallback is correct, just flagged); editing `io_tokens.ts` needs no regen.

Canon: `Ghost/test/Story/Lake/LakeTiles.g`. Compiler: `src/lib/O/lang/compile.ts`,
`LangCompiling.svelte`. CLI: [[lang-compile-cli]]. Open language work: handover heading L,
`LangCompiler_TODO.md`. Peel/capture details: [[langtiles-peel-syntax]].
