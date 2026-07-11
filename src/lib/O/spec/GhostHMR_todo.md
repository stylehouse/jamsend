# GhostHMR — runners pick up new code live, no refresh

## 0. Next

The arc: a runner must acquire the editor's freshly-compiled `.go` **live, via Vite HMR** —
 never by a manual tab refresh (the current reality, which is absurdly broken). No new push
  machinery: the pushes that already exist (rungo demands, GhostLedger pins) become the
   *check* that code landed, not the delivery. Delivery is Vite's job.

### ✅ STEP 0 IS DONE — THE HMR CLAIM IS PROVEN (2026-07-11, mid-run, no reload)

The GhoghoDrone graffiti probe (below) was run end-to-end on the LIVE runner and it **worked**.
 A Story-ghost `.go` (`gen/Story/Radiation.go`) hot-swapped **mid-run** and the very next step
  picked up the new code — no tab reload, same run uid throughout. The evidence, airtight:
- Started GhoghoDrone (uid `db1d6401`), let it step. Recorded fixtures from a prior run pinned
   `mark:steady`, so this run was `'check'` mode against them.
- At ~step 10 edited `GhoghoDrone_beat`'s `mark: 'steady'` → `'graffiti'` in `Ghost/Story/Radiation.g`
   and `ghost_compile`d it. The editor wrote `Radiation.go` (dige `c2c3dc73a6d32777~g1`, `mark:'graffiti'`).
- The run **kept the same uid and never reloaded** (state polled continuous 2→…→20). Got_snaps
   read back by `@uid`: **steps 1–10 `mark:steady`, steps 11–20 `mark:graffiti`.** The crossover is
    step 11 — the first beat after the compile landed.
- Independently corroborated by the check-mode `ok_pct` trajectory: `done=11→0.91` (10 ok, 1 bad =
   step 11, first graffiti), `done=18→0.56` (10 ok, 8 bad = steps 11–18). Exactly 10 steady + graffiti-tail.

**So the todo's pessimism about `Lies_ghost_set` (load-once, `@vite-ignore`, no accepting boundary)
 was WRONG for the Story-ghost path — Vite already delivers the update AND the swapped instance
  re-runs its eatfunc live.** That reframes the work below: items 2–3 are largely *already true* for
   this path; the remaining value is (a) confirming the same holds for the `{N,M,S,V}` business spine,
    (b) making the swap first-class/visible (the `%ghost_swapped` caveat, item 5) rather than a silent
     `mark` change, and (c) the manifest cleanup (item 3) for the editor-graph-isolation guarantees —
      not for making HMR *work*, which it does.

**Loose end (relay-blocked at writing):** the probe left `Radiation.go` at `mark:'graffiti'` on disk;
 the steady recompile to restore parity kept failing on a half-open editor relay (tab-throttle wedge —
  run `scripts/editor_awake.sh` on the host). Before committing the Book: recompile the steady `.g`
   (editor awake) so `Radiation.go` carries `mark:'steady'` + its steady dige, then record ONE clean
    steady GhoghoDrone run for a green `wormhole/Story/GhoghoDrone/toc.snap` (the current toc holds the
     deliberately-red graffiti verdict). The 001–020.snap fixtures are the good steady gate already.

Next moves, in order:
1. ~~**Step 0 experiment**~~ — DONE, positive (above).
2. **One-ghost proof** — effectively DONE for the Story path via GhoghoDrone; still worth repeating on
    a `{N,M,S,V}` business-spine ghost (different load path — `Lies_ghost_set` early-return) to confirm.
3. Convert the spine to `Ghosts.svelte` + `ghost_manifest.ts` (design below) — now for editor-graph
    isolation + retiring the hand-kept list, NOT to make HMR work.
4. Per-Book Story-ghost selection.
5. eatfunc version check (`/^Ghost_version_/` class; mid-run swap = named caveat) — make the swap that
    GhoghoDrone just proved *visible* as `%ghost_swapped` instead of a silent behaviour change.
6. End-to-end CLI verification (recipes below), then retire `Lies_ghost_set`'s spine loading.

## What is known, empirically (2026-07-10)

- `svelte.config.js` `extensions: ['.svelte', '.go']` already makes every `.go` a compiled
   Svelte component. Fetched off the live dev server **as an import request** (`?import`, or a
    real browser import with `Sec-Fetch-Dest: script`), a `.go` comes back fully transformed
     **with `createHotContext` + HMR self-accept wiring** — identical treatment to `.svelte`.
      A bare header-less fetch returns raw source; don't be fooled by that in tests.
