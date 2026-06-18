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
| node               | the real repo                | `/tmp/Story_cli_fs` sandbox        | done     |
| OPFS-from-GitHub   | github snapshot in OPFS `seed/` | OPFS `scratch/`                  | **done** |
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
- **OPFS-from-GitHub is two OPFS subdirs, NOT a live network nav.** `seed/` is hydrated ONCE from
   github and thereafter read-only; `scratch/` takes every write. After hydration the nav makes no
    network calls — it's the same two-root overlay as the node backend, just over
     `FileSystemDirectoryHandle`s instead of fs paths. So Story saves (`story_save` writes toc.snap on
      every run) land in `scratch/` and persist across reloads, while `seed/` stays pristine github.
- **Hydration is CORS-safe by construction.** ONE `api.github.com/.../git/trees/<ref>?recursive=1`
   call lists the repo (CORS-enabled, but unauthenticated = 60/hr — so we spend exactly one); every
    blob then comes from `raw.githubusercontent.com` (a CDN, also CORS-enabled, no API budget). Don't
     "optimise" blob fetches back onto the contents API — that would burn the 60/hr on the first seed.
- **Idempotency rides a marker file**, `seed/.seed_ref`, holding `<ref> :: <subpaths>`. The auto-mount
   calls `mount_opfs_github_nav` unconditionally; `seed_from_github` reads the marker and, on a match,
    returns without a single fetch — so a return visit remounts near-instantly. Change `ref` or the
     subpath set and it re-hydrates; pass `force` to redo.
- **Seeded subpaths are bounded on purpose** — default `['wormhole','Ghost']` (~239 files): the Story
   books plus the top-level ghost source Lies compiles. Widen `subpaths` to carry more of the tree,
    but the recursive Trees call can `truncated`-clip on a huge repo (we log it) — seed narrower then.
- **No backend → reads reply `{error}`, NOT `{not_found}` — and a naive reader fatals on it.**
   `Auto.go` loads `wormhole/Present/toc.snap` on boot; with no share open (and the cloud not yet
    mounted) the worker replies `{error:'📭 nav not ready'}`, whose absent `.content` decoded as the
     fatal `['empty snap']` every tick (`Auto.go:102`). Fixed there: an `{error}` reply now drops the
      finished req and re-issues next think (wait, don't decode); `not_found` OR empty content both
       mean "no library yet" → seed defaults. Any reader of `rw_op`/`wh_op` must treat `{error}` as
        not-ready, not as content — Story/LiesStore already gate on the req, this was the one that didn't.
- **The cloud auto-engages when there's no local share** (DirectoryOpener) — that is the point: out on
   the web there is no directory picker. The mount is fire-and-forget OFF the tick mutex (a fresh seed
    is hundreds of fetches; awaiting it in-tick would freeze the machine). State rides `A.c.cloud_*`
     (runtime refs, never snapped — the ONLY safe things to mutate from the off-mutex promise); the
      promise just sets `A.c.nav` and pokes `H.main()`. "Open directory" stays enrolled as a dev
       override (it nulls `A.c.nav` so the worker rebuilds `WormholeNav(DL)`). NB this also auto-seeds
        on a fresh localhost dev load before you pick a dir — harmless (OPFS-cached) but gate on
         `location.hostname` if that ever annoys.

## The arc (how we got here)

Built `-I` (include a throwaway shim Book) → ran Peregrination to see if "everything" works →
 it ran (5 steps) BUT the minimal inline `nodeNav` shim gave the booted machine repo-root write
  access, so the Lies pipeline wrote real `gen/`/`Ghost/` source and nearly overwrote an
   in-progress `Peregrination.go` edit → replaced the shim with `NodeWormholeNav`, an overlay that
    sandboxes writes → verified the tree stays byte-identical across a full compile-pipeline run.

Then the browser counterpart: realised OPFS hands back a `FileSystemDirectoryHandle` — the SAME
 shape the File System Access API gives — so the node backend's two-root overlay ports almost
  verbatim, just walking handles instead of fs paths. Built `OpfsOverlayNav` over `seed/`+`scratch/`,
   a one-API-call github hydrator (Trees → raw CDN) guarded by a marker, and wired a "Use cloud"
    action into `DirectoryOpener` (plus silent remount when the marker says OPFS is already seeded).
     This is what makes Story a medium of the web: open the app cold out on the web, the books
      hydrate, saves persist in OPFS — no local directory picker.

## Next move

1. **Verify in the real app on :9091.** Browser-only (OPFS + fetch), so it can't be headless-checked
    the way the node backend was. With no local dir open, the cloud auto-mounts — confirm the Library
     loads (no more `empty snap` spam), a Story book runs from the seed, and a save survives reload
      (lands in `scratch/`). Watch the one Trees call + raw fetches in devtools; confirm no second API
       hit on reload (marker short-circuit). REQUIRES `stylehouse/jamsend` be public — if it's private
        the unauthenticated Trees/raw fetches 404 and the mount surfaces "cloud failed"; that needs a
         token story (out of scope here).
2. **Records-as-files for Identities** — expose the IndexedDB Identity schema under an
    `identities/` path namespace; "switch who you are" = read a different record; store the record
     in the music-collection directory so procuring music procures identity.
3. Now worth doing: factor a shared `WhNav` interface/type that `WormholeNav` (browser),
    `NodeWormholeNav`, and `OpfsOverlayNav` all declare against, so the contract — `read_file`,
     `write_file`, `dir` — is named in one place instead of three. Three implementations is the
      point where the duck typing has earned a name.

## Files

- `src/lib/O/Housing.svelte.ts` — `WormholeNav` (browser, wraps a DirectoryListing ~1900); the
   `Wormhole` worker + `A.c.nav` seam (~1730); the `rw_op` read/write/list path (~1810). The
    `DirectoryOpener` actor (~1625) auto-mounts the cloud nav when there's no local share (fire-and-
     forget, state on `A.c.cloud_*`), keeping "Open directory" as a dev override. Both `w:DirectoryOpener`
      and `w:Wormhole` live under the same `A:Wormhole` (~1603), so `A.c.nav` set by one is read by the other.
