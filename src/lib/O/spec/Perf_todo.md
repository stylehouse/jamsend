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
    150 ms busy-polls with one paced safety fire once ttlilt expiry can re-pump.
4. **dige-gate `organise`/`attend`** so an unchanged tree isn't fully re-walked.
5. Longer game: collapse the 12-13-hop chain — the `N × 50 ms` floor caps everything.
6. Digest-gate `Lang_build_mapules` the way `Lang_Map_report` is.

## Proposed track: high-frequency "snappings" + an in-flight console

A second, opt-in cadence *beside* the Story-step snap: **super-intensely-often
 snappings** on any system we designate — e.g. taken **between event handlings**,
  armed **once some designated C\*\* exists** — that you can **remote into and
   look at + manipulate** the live editor via an **in-flight Story console**.

Why it belongs here: today the only structured snap of the C tree is the
 between-steps Story snap (`snap_H`/`story_snap`, `Story.svelte:1071`), which is a
  full-tree Travel+encode — too heavy and too coarse to fire between event handlers.
   The want is a *lighter, denser* observation track: a scoped snap (a subtree, not
    all of H) fired at a fine cadence on nominated systems, cheap enough to run
     between handlings without becoming a §3-style per-pass tax.

Design constraints it must respect (from the diagnosis above):
- **Scoped, not whole-tree.** Snap only the designated C\*\* subtree (Travel from a
   named root), never all of H — else it becomes another O(N)-per-beat tax.
- **Off the snap pump.** The observations are diagnostic; they ride `.c`/`H.ave`
   (like Cyto's `source_n`, like run pins), never `.sc` — no encode cost, no snap
    pollution.
- **Armed by presence, gated to designated systems.** "Once some C\*\* exists"
   = arm when a marker particle is present; "any system we designate" = an explicit
    opt-in flag per w/host, not global. Default off.
- **Between-handlings cadence, not per-tick.** Hook the observation to the
   event-handling boundary (the `answer_calls` drain edge), not the 3 s heartbeat —
    this is the "intensely often" the Story-step snap can't give.
- **Remote + manipulable.** The console rides the same `/relay` websocket the
   editor/runner already share (`runner_ask.mjs` is the request/reply precedent);
    it should both *read* the dense snap stream and *inject* mutations (an in-flight
     REPL against the live world), the interactive twin of `story_repl.mjs`.

Open questions:
- Cadence knob: per-handling vs. a fine timer (e.g. sub-heartbeat) vs. change-gated
   on the designated subtree's version.
- Retention: a ring buffer of the last N dense snaps (cf. the run-pin `KEEP` cap,
   `LiesFunk.svelte:1324`) so you can scrub, not just see now.
- Where the console mounts: a Lens/Brink face (the ambient dock layer) vs. a
   separate remote surface.
- Cost ceiling: a hard cap + a `log()` when it drops, so the observation track can
   never itself become the sluggishness it's meant to diagnose.

## Status log

- **2026-07-02** — §6 graft cache key: replaced `dock.version:job.version` in
   `LangGraft.svelte`'s `graft_cache_key` with a content digest of the resolvable
    targets' consumed spans (name@line:from:to over defs+regions), hashed only once
     per recompile (cached against `job.version`) so the steady every-wake pass stays
      O(1). Mirrors `Lang_Map_report`'s `Map_dige` gate. Type-clean; **:9091-unverified**
       (Lang graft = bookmark anchoring, browser-verify owed).
