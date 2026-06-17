# w:Wormhole — pluggable storage backends

## Destination

`w:Wormhole` becomes a **layered virtual filesystem with pluggable backends**, so the same
 app code reads/writes the project tree from wherever it lives: a user-picked directory, the
  node filesystem (headless tests), or — the goal — **OPFS seeded live from github.com**, so
   the in-browser app carries whatever it wants of the tree with zero setup (no directory
    picker). On top of that, IndexedDB schemas (starting with **Identities**) sync through the
     same contract so you can *switch who you are*; and a user's identity record lives inside
      their **music collection**, so whichever backend procures the music procures the who.

## The whole abstraction (don't widen it)

The Wormhole worker (`Housing.svelte.ts`, `async Wormhole(...)` ~1702; `rw_op` block ~1785)
 funnels EVERY I/O through `A.c.nav` and calls exactly three methods:

  - `read_file(dir, file): Promise<string|null>`
  - `write_file(dir, file, data): Promise<void>`
  - `dir(...parts): Promise<{ expand(), directories:[{name}], files:[{name}] } | null>`

That is the entire backend interface. A backend is any object with those three. The
 `if (!A.c.nav) …` line in the worker is the only plug — set `A.c.nav` and you've mounted a
  backend; production code never learns which one.

The one composition primitive is the **overlay**: a read-through *seed* layer + a write-to
 *scratch* layer. Every backend in the plan is that shape with different layers:

| backend            | seed (read) layer            | scratch (write) layer              | state    |
|--------------------|------------------------------|------------------------------------|----------|
| browser dir        | user-picked FS-Access dir    | same dir                           | shipped  |
| node               | the real repo                | `/tmp/Story_cli_fs` sandbox        | **done** |
| OPFS-from-GitHub   | a github.com-procured snapshot | OPFS (`navigator.storage.getDirectory()`) | next |
| records-as-files   | (a schema exposed as paths)  | same                               | planned  |

Express **seeding** as a read-only lower layer, and **records** (Identities) as file *paths*
 (`identities/<who>.json`) — NOT as new nav methods. The temptation to add `list`/`seed`/`sync`
  is the thing to resist; it would make `Housing.svelte` backend-aware. Keep it at read/write/dir.

## The bombs (what detonates if the next reader doesn't have it)

- **`Housing.svelte` is in the browser bundle — it CANNOT `import 'node:fs'`.** Any node-only
   backend must live outside app code and be **harness-injected** via the `A.c.nav` seam. That
    is why `scripts/NodeWormholeNav.ts` lives in `scripts/` and the runner sets `WA.c.nav`
     before the worker first runs. Do not "tidy" it into `Housing.svelte`.
- **`story_save` writes `toc.snap` on EVERY run, not just `ACCEPT`** (Story.svelte ~1759). Before
   the overlay, that meant every plain headless run dirtied `wormhole/Story/<Book>/toc.snap`
    (TimeSpool sample drift). The node overlay sends those writes to the sandbox, so plain runs
     leave the tree pristine; only `ACCEPT` lets `wormhole/` writes pass through to the real repo.
- **Booting a compile-pipeline Book writes real source.** Lies compiles docks and writes
   `gen/*.go` + `Ghost/*.g` through the rw_op path (e.g. running Peregrination logs `LiesStore
    wrote gen/Story/Peregrination.go`). Pre-overlay this hit the working tree and would clobber an
     in-progress hand-edit of a generated file. These writes are **persistence-only** — the run
      uses in-memory compiled results, so diverting them to the sandbox does NOT break the run
       (verified: a Peregrination run with all writes overlaid leaves `git status` byte-identical).
- **Overlay read order is overlay-shadows-base.** A file written this run (to the sandbox) is
   read back from the sandbox; otherwise it falls through to the repo. So read-after-write within
    a run is coherent even though the repo never changed.
- **Peregrination is `match: 0/5` — not a runner bug.** Its fixtures are mid-development; heading-3
   proof is in-app only and the step-3 dige isn't recorded yet (see `Peeroleum_handover.md`).

## The arc (how we got here)

Built `-I` (include a throwaway shim Book) → ran Peregrination to see if "everything" works →
 it ran (5 steps) BUT the minimal inline `nodeNav` shim gave the booted machine repo-root write
  access, so the Lies pipeline wrote real `gen/`/`Ghost/` source and nearly overwrote an
   in-progress `Peregrination.go` edit → replaced the shim with `NodeWormholeNav`, an overlay that
    sandboxes writes → verified the tree stays byte-identical across a full compile-pipeline run.

## Next move

1. **OPFS-from-GitHub backend.** Hydrate a read-only seed from github.com (contents API or a
    tarball fetch) into OPFS once, then serve reads seed→OPFS, writes→OPFS. Browser-side, so it
     can't be headless-verified the way the node backend was — drive it in the real app on :9091.
2. **Records-as-files for Identities** — expose the IndexedDB Identity schema under an
    `identities/` path namespace; "switch who you are" = read a different record; store the record
     in the music-collection directory so procuring music procures identity.
3. Optional first: factor a shared `WhNav` interface/type that `WormholeNav` (browser) and
    `NodeWormholeNav` both declare against, so the contract is named in one place.

## Files

- `src/lib/O/Housing.svelte.ts` — `WormholeNav` (browser, wraps a DirectoryListing ~1885); the
   `Wormhole` worker + `A.c.nav` seam (~1702); the `rw_op` read/write/list path (~1785).
- `scripts/NodeWormholeNav.ts` — the node overlay backend (read/write/dir on `node:fs`).
- `scripts/Story_cli.spec.ts` — injects it: `WA.c.nav = new NodeWormholeNav(ROOT, '/tmp/Story_cli_fs', ACCEPT)`.
- Related (the `-I` shim that prompted running Peregrination): `scripts/Story_cli_run.mjs`
   (`-I <shim>` / `-b <Book>` / `--accept`), `scripts/SuchATest.svelte`, `scripts/Story_cli.svelte`
    (the `include` prop + M-shim). See `Story_cli_handover.md` for the runner proper.

## Working-tree state at handoff (uncommitted)

Mine, ready to commit: `scripts/NodeWormholeNav.ts`, `scripts/Story_cli_run.mjs`,
 `scripts/SuchATest.svelte` (new); `scripts/Story_cli.spec.ts`, `scripts/Story_cli.svelte`,
  `Story_cli_handover.md`, this file (modified). The `-I` include + node backend are one batch.
   (`Story_cli`'s Accept path, the sweep, and the `until_ts` mung rule already landed in commit
    `9f109772`.) Safe to revert: `wormhole/Story/LakeNets/toc.snap` is a confirmed pre-overlay
     run artifact — `TimeSpool` sample drift only (step diges unchanged), written by a sweep run
      that reached LakeNets before the overlay existed. `git restore` it; not an intended change.
