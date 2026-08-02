---
name: ghost-compile-after-g-round
description: "after a ROUND of .g edits, run ghost-compile on each so they HMR live into the runners — never leave .g hacks disk-only"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a3077b3c-d41a-4880-939d-0bb7c8c747ac
---

After hacking `.g` files, run `npm run ghost-compile -- <file.g>` on each — once, after a whole ROUND of edits (not per-file mid-round). The relay → live editor recompiles and the new gen **HMRs into the running runners**, so the live :9091 session reflects the disk edits.

**Why:** a `.g` edit on disk is inert to the live session — the Creduler only re-acquires the spine on a fresh boot, so an already-running runner keeps executing stale gen. ghost-compile is the live bridge: it pushes the recompiled gen into the running runners without a reload. Headless harnesses (Story_cli/FlockCompile) prove a `.g` *parses*, but they don't HMR your real browser session.

**How to apply:** at the end of a .g-editing round, ghost-compile each changed `.g`. Needs the editor open on :9091 (it owns the only compiler; a down channel just no-ops). See [[ghost-compile]] for the loop mechanics + content-addressed dige, and [[creduler-runner-architecture]] for how runners acquire the spine.

**RUN vs COMPILE — the split after CredRunner (2026-06-25).** The COMMITTED gen now runs headless: `scripts/CredRunner.spec.ts` drives a Creduler-acquired Book's BEHAVIOUR (not just parse) with zero browser ([[headless-creduler-runner]]). But ghost-compile is STILL the only way to turn a `.g` EDIT into a `.go` — FlockCompile compiles in-memory (no write), and there is no headless `.go` writer yet (that's runner-access **Tier 2**, the next runner investment). So: to verify the committed spine, run CredRunner headless; to test a `.g` EDIT, you still ghost-compile on :9091 (or build Tier 2). CredRunner `import`s `gen/**/*.go` — it will NOT pick up uncompiled disk edits, so a green CredRunner after a `.g` edit you didn't compile is testing STALE gen.

**ghost-compile HANGS on a SPINE ghost against a live runtime; use LocalGen instead (2026-07-08).** Tier 2 exists now — **`scripts/LocalGen.spec.ts` is the browserless `.go` WRITER** ([[localgen-browserless-compile]]), and it is the ONLY reliable way to compile a heavily-depended-on SPINE ghost (`Ghost/M/Ra.g`, and likely the other spines). ghost-compile of a spine `.g` against a live editor **times out with no reply** — recompiling it HMR-remixes the spine into the running runtime and WEDGES it (proven: even appending a trivial valid method hangs; only the pristine no-op hash replies; leaf Book ghosts like `Radiation.g` compile fine because nothing depends on them). Escape: `GFILES='Ghost/M/Ra.g' CHECK=1 npx vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts` to VALIDATE (compile-only, diffs vs committed), drop `CHECK=1` to WRITE the gen. No editor, no HMR, no wedge — surfaces the real `compile_error`. Do NOT bisect a "parse-storm" by hammering ghost-compile: a wedged editor makes EVERY change hang, confounding the bisect (a whole session lost to this). Correct the stale claim above: the headless `.go` writer DOES exist.

**EDITOR_URL may need forcing (2026-07-20):** ghost-compile's default target answered on
:9092 with no editor connected in the standing dev-container setup — pass
`EDITOR_URL=http://172.17.0.1:9091 npm run ghost-compile -- <file.g>` when a compile
gets no editor. Leaf ghosts (`Ghost/V/Vyto.g`, `Vytonation.g`) compiled clean there.

**An IDLE editor also times out ghost-compile (2026-07-11)** — even the leaf `Radiation.g`, editor
tab alive and channel healthy: the compile chain needs a DENSE think stream (user presence), and an
idle editor thinks only on the sparse beacon-nudge trickle, so the reply misses the CLI's 12s window.
LocalGen is the dependable path whenever no human is at the editor. And its disk `.go` write DOES
HMR into live tabs (proven 2026-07-11: a live runner picked up a LocalGen-written gen with no
reload — the sabotage run stepped the new code).
