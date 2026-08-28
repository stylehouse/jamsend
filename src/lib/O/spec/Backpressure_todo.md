# Backpressure_todo.md — making the transfer a req-driven machine with a control loop

The download works and is honest about its bytes. What it does not have is a **closed loop**:
 every knob in it is a constant, most stages share one 600ms beat, and the signals that exist —
  a live rate graph, drop messages, `ws.bufferedAmount` — are either consumed by no code at all
   or read on the path we don't use. This doc is the plan to fix that shape, not to re-tune the
    constants.
*(2026-08-08: "most", not "every" — the two janitors, `Ra_shuffle_cull` and `Stoker_tour`, now fly
 detached off the beat, `Composition_todo` §3.7. `Heist_keep_beat`, the flush and the friend-offer
  loop still share it, which is what the rest of this doc is about.)*

None of this is a new problem. It is flow control and congestion control, a literature forty
 years deep, and each section below names the standard result it is applying — because the failure
  modes here (tail-loss stalls, head-of-line blocking, timeout ambiguity, open-loop pacing) are
   the *canonical* ones, and the cures are known. The work is mapping them onto the C-tree/req
    substrate, not inventing them.

Scope is the transport spine — `Heist` / `Ra` / `Repli` / `Peeroleum` / `Tribunal` / `Swarm`.
 The feature-level Heist story lives in `Heist_todo.md`; the Repli protocol's own shape and its
  2026-08-05 audit is `Repli_design.md`; the 2026-07-29→30 wedge archaeology is
   `Download_stall_handover.md`. None are superseded by this; this is the layer under all three.

---

**Scope note (2026-08-06):** this doc owns the **transfer control loop** — pacing, the clocks, the
 req shape, the defects in §3. The evening of 2026-08-06 produced a pile of failures that are NOT
  that (the boot wait, one-sided reload, Vyto never settling, a starved radio, dropped continuations,
   an `ive_got` storm) and they live in **`Composition_todo.md`**, together with the symptom ledger in
    the human's own words and the one repeated mistake behind most of §3. Read that first if you are
     here because "it all falls apart when everything runs at once"; read this if you are here because
      "the pull is paced wrong".

## 0. Next move (read first)

