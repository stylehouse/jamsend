# Editron — the editor↔runner channel & Creduler

Editor (`Lies%editor`, the Editron Book) edits a `.g`; a runner (`Lies%runner`) acquires
 that version, runs it, and reports back. Two origins, Peeroleum's real websocket as the wire,
  a relay per origin bridged server-to-server. **The channel carries and the round-trip is fast
   (~0.5s edit→green).** What remains is the *Creduler* (credibility of code over runs) and
    shaving the last compile latency.

This doc merges the three former Editron handovers into one arc: **architecture → the channel
 contract → the session that made it fast → the bombs → what's left**. The transport spine it
  rides lives in `Peeroleum_spec.md`/`Peeroleum_handover.md` (heading 10); this is the Lies/Editron
   side. Editron is the **Atime expression** of the `%subscribe` wire (`Wire_spec.md`); Interest is
    its UItime sibling — they share the subscribe/wake vocabulary, not a merge.

## 1. Architecture — the editor is a Story Book; the Pantheate split

**The editor runs as a Story Book, not a top-level world.** `?B=Editron` (parsed in Otro via
 `boot_param`; `B=` env in node) stamps `H.c.book`; `A=Auto` reads it on first boot and activates
  the Editron Book. `Story_subHouse` stands up the Run via **`Run_A_Editron`** (the `Run_A_<Book>`
   recipe, mirroring `Run_A_Peregrination`), which lays `A:Editron/w:Editron` + `Lies%editor` +
    `Lang%editor` (+ Pantheate) INTO the Run. The per-beat handler `Editron(A,w)` (both in
     `src/lib/O/Editron.svelte`) opens the Waft named by `?W=<Waft>` (env `W=`, default
      `Ghost/Net/Easy`). The Book itself is `wormhole/Story/Editron/toc.snap` (one step + `Opt/noCyto`).
 Boot it: `/Otro?B=Editron` (`&W=<Waft>` for a different Waft).

**Why a Book:** running the editor's own startup AS a Story makes boot one observable, re-runnable
 step — if the editor breaks, re-run the Book and read the step snap to see how far boot got. First
  of the "runtime stories"; diagnostics are Story-based.

**The Pantheate split — editor compiles, runner runs.** Editron edits a Waft; it must NOT *run* it.
 Compiling a `.g` in the editor writes the `.go` and stops — the editor's Pantheate must not import +
  mount the compiled module, or the editor would run the code itself. The `.go` lands in the shared
   dev repo; the runner instance picks it up and runs the test.
 The compile→include chain is in LiesCortex: `e_Lies_compiled` writes the gen via `req:Codebit`; on
  `write_finished` it fires `i_elvisto('Pantheate/Pantheate','Ghost_update_notify',…)`, which
   dynamic-imports the `.go`, mounts it as a `UI:'Pantheate-include'` component, and `req:include`
    polls `H[Ghostmeta_…]()`. The gate that stops the editor taking up the code is **on the Run's
     role, not the per-`w` flag** (Pantheate's own `w` carries neither flag): `Run_A_Editron`/
      `Run_A_Peregrination` stamp `H.c.role='editor'|'runner'`, and the predicate lives in one place —
       `LiesLies.svelte` (`Lies_role`/`Lies_is_editor`/`Lies_is_runner`, three-state so a *bare* Lies
        — the plain app, Machinery test Runs — still mounts). `req_Codebit` fires the notify only when
         `!H.Lies_is_editor()`. `editor:1`/`runner:1` are the explicit counterparts; the scattered
          `w.sc.runner` reads now route through `Lies_is_runner`.

**Cross-instance.** Editor and runner are *different servers* — separate Houses, no shared `eatfunc`,
 no shared OPFS (it's per-origin; `localhost` ≠ the public domain). So the channel must **carry the
  bytes**, not poke a "re-read" — there is no common disk. The handoff is the `.go`/`.g` *over the
   wire* plus a *signal*. Browser↔browser is CORS-blocked, but each instance's node server can message
    server-to-server (a cross-origin **WebSocket** is not fetch-CORS-gated).

## 2. The channel — Peeroleum heading 10, relay on the editor's server

The editor↔runner handoff is the **first customer of Peeroleum's real websocket transport**, not a
 bespoke socket. Topology: both servers on localhost / the public domain; each browser connects to
  its own-origin `/relay`; the two relays bridge server-to-server (no CORS) over plain ws to the
   editor's domain; role is browser-commanded and set-once (`Lies%runner` compels its server to become
    the runner-server and dials the editor once). The relay forwards a signed frame by `header.to`
     without parsing `body`. WebRTC (heading 9) is worse here — the PeerJS broker is derived from
      `location.host`, so two origins never meet; the fixed editor-server endpoint sidesteps NAT and
       discovery entirely.

**The four asks of Peeroleum** (full settled design under heading 10 there):
1. **App-frame dispatch seam.** `Peeroleum_deliver` routes registered app `header.type`s to a
    consumer handler (`Peeroleum_on(type, fn)`) instead of the hardcoded `hear_*`, keeping the inbox
     `verified→done|error` lifecycle, acks, and `%faulty` rollup. Lets the music app and Lies share one
      bus; the spine stays domain-free.
2. **A public emit** — `Peeroleum_send(w, frame)` (or `%req:send`). We *want* the ack (it tells the
    editor the runner received the source). If `%req:send` is the surface, mind the **c.up rule**: a
     Pier-hosted req silently never pumps unless `Pier.c.up=Peering; Peering.c.up=w` is stamped.
3. **A watchable peer-ready signal** — the existing `%Pier … handshake,finished` (or `%Pier` +
    `%active_transport,open`) is enough; an explicit `%peer,ready` marker would be a nicety.
4. **The real ws transport on the editor's node server.** `body` is opaque text (the `.g`/result snap;
    binary/chunking is heading 7, not needed yet). **Caution:** the half-removed `socket.io`
     scaffolding in `vite.config.server.js` is a phantom — `socket.io` is not installed, `server.ts`
      doesn't exist, `server.js` is a bare static+health Express server. Treat the ws layer as greenfield.

