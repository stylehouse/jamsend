# Backpressure_todo.md — making the transfer a req-driven machine with a control loop

The download works and is honest about its bytes. What it does not have is a **closed loop**:
 every knob in it is a constant, every stage shares one 600ms beat, and the signals that exist —
  a live rate graph, drop messages, `ws.bufferedAmount` — are either consumed by no code at all
   or read on the path we don't use. This doc is the plan to fix that shape, not to re-tune the
    constants.

None of this is a new problem. It is flow control and congestion control, a literature forty
 years deep, and each section below names the standard result it is applying — because the failure
  modes here (tail-loss stalls, head-of-line blocking, timeout ambiguity, open-loop pacing) are
   the *canonical* ones, and the cures are known. The work is mapping them onto the C-tree/req
    substrate, not inventing them.

Scope is the transport spine — `Heist` / `Ra` / `Repli` / `Peeroleum` / `Tribunal` / `Swarm`.
 The feature-level Haul story lives in `Heist_todo.md`; the Repli protocol's own shape and its
  2026-08-05 audit is `Repli_design.md`; the 2026-07-29→30 wedge archaeology is
   `Download_stall_handover.md`. None are superseded by this; this is the layer under all three.

---

## 0. Next move (read first)

1. **Egress classes on the relay socket** (§5.1) — smallest, self-contained, independently
    testable, and the likeliest cure for BOTH the reconnect storm and the "looking through the
     album" census stall. Do this first; it needs no refactor.
2. **Close the sensor gap** (§5.2). The wire rate IS measured (the `%Transfer` HUD's up/down
    graph + drop messages — `Repli_meter`). What's missing is per-haul **goodput** and any
     *consumer* of the signal: today the loop is open — a human watches the graph and edits
      constants.
3. **Then the req refactor** (§4) — `%Haul` grows a real req pile so ask and land stop being
    sequential statements in one beat.
4. **§7 is ruled on, not open.** The five design questions were decided by the human on the
    evening of 2026-08-05 — build on them rather than re-opening them. Two carry weight beyond
     this doc: the retransmit timer is **an ambient tick, never a ttlilt** (§7.1), and **`req` is
      a better home for state than a string on a particle** (§7.5).

**Scope: v1.0 in ~38h from 2026-08-05 evening.** That is the frame for every "in scope?" call
 here. §5.1 → §5.3 → §5.4 is the spine; §5.6/§5.7 are refinements that can miss the date;
  §5.9 (era-scoped seqs) is post-v1.0 by design; per-peer trunk fairness is explicitly out
   (§7.4). Do not pre-build for anything ruled out.

**The arc:** one serial polling beat → three concurrent pumps under one host, with a measured
 control loop, explicit signals where today there are only timeouts, and a wire that never
  starves control frames behind bulk.