00. **BUILD `MusuNeGrind` — the composition Book (the human 2026-08-06: "perhaps we need a two-tab
     bulky-binary-Repli situation to see how much of the problematics come with us there").** This is
      the top item and it is not a convenience, it is a **missing test level**. Every defect found on
       2026-08-06 — §3.1b, §3.1c, §3.1d, the landing race, the `ive_got` storm — lived in COMPOSITION,
        and not one of them was reachable by any `Musu*` Book, because each of those runs one mechanism
         in a quiet world. The human's own verdict: *"all these Musu\* tests really didn't prepare us
          too well for the clusterfuck of them all together."* Correct, and structural.

    **Shape** (copy `MusuVend`'s scaffold, `Heistation.g:653` — `Lake_link` loopback, two Piers, no FSA,
     `Musu*` naming convention so `do_fn_for` dispatches by `w.sc.w`):
     - Origin holds a %Library of a FEW records with MANY chunk particles each (enough that pages tile
        and `Ra_pull_beat` runs over many beats — the single-page Books never exercise the pull loop).
     - Follower pulls them while the radio plays and a %Mag replicates: all three at once, which is the
        entire point.
     - Then INJECT the stressors deliberately, each of which is a bug already paid for:
        punch a chunk out of the middle of a page (§3.1b); release a source rec while a want is parked
        on it (§3.1c); let a landing run while the puller is still beating (the landing race).

    **Assert INVARIANTS, not a snap.** The fixture will be nondeterministic exactly like MusuBuddy
     (real clock, real pacing), so the 500-line diff cannot be the gate — `%see` claims are:
     - `held` never DECREASES except while that pick is landing
     - no rec is released while a want is parked on it
     - every asked page eventually lands or is explicitly parked
     - **the beat never overruns 600ms for N consecutive ticks** ← the load-bearing one. Everything
        else degrades *through* the beat, so this single claim would have caught the landing race, the
         park/release livelock, and the `ive_got` storm. `Swarm_share_beat`'s skip counter already
          measures it (`⏳ … skipping this tick (×221 so far)`); nothing asserts on it.

    **A real two-TAB version needs two runners over the relay**, not one runner with two Piers — that
     is the follow-on, and it is what would catch the one-sided-reload wedge (item 3 below). Build the
      one-runner version first: it is deterministic enough to iterate on and needs no human present.

    **BUILD PLAN (2026-08-28, terrain mapped by two exploration passes — anchors inline; the human asked
     for this before a long build session).** The map changed the shape in one way worth stating up front:
      **`make_lossy_partner` already exists** (`Reliable.g:91-125` — per-Pier `drop`/`dup`/`delay:{seq:ticks}`/
       `blackhole`, deterministic, already worn across `Peregrination.g`). So a loopback Book with injected
        latency+loss is **no longer the zero-latency mock** that makes the control loop inert cargo (§5.5/§5.6):
         a seeded `delay:` gives non-zero RTT `s`, a seeded `drop:` exercises the tail probe and the ack-clock's
          re-issue. That splits the work into two rungs that prove DIFFERENT things — build Tier 1, checkpoint,
           then Tier 2 (Tier 3 rides alongside 2).

    **TIER 1 — `MusuNeGrind`, deterministic bench (loopback + lossy wrapper).** NOT the throwaway item 00
     once feared: it is the DETERMINISTIC, fixtured reproducer of both the flood and the control loop.
     Template is `MusuHeist` (`Heistation.g:51-399`) — two Piers sealed by Idzeug over one %Station world,
      pinned clock+seed, `Crate_nav_paths` census, Repli jobs. Copy that scaffold and:
     1. **Inject the wire.** At the `Lake_link` call (`Heistation.g:176`) wrap one direction's port with
         `make_lossy_partner(port, schedule)` (`Reliable.g:91`). A heist's `repli_page` seqs are DYNAMIC, so
          the old explicit-seq schedule (`drop:[s]`/`delay:{seq:N}`) can't name them — so **2026-08-28 added
           PATTERN keys to `make_lossy_partner` (LANDED, additive, PereProof/PereComplain/PereReborn still
            green):** `dropEvery:N` (drop the first transit of every Nth passing frame — retransmit heals) and
             `delayAll:N` (hold every passing frame N ticks — the one that WAKES the estimator/clock). ⚠ The
              open question `delayAll` can't answer on the bench: the RTT sample is wall-clock (`Date.now`), so
               a non-zero SAMPLE needs real time between want-send and the `tick()`-release — a logical hold
                alone may read ~0ms if the drive ticks immediately. So the drive must `w.c.lossy_uno.tick()`
                 each pump pass AND the pump must span real wall time (the live runner's post_do/beat cadence).
                  This is the FIRST thing to settle when the Book is built — it decides whether the loop is
                   actually exercised or still inert. Add `blackhole:[tailseq]` for the §3.1 tail-loss stall.
     2. **Few records, MANY chunks each** (item 00's Shape) so pages tile and `Ra_pull_beat` runs over many
         beats — single-page Books never exercise the pull loop, the window, or the clock.
     3. **Turn the loop ON in-Book:** `w.c.heist_selfclock=1` + a chosen `w.c.heist_window` in setup, so the
         ack-clock actually drives. Tier 1 is where the clock's ACCOUNTING is proven (outstanding holds under
          drops+parks, no double-send, `clocked` climbs) before a nondeterministic relay makes a red hard to pin.
          This is ALSO item 3's deferred gate: the lossy loopback IS the "re-record the chunk-path Books green
           first" gate generalised, so it is what finally lets `heist_selfclock` go default-ON with a green net.
     4. **Reproduce the flood deterministically:** a slow transcode frontier (park a spread of wants) + the OLD
         unbudgeted serve (`w.c.repli_serve_parked_budget` set high) → burst → assert inbox depth spikes; then
          the default budget (32) → assert it does NOT. That before/after IS the fix's HELP made into a fixture —
           the thing item 00 was always for. (The mutex-drain O(depth) amplifier is present in loopback; the
            real-relay-only amplifiers — `ws.bufferedAmount`, the 15s reaper, OS jitter — are Tier 2.)
     5. **Assert INVARIANTS, not the snap:** `held` never decreases except mid-land; no rec released while a
         want is parked on it; every asked page eventually lands or parks; **the beat never overruns 600ms for
          N consecutive ticks** (the load-bearing one — `Swarm_share_beat`'s skip counter already measures it,
           nothing asserts on it). The loss schedule is seeded, so the snap is jitter-free and CAN gate here
            (unlike Tier 2) — but the `%see` invariants are the real gate.

    **TIER 2 — `MusuNeGrindLive`, the REAL relay, two tabs (the human's actual ask).** What EXISTS and works
     live: `Swarm_share_up` (`Swarm.g:2750`), `Swarm_seal` (`:2020`), Idzeug mint/redeem, the grant gate
      `w.c.repli_allow` (`:2764`), `Repli_arm`, `?B=<Book>&I=<tag>` boot (`Otro.svelte:34`),
       `Lies_become_book_drive` (`LiesFunk.svelte:1976`). Swarm.g needs NO change (it is already relay-complete —
        and it is another agent's file this stage). The missing pieces:
     1. **`Relay_link(w, pubA, pubB)`** beside `Lake_link` (`Peregrination.g:202`): instead of pairing two
         in-process ports, return two ports each **relay-bound under a signed hello** — each dials `:9091/relay`,
          the relay binds `prepubOf(pub)→socket`, pull frames route `to:<prepub>`. Repli's handlers are unchanged;
           ONLY the port origin changes. This is the load-bearing new primitive.
     2. **A two-tab coordination wrangle** (runs in BOTH tabs' worlds — two Houses, two `w:` instances, no shared
         %Account tree): each tab mints its %Identity off `?I=<tag>`, seals via an Idzeug redeemed over the relay
          (SwarmStaple `Swarmation.g:33-150` proves the in-memory seal; here it crosses the wire), and ELECTS
           source/sink by **prepub ordering** (lower serves) so no master is needed. Each tab knows the other's
            `?I=` from the Book's own seed and derives its prepub; rendezvous by polling a witness row.
     3. **A two-runner driver:** `runner_ask.mjs` insists on ONE runner (`--runner=<pub>`, no failover —
         `:382-433`). Cheapest parallel drive: a bash wrapper booting two tabs (`&I=alice`/`&I=bob`) and polling
          two backgrounded `runner_ask --runner=` sessions for convergence. A `run-both` op in the mjs is the
           tidier follow-on.
     4. **Assert INVARIANTS only** (real clock, real loss — no snap gate): the Tier-1 `%see` set plus the
         relay-only ones — inbox depth bounded (`🛰☠` never fires under the budget), socket never reaped mid-pull
          (the 15s `relay.ts` heartbeat), goodput converges on wire-rate with the clock on.

    **TIER 3 — controllable-relay shim (rides alongside Tier 2, small).** `Socket_real.wire()` (`Tribunal.g:107`)
     is a bare `ws.send`; add `if (w.c.wire_latency_ms) setTimeout(() => ws.send(…), w.c.wire_latency_ms)` (~3
      lines) + a relay-side `if (Math.random() < w.c.relay_loss_rate) return` drop gate (`relay.ts` routing, ~1
       line). Makes even the REAL relay repeatable so a Tier-2 red reproduces instead of vanishing. Both behind
        knobs unset in production (the `heist_selfclock` stance).

    **COLLISION CHECK before starting:** the other agent has touched `Swarm.g`/`Supervisor.g`/`Swarmation.g`/
     `Siphonation.g`. Tier 2 lands in `Peregrination.g` + `Heistation.g` (+ `Reliable.g`'s existing wrapper) and
      needs NO Swarm.g edit — but confirm `Heistation.g`/`Peregrination.g` are clear, and read `Swarmation.g`'s
       seal wrangle for the Idzeug idiom rather than editing it.

0. **READ §3.1b FIRST (found + fixed 2026-08-06).** Every pull loop tested the *stride-aligned
    chunk* as its stand-in for "is this page missing", so a page that lost ONE chunk to the relay's
     bulk-lane shed read as held and was **never re-asked** — a permanent invisible hole, `landed:0`
      forever. The human's "disconnects a lot! burning CPU!" and the 48s decode were **downstream of
       that single predicate**, not independent problems. Fixed by `Ra_page_hole`. The rule it
        leaves — *the unit of asking is a page, so the unit of needing must be a page* — governs
         anything §5.6 builds on this seam. Do not chase `Ra_source_pcm` on the old evidence.
0c. **AND §3.1e (found + fixed 2026-08-08, live, the same family).** The PCM belt shed what the
     transcode pump had admitted — 8 parked wants vs a 384MB cap = a decode livelock the backoff
      ladder was structurally blind to (it brakes *failed* decodes; these all *succeeded*). The rule
       it adds: **a belt without an admission bound upstream is a livelock generator for any working
        set larger than the cap.** Check §3.1e before adding any new byte budget.
0b. **THEN §3.1c (found + fixed 2026-08-06, same day, from a live report).** §3.1b was not the last
     of its family. The *source* freed a track's bytes while the sink was 17 chunks short, because
      `rec.c.sent >= total` is a **high-water frontier standing in for coverage** — §3.1b's exact
       mistake wearing the other hat — and because `PARK_CEIL` and `RELEASE_IDLE` were both 20000, so
        the quiet a park *instructs* read as the disinterest a release *requires*. Fixed by making a
         standing `%parked_want` veto the release, deriving `RELEASE_IDLE` from `PARK_CEIL`, and
          answering every re-park instead of only the first. The rule: **a park is a contract, not a
           hint** — anything that frees or evicts bytes must ask whether it promised them. §3.1d is the
            small sibling (the overlap slot opened for a *stuck* track, not a *finishing* one).
    **If you are hunting a new stall, grep for the pattern before you grep for the symptom:** a
     high-water cursor (`sent`, `have`, `frontier`, `last_asked`) being asked a question about
      coverage. That single shape has now produced three distinct bugs in two days.
1. **DONE (2026-08-06): §5.1, §5.3, §5.4's narrow cut, and §5.2's attribution half.** Egress
    lanes carry bulk behind control with confessed shedding; a park signals the sink; the
     landing left the beat via `expecting()`; `Ra_pull_beat` samples per-heist goodput into the
      HUD (`rec.c.gp`). Each section carries its own landed-note — read those before re-planning.
2. **DONE (2026-08-06): §5.5.** The arrival seam MEASURES: `Repli_land_rtt` samples the path at the
    moment a page completes, Jacobson/Karels keeps `srtt`/`rttvar`/`rto` on the source Pier, and both
     hardcoded 4s re-asks now read it (with Karn's rule, a per-key backoff ladder, and a tail probe).
      Read §5.5's landed-note before building on it — especially the rule it cost a red to learn:
       **`ra_want_ts` is now an OUTSTANDING marker, so every reader must pair it with a presence
        check.**
3. **BUILT, GATED OFF (2026-08-28): the self-clocking half of §5.6.** The arrival seam now learns to
    DRIVE — a completed page issues the next want (the ack-clock) instead of waiting on the 600ms beat,
     so throughput stops being bound by 6 wants × 2 chunks ÷ 600ms. Landed as `Ra_clock_arm` +
      `Ra_clock_issue` (`Ra.g`), fired from `Repli_land_rtt`'s new `if (w.c.repli_clock)` branch
       (`Repli.g`), all **gated behind `w.c.heist_selfclock` (default OFF)**. The build notes and the
        one deviation from the worked plan are in §5.6's landed-note below. Why gated rather than
         fixture-recorded: §5.6 says this MOVES chunk-path fixtures and wants MusuRaStream/MusuRaChase
          re-recorded green FIRST — but that is a supervised landing, and it was built the day the human
           was leaving the daemon running. So it ships OFF (no `repli_clock` registered ⇒ the fire branch
            is a dead branch ⇒ byte-identical; MusuHeist 22/22 + the MusuReplica Float32 control 14/14
             caveat:0 on the live runner confirm the gate does not leak), and the human flips it on
              against the live daemon to watch goodput converge on wire-rate. **To make it DEFAULT-ON:**
               re-record MusuRaStream/MusuRaChase green, wire `rec.c.ask_next` into `Swarm_note_era`'s
                rebirth wipe (the one rough edge, noted in `Ra_clock_issue` — Swarm.g was another agent's
                 file this stage), then the AIMD half (item 4) turns the fixed `W` into `rec.c.win`.
4. **Then §5.6's AIMD half** (the window becomes a variable the loop moves — one variable,
    by construction of the clock stage) and the fuller req shape of §4 only if the beat still
     misbehaves once the clock runs.
4. **Then §5.6's AIMD half** (the window becomes a variable the loop moves — one variable,
    by construction of the clock stage) and the fuller req shape of §4 only if the beat still
     misbehaves once the clock runs.
5. **§7 is ruled on, not open.** The five design questions were decided by the human on the
    evening of 2026-08-05 — build on them rather than re-opening them. Two carry weight beyond
     this doc: the retransmit timer is **an ambient tick, never a ttlilt** (§7.1), and **`req` is
      a better home for state than a string on a particle** (§7.5).

**FIELD NOTE (2026-08-26): the flood showed up in the wild, off the test bench.** A live
 humdinger daemon serving a real pull logged `🛰☠ inbox backstop: pier editor holds 2050 unemits`
  — the sink's serial `%req:unemit` drain (`inbox.do()`, under the beliefs mutex) fell behind an
   ungated source `conn.send`, hit the 2000 cap, and shed oldest → drop→re-ask churn. Not a new
    defect: it is §2's convoy and §3.3's head-of-line starvation observed under REAL Book-drive
     mutex load instead of a quiet `Musu*` world — the first datapoint that the open loop bites
      *outside the bench*. It reinforces items 3/4 (the ack-clock + AIMD are what close it) and
       item 00 (only the composition Book would reproduce it deterministically). The ack today is
        retransmit-only — nothing tells the source the sink is drowning, so there is nothing to
         *decrease* on; the missing §5.3 park-back is upstream of §5.6's window. **Build stance to
          carry into item 4:** make the loop's own state (window, in-flight, queue-depth, `srtt`)
           **legible matter — C particles under the Pier, not closure locals** — so the loop is
            ordinary C ops, Story can `%see` it, and Vyto can render the convoy instead of us
             grepping `☠`. One representation serves the loop and the view; it dogfoods the one bet.

**ROOT-CAUSE UPDATE (2026-08-28, static trace of the serve/ask paths).** Traced every ask/serve path
 against the 2050 depth. The ASK side is already bounded everywhere: `Ra_pull_beat` holds at most
  `INFLIGHT`(2) × `LEAD`(32) outstanding, and `Ra_restock_beat`'s mirror/preview walk carries an
   *aggregate* `want < B` budget across records. A flood 2050 deep cannot come from either — so it comes
    from the **source**. The one un-budgeted path is **`Repli_serve_parked`** (`Repli.g`): on a transcode-
     frontier advance it re-served EVERY ready parked want in a single synchronous pass. A source that
      accumulated a large parked backlog (the sink re-asking for minutes while the transcoder ran behind —
       §3.1c/§3.1e territory) therefore DUMPS the whole backlog as one un-paced `repli_page` burst the
        instant the frontier moves, and the sink's serial inbox (sha256 + mint per frame, one mutex) sheds
         it at 2000. The `tx 0p/0KB` on the flooded tab fits: the sink is not asking *during* the burst —
          it is drowning in a push its own re-asks provoked minutes earlier. **First cut LANDED (2026-08-28,
           unverified against a live flood):** a per-advance serve budget (`w.c.repli_serve_parked_budget`,
            default 32) so a backlog *dribbles* instead of dumps; the remainder stay parked and self-heal via
             the RTO re-ask. Book-invisible by threshold (no Book parks near 32), so no fixture moves —
              **provably harmless, but its HELP is unverifiable** until item 00's `MusuNeGrind` reproduces the
               burst (or the daemon re-floods). Caveat not ruled out without the live shelf: the opus
                live-stream (`Swarm.g:3428`) is a second possible contributor. This does NOT retire items 3/4
                 — a budget *paces* the burst; only the ack-clock/window *bounds the steady state*, and only a
                  receive-side signal (§5.3-style, keyed on inbox depth) lets the source stop before it floods.

**THE FLOOD IS RE-ASK DUPLICATION, NOT WIDTH (2026-08-28, live re-flood, both ends observed).** The human
 left the daemon serving a real pull and pasted both ends. The decisive numbers: the ask window is ≤32 pages
  outstanding, yet the sink's inbox hit **2050** — ~64× the window. A bounded window cannot produce 64× its
   own size of *distinct* pages, so the 2050 is **the same ~32 pages asked and served over and over**. The
    mechanism, one sentence: *a page only counts as LANDED once the inbox DRAIN mints it (sha256 + chunk
     particle), that drain is O(inbox-depth) per frame (below) so it falls behind the MEASURED (short) RTO,
      an undrained page still reads as a hole (`Ra_page_hole` sees the minted chunk map, not the inbox), so
       the sink re-asks a page already sitting in its own inbox, the source re-serves it, the inbox deepens,
        the drain slows, more re-asks fire — a congestion collapse inside a bounded window.* It is §3.2's sin
         (a timeout standing in for three different truths) on the RECEIVE side: *undrained-in-my-inbox* is
          collapsed into *lost-on-the-wire*.
 **Why cursors/the budget don't catch it:** the window bounds how far AHEAD you ask; this is duplication
  WITHIN the window. Worse, the window's own accounting HIDES it — "outstanding" = a `ra_want_ts` stamp,
   cleared only on MINT, so an arrived-but-undrained page still counts as outstanding → the ack-clock
    correctly stays silent while the beat's RTO re-asks the very same page. The clock behaves perfectly and
     the flood happens in the gap between the two. The missing thing is a STATE, not a cursor: the sink has
      *landed* and *not-landed* but no *arrived-but-not-yet-drained*.
 **FIX LANDED (2026-08-28), gated + Book-invisible — sink-side self-applied backpressure.** Rather than track
  per-page "arrived" (the page's `(id,offset)` identity is *inside* the undrained frame — only known once the
   lines decode in the drain, so per-page tracking is expensive), use the one O(1) fact the sink already has:
    **its own inbox depth.** `Peeroleum_bound_inbox` stashes `pier.c.inbox_depth`(+`_ts`) for free (it already
     holds `live`); `Ra_pull_beat` reads `rec.c.rx.c.inbox_depth` and, when it exceeds `w.c.heist_drainbound_ceiling`
      (default 800, well under the 2000 shed), SUPPRESSES re-asks (and the tail probe) — a "missing" page is
       then far likelier undrained-in-inbox than lost. FIRST-asks of new ground still go (bounded by B/LEAD),
        so forward progress never stalls; only the wasteful re-buy of an in-flight page is held. `_ts`-guarded
         (a stale-high depth from a flood that ended in a quiet spell is ignored, not a permanent wedge).
          Book-invisible by construction (a loopback inbox drains in-tick → depth ~0 → never fires): MusuHeist
           22/22 + MusuReplica 14/14 caveat:0 on the live runner confirm it. HUD: `entry.drainbound` shows when
            re-asks are being held. **Unverified against the live flood** (same caveat as the budget) — the
             daemon that flooded was up 2.7h on PRE-budget/pre-this code, so NONE of the 2026-08-28 fixes were
              in that loop; a restart is needed to test any of them.
 **THE DEEPER AMPLIFIER — the O(depth)-per-frame drain (scoped 2026-08-28; NOT landed, needs human eyes).**
  The drainbound gate stops the *duplication*; the reason depth builds at all is that the drain is O(depth)
   per frame, so it loses the race to the RTO. Ranked hot-path costs (see §5.8):
   - **`Peeroleum_book_unemit`'s dedup query** (`Peeroleum.g:~721`/`:779`): `inbox.oai({req,seq,type,body_hash,
      body_len})` runs on EVERY frame; `o_query` keys on `req` (O(1) → the whole unemit bucket) then filters
       seq/type/hash/len (O(depth)). This is the UNCONDITIONAL per-frame O(depth) — the base amplifier in the
        current (error-free) flood.
   - **`Peeroleum_rollup_faulty`** (`Peeroleum.g:~1131`): `inbox.o({req:'unemit'}).filter(u=>u.sc.error)` runs
      per deliver and — the sharp edge — its early-return is `!faulty_owed && !faulty0`, so ONCE a `%faulty`
       node exists (any error ever, e.g. a startup-hold), it re-scans O(depth) on EVERY later frame. This is
        the catastrophic amplifier of the *errored* flood family (the giant-stuff / startup-hold thread).
   - The bound's own scans are amortised (50-frame stride) — minor.
   Three fixes were scoped, all deferred for review because they touch the transport dedup/cache path (or the
    generic C layer): (A) an O(1) per-pier `booked[seqkey]→ureq` map for the dedup, with invalidation on
     drop/reset — Peeroleum-only, ~15 lines, the invalidation is the risk; (B) a multi-level X index so a
      composite-key query is O(result) not O(depth) — `Stuff.svelte.ts`, ~50 lines, fixes the pattern
       everywhere but higher blast radius; (C) fix the rollup early-return so a stable `%faulty` isn't
        re-scanned per frame — ~5 lines, Peeroleum-only. Recommend (C)+(A) together; (B) is the structural
         option. **Landing any of these needs a human — they are the belief-loop's ingress hot path.**

**SCOPE FLAG for the human — §7.4 may want reopening (flagged, NOT acted on).** `Portability_doc`
 §0 now bets pool↔pool phone-to-phone transfer is the MAJORITY path ("design the pool paths as
  primary, not a nicety bolted on"). That pressures §7.4's ruling that per-peer trunk fairness is
   OUT — the ruling rests on "every transfer crosses the relay one connection at a time / a single
    pair saturating is not observed," which the star topology guaranteed and a pool-primary world
     inverts. If pools are primary, many concurrent peers IS the product and §5.9/§7.4 stop being
      post-v1.0. This stays a flag: §7 was the human's ruling and holds until the human re-rules.
       When it is picked up, coordinate the diff with `Portability_doc` §5 — same Repli/Peeroleum
        file, orthogonal axis (identity/merge there, congestion here); sequence AFTER `RepliShadow`
         so the window builds on the shadow-shape, not the doomed `Repli_identity_keys` loc-table.

**Scope: v1.0 in ~38h from 2026-08-05 evening.** That is the frame for every "in scope?" call
 here. §5.1 → §5.3 → §5.4 is the spine; §5.6/§5.7 are refinements that can miss the date;
  §5.9 (era-scoped seqs) is post-v1.0 by design; per-peer trunk fairness is explicitly out
   (§7.4). Do not pre-build for anything ruled out.

**The arc:** one serial polling beat → three concurrent pumps under one host, with a measured
 control loop, explicit signals where today there are only timeouts, and a wire that never
  starves control frames behind bulk.

*(Facts below re-verified against the working tree the evening of 2026-08-05, after the `%Keep`→
 `%Heist` rename and the day's Repli/Peeroleum landings. §6 records what landed; the defects in §3
  all still stand. §9 is the fresh-reader trap list.)*

---

## 1. What is actually there now (measured 2026-08-05, re-verified same evening)

| knob | value | where |
|---|---|---|
| share beat cadence | **600ms** | `Swarm.g:1611` `Swarm_share_loop`, `setTimeout(tick, 600)` |
| wants issued per beat per record | **6** | `Ra.g` `heist_want_budget` |
| chunks per want (a "page") | **2** | `repli_page`, `Repli_serve_want` `end = min(from+PAGE, …)` |
| chunk size | **256KB** | `Heist.g:32` `return 262144` |
| ask window (`LEAD`) | **32 missing pages** ≈ 16MB | `Ra.g` `heist_want_lead` |
| re-ask timer | **fixed 4s** per (id, offset) | `Ra.g` `ra_want_ts` |
| tracks in flight | **2**, 2nd opens within 24 chunks of done | `heist_inflight` / `heist_overlap` |
| breach cooldown | 5s | `heist_breach_cooldown` |
| relay heartbeat reaper | **15s** miss → terminate | `src/lib/server/relay.ts:543` `HEARTBEAT_MS` |

### 1.1 The issue-rate ceiling — Little's law says the window is innocent

```
6 wants/beat × 2 chunks × 256KB ÷ 0.6s  =  5 MB/s   per record
```

Hard ceiling regardless of path capacity. Two records in flight → 10MB/s aggregate.

Put it in the standard terms: steady-state throughput is bounded by **min(issue rate,
 window ÷ RTT)** — Little's law, with the window as the queue and the RTT as the residence
  time. The window is 16MB outstanding; on local-local the RTT is single-digit milliseconds, so
   `window ÷ RTT` is measured in **GB/s**. The issue rate is 5MB/s. The window term is three
    orders of magnitude away from binding — **the pacing is the throttle, full stop.** A 65MB
     flac is ~13s of pure ask-pacing before anything else goes wrong.

This matters for the review: **the first instinct — "open the window" — is wrong.** The window
 is already wide. The rate at which we may *issue* into it is what binds, and it binds because it
  is a constant with no feedback term (§5.6).

---

## 2. The three clocks, and the convoy they form

One download crosses three scheduling disciplines that do not know about each other:

| stage | discipline | clock |
|---|---|---|
| Peeroleum inbox | serial `%req:unemit` drain (`inbox.do()`) | frame arrival |
| Heist | `%Heist` `state` string, polled | the 600ms beat |
| Repli park/unpark | event-driven demand (`%parked_want`) | producer frontier |

They all funnel onto one thread and mostly onto that one beat. **The beat is a barrier, not a
 scheduler.** `share_beat_running` skips a tick while the previous beat is in flight, so the
  system's effective clock rate is `max(600ms, slowest thing that ran)`. This is the textbook
   **convoy effect** — non-preemptive batch service, where one long job doesn't degrade itself,
    it holds every short job behind it. `Swarm.g` already knows and says so in its own comment:
     *"a long landing steals the very window the OVERLAP pre-ask needed."* Since 2026-08-05 the
      convoy is at least *visible*: an `ev:'beat'` electrode (`Swarm.g:1607`) traces any beat
       over 600ms with its `ms` and the `skips` it caused.

The Peeroleum leg deserves its own sentence, because it is the stack's ingress queue: every
 booked frame — and a 256KB `repli_page` is a booked frame; only `repli_want` bypasses — mints a
  `%req:unemit` into the Pier's inbox and drains through one serial `do()`. That queue is now
   *bounded* with a ledger for the reused-seq guard (`Peeroleum_bound_inbox` /
    `Peeroleum_inbox_ledger`, §6 — bounded queues + load shedding, the standard cure for
     unbounded-producer pathologies), but the drain itself is still main-thread work per frame:
      sha256 verify + particle mint inside the tick (§7.3, §9.3).

**Surprise worth flagging: `Heist.g` contains no reqs at all.** Counting `req:` occurrences
 across the transport ghosts (2026-08-05 evening): `Peeroleum` 31, `Tyrant` 25, `Repli` 8,
  `Radiola` 8 — and `Heist` **0**. The heist is a hand-rolled beat with a state string, entirely
   outside the req machine, while every neighbour it talks to is inside it.

---

## 3. The defects this shape produces

### 3.1 The tail stall ("still a bit stally at the end")

Two things compound at the end of a track, both structural:

- **The window is empty by construction at the tail, so recovery degenerates to stop-and-wait.**
   Mid-track a lost page is invisible — 30 other pages are in flight and bytes keep landing while
    the hole waits out its 4s. At the tail there is nothing ahead to ask for, only holes behind:
     the remaining time is *pure* timeout, each surviving hole costing a full 4s, serially, with
      the wire idle. This is the classic **tail-loss problem**: TCP needed two separate mechanisms
       — fast retransmit off dup-acks (Jacobson), then Tail Loss Probe — precisely because a
        retransmission timer alone is this bad at the tail. We have neither, and our RTO is a
         constant (§5.5).
- **The landing is a stop-the-world barrier fired at exactly that moment.** `Heist.g:1688`
   `await this.Heist_land(...)` is inline on the beat. The instant a track completes, the beat
    blocks for the whole write + read-back + sha256, and every 600ms tick is skipped meanwhile.
     During that window the *other* in-flight track issues zero wants, the re-ask timer does not
      run, the parked-want pump does not run, the census ask does not go out. `heist_overlap`=24
       exists to hide the handoff gap, but the landing barrier is far larger than the overlap can
        cover.

So the tail is where loss recovery is at its worst *and* where we schedule the longest blocking
 operation. The crswap fix (§6) shrank the second one ~28× — the `land` electrode's own numbers:
  `wr:31080ms` of a `ms:31777` landing against `wire:397ms` of actual transfer, now ~19ms/chunk —
   which is why "stalls" became "a bit stally". The barrier is smaller; it is still a barrier.

### 3.1b The re-ask was blind to intra-page holes — shedding was silently permanent loss
 *(FOUND + FIXED 2026-08-06; this is the one that actually caused "disconnects a lot! burning CPU!")*

Every pull loop in the tree tested **`map[off] == null`** — the stride-aligned chunk *alone* — as its
 stand-in for "is this page still missing". That silently assumes a page lands **all-or-nothing**.
  It does not: `Repli_serve_chunks` lifts EACH chunk into its own buffer, so each rides its own
   `repli_page` frame, and three separate mechanisms drop them **one at a time** —

- the relay's **bulk-lane shed** (`Tribunal.g:156`), whose own comment promised *"the sink re-asks,
   so this is congestion not loss"*;
- a **cid breach** refusing one chunk's bytes (`Repli_attach_page`);
- the **page-stash cap** orphaning a page whose lines were lost.

Any of them can take seq `off+1` while `off` survives. The loop then reads the page as held and
 **never asks again**. `done` is `held >= total`, so the track can never complete — a permanent,
  invisible hole. This is not a slow path; it is an unreachable one.

**The evidence** (`wormhole/_trace/runner-f5da6599b8505881-1785939454928.jsonl`): `landed:0` on
 **every** `pulls` row for the entire session, with tracks frozen at `252/255`, `104/109`, `104/119`
  — climbing normally, then stopping a few chunks short and sitting there through bench, re-ask and
   reheal, forever.

**Why it read as a network/CPU problem** — the cascade is worth keeping, because every step of it
 points somewhere other than the cause:
  nothing lands ⇒ nothing releases ⇒ ~8 tracks of chunk particles accumulate ⇒ the beat degrades
   (`beat ms=1319 skips=7→8→9`) ⇒ the event loop stalls ⇒ a whole-file read that costs **88ms** and
    **226ms** on healthy tracks takes **42418ms** ⇒ mark gaps reach 21–23s ⇒ past the relay's **15s**
     reaper ⇒ socket cut ⇒ reconnect ⇒ in-flight ephemeral pages lost ⇒ *more* tail holes. The
      disconnects, the CPU burn, and the 48s "decode" were all **downstream of this one predicate**.
       `Ra_source_pcm` is a victim here, not a culprit — do not go windowing it on this evidence.

**The fix**: `Ra_page_hole(map, off, PAGE, total)` — is ANY seq of `[off, off+PAGE)` missing? — at
 all five sites (`Ra_pull_beat`'s ask loop and its tail probe, `Ra_stage`'s classifier,
  `Ra_restock_beat`'s preview loop, `Swarm_share_beat`'s live window). Re-asking a partly-held page
   re-delivers chunks already in hand; that is deliberate and safe — the stride is FIXED by
    `Repli_page_ready`'s contract, so a hole *cannot* be asked for on its own, and a re-landed chunk
     is idempotent (same bytes, same cid).

**The standing rule this leaves:** *the unit of asking is a PAGE, so the unit of "do I still need
 this" must be a page too.* Any future loop that tests one chunk's presence to decide a page's fate
  re-opens this. And **shedding is only sound while the re-ask is page-wide** — `Tribunal.g` now
   says so at the point where it sheds, because that lane's correctness depends on it.

*Attribution note:* `MusuRaChase` is red 56/56 both with and without this change, with **byte-identical
 step diges** either way — verified by a controlled revert-compile-run on the same runner. Its red is
  pre-existing (un-accepted fixtures), not this. The general reason no Book moves: `Ra_page_hole` and
   `map[off]==null` differ *only* when a page has a hole with its first chunk present, which local
    Book transfers never produce.

### 3.1c The source freed the bytes it had just promised to serve — the park/release collision
 *(FOUND + FIXED 2026-08-06, the live report: "120/137 downloaded side, disappeared from the uploaded
  side, but hasn't started turning up on disk yet! not even as a chrswap")*

Read that report literally and it names its own cause. **"Disappeared from the uploaded side" IS
 `Heist_release_rec`** — that function ends with `delete xf.serves[id8]`, so the row vanishing from the
  transfer HUD is the source freeing the record's `%Body` bytes. It freed a track the sink was still
   seventeen chunks short of. And nothing reached disk because landing is gated on `held >= total`, so
    a pull that can never complete never writes — not even a `.crswap`.

**Three faults compose into a livelock**, and each is individually defensible:

1. **`rec.c.sent >= tot` is a high-water frontier, not coverage.** `Repli_serve_chunks` only ever
    raises it (`if (end > sent) sent = end`), so it means *"the last page I shipped touched the end"*,
     never *"every page has crossed at least once"* as the release sweep's comment claimed. This is
      **§3.1b's mistake wearing the other hat** — there, a frontier stood in for coverage on the
       *asking* side; here it does on the *freeing* side. One shed page out of the middle and the
        frontier still reads `total`.

2. **`PARK_CEIL` and `RELEASE_IDLE` were both 20000.** That is not a chosen relationship, it is a
    collision. A park *instructs* the sink to go quiet for up to `PARK_CEIL` (§5.3 — "not lost, stop
     spending"), and the release sweep reads that same enforced quiet as *"nobody wants these bytes"*.
      **The source frees exactly what it promised, at roughly the moment the sink is allowed to ask
       again.**

3. **A re-park answered with total silence.** `Repli_park_want`'s `!p.c.counted` latch was right to
    make the counter and the trace one-shot — that is the flood it exists to prevent — but the
     `repli_parked` *reply* sat inside it too. So the second and every later ask for the same offset
      got nothing back at all. The sink's suspension is bounded, so it expires, the sink re-asks, and
       hears silence — **indistinguishable from a dead source**, and it burns the backoff ladder to
        ×8 against a source that is working perfectly and merely slow.

The cycle: release → sink re-asks → park (silent) → A3 re-materialises the file (**a 25MB disk read,
 re-chunk and re-hash, every 5s**) → serves a page → 20s quiet → release again. That is the CPU burn,
  and it is *caused* by the release rather than relieved by it: keeping the bytes would have made every
   retry a memory hit.

**The fix** — an outstanding promise outranks a memory policy:
- `Heist_parked_ids(w)` (built **once per sweep**, never per rec) — any rec with a standing
   `%parked_want` on a caster Pier **vetoes** its own release.
- `RELEASE_IDLE` is now *derived* (`PARK_CEIL * 2 + 5000`), not restated, so the two constants cannot
   drift back into agreement. A sink is owed its whole suspension plus a round trip to re-ask in.
- The byte-cap belt sorts **promised last**. It must still be able to shed everything — it is what makes
   the 3GB cliff structurally unreachable, so it can never be vetoed outright — but it gets to choose.
- `Repli_park_want` answers **every** re-ask (throttled 2s, well under `PARK_CEIL`), so a suspension is
   always refreshed before it lapses. Counter and trace stay one-shot.

**The standing rule:** *a park is a contract, not a hint.* Anything that frees, evicts or expires bytes
 must ask whether it has promised them first. The mirror of §3.1b's rule, and it generalises the same
  way — **do not let a high-water mark answer a question about coverage.**

*Also fixed in passing:* the HUD's serve row was only written on a **frontier advance**, so a source
 doing nothing but retransmits — precisely the state worth watching — left its `ts` frozen and sank out
  of the four-most-recent list. The uploader looked idle while it was working hardest. Re-serves now
   write the row with a `↻n` retransmit count, so *repair* and *progress* are visibly different things.

### 3.1d The overlap slot opened for a track that was stuck, not finishing
 *(FIXED 2026-08-06, the live report: "downloads overlap a bit much now")*

The in-flight window (`INFLIGHT` 2) opens a second slot once the active track is within `OVERLAP` (24)
 chunks of done, to pre-ask the next one and beat the handoff latency. But *near done* was the whole
  test. A track **wedged** near the end — the 120/137 shape above — satisfies it permanently, so it
   propped the window open for as long as it stayed stuck, and the source was asked to materialise a
    second 25MB track while it still owed bytes on the first. Two half-finished bars, twice the source
     memory, neither finishing sooner. The slot now also requires the track to be **moving** (an advance
      within 3s); *stalled* is the bench watchdog's job (45s → 60s off), not the overlap slot's. The
       `pulls` electrode gained a `why:'frozen'` cause so the two are distinguishable in the ring.

### 3.1e The PCM belt shed what admission had promised — the cap-thrash livelock
 *(FOUND + FIXED 2026-08-08, live: "failing to heist… big dysfunctional gaps between doing anything")*

The sink saw `heist-noprogress` for 60–100s per track, then a 1–8s burst — the wire was fast, the
 source just wasn't answering. The source's ring told the whole story in one window (136s): **28
  `pcm-decode-start` of the same 8 records, 15 `pcm-free why=cap`, 28 `park-stall` barks, and TWO
   heist serves.** `Ra_transcode_pump` ensured a transcode for *every* distinct parked-want id — no
    admission bound — so 8 wants stood up ~700MB of whole-file PCM against `Ra_pcm_sweep`'s 384MB
     belt. The belt shed open encodes oldest-first; the next pump pass found `rec.c.pcm` null and
      re-kicked at full price (7–23s of decode each). And the 2026-08-07 backoff ladder never braked
       it, **because the ladder arms on FAILED decodes and every one of these SUCCEEDED** — success
        clears `pcm_tries`, so eviction manufactured an endless stream of successful decodes the only
         existing brake was blind to. The tab spent whole minutes re-decoding audio it had just thrown
          away; the serve got the scraps.

This is §3.1c's rule wearing the PCM hat — **eviction may not break admission's promise** — plus the
 eviction-fairness lesson: no re-tuning of the sweep can fix it, because demand exceeded the cap
  *by construction*. Fixed with an admission gate in `Ra_transcode_pump`: a NEW whole-file decode is
   only kicked while counted PCM stays under CAP/2 (an un-landed kick charged CAP/4 — the sweep's own
    "~4 tracks" arithmetic; both derived from CAP, never twin constants). Deferred ids simply **stay
     parked** — that is what a park is for — and admit as open transcodes finish and free at done.
      A rec already holding pcm or an open `ra` passes freely, so nothing in flight starves. Verified
       live: `capfree=0` in every ring sampled, decode-starts fell to zero, serves climbed 1→16, and
        the stalled album landed completely within minutes of the HMR. The general rule for §5.6 and
         anything else that adds a byte budget: **an eviction bound (a belt) and an admission bound
          are two different organs, and a belt without admission upstream of it is a livelock
           generator for any working set larger than the cap.**

**The residual, measured the same evening:** the CAP/2 budget is conservative enough that ONE long
 track streaming (394s ≈ 150MB of PCM) nearly fills it, so a new stream want queued ~145s at `off=16`
  before admission (still 3–10× better than the 480–1438s the thrash produced, but user-visible as a
   slow stream start). Two candidate cures were named: (a) charge the REAL estimate instead of CAP/4
    and admit against CAP instead of CAP/2, accepting a rare belt-shed when an estimate lies; or
     (b) mirror §3.1c properly — a standing `%parked_want` VETOES the belt for that rec (the sweep's
      "a belt that can be vetoed is not a belt" then needs a second, harder bound behind it).

**Cure (a) has since landed, at a SECOND site — `Ra_pcm_admit` (2026-08-08, `Ra.g`).** The pump's
 CAP/2 census above still stands and still gates which parked ids get a transcode ensured; `Ra_pcm_admit`
  sits one layer lower, at the decode kick inside `Ra_transcode_ensure`, and answers the finer question
   *"may this record start a whole-file decode right now?"*:
- charges a real per-record estimate, `Ra_pcm_est` = `secs × 48000 × nch × 4` (an unknown duration
   assumes a big one on purpose — over-estimating costs a wait, under-estimating is the livelock);
- counts bytes already **held** *and* bytes already **in flight** (`pcm_pending` records have not called
   `Ra_pcm_hold` yet, so a hold-only census would admit the whole thundering herd in one beat);
- admits against the **full CAP**, with a **playing-record override** (`Ra_pcm_playing`, bounded by
   there being one playhead) so a listener is never starved by speculative demand;
- refusal is **not failure** — no backoff is climbed, the want stays parked, and one `pcm-wait` trace
   per 5s per record keeps a merely-waiting queue distinguishable from a stuck one.

⚠ **One part of it is reasoning, not measurement.** The **lone-candidate floor** — admit regardless of
 size when nothing is held and nothing is in flight — exists because `want` alone passes 384MB somewhere
  past ~17.5 minutes at 48kHz stereo Float32, so a DJ set or a podcast would otherwise be refused
   *forever* with no backoff to let it through. Its own comment says it was *"found by an adversarial
    read, NOT by a run — nobody has yet watched a 20-minute track play."* The arithmetic is checkable;
     the behaviour is not yet observed. Cure (b) was not built and is not needed unless this proves thin.

### 3.2 The sink is blind to why a want went unanswered — a timeout is the weakest signal

`Repli_park_want` (`Repli.g:476`) mints a source-local `%parked_want` and **replies nothing**.
 `Repli_serve_miss` is a throttled console line on the *source's* tab. So the sink cannot
  distinguish:

| truth | right response | wire analogue |
|---|---|---|
| want lost on the wire | retransmit **now** | loss (dup-ack / NAK) |
| source parked it behind its transcode frontier | **wait**, stop spending budget | ECN — "not lost, back off" |
| source has no record for that id | give up, **re-census** | unreachable — repair the route |

Three states wanting opposite responses, collapsed into one 4s timer. **Implicit inference from
 timeout is the slowest, most ambiguous signal available; an explicit one-bit message beats it
  every time** — that is the whole argument for ECN over loss-inference, applied here. The
   observed `◈⚠ transcode STALLED — parked want id=794aa24e… waiting 20s…118s` is the source
    *knowing* the answer for two minutes while the sink re-asked ~30 times. Not a tuning gap — a
     missing message.

Two of the three rows moved on 2026-08-05, neither on the wire yet:

- The park is now *counted and addressed*: `w.c.repli_parked` feeds the witnesses, and the
   `%parked_want` stashes `p.c.reply_to` / `p.c.reply_from` (`Repli.g:481`) — which is exactly
    the addressing a `repli_parked` reply needs. §5.3 is now little more than a frame send plus a
     sink-side handler.
- The third row got a coarse heal at the Heist level: after 3 unanswered asks the sink re-sends
   the DESCRIBE (`Heist.g:1649`, throttled 20s), which re-registers the source's rummage lib
    after a source-side reload wiped its `.c`-only memo. A repair, not a signal — the sink still
     spent three timeouts learning what one frame could have said.

### 3.3 No send-side backpressure, and it costs the connection

`Tribunal.g:97` sends bare:

```
let wire = (frame) => { if (frame && frame.buffer) ws.send(encode_binary(frame)) else ws.send(JSON.stringify(frame)) }
```

`ping`/`pong`, acks, `repli_want`, census/describe replies and 256KB `repli_page` frames all
 share one socket with no gating — **head-of-line blocking with priority inversion**: a 10-byte
  pong queued behind bulk pages inherits their serialization delay, and on a slow or stalled
   socket that delay is unbounded because nothing reads `bufferedAmount` before writing. The
    reaper then converts starvation into death: `relay.ts:543` terminates any socket that missed
     a pong inside 15s. **The missing backpressure does not merely waste memory — it kills the
      connection**, which is the observed `code=1006` → Piers gone → `no Pier … DROPPED` flood →
       desync. `bufferedAmount` *is* read, but only for the WebRTC datachannel
        (`Peerily.svelte.ts:602,609`) — the relay path, which is what local-local uses, reads
         nothing.

This is also a live suspect for the "looking through the album" census stall: the describe reply
 is a small frame queued behind 256KB pages, and if the socket is reaped mid-flight it is gone.

The cure is the oldest one in networking — **class-based priority queueing** (§5.1). Control
 frames ride an express lane that never waits behind bulk; bulk defers to the one congestion
  signal the browser offers.

---

### 3.4 Open-loop pacing on the LIVE window — closed 2026-08-08 (the owner's ladder), UNHEARD

The intro names **open-loop pacing** as one of the canonical failure modes this doc exists to close.
Here is where it lived, in the "keep the wire ahead of the playhead" leg of `Swarm_share_beat`:

| knob | was | now |
|---|---|---|
| asks per beat | **flat 3** | 6 / 3 / 1 by banked lead (<8s / <16s / ≥16s) |
| re-ask a missing live-window page | **flat 4000ms** | 1500ms when under 8s banked, else 4000ms |
| a record becomes PLAYABLE at | **chunk 0 — two seconds** | 8s banked (`Radio_playable`, seconds not chunks, clamped to `total`) |

**The design is the owner's, 2026-08-08**, and worth quoting because it names the principle better than
the code does: *"the main cause is not prioritising the Records enough… prioritise the current track
over the potential next track, unless we're >16s ahead."* The old shape had no notion of priority at
all — **a track with thirty seconds banked spent exactly the same wire as one about to go silent.**

`lead` is the count of **contiguous** chunks from the head. Contiguous matters: audio past a hole is
not lead, it is audio after the gap, and counting it would report a comfortable buffer at the exact
moment the playhead is about to hit silence.

**One correction to the model, recorded so it is not re-derived.** The ">16s ahead" rung was conceived
as yielding to the *next track's* prefetch. It does not: `Radio_prime` never asks over the wire, it only
decodes chunks already held (`Radio.g:557` — `if (m.bytes[start] == null) return`). What the top rung
actually yields to is `Heist_keep_beat` and the friend-offer loop sharing the same serial beat. Still
worth having, for a different reason than intended — and see `Composition_todo` §3.6, which argued the
same convoy from the other end. ⚠ **§3.6's named mechanism was REFUTED by measurement the same day**
(the beat was held by the cull, not by `keep`); it is kept there deliberately as a worked example. Its
*instinct* was later half-vindicated by §3.12 — a heist really does destroy the radio's supply, through
the PCM belt rather than through the beat. Cite §3.7 and §3.12, never §3.6.

**Status: compiled, gated, and HEARD BY NOBODY.** The 8s gate is `humdinger`-gated (it moves when a
track becomes eligible, and every Book timing moves with it — the trap that turned MusuHeist red when
`Radio_prime` first ran ungated); the budget/re-ask changes are in the share beat, which is live-only by
construction. So no Book can regress and no Book can confirm it either. **This is a tuning change to the
audio path validated only by reading.** Treat the next real listen as the test.

**The instrument, when a gap does happen:** `w.c.lead_s` (off-snap) beside the `cull=/tour=/peers=/keep=`
split now in the skip line. Low `lead_s` with beats running ⇒ starved of ASKS, and the ladder is wrong
or too shy. `keep=` dominating ⇒ starved of BEATS — the ladder cannot help, because a budget of 6
spends nothing if the beat never runs.
 **Read the split as a progress bar, not a cost table** (`Composition_todo` §0): it is zeroed at the top
  of each beat and each field stamped only on completion, so the last non-zero field is how FAR the
   stuck beat got. And since 2026-08-08 `cull=`/`tour=` measure only the cost of *kicking* a detached
    janitor (≈0) — the real durations arrive as `cull_bg=`/`tour_bg=` in the same line.

## 4. The refactor: `%Heist` grows a req pile

### 4.1 The idioms we are copying

**`LiesStore` — the exemplar for a pump that IS a req** (`LiesStore.svelte` header):
- `req:Store, maz:7, eternal` sits on `w` and pumps itself each tick. *"nothing outside calls a
   pump, `req:Store`'s do_fn IS the pump."*
- `sc.ok` is a **pass-local** gate: Store sets it at the end of its cycle, `do()` treats it like
   finished for maz gating so a lower-maz dependent proceeds **in the same pass**; `do_one` clears
    it at entry next tick.
- Children are **stable reqs keyed by identity** — `req:LiesStore_write,path,dige`,
   `req:LiesStore_read,rw_name` — one per real thing, not one per attempt.
- Two settle disciplines: **finish-and-sweep** (transient, dropped once served) vs
   **keep-as-accessor** (the `%Good`/`known` ledger carrying `dige`+`kind`+`at`).
- **Producer and consumer never share a req.** The consumer arms a hold on its *own* req and
   waits, rather than reaching across into Store.

**`Radiola` — the exemplar for one host pumping several work-leaves**: `%Stock` carries both
 `%req:restock` (producer refill) and `%req:reap` (wear sweep) — *"The 'two jobs' need no special
  handling: do() runs every child."* And the law at `Radiola.g:277`: the player **consults** the
   ledger, **never piles reqs under it**.

That second one is the whole refactor in a sentence: **make ask and land siblings under one host
 so `do()` drives both, instead of sequential statements in one beat where the second `await`s.**

**The evidence base for why (censused 2026-08-06, parked here for when this section is picked up):**
 the three transport ghosts (`Heist.g`/`Ra.g`/`Repli.g`) carry **29 distinct hand-rolled `.c`
  throttle/attempt stamps** — `answer_ts, answers, ask_ts, bench_ts, breach_at, census_ts, desc_ts,
   done_ts, flow_ts, heist_rehydrate_tries, land_warn_ts, last_land_ts, parked_at, pull_progress_ts,
    pull_started_ts, pull_ts, ra_tries, ra_want_ts, ready_ts, recensus_ts, rematz, reserve_mark_ts,
     resume_navwait_ts, serve_mark_ts, serve_miss_ts, tlp_ts, told_at, want_ts, warned_at`. Every one
      privately answers the same three questions a req answers structurally (already running? ran
       recently? ran too often?), several have already produced bugs (the §4.1-Heist deaf budget, the
        `ra_want_ts` two-readers red, the human's recurring *"we did this expensive thing five
         times"*), and none is visible in a snap. The refactor's cheap first cut: make MATERIALISE a
          `%req:materialise,of:<id>` — the most expensive verb in the system, currently guarded by a
           bare 5s stamp with the release sweep pulling the other way (`Heist_todo` §4.2).

### 4.2 The proposed shape

```
%Heist,seed,pub
  req:Heist          maz high, eternal      the pump — replaces the Heist_keep_step call
    req:Census                             the describe/rummage ask (own RTO, own hold)
    req:Ask,id                             one per record in flight — issues wants, never blocks
    req:Land,id                            one per landing — holds the writer, never awaited inline
  Pick,ref …                               unchanged; the plan/ledger, CONSULTED not piled under
```

`req:Ask` and `req:Land` are **siblings**, so one `do()` pass reaches both. A landing in flight no
 longer stops the asker.

**Who pumps it:** the existing share beat, unchanged as the ambient tick (§7.1) —
 `Heist_keep_beat` thins to `keep.do()` per heist (plus its source-side housekeeping), and the
  work moves from `Heist_keep_step`'s state-string dispatch into the req do_fns. No new timer, no
   new loop; the beat stops being the *worker* and stays the *clock*.

### 4.3 The discipline that makes it actually concurrent

This is the part a reviewer should press hardest on, because getting it wrong buys nothing.

**`do()` is serial** — a cooperative scheduler, and an `await` inside a do_fn makes it a
 *blocking* one. Moving the heist onto reqs does *not* by itself fix the convoy: if `req_Land`'s
  do_fn `await`s the whole write, siblings still block exactly as they do today. The rule is the
   non-blocking-IO shape every event loop converges on — **issue, return, complete via
    continuation**:

> A long operation is **kicked off**, and its req **stays unfinished** and returns.
> Completion arrives out of time via `reqyoncile`.

`Housing.svelte.ts:2210/2276` already uses this shape for IO
 (`const done = (reply) => { finish(reply); fs_req.sc.finished = 1 }`), and
  `e_reqyonciliation` exists precisely to *"drive a req's chain after its async Atime."*

**Hold, not wake** (`Coding_guide.md`): an unfinished req (`needs_work`) or a ttlilt is a HOLD; a
 wake merely re-drives. A pending async operation that must show up in a snap needs a hold. And:

- **A ttlilt is a one-shot snap-timing advisor — "don't snap for ~N seconds". It is NOT a
   keep-alive and it does NOT re-fire a think.** (memory: `ttlilt-not-a-keepalive`)
- **Prefer an unfinished req over a ttlilt wherever you can** — a deterministic hold beats
   "hope N seconds is enough."

So `req:Land` should be a **plain unfinished req**, not a ttlilt: it is unfinished while the
 writer works and finishes when `close()` + the read-back gate pass. That is deterministic, and it
  makes the Story snap correct for free — the snap can never catch a half-written file, which the
   current inline-await gets only by accident of blocking.

`req:Ask`'s retransmit timer wants **no timer primitive at all** (§7.1, ruled): the req stays
 unfinished while any hole is outstanding, and the **ambient beat** re-drives it. Each pump asks
  "anything outstanding past its RTO?" — re-issue if so, return unfinished either way. No ttlilt.
   The beat's cadence is the retransmit clock's resolution, which is ample for an RTO measured in
    hundreds of ms and up.

And `req:Land` sits **beside** `req:Ask` at the same `maz`, not above or below it (§7.2, ruled):
 the ask set is derived from what is already landed, so there is no read-your-writes hazard to
  order around, and per record the two never even coexist.

### 4.4 What must not regress

`pick.sc.landed` and `Heist_keep_persist` are stamped immediately after the awaited `Heist_land`
 (`Heist.g:1689` / `:1699` — the persist is itself awaited, "Berth must know THIS one is done
  before the next reload"). Once the landing is no longer awaited inline, **they must move into
   the completion seam** or the ledger claims a file that is not yet on disk — and Berth would
    resume as if it were. So must `Heist_writer_drop` (`Heist.g:288`): a landing that dies
     without releasing its held writer leaves an exclusive FSA lock, and every later attempt at
      that path dies `NoModificationAllowedError` until a reload. This is the single
       highest-risk edit in the refactor.

---

## 5. Staged plan

Each stage is independently landable and independently testable.

### 5.1 Egress classes on the relay socket  *(no refactor needed — do first)*

**AMENDED 2026-08-06 — a bounded lane MUST confess its shedding.** As first landed, the bulk lane
 dropped the oldest page when the local queue passed `BULK_CAP` **silently**. The shed itself is
  right (bounded and shed, like the outbox/inbox; the sink re-asks, so it is congestion, not loss).
   Doing it silently was not: `port.send` has ALREADY returned to Repli, which counts the page as
    away — so the source reads *"273/300 sent"* while the sink holds *25*, the counters disagree by
     exactly the frames we dropped, and **nothing anywhere says so.** The human hit precisely this and
      reasonably read it as a sink bug. An invisible shed is indistinguishable from a defect, and it
       sends the hunt to the wrong end of the wire. Now counted (`w.c.relay_bulk_dropped`, surfaced
        through `Repli_meter.bulk_dropped`) and logged on the 1st and every 25th.
 **The general law, worth more than the fix:** anywhere we shed to stay bounded, the shed is a
  FIRST-CLASS EVENT, not an implementation detail — because the layer above has already been told
   the opposite. Bounding without accounting turns a deliberate policy into a phantom bug.

**Why not just reorder the `%outbox` instead?** Because it is not a queue. `Peeroleum_send`
 books an `%emit` for *retransmit tracking* and calls `wire()` in the same breath — the frame
  reaches `ws.send` immediately, nothing ever waits its turn there. Worse for this purpose, every
   bulk type is already **ephemeral** (`Peeroleum.g:426`) and books no emit at all, so the outbox
    does not even contain the frames we want to hold back; the only things in it are the
     door-opening handshakes, whose order must not be touched. The same goes the other way for the
      inbox — see §7.3: it is receive-side, so reordering it cannot rescue a pong that was never
       *sent*, and the frames worth prioritising already left that queue entirely rather than
        moving up it.

**The queue that actually exists is `ws.bufferedAmount`** — inside the browser's WebSocket, strictly
 FIFO, with no per-message inspection, no reordering and no cancel. `wire()` is a bare `ws.send`
  (`Tribunal.g:97`). So this item is not "reorder the queue", it is **stop handing everything to a
   queue we do not control**: hold bulk in a queue we own, and ordering becomes ours to decide.
    *You can only reorder a queue you hold.*

Split `Tribunal.g`'s `wire` into two strict-priority lanes:
- **express** — everything that is not bulk: sent unconditionally, never behind a page.
- **bulk** — sent only while `ws.bufferedAmount < HIGH`, else queued locally and flushed as it
   drains (the browser `WebSocket` has no drain event — poll `bufferedAmount` on the beat or a
    short timer; the datachannel path already has `bufferedamountlow`).

**Classification, precisely — a naive type list gets this wrong.** There are no `census`/
 `describe` frame types: the folder-describe is a `%Rummage` particle shipped via `Repli_offer`
  (`Heist_rummage_ask`, `Heist.g:1327`), so it rides **`repli_lines`** — a split that sends
   `repli_lines` bulk queues the census reply behind pages and re-creates the exact stall this
    stage exists to fix. The only type carrying six-figure byte bodies is **`repli_page`**. So:
     **bulk = `repli_page`; express = every other type** (`ping`/`pong`/`ack`/`hello`/`vouch`/
      `trust`/`key`/`swarm_hi`/`pulse`/`advertise`/`ive_got`/`repli_want`/`repli_lines`/
       `stream_offer`/`audiochunk`/`no_protocol`, §5.3's `repli_parked`). `audiochunk` is the
        LIVE radio stream — real-time audio must never wait behind heist bulk, which alone
         forbids a "small allowlist, bulk by default" stance. A pathological `repli_lines` flood
          (a whole-library re-offer after rebirth) is possible but rare and self-limiting; if it
           ever shows, gate lines frames by *size*, not by type.

Fixes pong starvation → the 15s reaper → the reconnects; stops describe replies queueing behind
 pages; and gives us the **first genuine congestion signal on the path we actually use** — with
  the bonus that once control has its own lane, a bulk drop or delay unambiguously means
   congestion rather than self-inflicted head-of-line, which is what makes §5.6's feedback loop
    trustworthy.

*Prove:* not Book-able (the relay socket sits under the mock's floor) — prove it live: the
 standing two-pier heist with `?socklog` armed, watching the `code=1006` reaper kills stop while
  a big track lands and the census answer arrive mid-pull; MusuHeist via `runner_ask.mjs` as the
   no-regression gate.

### 5.2 Close the sensor gap — attribute, then consume
The aggregate wire rate is already measured and visible: `Repli_meter` (`Repli.g:559`) flushes
 every ~1.5s into `Repli_xfer_get`'s shared object — `rx_kbps` / `tx_kbps`, a 32-sample spark,
  drop and breach messages — and the `%Transfer` HUD draws it: up/down, graph, KB, dropped-frame
   messages below. **The sensor exists. Two things are missing:**

- **Goodput attribution.** The graph is wire throughput; nothing measures per-heist *goodput*
   (bytes landed ÷ time) or the efficiency ratio between them. Duplicate asks, re-serves and
    breach-refused pages are invisible as waste — the graph goes *up* while the transfer gets
     *worse*. Marks already exist at both ends (`Ra_pull_beat`'s pulls, `Repli_serve_want`'s
      serves); the missing piece is landed-bytes per heist over time, and wants-issued vs
       pages-landed per beat.
- **A consumer.** No code reads any rate. Every knob in §1 is open-loop — constants tuned for
   one operating point, with a human watching the graph as the feedback path. §5.5 and §5.6 are
    the consumers; this stage is the prerequisite that makes them judgeable rather than vibes.

*Prove:* all runtime `.c`, no snap byte — so no fixture moves and no Book gates it. The proof is
 the HUD showing a per-heist goodput number beside the wire rate, and `runner_ask.mjs world`
  carrying the same fields; sanity-check that goodput ≤ wire rate always, and that a deliberate
   re-ask storm (drop a source mid-pull) opens a visible gap between them.

### 5.3 Signal a park back to the sink
A tiny `repli_parked` reply from `Repli_park_want` — ECN semantics: "not lost, stop spending."
 The addressing is already stashed on the parked particle (`p.c.reply_to` / `p.c.reply_from`,
  `Repli.g:481`), so the source side is a frame send. The sink side: suspend the RTO for that
   (id, offset) and stop burning want-budget there until unparked bytes arrive or a generous
    ceiling passes. Cheap, and it is missing *information* — which always beats better tuning of
     an ambiguous timeout. **Mind §9.1**: the new frame type must join Peeroleum's ephemeral set
      AND Tribunal's ambient log map, or it re-creates the outbox melt and the log flood.

Ephemeral is the *correct* class here, not merely the safe one, and the FRAME RELIABILITY POLICY
 at `Peeroleum.g:427-431` decides it outright: **a frame that opens a door (a handshake) or
  carries pushed app data with no re-ask behind it is RELIABLE; a frame that is gossip, a beacon,
   self-re-asking — or the RESPONSE to a self-re-asking pull — is EPHEMERAL.** `repli_parked` is
    the response to a self-re-asking want: lose it and the sink falls back to the timer it has
     today. Reliable would be strictly worse than useless, because live `Peeroleum_arm_whittle`
      runs only in Books — an un-acked reliable emit is retransmitted by nothing and culled by
       nothing, so it just climbs toward the 6000-row "giant stuff" cliff that killed the deliver
        pump mid-heist.

**LANDED 2026-08-06.** `Repli_park_want` is now `async` and sends `repli_parked` (`from: h.to, to:
 h.from`, addressed off the SAME `p.c.reply_to`/`p.c.reply_from` `Repli_serve_parked` already reads)
  on first park only, gated by the existing `p.c.counted` latch. The sink's handler
   (`Repli_recv_parked`, registered in `Repli_arm`) stamps `w.c.ra_parked[id:offset] = Date.now()`;
    `Ra_pull_beat` reads it and skips the 4s re-ask while `nowms - parkedAt < PARK_CEIL`
     (`w.c.heist_park_ceiling`, default 20s) — bounded, so a park that never resolves still falls
      back to the ordinary timer. `w.c.ra_parked` rides beside `ra_wanted`/`ra_want_ts`, cleared
       together on rebirth (`Swarm_note_era`).

*Proven:* MusuReco (Musuation.g) grew a `witnessed:parked_signalled` / `%see:` pair keyed on
 `w.c.ra_parked` — the SINK's own record, written only off an arrived frame, so it proves the
  signal crossed rather than merely that the source counted a park. Re-recorded live and run
   robustly green 3/3 (`ok_pct:1` each). MusuHeist/MusuPier/MusuDoor/MusuReplica re-ran clean with
    no fixture change beyond routine TimeSpool telemetry (they don't hit a park). **MusuRaChase and
     MusuRaStream could not be re-verified this pass** — both are `needsFSA` Books and the only
      reachable runner had silently lost its FSA grant between an earlier clean 56-step run and
       every retry after (`phase:"begun"`, `done:0` forever — see the runner-traps memory). The one
        real run before the grant was lost showed `witnessed:` unchanged but was **missing one
         `%see:` claim** present in the recorded fixture (`'the playhead crossed the first boundary
          onto chunks transcoded on demand'`) — plausibly explained by the one new `await` this
           change adds to the source's serve-parking path nudging a wall-clock-timed real-decode
            boundary across a step edge, but NOT confirmed against a second clean run, and their
             fixtures were deliberately left un-accepted. **A reviewer with a live FSA-granted
              runner should re-run both before this ships**; if the claim is genuinely and
               reproducibly gone, the fix is almost certainly to shave the added latency (skip the
                digest for a fixed-body ephemeral control frame, or inline a constant body_hash)
                 rather than to change the parking semantics.

*Prove:* the transcode-outrun path already has witnesses (`repli_parked`/`repli_unparked` counts,
 `witnessed:outran_then_served`, `Musuation.g:2964`) — extend that Book with a
  `%see:'the sink stopped re-asking while the want was parked'` off the sink's want counters, and
   re-record it live. The negative control is today's behaviour: ~30 re-asks across a two-minute
    park.

### 5.4 The req refactor (§4)
`%Heist` grows `req:Heist` with `req:Census` / `req:Ask,id` / `req:Land,id` siblings. Landing leaves
 the beat. Watch §4.4.

*Prove:* the one stage that moves snaps — `%Heist` grows req children, so `Heistation` and
 `Sounditron` re-record from a live runner (§8). Use the claim-set diff gate (`Repli_design.md
  §9.6`): fixture bytes may move freely, but refuse the accept if any `witnessed:`/`see:` claim
   changes. The live proof of the actual point — landing no longer blocks asking — is the
    `ev:'beat'` electrode: during a big track's land, `skips` must stay ~0 and the *other*
     in-flight track's pulls must keep advancing, where today the beat logs `ms:30000+` stalls.

**LANDED 2026-08-06 — narrower than the §4.2 shape, on purpose.** The full `req:Heist`/`req:Census`/
 `req:Ask,id` ceremony is NOT built. What shipped is the one thing actually measured broken
  (§3.1) — `Heist_keep_step`'s `state:'pulling'` branch no longer `await`s `Heist_land` inline —
   using `this.expecting(w, name, secs, async_fn)` (`Hovercraft.svelte`), the SAME "issue, return,
    complete via continuation" primitive already proven elsewhere (`Story_demand_audio`,
     `Musu_gen_testsounds`, every `rachase_*`/`buddy_*` Book stage) rather than hand-rolling a new
      `req:Land,id` shape. It IS a req underneath (`w.oai({req:name})`, ttlilt-held, finishing via
       `reqyoncile` — Coding_guide's hold-not-wake rule, honoured for free) — just not one wearing
        the `%Heist` parent §4.2 sketched. The ask/census side (`pick.c.ask_ts` throttling,
         `Ra_pull_beat`) was already non-blocking and untouched. **Reasoning for the narrower cut:**
          the reviewer's own framing of "§5.4" was "moving landed/persist/writer_drop out of the
           inline await" — that IS this change; the full particle ceremony is a bigger, riskier
            rewrite of ~250 lines of tuned windowing/bench/progress logic that isn't itself broken,
             and doing it here would have multiplied risk on the one part asked for extra scrutiny.
              §4.2's fuller shape stays a valid later direction, not abandoned.

**What actually changed, precisely:**
- `Heist_land_stream` now `return`s `true` past its one real success tail (`Heist_catalog_land`) and
   falsy off every early-return breach path; `Heist_land` propagates it. **This closes a
    pre-existing, latent bug**, not one this refactor introduces: the old inline call ignored
     `Heist_land`'s return entirely and stamped `pick.sc.landed = 1` unconditionally — including
      after a breach that had already unlinked the file. Necessary here because the continuation
       needs *something* to branch on; left as `TODO` it would have carried the bug into async form
        with a longer window to hit it.
- `pick.c.landing` is the single-flight latch (a second beat reaching an already-landing pick just
   `continue`s); `left` counts a landing-in-progress pick so the keep can't read `!left` and flip to
    `state:'done'` — which **drops the keep** — while a write is still in flight underneath it;
     `inflight` does NOT count it, so the network window opens for the next pick immediately (the
      actual point of the stage). The bench watchdog and OVERLAP check are skipped for a
       landing-in-progress pick — it isn't stalled, it's writing, and subjecting it to the 45s
        network-stall bench would have been a false positive waiting to happen.
- **A liveness guard I added beyond what was asked, because the restructuring itself opens the
   hazard**: `Heist_land` running off-beat can now outlive a user's ✕ (`Heist_keep_cancel` rm's the
    `%Heist` and `Heist_keep_forget` wipes the Berth entry). `Heist_keep_persist`'s Berth write is
     `oai` — find-or-create — so an unguarded stale continuation would have **resurrected the very
      entry the cancel just deleted**. The fix: re-check `shop.o({Heist:1, seed:...})[0] === keep`
       immediately before persisting; skip if the keep is no longer the live one. The file itself is
        left on disk either way (harmless extra, the same tolerant stance `Heist_held`'s dedup
         already takes). **No fixture exercises `Heist_keep_cancel`** — this is reasoned, not
          live-verified; flag it for anyone adding cancel coverage.
- The finishing `%req:heist_land_*` particle `expecting()` mints is explicitly `w.drop()`'d in a
   `finally`, both on success and on error — CLAUDE.md's "an owner drops its finished transient
    reqs" law. Every OTHER production `expecting()` caller leaves theirs (fine at their volume —
     once per session); this one fires per landed track, real heist scale, so it would have been
      the exact dead-row pile the law warns about if left alone.

