# Composition — what breaks when it all runs at once

*Opened 2026-08-06, from one evening of the human running the real thing and saying what was wrong.*

This doc exists because the failures below have **no other home**. Each subsystem has a todo that
 owns its mechanism — `Backpressure_todo` the transfer control loop, `Radio_todo` the dial and the
  glass, `Cluster_spec` the relay and the boot, `Vyto_sizing_todo` the foam — and every one of those
   mechanisms was, on the evening this opened, *individually correct*. The app was still barely usable.

**The arc:** get from "each part is proven and the whole is unusable" to "the whole is proven".
 That needs a test level that does not exist yet (§3), a ledger of what actually goes wrong so we
  stop rediscovering it (§1), and a name for the mistake that keeps producing it (§2).

---

## 0. Next move (read first)

1. **Build `MusuNeGrind`** (§3). Everything else in here is a symptom; this is the instrument.
    Design + the invariants it must assert are in `Backpressure_todo` §0 item 00. New `MusuNe*` Book
     prefix (the human: *"far too much is ending up in Musu"*), registered in `Waft:Credence` under
      `What:MusuNe`. Copy `MusuVend`'s scaffold, `Heistation.g:653`.
2. **Then the startup wait** (§4.1) — it taxes every iteration, including the ones spent fixing the
    rest of this list. Measure before touching: the era ladder is only ~15s worst case, so it is not
     the whole story and guessing at it has already cost one wrong diagnosis tonight.
3. **Then one-sided reload** (§4.2). Until it works, every test of everything else costs two
    coordinated reloads, which is the tax that makes the whole loop grim.
4. Then §4.3–§4.7 as the Grind Book surfaces them with evidence attached, rather than in the dark.

**Free win available before any of the above (2026-08-08):** §3.6 states a testable chain — the
 playhead's chunk asks share one serial beat with the whole heist driver, so a heist may be setting the
  clock the music runs on. The instrument is already shipped and costs nothing to read: catch one
   `⏳ Swarm_share_beat still running past 600ms` line during a heist with music playing and read its
    `cull=/tour=/peers=/keep=` split. One paste either promotes §3.6 to measured or kills it. Do that
     while doing something else; it needs no runner and no setup, only a live tab.

**Do not** treat §1's fixed rows as closed history — read §2 first. The pattern is the deliverable.

---

## 1. The ledger — every complaint of 2026-08-06, verbatim, with status

Kept verbatim on purpose: the human's own words repeatedly turned out to name the cause precisely
 ("disappeared from the uploaded side" *is* `Heist_release_rec`), and paraphrasing loses that.

