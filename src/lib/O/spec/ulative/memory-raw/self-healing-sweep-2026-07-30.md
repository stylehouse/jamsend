---
name: self-healing-sweep-2026-07-30
description: overnight self-healing survey (12 ranked findings) + 6 landed fixes — req-machine fault isolation, Radio_pump/IDB/Peeroleum/Ra_mag_warm — 6 findings still open
metadata: 
  node_type: memory
  type: project
  originSessionId: 44a600bf-90a8-4f5a-a1f2-7e8fb2c1707a
---

The human, mid a big overnight Heist-reliability push: "everything needs scampering around looking for
ways it can be more self-healing." A background research agent swept the whole app (read-only, no edits)
and returned 12 ranked findings (likelihood × severity). Six were landed same night; six remain open.

**Landed (all compiled + bundle-verified):**
1. **Core req-machine fault isolation** — `Stuff.svelte.ts` `_req_do_one`: `await handler(req)` had no
   try/catch, so one throwing do_fn propagated out of `do()`'s for-loop and stopped every SIBLING req at
   that level, AND any outer multi-host loop calling `.do()` (confirmed live in two places: Housing's
   `reqdo_sweep` over every Agency→world, and LiesFunk's Waftica Funkcion pump). Now caught, logged loudly
   (console.error + `Story_error`), req stays `!finished` so the NEXT `do()` pass naturally retries it — no
   cooldown/skip logic added on purpose, that's a bigger change to the single most central path in the
   system and wasn't made without review. **The highest-value fix of the six** — most other findings traced
   back to "no per-req isolation" as their root shape.
2. `Ghost/M/Radio.g` `Radio_pump` had zero try/catch across its whole body (disk reads, `AudioDecoder`
   feed/open — throws on malformed packets, decoder state). Renamed the body to `Radio_pump_tick`, made
   `Radio_pump` a thin try/catch wrapper that reschedules via `Radio_pump_soon` on catch instead of letting
   "the radio that never stops" silently stop forever.
3. `src/lib/data/IDB.svelte.ts` `openDatabase`'s `onblocked` handler did `throw` inside an IDB event
   callback — does NOT reject the enclosing Promise (resolve/reject just never called), so `getDB()` hung
   forever and `dbConnections`'s cache meant EVERY future caller for that db:version hung too. Now
   `reject(new Error(...))`; also cleared the cache entry on both `onerror`/`onblocked` so a later `getDB()`
   gets a fresh attempt instead of replaying a stuck promise.
4. `Ghost/N/Peeroleum.g`'s retx/liveness/cull sweep (`Peeroleum_retx_sweep`/`_liveness_sweep`/`_runstepped`)
   was NEVER armed for the live Swarm p2p channel. Root cause traced past the survey's own guess:
   `Peeroleum_arm_whittle`'s rearm chain rides `Runstepped` (`Hovercraft.svelte`), which only drains when
   `Story._resolve_runstepped()` fires — i.e. only after a STORY SNAP COMMITS. A live Sounditron resident
   boots through its initial steps once and then runs forever on detached loops (trickle/beat/pump) with no
   further stepping, so that chain, even if armed, would never actually drain live. Fix: don't call
   `Peeroleum_arm_whittle` at all for the live channel — call the three sweep functions DIRECTLY off
   `Sounditron_trickle_look`'s existing ~5s wall-clock cadence (same tick as `Swarm_pulse_all`). Verified
   safe: every frame in the hot heist data path (`repli_want`/`repli_lines`/`repli_page`/`ive_got`/`pulse`)
   is EPHEMERAL (never touches this outbox) — only handshake-class frames (`pier_accept`/`reinvite_seal`/
   `suggest`) are reliable, so this can't interfere with active transfer, it only makes a lost handshake
   frame retry instead of stalling forever.
5. `Housing.svelte.ts` `_deliver_targeted` caught a targeted elvisto handler throw with only
   `console.warn` — never wired to `Story_error` (its sibling failure path 3 lines above it in `i_elvisto`
   WAS wired the same night, for the begun-wedge hunt). One-line fix: add the `Story_error?.(...)` call.
6. `Ghost/M/Ra.g` `Ra_mag_warm` gated its whole warm-start want-loop behind a ONE-SHOT `mag.c.warmed` flag
   (fires once ever, no re-ask) plus a permanent `ra_wanted[key]` boolean with no timer — the exact bug
   class `Ra_pull_beat` already proved a fix for (`ra_want_ts`, 4s re-ask). A single dropped want-reply
   meant `mag.sc.warm` never armed, permanently. Restructured: gate on `!mag.sc.warm` (not a one-shot flag)
   and reuse the proven `ra_want_ts` timestamp re-ask, so it keeps trying (throttled 4s) until it actually
   goes warm. Confirmed `mag.c.warmed` had no other readers before removing it.

**Landed, second pass:**
7. `LiesStore.svelte`/`LiesCortex.svelte`: a failed disk write on `req_Store` Phase 1 only
   `console.error`'d — the Cortex handoff (stamping `write_finished` on the waiting `req:Codebit`) lived
   entirely in the success branch, so an error left `req:Codebit` parked forever (`req_Codebit` just
   `return`s every tick with no ttlilt), spinner never clearing — contradicted CLAUDE.md's own stated
   contract ("errors thread back through Codebit%of_dock"). Fixed: the error branch now ALSO hands off
   (`codebit.sc.write_error` + `write_finished`); `req_Codebit` checks `write_error` first and, if set,
   settles `Lies_compile_settled` with the error (skips the Pantheate import — never import a file that
   wasn't actually written) instead of hanging; `Lang_drain_compile_settles` (`LangCompiling.svelte`)
   carries the `error` field onto `req:compiled_is_settled` so a reader can show it instead of inferring a
   silent stall. Three files, all bundle-verified.

**Open (found, not yet fixed — ranked by the survey, highest first, roughly by remaining severity):**
- Cytui wave-render pipeline (`process_queue`/`apply`, ~4841-4872) has no try/catch; any face-mount
  exception sticks `anim_busy=true` forever, and `diag_check` can't see it (blind to its own failure mode).
  Cytui is display-side (human's zone per [[vyto-refactor-avoid-display]]) — flag, don't just fix.
- `Story.svelte` `snap_step_after_wave`/`story_snap`/`snap_H` has no local try/catch — a throw (e.g. any
  `.sc.X = false` snapped anywhere in the Run tree, per [[story-step-false-flags-encode]]) wedges the whole
  run `driving` forever with no watchdog.
- `LiesRun.svelte` `req_BlatDo` latches `req_sent` once with no re-arm if its elvis target resolves to
  nothing (a `resetStory`/`become_book` mid-flight race) — permanent Rundown/BlatDo zombie.
- FSA writable-stream leak: a non-`NotFound` write error (quota/permission) never aborts the writer, and
  `_is_stale` only recognizes `NotFoundError` — poisons all future writes to that exact file
  (`NoModificationAllowedError`) until a full reload. `Directory.svelte.ts`/`Housing.svelte.ts` bin_write path.
- `Vytui.svelte`'s per-world render-state Maps (8 of them) are never pruned when `Ghost/V/Vytonation.g`
  drops a prior `A:Vyto`/`w:Vyto` — leaks one entry per Book run on a persistent shared runner tab (the
  normal verification workflow all session). Display-side, flag don't fix.

Full ranked write-up with file:line + failure-scenario for all 12 lives in the subagent's own report text
(not persisted to a file — if this matters later, re-run the same sweep prompt: general-purpose agent, told
to survey Peeroleum/Lies*/Story/Housing/Cytui/Vyto/p2p for silent failures + stuck states + missing retries,
excluding whatever's already fixed by then). [[fight-back-on-core-changes]] governed how carefully #1 was
approached (pure containment, no behavioral/gating change) given it's the most central function in the app.