**Frame types Lies registers** (plain-text bodies):
```
dock_push   editor → runner   body: { path, source, dige }       — superseded by Rungo, see §3
run_result  runner → editor   body: { path, dige, ok, errors[], snap_dige }
```
Editor emit fires on the save signal (`write_finished`) when `w%editor`. Runner receive feeds the drain
 the spine already has: `LiesStore_good` → `LiesStore_land_good` (sets content, re-digests `/known`) →
  `LiesStore_drain_good` (re-pushes to Lang's subscriber → recompile → because `w%runner`, mount + run).
   No new pipeline on our side. Result home re-attaches `run_result` to the editor's `Codebit%of_dock`
    so the staging chrome lights up.

## 3. The arc that made it fast (~10s → ~0.5s edit→green)

1. **dock_push → Rungo.** A Rungo is the *authority to run*, carrying `header.seq` (the authority
    token; a fresh seq re-authorises a run even of unchanged code) and `demands:[{path,dige}]` (many
     ghost demands, all must be live first; single today, the list is the multi-ghost seam). Keyed
      `req:rungo,seq`; higher seq supersedes a still-waiting lower; spent rungos dropped.
       (`LiesLies.svelte`, caller `LiesCortex.e_Lies_compiled`.)
2. **Permission-first.** The Rungo leaves *before* the write, so it crosses the slow relay while the
    `.go` is written + HMR'd locally — they converge instead of the channel RTT trickling on after.
3. **gen-write via the relay.** The browser's File-System-Access `.go` write cost ~463ms. The editor
    now ships the `.go` down its relay socket as `{control:'gen_write',path,body}`; `relay.ts` (Node,
     has fs) validates the path (`gen/**.go` under `resolve('src/lib/gen')`, no traversal, ≤5MB) and
      `fs.writeFile`s it in **~3–6ms**. Vite HMRs it to both origins. When relayed there's no
       LiesStore_write req for phase-1 to hand off, so `e_Lies_compiled` stamps the Codebit's
        `write_finished` itself (optimistic settle). Falls back to FSA if the ws is down.
4. **Channel freeze (transport self-edit flap).** Editing `Peeroleum.g` HMR-reloaded the editor's
    *own* transport (`channel down / re-establishing` after every haunt), and the settle tick rode that
     transport. Froze the working spine+carriers to `src/lib/p2p/transport/*.go`; the channel imports
      the frozen copy, so the live `gen/N/Peeroleum.go` is no longer in the editor's Vite graph →
       editing it HMRs nothing there. (`LiesLies.Lies_transport_up`.)
5. **The 5s hang → trickle-think (see the bomb below).** `feebly_ponder` is Runtime-gated, so on an
    idle Creduler the just-landed code can sit ~5s before anything re-pumps. `req:rungo`/`req:compile`
     carry an ungated paced re-check. *(This is the 150ms busy-poll the owner wants replaced with a
      single event-wake — see §5.)*
6. **.g-only compile gate.** `req_compile` + `Lang_compile_dock` bail unless `Lies_gen_path(path)` is
    defined (a `.g` under `Ghost/`). Killed the soft-parse on non-.g and an infinite `waiting:parser`
     hang on a no-grammar file. (`Lang.svelte`, `LangCompiling.svelte`.)
7. **Cred\*.snap Lines-encoded**, `disk_dige` stamped at settle, `dim:false`→`1|absent`, `tlog`
    timestamped perf logs.

## 4. The bombs — knowledge that, missing, dooms the next session

- **`%ttlilt` is NOT a keep-alive.** One-shot snap-timing advisor; re-arming is a no-op, it never
   re-fires think. Any req that bows out on a ttlilt needs *something else* to re-pump it. The
    **trickle** (ungated paced `i_elvisto(w,'think')`) is the current fix shape in `req_rungo` AND
     `req_compile`. `feebly_ponder` is Runtime-gated (`if(!this.c.runtime)return`) → a no-op on idle
      ambient Houses, which is why settles/rungos stalled ~5s.
- **The editor compiles `gen/N/Peeroleum.go` but never *imports* it** (Pantheate split: editor
   compiles, never runs). That's why freezing the channel onto `p2p/transport/*.go` fully insulates the
    editor. **Promote a new spine into the channel by hand-copying** `gen/N/*.go → p2p/transport/*.go`.
     The frozen copies are deliberately stale until you do.
- **Runner global-deposit caveat (unverified).** The runner's Story test may still mount the live
   `gen/N/Peeroleum.go`, whose eatfunc deposits `Peeroleum_send` etc. **globally** (`ghostsHaunt` → all
    houses), overwriting the frozen channel methods on the runner. Editor is fully decoupled; runner
     isolation is the deeper "dogfooded someday" piece. Check whether Peregrination still mounts
      Peeroleum globally.
- **`relay.ts` is Node server code.** HMR never touches it, but it's a direct import of
   `vite.config.ts`, so Vite **auto-restarts** the dev server on edit. If `✍ gen_write` never appears
    after a compile, it didn't restart — `touch vite.config.ts`. Control frames stay editor→its-own-relay
     (`handleControl`).
- **Snapped booleans = `1` or absent, never `false`/`0`** (now CLAUDE.md policy). Prefer delete over 0,
   a C method (`r()`/`roai` replace) over raw `delete n.sc.key`.
- **`mode` is still editor-local.** `run_arm{mode}` doesn't cross; the runner runs `in_place` by
   default. To wire `from_start` across, add `mode` to the Rungo (or a dedicated frame) + branch in
    `req_rungo` → `Lies_drive_run(w, path, mode)`. The editor side exists: Esc arms a run (`Lies_run_arm`),
     stamping `w%run_arm{path,mode}` and, on a runner, invalidating the dock's Good + resuming (in-place)
      or resetting (from-start, the `Story_reset` path).
- **The UIless-include problem (runner side).** Pantheate mounts the gen as a UI component whose
   `onMount`→`eatfunc` injects `Ghostmeta`; UIless renders no UIs, so the runner's `req:include` ttlilt
    times out at `waiting:ghostmeta`. A UIless run can't yet mount a fresh `.go`. For v1 the runner is a
     dev browser tab; the channel is identical either way — only the last hop (which House terminates it)
      changes when the UIless runner (Peeroleum heading 1b / Story §16) lands. This is the prerequisite
       for the runner side actually executing pushed code, and it ties into the Creduler (§6).

## 5. The compile boomerang & the trickle — the live latency thread

- **Cause A (handled):** missed re-pump after `pending` clears → `req_compile` stayed `firing`. The
   trickle catches it.
- **Cause B (handled):** the transport self-edit flap (§3.4). The channel freeze should kill it for the
   editor.
- **The trickle itself is a busy-poll the owner wants gone.** Both `req_rungo` (`LiesLies.svelte`) and
   `req_compile` (`Lang.svelte`) bow out on a ttlilt and re-arm a `setTimeout(150ms)→i_elvisto(w,'think')`.
    Each fire is a full `beliefs()` pass; a rungo waiting 20s is ~130 passes, and a wedged req polls
     forever at ~7Hz — the CPU burn. **The event-driven wake it polls for largely already exists:**
      `Lang_drain_compile_settles` calls `H.main()` (not Runtime-gated) when a settle arrives, and
       `e_Lies_compiled`/`Lies_compile_settled` fire `i_elvisto(w,'think')`. The two gaps that make the
        poll a fallback are: (a) `LiesStore.svelte:491` stamps `write_finished` with no wake (the
         prime boomerang suspect — add a `feebly_ponder`/think + `tlog` there); (b)
          `Ghost_version_checkin → feebly_ponder` is Runtime-gated, so an idle runner's checkin wakes
           nothing — wake w:Lies ungated for the runner role (scoped, not a blanket ungate; the gate
            protects Story snap-timing). With those, delete the repeating trickle or demote it to a
             single ~1s safety fire.
- **Landed since:** the `LiesStore.svelte:491` `write_finished` wake (ungated `i_elvisto(w,'think')` +
   `tlog`) is in. Both trickles now **shout every 10th spin** (`🔥 … burning CPU` — `req_compile` in
    `Lang.svelte`, `req_rungo` in `LiesLies.svelte`), so a wedged spin is visible, not silent — grep `🔥`.
  **NEXT MOVE (the Editron final-stretch fix-first):** if `🔥` still fires after the wake, the spin is the
   write→Codebit handoff or gap (b) — `Ghost_version_checkin → feebly_ponder` is Runtime-gated, so an idle
    runner's checkin wakes nothing (wake `w:Lies` ungated for the runner role, scoped). Then delete the
     repeating trickle or demote it to a single ~1s safety fire. The `🔥` decoration is the instrument;
      killing the spin is the work.

## 5b. The runner model (current) — Creduler bootstrap; the runner runs the LIVE spine

This is the big shift from §1's "Pantheate include in the Run". The runner no longer compiles or includes
 inside its Story Run; it **acquires** what the editor shipped, bootstrapped from the top House.

- **`Peregrination.svelte` is deleted.** `Ghost/Story/Peregrination.g` IS the Book now: it defines
   `Run_A_Peregrination()` (the Run recipe — lays `A:Peregrination/w:Peregrination`) and `Peregrination(A,w)`
    (the per-beat handler, renamed from `LakeNetherland` — `w:Peregrination` resolves straight to it). No
     hand-written bootstrap, no call-through.
- **The Creduler is the bootstrap.** `Auto.svelte` stands up the Mundo runner Lies (`w:Lies{runner,creduler}`,
   "outside Story"). Its tick drives **`Creduler_ensure()`** (`LiesLies.svelte`): load every `.g` in
    **`CREDULER_GHOSTS`** (the runner's include manifest — grouped Ghost.svelte-style; add a line to extend)
     LIVE onto H via **`Lies_ghost_load`** (enrol the gen `.go` in `watched:UIs` → Otro mounts → `onMount`
      eatfunc deposits methods + `Ghostmeta`), riding **`%Creduler_pending`** on H while it works.
- **Story kickoff gates on `%Creduler_pending`.** `Story.svelte` top: `if (H.oa({Creduler_pending:1}))
   return w.i({waits:'loadingcoding'})`. toc may decode; steps don't begin until the ghosts are live and
    `Run_A_Peregrination` is actually on H. (Grep `Creduler_pending` / `loadingcoding`.)
- **Two runner primitives** in `LiesLies` (acquire region): `Lies_ghost_live(path)` = the live `source_dige`
   off `Ghostmeta_<…>()` (presence/currency — `req_rungo` compares it to the demanded dige; the Creduler
    checks presence); `Lies_ghost_load(path)` = the load half above.
- **The runner runs the LIVE spine.** `CREDULER_GHOSTS` includes the transport (`Ghost/N/Peeroleum.g`,
   `Tribunal.g`) as live gen, so the runner tests current code. **`Lies_transport_up` is now EDITOR-ONLY**
    (`role!=='editor'` bails) — the frozen `p2p/transport/*.go` is the editor's bootstrap alone (it can't
     ride the spine it's editing). This fixed the "test ran the frozen `figaro:Sausage` copy" bug. The
      runner's channel flaps on each push — fine, it re-runs. Promote a new spine into the *editor's* channel
       with **`lang-compile --write`** then `cp gen/N/*.go → p2p/transport/`.
- **`feebly_elvisto(target,method,extra)`** (`Housing`) — best-effort `i_elvisto`, no-op if no target A is up
   the tree. The Lies→Lang pokes (`Lang_workon_update`, `dock_content`, `Lies_waft_mutated`,
    `Lies_compile_settled`) route through it, so a runner with no Lang doesn't throw.
- **`lang-compile --write`** writes the gen `.go` from the CLI (UIless *compile*) — kills the "recompile in
   the editor" manual step. Still NOT the UIless *include* (running the `.go`'s eatfunc headless) — that's
    the open blocker in `Everything_todo.md`; the runner stays a browser tab.

## 5c. The Editron final stretch — the three moves left

1. **Fix the compile boomerang** (§5 fix-first). The `🔥` log is now the instrument; kill the spin, then
    delete/demote the trickle.
2. **Phase 1 — assure the editor of whole Story runs remotely** (the live front). Transport is proven; the
    named moves: the version handshake (acquire-then-poll), confirm the run actually fires and `run_result`
     returns, wire `mode` onto `dock_push`. Caveats: the `active_transport` keystone was "start here" (not
      live last anyone looked); headless is blocked on the include problem, so "remotely" = a second browser
       tab, not node (v1, fine — be explicit headless isn't on this path).
3. **Phase 2 — in the Waft as Funkcions, red|green.** Triggering is solved (Funkcions are the Waft's embedded
    applets, Waft_spec §201; the ballistics drum-pad already does struck-on-demand test-trigger Funkcions).
     The unbuilt bit is the **binding**: Story step/run-result → Funkcion pass/fail → red|green decoration.
      `run_result` already threads back to light the staging badge, so the data arrives; surfacing it
       per-Funkcion is new. **Not spec'd anywhere yet — write a short spec note before building.**

Then return to Interest.

## 6. Creduler — open slices

The Creduler is credibility of code over runs. Its missing half is **a runner that drives a Story to a
 real verdict and reports it** — which is exactly the Story `req:Step`/`req:Drive` recast + UIless run
  (`Story_next_level_spec.md` §15–16, `Story_cli_docs.md` for the working node harness). Treat that
   thread as the Creduler runner, not a separate Story effort — it is the highest-leverage move
    (`Everything_todo.md`).

- Report the **real storyFinished verdict** as `run_result` (replace the provisional "acquired=ok" in
   `req_rungo`).
- **git seam:** a relay endpoint (path+dige → committed? + enclosing rev), then group `Credulation` by
   git rev. `Cred*.snap` are Lines-encoded now; commit-status still stubbed null. (The overlay
    write-verdict pattern — write to sandbox every run, commit on acceptance — already exists in the
     Wormhole backends; reuse it.)
- **Nondeterminism** from the trail (same version-set, differing outcomes).
- **Editor-side Cred Waft** (Funkcions) — expands to list runners, normally collapsed.
- `%rungo` dedupe — don't re-run an already-run seq (seq-authority is in place; the guard is NOT wired).

## 7. Other queued (not started)

- **Compile-conditions popover** — SurprisePopover-standardised; surfaces no-parser / incomplete-parse
   (Lezer error nodes) / bad_js as *ignorable* conditions with a **"push illegal JS anyway"** override.
    The Lezer-error-node check also catches the mid-token `figaro:` case that today renders
     valid-but-wrong JS (`{figaro:undefined}`) and pushes garbage past `bad_js`.
- **Strip visuals** — compile leg **dim while compiling** (`pending && !secs`) / **skitsytwisty while
   writing .go** (`pending && secs`); runner **half-pill** expandable to error / Story summary / Story
    diff (content = TODO).
- **non-.g Pointing** — tsstho Points in `.ts`/`.svelte`, markdown Points in the specs, on a
   parse-for-Points-only path that emits NO `.go` (see [[nong-pointing-todo]] + the gate comment in
    Lang.svelte).
- **Deferred for v1:** security/trust *enforcement* (accept the one runner, trust-everything handshake);
   many-runners fan-out (`dock_push`/Rungo per connected runner); `Thangs` persistence of who's allowed
    (Peeroleum heading 11).
- Loose ends: stray `debugger` at `Housing.svelte.ts:1852`; the `ack seq=undefined DROPPED` after each
   HMR (channel re-establish — separate from latency).

## Verify-in-app (browser-only)
- **boot-yield.** After the one boot step the Run must stay live + interactive. Open question: does the
   editor stay responsive on `Run.c.no_ambient=true` via interaction-poked think, or does a "boot story
    → re-enable ambient tick, stop story_drive" mode need adding to `story_drive`? Verify on :9091.
- **step count / mode.** `toc.snap` has one `step,dige` (a lie dige). Confirm it runs exactly one step
   then settles; Accept/Resnapture to record the real dige.
- **re-activation landmine (pre-existing):** `Auto.svelte` `auto_reset_story` has `throw "forgot A"` in
   the existing-H:Story teardown loop — switching Books after one is up will throw. First boot is fine;
    fix before relying on Book-switching.