| # | What the human said | What it was | Status |
|---|---|---|---|
| 1 | *"it still says we have a half-sealed link to Lefto… they BOTH say 'we never granted back'"* | `Diag_trouble` read `self.sc.pub`; an %Identity keeps its pub on `.c.keys` and only `prepub` in sc. `mine` was always `''`, so every whole %Pier reported half-sealed, forever, on both ends | **FIXED** |
| 2 | *"downloads overlap a bit much now"* | two causes: the overlap slot opened for a track *stuck* near the end rather than *finishing*; and `heist_inflight` was enforced **per %Haul**, so N Hauls gave N concurrent tracks whatever the knob said | **FIXED** (`INFLIGHT=1`, global budget, moving-gate) |
| 3 | *"120/137 downloaded side, disappeared from the uploaded side, but hasn't started turning up on disk yet! not even as a chrswap"* | the source freed bytes it had promised. `rec.c.sent >= total` is a frontier not coverage; `PARK_CEIL` and `RELEASE_IDLE` were both 20000, so the quiet a park *instructs* read as the disinterest a release *requires* | **FIXED** (`Backpressure_todo` §3.1c) |
| 4 | `◈ pull Cosmic Hweeldi 142/196 … 141 … 138 … 135 … 132` → `BENCHED 60s — frozen` | **`held` going DOWN.** `Heist_land` releases each chunk as it reaches disk; §5.4 moved the landing off the beat and never told the puller. So the sink re-asked, re-downloaded and re-hashed a file it was at that moment writing — and the bench watchdog, which wants `held` to climb, benched it for succeeding | **FIXED** — the largest single win of the evening |
| 5 | *"I can't get past that 100% cpu usage, that is shit, and probably causing all these other problems"* | correct on both counts. One real find: `o_query`'s second-and-later key filter was **O(M²)** — `M = M.filter(…)` per rejected row — in the innermost query primitive, hit per frame by `inbox.oai({req:'unemit', seq, …})` | **PARTLY** — see §4.3 |
| 6 | *"likes pausing in Peeroleum_deliver / Peeroleum_book_unemit"* | a stack sample says *where*, never *how much* or *why*, and the two candidate whys want opposite fixes | **INSTRUMENTED** — `deliver` electrode, silent unless ≥10% of wall clock or a ≥50ms block |
| 7 | *"73 dropout(s) spliced — real gaps you would have heard"* | `Diag_trouble` reading `radio.sc.drops`: audible gaps the concealer spliced over. A **symptom readout**, not a cause — the audio callback missed its deadline because the thread was pinned | downstream of §4.3 |
| 8 | *"targeted e:reqyonciliation landed nowhere — target reminted\|dropped"* | `Housing.svelte.ts:1339`. An `elvisto` aimed at a %req *by reference*, delivered at Atime; the target had been dropped by then. Returns cleanly, so a warn not a fault — but it means reqs are being dropped out from under in-flight continuations, which is what a churning heist does (`w.drop(landReq)`, the awaitbuf orphan sweep, the BUFCAP sweep) | **OPEN** (§4.5) |
| 9 | `ws CLOSE code=1006` reconnect storm, *"but less than before"* | downstream of #4 and §3.1b — a pinned thread misses the relay's 15s reaper | improving; re-measure after #4 |
| 10 | `⏳ Swarm_share_beat still running past 600ms — skipping this tick (×221 so far)` | the beat permanently overrunning while the wire moved only ~60KB/s of actual music | **OPEN** (§4.4) — and the reason this is the Grind Book's load-bearing assertion |
| 11 | duplicate `ws RECV ive_got seq=321` ×4, `seq=323` ×4, ~4 fresh seqs/sec out | **NOT sender retransmits** — `ive_got` has been ephemeral on send since an earlier pass. Mis-diagnosed once tonight; see §4.6 for the two live leads | **OPEN** |
| 12 | `▣⚠ Vyto watchdog: forced settle after 240 frames of unbroken motion` (repeatedly) | a cell never stops moving, so the glass never settles and renders continuously | **OPEN** (§4.7) — a standing CPU consumer independent of the wire |
| 13 | `🗂⚠ wormhole write … toc.snap overran 5000ms — retrying (attempt 2/4)` | disk write starved behind everything else | **OPEN** |
| 14 | *"the startup time it takes to get around to trying the Heist again… way too slow! what the fuck are we waiting on?"* | unknown. The era-confirm ladder is ~15s worst case, so it is not the whole story | **OPEN** (§4.1) |
| 15 | *"we're still not having just the runner reloading working at all — the two Pier have to hit reload at the same time and arrive with fresh states for each other"* | a reborn peer restarts its per-Pier seq at 1; the survivor's inbox still holds finished %unemit rows at those seqs, so its frames are re-acked and never dispatched until the era handshake resets the route | **OPEN** (§4.2) — known as `Cluster_spec` heading 8 |
| 16 | *"☠ the radio is starved… I just feel that I do not care, it should just work out somehow"* | right instinct. A starve should dial what it *has*, not raise a badge | **OPEN** (§4.8) |
| 17 | *"all these Musu\* tests really didn't prepare us too well for the clusterfuck of them all together"* | structurally correct, and the reason this doc exists | **→ §3** |
| 18 | *"so it's pretty shit code I guess?"* / *"it has quite a few things to robusticise"* | see §2 — it is one repeated mistake, not diffuse quality | **→ §2** |

| 19 | `deliver threw ReferenceError: pub is not defined at Peeroleum_bound_inbox` + *"good software is incapable of producing this kind of autistic bollocks"* | **`${pier%pub}` inside a template literal.** The `.g` compiler leaves `%` alone in a backtick string, so it emitted the JS `pier % pub` — modulo against an undeclared name — and threw. In a **log line**, on the branch that runs **only at the 2000-unemit cap** | **FIXED** — and see §2.1, it is the sharpest case in the doc |
| 20 | `◈⚠ transcode STALLED — parked want id=… from_idx=16 waiting 1438s` ×3, climbing | 24 minutes parked, three ids, all at `from_idx=16`. Downstream of #19 (a source whose deliver throws cannot serve a park) but the identical `from_idx` on three unrelated tracks is its own smell — investigate after #19 has run clean | **OPEN** |

