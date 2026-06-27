# Runner-talk TODO — the remote-runner Story talk-to interface

One place for the improvements to the **live-browser-runner talk-to interface** (the `runner_ask` RPC +
 `story_repl`), so the agent can *drive → examine → accept* a Story run in a real browser over the relay —
  real time, real audio, no human at `:9091`.

This is the **live realisation of `Cluster_design.md §7` "the self-driving Tiers"** (which were written for
 the *headless* CredRunner) and of `Story_next_level_spec.md §16` "the agent as test driver." Read those for
  the *why*; this is the concrete *what + where + how* for the live interface. Brief of record for the music
   cluster's slice of it: `Music_todo.md §6.2`.

---

## 0. What EXISTS now (built 2026-06-26 — do not rebuild)

A request/reply RPC to a runner already running in a browser (`?B=<Book>`), mirroring `ghost_compile`'s
 addr-less-CLI ↔ browser round-trip but pointed at the **runner**. Proven live (PortPlan green, AwFloat
  red-by-design, MusuLive/LeafFarm red, a real `self,round` drift localised by diff).

| Piece | Where | Note |
| --- | --- | --- |
| relay corr-routing | `src/lib/server/relay.ts` (`runner_ask`→runner, `runner_ack`→CLI by corr, ~L280/L391) | additive; mirrors `ghost_compile`/`gen_write` |
| handler registration | `src/lib/O/LiesLies.svelte:237` `on('runner_ask', …)` | on the runner role, inside `Lies_channel_up` |
| handler + ops | `src/lib/O/LiesFunk.svelte:607` `Lies_runner_ask_recv` | ops: `ping`/`run`/`state`/`steps`/`snap`/`diff` + (new) `snaps` (1a, atomic multi-read)/`retain` (1b1, sets `keep_snaps`)/`trace` (1d, `Run_trace`); replies `{control:'runner_ack',corr,…}` via the `Lies_ghost_compile_ack` ws idiom |
| live-This nav | `src/lib/O/LiesFunk.svelte` `Lies_runner_this()` | `H:Story → A:Story → w:Story → c.This` (same nav `Cred_run_outcome` uses) |
| one-shot CLI | `scripts/runner_ask.mjs` | `ping/run <Book> [--watch]/state/steps/snap <n>` |
| readline explorer | `scripts/story_repl.mjs` | persistent socket; `+ diff <n>` (vs expected) `+ diff <n> prev|<m>` (temporal, step→step) `+ books`/`book` |
| node proof | `scripts/runner-ask-test.ts` | relay round-trip, 6/6 |

