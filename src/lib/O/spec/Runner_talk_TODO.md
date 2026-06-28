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
| handler + ops | `src/lib/O/LiesFunk.svelte:607` `Lies_runner_ask_recv` | ops: `ping`/`run`/`state`/`steps`/`snap`/`diff` + `snaps` (1a, atomic multi-read)/`retain` (1b1, sets `keep_snaps`)/`trace` (1d, `Run_trace`) + (new) `rungos` (list held runs) and an optional `uid` on every read op (1b-hold, serve a held run's pins); `run` now returns the new `uid`; replies `{control:'runner_ack',corr,…}` via the `Lies_ghost_compile_ack` ws idiom |
| run-hold (uid) | `src/lib/O/LiesFunk.svelte` `Lies_runner_begin`/`Lies_runner_verdict` + `Lies_rungo_record`/`Lies_rungo_steps` | each `Storyrun:<ident>` carries a `uid`; at verdict the produced steps are PINNED into `sr.c.pins` (**off-snap** Record keyed by step n: `{n,ok,caveat,dige,got_snap,exp_snap,trace}` — string *refs*, not copies). Bounded history (last 3 finished) + `w.c.active_rungo`. The runner "hangs in there" — a held run stays queryable by `@uid` after `This` churns |
| live-This nav | `src/lib/O/LiesFunk.svelte` `Lies_runner_this()` | `H:Story → A:Story → w:Story → c.This` (same nav `Cred_run_outcome` uses); `Lies_rungo_steps` reads here when no `uid` is asked |
| one-shot CLI | `scripts/runner_ask.mjs` | `ping/run <Book> [--watch]/state/steps/snap <n>/rungos [@uid]` |
| readline explorer | `scripts/story_repl.mjs` | persistent socket; `+ diff <n>` (vs expected) `+ diff <n> prev|<m>` (temporal, step→step) `+ rungos`/`@uid` (target a held run; bare `@` = last run) `+ books`/`book` |
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
  `retain on`, and the per-step `trace`). **1c — DONE 2026-06-27** (exp over the wire via `w:Story.c.exp_snaps`,
   the in-memory check-mode preload — see §1c; was deferred as byte-equivalent on shared disk, now cuts the
    CLI loose from the fixture and makes `@uid` diffs self-contained). **1e (ACCEPT) + 1f — remain.**

**Update (2026-06-27): the post-run HALF of 1b landed — the uid run-hold (§1b.hold below).** 1b was two
 problems wearing one coat: *(during a run)* don't trim a middle step → `retain` (1b1, done); *(after a run)*
  don't lose the run when the next one churns `This` → the **uid-pin hold**. A run now mints `Storyrun,uid:`
   and PINS its produced steps off-snap (`sr.c.pins`), so you `run X` → get a uid → keep pulling `diff/snap/
    trace @uid` long after, even past another run. **Type-clean; :9091 uid round-trip owed.** Still open from
     1b: **(b2) breakpoint** — pause *at* step n mid-drive (the live-pause half, a `req:Step` build, §15).

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

### 1b.hold — the uid run-hold (DONE 2026-06-27, the human's design)  *(the "after the run" half)*
- **what** — a run "hangs in there" as a **uid-addressable** record you keep talking to. `run X` returns a
   short `uid`; `rungos` lists held runs; any read op (`snap`/`snaps`/`diff`/`trace`/`steps`) takes an
    optional `uid` → served from that run's frozen pins instead of the live `This`. CLI: append `@<uid>`
     (bare `@` = the last run) to any read; `rungos`/`rg` to list.
- **why** — the live runner churns: the next run's `resetStory` overwrites `This`, and the 5-step trim drops
   middle steps. `retain` (1b1) only protects the *current* run *during* it; once you kick another Book the
    old one is gone. The hold makes a past run **deterministically inspectable** — kick run B, still diff run A.
- **where + shape** — `Lies_runner_begin` mints `Storyrun:<ident>,uid:` (uid = 8-hex of `crypto.randomUUID`),
   sets `w.c.active_rungo`, keeps a **bounded history (last 3 finished)**, drops stale never-finished records.
    `Lies_runner_verdict` PINS the produced steps into **`sr.c.pins`** — a plain Record keyed by step n
     (`{n,ok,caveat,dige,got_snap,exp_snap,trace}`), **on `.c` so it is OFF-SNAP** (never encoded, no snap
      bloat; same family as `w.c.exp_snaps`). Two readers: `Lies_rungo_record(w, uid?)` (uid prefix-matched →
       that held run; else active/latest) and `Lies_rungo_steps(w, ask)` (pins when `ask.uid`, else live This).
