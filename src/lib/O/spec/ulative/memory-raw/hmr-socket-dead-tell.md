---
name: hmr-socket-dead-tell
description: "a long-lived tab can serve STALE Cytui — HMR socket dies OR the browser cache pins old JS; src edits never land while relay ops keep working. PROVE it's the tab not the dev server by node-fetching the served bundle; tell = runner_shot --arm says 'no cy_face hook — old Cytui'; fix = HARD reload / unregister SW / restart vite (soft reload can't bust it)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 127f6ff9-4278-4954-b130-ada7f9af70d9
---

**A runner tab can be half-alive: relay socket fine, Vite HMR socket dead.** Found 2026-07-12:
 `runner_ask`/`runner_shot` all answered (shots, snaps, dispatch — the `/relay` ws), but an edit to
  `src/lib/O/Cytui.svelte` never executed in the tab — a fresh unconditional `vlog()` probe line never
   appeared in the `--why` film strip across repeated repaints. Two sockets, two fates.

**Why gen edits mask it:** `src/lib/gen/**/*.go` freshness does NOT ride HMR on a runner — the runner
 ACQUIRES the spine via Creduler on every `become_book` ([[creduler-runner-architecture]]). So .g→LocalGen
  rounds keep landing while .svelte edits silently don't — which reads as "my ghost change worked but my
   UI change did nothing", a very confusing split.

**The tell:** add a cheap unconditional-on-first-pass `vlog('<probe>', …)` in the edited render path and
 `runner_shot --why` — if repaints happen (fresh `morph` lines) but the probe never shows, HMR is dead.

**How to apply:** don't debug the feature — reload the tab (no remote reload op exists on the relay as of
 2026-07-12; the human must do it). After ANY long runner session, assume .svelte edits need a tab reload
  before pixel-verifying. See also [[hmr-remixes-ghost-methods]] (the opposite failure: HMR alive but
   construction-captured refs stale).

**2026-07-15 — the WORSE variant: a whole session "not landing" in ANY tab (incl. freshly opened), the
 human seeing nothing.** Diagnosis ladder, in order:
 1. **PROVE it's the tab, not the dev server** — node-fetch the served bundle and grep for a recent
     identifier: `node -e 'fetch("http://172.17.0.1:9091/src/lib/O/Cytui.svelte").then(r=>r.text()).then(t=>console.log((t.match(/vsub_grab/g)||[]).length))'`. If it prints >0, Vite is serving your code FINE and the tab is stale. (curl may be absent in the sandbox; node fetch works, same as runner_ask's socket.)
 2. **The tab-side tell:** `runner_shot --arm --runner=<id>` replies `no cy_face hook — this tab runs an
     old Cytui` on EVERY tab, even one just opened — that's a client-cache pin, not a per-tab HMR death.
 3. **`runner_ask reload` can't fix it** — it's a SOFT `location.reload()` that reuses the browser cache.
     There's no cache-busting reload op over the relay; the human must HARD-reload (Ctrl/Cmd+Shift+R).
 4. **Service worker:** `src/service-worker.js` exists (SvelteKit auto-registers it). The CURRENT one is
     pass-through (caches NOTHING), so it's usually innocent — but an OLD *caching* SW version can linger
      in a browser and keep serving a stale shell; DevTools → Application → Service Workers → Unregister,
       or restart the vite dev server (re-versions modules), is the sure fix.
 5. **CANARY to confirm propagation once reloaded:** ship a blatant visible change (e.g. append `?` to a
     label) — when it appears, the pipeline works; then revert it.
Don't chase a phantom code bug while the tab is stale — you'll "fix" already-correct code blind.

----
## merged from hmr-remixes-ghost-methods.md

---
name: hmr-remixes-ghost-methods
description: "ghost methods DO re-mix onto the live House on HMR (ghostsHaunt → all_House); the handover's 'hard-reload after editing a ghost' is folklore"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4c70ad5a-6ab8-4d46-a931-c5c1f71d8040
---

Ghost methods **do** re-mix onto the live House on Vite HMR — the GhostCompile handover's bomb #6 ("Svelte HMR can swap the component without re-mixing; hard-reload the editor tab") is wrong/over-cautious.

Mechanism: `eatfunc` → `ghostsHaunt` (Housing.svelte.ts) does `this.ghosts = {...this.ghosts, ...hash}` then `for (const h of this.all_House) Object.assign(h, this.ghosts)`. `all_House` (`:466`) = the House + every subHouse recursively, downward. And the code asserts the trigger: `LiesCortex.svelte:320` "once required, Vite's HMR re-runs eatfunc on every hot update"; `LiesLies.svelte:610` "Ghost_version_checkin — called from the core ghostsHaunt on every HMR/haunt." So editing a ghost (.svelte) → HMR re-runs its onMount eatfunc → re-mixes its methods onto every House.

**The real caveat** (what likely misled the handover author): re-mix freshens anything DISPATCHED through the House — `this.foo()`, `H.foo()`, `i_elvisto → e_foo`. It does NOT freshen a function VALUE captured by reference at construction and stashed (a closure on a particle's `.c`, a once-registered callback). Those hold the old function until re-registered. The eatfunc pattern dispatches via `H.method`, so most things re-mix; the handover's "started worked in both old w.c and new H.c" confusion was an H.c-vs-w.c routing issue, not a re-mix failure. Supersedes the hard-reload advice in [[ghost-compile]].

----
## merged from method-flood-stale-gen.md

---
name: method-flood-stale-gen
description: "a \"!method: X\" console flood = an ambient think hit a world whose method isn't on H — usually a STALE/PARTIAL gen after a .g regroup (recompile ALL moved .g)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6e81e17b-0313-4c6b-a20b-2ea29c407d71
---

`💭 A/w !method: Method` (Housing.svelte.ts `_Aw_think`, line ~1307) fires when an AMBIENT elvis
(`!e.sc.Aw` → targets every world, `_e_targets_T` returns 2) reaches a `w:` whose method doesn't
resolve on H.  TWO causes: (1) an INERT report world with no drive method by design (e.g.
`w:Voronoiology` — expected, benign, every crush beat); (2) a genuinely MISSING method.

**The load-bearing case (2026-07-10):** after the owner regrouped Book-drives into
`Ghost/Story/Voronation.g`, the committed `src/lib/gen/Story/Voronation.go` was a STALE PARTIAL
(185 lines for a 606-line source) — it had VoroMitosis/VoroRadioPier but NOT VoroScape/VoroClinic/
Botany_plant.  So the runner loaded a Voronation ghost missing `VoroScape` → `this.VoroScape`
undefined → `!method: VoroScape` flood AND the Book's drive never ran → the world snapped nearly
empty (just belief `self,round=N`, `visible=2 bare:self`).  "Is this test just this now?" = it was
never running; a husk.  **Fix: recompile the .g** (`GFILES="Ghost/Story/Voronation.g" node_modules/.bin/vitest
run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts`) → 675-line complete gen → reload.

**Rules:** after a regroup/move of methods between .g files, RECOMPILE EVERY moved .g — a partial
gen loads a husk, no error, just missing methods.  The `!method` warn is now `V.beliefs`-gated (was
the only ungated one; siblings 1297/1301 always were) so the inert-report-world case doesn't flood.
See [[runner-shot-pixel-loop]] (the render telemetry `wave stuff:0` every beat = empty world, catches
this faster than the console), [[gen-crosswire-runner-dead]], [[ghost-compile-after-g-round]].