**Delivery path is sound and needs no `.g`/`.go`:** the runner's `w:Lies` is single-identity, so
 `Peeroleum_route`'s "ONE Peering / ONE Pier ⇒ use it" short-circuit (`Ghost/N/Peeroleum.g:258,262`) routes
  a CLI frame to the sole Ud-stamped Pier *regardless of `from`*; a reliable carrier books straight (no
   inseq, `Peeroleum.g:357`); the inbox gate checks only `%Ud`, never `from` (`Peeroleum.g:420`). Same path
    prod `become_book` rides. (`ghost_compile` settles on a dige-POLL, NOT this hop — don't cite it as proof.)

**Today the answer is essentially OK|NOT-OK + a snap.** The gaps below are what turn it into a real
 inspect-and-accept loop.

---

## 1. The improvements (the work)

Each: **what · why · where · how.** Ordered for "get them now" in §2.

**Status (2026-06-26):** **1a / 1b1 / 1d — DONE + verified live** against a `:9091` runner (all `.svelte`
 eatfunc + `story_repl`, HMR'd in, no `.g`/`.go`; proven with the LeafFarm step-9→10 temporal diff under
  `retain on`, and the per-step `trace`). **1c — DEFERRED:** on a shared `/app` the runner's `fetch_snap`
   reads the *same* disk fixture the CLI already falls back to, so it's byte-equivalent; value only for a
    no-shared-disk remote runner. **1e (ACCEPT) + 1f — remain.**

### 1a. Atomic multi-step snap  *(small, enabling)* — DONE
- **what** — `op:'snaps', ns:[…]` returns `{n: got_snap}` for several steps from ONE read of `This`.
- **why** — a temporal diff (`diff <n> prev`) currently does two separate `snap` round-trips; on a churning
   runner the two can land on different run instants. One read makes a pair (or window) coherent.
- **where** — `Lies_runner_ask_recv` (`LiesFunk.svelte`); `story_repl.mjs` `diff` uses it instead of two `snap`s.
- **how** — trivial: map over `Lies_runner_this().o({Step:1})` once. ~10 lines.

### 1b. Hold / retain — inspect a middle step before it's GC'd  *(the race we hit)*
- **what** — keep a step's `got_snap` alive for inspection. Two grades: **(b1) retain mode** — a `runner_ask`
   flag that suppresses the per-run 5-step `got_snap` trim so any step stays readable; **(b2) breakpoint** —
    `op:'hold', at:<n>` pauses the drive *at* step n (`Story_next_level §16.1` "pause-as-soon-as-wobble", with
     the §4.2 fuzz classifier as the optional condition), `op:'release'` resumes.
- **why** — the live runner is a **shared, churning resource**: the StoryTimes sweep + compiles overwrite
   `This` between commands (observed `running` flip to `Ghost/M/Radiola.g` mid-inspect), and Story trims
    middle steps' produced snaps (the 5-step trim, `Story.svelte` ~L663/676/723). So inspecting an arbitrary
     middle step (e.g. step 10 of 30) is a *race* — caught only by a tight single-session grab. A hold/retain
      makes it deterministic.
- **where** — the trim site in `Story.svelte`; the drive loop `story_drive` (`Story.svelte:~1692`); the
   StoryTimes sweep (`src/lib/O/Funk/StoryTimes.svelte`) — its re-run is what clobbers `This`, so a hold must
    also tell the sweep to leave the held run alone.
- **how** — retain (b1) is the cheap first cut: gate the trim on a `w.c.retain_snaps` flag the runner sets on
   a `runner_ask` op. Breakpoint (b2) is the fuller §16.1 build (a `req:Step`-level pause — see §15).

### 1c. Diff over the socket — expected travels on the wire  *(Tier 1)*
- **what** — `op:'diff'` returns the **expected** snap too, not just `got` + a maybe-loaded `exp_snap`.
- **why** — today `got_snap` is fully over the socket but the *expected* rides the shared-disk fixture
   (`wormhole/Story/<Book>/<NNN>.snap`), because the runner only holds `exp_snap` once the UI diff panel
    lazily loaded it (`Story.svelte:1459-1474`, `fetch_snap → read_snap → Step.sc.exp_snap`). That only works
     on a shared `/app`; a real remote runner has no disk for the CLI to read.
- **where** — `Lies_runner_ask_recv` `diff` branch; drive the same `fetch_snap` Wormhole `read_snap` the UI
   uses (set `run.sc.fetch_snap = n`, await the read, return `Step.sc.exp_snap`).
- **how** — async in the handler; or pre-warm exp for all steps after a run. Completes
   `Story_next_level §16.1` "diff channels in the pile" over the wire.

### 1d. Per-step stack / trace — the *why*, not just OK|NOT-OK  *(Tier 4)*
- **what** — `op:'trace', n:<n>` returns the step's trace channel: what held it (the **ttlilt** + its `req`/
   `of_w`), the quiescence label (causal vs `timeout`), the beliefs-cycle count, and any error/stack.
- **why** — a red step today is opaque ("NOT-OK"); the trace says *why* it failed and *what it was waiting on*.
   This is `Cluster_design §7` **Tier 4** ("observability I can grep") + `Story_next_level §2` true-text
    channels (`Snap:trace`) + §8.1 "seeing what held the step up."
- **where** — the trace substrate is `trace_enable`/`trace`/`trace_drain` (`Story_next_level §2.5`), the
   `Run_trace` beliefs-cycle counter, and the ttlilt records (`Hovercraft.svelte`, the `%ttlilt` with
    `until_ts`/`req`). Surface them off `Lies_runner_this()` / the run's `Snap:trace`.