- **the shape, precisely (don't grep for child particles)** — conceptually `Storyrun(uid)/Step:n → {got, exp?}`,
   but it is a **`.c` Record, NOT snapped `Step:` child particles**. Off-snap by construction; a pin holds the
    *reference* to the (immutable) snap string, not a copy — pinning just extends the string's lifetime past the
     `This` churn. `exp_snap` is now filled from `Step.sc.exp_snap` (UI lazy load) ?? `w:Story.c.exp_snaps[n]`
      (the check-mode preload — see §1c), so a check-mode run's pins carry expected for self-contained `@uid`
       diffs over the wire; the CLI falls back to the disk fixture only when exp is null (non-check / no fixture).
- **memory** — bounded: ≤ 3 runs, each holding the steps that survived the trim (or **all** steps under
   `retain on`). Refs-not-copies + off-snap ⇒ low MBs on the *browser runner*, nothing on the CLI. Freed by
    FIFO eviction (`w.drop(oldest)` on the 4th run's begin → GC) or tab reload — **NOT** on CLI exit (the hold
     is decoupled from the readline lifecycle on purpose). `KEEP` is a one-line constant; set 1 for strict
      one-at-a-time. Open knob: a `forget <uid>`/`forget all` op for explicit release (not built).

### 1c. Diff over the socket — expected travels on the wire  *(Tier 1)* — DONE 2026-06-27
- **what** — `op:'diff'` returns the **expected** snap too, not just `got` + a maybe-loaded `exp_snap`.
- **why** — `got_snap` was fully over the socket but the *expected* rode the shared-disk fixture
   (`wormhole/Story/<Book>/<NNN>.snap`), because the runner only held `exp_snap` once the UI diff panel
    lazily loaded it. That only works on a shared `/app`; a real remote CLI has no disk to read.
- **what landed (NOT the original plan)** — the planned "drive `fetch_snap` and await" doesn't fit a
   request/reply handler: `fetch_snap → read_snap` is a **multi-round reactive Wormhole pump**
    (`Story.svelte:1470`; `i_elvis_req` returns *pending* across beliefs rounds), not an awaitable call.
     Instead the source is **`w:Story.c.exp_snaps`** — the check-mode preload (`Story.svelte:1451`) that reads
      EVERY step's expected into memory ONCE at run start (timing-safe; respects "never load a snap mid-run on
       a runner", [[entropy-samples-fuzzok]]). Every Book with fixtures runs check-mode (`run.sc.mode =
        step_count>0 ? 'check'`, L1404), so it's already populated.
- **where** — `Lies_rungo_steps` (live path) + `Lies_runner_verdict` (pin path) fold
   `Step.sc.exp_snap ?? w:Story.c.exp_snaps[n]` as the exp; the `diff` branch ships it. Pinned at verdict
    because the next run's toc-load wipes `exp_snaps` (L1409) — so a held `@uid` diff keeps its expected.
- **caveat** — cuts the **CLI** loose from disk; the **runner** still read the fixture off its own disk (at
   preload). A truly diskless *runner* needs exp seeded into the `become_book` payload — a further step. CLI
    still falls back to the disk fixture only when exp is null (a non-check run / no fixture for that step).

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
3. **1c diff over the socket** — DONE; expected on the wire via `w:Story.c.exp_snaps`; CLI no longer needs the fixture.
4. **1d trace/stack** — turn NOT-OK into *why*.
5. **1e ACCEPT (signed)** — close the loop; the one write op, gated by cluster Idento.
6. **1f handler re-registration** — fold in alongside any of the above (it touches the same file).
7. *(later)* **1b2 breakpoint** — the fuller §16.1 pause-as-soon-as-wobble, once the drive is `req:Step` (§15).

All of 1a–1f are **`.svelte` eatfunc + the two `scripts/` files** — no `.g`/`.go`, so they HMR into a live
 runner (except a *new* handler, which is 1f's point). Verify each with `story_repl` against a `?B=` tab.

### Dev workflow (how to iterate on this interface)
1. **Edit** the `.svelte` eatfunc (`LiesFunk`/`LiesLies`) or the `scripts/*.mjs` → it HMRs straight into a
    live `?B=` runner. A new **op** on an existing handler hot-swaps; a brand-new **handler** needs 1f /
     a tab reload (see §1f).
2. **If you touched a `.g`** — e.g. the transport in `Ghost/N/Peeroleum.g` (route/carrier) or
    `Tribunal.g` — **ghost-compile it FIRST**: `npm run ghost-compile -- Ghost/N/Peeroleum.g` (needs an
     editor open on `:9091`). Disk `.g` edits are inert until compiled; the runner only re-acquires gen on a
      fresh boot. The run-hold above is pure `.svelte`/`.mjs`, so it needed **no** ghost-compile — but the
       moment a change reaches the wire format (a new frame type, not just a `runner_ask` op), it's `.g` and
        the rule applies. (Memory: `[[ghost-compile-after-g-round]]`, `[[g-over-scattered-ts]]`.)
3. **Verify** headless with `node --check` (scripts) + `vite-node scripts/runner-ask-test.ts` (relay 6/6),
    then live with `story_repl` against the `?B=` tab. `npm run check` wants ≥ ~2.5G free (raise the
     `claude` compose service's `memory` if it OOM-kills at the 2G default).

---

## 3. Cross-refs
- `Cluster_design.md §6` (acceptance = attention × crypto) + **§7** (the self-driving Tiers — the headless
   framing this live interface realises).
- `Story_next_level_spec.md §16/§16.1` (agent as test driver; pile breakpoint + diff channels), **§2** (true-
   text channels / `Snap:trace`), **§3.2** (surf one object through time — the temporal diff), **§8.1**
    (seeing what held a step), **§15** (drive as `req:Step` — what a real breakpoint needs).
- `Music_todo.md §6.2` (the music cluster's brief of the same interface).
- Memory: `[[creduler-runner-architecture]]`, `[[headless-creduler-runner]]`, `[[story-cli-runner-boot]]`.
