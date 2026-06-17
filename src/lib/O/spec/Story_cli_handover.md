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
ACCEPT=1 BOOK=PortPlanet node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts
```

`ACCEPT=1` **re-records**: the got snaps become the new fixtures (see "Re-recording" below).

Sweep every Book and aggregate a fleet verdict (green/amber/red):
```
node scripts/Story_cli_sweep.mjs                # all Books under wormhole/Story/
node scripts/Story_cli_sweep.mjs PortPlanet Mundane*    # a list (simple * globs ok)
ACCEPT=1 node scripts/Story_cli_sweep.mjs       # re-record sweep (rewrites fixtures)
```
Each Book runs in its OWN fresh vitest process (clean House singletons); the per-Book
 `run.json` is read back into a fleet table + `/tmp/Story_cli/_fleet.json`. green = every
  step matches, amber = ran but surprises, red = no `run.json` (boot/drive failure).

Include a test-shim component with `-I` (run a Book whose code isn't in the main Ghost bundle):
```
node scripts/Story_cli_run.mjs -I MyShim            # mount scripts/MyShim.svelte, Book defaults to MyShim
node scripts/Story_cli_run.mjs -I MyShim -b Probe   # shim, run Book:Probe
node scripts/Story_cli_run.mjs MundaneStation       # no shim, just run a Book
node scripts/Story_cli_run.mjs -I MyShim --accept   # record a fixture for the shim Book
```
The real test-case games (Mundane, MachReqy, the Understand* suite…) attach by being
 rendered `<X {M}/>` in **Machinery.svelte's template**, depositing a worker via `M.eatfunc`
  on mount.  `-I` does the same for one extra component without editing that template: the
   runner mounts it alongside `<Ghost>` with the same `M={eatfunc}` shim.  Expect `-I` to be
    common as test code moves out of the bundle — eventually a Book's own Story advice names the
     shim(s) to include.  Write the shim as a `<script>`-only `.svelte` (see any Machinery child
      for the shape: `let {M}=$props(); onMount(async()=> await M.eatfunc({ <Worker>(A,w){…} }))`).
       A Book with no `toc.snap` runs in `mode:'new'` (total=1) — one recorded step at
        `/tmp/Story_cli/<Book>/001.got.snap`.  The worker is `<w-name>(A,w)` (Agency dispatches
         `this[w.sc.w](A,w)`); for a default actor that is the Book name.  Mechanism under the
          hood is the `INCLUDE=<name>` env the spec reads; `-I` is the ergonomic front for it.

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
- **Wormhole:** skip the browser DirectoryOpener; the runner injects a node backend at the
   `WA.c.nav` seam — `scripts/NodeWormholeNav.ts`, an overlay that reads repo→`/tmp` sandbox and
    writes to the sandbox (so compile-pipeline Books don't mutate the tree), letting `wormhole/`
     fixture writes pass through to the repo only under `ACCEPT`. The worker funnels all I/O
      through `A.c.nav`'s three methods (`read_file`/`write_file`/`dir`). The backend abstraction
       and where it's going (OPFS-from-GitHub, Identities) is its own brief: **`Wormhole_backends_handover.md`**.
- **The runner owns its verdict:** it does its own mo:main-normalized diff of each got vs the
   fixture rather than trusting Story's internal dige.

## Re-recording — `ACCEPT=1` (the regenerate-from-CLI path)

`ACCEPT=1` makes the runner accept its own got snaps as the new fixtures, through the
 machine's real write path — no special node-only file poking. It rides on the fact that
  **`story_save` already runs headless** (the Wormhole→`A.c.nav` write path is live; in a plain
   check run it just has `to_write=0`).

The flow, after the normal check pass completes:
- **`w.c.keep_snaps = true`** is set during the run, disabling the 5-step `got_snap` trim so
   *every* step still carries its produced snap at the end (not just the last five).
- Each live `This/Step` with a `got_snap` is **promoted**: `accepted=true`, and its got dige
   (already on `step.sc.dige` from the check pass) is pushed into `The` via `The_step(w,n).sc.dige`
    so `encode_toc_snap` stamps a matching `toc.snap`.
- `story_save()` then writes `toc.snap` + every `NNN.snap` through `nav` into
   `wormhole/Story/<Book>/`. The runner cranks ~30 extra drain ticks so those deferred
    (`setTimeout`→`post_do`→Wormhole-req) writes flush before it reads back.

Because the got snaps are already `mo:main`-free (the `story_matching` `%mo` skip drops it from
 snap *and* dige), a re-record is the repo-wide `mo:main` cleanup: **every** step's dige changes
  (the old toc diges were computed with `mo:main`), so all `NNN.snap` lose the `mo:main` line and
   `toc.snap` gets fresh diges. Genuine content (e.g. `surprise=42`) is baked in at the same time.

PortPlanet, re-recorded then re-checked, is now **6/6 `match` *and* `story_ok`** (was 4/6). The
 diff is reviewable/revertible — fixtures are git-tracked; the human reviews before commit.

## PortPlanet result (the original proof — now resolved by re-record)

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

- `scripts/Story_cli.svelte` — the Otro-type shell (constructs H, mounts Ghost; `include` prop mounts the `-I` shim with an M-shim)
- `scripts/Story_cli.spec.ts` — the driver + pile serialiser (the runner proper; `ACCEPT=1` re-records; reads `INCLUDE` for `-I`)
- `scripts/NodeWormholeNav.ts` — node backend for `w:Wormhole` (overlay; see `Wormhole_backends_handover.md`)
- `scripts/Story_cli_sweep.mjs` — fleet sweep: run every Book in its own process, aggregate green/amber/red
- `scripts/Story_cli_run.mjs` — single-Book runner with `-I <shim>` / `-b <Book>` / `--accept`
- `scripts/Story_cli.vitest.config.mjs` — vitest harness (jsdom, browser condition, forks)
- `scripts/Story_cli.setup.ts` — globals (indexedDB stub, raf, tolerate late rejections)
- `scripts/Story_cli_boot.spec.ts` — minimal boot proof (House constructs, ghosts deposit)

## Open / next

- **Re-record fixtures** — DONE for PortPlanet via `ACCEPT=1` (see "Re-recording" above). Still
   to do: run the same accept across the *rest* of the Books to land the `mo:main` drop repo-wide
    (every book's fixtures still carry `mo:main` until re-recorded). Best done as an accept sweep
     once the read-only sweep below confirms each book runs clean first.
- **Multi-book sweep** — DONE: `scripts/Story_cli_sweep.mjs` loops the Books and writes a
   fleet report (`/tmp/Story_cli/_fleet.json`, green/amber/red per Book) — `Story_next_level`
    §12. Findings so far:
   - `ttlilt,until_ts` was an un-munged absolute wall-clock deadline (now + ttl), so every
      ttlilt Book diffed on a timestamp that changes each run — pure noise, like `mo:main`.
       Fixed: a `story_matching` mung rule on `ttlilt`'s `until_ts` (Story.svelte, beside the
        other `type:'time'` rules). Like the `mo:main` drop it invalidates on-disk fixtures, so
         every ttlilt Book needs a re-record (`MundaneStaying` done: 2/3 → 3/3).
   - **`MundaneStation` drains past a ttlilt pause** (open): the headless run completes the
      `De:populate` items + exports and shows `round=3`, where the fixture captured a *mid*-
       ttlilt `see:ttlilting...` paused state. Not a normalization gap — the node clock lets the
        drive walk through a timed pause the browser honoured. This is the next real
         investigation: the ttlilt hold needs to gate the headless drive the way it gates UItime.
- **Emission frequencies** — the dump is "everything-at-once"; add a "pause-as-soon-as-wobble"
   mode (stop + dump at the first non-fuzz surprise).
- **Diff channels** — the pile is `Snap:H` + trace; add `Snap:cont`/`Snap:refs` once the
   encoder merge (`Story_next_level` §1–2) lands, so "grep a kind of diff" gets richer.
- The pile (grep/diff offline) replaced the originally-floated telnet REPL — for an agent,
   files beat a socket. A live telnet hang is still possible later for a *paused* run.
