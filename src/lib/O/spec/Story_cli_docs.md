# Story_cli — notes to self for running Books UIless

The keeper doc for the UIless Story runner. **How to run it + the pile layout live in
 the header comment of `scripts/Story_cli.spec.ts`** (the `BOOK=…` / `ACCEPT=1` commands,
  the `NNN.got.snap`/`run.json`/`wstory.json` file list, the query examples); the *design*
   it realises is `Story_future.md` §16. This file is the **durable gotchas** — the
    things that bit a past session hard enough to be worth re-reading before you touch a
     ttlilt-timed Book, go spelunking in the trace, or wonder why the pump seems dead.

## Acquired (Creduler) Books — `CredRunner`

`Story_cli` runs **fixture** Books (spine on disk).  A **Creduler-ACQUIRED** wrangler Book (PereStaple /
 PereTyrant / Editron / Musu — spine loads via `Creduler_ensure` / `CREDULER_GHOSTS`) needs two things
  `Story_cli.svelte` lacks, both supplied by `scripts/CredRunner.spec.ts` + `scripts/Story_cli_runner.svelte`:
- **Render the dynamic includes.** The acquire enrols each gen `.go` as a `watched:UIs` Pantheate-include;
   in-app **Otro** mounts those, `Story_cli.svelte` (just `<Ghost>`) does not.  The runner shell adds Otro's
    one line — `{#each house.UIs.ob({UI:1})} <svelte:component this={uiC.sc.component} H={house}/>` — so an
     enrolled gen mounts headless and its onMount eatfunc deposits.  (`.go` resolves because `svelte.config.js`
      maps it to svelte; jsdom fires onMount — the "onMount never fires UIless" warning on `Lies_ghost_set` is
       about a true no-DOM run, not this jsdom one.)
- **The acquire prelude.** Make the creduler Lies (`H.i({A:'Lies'}).i({w:'Lies',runner:1,creduler:1})`), then
   crank `await H.Creduler_ensure(liesW)` + `flushSync()` + think until the spine reads live, BEFORE standing up
    `w:Story,Book:<Book>` (the rest is the Story_cli drive loop verbatim).

Run + record exactly like Story_cli:
   `BOOK=PereStaple node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts`
   — `ACCEPT=1 …` re-records the fixtures.  `CredulerProbe.spec.ts` is the bare-acquire proof (spine methods
    deposit) — run it to tell "acquire broke" from "drive broke" when a run wedges.

**Known caveat — the handshake-quiescence step.** A step whose work completes via a `post_do`/`feebly_ponder`
 round-trip with **no ttlilt** can snap one beat early headless: node reaches quiescence before the deferred
  completion (the inverse tail of the MundaneStation race below — same root).  PereStaple step 3 caught it
   (`req:handshake` not yet `,finished`, no `witnessed:step_3`); steps 4+ reconcile.  Do NOT "fix" it by
    trickling think while a req is open — a req that legitimately spans steps then never lets an earlier step
     quiesce (it hangs).  The real fix is a waiting ttlilt on the unfinished req (a `.g` edit) — the same
      ttlilt-determinism lever this whole doc is about.

## How it boots & drives — the load-bearing gotchas

- **Substrate is vitest + jsdom + `svelteTesting()`, NOT vite-node.** vite-node ignores
   `--config`, dies on "server is being restarted" for the full ghost graph, and
    `ssrLoadModule` compiles components SSR-mode so `onMount` never fires → ghosts never
     deposit. And the vitest config is **`.mjs`, not `.ts`** on purpose: a `.ts` config makes
      vite bundle into root-owned `node_modules/.vite-temp` → EACCES under uid 1000. Don't
       "tidy" either of these back.
- **The House pump is dead UIless.** The `$effect.root` (`todo→beliefs` pump, the
   `started` flip in `Housing.start`) does NOT flush under node — not even with `flushSync`.
    So the driver cranks Atime by hand: force `h.started = true` and call
     `h._really_answer_calls()` to drain each House's todo, recursing every sub-House (each
      has its own dead pump). This is the documented Atime pipeline minus the UItime `$effect`
       layer node doesn't have. If a Book "does nothing," this is why — something isn't being
        drained.
- **Driving the clock without over-driving.** Kick `think` only until `run.c.driving` is
   true (toc-load), then let `story_drive` own the clock — EXCEPT while a `%ttlilt` is live
    below a req (async work pending): trickle `think` into every House so the deferred beats
     fire, paced toward the soonest `until_ts`. Self-terminating (ttlilts drop on finish).
      Without the trickle the run quiesces early and the pending work's ttlilt just times out
       (the stuck-compile blob). See the `liveTtlilts` gate in `Story_cli.spec.ts`.
- **no own-Cyto + lenient.** Cyto is opt-in now (`Opt/useCyto`, default off), so most Books
   need no patch. For the Books that DO set it (the Leaf* tests) the headless runner forces it
    off — patch `The_Opt_val('useCyto')→false` (else the tick-1 Cyto commission throws "no House
     has A:Cyto") — and set `w.c.lenient = true` (so `check` mode walks all steps instead of
      pausing on the first dige mismatch). The runner does its own mo:main-normalized
       got-vs-fixture diff rather than trusting Story's internal dige.
- **Wormhole I/O** goes through a node backend injected at `WA.c.nav` (`NodeWormholeNav.ts`,
   a repo→`/tmp` overlay) — its own brief is `Wormhole_backends_handover.md`.