*(Facts below re-verified against the working tree the evening of 2026-08-05, after the `%Keep`→
 `%Haul` rename and the day's Repli/Peeroleum landings. §6 records what landed; the defects in §3
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
| Heist | `%Haul` `state` string, polled | the 600ms beat |
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

## 3. The three defects this shape produces

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

## 4. The refactor: `%Haul` grows a req pile

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

### 4.2 The proposed shape

```
%Haul,seed,pub
  req:Haul          maz high, eternal      the pump — replaces the Heist_keep_step call
    req:Census                             the describe/rummage ask (own RTO, own hold)
    req:Ask,id                             one per record in flight — issues wants, never blocks
    req:Land,id                            one per landing — holds the writer, never awaited inline
  Pick,ref …                               unchanged; the plan/ledger, CONSULTED not piled under
```

`req:Ask` and `req:Land` are **siblings**, so one `do()` pass reaches both. A landing in flight no
 longer stops the asker.

**Who pumps it:** the existing share beat, unchanged as the ambient tick (§7.1) —
 `Heist_keep_beat` thins to `keep.do()` per haul (plus its source-side housekeeping), and the
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

- **Goodput attribution.** The graph is wire throughput; nothing measures per-haul *goodput*
   (bytes landed ÷ time) or the efficiency ratio between them. Duplicate asks, re-serves and
    breach-refused pages are invisible as waste — the graph goes *up* while the transfer gets
     *worse*. Marks already exist at both ends (`Ra_pull_beat`'s pulls, `Repli_serve_want`'s
      serves); the missing piece is landed-bytes per haul over time, and wants-issued vs
       pages-landed per beat.
- **A consumer.** No code reads any rate. Every knob in §1 is open-loop — constants tuned for
   one operating point, with a human watching the graph as the feedback path. §5.5 and §5.6 are
    the consumers; this stage is the prerequisite that makes them judgeable rather than vibes.

*Prove:* all runtime `.c`, no snap byte — so no fixture moves and no Book gates it. The proof is
 the HUD showing a per-haul goodput number beside the wire rate, and `runner_ask.mjs world`
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
`%Haul` grows `req:Haul` with `req:Census` / `req:Ask,id` / `req:Land,id` siblings. Landing leaves
 the beat. Watch §4.4.

*Prove:* the one stage that moves snaps — `%Haul` grows req children, so `Heistation` and
 `Sounditron` re-record from a live runner (§8). Use the claim-set diff gate (`Repli_design.md
  §9.6`): fixture bytes may move freely, but refuse the accept if any `witnessed:`/`see:` claim
   changes. The live proof of the actual point — landing no longer blocks asking — is the
    `ev:'beat'` electrode: during a big track's land, `skips` must stay ~0 and the *other*
     in-flight track's pulls must keep advancing, where today the beat logs `ms:30000+` stalls.

**LANDED 2026-08-06 — narrower than the §4.2 shape, on purpose.** The full `req:Haul`/`req:Census`/
 `req:Ask,id` ceremony is NOT built. What shipped is the one thing actually measured broken
  (§3.1) — `Heist_keep_step`'s `state:'pulling'` branch no longer `await`s `Heist_land` inline —
   using `this.expecting(w, name, secs, async_fn)` (`Hovercraft.svelte`), the SAME "issue, return,
    complete via continuation" primitive already proven elsewhere (`Story_demand_audio`,
     `Musu_gen_testsounds`, every `rachase_*`/`buddy_*` Book stage) rather than hand-rolling a new
      `req:Land,id` shape. It IS a req underneath (`w.oai({req:name})`, ttlilt-held, finishing via
       `reqyoncile` — Coding_guide's hold-not-wake rule, honoured for free) — just not one wearing
        the `%Haul` parent §4.2 sketched. The ask/census side (`pick.c.ask_ts` throttling,
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
    `%Haul` and `Heist_keep_forget` wipes the Berth entry). `Heist_keep_persist`'s Berth write is
     `oai` — find-or-create — so an unguarded stale continuation would have **resurrected the very
      entry the cancel just deleted**. The fix: re-check `shop.o({Haul:1, seed:...})[0] === keep`
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

### 5.6 A window that breathes
Replace the constant `B` with a byte window under **AIMD** — additive increase on timely arrival,
 multiplicative decrease (halve) on RTO, floor ~2 pages — the Chiu-Jain result being that AIMD is
  the increase/decrease pair that converges to fair and efficient sharing, which starts to matter
   the day two hauls share one uplink. And clock issuance on **arrival** as well as the beat:
    self-clocking, the ack-clock that lets a transfer run at wire speed between beats instead of
     at `window ÷ 600ms`. This is where "push against the limit slightly all the time" actually
      lives. (A rate-based alternative — pace directly off §5.2's measured delivery rate,
       BBR-style, with the window as backstop — is worth a paragraph in review; AIMD is the
        simpler first loop and the signals it needs exist after 5.1.)

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

**7.5 `%Haul` stops carrying transport state in `state`. RULED — the req pile owns it.**
 `state` keeps only what the human is looking at (`choosing`/`primed` — UI form-state); the
  transport half (`pulling`/`done`) moves onto the reqs, which is the better place for it.
   The general principle the human states, worth carrying past this doc: **`req` can take the
    business end of a lot of the model — it is a better place for state than a string on a
     particle**, because a req carries its own liveness (`needs_work`), its own hold, and its own
      pump, where a string carries only an assertion that something once set it.

 *Where exactly the form-state lives (the human, 2026-08-05, later): **on the `%Haul` itself,
  where it already is** — `state:choosing|primed` stays on the intent particle, because that is
   the particle HaulFace dresses (mainkey-imposed, `glass_faces.ts`) and the split criterion is
    **presentability**: what the human looks at and acts on rides the data the face reads;
     "req is the less user-presentable side of things." Not on the `%Heist` job — it does not
      exist during choosing and is pure transport — and not on the `%HaulBar` (`dontSnap`;
       form-state should snap). One edge for §5.4 to mind: the done-✓ lingers ~8s on the face
        today off `state:'done'`. Once transport state is req-shaped, that linger still needs
         something face-readable — a brief `done:1` stamp on the `%Haul` (snapped-boolean rules:
          `1` or absent, and the haul drops itself soon after) keeps the face honest without
           resurrecting the string.*

---

## 8. Fixture cost

§5.4 changes what a `%Haul` looks like in a snap, so `Heistation` and `Sounditron` need live
 re-records — **from a live runner** (`scripts/runner_ask.mjs`), never `Story_cli_run.mjs`.
  Sequencing note, updated: the `%Keep`→`%Haul` swap has **landed** (2026-08-05) and its fixtures
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
