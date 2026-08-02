---
name: running-check-in-container
description: "how to run svelte-check / vitest in this container, and the root-owned-dir gotcha"
metadata: 
  node_type: memory
  type: project
  originSessionId: fa0ec816-b234-47f2-acb4-2627d6da2daf
---

`npm run check` (svelte-check) and vitest work in this container, BUT generated/cache
dirs are sometimes left **root-owned** while the session runs as `node`, giving `EACCES`:
- `/app/node_modules/.vite-temp/...` (Vite bundling the config) — fixed once node owns `node_modules`.
- `/app/.svelte-kit/tsconfig.json` and `.svelte-kit/generated/...` (svelte-kit sync writing).

**How to apply:** if a root-owned dir blocks the run, you usually can't `chown`/`rm` its
contents, but `/app` itself is node-writable, so **rename the dir aside** and let the tool
recreate it: `mv .svelte-kit .svelte-kit.old` then `npm run check` (runs `svelte-kit sync`).

**New-route variant (2026-07-03):** creating a NEW `src/routes/<X>/+page.svelte` while the
HOST dev server (root) runs → root-owned `.svelte-kit/types/src/routes/<X>/` (+ sometimes a
root `generated/client/nodes/N.js`).  `npm run check` then dies at its standalone
`svelte-kit sync` (update_types writes `$types.d.ts` UNCONDITIONALLY — no content-skip).
Workaround: run **`npx svelte-check --tsconfig ./tsconfig.json` directly** — the config-hook
sync throws per-style-transform EACCES noise into stderr/diagnostics but the check COMPLETES
with full type coverage (verify via the "svelte-check found N errors in M files" tail).
A root `nodes/N.js` can be `mv`'d aside (parent is node-writable); the types dir needs a host
chown.  Node numbering differs between host/container syncs — harmless, but the running dev
server may need a restart after container-side sync touched generated/.

**CAUTION:** moving `.svelte-kit` aside breaks a *running* dev server — the live Vite holds
`.svelte-kit/generated/server/internal.js` open and throws `Cannot find module '__SERVER__/internal.js'`.
The sync regenerates it, but the dev server needs a browser reload / restart to recover.
Prefer doing this when the dev server is down, or warn the user first.

Baseline noise: the codebase has ~2966 pre-existing svelte-check errors (mostly implicit-`any`
on untyped params, plus ~2900 "Property X does not exist on type 'House'" — eatfunc/ghost-injected
methods the House class type doesn't declare). To judge whether an edit regressed, grep the check
output for the edited file's line range — don't look at the total.

**OOM gotcha (2026-06-27):** `npm run check` can be **SIGKILL'd (exit 137)** before it emits any
diagnostics — `svelte-check` needs ~1.5–2G heap, and the **`claude`** compose service is capped at
`memory: 2G` (docker-compose.yml ~L149) with ~1.28G *anon* already resident (the agent/node tooling —
checked `/sys/fs/cgroup/memory.stat`, it's anon not reclaimable cache). The cap is **read-only from
inside** the container (can't `echo > memory.max`; no docker socket either). Fix on the HOST: live, no
restart → `docker update --memory 4g --memory-swap 4g $(docker ps -qf name=claude)`; persistent → bump
the compose `claude` service `memory` then `docker compose up -d claude` (RECREATES = ends the session).
Bumped the compose value to 4G this session. The `app` (dev-server) service is a *separate* container at
1G — its memory is unrelated to check's OOM.

**The total drifts run-to-run** (saw 2966 → 2970 across a session with no causal code change —
confirmed by reverting to the exact prior state and still getting 2970). svelte-check's
incremental cache re-attributes the ghost-on-House false-positives, so ±a-few on the total is
nondeterministic noise, NOT a regression. Only trust per-file/per-region diffs of the *edited*
files; a controlled revert (undo the edit, recheck) is the definitive test.

**There IS a CLI Story runner now** — `scripts/Story_cli.spec.ts` boots the whole machine in node
(vitest+jsdom+svelteTesting), drives a Book, and dumps `w:Story` to `/tmp/Story_cli/<Book>/` to
grep/diff. Run: `node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts`
(set `BOOK=`). Full details + gotchas in `spec/Story_cli_docs.md` (+ the `scripts/Story_cli.spec.ts` header) and [[story-cli-runner-boot]].
So you CAN now confirm a story from the CLI (PortPlanet proven: steps 1–4 match fixtures; 5–6 differ
only by `surprise=42`, a stale fixture). The pump's `$effect` is dead UIless → the runner cranks
Atime by hand. Note: container must run uid 1000 (the `app` compose service needed `user:"1000:1000"`
+ `chown node_modules`), else root-owned `node_modules/.vite*` → EACCES.