**Verified live:** `MusuHeist` — no fixture change at all (a correctly-held async op is invisible to
 a quiescence-gated snap; this is stronger evidence than a matching re-record would have been) —
  but **flaky at step 2** (census/setup, real file reads + hashing) across 6 runs: 3 clean, 3 red,
   always the same step, always before `state:'pulling'` even exists. Structurally cannot be this
    change (`Heist_keep_step`'s pulling branch hasn't run yet at step 2) — most likely the runner
     environment (mid-session reload, possibly a shared/busy tab; `ping` showed another Book running
      when this pass started). Re-run a few times before trusting a single MusuHeist result either
       way, independent of anything in this doc. **Not compile-checked, live-checked only** —
        `Heist_keep_cancel`'s path has no Book at all (see above).

**§4.4's actual risk, restated against the real diff**: the `pick.sc.landed` / `landed_at` / `bump`
 / `Heist_keep_persist` block moved verbatim into the continuation, in the same order, gated the
  same way (`if (ok)`) it always effectively was — the diff to read carefully is the `left`/
   `inflight` split and the liveness guard above, not the stamp order itself.

### 5.5 Measured RTO + tail probe
Replace the fixed 4s with the Jacobson/Karels estimator: EWMA `srtt`/`rttvar`,
 `RTO = srtt + 4·rttvar`, floor ~250ms. **Mind Karn's rule**: an arrival for a re-asked offset is
  ambiguous — you cannot tell which ask it answers — so never take an RTT sample from a
   retransmitted (id, offset) unless asks carry a serial to disambiguate. Plus a tail probe: when
    holes are outstanding and nothing has arrived for ~2·srtt, re-ask the newest hole immediately
     rather than sitting out the full RTO — the TLP move, aimed at exactly the §3.1 tail. Lands
      cleanly only after 5.4, because before that the beat lies about time.

