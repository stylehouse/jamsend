# Editron — the editor↔runner architecture (Lies side)

The coherent overview of the editor|runner machine: who the two roles are, how code crosses
 between them, how a run is driven and its verdict returned, and how the Credence board reads
  those verdicts back. The transport *spine* lives in `Peeroleum_spec.md` (heading 10); this is
   the Lies/Editron side that rides it. Editron is the **Atime** expression of the `%subscribe`
    wire (`Wire_spec.md`); Interest is its UItime sibling — shared subscribe/wake vocabulary, not
     a merge.

**One sentence.** An editor (`Lies%editor`) edits a `.g`, compiles it to a `.go`, and ships *the
 authority to run it* to a runner (`Lies%runner`) on another origin; the runner acquires that
  version, runs the Story, and reports a real pass/fail verdict back; the **Creduler** accrues
   those verdicts over runs and **Credence** (a Funkcion board) reads them back.

---

## 1. Roles & boot — the editor is a Story Book; the Pantheate split

**The editor runs as a Story Book, not a top-level world.** Boot it `/Otro?E=Editron` (`&W=<Waft>`
 for a different Waft). Otro's `boot_param` parses `?E=<Book>` (editor) / `?B=<Book>` (runner) — the
  `E=`/`B=` env in node — stamping **`H.c.book`** and **`H.c.boot_role='editor'|'runner'`** (the plain
   app stamps neither). A booted role skips the disk **Library** entirely — Auto's `run` page: the
    editor edits a Waft and the runner runs one Book, so neither browses or persists a book library;
     only the plain app loads it. `A=Auto` reads `H.c.book` on first boot and stands the Book up:
      `Story_subHouse` lays the Run via the
    **`Run_A_<Book>`** recipe (`Run_A_Editron` mirrors `Run_A_Peregrination`), which puts
     `A:Editron/w:Editron` + `Lies%editor` + `Lang%editor` (+ Pantheate) INTO the Run. The per-beat
      handler `Editron(A,w)` (`src/lib/O/Editron.svelte`) opens the Waft named by `?W=` (default
       `Ghost/Net/Easy`). The Book itself is `wormhole/Story/Editron/toc.snap` (one step, no own Cyto).

*Why a Book:* running the editor's own startup AS a Story makes boot one observable, re-runnable
 step — if the editor breaks, re-run the Book and read the step snap to see how far boot got.

**How Auto takes params** (the cross-ghost calling convention, worth stating once because the whole
 run lifecycle rides it). A deferred call `i_elvisto(target, method, sc)` lands `sc` as the elvis
  event's `ev.sc`; the handler drains them with `this.o_elvis(w, method)` and reads `ev.sc.<key>`.
   So in `Auto.svelte`:
- **boot** — `H.c.book` (the booted Book) drives the first `picks_a_book → auto_reset_story`,
   **gated on `%Creduler_pending`** (don't build `w:Story` into a half-loaded House — the Creduler
    wakes Auto the moment the spine reads live).
- **`resetStory{Book}`** — NOT Library-gated (a `?B=` runner has no Library): `bname = ev.sc.Book ??
   active Library Book ?? H.c.book`. This is the path a Credence Book-cell click and the StoryTimes
    sweep drive (via `become_book` → `Lies_become_book_drive` → `i_elvisto('Auto/Auto','resetStory',{Book})`).
- **`storyFinished{Book,mode}`** — on a runner (`H.c.boot_role==='runner'`) it `Cred_spool`s the soul
   and calls `Lies_runner_verdict(liesW, bname)` to report the verdict over the channel.

`auto_reset_story(bname)` tears down any existing `H:Story` (walking `A → w → run`, stopping each
 drive first), then `post_do`s a fresh `subHouse('Story')` with `w:Story{Book:bname}`. A Book absent
  from the Library still boots — `Story_subHouse` resolves its `Run_A_<Book>`.

