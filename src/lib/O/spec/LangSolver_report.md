# What an IOing expression becomes — the LangSion reduction

A report on what to reuse (ideologically) from `iooia` |`Index.coffee`, and how
to build it — by building it, as a reductive oracle in `LangSion` that decides
which existing drill an IOing wants and throws the moment one reaches past them.
The work stays inside the cordon (`LangSion`, the docs); where a feature needs
`LangCompiling`, the grammar, `Selection`, or a Lies/Understanding fact, that is
called out as going beyond it.

---

## The question

`IOing` is `IOness IOpath` — a verb (`i`|`o`|…) and a `/`-separated path of legs,
each leg a comma-joined `PeelGroup` that becomes one match `sc`. The grammar
already tokenises far more than compiles: the full `IOness` family
(`i|o|oa|ob|o1|oa1|bo|boa|drop|empty`), the `IOness2` family (`oai|roai|moai|r`),
two `IOpath`s on one `IOness2` (the inline `->` shape), captures, puddles. But
`Lang_compile_IOness` trims to `i`|`o` and throws on the rest, and
`Lang_compile_IOing` routes only single-leg-inline |the five drills.

So "what an IOing becomes" is, today, a small reduction of a much larger design.
The honest move is to make that reduction *explicit and shared*: one oracle that
reductively lands on the cheapest existing helper, and fails loud — naming the
`iooia` seam — the instant an expression wants more. That oracle lives in
`LangSion` because it is exactly "compile-time thinking about runtime stuff":
the same ladder that tells `LangCompiling` which helper to emit tells the runtime
which drill a plan will run.

---

## The ideology in `iooia` — the cast, and where each one already sits

`iooia` is the prior I/O culture in the older `&s,d{…}` dialect. It is much
bigger than what ships, and most of it is deferred — but the *shapes* are the
map of where the current system is heading. The reusable ones:

| `iooia` shape | what it is | where it sits now |
| --- | --- | --- |
| `parsetalk(talk,params,d)` | parse a talk string into a `d` descriptor (`d.path`, `d.is`, `d.plumb`) | the stho grammar + `Lang_compile_Leg`/`PeelItem` build the same `d` as syntax-tree-derived leg objects |
| `rowing` — travel `d.path` for i/o hooks | the per-leg walk, binding params, doing upstream `plumb` first | the drills (`_i_drill`/`_o_drill`) are `rowing` with one C per leg, no plumb |
| `nz(d)` → `t`, `t.more()` | turn a result into a cursor you pull a row at a time | `_io_cursor` (built here, single-row); `_o_iter` is the drained-in-one form |
| `parkar()` ark-grouping read-ahead | fold a fanned leg into `ar[k]=[v+]` columns — "basically a database" | **not built**; the capture doc's fan-out future; gated on the taxonomy seam |
| `forS` — domes that iterate | a standing cursor (`1s&forSing`, `in_progress`), Babz-set params from `T` | `Sunpit` → `_o_iter` today; the slow-motion version is `_io_cursor` here |
| `not:1` compile-time mode | `io.i(talk,params,{not:1})` hands back `sjson(d)` — the call as data, the smart work done before now | **a separate dream**; see the sleeping-optimiser note below — not a `LangSion` helper |
| `doof`/`separation` | a function mid-path; cloning through it | **not built**; a `_io_plan` flag throws on it |
| `gref`/`parsegref`/`codegref` | attribute/fuzzy matching | **not built**; out of scope per the Waft spec (decoration before fuzzy) |
| `knowables` / via-T | "understand this name, then look it up" — late resolution | the verb-family throw points here; `Selection.process` is the Map-building cousin |
| J6ing — dome consciousness | the overmind that decides when work happens, savepoints | the "overmind driving an elvis through an extent" — `_io_cursor.more()` is the pull it drives |

`Index.coffee` is the indexing cousin (`brackX`, `X_t`/`X_s` columns-by-value).
It belongs to the Map-building / fuzzy phase (`Selection.process`, the Dexie
index), not to the IOing reduction — reusable later, not now. It is noted and
set aside, same as `gref`.

---

## The reduction we actually ship

One C per leg. No fan-out, no plumb, no doof, no fuzzy. The verbs are `i`|`o`.
On that footing the whole space collapses to a short ladder, cheapest-first:

