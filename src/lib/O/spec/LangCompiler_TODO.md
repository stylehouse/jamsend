# Lang compiler — TODO list

Open compile-side work + the durable authoring rules. The IOing *reduction* (drills, the
 `_io_plan` oracle, the database horizon) has its own list in `LangSolver_report.md`; this
  file is the surrounding compiler. Completed work is git history, not here.

## Advice to writers of `.g` code (durable do/don't)

### Imports — `IMPORT()` with `$lib/…`, never relative
Reach a TS module via the `IMPORT()` header pseudo-method, always with the absolute `$lib`
 alias — never a relative path. The gen `.go` lands at two depths (runner `gen/N/*.go`, editor
  frozen `p2p/transport/*.go`), and only a `$lib` alias resolves identically from both. Keep
   shared primitives that a node side also needs (e.g. `cluster_trust.ts`, so `relay.ts` can
    import it) in their own TS module and `IMPORT` them — a `.go` is a browser Svelte component,
     not a home for node-side or duplicated code. `RENDER()` is the tail twin (`<Child {H} />`).
  See `Ghost/test/Story/Lake/LakeTiles.g` for both shapes.

### What's imported by default
The gen template auto-injects only **`TheC`** (plus `onMount`, eatfunc plumbing, not yours to
 call). Everything else needs an explicit `IMPORT`; don't re-`IMPORT` `TheC`.

### After you edit a `.g` on disk — run `ghost-update`
Editing a `.g` outside the in-app editor does NOT regenerate its `.go`, so runners keep judging
 themselves current against stale code (the dige is content-addressed, `Ghostmeta = sha256(.g
  text)[:16]`). The one maneuvre, no flags:

```
docker compose exec claude npm run ghost-update -- Ghost/N/Foo.g [more.g …]
```

It compiles each `.g`, writes its `.go` (Vite HMRs that to every dev server on the shared `/app`,
 so runners re-acquire), then ALWAYS — concurrently — **notifies** the editor (signs a
  `this_dock_updated` with claude's cluster key, short-lived ws to `EDITOR_URL`'s relay, so the
   editor re-reads the dock's `%Good`) and **verifies** `EDITOR_URL` serves the new module.
 `EDITOR_URL` comes from the cluster env (`gen-cluster-identos` defaults `http://172.17.0.1:9092`).
  The editor needs its cluster key (🪪 Id hatch) to have its own `gen_write` accepted; claude needs
   `.env.cluster-claude` to sign. Open hop: the editor still drops claude's notify PRE-`%Ud` until
    the relay verifies + forwards it — verify + runner HMR work regardless. See `ClusterTrust_handover.md`.

### `lang-compile` PASS ≠ it runs
The editor and `npm run lang-compile` share the translator + syntax gates, so `✓ PASS` means the
 `.go` is valid JS/TS — NOT that the ghost behaves. A `.go` is a live Svelte component; only an
  in-app run / a Story test mounts it (catching a bad import path, a runtime throw, an eatfunc that
   deposits nothing). Gate syntax with `lang-compile`; verify behaviour on :9091.

## Open

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