**The Pantheate split — editor compiles, runner runs.** The editor edits a Waft; it must NOT *run*
 it. Compiling a `.g` writes the `.go` and stops — the editor's Pantheate must not import + mount the
  compiled module, or the editor would run the code itself. The gate is **on the Run's role, not a
   per-`w` flag**: `Run_A_Editron`/`Run_A_Peregrination` stamp `H.c.role='editor'|'runner'`, and the
    predicate lives in one place — `LiesLies.svelte` (`Lies_role`/`Lies_is_editor`/`Lies_is_runner`,
     three-state so a *bare* Lies — the plain app, Machinery test Runs — still mounts and runs).
      `req_Codebit` fires the Pantheate include only when `!Lies_is_editor()`. The per-`w`
       `%editor`/`%runner` flags remain as the explicit fallback; scattered `w.sc.runner` reads route
        through `Lies_is_runner`.

**Cross-instance.** Editor and runner are *different servers* — separate Houses, no shared `eatfunc`,
 no shared OPFS (per-origin; `localhost` ≠ the public domain). So the channel must **carry the bytes**,
  not poke a "re-read" — there is no common disk. Browser↔browser is CORS-blocked, but each instance's
   node server can message server-to-server (a cross-origin **WebSocket** is not fetch-CORS-gated).

## 2. The channel — Peeroleum relay, on the editor's server

The editor↔runner handoff is the **first customer of Peeroleum's real websocket transport** (heading
 10 there), not a bespoke socket. Topology: each browser connects to its own-origin `/relay`; the two
  relays bridge server-to-server (no CORS) over plain ws to the editor's domain; role is
   browser-commanded and set-once (`Lies%runner` compels its server to become the runner-server and
    dials the editor once). The relay forwards a signed frame by `header.to` without parsing `body`.
     (WebRTC is worse here — the PeerJS broker derives from `location.host`, so two origins never meet;
      the fixed editor-server endpoint sidesteps NAT and discovery.)

**Lies as a Peeroleum consumer.** `Peeroleum_on(type, fn)` registers a handler; `Peeroleum_send_consumer(w,
 type, body)` emits; the spine keeps the inbox `verified→done|error` lifecycle, acks, and `%faulty`
  rollup, staying domain-free. Frame types Lies registers (plain-text bodies):

```
rungo        editor → runner   { demands: [{path, dige}], header:{seq} }   — the authority to run
become_book  editor → runner   { book }                                    — point the runner at a Book
run_result   runner → editor   { path, dige, ok, ok_pct, done, book, snap_dige, errors }
ping / pong  either            liveness
```

- **A Rungo is the *authority to run***, carrying `header.seq` (a fresh seq re-authorises a run even of
   unchanged code) and `demands:[{path,dige}]` (ghost versions the runner must have live before it runs;
    the list is the multi-ghost seam). Keyed `req:rungo,seq`; higher seq supersedes a still-waiting lower.
     It leaves *before* the write, so it crosses the slow relay while the `.go` is written + HMR'd locally.
      (`LiesLies.svelte`, caller `LiesCortex.e_Lies_compiled`.)
- **gen-write over the relay.** Rather than a ~463ms browser File-System-Access write, the editor ships
   `{control:'gen_write',path,body}` down its relay socket; `relay.ts` (Node, has fs) validates the path
    (`gen/**.go` under `src/lib/gen`, no traversal, ≤5MB) and `fs.writeFile`s it in ~3–6ms; Vite HMRs it to
     both origins. Falls back to FSA if the ws is down.