- a single leg, under two captures, not iterated → **tier 0**, inline
  (`w.i(sc)` |`w.o(sc)`); the drills never see it.
- a `Sunpit` → `_o_iter`, the flat frontier.
- two-plus captures → `_i_drill_caps` |`_o_drill_caps`, a destructured bag.
- one capture → `_i_drill` |`_o_drill1`, with the `.$`/`$` value-or-row grab.
- no capture, multi-leg → `_i_drill` |`_o_drill`.

`_i_drill` is `oai` (find-or-create) every leg above the last, then `i` on the
last — so the leaf is a fresh insert and the path it walks through isn't
duplicated. `_o_drill` picks `[0]` at each intermediate step and returns the
final leg's whole array; `_o_drill1` takes the first hit. `_o_iter` flat-maps
all matches at every level. That is the entire runtime surface, and it covers
every line in `LangTiles.g`.

---

## The build — a reductive oracle in `LangSion`

Four additions, all methods on the `eatfunc` `this`, all inside the cordon.

### `_io_plan(adv)` — the oracle

Runs on (nearly) every IOing. Takes the *advice* `{ ness, legs, sunpit?, flags? }`
(the word `adv` because `req` is taken by reqy) and returns
`{ tier, helper, ness, iter, caps, grab }`, or throws. The usual answer
is "a drill handles it" — so the verb compiles |runs with no further modelling,
which is the point: it reductively figures what it can get away with, and does
so the vast majority of the time.

It throws on a verb outside `{i|o}` (the IOness family |the `oai`-verb want
their own last-leg drills — unbuilt) and on any `flags` the compile side sets
when the tree carries a node a drill can't walk (`wildcard` `/*:` |`@ark`
frontier |`doof` mid-path |the `->` flow form). The runtime leaves `flags`
unset, since a built `Leg` can't hold those shapes anyway — so one function
serves both callers: `LangCompiling` fills `flags` from the syntax tree,
the runtime relies on the legs.

It is the single source of truth for the tier. `LangCompiling` can read it
instead of carrying its own copy of the ladder; the runtime can assert a plan
before running it. A logic-mirror of the ladder was run against every IOing in
`LangTiles.g` — all thirteen land on the same helper `Lang_compile_IOing`
already emits, and the unbuilt verb |flag cases throw.

### `_io_run(C, adv)` — execute a plan

The one entry that turns a plan + legs into the C work. Most generated code
still calls the named drills directly — a lean inline read |a destructured
`let {a,b} =` reads better in place. `_io_run` is for the callers that *hold* a
plan rather than emit one: the slow-motion cursor, a Se walk, an overmind
stepping an extent. tier 0 is inlined here too, so a plan alone can run any
IOing. The value-grab is applied at this boundary so a caller sees the value
for `.$`, the row C for a bare `$`.

### The big-datastructure / sleeping-optimiser dream — left unbuilt

There was a passing suggestion to "freeze" a plan to JSON — the `iooia` `not:1`
shape, the call as data. On reflection that was over-suggested: rendering a plan
to JSON is trivial (`legs` are already plain data), so a tiny `_io_freeze` would
be busywork that earns little on its own. The thing it was reaching at is bigger
and far less settled — something that would *sleep whole chunks of the compile
system* for optimisation, inlining big datastructures where it's safe to, and
that would only be able to do so because it knows where entanglements exist.
That is scarcely sketched anywhere yet. It seems to be mostly about
`Selection.process()` sublating into whatever it is really trying to become —
which looks like it goes in and out in several places, woven through the rest of
the apptivity — and not about `%Seem` at all. It wants its own dream-up before
any of it is named in code. Noted here as an open horizon, not a helper.

### `_io_cursor(C, legs)` — slow-motion S

A `Sunpit` frontier you pull a row at a time, holding your place across pulls,
so an overmind can step it when it wants — slow motion, in place — instead of
draining it in one `for-of`. This is `iooia` `nz()`/`t.more()` |`forS` (the
standing cursor, its `in_progress` flag) reduced to a single-row eager frontier:
a single walk advancing through an extent, pulled by an elvis from whatever
process is minding it.
`.more()` hands back the next C |`undefined` once drained; `.i`/`.done` track
position; `.in_progress` is the flag a `forS` reads to resume a held cursor
rather than rebuild it.