*Also open, found while reading rather than reported:* `MusuMag` is red at 0.7 with four unfired
 `%see` claims (mag/warm-start/park pipeline). **Pre-existing** — proved by controlled revert, identical
  red with and without the evening's changes — and undiagnosed.

---

## 2. The pattern: a cheap local read standing in for the expensive true one

Every defect in §1 that was actually *fixed* is the same mistake:

| the cheap read | the true question | cost |
|---|---|---|
| `map[off] == null` | is any chunk of this page missing? | permanent invisible holes (`Backpressure_todo` §3.1b) |
| `rec.c.sent >= total` | has every page actually crossed? | source freed promised bytes (§3.1c) |
| `now - want_ts > 20s` | does the sink still want this? | a park's own enforced quiet read as disinterest |
| within 24 of done | is this track *finishing*? | a wedged track propped the window open forever |
| `rheld > bench_held` | is this track frozen? | a landing benched for succeeding |
| `self.sc.pub` | what is my pubkey? | both ends accusing each other, forever |

Each is individually reasonable, cheap, and correct *at the time it was written*. Each became wrong
 when something else changed underneath it — the relay learned to shed, the landing left the beat.
  **That is not a quality problem, it is a coupling problem**, and it is why the answer is §3 rather
   than a code-review pass.

**The standing rule:** a high-water cursor may not answer a question about coverage; a timer may not
 answer a question about consent. Both are greppable — a frontier name (`sent`, `have`, `held`,
  `frontier`, `last_asked`) on the left of a comparison against a total or a threshold. Worth one
   deliberate sweep of the transfer spine, which has **not** been done.