- **`.g-only compile gate.** `req_compile`/`Lang_compile_dock` bail unless `Lies_gen_path(path)` resolves
   (a `.g` under `Ghost/`) — no soft-parse on non-`.g`.
- **The c.up rule.** A Pier-hosted `%req` silently never pumps unless `Pier.c.up=Peering; Peering.c.up=w`
   is stamped (the A/w spine walk wires only A/w). Bites any send/recv req hung under a Pier.

## 3. The runner model — Creduler bootstrap; the runner runs the LIVE spine

The runner does NOT compile or include inside its Story Run; it **acquires** what the editor shipped,
 bootstrapped from the top House.

- **`Ghost/Story/Peregrination.g` IS the Book** (no `Peregrination.svelte`): it defines
   `Run_A_Peregrination()` (the Run recipe) and `Peregrination(A,w)` (the per-beat handler). No
    hand-written bootstrap, no call-through.
- **The Creduler is the bootstrap.** `Auto.svelte` stands up the Mundo runner Lies
   (`w:Lies{runner,creduler}`, outside Story). Its tick drives **`Creduler_ensure()`** (`LiesLies.svelte`):
    load every `.g` in **`CREDULER_GHOSTS`** (the runner's include manifest — add a line to extend) LIVE
     onto H via **`Lies_ghost_load`** (enrol the gen `.go` in `watched:UIs` → Otro mounts → `onMount` eatfunc
      deposits methods + `Ghostmeta`), riding **`%Creduler_pending`** while it works.
- **Story kickoff gates on `%Creduler_pending`** (`Story.svelte`: `if (H.oa({Creduler_pending:1})) return
   w.i({waits:'loadingcoding'})`) — steps don't begin until the ghosts are live and `Run_A_Peregrination`
    is on H.
- **The runner runs the LIVE spine.** `CREDULER_GHOSTS` includes the transport itself (`Ghost/N/Peeroleum.g`,
   `Tribunal.g`) as live gen, so the runner tests current code. Two acquire primitives in `LiesLies`:
    `Lies_ghost_live(path)` = the live `source_dige` off `Ghostmeta_<…>()` (presence/currency — `req_rungo`
     compares it to the demanded dige); `Lies_ghost_load(path)` = the load half. `feebly_i_elvisto(target,
      method,extra)` (`Housing`) is a best-effort `i_elvisto`, a no-op if no target A is up the tree — the
       Lies→Lang pokes route through it so a runner with no Lang doesn't throw.

**Transport freeze (editor only).** The editor can't ride the spine it's editing: editing `Peeroleum.g`
 would HMR-reload its own transport. So the editor bootstraps off a **frozen** copy at
  `src/lib/p2p/transport/*.go`; `Lies_transport_up` is EDITOR-ONLY (`role!=='editor'` bails). The editor
   *compiles* `gen/N/Peeroleum.go` but never *imports* it, so editing it HMRs nothing in the editor's Vite
    graph. **Promote a new spine into the editor's channel by hand:** `lang-compile --write` then `cp
     gen/N/*.go → src/lib/p2p/transport/`. The frozen copies are deliberately stale until you do.

## 4. The Funkcion board — Credence reads verdicts back

**Funkcions.** A `%Funkcion`'s mainkey value is its **kind**; a kind is a self-contained module under
 `O/Funk/`, registered in `O/Funk/kinds.ts` as `{ run?, component }`. The host stays generic: `Waft.svelte`
  mounts `<FunkHost>` for any `%Funkcion` (or legacy `%havoc`) and knows nothing else; `FunkHost` dispatches
   on kind to the kind's own component. **Monitor vs action** is the whole taxonomy: `run` present = a
    **monitor** (pumped every tick), `run` absent = an **action** (struck on click). Adding a kind = one
     `O/Funk/<Kind>.svelte` + one registry line.

*The pump is ours.* The `req:Funkcion`s live in a `%Funkcions` container (`funks.c.up=w` hand-stamped),
 driven by an explicit `Lies_pump_funkcions → funks.do()` (`req_Store` Phase 2b), separated from `w`'s main
  req tree. `Lies_instantiate_funkcions` binds each monitor kind's `run` on Waft load + on `watch_c` mutation;
   `funk_id` keys on the funk's structural `c.Dip` (the waftid slot `Waft_dip` stamps on every Waft** particle),
    so sibling cells of one kind get distinct reqs.

**Kinds today.**
- **`Storying`** (monitor) — a verdict light. Bound to a Book (`%of_Book`) or dock (`%of_dock`), `storying_run`
   finds the matching `%run_result` (by `book`, latest by `at`; or by dock `path`) and stamps an off-snap
    `funk.c.verdict={phase,pass,total,dige}` (NOT `req.sc.ok` — "the closure ran" ≠ "the test passed"). Shows
     ✓/✗/◴; a click launches its run.
- **`StoryTimes`** (monitor whose pumped `run` IS a sequencer) — the run-all *station*. A click only *arms*
   (`funk.c.sweep={phase:'arm'}`); the pump's `Lies_storytimes_drive` builds the queue from the station's scope
    (its containing `What`, or the whole Waft for `%all`), dispatches `become_book`, and advances on each
     book-keyed `run_result`, recording pass/fail and proceeding regardless (a 60s per-Book timeout fails-and-
      advances so a stall can't wedge it). The runner is one *sequential* Story Run, so in-flight width is
       `Lies_storytimes_width` = `min(runner_count, ADDRESSABLE)`; `ADDRESSABLE=1` today (see TODO: per-runner
        addressing). State is off-snap on `funk.c.sweep`.
- **`Ballistics`** (action) — the havoc drum-pad, struck on demand (`e_Lies_strike` → a Lies/Store limb).
   `%havoc:<kind>` folds into `Funkcion:Ballistics,kind:<kind>`.

**The verdict loop** (a Book run, wired both ways from a cell click). A **dock** cell → `Lies_run_arm{of_dock}`
 (the Esc "run it now" intent, a Rungo). A **Book** cell → `become_book`: the editor ships the frame, the runner
  `Lies_become_book_drive` stashes `awaiting_verdict{book}` + `resetStory{Book}`; on `storyFinished`,
   `Lies_runner_verdict → Cred_run_outcome` reads the just-finished Story's `%ok` steps/total and
    `Lies_report_result`s a real `run_result` back, Book-keyed. The editor's `Lies_run_result_recv` stamps it
     on `w:Lies` as `%run_result{path|Book:<name>}` carrying `ok_pct`/`done`/`dige`/`book`; the `.ls-health`
      step badge (`Liesui.svelte`) and the Storying lights read it.

**The board.** `wormhole/Credence/toc.snap` = `Waft:Credence`, Book-bound + What-grouped to mirror the Library
 (`Peregrination | Lake* | Leaf* | Port* | Stuff* | LangTiles` — the substantive Books; the rest are R&D husks,
  [[story-books-catalog]]). Each `What:*` holds its Storying cells + a `Funkcion:StoryTimes` station; a board-wide
   `Funkcion:StoryTimes,all:1` sits at the root. Open via Liesui `+Waft → Credence`.

**Inline Funkcions ↔ editable C** (the per-What presentation). A What full of Funkcions reads best as its
 illusions *flowed inline*, not a bullet list. `Waft_dip` stamps `c.inlined` on such a What at load (a
  suggestion; an author forces it with `%What:Label,inline`), and `Waft.svelte` lays it out as a compact flow of
   live cells. A `✎` on the What flips it to the conventional bullet C**, where each Funkcion node becomes a
    plain editable PeelInput row (`raw_props`: depeel idle → peel back into the funk's `sc`); `◉` restores the
     inline flow. The two affordances ARE the illusion — toggle the suggested inline, and edit the node itself —
      no separate dis-illusion chrome (`struct_what` holds the session's flipped Whats).

**The matrix IS a Waft — don't build a grid widget.** The `book × dock` matrix is already the Waft you navigate:
 a cell is a `%run_result` (row = `book`, column = `path`), coloured by the `.ls-health` step badge reused; one
  Funkcion per row IS the cell, so the "grid" is whatever layout the Waft gives its Funkcions — a `$derived`
   group-by when per-row grouping is needed, never a `<table>`. Credence holds only the light matrix (editor-side);
    the snaps stay on the runner (`Story/This`), pulled across on demand to diff a cell. Relevancy = a `(book,path)`
     with a `run_result` (observed) ∪ a Funkcion's declared `%of_dock` (so a never-run column still shows).

## 5. Durable gotchas

- **`%ttlilt` is NOT a keep-alive** ([[ttlilt-not-a-keepalive]]). One-shot snap-timing advisor; re-arming is a
   no-op, it never re-fires think. Any req that bows out on a ttlilt needs *something else* to re-pump it.
    `feebly_ponder` is Runtime-gated (`if(!this.c.runtime)return`) → a no-op on idle ambient Houses.
- **Snapped booleans = `1` or absent, never `false`/`0`** (CLAUDE.md policy). Prefer delete over 0; a C method
   (`r()`/`roai` replace) over a raw `delete n.sc.key`.
- **The editor compiles the spine but never imports it** — the freeze (§3) insulates it. Promote a new spine by
   `cp gen/N/*.go → p2p/transport/`; the frozen copies are deliberately stale until you do.
- **`relay.ts` is Node server code** — a direct import of `vite.config.ts`, so Vite **auto-restarts** the dev
   server on edit. If `✍ gen_write` never appears after a compile, it didn't restart — `touch vite.config.ts`.
- **`mode` is editor-local.** `run_arm{mode}` doesn't cross; the runner runs `in_place`. To wire `from_start`
   across, add `mode` to the Rungo (or a frame) + branch in `req_rungo → Lies_drive_run(w, path, mode)`.
- **Runner global-deposit caveat.** The runner mounts the live `gen/N/Peeroleum.go`, whose eatfunc deposits
   `Peeroleum_send` etc. **globally** (`ghostsHaunt`). Editor is fully decoupled; runner isolation is the deeper
    "dogfooded someday" piece.

## 6. Cross-refs

- `Peeroleum_spec.md` heading 10 — the transport spine, relay, frame lifecycle. Heading 1b — the UIless runner.
- `Wire_spec.md` — the `%subscribe`/wake vocabulary Editron (Atime) and Interest (UItime) share.
- `Story_cli_docs.md` — the working node Story-runner harness (the headless-verdict thread).
- Memories: [[creduler-runner-architecture]], [[opfs-illegal-under-dev-boot]], [[nested-req-needs-cup-stamped]],
   [[ballistics-drum-pad]], [[editron-verdict-phase2]].

---

## FUTURE

- **Funkcions as public-sphere infrastructure.** A Credence board is a small instance of a larger pattern:
   embedded buttons in a shared document that switch *server-side* capability on. "Click a test to run it on
    the runner" generalises to *people activating a capability* — the Waft is the public surface, the Funkcion
     the franchise, the runner the server that acts. As the channel hardens (trust/addressing, see TODO),
      *who may strike which Funkcion* becomes a permissions question, not just a test-runner one. The taxonomy
       already has the seam: a monitor reads, an action acts; an action that acts on the *server* is the franchise.

## TODO

- **Creduler headless verdict** (the highest-leverage open half): a runner that drives a Story to a real
   verdict *without a browser tab* — the `req:Step`/`req:Drive` recast + the **UIless-include** problem
    (Pantheate mounts the gen as a UI whose `onMount` injects `Ghostmeta`; a UIless run renders no UIs, so
     `req:include` times out at `waiting:ghostmeta`). Until then "remotely" = a second browser tab, not node.
      (`Story_next_level_spec.md` §15–16, `Story_cli_docs.md`.)
- **Nondeterminism guard** — a Credence cell seen both ✓ and ✗ at the SAME version-set. Capture the version-set
   at START and END of a run: start ≠ end = an HMR drifted mid-run (verdict suspect, discard/re-run); only
    start == end with a differing outcome is true nondeterminism. Don't conflate drift with nondeterminism.
- **Multi-runner addressing** — the frame needs a per-runner `header.to` so the editor can address one of several
   connected runners. StoryTimes already fans out across the fleet; it's gated only by `ADDRESSABLE=1` until this
    lands. (Then lift the cap to `Lies_runner_count(w)`.)
- **git seam** — a relay endpoint (path+dige → committed? + enclosing rev), then group `Credulation` by git rev.
   `Cred*.snap` are Lines-encoded; commit-status still stubbed null. Reuse the Wormhole overlay write-verdict pattern.
- **`%rungo` dedupe** — don't re-run an already-run seq (seq-authority is in place; the guard is NOT wired).
- **Book persist + remote-set** — persist the runner's current Book to `localStorage` (per-origin; NOT OPFS,
   [[opfs-illegal-under-dev-boot]]); precedence persisted > `?B=` seed, so a refresh resumes the remote-controlled
    shared runner tab.
- **`run_phase` progress relay** (garnish) — Story emits `story_analysis {the_steps,live,frontier}` per tick;
   relay it as a light frame so a Funkcion shows `◴ 3/5` not a bare spinner. The verdict is the load-bearing signal.
- **Trickle → single wake** — `req_rungo`/`req_compile` bow out on a ttlilt and re-arm a paced `setTimeout →
   i_elvisto(w,'think')` busy-poll (shouts `🔥` every 10th spin). The event wakes largely exist
    (`Lang_drain_compile_settles → H.main`, `write_finished → think`); demote the trickle to one ~1s safety fire.
- **Compile-conditions popover** — SurprisePopover-standardised: surface no-parser / incomplete-parse (Lezer error
   nodes) / bad_js as *ignorable* with a "push illegal JS anyway" override (also catches the mid-token `figaro:`
    case that renders `{figaro:undefined}`).
- **Strip visuals** — compile leg dim while compiling / skitsytwisty while writing `.go`; runner half-pill
   expandable to error / Story summary / Story diff.
- **non-.g Pointing** — tsstho Points in `.ts`/`.svelte`, markdown Points in specs, on a parse-for-Points-only
   path emitting NO `.go` ([[nong-pointing-todo]]).
- **Runner / low-end bundle split** — keep CodeMirror + the editor island off the runner and old-mobile
   endpoints. The editor is one static-import island (`Lang*`, `O/lang/`, `@codemirror/*`); today it rides into
    the runner's chunk because the runner's spine statically reaches `Lang*`. Gate the editor mount by role
     behind a dynamic `import()` so Rollup splits it into an editor-only chunk the runner never names; verify
      with a bundle visualizer that the runner entry no longer contains `@codemirror`. *Cheap precursor done:*
       all langs but `stho` are now lazy (`tsstho`/`markdown` `await import()` their grammars, so `@lezer/javascript`
        and `@codemirror/lang-markdown` only load when a `.ts`/`.svelte`/`.md` dock opens). A separate route/entry
         for the runner would let Vite split it for free — worth it if the runner endpoint hardens.
- **Trust enforcement** (deferred for v1) — accept-the-one-runner trust-everything handshake → real
   per-Funkcion permissions; `Thangs` persistence of who's allowed (`Peeroleum` heading 11).
- **Loose ends** — stray `debugger` at `Housing.svelte.ts:1852`; the `ack seq=undefined DROPPED` after each HMR
   (channel re-establish, separate from latency).
- **Verify-in-app** — after the one boot step the editor Run must stay live + interactive on `Run.c.no_ambient=true`
   (interaction-poked think vs a "boot story → re-enable ambient" mode); the `toc.snap`s carry one `step,dige`
    lie — confirm one step then settle, Accept/Resnapture to record real diges (the now-honest badge reads red
     until they're re-recorded).