## Ignore `src/lib/gen/**/*.go`

They are **generated** by the Lang compile pipeline (`// GENERATED by Lang compile — do
 not edit by hand.` at the top of each). They're git-tracked, so they show up in greps
  and file lists, but they are compiled OUTPUT of `.g` LangTiles source — never authored,
   never the place to understand the machine, never the place to fix anything. When you
    grep the codebase to learn how something works, exclude them (`--exclude-dir=gen` or
     `:!src/lib/gen`). Edit the `.g` source and recompile; don't touch the `.go`.

## ttlilt timing must out-run host scheduling jitter — the MundaneStation lesson

A `%ttlilt` is wall-clock: `i_req_ttlilt(req, secs)` stamps `until_ts = now + secs`, and
 `o_Story_req_ttlilt` holds the step open while `until_ts > now`. Its whole job
  (Hovercraft.svelte) is to let Story **snap a coherent picture** — i.e. wait until the
   work it gates has landed, then snap. It is NOT a guaranteed pause; it's "this slice of
    wall-clock isn't quiescent yet."

The trap: a test that arms a `ttl` **equal to (or shorter than) the latency of the work it
 waits for** is a race, and you lose it differently in each environment. MundaneStation's
  `make_item` used to arm a **0.2s ttlilt beside a `setTimeout(…, 200)`** that did the
   populate. 200ms vs 200ms. Read the timed trace of a healthy run (the ms column is now
    in `NNN.trace.txt`):

```
   63ms  think   MundaneStation        ← folders still EMPTY (timers pending)
  202ms  ttlilt  Story poll: held …    ← ttlilt holding the step open
  270ms  todo    reqyonciliation       ← the setTimeout(200) callbacks finally fire
  292ms  reqyoncile  made song_1        ← work lands ~270–318ms, NOT at 200ms
  325ms  think   MundaneStation        ← re-think: folders now FULL
  455ms  quiescent → snap              ← snaps the populated state
```

The setTimeout nominally fires at 200ms but actually lands at **~270ms** — ~70ms of host
 scheduling lag (these containers routinely eat 0.2s). So:
- With `ttl 0.2`: the ttlilt expires at 200ms, *before* the work lands at 270ms. Whoever
   polls in that window snaps **empty folders**. The browser (busy main thread, timer
    callback delayed further) reliably caught this; node (idle thread, exhaustive `drain()`)
     reliably closed the window first and snapped **full**. Neither is wrong — the test was
      under-specified, and "UIless walked through a pause" was a misread: the trace shows
       the ttlilt *was* honored. The two environments just resolved a coin-flip differently.
- With `ttl 0.6`: ~400ms of slack. Even with 70ms of jitter the work lands at ~270–318ms,
   far inside the held window, so **both** environments snap the populated state. The req
    finishes at ~318ms and drops its ttlilt, so the step still snaps promptly (~455ms) — the
     0.6 is headroom, not a fixed 600ms wait. "Accept some slowness when things go wrong":
      worst case you wait up to `ttl` for a stuck req. It's test code; determinism wins.

**Rule for ttlilt-timed test Books:** `ttl ≥ work_latency + host_jitter`, with margin.
 0.6s against ~0.2s work is the house convention — `MundaneStaying` already uses `ttl:600`
  (its comment spells out "snap after until_ts expires, NOT at 150ms"); MundaneStation was
   the one outlier at 0.2 and is now 0.6 (`Mundane.svelte`, `MundaneStation`'s `make`).
    Increasing the ttl is the cheapest determinism lever you have — reach for it before you
     consider gating the UIless drive.

Note the populated-snap was always node's behaviour; the on-disk fixtures already match
 (`5/5`). The fix's value is that a **browser** re-run now agrees too — the fixture stops
  being node-matching-node and becomes environment-independent.

Residual: `round=N` (carries `{"mung":["age"]}`) can still drift by ±1 think-pass under
 timing jitter (~1 run in ~14). It's age-munged in the dige so `story_ok` is robust; only
  the raw-text `match` is sensitive. This is the handover's long-known "acknowledged
   non-determinism (round value)", not a ttlilt issue — live with it or mung `round` out of
    the snap text too if it ever gets annoying.

## The H.trace system — reading time out of a Story run

`H.trace(kind, tag)` pushes a `TraceEvent {t: performance.now(), kind, tag}` onto
 `H.trace_log` (Housing.svelte.ts). Story enables it per step (`trace_enable`) and drains it
  into `step.sc.Run_trace` at snap (`trace_drain`). Two ways to read it:

- **In-app:** Storui renders `Step.sc.Run_trace` as a timeline (`Storui.svelte` ~1238) —
   each event positioned by `ms_in_step = ev.t - t0`, kind-coloured (FNV hash → hue), with a
    copy-to-clipboard button. That's the live view when you have the browser.

- **UIless (the pile):** `NNN.trace.txt` now carries the timing too —
   `ms-since-step-start | kind | tag`, t0 = first event of the step (same `ms_in_step`
    semantics as Storui). The `traceDump` helper in `Story_cli.spec.ts` emits it. **This
     column is the UIless equivalent of staring at the Storui timeline** — without it you're
      reverse-engineering timing from `+Nms` tags baked into trace messages, which is how the
       MundaneStation race stayed mysterious longer than it should have. When a Book diffs on
        timing, read the trace column first.