- `src/lib/O/Auto.go` — Library loader (`wormhole/Present/toc.snap`); now treats an `{error}` reply as
   not-ready (re-issues) and empty content as defaults, instead of fatalling on `['empty snap']`.
- `src/lib/O/WormholeOpfs.svelte.ts` — the OPFS-from-GitHub backend: `OpfsOverlayNav` (read/write/dir
   over two `FileSystemDirectoryHandle`s), `seed_from_github` (Trees API → raw CDN, marker-guarded),
    `mount_opfs_github_nav` / `opfs_github_seeded` orchestrators, `JAMSEND_SOURCE` default. Browser
     app code (every API it touches is a browser API) — unlike the node backend, it is NOT in the harness.
- `scripts/NodeWormholeNav.ts` — the node overlay backend (read/write/dir on `node:fs`).
- `scripts/Story_cli.spec.ts` — injects it: `WA.c.nav = new NodeWormholeNav(ROOT, '/tmp/Story_cli_fs', ACCEPT)`.
- Related (the `-I` include that prompted running Peregrination): `scripts/Story_cli_run.mjs`
   (`-I <shim>` / `-b <Book>` / `--accept`) and `scripts/Story_cli.svelte` (the `include` prop +
    M-shim). An `-I` shim is just ghost code to add — a `<script>`-only `.svelte` that deposits a
     worker via `M.eatfunc`. See `Story_cli_docs.md` + the `scripts/Story_cli.spec.ts` header for the runner proper.

## Working-tree state at handoff (uncommitted)

Mine, ready to commit: `src/lib/O/WormholeOpfs.svelte.ts` (new); `src/lib/O/Housing.svelte.ts`
 (DirectoryOpener auto-mounts cloud when no share + import), `src/lib/O/Auto.go` (no-nav reply no
  longer fatals), this file (modified). One batch: the OPFS-from-GitHub backend + its auto-engage.
   Typechecks clean — the only `npm run check` hits in the edited range are pre-existing baseline
    noise (`trace`/`mutex`/implicit-any on `House`/worker params), none in the new code. Not yet
     runtime-verified in the browser — that is next move #1.
   (The node backend + `-I` include from the prior handoff landed in commit `98a63f87`.)
