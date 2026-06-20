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
      `Ghost/Net/Easy`). The Book itself is `wormhole/Story/Editron/toc.snap` (one step; no own Cyto, the default now).
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
- **`feebly_i_elvisto(target,method,extra)`** (`Housing`) — best-effort `i_elvisto`, no-op if no target A is up
   the tree. The Lies→Lang pokes (`Lang_workon_update`, `dock_content`, `Lies_waft_mutated`,
    `Lies_compile_settled`) route through it, so a runner with no Lang doesn't throw.
- **`lang-compile --write`** writes the gen `.go` from the CLI (UIless *compile*) — kills the "recompile in
   the editor" manual step. Still NOT the UIless *include* (running the `.go`'s eatfunc headless) — that's
    the open blocker in `Everything_todo.md`; the runner stays a browser tab.

## 5c. The Editron final stretch — the three moves left

1. **Fix the compile boomerang** (§5 fix-first). DONE for the wedge: the `req:compile` in-flight guard that
    never cleared (trickle spinning on a stuck pending — the `🔥` log) is fixed. Demoting the trickle itself
     to a reason-driven wake is the remaining tidy.
2. **Phase 1 — assure the editor of whole Story runs remotely** (the live front). MOSTLY DONE: the
    `active_transport` keystone is live; the editor↔runner loop crosses both tabs; acquire-then-poll
     converges across an HMR (`↻ rungo … ⏳→✓`); the run fires and `run_result` returns. The verdict is now
      REAL — reported from `storyFinished` (`Lies_runner_verdict` → `Cred_run_outcome`), not the old
       provisional `ok:true` at FIRE (§6). Left: wire `mode` across (still editor-local — `run_arm{mode}`
        doesn't cross; add it to the Rungo + branch in `req_rungo` → `Lies_drive_run(w,path,mode)`), and
         re-record the stale `toc.snap`s (Editron/Peregrination mismatch every step, so the now-honest badge
          reads red until they're re-recorded). Caveat unchanged: headless is blocked on the include problem,
           so "remotely" = a second browser tab, not node (v1).
3. **Phase 2 — in the Waft as Funkcions, red|green.** Spec'd in §5d below. Triggering is solved; the unbuilt
    bit is the binding (Story step/run-result → Funkcion pass/fail → red|green decoration). **Partial landed:**
     the editor's `.ls-health` card is now the at-a-glance verdict — step-level `{passed}/{total} {Book}`
      (e.g. `2/5 Peregrination`), green only when every step passed, open by default (`Liesui.svelte`). This is
       the reusable cell decoration the Waft Funkcions will wear (§5e "matrix IS a Waft"); the `book` field now
        rides the `%run_result` wire to label the row. The dock-level all-or-nothing badge that read a misleading
         `0/1 docks green` for a partial pass is gone — step granularity is the honest read.

Then return to Interest.

## 5d. Phase 2 — Funkcions go red|green

Destination: a Waft's embedded Funkcions show a pass/fail colour, so the Waft reads as a board of live test
 lights. The three seams that were open here are now resolved by the framework below — the **mapping key** is
  the Funkcion's `%of_Book`/`%of_dock` binding; the **colour** comes from a *separate* off-snap
   `funk.c.verdict` (not the per-tick `req.sc.ok`, which only means "the run closure executed" — conflating
    them would lose broken-Funkcion vs failing-test); the **decoration** is the kind's own component (the
     Langui good/bad/working idiom, `working` = awaiting a verdict). The Interest-driven runstate
      (start/pause/poke from the cursored region, §201) stays future — these cells are plain buttons for now.

**LANDED — the Funkcion framework + the Credence cell.** A `%Funkcion`'s mainkey value is its **kind**;
a kind is a self-contained module under `O/Funk/`, registered in `O/Funk/kinds.ts` as `{ run?, component }`.
The host stays generic:

- **`Waft.svelte`** mounts `<FunkHost>` for any `%Funkcion` (or legacy `%havoc`) and knows nothing else —
   it is the host of the whole editable web, ignorant of any one applet.
- **`FunkHost.svelte`** dispatches on kind to the kind's own component; an unknown kind renders a bare line.
- **The pump is ours.** The `req:Funkcion`s live in a `%Funkcions` container (`funks.c.up = w` hand-stamped),
   driven by an explicit `Lies_pump_funkcions` → `funks.do()` in req_Store Phase 2b — *separated from w's
   main req tree*, so we own when/whether they tick. `Lies_instantiate_funkcions` (`LiesStore`) binds each
   *monitor* kind's `run` on Waft load + on `watch_c` mutation (a UI-authored cell binds too). `funk_id` keys
   on the funk's structural `c.Dip` (the waftid slot `Waft_dip` stamps on every Waft** particle), so sibling
   cells of one kind get distinct reqs without leaking kind-vocabulary into the host.
- **Monitor vs action** is the whole taxonomy: `run` present = a **monitor** (pumped); `run` absent = an
   **action** (struck on click). Adding a kind = one `O/Funk/<Kind>.svelte` + one registry line.

**Kinds today:**
- **`Storying`** — a *monitor*. Bound to a Book (`%of_Book`) or dock (`%of_dock`), `storying_run` finds the
   matching `%run_result` (by `book`, latest by `at`, since one Book runs several docks; or by dock `path`)
   and stamps a *separate* off-snap `funk.c.verdict={phase,pass,total,dige}` (NOT `req.sc.ok`; per-step
   `round(ok_pct*done)/done`). Its component shows the ✓/✗/◴ light and, on click, launches a run.
- **`Ballistics`** — an *action*. The havoc drum-pad, struck on demand (`e_Lies_strike` → a Lies/Store limb).
   `%havoc:<kind>` is folded into `Funkcion:Ballistics,kind:<kind>` (only InterestLive used it — limb
   `surprise_read`, fabricate a disk-diverged-under-edit on the active dock).

**Run, wired both ways** (a click on a Storying cell):
- A **dock** cell → `Lies_run_arm{of_dock}` (the Esc "run it now" intent).
- A **Book** cell → `e_Lies_become_book` → the editor ships a `become_book` frame; the runner
   `resetStory{Book}`s and the `storyFinished → Lies_runner_verdict → run_result` loop reports back,
   Book-keyed (`Lies_run_result_recv` accepts a no-dock result as `Book:<name>`). **Repeated Book switches
   are now safe** — `Auto.auto_reset_story`'s old `throw "forgot A"` (the existing-`H:Story` teardown loop
   iterating `existing.o({w:1})` directly, finding no `w`) is fixed: it now walks `A → w → run`, stopping
   each drive before teardown. So the sequencing driver (StoryTimes, §5f) is unblocked.