### `_se_plan(seem)` — a `%Seem` said as an IOing (frontier — highly experimental)

A theoretical weld, not a load-bearing path: the idea that `Se` could be wired by
throwing an IOing around it, so a Seem's reach into the remote `%What` reads as
an `o`-walk with a wide match |a trace tag, and the same ladder that routes
`o`|`i`|`S` would describe what a Seem does. `_se_plan` sketches the translation —
`%Seem:origin` as `o` one wide leg (`match_sc:{}`), the awareness walk yielding
`goners`|`neus`; `%Seem:working` the same shape carrying its D/U sphere. It is a
sketch of the shape only: the `%Seem` itself lives in `Selection`, beyond the
cordon, and whether `Se` wants saying this way at all is unsettled. `trace_sc`
rides the walk, not the leg `sc`, so it returns on `opt.trace` and `_io_plan`
stays match-only; a walker (`Selection.process`) would consume the trace, not a
drill. Kept as a frontier marker, not a wire.

---

## Se via IOing — a frontier weld, not a settled wiring

This whole idea is marked experimental. The two-Seem model in `LiesEnd` already
speaks in `match_sc`/`trace_sc`, which is the same vocabulary a Leg's `sc`/`exactly`
is — so it is *tempting* to say every Seem walk could become an IOing the oracle
classifies (`%Seem:origin` the awareness `o`, `%Seem:working` the editable-clone
`o`, the `goners`/`neus` of a re-walk being the "remote moved" clue rather than
the push-state, which stays the `enWaft`-compare). But whether `Se` wants saying
this way is unsettled, and the `%Seem` lives in `Selection` beyond the cordon. So
`_se_plan` stands as a marker of the possible weld, not a load-bearing path; if
it ever firms up it needs `Selection.process` to consume the `trace` and
`understandable` it hands back alongside the leg.

---

## Slow motion, the overmind, the extent

The dream — `S` IOing in slow motion, iterating when they want, in place, via an
elvis from an overminding process — is a single walk advancing through an extent.
The pieces are real for the handled tiers: `_io_cursor` is the standing position,
`.more()` is the elvis the overmind pulls, `.in_progress` is the resume flag. What
is *not* real is the read-ahead that turns a fanned leg into columns — the
"basically a database" escalation — because that needs the taxonomy seam below;
nor is the larger optimiser that would sleep and inline whole chunks knowing the
entanglements, which is its own dream-up (above).

---

## The TODO seam

The deferred work, smallest-first, with which ones leave the cordon:

- the oai-verb (and the rest of the IOness|IOness2 family): their own last-leg
  drills. In cordon — `LangSion` drills + `Lang_compile_IOness` in `LangCompiling`.
- the fan-out / database escalation: a mid-path leg matching N rows turns the
  captures below it into N-wide columns (`parkar` ark-grouping). `_io_cursor` is
  single-row until this lands. Beyond cordon — it needs the taxonomy seam,
  "which legs are plural", which is either an stho annotation (the collector
  decides locally) |a Lies/Understanding fact (the compiler consults Lies at
  compile time, a producer/consumer seam across the cordon). Resolve the seam
  first; it gates the fan-out drill design.
- the `->` flow form (split obtain from insert) + `@s`|`@are` frontier refs.
  The grammar already allows two IOpaths on one IOness2 (the inline form);
  neither `->` nor `@`-resolution is built. Beyond cordon — grammar + compile.
- `doof` mid-path (a function in the path) + `separation` cloning. Beyond cordon.
- `gref` fuzzy matching + the Map-building phase (`Selection.process`, the Dexie
  index, `Index.coffee`'s `brackX`). Out of scope per the Waft spec — decoration
  powers before fuzzy-matching powers. Beyond cordon.
- the sleeping-optimiser / big-datastructure-inlining dream that knows where
  entanglements exist. Scarcely sketched; mostly about `Selection.process`
  sublating, not `%Seem`. Wants its own dream-up. Beyond cordon.
- adopt `_io_plan` as `LangCompiling`'s tier source: today `LangCompiling`
  carries its own copy of the ladder; the mirror confirms they agree, so the
  compile side could call `_io_plan(flags-from-tree)` and drop the duplicate.
  In cordon for `LangSion`; the call-site change is in `LangCompiling`.
