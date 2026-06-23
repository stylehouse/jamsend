# Lang compiler — TODO list

Open compile-side work + the durable authoring rules. The IOing *reduction* (drills, the
 `_io_plan` oracle, the database horizon) has its own list in `LangSolver_report.md`; this
  file is the surrounding compiler. Completed work is git history, not here.

## Advice to writers of `.g` code (durable do/don't)

### Imports — `IMPORT()` with `$lib/…`, never relative
Reach a TS module via the `IMPORT()` header pseudo-method, always with the absolute `$lib`
 alias — never a relative path. The gen `.go` lands at two depths (runner `gen/N/*.go`, editor
  frozen `p2p/pinned_staging/*.go`), and only a `$lib` alias resolves identically from both. Keep
   shared primitives that a node side also needs (e.g. `cluster_trust.ts`, so `relay.ts` can
    import it) in their own TS module and `IMPORT` them — a `.go` is a browser Svelte component,
     not a home for node-side or duplicated code. `RENDER()` is the tail twin (`<Child {H} />`).
  See `Ghost/test/Story/Lake/LakeTiles.g` for both shapes.

### What's imported by default
The gen template auto-injects only **`TheC`** (plus `onMount`, eatfunc plumbing, not yours to
 call). Everything else needs an explicit `IMPORT`; don't re-`IMPORT` `TheC`.

### After you edit a `.g` on disk — run `ghost-compile`
Editing a `.g` outside the in-app editor does NOT regenerate its `.go`, so runners keep judging
 themselves current against stale code (the dige is content-addressed, `Ghostmeta = sha256(.g
  text)[:16]`). The one maneuvre, no flags:

```
docker compose exec claude npm run ghost-compile -- Ghost/N/Foo.g [more.g …]
```

This is the **remote-local-ghost-compile** form, and the name earns its strangeness: the `.g` is
 already on the editor's shared `/app` disk, so the CLI ships no content — it signs a `ghost_compile`
  ticket `{path, dige}` (claude's cluster key) to `EDITOR_URL`'s relay and STAYS OPEN. The live editor
   force-loads that dock, compiles it, writes the `.go` (Vite HMRs it to every runner on the shared
    disk), and **acks back** `started → done(dige) | error(errors)`, corr-routed to the waiting CLI;
     the CLI also dige-poll-verifies `EDITOR_URL` serves the new module, and times out (12s) if the
      editor is gone/half-open. `EDITOR_URL` comes from the cluster env (`gen-cluster-identos` defaults
       `http://172.17.0.1:9092`); the editor needs its cluster key (🪪 Id hatch) for its own `gen_write`
        to be accepted, claude needs `.env.cluster-claude` to sign. A *purely* remote form — CodeMirror
         carrying the edit over the wire, no shared disk — could exist but doesn't.
   See `GhostCompile_feedback_handover.md`.

### compile PASS ≠ it runs
The editor's compile (driven by `npm run ghost-compile`) runs the translator + syntax gates, so a
 written `.go` is valid JS/TS — NOT proof the ghost behaves. A `.go` is a live Svelte component; only an
  in-app run / a Story test mounts it (catching a bad import path, a runtime throw, an eatfunc that
   deposits nothing). Gate syntax with `ghost-compile`; verify behaviour on :9091.

## Open

- **post-IOing element accessor — `o req:handshake 0` / `-1` / ranges.** A query (`o`/`oa`/…) returns a
   list, and reaching one element is today raw JS: `pier.o({req:'handshake'})[0]`, then `.sc.finished`.
    The seam: **anything that is illegal JavaScript right after an IOing is the DSL's to claim.** A bare
     trailing integer is illegal JS after `o {…}` (two expressions, no operator), so it can mean index:
     - `pier o req:handshake 0`   → `pier.o({req:'handshake'})[0]`   (first match)
     - `pier o req:handshake -1`  → `…[len-1]` (last) — `.at(-1)`, so a negative counts from the end
     - `pier o req:handshake 0..2` (or `0:2`) → a range/slice accessor (returns a list) — spelling TBD
    Composes with the existing capture/`%` sugar so the cited line collapses to one tile:
     `if (pier o req:handshake 0)%finished` ⟶ `if (pier.o({req:'handshake'})[0]?.sc.finished)`, or with a
      let: `let hs = pier o req:handshake 0` then `hs%finished`. Decide: does `0` bind tighter than a
       following `.$:cap` / `%key`? (Index first, then the accessor on the element — `o … 0 %finished`.)
        Guard the obvious footgun: a bare `0` that is actually a *value* leg belongs inside the peel
         (`req:0`), never trailing; the accessor only attaches after the whole IOing peel closes.

- **whole-doc parse vs. the per-line fast path.** `Lang_compile_collect` parses each candidate
   line standalone — the cause of multi-line template literals miscompiling (a prose line in a
    backtick re-parsed as a `ControlFlow` block). A whole-doc stho parse of the largest ghost
     measured ~15 ms, ~0 % error nodes, so the per-line path could retire in favour of one
      whole-doc walk (CM parses incrementally; see `ensureSyntaxTree`), removing the multi-line
       string/comment hazard structurally. Gated on confirming the in-editor cost.

- **IOness2 captures / multi-leg.** `Lang_ioness2_arg_src` takes a single leg per arg and throws
   on a drilled `a/b/c` path. If a drilled match ever makes sense for these verbs it needs the
    drill treatment; for now the throw is the spec.

- **translation-display wiring.** The line-by-line translated view (`LangCompiling.svelte`, the
   disabled `if (0 && ln.kind === 'translated')` block) is still TODO to wire up.

- **`</script>` sharp edge.** A literal `</script>` in `.g` source (even inside a comment)
   truncates `Lang_validate_rendered_module`'s extractor — it marks the FIRST one as the script
    end. Low priority (write "closing script tag", not the literal); the extractor could scan for
     the LAST `</script>` or skip comments/strings if it ever bites real code.

- **RENDER → manifest.** A `.g` can name its child ghosts as `<Child {H} />` via `RENDER()`, so the
   dependency tree could live in source instead of the runner's hand-maintained flat
    `CREDULER_GHOSTS` include array (`LiesLies.svelte`). Migrating that (mount order, the
     live-vs-frozen-spine split the editor needs) is the follow-on.
