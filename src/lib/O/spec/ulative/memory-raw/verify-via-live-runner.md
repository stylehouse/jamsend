---
name: verify-via-live-runner
description: "Verify Story Books via a real Lies%runner request (runner_ask.mjs), NEVER the headless Story_cli — it gives false greens"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ce9a058e-b2c4-4be7-8772-57abeb9cc55d
---

Owner BANNED the headless `scripts/Story_cli_run.mjs` for verifying Story Books (2026-06-29). Verify by making a **real Lies%runner request** to a LIVE runner instead — `scripts/runner_ask.mjs` (a CLI over the `/relay` websocket to a browser runner on :9091, booted `?B=<Book>`; reply is the live world, real wall-clock). Ops: `ping` · `run <Book> --watch` · `state` · `steps` · `snap <n>` · `rungos` (+ `@uid` for a held run). `RUNNER_URL` default `http://172.17.0.1:9091` (this container) / `http://localhost:9091` (host). Exit 1 = red run. `story_repl.mjs` = interactive twin. **Runners should always be available** — `ping` to check.

**Why (the bomb):** headless Story_cli boots node+jsdom with REAL DISK access, so it reads the wormhole off disk, loads the GhostList, and quiesces at `round=8`. The real runner quiesces at `round=4` with NO GhostList + `acquire` unfinished. So a Book recorded/verified headless matches *itself* but goes ALL-RED on a live runner (GhostList Good/dirlist-Funkcion/desire-Waft/o_elvis + boot-progress diverge — the test markers themselves still pass). My "all 4 Lake\* green 1/1" this session was a **bubble, not a gate**. Caught when owner ran them on the real runner and pasted the red Dif tree.

**How to apply:** never claim a Book green off Story_cli. Run it through `runner_ask.mjs` against a live runner; recorded fixtures must come from the live runner too. Now canonical in CLAUDE.md ("Running a Story Book: a real Lies%runner request, never headless"). The headless GhostList dige-spay I added to `Story.svelte` is a band-aid on the bubble symptom — drop it once the gate is real. See [[headless-creduler-runner]] (CredRunner is the faithful-ish headless twin), [[storyrun-run-record]], [[creduler-runner-architecture]], [[keeping-phase1-kindtable]].