- The runner's only load path is `Lies_ghost_set` (LiesLies.svelte ~897):
   `import(/* @vite-ignore */ \`../../lib/${gen}\`)` behind an already-enrolled early-return.
    Loaded once, never re-imported. Everything downstream (rungo park-and-poll,
     `Lies_ledger_secure`'s 20s hold) compensates for that by *waiting* for code that today
      never arrives — runs time out red or the human refreshes the tab.
- gen dirs are clean and exactly mirror the curated `CREDULER_GHOSTS` list:
   `gen/{N,M,S,V}/*.go` = the 13-ghost business spine; `gen/Story/*.go` = the 4 story ghosts
    (Musuation, Peregrination, Radiation, Swarmation). **The dirs ARE the manifest.**
- Mount plumbing already right: `.go` components are mounted hidden (BigSoundland
   `spine_shims`), instance script runs `eatfunc` → `ghostsHaunt` deposits methods + Ghostmeta
    on EVERY House → `Ghost_version_checkin` wakes thinks. ONE mount suffices for all Houses.

## Step 0 — the experiment (do this first)

Unknown: does a `.go` change emit an HMR update the runner applies, and does a hot-swapped
 instance re-run its eatfunc (fresh Ghostmeta)? Candidates for the snapped link: the
  `@vite-ignore` URL never entering the client graph properly; the update not reaching an
   accepting boundary; the swap not re-running the instance script.

Recipe (live runner on :9091, NOT headless):
1. `node scripts/runner_ask.mjs ping` — confirm live.
2. Append a harmless comment line **directly to a `.go`** (e.g. `gen/N/Reliable.go`) on disk —
    vite's watcher sees the same inode the editor's gen_write touches.
3. Within a few seconds, ask the runner whether the ghost's live dige moved (a Book run's
    ledger gate resolving, or read the `%GhostInclude,dige` off a snap; `Creduler_ensure`
     refreshes it every tick). Also worth watching: does the tab full-reload (Vite's
      no-accepting-boundary fallback)? A full reload would ALSO explain "runner seems stale
       until poked" symptoms differently.
4. **Revert the `.go`** — it's a generated file; direct edits are churn, never commit them.

If the swap lands but eatfunc doesn't re-run: the fix is in how the component re-instantiates
 (Svelte 5 HMR re-creates instances; instance-script eatfunc should re-fire — verify).
If no update fires at all: the `@vite-ignore` URL never registered client-side — the static/
 tracked import conversion below fixes it structurally.

## Design

### ghost_manifest.ts + Ghosts.svelte

- **`src/lib/O/ghost_manifest.ts`** — plain TS, import-light, safe to import ANYWHERE:
    ```ts
    export const SPINE = import.meta.glob('/src/lib/gen/{N,M,S,V}/*.go')      // lazy thunks
    export const STORY = import.meta.glob('/src/lib/gen/Story/*.go')          // lazy thunks
    ```
    Non-eager glob = **no static edges** (nothing dragged into the editor graph), but the
     modules are Vite-**tracked** (glob is analyzable), so once a thunk is awaited the module
      is a normal self-accepting HMR boundary. `Object.keys()` enumerates the manifest
       synchronously — `CREDULER_GHOSTS` derives from the keys (reverse of `Lies_gen_path`:
        `gen/N/Foo.go` → `Ghost/N/Foo.g`), killing the hand-kept list in LiesLies.
- **`src/lib/O/Ghosts.svelte`** — the runner's include spine: awaits every SPINE thunk +
   the Book-selected STORY thunks, mounts each component hidden (they render nothing).
    Reached ONLY by a literal dynamic `import('$lib/O/Ghosts.svelte')` on the runner boot
     path (where `spine_shims` mounts today — BigSoundland; check the /Otro Story-runner
      route too), gated on runner role. Replaces `Lies_ghost_set`'s spine loading and the
       Pantheate-include spine enrollment (NOT LiesRun.svelte's compile-run include path —
        that's the editor's, untouched).

### Story ghosts per Book