**BUILD PLAN (worked 2026-08-06 — estimator + Karn discipline + TLP; sink-local, no new frames).**

*Where the state lives:* per source Pier, off-snap — `pier.c.rtt = { srtt, rttvar, rto }`. This
 is a measurement, not model state: no particle, no snap byte, no version bump — the same stance
  as `repli_meter`. (§7.5's req-beats-a-string ruling is about TRANSPORT state; a rate estimate
   is telemetry.)

*The sample.* `w.c.ra_want_ts[key]` (key = `id:page_off`) already stamps every want at send —
 that IS the departure half, for free. The arrival half is `Repli_attach_page`'s chunk-particle
  branch (`landed == 1` under `await_bufk`): the page offset comes off `mirror.sc.seq`
   (`seq - seq % PAGE`), the rec off `mirror.c.up`, and if the key holds a stamp:
    `sample = now − ts`. Then **CLEAR the stamp** — today `ra_want_ts` is never cleared on
     landing, it only goes stale; clearing on land is what makes "a stamp exists" MEAN
      "outstanding", which §5.6's window accounting then reads directly. (Do NOT touch
       `ra_wanted` — that is `Ra_restock_beat`'s want-once cursor and must persist.)
 **Karn**: never sample a re-asked key. Every re-ask site — `Ra_pull_beat`'s expiry path,
  `Ra_mag_warm`'s warm retry, the TLP below — stamps `w.c.ra_retx[key] = 1`; the attach seam
   skips the sample when set, and clears it alongside the stamp. A key landing out of a PARK
    (`w.c.ra_parked[key]` present) is ALSO no sample — its elapsed time measures the far
     transcoder, not the path — and clear the park entry right there too: today it only ages
      out, so it lingers as a 20s re-ask suppressor after the bytes already landed.
 **The estimator**, Jacobson/Karels verbatim: first sample `srtt = s; rttvar = s/2`; after,
  `rttvar = ¾·rttvar + ¼·|srtt − s|`, `srtt = ⅞·srtt + ⅛·s`, `rto = clamp(srtt + 4·rttvar,
   250, 8000)`. Init `rto = 4000` — today's constant — so behaviour before the first sample is
    byte-identical to today; the change can only tighten, never loosen.

