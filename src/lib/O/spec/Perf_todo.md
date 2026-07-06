# Perf_todo.md — why Lies|Lang shakeout is sluggish, and where to cut

The "shakeout" is the settle from an edit (or any event) until the C tree, the
 compile, the run and the UI all quiesce. It *can be* sluggish — sometimes snappy,
  sometimes it drags — and the variance is itself a clue. This doc is the causal
   map (with file:line) and the ranked levers. Distilled from a five-probe sweep of
    the think loop, the req sweep, the Lies Store/Cortex/Run pipeline, the Lang
     compile/reindex path, and the reactivity+snap layer. Corroborated by the app's
      own notes: `spec/Editron.md` §"THE LATENCY SWAMP" and `spec/Everything_todo.md`.

Paths below are `.svelte`/`.svelte.ts` as they resolve on disk.

## The shape of it: a slow serial spine, taxed per-pass

Sluggishness isn't one bug. It's a slow serial settling spine with several
 O(N)-per-pass taxes stacked on it, plus a ttlilt/trickle mismatch that delivers
  progress in coarse quanta. Six layers, worst-multiplier first.

### 1. The spine — a 50 ms serial gate × many one-pass-later hops

Everything settles by draining ONE queue (`H.todo`) with a fixed **50 ms gate
 between items** (`ANSWER_CALLS_TICK_MS`, `Housing.svelte.ts:15`). The loop is a
  `$effect` on `todo_version` (`Housing.svelte.ts:418`). **Every `i_elvisto`
   cross-ghost call is inherently one pass later** (`Housing.svelte.ts:566`) — the
    target only runs on a later drain. A typical edit→compile→run threads **~12-13
     elvisto hops** (~8 compile + ~4-5 run, plus a cross-machine channel RTT for the
      rungo). A logically-instant chain pays `N × 50 ms`. The spec's own words:
       "a known-causal chain pays N × 50ms of pure latency floor"
        (`Everything_todo.md:66`). ≈ 0.6-1 s of pure pass-threading before any O(N).

### 2. The amplifier — ttlilt can't re-fire, so progress is quantised

This is what makes it *"can be"* sluggish. A **ttlilt only holds the snap open; it
 does NOT re-fire think** (`Hovercraft.svelte:372`), and `feebly_ponder` is
  Runtime-gated (`Housing.svelte.ts:704`). So every waiting req carries its own
   ungated **150 ms `think` trickle** to make progress — `req:compile`
    (`Lang.svelte:1140`), `req:rungo` (`LiesLies.svelte:814`), `creduler_trickle`
     (`LiesLies.svelte:745`), `sweep_trickle` (`LiesFunk.svelte:1566`). When a
      settle-think is *caught* by an event wake it's snappy; when *missed*, progress
       advances only every 150 ms; and if even the trickle is absent it falls to the
        **3 s heartbeat** (`Housing.svelte.ts:427`) — "seconds dead per Book"
         (`LiesFunk.svelte:1562`). The trickles self-diagnose as "🔥 burning CPU on
          stuck pending" (`Lang.svelte:1139`): a stuck req both slows AND heats.

### 3. The per-pass tax — four unconditional near-full tree walks every beat

Each `beliefs()` pass does O(N)-over-particles work with **no change/dige gate**
 (`Housing.svelte.ts:913`):