Small prefix map beside the globs: `Pere*→Peregrination, Musu*→Musuation, Ra*→Radiation,
 Swarm*→Swarmation`; keyed off `H.top_House().c.book` when become_book lands; **unknown Book →
  mount all** (today's behaviour as fallback). Interim stand-in for the `RENDER → manifest`
   item in `LangCompiler_TODO.md` — same seam, retires into it later.

### eatfunc checks versions — the `/^Ghost_version_/` class

`ghostsHaunt` already calls `Ghost_version_checkin()` on every haunt; today it only wakes
 thinks. Extend it to judge what landed:
- **Pre-run**: nothing new — the landed Ghostmeta satisfies the parked rungo / ledger hold,
   which flip from 20s prayer to sub-second confirmation.
- **Mid-run**: if a run-record is open and a landed dige MOVED a pinned ghost, stamp
   `%ghost_swapped,path,from,to` on the run record and surface a **caveat — deliberately not
    a fatal**: HMR-during-a-test-to-change-its-behaviour is a wanted capability; the swap
     must be first-class and visible, never silent. (`Lies_ledger_secure` must stash the
      secured pins, e.g. `w.c.run_pins`, so checkin has something to compare against.)
- Everything this seam raises is namespaced `Ghost_version_*` so runner_ask / the runner can
   classify version trouble by `key =~ /^Ghost_version_/`.

### Relation to the shipped GhostLedger (commit 8aa5d1de)

The ledger (editor-minted pins over the recompiled Codebit set; become_book carries head+pins
 inline; `Lies_ledger_secure` pre-run hold; `Ghost_version_ledger_timeout|_missing` fatals)
  was built as the safety net for exactly this staleness. With HMR delivering, the net stays
   but should almost never be seen waiting — its remaining job is the runner whose HMR ws is
    genuinely dead. Deferred ledger refinements (run_result carrying ledger_dige → stale
     badge; seq-based fatal precision) are unchanged by this work.

## Verification (live runner + CLI only — NEVER headless Story_cli_run)

- **Positive**: append a comment line to a spine `.g` (comment ⇒ dige moves, behaviour
   doesn't), `npm run ghost-compile -- Ghost/N/Reliable.g` (drives the LIVE editor to compile
    + write the `.go`), then WITHOUT any reload: runner's live dige moved + a Book runs green
     (`node scripts/runner_ask.mjs run <Book> --watch`). Afterwards **revert the `.g` comment
      AND ghost-compile again** so disk parity with the committed tree is restored.
- **Mid-run**: start a longer Book, ghost-compile mid-flight, expect the run to complete with
   the `%ghost_swapped` caveat visible in `runner_ask steps`.
- **GhoghoDrone — the purpose-built mid-run probe** (added 2026-07-11, `Ghost/Story/Radiation.g`
   + a `What:Misc/What:GhoghoDrone` row in `wormhole/Credence/toc.snap`). A brand-new Book that
    runs **20 steps, each held ~10s** by an `expecting()` ttlilt (a clean RESOLVE under a 12s
     ceiling) → **~200s of wall clock**, a wide window to graffiti mid-flight. No fixtures ⇒ Story
      runs it `'new'` mode; `GhoghoDrone_drive` forces `run.sc.total=20` so it steps 1..20 on its
       own and records. Each `GhoghoDrone_beat` stamps `w/%drone,at_step:N,mark:steady` — **edit
        `mark` (or the `%see` line) in the beat, ghost-compile, and the next held step's snap should
         carry the new value with no reload** (that is the whole HMR claim). Recipe once a runner is
          booted with the code: `node scripts/runner_ask.mjs run GhoghoDrone --watch` (set
           `RUNNER_WATCH_MS=250000` — the run outlasts the 120s default watch), then mid-flight edit
            + ghost-compile, and watch `runner_ask snap <n>` / `steps`.
      NOT YET COMPILED/RUN: the editor was unreachable headlessly this session (no ack on the
       `:9091` relay, `:9092` down), so `Radiation.go` is unregenerated and the Book is unverified —
        first awake step is to ghost-compile `Ghost/Story/Radiation.g` (editor) + reload a runner.
   - ghost-compile tooling note: `npm run ghost-compile` dies `EACCES` here — `node_modules/.vite-temp`
      (vite's TS-config bundle dir) is root-owned. Workaround that worked: a `.mjs` config in a
       scratch dir that has its OWN `node_modules/` with just a `vite` symlink (so the bundle temp
        lands writable), `EDITOR_URL=http://172.17.0.1:9091`, run `vite-node -c <that.mjs>
         /app/scripts/ghost_compile.ts -- <path>`. The relay/editor still has to answer.
- Editor sanity after the first reload: editor tab still boots its channel off
   `pinned_stable`, compiles, runs — i.e. the spine didn't leak into its graph.

## Traps (the bomb-defusal list)

- **The editor must NEVER ride the live spine** — `p2p/pinned_stable/*.go` is a deliberate
   frozen copy (LiesLies ~442). An *eager* glob, or importing `Ghosts.svelte` (or anything
    with static gen edges) into LiesLies/core, statically drags `gen/**` into the editor
     graph. Lazy globs + literal dynamic import behind runner role, only.
- `LiesRun.svelte`'s `Pantheate-include` + `req:include` path is the EDITOR's compile-run
   machinery — leave it alone.
- BigSoundland mounts `spine_shims` OUTSIDE the view switch for a reason (a persisted
   `sprawl` view once starved the boot) — `<Ghosts/>` must inherit that unconditional-mount
    guarantee.
- Direct edits to `gen/**.go` are generated-file churn: fine for experiments, always revert,
   never commit.
- Repo rules in force: verify on the LIVE runner only; wormhole churn reverted, commits by
   explicit path on the feature branch; snapped booleans are `1`-or-absent; read
    `Coding_guide.md` before touching req/ttlilt/belief-loop territory.