*Who reads it:* the two hardcoded `4000`s — `Ra_pull_beat`'s re-ask gate and `Ra_mag_warm`'s
 warm retry — become `(rec.c.rx?.c.rtt?.rto || 4000)`. Add per-key exponential backoff on
  repeated expiry (`w.c.ra_tries[key]`, effective timeout `rto << min(tries, 3)`, cleared on
   land): a wedged source gets a doubling ladder, not a hammering metronome — the park signal
    (§5.3) already covers the LEGITIMATE slow case.

*The tail probe.* Per rec: `rec.c.last_land_ts` (stamped at attach) and `rec.c.last_asked_off`.
 On the beat, when the rec has outstanding stamps and `now − last_land_ts > max(2·srtt, 600)`:
  re-ask `last_asked_off` once per quiet spell (mark `ra_retx`, stamp `ra_want_ts` so the
   ordinary gate doesn't double-fire). §3.1's tail hole today costs a serial 4s each; under TLP
    it costs ~2·srtt, floored by the 600ms beat resolution — that floor is intended (§7.1: the
     beat IS the retransmit clock's resolution).

*Rebirth:* `Swarm_note_era` already wipes `ra_wanted`/`ra_want_ts`/`ra_parked` — the new maps
 (`ra_retx`, `ra_tries`) MUST join that wipe, and per-rec outstanding counts (§5.6) reset with
  them. `pier.c.rtt` SURVIVES rebirth: the path outlives the peer's boot, and a one-boot-old
   srtt is a better prior than none.

*Surface it* (§5.2's first consumer): `srtt`/`rto` join `Repli_xfer_get`'s per-pull entries so
 the HUD and `runner_ask world` show the measured path beside goodput.

*Fixture cost: none expected.* No new frame types (§9.1's two lists untouched), no snap keys.
 In Books the mock wire drops nothing, so the RTO virtually never fires and the estimator is
  inert cargo. Re-run MusuHeist + the chunk-path Books as regression; claims must not move.

**LANDED 2026-08-06.** `Repli_land_rtt` + `Repli_rtt_note` + the `Repli_rto`/`Repli_srtt` readers
 (Repli.g, at the arrival seam), the measured gate + per-key backoff + the tail probe in
  `Ra_pull_beat`, the same gate in `Ra_mag_warm`, `ra_retx`/`ra_tries` joining `Swarm_note_era`'s
   rebirth wipe, and `srtt`/`rto`/`tlps` on the pull's HUD entry. Knob: `w.c.heist_tlp` (default on).
   Three things the build learned that the plan above did not know:

- **The sample falls when the PAGE completes, not when a chunk lands.** A want asks for a page —
   PAGE chunks, PAGE frames — so clearing the stamp on the first arrival would leave the second
    chunk in flight with nothing behind it, and an out-of-order pair would re-ask a page that was
     already arriving. `Repli_page_ready` (the source-side helper, substrate-aware) reads the mirror
      just as well, so it is the gate. It also makes the sample the honest one: the RTO governs
       "when do I give up on this PAGE", not on one frame.
- **Clearing the stamp broke `Ra_mag_warm`, and that is the generalisable lesson.** That loop had
   NO presence check — it re-asked page 0 on a cadence until the mag happened to go warm, held down
    only by the 4s timer being long. Once a landing clears the stamp, "no stamp" reads as "never
     asked" and it fired every pass: +2 served pages in MusuMag's step 3, caught by the fixture, not
      by review. **Every reader of `ra_want_ts` must now pair it with a presence check** — the stamp
       is an OUTSTANDING marker, no longer a want-once memo. `Ra_pull_beat` always had one
        (`map[off] == null`); `Ra_mag_warm` now does too. §5.6's window accounting inherits the rule.
- **The tail probe was innocent and is still unproven.** Suspected in MusuMag's remaining red, gated
   off, re-run — no change; the red survives a full revert of this section (see below). So the TLP
    costs nothing in Books, which also means no Book yet EXERCISES it: nothing here drops a page.
     Its first real evidence will be live, on `tlps` in the HUD during a lossy pull.

*Verified on the live runner (never `Story_cli_run.mjs`):* MusuHeist 22/22, MusuReplica 14/14 (the
 Float32 control — unmoved, so the substrate split held), MusuReco 11/11, RepliShadow 5/5,
  RepliSplit 5/5, RepliUpsert 7/7, MusuStock 5/5. (**`caveat` counts are run-to-run noise, not a
   signal** — MusuHeist returned 1, then 21, then 1 on identical code. A caveat is a mismatch
    FORGIVEN as acknowledged value-noise, so whether a step mismatches at all rides the wall clock.
     Read `ok_pct`; ignore the caveat tally unless a claim moved.) **MusuMag (0.7, steps 8–10) and Sounditron (0.0)
   are red at EXACT parity with a baseline run taken with `Ra.g` + `Repli.g` reverted to HEAD** —
    both pre-existing, neither caused here. That revert-and-re-run is the only thing that settles
     causation while the tree also carries someone else's uncommitted work; the fixture diff alone
      (2 extra pump rounds + 6 `repli_parked` unemit rows at step 8) reads exactly like a transport
       regression and is not one. Do that before believing a red is yours.

*Still unproven:* a real RTT sample. Books land pages inside a tick, so `s` is often 0 (guarded, no
 sample) and `rto` stays at the 4000 fallback — the estimator is genuinely inert cargo there, which
  is why the fixtures did not move. Its first honest reading needs two peers and a real heist:
   watch `srtt`/`rto` beside `goodput_kbps` in `runner_ask world`.

### 5.6 A window that breathes
Replace the constant `B` with a byte window under **AIMD** — additive increase on timely arrival,
 multiplicative decrease (halve) on RTO, floor ~2 pages — the Chiu-Jain result being that AIMD is
  the increase/decrease pair that converges to fair and efficient sharing, which starts to matter
   the day two heists share one uplink. And clock issuance on **arrival** as well as the beat:
    self-clocking, the ack-clock that lets a transfer run at wire speed between beats instead of
     at `window ÷ 600ms`. This is where "push against the limit slightly all the time" actually
      lives. (A rate-based alternative — pace directly off §5.2's measured delivery rate,
       BBR-style, with the window as backstop — is worth a paragraph in review; AIMD is the
        simpler first loop and the signals it needs exist after 5.1.)

**BUILD PLAN (worked 2026-08-06) — the SELF-CLOCKING half lands now, with §5.5; the AIMD half
 stays deferred until the clock has run live.** This is the "landing off the share beat" item:
  today a landed page does NOTHING until the next 600ms beat deigns to notice it — arrival, the
   one event that proves the pipe has capacity, is the one event that drives nothing.

*The shape:* one new optional hook, `w.c.repli_clock`, registered by the pull side (Ra) and
 fired by `Repli_attach_page` after a landed chunk on the chunk-particle path only (`landed == 1`
  under `await_bufk`, beside `repli_on_land` — which is the radio's wake and stays the radio's).
   Unregistered — every Float32 Book, the idle app — nothing fires: byte-identical.

*The discipline that makes it safe:* the attach seam runs INSIDE the inbox drain, inside the
 beliefs mutex (§7.3, §5.8) — the hook does O(1) bookkeeping and NOTHING else inline. It
  decrements the rec's outstanding count when the landed page's LAST chunk is present (an
   O(PAGE) presence check), stamps `last_land_ts`, and arms ONE coalesced `post_do` issuance
    per rec (`rec.c.clock_armed` — the `bulk_pump_armed` pattern from Tribunal's lane). The
     issuance fn then runs as its own Atime pass: while `outstanding < W` and the ask cursor
      (`rec.c.ask_next`, the lowest never-asked page offset) still has pages, send wants —
       addressed off the same breadcrumbs `Ra_restock_beat` uses (`rec.c.rx`, `rec.c.from`,
        `w.c.repli_mirror_pier`), stamping `ra_want_ts` exactly as the beat does, so the
         estimator and the recovery timer see clock-issued wants identically. `repli_want` is
          already ephemeral in Peeroleum (§9.1), so the clock cannot melt the outbox.

*Division of labour, precisely TCP's own:* the CLOCK sends new data; the BEAT recovers.
 `Ra_pull_beat` keeps its B=6 budget as BOOTSTRAP (a fresh rec has nothing outstanding — no
  arrivals, so the clock is silent) and as RECOVERY (RTO re-asks + TLP; holes BEHIND the
   cursor are its property, the cursor AHEAD is the clock's). A total arrival stall — every
    outstanding want lost — starves the clock, and the beat's RTO re-ask is what restarts it:
     the timer-restarts-the-ack-clock shape, verbatim.

*The window is FIXED in this stage:* `W = w.c.heist_window`, default modest — 16 pages = 8MB
 outstanding (LEAD=32's 16MB is the ceiling, not the target) — because removing the issue-rate
  throttle promotes the REAL constraints (the sink's per-frame drain inside the mutex, the
   source's pack+hash, the relay's bulk lane) to operating limits for the first time. Watch the
    source's `relay_bulk_dropped` and the `beat` electrode while raising it. PARKED offsets
     count as outstanding: a parked frontier must HOLD the window — asking further ahead of a
      transcoding source only parks more.
 *Then AIMD is one variable:* W becomes `rec.c.win` — +1 page per clean RTT round, halve on
  RTO expiry, floor 2, with maybe a BBR-flavoured cap off §5.2's goodput later. Nothing in this
   stage's shape moves to admit that; building the clock first is what buys the one-variable
    retrofit. *(Tribunal.g needs NOTHING this stage — its `relay_bulk_queued`/`relay_bulk_dropped`
     are already surfaced; they become the loop's INPUTS only when AIMD lands.)*

*What it buys, in §1.1's own terms:* the binder stops being `6 × 2 × 256KB ÷ 0.6s = 5MB/s`
 and becomes `min(W ÷ RTT, wire, drain)` — on local-local, wire/drain-bound at last; the 65MB
  flac that was ~13s of pure ask-pacing becomes wire-limited.

*Fixture cost: REAL, unlike §5.5's.* Arrival-clocked wants change how many pages land per Story
 step, so held-counts in snaps can move for the chunk-path Books — MusuRaStream/MusuRaChase (the
  two already un-accepted: re-record them green FIRST, one suspect per red) and possibly
   Heistation/Sounditron. Claim-diff gate as ever: bytes may move, `witnessed:`/`see:` claims
    may not. MusuReplica/MusuReco are Float32-path — no hook registered — and must not move at
     all; drift there means the gate leaked.

*Prove live:* time the 65MB pull before/after; goodput vs wire-rate in the HUD (they should
 CONVERGE — a widening gap under the clock means duplicate asks, i.e. the accounting is wrong);
  `skips` ~0 on the `beat` electrode mid-pull; `relay_bulk_dropped` flat at W=16.

**LANDED, GATED OFF (2026-08-28) — `Ra_clock_arm` + `Ra_clock_issue` (`Ra.g`), the fire branch in
 `Repli_land_rtt` (`Repli.g`), knob `w.c.heist_selfclock` default OFF, window `w.c.heist_window`
  default 16 pages.** How it maps onto the plan above, and the deviations:
- **Registration is in `Ra_pull_beat`, not an arming site.** The plan pictured Ra registering the
   hook at share-up. But `Ra_pull_beat` rides the station `w` in EVERY pull path (live share AND Musu
    loopback), so an idempotent `if (w.c.heist_selfclock && !w.c.repli_clock) w.c.repli_clock = …` at
     the top of the beat cannot miss an arming site and needs no edit to Swarm.g (another agent's file
      this stage). The knob-gate means OFF ⇒ never registered ⇒ `Repli_land_rtt`'s branch is dead ⇒
       byte-identical, which is the whole harmlessness argument.
- **OUTSTANDING is derived from the stamps, not a counter.** The plan said "decrement the rec's
   outstanding count." A counter drifts (a dropped want, a park that never lands). §5.5 already made
    "a `ra_want_ts` stamp exists" MEAN "outstanding," so `Ra_clock_issue` just SCANS the rec's stamps
     — self-correcting by construction: land drops one, park keeps one (holds the window, §5.3), a lost
      want keeps one until the beat re-asks. No `rec.c.outstanding`, no decrement seam, nothing to drift.
- **The hook ARMS, it does not send.** Fired inside the inbox drain (the beliefs mutex), `Ra_clock_arm`
   only sets `rec.c.clock_armed` and `H.post_do`s the real issuance as its own Atime pass (Tribunal's
    `bulk_pump_armed` idiom). A burst of N pages in one drain ⇒ ONE issuance, after the drain — the
     "O(1) inline" discipline the plan demanded.
- **Both the arm and the issue re-check the knob**, so toggling `heist_selfclock` off LIVE silences the
   clock even though the hook stays registered on `w` (registration is one-way).
- **Telemetry: `rec.c.clocked`** counts clock-issued wants and rides the pull's HUD entry
   (`entry.clocked`) beside `srtt`/`goodput`, so `runner_ask world` SHOWS the clock firing.
- **The one rough edge, left deliberately:** `rec.c.ask_next` (the clock's forward cursor) is NOT reset
   on rebirth — `Swarm_note_era` wipes the `w.c` want maps but not this per-rec cursor, and Swarm.g was
    off-limits this stage. Held chunks survive a rebirth so `Ra_page_hole` stays correct; a stale cursor
     only means the clock resumes ahead while the beat backfills behind — it self-heals, never loses a
      page. Wire the reset in when the knob goes default-on.
- **Verified harmless, NOT yet helpful.** MusuHeist 22/22 `ok_pct:1` (chunk path) + MusuReplica 14/14
   `caveat:0` (Float32 control — proves the gate didn't leak into the no-hook path), live runner, clock
    OFF. Its HELP is unmeasured until the human flips `heist_selfclock` on against the live daemon (watch
     `clocked` climb and goodput converge on wire-rate) or item 00's `MusuNeGrind` exercises it on the
      bench. Same "harmless now / helpful live" posture as the 2026-08-28 `Repli_serve_parked` budget.

### 5.7 Negotiated chunk size
256KB is fixed everywhere. The latency argument against big frames is serialization delay —
 256KB ahead of your pong is 200ms at 10Mbps — but that argument evaporates for *control* once
  5.1 gives it an express lane, leaving frame size a pure throughput/overhead trade: local-local
   wants 1–4MB, a slow remote wants 64KB, and the right size is roughly a small fraction of the
    measured bandwidth-delay product. Pointless before 5.1.

### 5.8 Get the byte work off the C tree's critical section
The deepest constraint: **the C tree is single-threaded under a mutex and we do second-scale byte
 work inside it.** `Heist_land` holds it for seconds; `Heist_materialise_one`'s whole-file
  `read_range(dir, filename, 0)` held it for 21s (`pcm-read ms:21264`). Same root as the missed
   pong. Windowed materialise first (the read already takes a window — same shape as the write
    fix), then ideally sha256 + FSA writes into a Worker — bytes only, particles stay home
     (§9.4).

**The Peeroleum inbox drain belongs to this item, and only to this item.** Its per-frame work
 runs inside the beliefs mutex / Atime (`Peeroleum.g:179-180`), so a burst of pages holds the
  world's tick for the length of the burst — but the *verify* half is already off-thread native
   (`crypto.subtle`, `:186`), so what remains here is the particle mint, not the hash. The drain's
    serial shape is load-bearing and must not be restructured (§7.3, ruled): fix it here, by
     shrinking what the mint costs per frame, or leave it.

### 5.9 Scope seqs to a station era — finish the epoch handshake  *(post-v1.0)*
The reused-seq guard (§9.2) exists because a seq alone cannot say WHICH incarnation of a peer
 it belongs to. The standard cure is an **incarnation number** — TCP's ISN selection + quiet
  time, QUIC's connection IDs, the view number in consensus protocols: mint a fresh token per
   boot, exchange it at handshake, scope every seq to it. `(era, seq)` is then unique by
    construction, and "is this frame from a previous life" stops being a *memory* problem (keep
     enough history to recognise old seqs) and becomes an *identity* one (read it off the frame).

Two-thirds of this is already built — one layer up, twice (§9.2): `Swarm_era` (a `Date.now()`
 minted per boot) rides every swarm frame with a `saw:` confirmation echo (`Swarm.g:758-801`),
  and the Lies channel's ping carries a `boot` page-life id (`LiesLies.svelte:1353`); both funnel
   a change into `Peeroleum_reset_handshake`. What remains is moving the era DOWN into the layer
    that owns seq: exchange it in the spec-§8 hello (`req_handshake`'s said/heard leaves) and
     stamp it in the Peeroleum header, so `Peeroleum_deliver` reads incarnation off the frame
      instead of trusting a channel above to have noticed:

- era differs and is **newer** → the peer restarted: reset once, book its seqs fresh —
   one-sided, no two-way seq-reset coordination (the very dance `Peeroleum_reset_handshake`
    keeps its seq cursor to dodge, `Peeroleum.g:1007`).
- era **matches** → same incarnation: the ledger dedups within-era redelivery only — the
   retransmit window, seconds — so §9.2's `RECENT_KEEP`/`DONE_KEEP` coupling stops being
    correctness-critical and demotes to a sizing preference.
- era **absent** → a legacy peer: today's guard, unchanged (the same wire-compat stance the
   `page.pub` rename took — never break an older peer).

**The design note that makes "a hashed timestamp" subtle: the era needs an ORDER, not just
 inequality.** `Swarm_note_era` fires on ANY change (`Swarm.g:775` — `peer_era !== sf.era`), so
  one delayed frame still carrying the old era re-notes it, and the next fresh frame reads as a
   SECOND rebirth — a spurious double reset (latent, not observed; FIFO sockets make it rare).
    A comparable era — the raw ms timestamp — fixes this for free: only *newer* means reborn,
     older means a stale frame to ignore. A pure hash throws the order away. If fixed width or
      clock-opacity is wanted, carry the hash BESIDE the comparable part
       (`era: <boot_ms>, era_h: sha256(pub+boot_ms)`), never instead of it.

---

## 6. Already landed (2026-08-05), for context

- **The O(N²) landing write.** `createWritable({keepExistingData:true})` copies the whole existing
   file into a `.crswap` sibling on *every* open, so an N-chunk file copied N²/2 chunks of bytes.
    A 65MB track took **180.2s** to write; the `land` electrode showed `wr:31080ms` against
     `wire:397ms` on a 27MB track. Fixed with a held writer (`bin_writer` in `Housing.svelte.ts` /
      `WormholeOpfs` / `RemoteWormholeNav` + the four session ops in `LiesFunk.svelte`): one empty
       swap, positional writes, one commit. Measured after: **19 ms/chunk at 50MB**, ~28× on the
        65MB case. The lock discipline rides with it: `Heist_writer_drop` (`Heist.g:288`) releases
         the held writer on every non-commit exit, because an un-aborted writable keeps an
          exclusive FSA lock and poisons every later attempt at that path until reload.
- **The memcpy tax on every beat.** `Ra_pull_beat` and `Ra_stage` built a full `Ra_chunk_map`
   per beat purely to test presence — and that map *copies* every held chunk not already a
    Uint8Array. Mid-heist that is tens of MB memcpy'd per second: downloader CPU burn plus GC
     churn hard enough to drop wire frames, which then masqueraded as a network problem. Now
      `Ra_chunk_have` (`Ra.g:1650`), the same walk with presence only, zero copies.
- **The beat can no longer freeze silently, and its overruns are measured.** `share_beat_running`
   is released *before* any instrumentation (`Swarm.g:1598` — a throw after the beat used to
    leave the guard latched and every subsequent tick skipped, the whole heist dead with no
     error), and the `ev:'beat'` electrode traces any beat over 600ms with `ms` + `skips`.
- **The NO PROGRESS watchdog was lying** — a high-water compared against a sawtooth signal, so a
   153-chunk track following a 196-chunk one could never clear the peak and barked through a
    healthy pull. Now compares against the previous value, not the max.
- **Peeroleum CPU melt, both walks.** `Peeroleum_rollup_faulty` (one whole-inbox walk) and
   `Peeroleum_bound_inbox` (three) ran after *every* booked frame, and a 256KB `repli_page` is a
    booked frame — the same O(N²) the 2026-07-29 pass had cured only for `repli_want`. Rollup is
     now gated on `pier.c.faulty_owed` (armed at the one site that stamps an unemit error); bound
      is strided 1-in-50 with `RECENT_KEEP` at 400 to stay clear of `done`'s stride overshoot.
- **The Pier inbox is bounded — a queue with a ledger, not an unbounded producer.** Detail in
   `Repli_design.md §8–9`: `DONE_KEEP=200` whittles served `%req:unemit`s, each promoted through
    the one path (`Peeroleum_inbox_ledger`) onto `%inbox/recent` so the reused-seq guard keeps
     its memory (`Peeroleum_served_before` consults the ledger *before* booking); a 2000-row
      structural backstop sheds oldest regardless. A throwing sweep now stamps `%sweep_err` on
       `w` instead of dying into the console. Orphaned `%req:awaitbuf`s are swept; `bufferid`
        rides as a string so it can't trip the `{k:1}` presence wildcard.
- **The re-census heal.** A source-side reload wiped `rummage_libs`/`keep_memo` (both `.c`), so a
   resumed heist re-asked every 4s forever against a source that could no longer resolve the
    keep-ids — silent without the trace (`asked:9 landed:0`). Now 3 unanswered asks re-send the
     DESCRIBE (throttled 20s, `Heist.g:1649`); keep-ids are deterministic so the standing picks
      resolve again in one round trip. Proper fix owed: durable `keep_memo` (the Dexie↔`.jamsend`
       sync item in `Heist_todo.md §0`).

## 6.1 Ruled out — do not re-derive

- **Short tail pages are NOT a park bug on the heist path.** `Repli_page_ready`'s particle branch
   clamps `end = Math.min(from + PAGE, total)`, so a short final page serves normally. The
    `rec.c.chunks` (transcode/opus) branch *does* hold a short tail page until
     `chunks.length >= nchunks` — correct by design, but it means a stalled encoder parks the tail
      **forever**, which is what the `◈⚠ transcode STALLED` warning reports.
- **The 16MB ask window is not the bottleneck** (§1.1). The issue rate is.
- **"Nothing measures throughput" is no longer true and was over-claimed here** — the wire rate
   graph exists (§5.2). The true gap is goodput attribution and a consumer.

---

## 7. Questions — RULED ON by the human, 2026-08-05 evening

These were open when the doc was written. They are now decided; a reviewer should build on
 them, not re-open them. The reasoning is recorded because each ruling closes a design branch.

**7.1 The retransmit timer: an ambient tick, not a ttlilt. RULED.**
 `req:Ask` stays **unfinished** while any hole is outstanding, and the **existing ambient beat**
  re-drives it — there is no need for a per-req timer primitive at all. Each time the pump reaches
   an unfinished `req:Ask`, it asks: *is anything outstanding past its RTO?* If yes, re-issue; if
    no, return still-unfinished. The beat's own cadence is the retransmit clock's resolution, and
     an RTO longer than the beat needs nothing else. This dissolves §4.3's load-bearing unknown:
      **there was never a gap** — "what re-drives an asker with no arrivals" is answered by the
       thing that already drives every other req.
 *Direction (not v1.0):* the human notes **a ttlilt may one day want to become think|retry
  causal** — i.e. a hold that genuinely re-fires rather than only advising the snapper. If that
   lands, this becomes a one-line simplification. Do not pre-build for it.

**7.2 `req:Land` and `req:Ask` do not face off on `maz`. RULED — plain siblings, same level.**
 The LiesStore precedent (IO *above* its consumers) does not apply, because there is no
  read-your-writes hazard to order around: **anything we Ask for is already sanitised by what we
   have Landed** — the ask is computed from the chunk map, so a landed chunk simply is not in the
    hole set. Stronger still, per record the two never overlap in time: `req:Land,id` only exists
     once that record is complete, at which point `req:Ask,id` has nothing left to ask for. Across
      records they are independent. So they are order-independent siblings and §4.2's shape stands
       as written, now on an argument rather than an assumption.

**7.3 The inbox drain keeps its handling and verifying. RULED — and I was overstating the
 problem.** Checking `Peeroleum.g` against the concern retired most of it:
 - **The serialisation is load-bearing and stays.** `inbox.do()` runs each `req:unemit`'s do_fn
    one at a time in arrival order, awaiting each (`Peeroleum.g:619-621`) — *"Awaiting keeps the
     delivery path serial, which is what the rest of it assumes"* (`:603`). Handling and verifying
      belong exactly where they are.
 - **sha256 is not main-thread work.** `Peeroleum_body_digest` is `crypto.subtle.digest`, native
    and async (`Peeroleum.g:186`); the whole delivery path awaits it. The FNV-1a digest that once
     stood there *was* synchronous, and going async is what dissolved that constraint (`:181`).
      My §7.3 premise was stale by one landing.
 - **Control frames already bypass the inbox entirely.** An ack "never enters the inbox or a
    `hear_*` handler" (`:497`), and `repli_want` bypasses too (`:611-615`). So the head-of-line
     risk on ingress is far narrower than §3.3's egress twin: pages behind pages, and hello/app
      frames behind pages. No pong is at stake here.
 What genuinely remains is **not an inbox-shape problem**: the drain runs inside the beliefs
  mutex / Atime (`:179-180`), so a burst of pages holds the world's tick for the length of the
   burst. That is the *same* defect as §5.8 (byte work on the C tree's critical section) and is
    fixed there. **No separate pass. Do not restructure the drain.**

**7.4 Per-peer fairness on the relay trunk: OUT OF SCOPE. RULED.**
 Ship v1.0. §5.1's bulk queue is a single FIFO; do not pre-build round-robin. (When a second
  concurrent peer transfer becomes real, the retrofit is local to the bulk lane.)

**7.5 `%Heist` stops carrying transport state in `state`. RULED — the req pile owns it.**
 `state` keeps only what the human is looking at (`choosing`/`primed` — UI form-state); the
  transport half (`pulling`/`done`) moves onto the reqs, which is the better place for it.
   The general principle the human states, worth carrying past this doc: **`req` can take the
    business end of a lot of the model — it is a better place for state than a string on a
     particle**, because a req carries its own liveness (`needs_work`), its own hold, and its own
      pump, where a string carries only an assertion that something once set it.

 *Where exactly the form-state lives (the human, 2026-08-05, later): **on the `%Heist` itself,
  where it already is** — `state:choosing|primed` stays on the intent particle, because that is
   the particle HeistFace dresses (mainkey-imposed, `glass_faces.ts`) and the split criterion is
    **presentability**: what the human looks at and acts on rides the data the face reads;
     "req is the less user-presentable side of things." Not on the `%Caper` job — it does not
      exist during choosing and is pure transport — and not on the `%HeistBar` (`dontSnap`;
       form-state should snap). One edge for §5.4 to mind: the done-✓ lingers ~8s on the face
        today off `state:'done'`. Once transport state is req-shaped, that linger still needs
         something face-readable — a brief `done:1` stamp on the `%Heist` (snapped-boolean rules:
          `1` or absent, and the heist drops itself soon after) keeps the face honest without
           resurrecting the string.*

---

## 8. Fixture cost

§5.4 changes what a `%Heist` looks like in a snap, so `Heistation` and `Sounditron` need live
 re-records — **from a live runner** (`scripts/runner_ask.mjs`), never `Story_cli_run.mjs`.
  Sequencing note, updated: the `%Keep`→`%Heist` swap has **landed** (2026-08-05) and its fixtures
   are already re-recorded, as has the big Repli/Peeroleum re-record sweep (`Repli_design.md
    §9.6`, 21 Books green). The remaining churn to sequence against is the `%pub`→`fullpub`
     rename (`Heist_todo.md §0.2`), which walks the same Cluster/identity fixtures — land §5.4's
      snap change and that rename as separate reds with one suspect each, not interleaved.

---

## 9. Traps for a fresh reader

The things that cost real time if you don't know them going in.

### 9.1 Peeroleum: the ephemeral set is hard-won, not an oversight

`repli_want`, `pulse`, `ive_got`, `repli_lines`, `repli_page` and `no_protocol` are **ephemeral**
 in `Peeroleum_send` (`Peeroleum.g:395,426`) — no outbox emit, no per-send log. This is not
  laziness: an unbounded `%outbox` culled only on ack **detonated** twice before (the `repli_want`
   storm, then `repli_lines`/`repli_page` killing the deliver pump so the source stopped answering
    at all and every download plateaued mid-track). The file's own comments carry that history.

**Consequence for §5.3.** A new `repli_parked` frame type must be added to *both*:
- the ephemeral set in `Peeroleum_send` — or every park books an outbox emit, which is precisely
   the melt pattern above; and
- the `ambient` map at `Tribunal.g:110`
   (`{ping, pong, ack, repli_want, repli_page, repli_lines, pulse, swarm_hi, advertise}`) — or it
    joins the ~3000 lines/min log flood that had to be gated once already.

Neither is optional, and neither will fail loudly.

### 9.2 Peeroleum: the reused-seq machinery is three mechanisms, and the principled one lives a layer too high

A reborn peer restarts its per-Pier seq at 1, so its frames land on stale finished `%req:unemit`
 rows and die undispatched, unacked — the silent post-reload mute. Three things stand against it,
  and mistaking the first for the design is the trap:

- **The collision guard** — the fallback belt, in `Peeroleum_deliver`: a standing finished unemit
   on the live inbox, plus the `%inbox/recent` ledger `Peeroleum_served_before` consults once the
    bound has culled the req. On a hit: **re-ack, never re-dispatch** (`:646-664`). This is the
     half with the coupled-constants invariant: `RECENT_KEEP` must stay `>=` the done window's
      high-water — `DONE_KEEP + one stride` now that `Peeroleum_bound_inbox` is strided 1-in-50;
       currently 400 vs ~250. Change either number and re-check the other; a too-small `recent`
        opens a silent re-dispatch hole for exactly the frames that just fell out.
- **The epoch, swarm half** — `Swarm_era` + the `saw:` echo on every swarm frame;
   `Swarm_note_era` on a changed era runs `Peeroleum_reset_handshake` so fresh seqs book fresh.
    Converges in ~one pulse round trip (~5s).
- **The epoch, Lies half** — the ping's `boot` page-life id (`LiesLies.svelte:1353`), same reset,
   for the editor↔runner channel. *"The swarm channel's swarm_hi is the twin."*

The guard is not the cure, and the code says so itself: a collision is answered with a re-ack
 while *"the boot-epoch reset … is what re-opens a reborn peer's stream"* (`:651`), and
  *"reconnect-replay dedup on a reliable carrier is the epoch handshake, heading 8 — not a
   cold-start re-baseline smeared on the deliver site"* (`:635`). So read the guard as what holds
    during the seconds before an era/boot change lands — and as the *only* protection on any
     future channel that forgets to re-implement rebirth detection, which is exactly why the
      detection wants to move down into the layer that owns seq. That finished shape — the era
       exchanged in Peeroleum's own hello, seqs scoped to it, the coupling above demoted to a
        sizing preference — is **§5.9**.

### 9.3 The inbox is already a req pile — Peeroleum is exemplar and problem at once

`inbox.do()` is a serial `%req:unemit` drain, so Peeroleum is *inside* the req machine while Heist
 is outside it. But a 256KB page's handling (sha256 verify + particle mint) is main-thread work
  *inside* that drain. Don't read "Peeroleum uses reqs" as "Peeroleum is fine" — see §7.3.

### 9.4 The single-threaded C tree is the floor under everything

The C tree is single-threaded under a mutex; ticks are serialised so a reader sees frozen state.
 **A Worker cannot hold C particles.** Any "just move it to a Worker" proposal has to move *bytes*
  (hash these, write these) and leave the particles on the main thread, reporting back at a seam.
   §5.8 is worded that way deliberately.

### 9.5 Verification: a headless green is a bubble

`scripts/Story_cli_run.mjs` (node+jsdom) has real disk access, loads the GhostList off the
 wormhole, and quiesces at a **different depth** than a live runner — its fixtures match itself and
  go all-red on the real thing. Verify only via a live runner tab on :9091 (`?B=<Book>`) through
   `scripts/runner_ask.mjs`; recorded fixtures must come from there too. Two further traps: not
    every runner the editor lists is usable (some are the human's manual test tabs), and a run can
     settle without leaving `stepping`, which makes `run --watch` block.

### 9.6 Mechanics

- `.g` edits need `npm run ghost-compile -- <path>`; `.svelte`/`.ts` are bundle-proofed by fetching
   `http://172.17.0.1:9091/@fs/app/<path>` for HTTP 200. **`curl` and `python3` are not installed**
    in the container — use `node -e` with `fetch`.
- Vite's dev transform does not type-check, so a 200 does **not** mean the identifier resolves.
   (An unbound `H` in a `this.`-scoped method passed the bundle-proof and had to be caught by
    reading the enclosing scope.)
- `npm run check`'s ~3000 warnings are pre-existing baseline noise and drift run-to-run. Judge an
   edit by grepping the *edited file's* line range, never the total.
- New particles must obey the mainkey law: a thing exists once under a container as its mainkey;
   anything that merely names it elsewhere wears its **own** mainkey (`of:` for many:1). Snapped
    booleans ride as `1` or absent — never `false`/`0`. Never stamp a maybe-undefined sc value.
- **Never stage, commit, or push.** The working tree is dirty by design; the human reviews the diff.
- `_spec` promotion is the human's call. This doc stays `_todo` until they say otherwise.

### 9.7 Sources that will mislead if read as current

`Download_stall_handover.md` is archaeology — the 2026-07-29→30 wedge hunt, much of it superseded
 by fixes that have since landed. Mine it for *reasoning*, not for current state. Same for
  `spec/history/Heist_todo_strata.md`. Current state for the feature is `Heist_todo.md`; for the
   transport, this doc.
