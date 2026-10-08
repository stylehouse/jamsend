# Perf_todo.md — why Lies|Lang shakeout is sluggish, and where to cut

The "shakeout" is the settle from an edit (or any event) until the C tree, the
 compile, the run and the UI all quiesce. It *can be* sluggish — sometimes snappy,
  sometimes it drags — and the variance is itself a clue. This doc is the causal
   map (with file:line) and the ranked levers. Distilled from a five-probe sweep of
    the think loop, the req sweep, the Lies Store/Cortex/Run pipeline, the Lang
     compile/reindex path, and the reactivity+snap layer. Corroborated by the app's
      own notes: `spec/Editron.md` §"THE LATENCY SWAMP" and `spec/Everything_todo.md`.

Paths below are `.svelte`/`.svelte.ts` as they resolve on disk.

## 0. What to get on with next

- **§7 (2026-10-08) — the serving box.** The jamserve daemon was paying 60–80% of a core to sit idle. Four cuts took it to
   ~12% idle and 7–11% while serving one listener. §7 names the shared cause: **we re-derive state by re-running "the
    function" when we could ask whether anything changed.** It ranks what's left. Next rungs, safest first: **R1b** (the daemon's own think, only where something moved), **R4a** (stop
     acking untracked data frames, about half the inbound), **R6a** (index `o()`'s second key). R3 turned out NOT cheap; see §7.3.
- The older Lies/Lang shakeout map (§1–6 below) is the same disease seen from the editor. Its scorecard is still the reference.

## 7. The serving box — "throwing lots of extra goes at the function" (2026-10-08)

> 👤 **For people.** The owner, watching `top` on the box that serves music to friends: *"that's way too much cpu"*, then
> *"it seems a fundamental weakness of our programming — throwing lots of extra goes at 'the function' to refresh state that
> may not need it."* That's the right diagnosis. Our whole machine keeps itself correct by **re-running everything, often**,
> instead of **noticing what changed**. In a browser tab a person makes the changes and the re-running keeps up with them. On
> a server that never sleeps, the re-running IS the workload. It runs whether or not anything happened.

### 7.1 What we measured (daemon `/status` cpu + `/profile`, node process only)

`process.cpuUsage()` counts **only the node process**. ffmpeg runs as spawned children, so the encoding (probe, measure,
 opus encode) is **on top** of every number here.

| state | CPU (one core) | what the profiler said |
|---|---|---|
| before, idle 2.6 days | **60–80%** | heap 1.5 of 1.65 GB, GC thrash, ~6.7 belief passes/s with nothing queued, 1,160 encodes for no audience |
| + tour rests with no audience | 44% | still ~6.7 passes/s |
| + 400 ms idle floor (wake on queued work) | 20% | 78% idle; top real cost = stack capture per `replace()` (~8%) |
| + no stack capture on the daemon | **12%** idle | bursts are `readdir` (37% of one sample): every radiostock lookup re-listed the folder |
| serving ONE listener, steady | **7–11%** | 92% idle; 12,928 frame wakes + 4,918 bare `think` posts since boot |
| a listener connecting (catalog + first pulls) | 28–36% burst | inbound frames ~5/s, share beats, folder listings |

The four cuts, each the same disease in a different organ:
- **Rotation for nobody.** `Stoker_tour` re-dug and re-encoded every 90 s with no listener. Now it rests (`Stoker_has_audience`).
- **Passes for nothing.** The daemon loop thought every House about 7 times a second, queue empty. Now it naps a floor
   (`IDLE_MS`, `/tune`) and wakes within 20 ms when anything is queued. (`scripts/daemon/main.ts`)
- **A debug instrument on the hot path.** `replace()` built `new Error().stack` every call, "in case" two replaces nested
   (`OPTIMISE_FOR_DX`). On the daemon it's off.
- **Re-deriving a listing.** `Ra_stock_find` re-read and re-parsed the whole radiostock folder per lookup. The nav now caches
   each folder against its mtime (`list_dir`, `scripts/NodeWormholeNav.ts`), pending a restart.

### 7.2 The theory — why "the function" gets so many goes

The belief loop is **immediate-mode**. A pass re-reads the world and re-decides everything: `organise()` walks the C tree,
 `attend()` dispatches every world's handlers, `reqdo_sweep` runs every req level (§3 above has the file:lines). Correctness
  comes from **re-derivation**. Nothing has to remember what depended on what, because everything is recomputed. That's the
   bet's great strength: state is legible, any pass can be snapped, Books are deterministic.

The cost is **(size of the world) × (how often we pass)**, and **not (how much changed)**. Three things make the pass rate
 high and unrelated to change:
1. **Wakes are cheap and anonymous.** `i_elvisto(w,'think')`, `feebly_ponder()`, `bump_version()` all mean "run the loop
    again soon". Each caller wakes the WHOLE House for its own small reason. The daemon's `woke` tally: 4,918 bare
     `think` posts on top of 12,928 real frames.
2. **Every frame is a full pass.** One friend's pulse, one `ive_got`, one chunk ack, each `handle_inbound` drains as its own
    item and its belief pass walks ~9k particles. The cost is per frame × world size, never per frame × what the frame touched.
3. **Waiting is done by polling.** A req that waits on something asynchronous re-checks on a trickle (§2) instead of being
    resumed by the thing it waits for. A waiting req therefore costs a pass per trickle forever (the "🔥 burning CPU on stuck
     pending" warnings are this, self-diagnosed).

The same reflex shows up outside the loop: **re-derive from the source each time** instead of keeping an index and
 invalidating it on write. The radiostock listing per lookup, the stack per replace, the dig per 90 s are all this shape.

### 7.3 The remedies, ranked — rewritten from the four surveys (2026-10-08)

Four read-only surveys went over the machinery: the belief pass, the wake sources, the inbound-frame path, and re-derivation.
 Their findings, with file:line, are in §7.6. They re-ranked the list and **corrected R3**, so read §7.6 before building any rung.

**Daemon-only cuts. Books never see these, so they're the safest first.**
- **R1 ✅ Demand-driven ticks.** No tick without queued work or a due ttlilt, beyond a 1 s floor (`IDLE_MS`, `/tune`).
- **R1b The daemon's own think is the biggest anonymous wake.** `main.ts` posts `think` to EVERY House on every loop iteration,
   including iterations started by a share beat `fn` that changed nothing. Post it only to a House whose global bump counter
    moved, or that holds an unfinished req or due ttlilt. First tag the post (`see:'daemon_tick'`) so the `woke` tally can prove
     whose thinks they are.
- **R1c Adaptive share beat.** `Swarm_share_loop` ticks every 600 ms forever. Make it 600 ms while a pull, serve, keep or
   playback is live, otherwise 3–5 s.
- **R1d Strip dev probes from a server.** `Creduler_reswap` does a fetch or 35 HEADs every 2 s, but a daemon has no HMR. Remove
   the duplicate `Ra_pcm_sweep` (it runs on an interval AND per pump). Latch `Sounditron_trickle` so a pass can't re-era it.

**Wire cuts. Halve the frames.**
- **R4a Don't ack what nobody tracks.** `repli_lines`, `repli_page` and `ive_got` are sent fire-and-forget but booked and
   ACKED on receive (`Peeroleum.g` req_unemit). Every chunk served comes back as an ack that wakes a full tick. That's about half
    the inbound frames.
- **R4b One pass per burst.** Hold ~50–100 ms after the first inbound before draining, and drop `feebly_ponder`'s trailing
   200 ms think when a tick think is queued. Then N frames cost one pass, not N to 2N.
- **R4c Don't re-send the unchanged.** `ive_got` re-sends every 30 s, the whole catalog every 60 s, and pulses every ~5 s even
   after the era is confirmed. Stretch the floors once the peer confirms our era. Send the catalog as a diff.

**Machinery cuts. These help every tab, and need Book sweeps.**
- **R6a Index the second key.** `o()` only indexes the FIRST key, usually a mainkey wildcard (`{Record:1,id}`), so every lookup
   by id scans the bucket, while `i()` already builds per-key buckets nobody reads. Seed from the narrowest indexed key, falling
    back on coercion misses. ~15 lines in `Stuff.svelte.ts` `o_query`. It fixes chunk lookups per serve, Card lookups, awaitbuf
     lookups per page, and `{Record:1,id}` everywhere at once.
- **R6b Memoise `Ra_recs` per shelf** (id / re / artist+title maps, validated by summed serials). `Ra_rec_find` becomes O(1), and
   that removes record × record loops in Heist_keep_pull/step, Heist_beat, Heard_landed and Repli_merge.
- **R6c `rm()` → `drop()` on hot paths.** `rm()` is a `replace()`: it empties the container and re-adds every survivor
   (`Repli.g` parked-want serve, `Ra.g` transcode pump, `Heist_beat`).
- **R6d Cache per record what's re-walked per tick:** chunk presence (`Ra_chunk_have`, `Radio_map`), `Heard_set` (the union of every
   Mag key, rebuilt per pump tick), and the Heists Berth waft (re-read from disk on every 1.5 s persist).
- **R8 Bump only on real change.** `Repli_merge`, the `IveGot` fact, `Presence_take` and the sibling `heard` stamp all bump with
   identical values, and the sibling stamp writes wall clock into `sc`. Cheap, and **a prerequisite** for any skip-unchanged gate.
- **R2 Answer a bare think without a pass when nothing changed.** Global bump counter in `TheX.bump_version`. MEASURE FIRST: log
   how many bare thinks find it unmoved. Gate in `_really_answer_calls`, but never for a House with a ttlilt (they're only marked
    timed out during officing) or a needs-work req. *(Owner: "if we have no other %elvis between those mindless ones I guess
     that's what we change.")*
- **R3 Dirty-scoped passes. NOT cheap, corrected.** `version` is per particle and **nothing carries it upward**. Plain
   `sc.x =` and `.c` writes bump nothing. Every pass bumps every A itself (`self_timekeeping` round, `A.replace({w:1})` in
    officing), and eternal reqs look like work every pass. It needs an up-propagated dirty bit (REACTAP's per-host tap is the
     base), the pass's own bumps excluded, and a `wants_clock` opt-in for handlers that do time-based work without a change
      (Lies_heartbeat, rungo/compile timeouts, mirror nudge, round-driven worlds; list in §7.6). Do it after R8 and R2.
- **R5 Resume, don't poll.** Unchanged: a waiting req registers a resume instead of a trickle.
- **R7 Instruments off the server hot path.** `OPTIMISE_FOR_DX` landed. Also: the `◈ pull` console line per record per beat, and
   `Heist_keep_persist`'s JSON-stringify-to-compare.

### 7.4 The laws a remedy must keep

- **A skipped pass must be provably a no-op.** Books snap at quiescence (Coding_guide "Wake ≠ Hold"). R2/R3 may skip work,
   never a HOLD: an unfinished req or a live ttlilt always earns its world a pass.
- **Verify by re-running Books** (Coding_guide "verify a timing fix by re-running"), on the live runner, through a subagent,
   5×. A remedy that turns one fixture red has found a hidden dependency on an anonymous wake. Name it and give it a real
    wake; don't widen the gate.
- **Measure the same thing twice.** `/status` `cpu` is a 30 s window of the node process alone. Quote it with `ticks_per_s`
   and the `woke` tally, and say whether a listener was connected. `/profile?ms=` for where it goes, `/census` for memory.

### 7.5 Is 7–11% for one listener fair?

Not yet. One listener means ~5 frames/s and a 600 ms share beat. The 92%-idle profile spreads what's left thin, across
 `o_query`, Svelte `get` and walks. That's the signature of many passes over a big world, not of one hot function. The surveys
  say where the passes come from. Each frame wakes a tick, and the tick thinks every House (R1b, R4b). Half the frames are acks
   nobody needed (R4a). Inside each pass, id lookups scan buckets (R6a), and the shelf is re-collected per lookup (R6b). Do those
    four, then measure one listener again with the same three numbers (`cpu`, `ticks_per_s`, `woke`).

### 7.6 Survey evidence (2026-10-08, four read-only explorers)

**The pass** (Housing.svelte.ts):
- `organise()` (1329) walks H/A/w plus lematched subtrees, not the whole particle tree (`V.req_legs` is parked at 0).
- `attend()` (1388) is O(worlds + A×T): it re-scans the T list per A at 1416.
- Officing (Hovercraft 466–542) marks ttlilts and `A.replace({w:1})`es every A.
- `reqdo_sweep` clears every req's `%ok` (Stuff 770), so eternals re-run every pass.
- None of the four has a change gate.

**Version** (Stuff.svelte.ts):
- `serial_i` is per particle (256). `oai` and `maybe_mutate_sc` bump the found particle, not its parent.
- Nothing propagates upward. Plain `sc` and `.c` writes bump nothing.
- The only per-C "last seen" stores are `watched` (Housing 1785) and the Stuffing matrix (1961).

**Handlers that do clock work without a change** (would stop under R3 without `wants_clock`):
- Lies_heartbeat → keepalive / watch_sync / drain_rungo (Lies.svelte 879, LiesLies 893)
- req_rungo's 20 s timeout (LiesLies 1687)
- LiesStore's complaint timers (981)
- Lang compile-settle expiry (LangCompiling 330)
- storytimes fail (LiesFunk 4143)
- Clustation_mirror_nudge (Auto 647)
- `w_ambiently_sleeping` round throttle (Hovercraft 91)
- The Swarm/Radio/Heist/Pool throttles mostly ride their OWN timers (the share loop, Radio's pump), so they're not on this list.

**The frame path:**
- Tribunal `on_message` → `Lies_deliver_soon` batches onto `inbound_batch` (LiesLies 1592–1606) → `Lies_drain_inbound`
   (1617: express first, then repli_page slices of 24).
- Peeroleum deliver branches call `feebly_ponder`, which only works under Story's `c.runtime` (Housing 931).
- So on the daemon, passes come from the tick loop. Frames more than 20 ms apart wake separate ticks.

**Steady frame kinds:**
- pulse ~5 s (Sounditron 2268/2337)
- swarm_hi backstop 5→60 s (Swarm 4928)
- ive_got 5 s census, 30 s re-send (5042)
- offer on mark change or every 60 s (5855)
- repli_want re-ask 4 s (Pool 1687), parked reply 2 s (Repli 658)
- chunks + an ack each (Peeroleum 1184–1189)
- presence `who` on pulse_all (Swarm 4831)

**Bumps with no change:**
- Repli.g 433 (bumps even when every prop compare matched)
- Swarm.g 5086–5088 (IveGot)
- Swarm.g 1841–1843 (sibling `sc.heard` = wall clock + bump, every pulse)
- Presence.g 109

**Periodic drivers on the daemon:**
- daemon tick think (main.ts, every House, every iteration)
- share loop 600 ms (Swarm 5674)
- watch loop 2 s (5546)
- Supervisor_beat 2 s (Supervisor 138)
- Sounditron trickle 2.5 s (2222/2337), its dog 10 s
- Ra_pcm_sweep 5 s AND per pump (Ra 2576, 3285)
- Stuffing heartbeat 3 s (Housing 587)
- Census 5 s, signature-gated
- **Creduler_reswap 2 s fetch/HEADs, with no daemon gate**
- persist_account fingerprint every 20 s
- Clustation_mirror_account per Auto pass

**Re-derivation:**
- `o_kv` indexes only the first key (Stuff 196–221, 464–486). The rest is a linear filter (502); `i()` already builds every
   key's bucket (327–335).
- `Ra_recs`/`Ra_rec_find` copy every level per call (Ra 1152–1210), from Repli_merge per page, Heist_keep_pull/step per pick,
   Heist_beat per mirror record, Ra_mag_warm / Ra_restock_beat per friend, Radio_head_ahead per pump tick, Radio_lineup_fill
    every 3 s.
- `Heard_shelf_index` re-runs `Ra_recs` to check its own key (Heard 907).
- `rm()` = replace = empty + re-add (Stuff 1074–1085) at Repli 829, Ra 3343, Heist_beat.
- `Heist_body_at` scans `{Original:1,seq}` linearly, twice per serve (Heist 48, Repli 1148).
- The Heists Berth is re-read on every persist (Heist 3334, 4910). `Ra_card` unpacks a whole stock file for its header (Ra 2350).
- Per-tick rebuilds: `Ra_chunk_have` ×2 per pulled record (Ra 3512, 3681, 3878), `Radio_map` per pump tick (Radio 4473),
   `Heard_set` per pump tick (Heard 817).

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
- `Lang_build_mapules` ungated (`Lang.svelte:734`, moved from the deleted `LiesHold.svelte`) though
   `Lang_Map_report` next to it is digested. **(§status: DONE — see lever 6 below.)**
- `%Map` emptied+rebuilt wholesale each compile, no region diffing (`lang/compile.ts`).
- `Lies_resolve_wants` runs its reduce+relabel **every heartbeat** even at cap-12
   (`Lies.svelte:961`; the cap tamed the unbounded O(N), the per-tick run remains).

### Not the machinery — the intentional typing debounce

The biggest wall-clock number in interactive use is the deliberate **6 s
 "quiet typing" timer** before compile even starts (`Lang.svelte:449`,
  `delay_ms = machine ? 30 : 6_000`) + a 400 ms text-push debounce
   (`Langui.svelte:259`; the "80ms throttle" comment at `Lang.svelte:406` is stale).
    Separable from shakeout; machine/test mode drops it to 30 ms.

## RE-RANKED 2026-07-07 by the trace gap-analysis (measure, don't guess)

The old ranking below was written from the causal map (structure), not from measured wall-clock.
 The `runner_ask trace <n>` + `scripts/trace_gaps.mjs` breakdown of a real Lies+Lang settle (HohoFlush)
  moves the priorities — see the Status log for numbers.  **Per step, the wall-clock splits ≈: the 50 ms
   answer_calls DRAIN GATE ~49% · a fixed ~428 ms trailing QUIESCENCE guard ~22% · tight belief work
    ~18% · the 150 ms TRICKLE ~11%.**  So:
- **#A (was Technique A / old lever #5) is THE lever** — collapsing the 50 ms per-item drain gate attacks
   the biggest slice.  Promote it.  **(§status 2026-07-07 eve: BUILT, −13/−14% measured; two
    cadence-sensitive Books unresolved — see the log.)**
- **The ~428 ms/step quiescence guard is a NEW candidate** (old ranking missed it): a contiguous idle wait
   after `beliefs/done`, ~428 ms in *every* step (the design assumed ~75 ms).  Understand `poll_step`'s
    trailing timer / any ttlilt it waits out before building — could be ~2.5 s across a 7-step Book.
- **Technique B (old lever #3 req-side twin) is DEMOTED for a Story STEP** — the trickle is only ~11% of a
   step, and the maz descent is *already* mostly event-driven (`Hovercraft.svelte:281` `if (req.sc.finished)
    await host.do()`).  Small win there, highest risk.  **BUT the workload flips for EDITOR STARTUP** — see
     the scorecard: boot is trickle-bound, so Technique B may be THE lever there.

## Where we are — the scorecard (2026-07-08)

> ⚠ **Read the 2026-08-04 status entry before trusting this scorecard.**  Technique A is listed below as
>  shipped — the code merged, but a stray `V.gallop = 0` left it INERT until 2026-08-04.  It is armed now
>   (one axis, universal-on, `c.no_gallop` the opt-out) and a fleet re-verify is OWED.

**Done + shipped to main** (branch merged 2026-07-08): #1 `V.req_legs` off · #2 graft cache key ·
 #6 `Lang_build_mapules` gate · **#A / Technique A — the gallop** (`perf/gallop-tighten`, −13/−14% on a
  warm Lies+Lang step, the biggest measured slice; two cadence-sensitive Books opted out via
   `The/Opt/{no_gallop:1}`).  **Abandoned:** #4 organise/attend dige-gate (zero upside by construction).

**NOT done — the two that remain, both belief-loop-structural (not cheap levers):**
- **Technique B** (= old lever #3, "trickle → single-wake").  **What it is, in one line:** the deep Lies req
   stack (Store `maz:7` → Cortex → Codebit → Rundown) pays **~150 ms PER LEVEL** because a finished child is
    only noticed by the next 150 ms *trickle* poke — Technique B makes the child's `finish()` **re-pump
     `do()` on its parent immediately**, turning that poll into an event (dev in `Story_future_directions.md`
      §3).  Demoted for a tight Story step (~11 % there), but it is the **prime suspect for EDITOR STARTUP**:
       the ~400 ms gallop win off a ~12 s boot proved the drain gate is a thin slice of boot; the other
        ~11.6 s is trickle-paced maz descent + real async (compile/CodeMirror/reindex) + idle lulls, and
         gallop touches none of it.  Technique B attacks the trickle-paced part.  **Measure first** — trace
          the boot and bucket the gaps (the boot-instrument owed, gated on "todo empty AND nothing pending",
           NOT the naive quiet-window that under-measured 653 ms vs a felt ~12 s) to confirm trickle-bound
            vs async-bound before building.
- **The ~428 ms/step quiescence guard** (NEW candidate the trace gap-analysis surfaced): a fixed trailing
   idle after `beliefs/done`, ~22 % of every step, still unexplained — needs a `poll_step` read (any ttlilt
    it waits out before building).

## Ranked levers (cheapest ratio first) — original structural ranking, see RE-RANK above

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
     deepest lever — it attacks the 50 ms × N *and* the per-pass O(N) × N together). **(§status: the
      blunt half — the time-sliced greedy drain — is DONE as Technique A / the gallop, shipped 2026-07-08.
       The observation-driven TARGETED collapse is future work; see `Story_future_directions.md` §3 + the new
        §4 execution-optimisation layer.)**
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

- **2026-08-04** — **Technique A was INERT the whole time it was "shipped".**  The human, watching the
   per-House todo counts in Otro's headings: *"they have been hovering at 8 or 11 or 1, not sure why not
    flying down as they are supposed to."*  They never flew because the gate was `V.gallop && this.c.gallop`
     — **two** enable-gates ANDed — and `V.gallop` sat at `0`, the disarmed A/B arm, from the merge on
      2026-07-08 onward.  So every House everywhere drained at the flat `ANSWER_CALLS_TICK_MS = 50`, one
       elvis per gate, a hard 20/s ceiling; a standing 8-11 is ~400-550 ms of pure queue latency, and it is
        *above* `GALLOP_DEPTH = 6`, i.e. past the engage-NOW fast path, which had therefore never once fired.
  - **Root cause is a naming/namespace fault, not a logic one.**  `V` is the debug-VERBOSITY namespace,
     where every member is 0-means-quiet by convention (`V.organise`, `V.beliefs`, `V.req_legs` — all `0`).
      A *behaviour* switch parked in that drawer inherited the drawer's default, and "disarmed for one A/B
       arm" became indistinguishable from "resting state of a log level".  The scorecard above kept saying
        **Done + shipped**, truthfully about the code and falsely about the effect.
  - **FIXED to the one-axis end-state this doc already named** ("under the intended universal-on end-state,
     `no_gallop` is the permanent opt-out for warming-observer Books").  `V.gallop` is **gone**.  The gate is
      now a single presence-keyed **opt-OUT**, `c.no_gallop`, universal-on: `Story` sets it on a Run only
       when the Book carries `The/Opt/{no_gallop:1}` (HohoTiles + HohoWaftMap), everything else gallops.
        `GALLOP_DISARM` (exported, **defaults `false`**) survives as an explicit **escape hatch** for a
         `perf_ab` arm or a bisect — never as configuration.
  - **Two rules earned, worth keeping:** an enable-gate that defaults OFF makes "shipped" and "doing
     nothing" look identical, so a kill switch defaults ARMED and says so in its name; and a feature flag
      never lives in a namespace whose convention is that everything in it is off.
  - **⚠ OWED: a fleet re-verify.**  Arming this is a real cadence change for every Book, and the last fleet
     evidence (46/65 green armed) is from 2026-07-08 — fixtures have moved a long way since.  The two
      known cadence-sensitive Books are already opted out and that mark carries through unchanged, but a
       sweep is owed before trusting a red.  One-line hold if it needs sequencing behind other fixture
        work: `GALLOP_DISARM = true`.

- **2026-07-07 (eve)** — **Technique A BUILT + MEASURED** (branch `perf/gallop-tighten`, stacked on
   `perf/mapules-digest-gate` for the trace/perf_ab tooling): the answer_calls drain gallop-tightens,
    50 ms → 4 ms gate (`GALLOP_TICK_MS`), while the todo shows **sustained occupancy** — an item
     waiting at `GALLOP_SUSTAIN=4` consecutive drain gates; standing depth ≥6 is an engage-now fast
      path — disengaging the moment it runs dry, with a `GALLOP_BUDGET_MS=400` full-gate breather
       clip.  Gating: `V.gallop` (module debug switch) + `c.gallop` per House; Story marks every
        `Run.c.gallop` in story_drive unless the Book carries `The/Opt/{no_gallop:1}` (presence-keyed
         — a snapped `gallop:0` reads back as truthy `"0"`).  Editor Mundo unmarked so far.  The
          intended end-state (human, 2026-07-07): a **universal House function**, flipped on
           permanently once mature — the knob stays as the debug out.
  - **The §3 design sketch's trigger was WRONG, and one trace said so:** a Book settle's queue is a
     serial DRIP — each elvisto hop posts the next at UItime, depth 1-3 peaking 5 (push-depth now
      tagged `+N` on every `todo` trace event) — so the sketch's "20-40 deep" standing pile never
       exists and a depth trigger NEVER fires.  Rebuilt as occupancy-over-time, sampled at the shift
        boundary with PRE-shift depth (a gate landing mid-cycle must not read the momentary empty
         between hop N and hop N+1's targeting, or a chain flaps the gallop off every item).  The
          mutex-yield retry tightens too — mid-gallop an item's work outlasts the 4 ms gate, so that
           retry is the common re-drive.
  - **A/B (perf_ab warm medians, n=5/arm, all runs green):** HohoFlush 11.85 s → 10.31 s (**−13%**),
     MusuGlide 3.67 s → 3.15 s (**−14%**).  Step-1 trace: the mid-gap (drain-gate) bucket collapsed
      1026 ms → 429 ms; the residual is engage lag + trickle dry-outs.  `GALLOP_SUSTAIN=2` was tried
       and REJECTED — HohoFlush noise-identical, MusuGlide worse/bimodal; 4 is measured-best AND more
        cautious.  The ~430 ms/step trailing quiescence guard is untouched by the gallop and is now
         the largest single slice — next lever.
  - **FLEET: 46/65 green armed.**  17 reds reproduce DISARMED too (reds-only control sweep) → NOT this
     lever: 2 unauthored stubs, 2 runner-killers (peering standup wedges the tab — MusuBounce/Editron),
      2 audio-timeouts (empty /music), a stale-fixture wave from the Voro-guts Cytui rewrite (not
       re-recorded), + wrong/ordering fixtures.  Full triage in `spec/Fleet_reds_report.md`.
  - **TWO were gallop-CAUSED and robustly so (0/6 armed, 6/6 disarmed): HohoTiles (steps 4-5) +
     HohoWaftMap** — now **RESOLVED** via `The/Opt/{no_gallop:1}`.  The step-4 diff named the mechanism:
      the fixture asserts a WARMED point (`heat=4.478,held,long` + its `{"say":…}` child, first→last
       spanning ~3.2 s; HohoTiles even carries an `EntropyArrest` tol:any matcher for the heat/first/last
        numbers) and the galloped settle quiesces at ~1.7 s, snapping the point just-born (`heat=0.98`,
         no say/held/long).  Genuinely **earlier AND different** — these Books observe mid-settle warming,
          the cadence-sensitive class §3's opt-out is for.  NOT re-recordable (the warmed state is a
           wall-clock race under gallop).  `The/Opt` is toc-only (under `The`, not the per-step `Snap:H`),
            so the mark is a one-line toc change with ZERO step-dige churn; verified both Books GREEN armed
             after marking, and the mark round-trips through a live re-encode.  **Branch is now
              fleet-green (modulo the pre-existing env/stale reds) and pull-ready.**  Under the intended
               universal-on end-state, `no_gallop` is the permanent opt-out for warming-observer Books.
- **2026-07-07 (pm)** — TRACE GAP-ANALYSIS reprioritised the levers.  Exposed the existing per-step
   beliefs-cycle trace over the CLI (`runner_ask trace <n>` — the runner-side `trace` op already served
    it; only the CLI OPS list lacked it) and wrote `scripts/trace_gaps.mjs` to bucket the inter-event
     gaps.  On HohoFlush (first Lies+Lang settle measured this way), **step 1 = 1984 ms across 103 events**:
       - **~982 ms (49%) in ~43 ms "mid" gaps** = the `ANSWER_CALLS_TICK_MS=50` drain gate draining ~28
          todo items one-per-50 ms.  → **Technique A (greedy-to-budget drain) is the biggest lever.**
       - **~428 ms (22%) in ONE contiguous `beliefs/done → quiescent/0.428` gap** — a fixed trailing
          quiescence wait, ~428 ms in EVERY step (steps 1/5/7 all show it), 6× the ~75 ms the design
           assumes.  ×7 steps ≈ 3 s of a ~12 s Book.  **NEW candidate lever — needs `poll_step` read.**
       - **~348 ms (18%)** tight belief work; **~225 ms (11%)** trickle (Technique B's whole target —
          small, and the descent is already mostly event-driven per `Hovercraft.svelte:281`).
     Lesson (again): measuring the premise before building redirected effort off Technique B (11%) onto
      Technique A (49%).  Same discipline that killed lever #4.  Method: warm-runner caveat aside, the
       gap STRUCTURE (proportions) is consistent across steps, so the ranking is robust to one sample.
- **2026-07-07** — built `scripts/perf_ab.mjs`, the PERF instrument the lever-#4 autopsy called for:
   warm the runner (discard cold run), then time N settles back-to-back on the SAME warm runner and
    report the **median** (robust to stalls) + spread + green-count.  A/B a lever by running one arm per
     flag state (HMR between), comparing medians — never single runs, never fresh-vs-degraded sweeps.
      Proven working; median is stable (HohoTiles ~14.2s, MusuGlide ~3.24s across batches).  It also
       surfaced the escalation of the drift finding: **after heavy session use the runner develops
        intermittent multi-second stalls (~1/5 runs)** — short Books stay green-but-slow, long Books
         (HohoTiles) sometimes trip a stall into a step-timeout RED (4/6 green).  Median survives this;
          CORRECTNESS signal does not.  A fresh :9091 tab reload clears it (human-only).  Lesson for the
           high-risk levers (Technique A/B): get clean correctness signal on a FRESH runner — a stall-red
            is indistinguishable from a real wake≠hold race, which is exactly what those levers risk.
- **2026-07-06** — lever #4 (`organise`/`attend` dige-gate) **tried and ABANDONED** (branch
   `perf/organise-gate`, discarded — never merged).  The gate: watermark = positional serial of every
    walked node's `version` (read off the standing `Se.c.T.sc.N`, House's own version excluded because
     `reset_interval`'s `{mo:'main'}` replace churns it every tick; `n.c.walk_id` tags so a reminted ref
      can't alias a stale mark); skip `Se.process` when the mark is unchanged.  Type-clean, HohoTiles
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
     perf-soft** under these same confounds; its HohoFlush content-gated greens are the real gate.
- **2026-07-06** — §6 `Lang_build_mapules` content gate (lever #6, branch
   `perf/mapules-digest-gate`): two-tier like LangGraft's — digest of every Map entry
    (kind|key|depth|line|class|span|region_path) PLUS the dock text (body spans/line
     geometry consume it — Map_dige alone is too weak here, Mapulen carry absolute
      offsets), hashed once per recompile (cached on dock.c against job.version), O(1)
       every other wake; same digest → the standing Mapulen survive, no empty+rebuild+
        dock-bump.  Verified LIVE on the :9091 runner: HohoTiles 6/6 green, HohoLango
         green; census mid-run dropped ~3.3k→~2.5k bumps/think (coarse — window-phase
          sensitive).  NOTE: HohoWaftMap is RED at step 1 (error:null, fixture shape)
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
