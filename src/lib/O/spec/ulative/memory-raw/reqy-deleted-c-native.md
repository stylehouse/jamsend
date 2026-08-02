---
name: reqy-deleted-c-native
description: "reqy() is deleted; the req machine is C-native (oai/doai/do/finish) — CLAUDE.md's reqy prose is stale"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 51f86304-44ce-4ef1-9acf-fe500af86b9e
---

`reqy(w).do()` / `reqy().roai()` / `moai` / `reqcon` / `handler_of_last_resort` are **deleted**. CLAUDE.md and several specs still describe them — treat that prose as stale.

The live req API is C-native on any host C (`src/lib/data/Stuff.svelte.ts:574-652`):
- `host.oai({req:'name', maz, eternal?, permanent?}, sc?)` — sync find-or-create-or-mutate a `%req` child.
- `host.doai(c, sc)?.(req => {…})` — oai + one-shot `do_fn` setter (null once wired).
- `await host.do()` — maz-priority pump over the host's `!finished && !ok` reqs.
- `host.finish(child)`, `host.all_finished()`.

Handler resolution: `{req:'p2pman'}` → `H.req_p2pman`; worker `w:Peeroleum` → `H.Peeroleum(A,w)` (`Housing.svelte.ts:1090-1100`). do_fn signature is `(req) => {}`; derive host via `req.c.up`.

`eternal` = never finished, self-settles via `req.sc.ok=1` each tick (convention, not an engine flag). `permanent` IS an engine flag (`Stuff.svelte.ts:595`) — un-finishes a drifted stage. Waiting today = `H.i_req_ttlilt(req, secs, {waiting})` (`Hovercraft.svelte:180`); the spec's `%req:waiting`/`%exports`/`%aim`-hoisting/`waits_savepoint` are **aspirational, not in the engine**. See [[peeroleum-bootstrap]].

The reqy()→C-native migration is **DONE** (engine deleted; the Hovercraft tail landed). One legacy holdout remains **by design**: an older `requesty_serial(w,t)` queue (its own `requesty_$t` mainkey, NOT `%req`) still serves `Pirating`/`Pirate`/`Agency` — left as-is per the user's call (don't touch Pirat*). Don't mistake it for the live req engine; new code must contain no `requesty_serial`. Canonical handover stays `spec/Hovercraft.design.md`.
