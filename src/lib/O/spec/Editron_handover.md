# Editron — the IDE top-level world (handover)

## What's built (this session)

`?A=Editron` (parsed in Otro via `boot_param` → also `A=` env in node) makes
 `may_begin` stand up `A:Editron/w:Editron` **instead of** `A:Auto`, so the Library never
  loads. `Editron(A,w)` (src/lib/O/Editron.svelte) stands up `Lies%editor` + `Lang%editor`
   (+ Pantheate) and opens the Waft named by `?W=<Waft>` (env `W=`, default `Ghost/Net/Easy`,
    the overlay carrying the Peeroleum/Peregrination `.g` docks). `editor:1` is the explicit, queryable counterpart to the test
     runner's `runner:1` — today the code branches on `!w.sc.runner`, so a plain Lies already
      behaves as the editor; the flag is for future `w%editor`-specific behaviour.

The bare stand-up is freshly testable in a browser (the OOM that blocked it was the Otro
 construction-`$effect` self-retrigger loop — never read the `$state H` inside the effect that
  reassigns it, or it loops allocating Houses → multi-GB; now fixed, NOT Editron). Run it on
   the dev instance: `/Otro?A=Editron` (add `&W=<Waft>` to open a different Waft). Staging
   (staging/docker-compose.yml, port 9092, a git worktree) is only for an isolated source
    checkout that dev's HMR can't disturb — not needed to exercise the feature.

## Next: editor compiles, runner runs — the Pantheate split

**Destination.** Editron edits a Waft; it must NOT *run* it. Compiling a `.g` in the editor
 should write the `.go` and stop — the editor's own Pantheate must not "take up" (import +
  mount) the compiled module, or the editor would run the code itself. The `.go` lands in the
   shared dev repo; the *runner* instance (`Lies%runner` + Story) picks it up and runs the
    test. Editor and runner are the two ends sharing the one Waft.

**The bomb.** The compile→include chain is in LiesCortex: `e_Lies_compiled` writes the gen via
 `req:Codebit`; on `write_finished` it fires `i_elvisto('Pantheate/Pantheate',
  'Ghost_update_notify', …)`, which dynamic-imports the `.go`, mounts it as a
   `UI:'Pantheate-include'` component, and `req:include` polls `H[Ghostmeta_…]()`. To stop the
    editor taking up the code, gate that notify/include on `!w%editor` (only-on-runner) — the
     editor keeps the compile + the error feedback but drops the mount. NOTE the runner end
      still has the *headless-include* problem found this session: Pantheate mounts the gen as
       a UI component whose `onMount`→`eatfunc` injects `Ghostmeta`, and headless renders no
        UIs, so the runner needs the UI-render (the H%Src idea) or a headless-include shim
         before it can actually run a freshly-compiled `.go`. (See Story_cli_handover.md +
          the headless compile-timeout findings — the runner's `req:include` ttlilt times out
           at `waiting:ghostmeta` because the gen UI never mounts.)

**Cross-instance.** Editor and runner are *different servers* — separate Houses, no shared
 `eatfunc`, so the editor can't just deposit methods for the runner. The handoff is the `.go`
  *file* (written to the shared repo via Wormhole + the Directory API) plus a *signal* to the
   runner to re-read/re-include. Browser↔browser is blocked by CORS, but each instance's
    **node server** (the vite/Wormhole backend) — soon to carry websockets — can message
     **server-to-server**, no CORS: editor's node server → "new `.go` at <path>" → runner's
      node server → runner re-pulls + re-includes.

**Next move.** (1) Gate `Ghost_update_notify`/`req:include` on `!w%editor` so `Lies%editor`
 compiles-without-mounting. (2) Make the runner pick up a fresh `.go` — file-poll first, the
  node-server websocket signal once those sockets land. (3) The headless-include fix is the
   prerequisite for the runner side actually executing it.
