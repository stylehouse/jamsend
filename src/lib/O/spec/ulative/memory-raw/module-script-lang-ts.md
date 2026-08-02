---
name: module-script-lang-ts
description: "bare `<script module>` with TS breaks Vite optimizeDeps esbuild scan — needs lang=\"ts\"; surfaces when a new dep triggers a re-scan"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2a47a269-1da9-4165-9d39-21bcea3120d2
---

A `<script module>` (Svelte 5 module block) that contains **TypeScript** (e.g. a param
annotation `node: HTMLInputElement`) but **lacks `lang="ts"`** compiles fine under
`svelte-check` and the normal Svelte/Vite compile — but **breaks esbuild's `optimizeDeps`
dependency scan**: `✘ [ERROR] Expected ")" but found ":"` at the annotation, "Failed to scan
for dependencies from entries", dev server won't boot.

**Baffling trigger:** the scan only re-runs when the optimized-deps cache is invalidated —
e.g. adding a NEW bare import somewhere unrelated. So an import in file A surfaces a latent
parse error in module scripts of files B/C. (Here: adding `import diff-match-patch` to
Langui surfaced bare module scripts in `ui/DocRow.svelte` + `ui/Waft.svelte`.)

**Fix:** `<script module lang="ts">`. Grep for offenders: `grep -rn '<script module>' src/ | grep -v 'lang="ts"'`.

If it persists after fixing (stale Vite state / black screen, "optimized dependencies changed.
reloading"): hard-refresh, else `docker compose restart app`, else nuke caches
`docker compose exec app rm -rf node_modules/.vite .svelte-kit` + restart. See
[[running-check-in-container]].
