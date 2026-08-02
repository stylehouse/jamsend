---
name: runner-shot-pixel-loop
description: runner_shot.mjs closed the pixel loop — take a PNG of the live Cyto canvas over the runner_ask rails; diag_cures rides the reply
metadata: 
  node_type: memory
  type: project
  originSessionId: 6e81e17b-0313-4c6b-a20b-2ea29c407d71
---

`scripts/runner_shot.mjs` (built 2026-07-10, committed shape in d86c6098 + refinements after) takes a
PNG of the LIVE Cyto canvas: `op:'shot'` in `Lies_runner_ask_recv` (LiesFunk.svelte) calls `cy.png()`
— `cy` is stashed on `top_House.c.cy` by Cytui onMount.  Usage: `node scripts/runner_shot.mjs
[out.png] [--viewport] [--scale=2] [--runner=<prefix>]`; targets the runner_ask sticky by default.

**Why it matters:** render/animation faults were eyes-only (metaphysics: nothing render-side snaps) —
the owner had to complain instead of me checking.  Now: run Book → shot → LOOK.  The
Voro_render_faults gauntlet is mostly shot-runnable; only MOTION quality (flashing, pacing) stays
eyes-on.

**Gotchas:** the tab must be RELOADED once after the handler/stash first lands (onMount stash).  The
reply also carries `diag_cures` — the diagonal-satan auto-cure tally (Cytui `diag_check`: post-settle
covariance spread ratio < 0.1 ⇒ free relayout, randomize on repeat) — `♒ ×N` on the CLI line, so the
satan is remotely detectable.  See [[verify-via-live-runner]], [[reactap-reactivity-census]] (same
corr-rails pattern).

----
## merged from probe-why-before-gate-run.md

---
name: probe-why-before-gate-run
description: "runner_shot --runner=<PREFIX> silently times out (unroutable bare prefix) and reads as a 'stale/dead tab' — court via runner_ask first (sets the sticky full prepub), then call runner_shot WITHOUT --runner"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 12f2682d-1c3e-4f5e-ba2c-7e09ee65b139
---

2026-07-14: to close the live SVG gate for 1b+cs, `runner_shot --why/--svg/--arm --runner=<prefix>` timed out on ALL runners — I wrongly concluded the tabs were "stale / HMR-dead" and burned a debugging saga (+two toc-clobbering VoroMitosis runs). ROOT CAUSE: `runner_ask` COURTS a `--runner=<prefix>` (resolves it to the full prepub via the cluster beacons, addresses `to:<full-prepub>`, and writes that full prepub to the sticky `/tmp/runner_ask.target`). `runner_shot` does NOT court — it puts `--runner=<prefix>` RAW into `to:`, and the relay routes only by FULL prepub or the 'runner' role, so a bare prefix drops silently → 12s timeout. The handlers (op:'why'/'svg'/'face' in LiesFunk `Lies_runner_ask_recv`) were fine all along; via the sticky (full prepub) they replied instantly. Gate then PASSED: facts render as typed key + lilac `: ` (vsub-colon) + value tspans, `woodystem ×3` as key + `×3` sup — composed at paint from typed k/v/n, not re-parsed; regions/rivers + 1 promotion receipt confirm cs exercised. Hardened runner_shot to resolve a short --runner against the sticky (or warn).

**Why:** CLAUDE.md already says `runner_shot --runner=` takes a "RAW relay addr — court via runner_ask first". A prefix is not raw/full; it looks dead instead of erroring. Distinct tell vs a real stale tab ([[hmr-socket-dead-tell]]): a genuinely-reached handler REPLIES ok:false ("no render telemetry / unknown op"), it never times out — a TIMEOUT is a routing/addressing miss, not a stale handler.

**How to apply:** to shoot a specific runner, `node scripts/runner_ask.mjs state --runner=<prefix>` FIRST (courts it, writes the full prepub to the sticky), then `runner_shot --why/--arm/--svg` WITHOUT --runner (reads the sticky). A `runner_shot` render-op timeout means BAD ADDRESS, not a dead tab — check the sticky is a full 16-hex prepub. Still: use a COMMITTED Book as the gate vehicle (a run's story_save clobbers the toc; committed = `git checkout`-recoverable), NEVER a Book whose toc is dirty-uncommitted ([[toc-collapse-orphaned-save]]).

2026-07-14 late, the SECOND shot gotcha: **arm the faces BEFORE the run, shoot IMMEDIATELY after done.** `runner_shot --arm` AFTER a Book finishes fires a fresh morph over the TORN-DOWN run world — the why-strip says `morph✗ von:1 seeds:0 need:<2 seeds` — which CLEARS the standing glass, and the plain shot right after `done` also found it empty on a fresh-reloaded tab (the mid-run glass doesn't survive to an unarmed post-run shot there). The order that works: `runner_shot --arm --face=…` FIRST (prefs stick per-tab via Cyto_* stash), THEN `runner_ask run <Book> --watch --runner=…`, THEN `runner_shot --svg` with no arm. An "empty glass" right after a green run = arming-order miss, not a render regression.
