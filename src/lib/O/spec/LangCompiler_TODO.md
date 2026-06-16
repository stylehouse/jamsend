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

## the data language — `req:X {…}` block → doai (unblocked)

`doai` now HAS a runtime: the Hovercraft req engine landed, so `doai()` exists on
`TheC` (alongside `oai`/`roai`/`moai`) and req is generally available on any C —
served when inside a w|req. So the grammar's `IOness2` `doai` token is no longer
stranded, and the **data language** it was waiting on is unblocked (forwarded here
from `Hovercraft.design.md`, which is now down to its own engine tail).

The piece: compile a `w roai req:X { …body… }` block into a `doai` call whose body
becomes the one-shot `do_fn` — i.e. `(await w.doai({req:'X'}))?.(async (req) => { …body… })`.
Spec the lowering: capture of the host `w` and the `req` param, and the fact that a
`doai` body is **async by construction** (so it ties into the async-verb warning
above — a method that compiles a `req:X {…}` block must be `async`). Its own piece;
sequence it after the in-flight req migrations settle.

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