- **how** — return the already-emitted trace text for the step; deeper, expose an **on-demand snap at any
   tick** (Tier 4's other half) so a wedge is readable mid-step, not only at boundaries.

### 1e. ACCEPT over the socket — close the loop  *(Tier 1, gated by §6)*
- **what** — `op:'accept', book:<Book>, step?:<n>` records the gate: the live analog of `CredRunner ACCEPT=1`
   / Resnapture, so the agent can re-bake a *forgivable* drift after reading the diff (e.g. MusuLive's
    `self,round` +6 stale bake, LeafFarm's age-mung) — without a human at `:9091`.
- **why** — drive → diff → **accept** is the whole point (Tier 1). Without it the agent can *see* a stale
   bake but not fix it; every rebake still needs the browser human.
- **where** — the accept/Resnapture path already exists per-test (`first_snap`/Resnapture, `Story.svelte`;
   the headless bake is `BOOK=… ACCEPT=1 … scripts/CredRunner.spec.ts`). Wrap it as a `runner_ask` op that
    runs the same record on the live runner.
- **how + SAFETY** — **sign the accept** under the cluster Idento (`src/lib/p2p/cluster_trust.ts`,
   `signHeader`), exactly as `gen_write` is gated, so the acceptance record carries **who/what/provenance**
    (`Cluster_design §6`: *acceptance = attention × crypto*). The relay routes it opaque; the runner verifies
     before recording. Accept is the one *write* op — it gets the tight gate, unlike the read ops.

### 1f. Re-register handlers outside the once-guard  *(robustness)*
- **what** — register `on('runner_ask', …)` (and siblings) where **HMR re-runs it**, not behind the
   once-guard.
- **why** — the registration sits in `Lies_channel_up`, guarded `if (w.c.channel_up) return` (`LiesLies.svelte`
   ~L195). HMR re-mixes the *method body* (so a new **op** on an existing handler hot-swaps — that's why the
    `diff` op went live without a reload) but NOT the one-time registration, so adding a brand-new **handler**
     needs a full page reload. Cost a confusing "ping timed out" until the tab was reloaded.
- **where** — `LiesLies.svelte` `Lies_channel_up`; move the `on(…)` block (or re-run it) on HMR.

---

## 2. Order to get them now

1. **1a atomic multi-snap** — tiny, makes the temporal diff coherent, unblocks 1b/1d windows.
2. **1b1 retain mode** — the cheap half of the hold; ends the middle-step race we hit.
3. **1c diff over the socket** — expected on the wire; the interface stops depending on shared disk.
4. **1d trace/stack** — turn NOT-OK into *why*.
5. **1e ACCEPT (signed)** — close the loop; the one write op, gated by cluster Idento.
6. **1f handler re-registration** — fold in alongside any of the above (it touches the same file).
7. *(later)* **1b2 breakpoint** — the fuller §16.1 pause-as-soon-as-wobble, once the drive is `req:Step` (§15).

All of 1a–1f are **`.svelte` eatfunc + the two `scripts/` files** — no `.g`/`.go`, so they HMR into a live
 runner (except a *new* handler, which is 1f's point). Verify each with `story_repl` against a `?B=` tab.

---

## 3. Cross-refs
- `Cluster_design.md §6` (acceptance = attention × crypto) + **§7** (the self-driving Tiers — the headless
   framing this live interface realises).
- `Story_next_level_spec.md §16/§16.1` (agent as test driver; pile breakpoint + diff channels), **§2** (true-
   text channels / `Snap:trace`), **§3.2** (surf one object through time — the temporal diff), **§8.1**
    (seeing what held a step), **§15** (drive as `req:Step` — what a real breakpoint needs).
- `Music_todo.md §6.2` (the music cluster's brief of the same interface).
- Memory: `[[creduler-runner-architecture]]`, `[[headless-creduler-runner]]`, `[[story-cli-runner-boot]]`.
