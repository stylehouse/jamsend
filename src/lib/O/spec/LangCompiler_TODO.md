# Lang compiler — TODO list

Running list of compile-side work, smallest/most-actionable first. The IOing
*reduction* (drills, the `_io_plan` oracle, the database horizon) has its own
list in `LangSolver_report.md` — this file is the surrounding compiler.

## async-verb warning (dev notification)

`r | rm | roai | moai` (and any future async verb) compile to `await …`
expressions, so the enclosing method must be `async`. The compiler does **not**
rewrite the method header — a non-async method containing one of these verbs
emits invalid TS (`await` outside async).

TODO: notify the dev, like a TS warning. When `Lang_compile_collect` emits an
await-requiring IOness2 verb inside a method whose decl wasn't written `async`,
surface a line diagnostic (the `words` index already records `{def, method,
async?}` per method — line 927 — so the check is local: does the enclosing decl
carry `async:1`?). Decide later whether to also offer an auto-`async` fix
(rewrite the `MethodLike` decl) vs. warn-only.

Where it plugs in — NOT the existing error path. Line-level errors go through
`line_errors` → `job.i({compile_error:1, line, msg, text})` (line ~603), read by
Liesui + the graft/minimap path. But that channel is **fatal**: the collector
`break`s at the first error (line ~568, "output beyond a mis-parsed line is
unreliable"), and `compile_error` is terminal for the graft. A warning must NOT
abort the compile, so it wants a **non-fatal sibling channel** — a
`compile_warning` particle, same `{line, msg, text}` shape, accumulated without
breaking the loop and rendered amber (Liesui + the `simpleLezerLinter` could
emit `severity:'warning'` instead of `'error'`). This is the same "continue past
the first error" UI path the collector already wishes for at line ~400.

## the data language — `doai %req:X` block → do_fn (DONE)

`doai` now HAS a runtime: the Hovercraft req engine landed, so `doai()` exists on
`TheC` (alongside `oai`/`roai`/`moai`) and req is generally available on any C —
served when inside a w|req. So the grammar's `IOness2` `doai` token is no longer
stranded, and the **data language** it was waiting on is unblocked (forwarded here
from `Hovercraft.design.md`, which is now down to its own engine tail).

Lowered (LangCompiling `_collect_line`, alongside the r-with-a-block branch): a
`doai` verb whose path is followed by a pythonic-indented body seeds the `%req`
and wires that body as its one-shot `do_fn`:

    doai %req:X,eternal          ;(await w.doai({req: "X", eternal: 1}))?.(async (req) => {
        i %roster          →          w.i({roster: 1})
        req i %seen                    req.i({seen: 1})
                                   })

Notes on the shape that landed:
  - the verb is `doai` itself (not the spec's earlier musing of `roai req:X {…}`),
    matching the runtime's `w.doai({…})?.(fn)` shape and the existing r-block path.
  - the body's implied arg is always named **`req`** — the seeded req handed back.
    Nested `doai` blocks shadow it per-block (the runtime names them desire/acquire;
    the compiler's convention is the fixed `req`).
  - host capture is the receiver: bare → `w`, a leading bareword (`A doai …`) → `A`.
  - the call leads with `;` — doai emits a call expression and the compiled lines
    above carry no trailing `;`, so the `(` would otherwise glue to the line above.
  - the body is **async by construction**, so its own await-verbs are fine; the
    enclosing method must still be `async` (ties into the async-verb warning above).
  - a bare inline `doai` (no block) has no handler to wire, so `Lang_compile_IOness`
    throws "doai needs an indented block — its do_fn body".

Corpus: `Ghost/test/LangTiles.g` `reqTiles` exercises moai + the doai block forms
(plain, receiver-before-verb with a maz level, and nested).

## whole-doc parse vs. the per-line fast path

`Lang_compile_collect`'s stho fast path parses each candidate line standalone,
which is what made multi-line template literals miscompile (a prose line inside
a backtick re-parsed as a `ControlFlow` block). Measured: a whole-doc stho parse
of the largest ghost is ~15 ms with ~0 % error nodes — no recovery storm — so
the per-line path could be retired in favour of one whole-doc walk (CM already
parses incrementally; read `ensureSyntaxTree`). That removes the multi-line
string/comment hazard structurally. Gated on confirming the in-editor cost.

## IOness2 captures / multi-leg

`Lang_ioness2_arg_src` takes a single leg per arg and throws on a drilled
`a/b/c` path. If a drilled match ever makes sense for these verbs, it needs the
drill treatment; for now the throw is the spec.

## validating the compile output — "nothing checked it" (the silent-passthrough class)

Two real bugs, same disease: the compiler emitted text that **was never validated** before
it was written/trusted, so a `.go` of garbage landed on disk (and svelte's parser is the first
thing to notice, far too late — and on the editor↔runner channel it would be PUSHED to a runner
that trusts it). See `Editron_runner_channel.md` for the channel half.

**Failure A — compile with no parser (FIXED).** `Lang_compile_collect`'s contract is "a line the
grammar doesn't recognise passes through verbatim (`kind:'raw'`)" — correct per line. But if the
WHOLE `language` facet is empty (the async `lang()` resolve hasn't landed on the dock's
`EditorState` yet, or no/wrong extension was wired), then EVERY line is unrecognised, so the
collector emits the entire `.g` as raw and `Lang_compile_render_module` wraps **uncompiled source**.
Nothing distinguished that from a legitimately all-raw-JS file, so `e_Lies_compiled` wrote it
(`LiesCortex.svelte:148`, `LiesStore_write(w, gen_path, source)`). Symptom: a `.go` whose body is
`Foo(A,w):` / `w i %see:…` (the DSL forms), a svelte `js_parse_error`, then self-correction on a
later pass once the parser was ready — i.e. an intermittent corruption window.
- **Fix:** `Lang_has_lang_parser(state)` (`compile.ts`) — is ANY grammar parser wired on the facet?
   (Deliberately weaker than `Lang_stho_parser`: stho OR tsstho both count; the guard is against
    "no grammar at all", the lang-not-ready race, not "wrong grammar".) `Lang_compile_dock`
     (`LangCompiling.svelte`) throws when it is false, inside the existing `try`, so it becomes a
      caught `compile_error` that deletes `job.sc.pending` and writes NOTHING. The job re-arms next
       pass once `lang()` has resolved — self-healing instead of silent garbage. Verified: bare
        `EditorState` → false (refuse), lang-wired → true (compiles).
- **The trigger (CONFIRMED): the editor, via `req_compile` — not the CLI.** `lang-compile.ts` and the
   bootstrap loader (`Peregrination.svelte`) both `await lang(lang_for_path(path))` before
    `Lang_compile_dock`, so they are innocent. The editor is not: Langui builds `editorExtensions` via
     `await lang(...)` (`Langui.svelte:1355`) and mints the dock's `EditorState`, but `req_compile`
      (`Lang.svelte`) fires `Lang_compile_dock` on a `reqonce` the moment the *state* is in — which can
       precede the parser landing on its `language` facet. And a `compile_error` is **terminal** in
        `req_compile`, so the parser-guard ALONE would make a raced dock never compile.
- **Fix (done): wait for the parser in `req_compile`.** Before the `reqonce`, if `dock.c.state` exists
   but `Lang_has_lang_parser(dock.c.state)` is false, arm `i_req_ttlilt(req,0.5,{waiting:'parser'})` and
    return (reqonce NOT consumed). The editor then compiles exactly once, cleanly, the moment the parser
     lands — which is what gives the line-by-line translation view real (not passthrough) output. The
      `Lang_compile_dock` guard is then pure belt-and-suspenders for any other caller.
- **Still separate (NOT this bug): the editor should compile but NOT write.** Wanting the translation
   view means the editor SHOULD compile; suppressing the `.go` write/push is the `w%editor` gate
    (`Editron_handover.md` "Pantheate split" + `Editron_runner_channel.md`), orthogonal to parser
     readiness. The translation display itself (`LangCompiling.svelte:238`, the disabled
      `if (0 && ln.kind === 'translated')` block) is still a TODO to wire up.

**Failure B — translated but invalid JS (CLI gate done; in-app twin proposed).** A raw-JS seam can
emit syntactically-broken JS even WITH a parser — e.g. a bare multi-line `else` mangled by the
indentation→brace logic into `} else {}` (bit `Socket_real`). The parser-guard does NOT catch this.
- **Done (author-time):** `scripts/lang-compile.ts` now runs the rendered module through esbuild
   (`transform`, `loader:'ts'`, no type-checking — the loosest syntax gate); `✓ PASS` means "module
    parses". Catches B before commit. See the `lang-compile-cli` memory.
- **Proposed (run-time twin):** the in-app compile has no such gate — a `.g` committed without
   running `lang-compile` could still write broken JS. Add a parse check of the rendered module
    before `e_Lies_compiled` writes/fires (and before a `dock_push` over the channel). esbuild is
     build-time only; in-browser, reuse the registry's Lezer JS parser and reject on error nodes,
      or `svelte.parse`. Gated on in-app verification.

**The general principle:** the compiler must not hand downstream (disk, Pantheate, the runner over
the WS) any output it hasn't proven is real compiled JS. The parser-guard (A) + the two output
gates (B) are that contract; A is in, B is half in (CLI), the in-app half is the next move.
