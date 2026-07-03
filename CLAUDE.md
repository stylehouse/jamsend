# CLAUDE.md

Project context loaded by every Claude Code session in this repo.
Keep it current; it is the memory you would otherwise re-type into each fork.

Distilled from a run of handover notes; only the durable shape was kept,
 not any single session's fixes or open threads. Correct anything stale.

**Before touching the belief loop, `req`/`ttlilt`, the compile pipeline, or anything a Story
 snaps: read `src/lib/O/spec/Coding_guide.md` — the non-obvious mechanics (wake ≠ hold, the
  ttlilt rules, the all-holds compile→rerun chain, and "verify a timing fix by re-running").**

## What jamsend is

A peer-to-peer music app: Svelte 5, served by the dev container on 9091,
 WebRTC for the streaming (so the dev server must be reachable on localhost,
  which is a secure context), peerjs alongside, a music library mounted
   read-only at /music.
On top of the app sits a large authored machine: a test|story runner, a live
 Cytoscape visualisation, and a compile|run pipeline for editable docks.
Most work happens in that machine, not the streaming itself.

## The data model — C objects (particles)

Everything is a particle, a `C` (TheC). A particle's type is its **mainkey**,
 the first key of its `sc` map. `mainkey(n)` is `Object.keys(n.sc)[0]`.
Mainkeys are mutually exclusive type tags; the first key of any sc should
 never appear as a non-first key of another.

Two child stores:
  `sc`: scalar string-children, encoded and persisted.
  `c`:  runtime refs and backlinks, never encoded.
Objects|functions belong in `.c` only; an object value in `.sc` is fatal
 at encode time.