Twice the surrounding comment confidently asserted the true property ("every page has crossed at
 least once") while the code computed the cheap one. **The comment is not evidence.**

### 2.1 The safety net nothing ever tests

§1 #19 deserves its own heading because it is the cleanest specimen in the doc, and because the
 human's objection to it — *"good software is incapable of producing this kind of autistic bollocks"*
  — is **correct, and the reason is structural rather than a matter of care.**

The `%` sugar had never been wrong anywhere else; a repo-wide grep found this was the only use inside
 a template literal, so the compiler gap and the one site that hit it coincided exactly once. But the
  compounding is the real lesson:

1. It sat in a **log line** — the least load-bearing code in the file.
2. On a branch that runs **only at the 2000-unemit cap** — i.e. only once the inbox is already
    melting. **No Book can reach it**, and no healthy session ever will.
3. That branch is the **structural backstop**: the thing whose entire job is to keep the pump alive
    through a flood.
4. So it threw on every visit once the flood arrived, and the one thing it exists to do — **trim** —
    was the one thing that stopped happening.

**The backstop did not merely fail to save the wire — it was disabled precisely by the emergency it
 exists for.** A safety net that runs only in the emergency is a net nothing tests, and an untested
  net is a trapdoor.

> **Correction (2026-08-06, from the 20-analyst review).** The first version of this section said the
>  throw meant *"the frame was lost"*. **That is wrong.** Both call sites (`Peeroleum.g:739`, `:768`)
>   invoke the bound **after** `await inbox.do()` and `Peeroleum_rollup_faulty`, so the frame was
>    already booked, dispatched and acked. What the throw actually cost was the trimming, the trailing
>     `feebly_ponder()` wake, and a rejected deliver promise. The consequence is still severe — untrimmed
>      is how the inbox reached 3400 unemits, and every per-frame inbox query is O(depth) — but it is a
>       **slow strangle, not frame loss**, and the distinction changes where you look next.
>  Worth recording why this matters more than the fact: **that claim was a comment asserting a property
>   the code did not support** — the exact failure §2 ends by warning about, *"the comment is not
>    evidence"* — written by the same hand, the same day, one file from the rule. The rule does not
>     exempt the person writing it, and prose is where this codebase is most confident and least checked.

Two rules out of it, both cheap and both now applied at the site:

- **Emergency paths need a test more than ordinary ones, not less.** Anything gated on a cap, a
   watchdog, a retry ceiling or a "this should never happen" is by construction unexercised. Either a
    Book drives it, or it must be assumed broken.
- **Housekeeping may not kill the work it houses.** Trimming is bookkeeping — the bound's own header
   already said *"allowed to run LATE, just never never"* — so it now runs through
    `Peeroleum_bound_safe`, a loud throttled catch. Deliberately asymmetric: `inbox.do()` and
     `Peeroleum_rollup_faulty` are NOT wrapped, because those **are** the delivery and a throw there
      must stay loud. The net goes around the housekeeping, never around the work.

This generalises §2's table. There the cheap read stood in for the expensive truth; here an
 **untested path stood in for a guarantee**. Same shape: something assumed sound because nothing had
  ever contradicted it, in a place nothing could.

### 2.2 The discovery layer has never been observable

*From a concurrent agent, 2026-08-06, and it reframes §3 — so it is recorded here rather than lost in
 a transcript:* **"the transfer's problems aren't mostly in the transfer — they're in the fact that the
  discovery layer above it has never been observable, so every bug there has had to be found by you,
   live, twice."**

The word *mostly* is too strong — the largest win of 2026-08-06 (#4, `held` going down) was pure
 transfer, as were #2 and #3. But strip that word and the claim is not only right, it is **measurable**.
  `Radio_trace` call sites, by ghost:

| ghost | marks |
|---|---|
| `Radio.g` | 15 |
| `Heist.g` | 11 |
| `Ra.g` | 9 |
| `Repli.g` | 4 |
| `Peeroleum.g` | 1 |
| **`Swarm.g`** | **1** |

Of the ~38 event kinds in the tree — `heist-*`, `transcode-*`, `pcm-*`, `serve-*`, `park-stall`,
 `land`, `pulls`, `starve`, `deliver` — **not one** reports a Pier going live or dark, an era change,
  an advertise, a grant, a seal, an invite redemption, a reconnect, or a rebirth. Swarm's single mark
   is `beat`, which measures the *clock*, not discovery.

**The asymmetry shows up in §1's status column, which is the real evidence:**
- transfer rows — #2 overlap, #3 released-while-promised, #4 held-going-down — **all FIXED**, each
   within a day of being reported;
- discovery rows — #11 `ive_got` storm, #14 startup wait, #15 one-sided reload — **all still OPEN**;
- #1, the half-seal, was discovery and is marked FIXED, but only after reading wrong **on both ends,
   forever**, with a badge sitting right there claiming to report it.

So the sharper statement: **the transfer's bugs get found and fixed in a day because it is instrumented;
 the discovery layer's bugs recur, stay open, and cost a live session each time.**

And the corollary, which ties this to §2.1: the discovery layer is not merely uninstrumented — its one
 instrument was **itself broken** (#1: `Diag_trouble` reading `self.sc.pub` for a key that lives on
  `.c.keys`, so `mine` was always `''`). A *wrong* instrument is worse than none, because it spends
   attention on a phantom while the real fault runs. Same shape as the backstop in §2.1: a thing whose
    whole job is to help in trouble, untested, doing harm exactly when it mattered.

**Why this reframes §3.** The missing level may be an **observability** level before it is a test level.
 Ten `Radio_trace` marks in `Swarm.g` — pier live/dark, era change, advertise, grant, seal, redeem,
  reconnect, rebirth, route register, offer — cost an afternoon, need no second tab, no harness, no
   coordination, and turn the four open discovery rows from "reproduce it live and stare" into "read
    the ring". A Book proves a mechanism you already understand; a trace finds the one you do not.
     Cheaper than `MusuNeGrind` and strictly prior to it.

**LANDED 2026-08-06 — `Swarm.g` 1 mark → 8** (`f8868a20f022e254`). Seven new electrodes, all `.c`-only
 (`Radio_trace` pushes to `M.c.supply_trace`, cap 1200), so no fixture byte moves:

| mark | where | the question it answers |
|---|---|---|
| `station-up` | `Swarm_station_up` | t=0 for the whole file; `era` names *this* boot; `routed` vs `piers` is the reload shortfall before a frame is sent |
| `rebirth` | `Swarm_note_era` | the peer restarted — counts `wanted`/`parked`/`retx` **before** the deletes discard them |
| `era-kick` | `Swarm_pulse_all` | the epoch backstop firing at all, and `kicks` climbing to the 60s ceiling = the stranded pair |
| `advertise` | `Swarm_gossip_music` | `piers → granted → told`: which of the three gates ate the boast |
| `seal` | `Swarm_seal` | a friendship reaching durable storage; `grants:1` is the one-way pairing at the moment it forms |
| `redeem` | `Swarm_redeem` | a pairing starting — a `redeem` with no `seal` after it is the silent issuer-side death |
| `rebuff` | `Swarm_rebuff` | every door slam, in the file rather than only in a console nobody was watching |

`advertise` is the one to read first: this verb already computed all three numbers and returned only
 `told`, to a caller that discarded it — the facts existed for one stack frame and were never once seen.
  That is §2's pattern one more time, in the discovery layer's most-complained-about path.

**What the verification runs then exposed, unprompted.** `Swarmation.g` defines exactly two Books,
 `MusuSelf` and `MusuThem`. Both ran green — and both were **vacuous**: neither had *any* recorded
  fixture in `wormhole/Story/`, and the snaps the run auto-wrote were six lines whose entire content
   was `self,round`. So the swarm layer's own two Books assert **nothing**, and a green from them is
    not a gate. (The auto-written stubs were deleted, not kept: recording a baseline while the tree is
     dirty is the one thing fixtures must never do.) Two consequences worth holding together:
- §2.2's claim was **understated**. Discovery isn't just uninstrumented — its Books are hollow, which
   is why `MusuBuddy`/`MusuHeist` carry the whole burden of a layer they only touch incidentally.
- it is a second, independent argument for **#23** (strip `self,round` via `omit_sc`): strip it and
   these two fixtures are *empty files*, which states the truth out loud instead of dressing a hollow
    Book in a plausible-looking snap.

### 2.3 A Book's verdict is partly a function of how warm the tab is

Found 2026-08-06 while verifying an unrelated change, and it undermines the gate itself, so it belongs
 beside §2.1 and §2.2 rather than in the runner notes.

Three consecutive `MusuHeist` runs, **identical code**:

| runner state | outcome | caveats |
|---|---|---|
| just `reload`ed (cold) | **red**, `ok_pct:0.95`, step 2 | 20 |
| warming | 22/22 | 14 |
| warm | 22/22 | 1 |

The failing step's entire diff was **one missing `%see`** plus `self,round=5` where the fixture had
 recorded `self,round=6`. The Book had started before the world settled to the depth the fixture was
  recorded at, so an early claim never fired. **`self,round` is the observable** — below the fixture's
   value means the run is cold and the red is an artefact.

Two consequences, both worse than the inconvenience:

- **False reds are cheap to generate and expensive to read.** The natural response to a red is to
   suspect the change in your hand. Here the honest attribution needed three runs and a fixture diff;
    the wrong attribution was one step away and would have reverted a correct fix.
- **Caveat counts carry no signal.** 1 → 14 → 20 on unchanged code. A caveat is *forgiven* value-noise
   (EntropyArrest grafting got→exp), so a jump must never be attributed to an edit without a re-run.
    Only `ok`/`ok_pct` mean anything.

**What `self,round` actually is** (corrected after a survey — the first draft of this section called it
 a frozen boot depth, which is wrong): it is the **cumulative belief-round counter** (`Hovercraft.svelte:39`),
  stamped into every snap, climbing all through a run — `MusuHeist` records `6,8,9,12,…,38`. It appears
   in the fixtures of **~120 Books**, and *changes within the run* in at least 30. Most exposed by count
    of distinct values: `MusuRaChase` 55, `MusuRaStream` 39, `PereProof` 32, `LeafFarm`/`LakeNets` 29,
     `MusuHeist` 21.

It is **not** entropy-arrested anywhere (no `Entcase` names it). That is why Books are normally green:
 under a quiescent runner the round sequence is genuinely reproducible. It drifts only when the tab is
  doing something *else* — which makes it the one value in the whole snap that detects ambient work.

**So do not EntropyArrest it.** Forgiving it would buy determinism by blinding ~120 Books to "something
 else was running", and it would not even fix the failure that prompted this: on that cold step 2 the
  fatal diff was the **missing `%see` line**, which is structural and no value-graft can forgive.
   Arresting `round` removes a diff line and leaves the step red.

**The right cut is to strip it from the snap, not forgive it in the snap.** The mechanism already
 exists — `omit_sc` session-key stripping, `SESSION_KEYS = {active, created_at, new, not_found}` at
  `Text.svelte:362`. `round` belongs in that class: a session fact, not a fixture fact. Keep the number
   as telemetry (where drift is a *signal* worth alerting on) and out of the recorded bytes. That gets
    determinism and keeps the detector, instead of trading one for the other.

The underlying rate variation is still **§4.1's unexplained startup wait**, and `round` is now a cheap
 probe for it. It also sharpens §2.2: the instrument was not merely absent, it was *lying in the
  direction that costs the most* — exactly like `Diag_trouble` and the backstop before it.

---

## 3. The instrument: `MusuNeGrind`

Not a convenience — a **missing test level**. Every defect above lived in composition, and not one
 was reachable by any `Musu*` Book, because each of those runs one mechanism in a quiet world.

Full design, invariants and traps: `Backpressure_todo` §0 item 00. In short — two runners over the
 **real relay** (not a loopback mock, so reconnects, sheds and one-sided reloads stay in scope),
  bulky binary Repli while the radio plays and a mag replicates, asserting **invariants not a snap**
   (the fixture will be nondeterministic like MusuBuddy, so a 500-line diff cannot be the gate).

The load-bearing claim is **the beat never overruns its cadence for a run of ticks**. Everything else
 degrades *through* the beat, so that one assertion alone would have caught the landing race, the
  park/release livelock and the `ive_got` storm. `Swarm_share_beat` already counts it
   (`skipping this tick (×221 so far)`); nothing asserts on it.

---

## 3.5 The metronome: an anti-freeze watchdog is pacing the whole machine (2026-08-06, MEASURED)

**`Vytui.svelte:127`, `MAX_MOTION_FRAMES = 240`, ~4s @60fps.** Its own header says it is unreachable:

> *"far beyond any real settle (<1s), so a healthy layout never trips it; a sick one can no longer peg
> the main thread → freeze the tab → kill the peer heartbeat."*

It trips on **every step of Sounditron**. The glass never settles on its own, so the watchdog is not a
backstop — it is the clock the Book runs on.

**How the account was closed.** Sounditron: 7 steps, ~7.75s each. MusuReco: 11 steps, ~1.1s each, same
runner, same minute. Five electrodes, each added because the previous one exonerated its suspect:

| span | mark | cost | verdict |
|---|---|---|---|
| the five boot waits | `boot` | **1.5s for the whole run** | innocent — every truth-fn settles at 0ms |
| `waitVyto` | `vyto-wait` | **60–180ms** | innocent (prime suspect) |
| quiescence | `quiesce` | **0.15–0.25s** | innocent |
| snap encode/compare/store | `snap-cost` | **16–103ms** | innocent |
| `advance` → next step | `advance` | **3801ms, ±7ms over 7 samples** | **the thief** |

`resolve:0` — the Runstepped callbacks are free. A dead-constant 3.8s is a *timer*, not contention.
`post_do` is documented **"Does NOT call beliefs()"**: it pushes onto `H.todo` and waits for something
ambient to drive the loop. On a world with a resident Vyto glass the only thing regularly driving it is
the 240-frame force-settle. **`post_do` is called twice per step** (once for `snap_step`, once for
`do_step`) — 2 × 3.8s = the 7.6s.

**Three consequences, in ascending order of importance.**
1. Sounditron is slow because its glass never rests, not because anything it waits for is slow. Every
   ceiling it was blamed on was settling instantly.
2. **This is very likely the unexplained 3–5s single-call block in `deliver`** (§2's open question, and
   the one thing the 20-analyst competition could not account for). A glass in continuous rAF motion
   pegs the main thread in ~4s bursts — which is precisely the failure its own comment predicts, written
   by someone who believed the branch was unreachable.
3. **Third instance today of the same pattern**, and it is now the most reliable thing in this document:
   `waitVyto`'s *"the chase still converges"*, `Swarm_gossip_music` computing three numbers and returning
   one, and now *"a healthy layout never trips it"*. Each is a **comment asserting a runtime property
   nobody measured**, each was false, each cost real time. §2's rule — *the comment is not evidence* —
   should probably be promoted from an observation to the thing this document is about.

**Next move (do NOT skip to a fix).** The question is now *why does Sounditron's voronoi never reach
`SETTLE_FRAMES = 8` consecutive calm frames* — a vertex-count flicker pinning `drift`, a target chasing
itself, or a NaN, all three named as suspects at `Vytui.svelte:121`. `runner_shot --why` reads the
render telemetry film strip (gate + wave/morph/settle ring) and is the right instrument. Find the cell
whose `disp`/`drift` stays pinned. **Do not raise `MAX_MOTION_FRAMES` and do not lower it** — it is
doing its job; the layout under it is not.

## 3.6 The music's asks are queued behind the heist's work (2026-08-08, HYPOTHESIS — instrumented, NOT yet measured)

**Status matters here and this document is the reason: the section above is MEASURED, this one is NOT.**
What follows is a causal chain read out of the source and matched against one console paste. It is
stated so it can be *killed*, and the instrument that kills or confirms it is already shipped.

**The chain.** All four of these live in one serial `Swarm_share_beat`, in this order:

| # | phase | what it is |
|---|---|---|
| 1 | `Ra_shuffle_cull` | disk-touching, self-throttled to 30s inside |
| 2 | `Stoker_tour` | the collection conveyor — a dig |
| 3 | the friend loop | offers, **and the "keep the wire ahead of the playhead" `Repli_want_next` asks for the PLAYING record** |
| 4 | `Heist_keep_beat` | *the entire heist driver, awaited inline* — its own comment concedes "cheap when no keep stands" |

`Swarm_share_loop` fires every 600ms but is **busy-guarded**: while a beat is still in flight the next
tick is *skipped entirely*, not queued. So the beat's true period is however long phase 4 takes — and
phase 3, the music's chunk asks, only runs once per beat. A heist therefore does not merely compete
with playback for bandwidth; it **sets the clock the playhead's asks run on**.

**What the 2026-08-08 console shows, and what it does not.** `×221` skipped ticks, and in the same
paste the radio flapping `playing → starved → playing → starved` on one record (`of:90`) while Repli
reported a healthy 300–500KB/s. A starve is `m.bytes[seq] == null` (`Radio.g:429`) — the needed chunk
was never *asked for in time*, which is what a stretched phase-3 cadence would produce, and it is
consistent with bytes flowing fast the whole while. **Consistent with is not evidence of.** Nothing
here rules out the ordinary explanation that the wire is simply slower than the playhead.

**The instrument (shipped 2026-08-08, `Swarm.g`).** The beat now records a four-way split on
`w.c.beat_split` and prints it *in the skip line itself* — the line everyone already pastes:

    ⏳ Swarm_share_beat still running past 600ms — skipping this tick (×N so far) … · last beat: cull=… tour=… peers=… keep=… (ms)

**The test, and it is one paste.** Catch that line during a heist with music playing.
- `keep` dominates ⇒ the chain above is real, and the fix is structural: the playhead's asks must not
   share a serial beat with the heist driver (give phase 3 its own cadence, or bound phase 4's work per
   beat). **Do not just raise the 600ms** — that lengthens the ask period, which is the defect.
- `cull`/`tour` dominate ⇒ different problem entirely, a disk verb on the live path.
- all four small but the total large ⇒ the cost is *between* the phases; suspect `post_do`/the metronome
   in §3.5 and treat this section as refuted.

**Why this is filed here and not in `Backpressure_todo.md`.** That doc names the shape already —
*"every stage shares one 600ms beat"* — and routes a starved radio to this document. This is that
sentence with a specific mechanism and a specific way to check it. It is also, note, the *fourth*
instance of §2's pattern in the making: "cheap when no keep stands" is a comment asserting a runtime
property nobody has measured. Measure it before believing either it or me.

## 4. Open, grouped by where the work is

**4.1 The startup wait.** Boot electrode with phase timings first; the era-confirm ladder
 (`5000 * 2^kicks`, capped 60s, reset on confirm at `Swarm.g:820`) is ~15s worst case and does not
  account for what the human sees. Do not guess at this one.

> **First measurement (2026-08-06, one Sounditron run on a peerless runner tab).** Step 7's own snap
>  said it: `Session,alive=41,possibilities=0`. The arithmetic closes exactly — 15s `stoker_wait`
>   timeout + 20s `peer_wait` timeout + 6s `sound_wait` timeout = 41s, with `relay_wait` settling
>    instantly. So on a world with **nothing to find, every ceiling is consumed in full, serially,
>     silently** — a timeout is "graceful", so it never complains, and the boot cost is Σ(ceilings)
>      by construction. Three realisations for whoever picks this up:
>  1. **The waits need a third state: settled-by-absence.** Each `Sounditron_await` truth-fn answers
>      "true yet?" but never "could this EVER come true here?" Zero sealed `%Pier` rows and no runner
>       lease ⇒ `peer_wait`'s 20s cannot be won — settle at once with an honest note. The stoker
>        comment CLAIMS an at-rest stoker settles early; the 15s burn on this run says that
>         absent-branch is not firing (suspect: shareless runner leaves `st.sc.stock` null without
>          the stoker ever classifying itself spent/idle). Two of the six waits have already had this
>           exact bug (the old `stock==null` 30s burn; `peer_live` reading a Lies lease so it timed
>            out EVERY run) — a wrong truth-fn costs its full ceiling on every boot forever, and
>             nothing catches it. That is §2.1's untested-net shape wearing a countdown.
>  2. **The electrode is nearly free: `Sounditron_await` already knows everything.** It holds the
>      label, the start time, and the met/timed-out outcome — it stamps them into the Beat HUD and
>       throws them away. Ten lines: append `{beat, label, ms, met}` to a `w.c.boot_ledger` (`.c`,
>        never snapped) and mirror it as a `Radio_trace` `ev:'boot'` mark, and every future run
>         carries its own phase breakdown, readable via `runner_ask world`. Do this BEFORE touching
>          any wait, then re-measure the real two-tab boot — the live case (peer present) should
>           settle early on every rung, so whatever the human still feels is a wrong truth-fn, and
>            the ledger will name it.
>  3. **The greeting is already event-driven** (`Swarm_hi_all` rides every (re)connect behind the
>      hello-bind, `Swarm.g:655`); the 5s→60s kick ladder is only the backstop for a LOST first
>       contact. So do not start by tuning the ladder — measure first; the ladder shows up in the
>        ledger as a peer_wait that settles at ~5s/10s rather than sub-second.

**4.2 One-sided reload** (`Cluster_spec` heading 8, era-scoped seqs). The single change that would
 most improve the *iteration* loop rather than the product.

**4.3 The CPU.** One real find landed (`o_query`, §1 #5 — reviewed and approved by the human).
 Whether that was the bulk is unknown; the `deliver` electrode will say, and it stays silent when
  healthy so its own output cannot drown the 300-mark ring. **`Stuff`/`Housing` are the stable end —
   changes there need evidence and an explicit look, not a plausible reading.**

**4.4 The overrunning share beat.** Likely a composite of 4.3, 4.6 and 4.7 rather than its own bug —
 but it is the thing the Grind Book asserts on, so it gets measured either way.

**4.5 Reqs dropped under in-flight continuations.** The `reqyonciliation` warn. Ask whether a
 continuation should hold its target alive, or whether the drop should cancel the continuation.

**4.6 The `ive_got` duplicate storm.** Two live leads, since retransmits are ruled out: the relay's
 fan-out, and `Swarm_gossip_music` firing on **every** `swarm_hi` (`Swarm_hi_hear`) unthrottled.
  *Tried and backed out 2026-08-06:* adding `ive_got` to `Peeroleum_deliver`'s receive-side bypass —
   `SwarmGot` went 0.33 while its three sibling Books stayed green, which is past the fixture drift
    that move alone explains. Note left at the site. Settle whether that Book asserts on the boast
     being **booked** or being **delivered** before trying again.

**4.7 Vyto never settling.** A cell whose `disp`/`drift` stays pinned, so the watchdog force-settles
 every 240 frames and the glass renders continuously. Independent of the wire; belongs with the Vyto
  docs but is listed here because it is a load-bearing share of the 100%.

**4.8 A starved radio should self-heal** — dial what it holds instead of raising a badge. *"It should
 just work out somehow"* is the correct specification.

---

## 5. Where things live

- **`Backpressure_todo`** — the transfer control loop: the three clocks, the req refactor, the
   measured RTO, §3.1b/c/d's defects, and `MusuNeGrind`'s design. Anything about *how the pull is
    paced* goes there, not here.
- **`Cluster_spec`** — relay, boot→channel map, the Brink ladder, the epoch handshake (§4.2).
- **`Radio_todo`** — the dial, the glass, the Vyto cell trims (§4.8's home once specified).
- **here** — the symptom ledger, the pattern (§2), and anything that is nobody's mechanism because
   it is everybody's.

*This is a `_todo`, not a `_spec`, and should stay one until the human reads and preens it.*
