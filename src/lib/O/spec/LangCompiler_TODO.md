# Lang compiler — TODO list

Running list of compile-side work, smallest/most-actionable first. The IOing
*reduction* (drills, the `_io_plan` oracle, the database horizon) has its own
list in `LangSolver_report.md` — this file is the surrounding compiler.

> Naming note: this doc's `moai` shipped as **`oai`** — `moai` is neither a live
>  method nor a grammar token (`IOness2` = `oai | roai | r | rm`; `doai` lowers
>   separately). Read `moai` as today's `oai` throughout.

## async-verb warning (dev notification) — SUPERSEDED by auto-async (the fix landed)

`r | rm | roai | moai` (and any future async verb) compile to `await …`
expressions, so the enclosing method must be `async`. The original worry: the
compiler did not rewrite the method header, so a non-async method containing one
of these verbs emitted invalid TS (`await` outside async).

**Resolved — the auto-`async` fix was chosen over the warn-only path.**
`_collect_line` now scans each translated method body and, if it carries a
method-level `await` (a user one OR a compiler-emitted `r|rm|roai|moai`) while the
decl was not written `async`, rewrites the header to add `async` and stamps
`defWord.async = 1` (`compile.ts`, the "auto-async" block ~line 766). Awaits
inside a nested async arrow (an `oai|r` BLOCK do_fn) are excluded via
`arrowRanges`, so they stay the arrow's concern. This covers every IOness2 verb
the heading worried about — there is no longer an invalid-`await`-in-sync-method
to warn about, so the `compile_warning` sibling channel is **not built** (the
silent rewrite is the better outcome).

If a non-fatal `compile_warning` channel is wanted later for a DIFFERENT class of
advisory (it would still want the same shape: a sibling to the fatal
`compile_error`, accumulated without breaking the collector loop, rendered amber
by Liesui / `simpleLezerLinter` at `severity:'warning'`), the design above stands
— but the async case no longer motivates it.

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

Corpus: `Ghost/test/Story/Lake/LakeTiles.g` `reqTiles` exercises moai + the doai block forms
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
that trusts it). See `Editron.md` §2 for the channel half.

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
    (`Editron.md` §1 "Pantheate split" + §2), orthogonal to parser
     readiness. The translation display itself (`LangCompiling.svelte:238`, the disabled
      `if (0 && ln.kind === 'translated')` block) is still a TODO to wire up.

**Failure B — translated but invalid JS (BOTH gates done).** A raw-JS seam can
emit syntactically-broken JS even WITH a parser — e.g. a bare multi-line `else` mangled by the
indentation→brace logic into `} else {}` (bit `Socket_real`). The parser-guard does NOT catch this.
- **Done (author-time):** `scripts/lang-compile.ts` now runs the rendered module through esbuild
   (`transform`, `loader:'ts'`, no type-checking — the loosest syntax gate); `✓ PASS` means "module
    parses". Catches B before commit. See the `lang-compile-cli` memory.
- **Done (run-time twin):** `Lang_compile_render_module` is now followed by
   `Lang_validate_rendered_module` (`compile.ts`) inside `Lang_compile_dock`'s `try` — so a failure
    drops into the existing `compile_error` path (writes NOTHING, re-arms next pass), before
     `e_Lies_compiled` and before any `dock_push`. It reuses `@lezer/javascript` configured
      `{ dialect: 'ts' }` (the JS dialect would error-node every `: type` / `as TheC` — do NOT reuse
       the registry's substitute parser, which is `{}`/JS), walks the tree for the first
        `n.type.isError`, and aligns the diagnostic to the `.go` module's line numbers (same
         `scriptOfModule` newline-padding as the CLI). The CLI now runs BOTH gates and prints a
          `⚠ gate disagreement` line if esbuild and lezer ever split, so the two stay in lockstep —
           verified agreeing on the whole `.g` corpus and on the `} else {}` / unclosed-paren / garbage
            reject cases. esbuild stays the author-time authority; lezer is the in-browser twin.

**The general principle:** the compiler must not hand downstream (disk, Pantheate, the runner over
the WS) any output it hasn't proven is real compiled JS. The parser-guard (A) + the two output
gates (B) are that contract; A is in, B is half in (CLI), the in-app half is the next move.
