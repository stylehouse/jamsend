# Editron — the IDE, run as a Story Book (handover)

## What's built (this session)

**The editor is now a Story Book, not a top-level world.** `?B=Editron` (parsed in Otro via
 `boot_param` → also `B=` env in node) stamps `H.c.book`; the default `A=Auto` (the Library/Story
  owner) reads it on first boot and **activates the Editron Book** (`Auto.svelte`, the "start Story
   from active book" block). `Story_subHouse` then stands up the Book's Run by calling
    **`Run_A_Editron`** (the `Run_A_<Book>` recipe, mirroring `Run_A_Peregrination`), which lays
     `A:Editron/w:Editron` + `Lies%editor` + `Lang%editor` (+ Pantheate) INTO the Run. The per-beat
      handler `Editron(A,w)` (both in `src/lib/O/Editron.svelte`) opens the Waft named by `?W=<Waft>`
       (env `W=`, default `Ghost/Net/Easy`, the overlay carrying the Peeroleum/Peregrination `.g`
        docks). The Book itself is `wormhole/Story/Editron/toc.snap` (one step + `Opt/noCyto`).
 `editor:1` is the explicit counterpart to the runner's `runner:1` — today the code branches on
  `!w.sc.runner`, so a plain Lies behaves as the editor; the flag is for future `w%editor` behaviour.

**Why a Book:** running the editor's own startup AS a Story makes it one observable, re-runnable
 step — if the editor breaks, re-run the Book and read the step snap to see how far boot got. This
  is the first of the "runtime stories"; diagnostics are Story-based.

Boot it on the dev instance: `/Otro?B=Editron` (add `&W=<Waft>` for a different Waft). Staging
 (staging/docker-compose.yml, port 9092, a git worktree) is only for an isolated source checkout
  that dev's HMR can't disturb — not needed to exercise the feature.

**Still to verify in-app (browser-only, can't be headless-checked):**
 - **boot-yield / "then we use it".** After the one boot step the Run must stay live and
    interactive. The Run House + its Lies/Lang workers persist (nothing tears them down — `Story`
     only drops H:Story on a *new* activation). Open question: does the editor stay responsive on
      `Run.c.no_ambient=true` via interaction-poked think, or does a "boot story → re-enable ambient
       tick, stop story_drive" mode need adding to `story_drive`? Verify on :9091 first.
 - **step count / mode.** `toc.snap` has one `step,dige` (a lie dige). Confirm it runs exactly the
    one step then settles; Accept/Resnapture to record the real dige.
 - **re-activation landmine (pre-existing, not ours):** `Auto.svelte` `auto_reset_story` has
    `throw "forgot A"` in the existing-H:Story teardown loop — switching Books after one is up will
     throw. First boot (no existing Story) is fine; fix before relying on Book-switching.

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

## The channel is Peeroleum's heading 10 (settled — see Peeroleum_handover.md)

The editor↔runner handoff is NOT a bespoke socket — it is the **first customer of Peeroleum's real
 websocket transport** (heading 10). The `.go` bytes ride `dock_push` frames editor→runner, run results
  ride `run_result` runner→editor, over the one envelope/transport/ack machinery. The dispatch seam is
   `Peeroleum_on(w,type,fn)`; Lies registers `dock_push`/`run_result`, gated on peer-ready (`%Pier`
    handshake-finished). Topology: both servers on localhost, each browser → own-origin `/relay`, the two
     relays bridge server-to-server (no CORS) over plain ws to the editor's domain; role is browser-commanded
      and set-once (`Lies%runner` compels its server to become the runner-server and dials the editor once).
       The full settled design — topology, two-AP routing, structural loop-safety, the four asks, v1
        trust-everything — lives under **heading 10** in `Peeroleum_handover.md`.