A snapped boolean rides as `1` or **absent**, never `false`/`0`: a JS boolean is not
 a clean scalar string and snaps inconsistently (a flat `dim:false` one tick, a munged
  `{"dim":false}` JSON object the next). Prefer **deleting** the key to setting it `0`,
   and prefer a C method (`replace()`/`r()`/roai's replace) over a raw `delete n.sc.key`
    so the change is tracked and the snap stays consistent.

Notation we use when talking about particles:
  `%Text` means `{Text:1}`; `%LE` means `{LE:1}`, never write `%LE,1`,
   unless the property obviously carries a value, as in `%Spotlight,src`.
  alone: `%like,this`; in a structure: `/like,this/written:is`.
  a property of a thing: `Text%dige`.

Find-or-create on a container:
  `C.o(sc)` returns matching children; `C.o(sc)[0]` is the existing one.
  `C.i(sc)` creates.
  `C.oa(sc)` is a boolean probe only; retrieve with `o(sc)[0]`, not oa.
  `C.oai(...)` is find-or-create.
In a query, a numeric `1` is a **presence wildcard** (`{k:1}` = has key `k`, any value);
 a string or other value matches that value literally. `exactly(sc)` / `{exactly}`
  stringifies, so it forces a literal match — and turns a `{k:1}` marker into `k:"1"`,
   which no longer wildcards (the footgun behind moai's serial re-find).
Creation bumps version; watchers ($effect) react off that.

**Travel** is the tree-walk primitive over the C tree, depth-first.
 The encoders walk with Travel + mainkey to serialise generically; a particle
  whose mainkey is not in the protocol is a fatal encode error, subtree skipped.
A **snap** is the text serialisation of the C tree which Story makes between steps.

## Subsystems (each a "ghost" — a .svelte module of logic)

**House (H)**: the container hierarchy. `H:Mundo` is the root, things like
 `H:LeafFarm` nest under it, `top_House()` walks up to Mundo, and a mutex
  serialises ticks so a reader sees frozen state. `w:` are worlds (w:Lies,
   w:Cyto, w:Story), `A:` are actors. Particles classify by sc key; H|A are
    invisible, w is compound.

**The req machine** (Hovercraft.svelte): a stack of requirements at **maz**
 levels. `reqy(w).do()` runs each level; `needs_work = !finished && !ok` gates
  entry. `sc.ok` is pass-local: re-armed at the top of each do() pass, so it
   suppresses re-runs within one pass but never survives across ticks. A req can
    arm a **ttlilt** and bow out; `level.some(needs_work)` then halts descent.
 Lifetimes: `eternal` persists across ticks, `permanent` is one-per-ghost and
  owns a write.

**Story** (StoryGhost.svelte): the test|story runner. `toc.snap` decodes to
 **The**, whose buckets are `The/Steps` (each step + its notes), `The/OtherStuff`,
  and `The/Styles`. `The` is canonical storage (step), `This` is the live
   session (Step); `step_c(container, n, key)` is the unified find-or-create for
    both. `snap_step` reads world state via a ref pass (snap_H). `beliefs()` is
     a traced phase; `dige` is the change-sensitivity|digest used to decide what
      is worth re-emitting. A test may flag itself out of Cyto to spare the
       graph noise.
 New test assertions are authored as `%see:'sentence'` — a **once-noticed**,
  self-describing claim emitted once the first pass a truth holds (no commas in
   the sentence — the peel parser splits on them; use an em-dash). It supersedes
    the older `%witnessed:step_N` latch (kept only for already-recorded gates);
     the snap-fixture diff stays the gate and the place to notice un-asserted
      detail.

**Cyto** (Cyto.svelte, view in Cytui): the live Cytoscape view. `cyto_scan`
 walks the particles, `cytyle_classify` returns skip|invisible|compound,
  surviving `n%*` become `cyto_node`s. Styling is **Matstyle** now, not the old
   cyto_nstyle branches. Animation is a **wave**: cyto_update_wave bumps version
    and a grawave duration drives the timing, Cytui animates off the $effect.
 `source_n` backlinks the node to its particle on `.c`, so no encode cost.

**Matstyle** (Matstyle.svelte): auto-swatch. Classifies a particle by mainkey
 and autovivifies a `matstyle:<key>` under `The/Styles`, with `%style:*` and
  `%meta:*` children stored C-within-C, not as flat sc keys. `dose_drives`
   interpolates a size from a dose value between min|max. The styles ride in
    `H.ave` beside This and swatches; the graph stays clean for streaming data.

**Text** (Text.svelte): the matching and encode|decode primitives. `enLine`
 encodes a line, `enWaft` encodes a Waft tree, and `mainkey_match` is the
  generalised rule matcher (returns skip|munging|thence|mainkey) that enLine
   calls internally. Protocols (WAFT_PROTOCOL and the like) are inline rule
    sets that attach omit_sc per mainkey.

**Lies**: the compile|run pipeline for editable docks, a req-stack all the way
 down. `LiesStore` (req:Store, the IO pump) settles finished writes|reads in
  phases. `LiesCortex` (req:Cortex) is the compile foreman. `req:Codebit` is
   one-per-dock and owns the generated write; `req:Rundown` is the runner, and
    `Pantheate` and `BlastPit` are where a run lands. Errors thread back to the
     editor through `Codebit%of_dock`. The document tree is Waft → What → Doc →
      Point (DocMinimap shows it, Lang_apply_openness folds it around engaged
       Points).

**elvis|elvisto**: the deferred cross-ghost call, as in
 `this.elvisto('Story/Story', 'fn', {...})`; a method on another ghost, run
  later rather than reached into directly.

## Commits are the human's job

Never stage, commit, or push. Leave every change in the working tree.
The human reviews the diff on the host and writes the commit message.
When you think a commit point has been reached, say so; do not run git
 to record it.

## "handover" really means "handoff doc" or even "continuation brief."

At resting points similar to commit points, but for context management, we jot down and restart the session.
A handover that's a changelog (what I did) is the weakest, most disposable part.
The load-bearing part is `destination + the knowledge that detonates the bomb if the next person doesn't have it + the next move`.
Show the arc, not just the diff.


## The ~3k svelte-check warnings are baseline noise

`npm run check` reports ~3000 pre-existing errors|warnings — mostly implicit-`any`
 on untyped params and "Property X does not exist on type 'House'" (eatfunc|ghost-
  injected methods the House type doesn't declare). Don't worry about the total; it
   even drifts run-to-run from the incremental cache. To judge whether an edit
    regressed, grep the check output for the *edited file's* line range, not the sum.

## Running a Story Book: a real Lies%runner request, never headless

Verify a Book by asking a LIVE runner to run it — not a headless boot.
 A runner is meant to be always available: a browser tab on :9091 booted as a
  runner (`?B=<Book>`), reachable over the same `/relay` websocket the editor uses.

`scripts/runner_ask.mjs` is the CLI to it (request|reply correlated by corr, like
 `ghost_compile.ts` but targeting the runner; reply is the live world, real wall
  clock, real AudioContext muted). `RUNNER_URL` defaults to `http://172.17.0.1:9091`
   (the dev server as seen from this container; `http://localhost:9091` on the host).
  - `node scripts/runner_ask.mjs ping`               — liveness `{role,channel,running}`
  - `node scripts/runner_ask.mjs run <Book> --watch` — become_book + poll to done|failed
  - `node scripts/runner_ask.mjs state`              — verdict + phase/n/total
  - `node scripts/runner_ask.mjs steps`              — per-Step ok|caveat|dige
  - `node scripts/runner_ask.mjs snap <n>`           — one Step's live got_snap
  - `node scripts/runner_ask.mjs rungos`             — held runs, each addressable `@uid`
 Exit 1 when a `--watch` run finishes red, so it scripts. `story_repl.mjs` is the
  interactive twin (`@uid` addresses a held run).

A runner that won't connect ("relay down", no ws attempt in the Network tab): read
 `src/lib/O/spec/Runner_network.md` — the boot→channel map, what each Brink badge asserts,
  and the diagnostic ladder (cross-wired `gen/N/Tribunal.go` first — the editor staying
   green while every runner is down IS that tell).

Do NOT verify with `scripts/Story_cli_run.mjs` (the headless node+jsdom boot). It
 has real disk access, so it loads the GhostList off the wormhole and quiesces at a
  DIFFERENT depth than a live runner — its fixtures match *itself* but go all-red on
   the real runner (the GhostList footprint + boot-progress diverge). A green there is
    a bubble, not a gate; recorded fixtures must come from the live runner too.
