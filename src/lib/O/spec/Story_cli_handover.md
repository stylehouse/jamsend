# Story_cli — running a Story Book outside the browser

A working CLI runner for the Story machine: boots the whole House+ghosts in node,
 drives a Book to completion, and **serialises `w:Story` to a pile of files you grep/diff
  offline** — so "seeing" a run is iterative bash, not a wall of console output. Built
   for an agent/CI to write→run→read→iterate without the live app.

This is the §16 ("running it headless") payoff from `Story_next_level_spec.md`, minus the
 Compile-bundle step — it loads the real source via vitest's transform instead.

## Run it

```
node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts
BOOK=Mundane node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts
```

Cold run ≈ 40s (≈99% is vite transforming the 500+ ghost graph + codemirror/cytoscape/
 peerjs). `vitest --watch` keeps a warm parent so re-runs are ~1s; `pool:'forks'` gives
  each run a fresh child (a precise, un-mutated copy — the "fork a non-HMR child per run").

## The pile it writes — `/tmp/Story_cli/<Book>/`

| file | what |
|------|------|
| `NNN.got.snap` | produced `Snap:H` for step N (mo:main already dropped by `story_matching`) |
| `NNN.exp.snap` | the recorded fixture for step N, mo:main-normalized (for a clean `diff`) |
| `NNN.trace.txt` | the `Run_trace` event stream for step N |
| `wstory.json` | the ENTIRE `w:Story` C-tree (sc + children, recursive) — the whole run |
| `run.json` | summary: per-step `story_ok` / fixture `match` / line counts / `surprises[]` |

Query it like any data:
```
cat /tmp/Story_cli/PortPlanet/run.json
diff /tmp/Story_cli/PortPlanet/005.got.snap /tmp/Story_cli/PortPlanet/005.exp.snap
grep -rn surprise /tmp/Story_cli/PortPlanet/
```

## How it works (the non-obvious parts)

- **Substrate: vitest + jsdom + `svelteTesting()`** (`scripts/Story_cli.vitest.config.mjs`),
   NOT vite-node. vite-node ignores `--config`, dies on "server is being restarted" for the
    full graph, and `ssrLoadModule` compiles components SSR-mode so `onMount` never fires
     (→ ghosts never deposit). The config is **`.mjs` not `.ts`** on purpose (a `.ts` config
      makes vite bundle into root-owned `node_modules/.vite-temp` → EACCES).
- **Boot:** `Story_cli.svelte` constructs `H` in a component `$effect` and renders `<Ghost>`;
   onMount→`eatfunc` deposits ~531 methods onto `H`.
- **The pump is dead headless.** The House's `$effect.root` (the `todo→beliefs` pump and the
   `started` flip, `Housing.start`) does NOT flush under node — even constructing H in a
    component effect, even with `flushSync` (all tested). So the driver cranks Atime by hand:
     force `h.started=true` and call `h._really_answer_calls()` to drain each house's todo.
      EVERY house has its own dead pump — drain top + `H:Story` + the dynamic Run (recurse
       `h.o({H:1})`). This is the documented Atime pipeline (`reactivity_docs.md`) minus the
        UItime `$effect` layer headless doesn't have.
- **Faithful round counts:** don't inject `think` every tick (that ran PortPlanet ~192
   rounds/step). Kick `think` only until `run.c.driving` is true (toc-load), then DRAIN-only
    so `story_drive` owns the clock.
- **noCyto + lenient:** patch `The_Opt_val('noCyto')→true` (else the tick-1 Cyto commission
   throws "no House has A:Cyto") and set `w.c.lenient=true` (so `check` mode walks all steps
    instead of pausing on the first dige mismatch).
- **Wormhole:** skip the browser DirectoryOpener; wire `A:Wormhole`/`w:Wormhole` and set
   `WA.c.nav` to a node-fs object with `read_file(dir,file)`/`write_file`/`dir` — the worker
    funnels all I/O through `A.c.nav`.
- **The runner owns its verdict:** it does its own mo:main-normalized diff of each got vs the
   fixture rather than trusting Story's internal dige.

## PortPlanet result (the proof)

Steps **1–4 byte-match** the fixtures. Steps **5–6 surprise**: a literal `surprise=42`
 particle the got has but the fixtures don't — and it's *real code* (`MachReqy.svelte:220`,
  `De.oai({surprise:42})` in `req_reportPortPlaneting`), not a node-ism. So the **fixtures
   `005.snap`/`006.snap` are stale** (predate that line); a browser re-run would diverge the
    same way. The runner correctly triaged three kinds of diff:
- **node-ism** (`mo:main` timer, rendered `Timeout()` in node vs an id in browser) → dropped
   via a `story_matching` skip rule on `%mo` (Story.svelte ~778). **This drops mo:main from
    every snap+dige → all `*.snap` fixtures carrying it need re-recording.**
- **acknowledged non-determinism** (round value / sibling order) → fixed by paced driving.
- **genuine surprise** (`surprise=42`) → flagged; stale fixture, not a runner bug.

That is the green/fuzz/surprise triage of `Story_next_level_spec.md` §4/§12, falling out of a
 headless run.

## Container note (why this was blocked)

The `app` compose service ran as **root** (alpine, no `user:`), writing root-owned
 `node_modules/.vite*`; the `claude` service runs as `user:"node"` (uid 1000) and couldn't
  write them. Fix applied: `user: "1000:1000"` on the `app` service (numeric — alpine has no
   `node` user) + `chown -R 1000:1000 node_modules`. Both containers now uid 1000. (Running
    the app non-root over root-owned node_modules is the "black screen": vite can't write its
     `.vite` cache. The `.:/app` bind mount also shadows the image's `npm install`, so host
      `node_modules` ownership is what matters.)

## Files

- `scripts/Story_cli.svelte` — the Otro-type shell (constructs H, mounts Ghost)
- `scripts/Story_cli.spec.ts` — the driver + pile serialiser (the runner proper)
- `scripts/Story_cli.vitest.config.mjs` — vitest harness (jsdom, browser condition, forks)
- `scripts/Story_cli.setup.ts` — globals (indexedDB stub, raf, tolerate late rejections)
- `scripts/Story_cli_boot.spec.ts` — minimal boot proof (House constructs, ghosts deposit)

## Open / next

- **Re-record fixtures** for the mo:main drop (repo-wide) and PortPlanet 005/006 (the
   `surprise=42`). The runner can write fixtures through `WA.c.nav.write_file` — wire an
    Accept path (run in mode:'new' / accept got) to regenerate from the CLI.
- **Multi-book sweep** — loop the Books (PortPlanet, Mundane, the Lake*/Stuff*/Leaf* games)
   and write a fleet `run.json` (green/amber/red per Book) — `Story_next_level` §12.
- **Emission frequencies** — the dump is "everything-at-once"; add a "pause-as-soon-as-wobble"
   mode (stop + dump at the first non-fuzz surprise).
- **Diff channels** — the pile is `Snap:H` + trace; add `Snap:cont`/`Snap:refs` once the
   encoder merge (`Story_next_level` §1–2) lands, so "grep a kind of diff" gets richer.
- The pile (grep/diff offline) replaced the originally-floated telnet REPL — for an agent,
   files beat a socket. A live telnet hang is still possible later for a *paused* run.