**The board.** `wormhole/Credence/toc.snap` = `Waft:Credence`, Book-bound + What-grouped to mirror the
Library: `Peregrination | Lake{Surfer,Nets,Flush} | Leaf{Farm,Juggle} | Port{Plan,Planet,Plant} |
Stuff{Flipping,Resolving} | LangTiles` (the substantive Books — the rest are R&D husks, [[story-books-catalog]]).
Open via Liesui `+Waft → Credence`; a fresh cell shows `◴ working`, greening/redding when its Book's
`run_result` lands. **These cells are buttons** — they don't auto-run, so `%run_when` is dropped: each
monitors a verdict and launches a *single* run on click. The fan-out "run them all" is `StoryTimes` (§5f);
the per-row `book × dock` matrix is still deferred.

## 5e. Credence — the editor-side admirer (the Creduler's opposite)

The Creduler accrues credibility (Credulate HEAD + Credulation trail) but today nothing reads it back —
 the soul is spooled write-only. **Credence** is the missing other half: the editor-side board that
  acquires and admires those Credulations. (Supersedes §6's one-line "Editor-side Cred Waft".)

- **A plain Waft, NOT an Interest.** `Waft:Credence` sits above the doc under test (e.g. above
   `Waft:Ghost/Net/Easy`). You navigate to it and click — direct manipulation, not cursored attention — so
    it forgoes the Interest channel entirely. Relevance here comes from runs (the matrix), not the cursor.
- **Inline Funkcions ↔ editable C (the per-What negotiation).** A What full of Funkcions reads best as its
   illusions *flowed inline*, not a bullet list of structural rows.  `Waft_dip` stamps `c.inlined` on such a
    What at load (a suggestion; an author forces it with `%What:Label,inline`), and `Waft.svelte` lays an
     inlined What out as a compact flow of live cells.  The illusion carries its own affordance — a `✎` on the
      What — that flips it to the conventional bullet C**, where each Funkcion node renders as a plain editable
       PeelInput row (`raw_props`: depeel idle → peel back into the funk's `sc`, mainkey is whatever you type);
        `◉` restores the live inline flow.  So the two halves of the illusion are (1) toggling the suggested
         inline and (2) editing the Funkcion node itself — no separate dis-illusion chrome, no per-node handle.
          `struct_what` holds the session's flipped Whats.  (Earlier tri-state per-node "view source" handle was
           too much structure by default — replaced by this.)
- **Tests = Library Books, as Funkcions.** DONE for the single-run: a hand-made `Waft:Credence` holds the
   Books as `Funkcion:Storying` test-lights (§5d), each a button that runs its one Book on click. The
    group fan-out — one click runs every Book under a What in sequence — is `Funkcion:StoryTimes` (§5f).
- **The matrix — the artifact, NOT a hoard of run instances.** Rows = Books (tests), columns = Docs
   (ghosts), each cell = `{relevant?, version(dige), verdict}`. The snaps stay on the runner
    (`Story/This`); Credence holds only the matrix — light, editor-side — and pulls a snap across on demand
     to diff a cell. Relevancy is **observed** from runs (the Creduler's `GhostInclude` + the rungo
      `demands` know what loaded), with a **declared** seed (a Funkcion's `%of_dock`/Books) so a never-run
       test still shows its column.
- **Nondeterminism is a cell property**, not a trail scan: a cell seen both ✓ and ✗ at the SAME
   version-set (see the §6 start==end guard — drift must not masquerade as nondeterminism).
- **Progress relay (optional, on top of the big-ok).** Story already emits
   `story_analysis {the_steps,live,frontier}` per tick; the Creduler relays it as a lightweight `run_phase`
    frame so a Funkcion shows `◴ 3/5` rather than a bare spinner. The load-bearing signal is still the
     final verdict (Phase 1, done); this is garnish.

**Driving the runner from Credence — Book becomes runtime, persisted, remotely set.** Clicking a `Port*`
 test must point the runner at that Book WITHOUT touching the URL (`?B=` is a crusty boot-only seed).
- The command is editor→runner "become Book X" → the runner runs `resetStory{Book:X}`. **Enabler landed
   this session:** `resetStory` now works on a runner with no Library (`Auto.svelte` — lifted out of
    `if (Li)`, Book off the event or `H.c.book`), so the path the click needs already fires.
- **Persist the current Book** to `localStorage` (per-origin — fits "one runner chrome shared on a dev
   machine"); NOT OPFS (forbidden under `?B=`/`?E=` dev boot, [[opfs-illegal-under-dev-boot]]). Precedence:
    persisted current-book > `?B=` seed; `?B=` degrades to first-time seed / hard override. A refresh then
     returns to the remote-controlled state (the cred ledger is already persisted), so the shared runner
      tab resumes where you left it.

**Build order:** (a) Funkcion→Book/dock bind (§5d first slice) — **DONE**; (b) editor→runner "become Book"
 frame — **DONE** (click a Book cell), `localStorage` persist still open; (c) `StoryTimes` the run-all sweep
  (§5f) — **DONE** (single-runner width; the fan-out seam is `ADDRESSABLE`); (d) the start==end version guard
   feeding the matrix; (e) the `run_phase` progress relay last.

**The matrix IS a Waft — don't build a grid widget.** The instinct to render an HTML `<table>` is the
 wrong altitude; the matrix is already the Waft you navigate. The minimal honest shape, all in existing
  particles, ≤20 lines of *display*:
- **A cell is a `%run_result`.** The verdict wire already lands `%run_result{path}` on the editor's
   `w:Lies` carrying `ok_pct`/`done`/`dige`/`book` (the `book` field landed with the `.ls-health` step
    badge — `Lies_report_result`→`Lies_run_result_recv`). Row = `book`, column = `path` (the Doc), value =
     `{dige, ok_pct, done}`. The grid is `run_results` grouped by `(book, path)` — a `$derived`, not a store.
- **The cell colour is the `.ls-health` step badge, reused.** `{rr_pass}/{rr_total}` green-when-equal is the
   cell; the matrix is just that chip laid out `book × path`. One Funkcion per row (§5d first slice) reads
    its row's `run_result` and colours its embed — the Funkcion IS the cell, so the "grid" is whatever
     layout the Waft gives its Funkcions. No table.
- **Nondeterminism / relevancy ride as cell sc, not new structure.** Seen-both-✓-and-✗-at-one-`dige` is a
   flag on the `%run_result` (set when a second verdict for the same `(book,path,dige)` disagrees — guard
    with the §6 start==end check so HMR-drift isn't mistaken for it). Relevancy is "this `(book,path)` pair
     has a `run_result` at all" (observed) ∪ a Funkcion's declared `%of_dock` (so a never-run column shows).
- **First build = the §5d first slice, unchanged.** One Funkcion, `%of_dock:<path>`, reads that dock's
   `%run_result` and shows the step badge red|green|working. The matrix is N of those on one `Waft:Credence`;
    nothing matrix-specific exists until per-row grouping is needed, and even then it's a `$derived` group-by.

## 5f. StoryTimes — the run-all station (LANDED, the Credulation sweep)

The `Storying` cells are *individual* run buttons: click one, that Book runs on the runner and its light
settles — single runs you play with. **`Funkcion:StoryTimes`** is the *station*: one button that runs **all
the `%of_Book` cells in its scope, in sequence**, never stopping for an `!ok` — just recording which passed
and which failed. That sweep IS the Credulation stationing: a full board pass at one sitting.

**BUILT.** `O/Funk/StoryTimes.svelte` (the kind) + `Lies_storytimes_drive` and helpers in `LiesWaft.svelte`
(the sequencer), registered in `O/Funk/kinds.ts`. `Waft:Credence` now carries a per-What station (the first
child of each `What:*`) plus a board-wide `Funkcion:StoryTimes,all:1` at the Waft root.

- **Scope = its containing `What`** (or the whole Waft for `%all` / a Waft-root station). Credence is already
   `Waft/What/*`-grouped, so a station scans its scope's descendants for `%of_Book` Storying cells and runs
    them in order (`Lies_storytimes_books`/`Lies_storytimes_scope_c`). A What-level station sweeps that group
     (`What:Lake` → the three Lake Books); the `%all` board-level one sweeps every What.
- **A monitor kind whose pumped `run` IS the sequencer.** Not an action (despite *feeling* like a button):
   a fire-and-forget click can't chain N become_books, because the runner is one *sequential* Story Run that
    `resetStory`s on each switch — a second become_book mid-run would clobber the first. So the click only
     *arms* (`funk.c.sweep={phase:'arm'}`); the central Funkcions pump ticks `storytimes_run` → `Lies_storytimes_-
      drive`, which builds the queue, dispatches become_book, and **advances on each `run_result`** (book-keyed,
       newer-than-dispatch), recording the verdict and proceeding regardless of pass/fail. A 60s per-Book
        timeout fails-and-advances so a stalled runner can't wedge the board. All state rides off-snap on
         `funk.c.sweep` (`{phase,queue,inflight,results,total}`) — inspectable, never persisted.
- **Runners on the phone — the in-flight width.** `Lies_runner_count(w)` reports however many runner Piers
   are connected (shown on the station as `⌥N`). The sweep keeps `Lies_storytimes_width(w)` Books in flight.
    **Today that width is capped at 1** (`ADDRESSABLE=1`): a `become_book` is a single-address broadcast to the
     one bridged runner — the frame carries no per-runner `to` (§7) — so two at once would reset that runner
      mid-run. **The fan-out seam is one constant:** when the channel carries a runner address, lift
       `ADDRESSABLE` to `Lies_runner_count(w)` and the same driver dispatches across the fleet, the round of
        cell-lights filling in parallel. (Each switch tears down + rebuilds the Story Run, so a sweep of 11
         Books on one runner is 11 teardowns — thorough, not fast; fanning across runners is the speedup.)
- **Feeds the matrix.** A sweep populates a whole Credence row at a known version-set — exactly the
   `book × dock` matrix's input; the §6 start==end version guard gates whether a sweep's verdicts are
    trustworthy or HMR-drifted.

**Vision — Funkcions as public-sphere infra.** A Credence board is a small instance of a larger pattern:
embedded buttons in a shared document that **switch server-side functionality on**. "Click a test to run it
on the runner" generalises to *people voting to activate a capability* — the Waft is the public surface, the
Funkcion the franchise, the runner the server that acts. Worth holding in view as the channel hardens
(trust/addressing, §4 / Peeroleum heading 11): *who may strike which Funkcion* becomes a permissions
question, not just a test-runner one. The Funkcion taxonomy already has the seam — a monitor reads, an
action acts; an action that acts on the *server* is the franchise.

## 6. Creduler — open slices

The Creduler is credibility of code over runs. Its missing half is **a runner that drives a Story to a
 real verdict and reports it** — which is exactly the Story `req:Step`/`req:Drive` recast + UIless run
  (`Story_next_level_spec.md` §15–16, `Story_cli_docs.md` for the working node harness). Treat that
   thread as the Creduler runner, not a separate Story effort — it is the highest-leverage move
    (`Everything_todo.md`).

- **storyFinished verdict → `run_result`: DONE.** `req_rungo` FIRE stashes `awaiting_verdict{path,dige}`;
   `Lies_runner_verdict` reports `Cred_run_outcome` from the `storyFinished` runner branch (Auto), threading
    `ok_pct`/`done` to the badge. (The deeper UIless `req:Step`/`req:Drive` recast for a headless verdict is
     still the open Creduler half.)
- **git seam:** a relay endpoint (path+dige → committed? + enclosing rev), then group `Credulation` by
   git rev. `Cred*.snap` are Lines-encoded now; commit-status still stubbed null. (The overlay
    write-verdict pattern — write to sandbox every run, commit on acceptance — already exists in the
     Wormhole backends; reuse it.)
- **Nondeterminism** is a Credence cell (§5e) seen both ✓ and ✗ at the SAME version-set. Guard: capture the
   version-set at the START and END of a run — start ≠ end means a version drifted mid-run (an HMR landed),
    so the verdict is suspect (discard / re-run, don't record); only start == end with a differing outcome
     is true nondeterminism. Don't conflate drift with nondeterminism.
- **Editor-side Cred Waft** — now specced as **Credence** (§5e): the board that reads the Credulations the
   Creduler spools. Expands to list runners, normally collapsed.
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
   many-runners fan-out — the frame needs a per-runner `to` so the editor can address one of several
    connected runners (`dock_push`/Rungo/`become_book` per runner). StoryTimes (§5f) is already written to
     fan out across the fleet; it's gated only by `ADDRESSABLE=1` until that addressing lands. `Thangs`
      persistence of who's allowed (Peeroleum heading 11).
- Loose ends: stray `debugger` at `Housing.svelte.ts:1852`; the `ack seq=undefined DROPPED` after each
   HMR (channel re-establish — separate from latency).

## Verify-in-app (browser-only)
- **boot-yield.** After the one boot step the Run must stay live + interactive. Open question: does the
   editor stay responsive on `Run.c.no_ambient=true` via interaction-poked think, or does a "boot story
    → re-enable ambient tick, stop story_drive" mode need adding to `story_drive`? Verify on :9091.
- **step count / mode.** `toc.snap` has one `step,dige` (a lie dige). Confirm it runs exactly one step
   then settles; Accept/Resnapture to record the real dige.
- **re-activation landmine (FIXED):** `Auto.svelte` `auto_reset_story` no longer `throw`s `"forgot A"` —
   the teardown loop now walks `A → w → run` (it had iterated `existing.o({w:1})` directly, found no `w`,
    and threw on every Book-switch / from-start reset). Book-switching and the StoryTimes sweep (§5f) are
     safe.