- `organise()` — full C-tree walk, every pass.
- **`assert_req_legs()` — a DEBUG assertion doing a SECOND full-tree walk + per-w
   recurse EVERY beat, and it's ON** (`V.req_legs = 1`, `Housing.svelte.ts:13`;
    body `:1353`). Its comment admits "the count oscillates 0↔N every beat." Pure
     diagnostic churn on the hot path — the standout "shouldn't be on" finding.
      **(RESOLVED — assertion dropped, `V.req_legs` parked at 0; see lever #1.)**
- `attend()` — nested, **O(A × N)** (`Housing.svelte.ts:1017`, inner forward `:1038`).
- `reqdo_sweep` + every-w handler dispatch + `self_timekeeping` per A/w.

Because settling takes MANY passes, this per-pass O(N) multiplies by the pass count.

### 4. The settling shape — one maz level per pass, eternal re-arm

`do()` descends **one maz level per pass** when a req bows out on a ttlilt
 (`Stuff.svelte.ts:631`), and eternal reqs re-arm `sc.ok` every tick so they
  **re-run their full handler every pass** (`Stuff.svelte.ts:623`; `Lies.svelte:1146`,
   `LiesStore.svelte:530`, `LiesCortex.svelte:234`). The Lies stack is deep — Store
    `maz:7` → Cortex `maz:5` → Codebit `maz:2` → Rundown `maz:1` — so it needs several
     passes just to walk down, each spaced by the gate/trickle/heartbeat. **No
      max-pass cap** exists; quiescence is decided externally by Story `poll_step`.

### 5. The reactive fan-out — every tick re-renders the panels

`H.ave` is **emptied, rebuilt, and bumped every think tick**
 (`Housing.svelte.ts:1480`); every `H.ave.ob()` consumer re-runs on that bump —
  Liesui alone fires **five O(N) queries per tick** (`Liesui.svelte:71-76`), plus
   Storui/Langui/Cytui. `story_analysis` forces an extra `ave.bump_version()`
    (`Story.svelte:639`). Subscriptions are **container-granular** (`void C.version;
     C.o()`): the recursive `waftitem` re-derives every ancestor's child list on any
      descendant bump (`ui/Waft.svelte`). One edit fans out O(subtree). No
       field-level subscription exists.

### 6. Redundant Lang recompute — cache keys that always miss

Per-compile (gated behind the debounce, not per-tick, but O(points)):
- **Graft point re-anchoring's cache key embeds `dock.version:job.version`**
   (`LangGraft.svelte:263`), both of which bump on *every* recompile — so the cache
    **always misses** and the full **O(points × (defs+regions))** resolve reruns
     (`LangGraft.svelte:412`). Tell: `Lang_Map_report` right beside it is correctly
      content-digest-gated (`Lang.svelte:706`). **← being fixed now (see §status).**
- `Lang_build_mapules` ungated (`LiesHold.svelte:442`) though `Lang_Map_report` next
   to it is digested.
- `%Map` emptied+rebuilt wholesale each compile, no region diffing (`lang/compile.ts`).
- `Lies_resolve_wants` runs its reduce+relabel **every heartbeat** even at cap-12
   (`Lies.svelte:961`; the cap tamed the unbounded O(N), the per-tick run remains).

### Not the machinery — the intentional typing debounce

The biggest wall-clock number in interactive use is the deliberate **6 s
 "quiet typing" timer** before compile even starts (`Lang.svelte:449`,
  `delay_ms = machine ? 30 : 6_000`) + a 400 ms text-push debounce
   (`Langui.svelte:259`; the "80ms throttle" comment at `Lang.svelte:406` is stale).
    Separable from shakeout; machine/test mode drops it to 30 ms.

## Ranked levers (cheapest ratio first)

1. **Turn off `V.req_legs` in production** (`Housing.svelte.ts:13`) — deletes an
    entire O(N) tree-walk-per-beat for zero functional change. Biggest ratio.
    **(§status: DONE — `V.req_legs = 0` and `assert_req_legs()` dropped outright; the
    leg-laying hooks stay gated + inert for the parked walk-carrier migration. :9091-unverified.)**
2. **Content-digest graft's cache key** like its neighbor `Lang_Map_report` — kills
    an O(points×regions) rerun on every same-structure recompile. **(§status: done, unverified.)**
3. **Trickle → single-wake** (already specced at `Editron.md:307`): replace the
    150 ms busy-polls with one paced safety fire once ttlilt expiry can re-pump. The **req-side twin** — have
     an inner `req**`'s `finish()` re-pump `do()` on the ancestor chain (poll→event, killing the per-level
      150 ms of §4's descent) — is developed as `Story_future_directions.md` §3 Technique B, with the snap
       tension it must respect.
4. ~~**dige-gate `organise`/`attend`** so an unchanged tree isn't fully re-walked.~~ **ABANDONED —
    tried on branch `perf/organise-gate`, discarded 2026-07-06.  Zero upside ceiling by construction:
     the idle census shows **~0 think beats** (organise() barely runs at rest), and during active
      settling every beat makes progress so a version-watermark always moves — the gate can NEVER fire
       when it would help.  The only beats it fires are ttlilt-spins, where skipping organise() strips
        the freshly-rebuilt `Se.c.T` that `attend`/`snap_H`/`reqdo` all read that same beat → stall.
         organise() is not a pure function of walked-node versions; it has load-bearing side effects.
          See the Status log for the full autopsy + the measurement-methodology findings it surfaced.**
5. Longer game: collapse the 12-13-hop chain — the `N × 50 ms` floor caps everything. **Examined in
    `Story_future_directions.md` §3** (time-sliced greedy drain + observation-driven targeted collapse; the
     deepest lever — it attacks the 50 ms × N *and* the per-pass O(N) × N together).
6. Digest-gate `Lang_build_mapules` the way `Lang_Map_report` is. **(§status: DONE —
    branch `perf/mapules-digest-gate`, verified live; see the Status log.)**

## Moved out: the observation track + the hop-chain collapse

Two forward-looking sections left this doc for **`Story_future_directions.md`** (2026-07-06) — they are
 build-ready design, not the causal map + concrete levers this doc keeps:
- **The high-frequency "snappings" + in-flight console** → `Story_future_directions.md` §2. (Its first
   piece, the `reactap` census, landed — see the Status log below.)
- **Lever #5's examination — collapsing the elvisto hop chain** → `Story_future_directions.md` §3
   (observe → reconstruct the slow chain → collapse; grounded in the `answer_calls` 50 ms throttle vs the
    UItime "one pass later" deferral).

## Status log

- **2026-07-06** — lever #4 (`organise`/`attend` dige-gate) **tried and ABANDONED** (branch
   `perf/organise-gate`, discarded — never merged).  The gate: watermark = positional serial of every
    walked node's `version` (read off the standing `Se.c.T.sc.N`, House's own version excluded because
     `reset_interval`'s `{mo:'main'}` replace churns it every tick; `n.c.walk_id` tags so a reminted ref
      can't alias a stale mark); skip `Se.process` when the mark is unchanged.  Type-clean, LakeTiles
       9/9 on the gated code.  **Why abandoned — the upside ceiling is zero by construction:** the idle
        reactap census shows **0 think beats / 5 s** (organise() barely runs at rest — the idle bumps are
         peer-channel `Lies_heard` + `reset_interval`, not think→beliefs→organise), so there is no idle
          walk to save; and during active settling *every* beat makes progress, so the version watermark
           moves every beat and the gate can never fire when it would help.  The only beats it DOES fire
            are ttlilt-spin beats — and there, skipping organise() removes the freshly-rebuilt `Se.c.T`
             that `attend`, Story's `snap_H`, and `reqdo_sweep` all consume that same beat → progress
              stalls until a trickle/heartbeat wake.  organise() is a *side-effecting* walk, not a pure
               function of walked-node versions.  Zero benefit + unproven safety = not worth shipping.
  - **The valuable yield was the measurement autopsy** (keep these for testing levers #3 / Technique A|B):
    1. **Cold-start ≈ 2.5×.** The FIRST run of a Book after an HMR reload (or idle gap) is ~2.5× slower
        than warm — Understandium at gate=0 measured **21 s → 8 s → 8 s** across three back-to-back runs.
         A sweep launched right after an edit runs its early Books cold.
    2. **Long-runner drift.** A live runner degrades over a 65-Book sweep, so a **fresh-runner baseline vs
        post-sweep-branch** wall-clock diff is confounded (the branch sweep's +122 s total was mostly this
         + cold-start, NOT the code — proven by re-running the "regressed" Books with the gate DISARMED and
          seeing the same slowness).
    3. **PeeringLive is FLAKY**, not a lever regression: red 3/4 at gate=0 (green 1/4) — a live-peering
        step-1 race (wake≠hold on the editor/channel state).  The baseline's single GREEN sample was luck.
         Treat it (and any live-peering Book) as flaky; gate on `ok` across ≥3 warm runs, never 1.
    4. **Testing protocol for the real-upside levers:** warm the runner first (discard run 1), interleave
        A/B on the SAME warm runner with n≥3 per arm, and never compare a fresh sweep against a degraded
         one.  A full 65-Book fresh-vs-branch diff is a coarse *correctness* net (verdict flips), NOT a
          perf instrument.
  - Corollary: lever #6's committed perf number ("census ~3.3k→~2.5k bumps") is **correctness-solid but
     perf-soft** under these same confounds; its LakeFlush content-gated greens are the real gate.
- **2026-07-06** — §6 `Lang_build_mapules` content gate (lever #6, branch
   `perf/mapules-digest-gate`): two-tier like LangGraft's — digest of every Map entry
    (kind|key|depth|line|class|span|region_path) PLUS the dock text (body spans/line
     geometry consume it — Map_dige alone is too weak here, Mapulen carry absolute
      offsets), hashed once per recompile (cached on dock.c against job.version), O(1)
       every other wake; same digest → the standing Mapulen survive, no empty+rebuild+
        dock-bump.  Verified LIVE on the :9091 runner: LakeTiles 6/6 green, LakeLango
         green; census mid-run dropped ~3.3k→~2.5k bumps/think (coarse — window-phase
          sensitive).  NOTE: LakeWaftMap is RED at step 1 (error:null, fixture shape)
           on THIS BRANCH **AND on unmodified main** — pre-existing, not this lever;
            needs its own chase.
- **2026-07-05** — reactap: the reactivity CENSUS landed (the observation track's first piece —
   the socklog sibling for the tree).  `REACTAP` (Stuff.svelte.ts) taps ROOT-X bumps — the only
    serial a `void C.version` subscriber sees; disarmed cost is one property read per bump — and
     keeps ONE first-sighting stack per particle (who bumps it).  `Lies_reactap_recv` (LiesFunk)
      arms a bounded window and reports per-habitat (nearest Waft) totals + the top bumpers;
       `scripts/reactap.mjs` is the CLI, riding the runner_ask corr rails so the relay needed no
        change.  For §5: run it against the IDLE editor — a fat count over an idle window IS a
         re-render driver, named with its stack.
- **2026-07-02** — §6 graft cache key: replaced `dock.version:job.version` in
   `LangGraft.svelte`'s `graft_cache_key` with a content digest of the resolvable
    targets' consumed spans (name@line:from:to over defs+regions), hashed only once
     per recompile (cached against `job.version`) so the steady every-wake pass stays
      O(1). Mirrors `Lang_Map_report`'s `Map_dige` gate. Type-clean; **:9091-unverified**
       (Lang graft = bookmark anchoring, browser-verify owed).
