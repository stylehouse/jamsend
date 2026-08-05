# Backpressure_todo.md — making the transfer a req-driven machine with a control loop

The download works and is honest about its bytes. What it does not have is a **clock it can
 trust** or a **loop that listens**. Every rate in it is a constant, every stage shares one
  600ms beat, and the one signal the OS offers us (`ws.bufferedAmount`) is read on the path we
   don't use and ignored on the path we do. This doc is the plan to fix that shape, not to
    re-tune the constants.

Scope is the transport spine — `Heist` / `Ra` / `Repli` / `Peeroleum` / `Tribunal` / `Swarm`.
 The feature-level Haul story lives in `Heist_todo.md`; the 2026-07-29→30 wedge archaeology is
  `Download_stall_handover.md`. Neither is superseded by this; this is the layer under both.

---

## 0. Next move (read first)

1. **Egress classes on the relay socket** (§5.1) — smallest, self-contained, independently
    testable, and the likeliest cure for BOTH the reconnect storm and the "looking through the
     album" census stall. Do this first; it needs no refactor.
2. **Measure bytes/sec** (§5.2). Nothing in the system measures throughput today. Without it
    every later stage is judged on vibes.
3. **Then the req refactor** (§4) — `%Haul` grows a real req pile so ask and land stop being
    sequential statements in one beat.
4. **This doc wants a second reader before §4 is built.** The open questions are §7.

**The arc:** one serial polling beat → three concurrent pumps under one host, with a measured
 control loop and a wire that never starves control frames behind bulk.

---

## 1. What is actually there now (measured, 2026-08-05)

| knob | value | where |
|---|---|---|
| share beat cadence | **600ms** | `Swarm.g` `Swarm_share_loop`, `setTimeout(tick, 600)` |
| wants issued per beat per record | **6** | `Ra.g` `heist_want_budget` |
| chunks per want (a "page") | **2** | `repli_page`, `Repli_serve_want` `end = min(from+PAGE, …)` |
| chunk size | **256KB** | `Heist.g:32` `return 262144` |
| ask window (`LEAD`) | **32 missing pages** ≈ 16MB | `Ra.g` `heist_want_lead` |
| re-ask timer | **fixed 4s** per (id, offset) | `Ra.g` `ra_want_ts` |
| tracks in flight | **2**, 2nd opens within 24 chunks of done | `heist_inflight` / `heist_overlap` |
| breach cooldown | 5s | `heist_breach_cooldown` |
| relay heartbeat reaper | **15s** miss → terminate | `src/lib/server/relay.ts:543` |

### 1.1 The issue-rate ceiling

```
6 wants/beat × 2 chunks × 256KB ÷ 0.6s  =  5 MB/s   per record
```

Hard ceiling regardless of path capacity. Two records in flight → 10MB/s aggregate. The
 **window** (16MB outstanding) is generous and is *not* what binds — the *issue rate* is. On
  local-local, where the wire is a memcpy through a node process on the same box, we are asking
   at 5MB/s and wondering why it is slow. A 65MB flac is ~13s of pure ask-pacing before anything
    else goes wrong.

This matters for the review: **the first instinct — "open the window" — is wrong.** The window
 is already wide. The rate at which we may *issue* into it is the throttle.

---

## 2. The three clocks

One download crosses three scheduling disciplines that do not know about each other:

| stage | discipline | clock |
|---|---|---|
| Peeroleum inbox | serial `%req:unemit` drain (`inbox.do()`) | frame arrival |
| Heist | `%Haul` `state` string, polled | the 600ms beat |
| Repli park/unpark | event-driven demand (`%parked_want`) | producer frontier |

They all funnel onto one thread and mostly onto that one beat. **The beat is a barrier, not a
 scheduler.** `share_beat_running` skips a tick while the previous beat is in flight, so the
  system's effective clock rate is `max(600ms, slowest thing that ran)`. A slow stage does not
   degrade itself — it halts every stage.

`Swarm.g` already knows this and says so in its own comment: *"a long landing steals the very
 window the OVERLAP pre-ask needed."*

**Surprise worth flagging: `Heist.g` contains no reqs at all.** A grep for req usage across all
 29 `.g` files ranks `Peeroleum` 39, `Radiola` 22, `Tyrant` 18, `Repli` 5 — and `Heist` **0**.
  The heist is a hand-rolled beat with a state string, entirely outside the req machine, while
   every neighbour it talks to is inside it.

---

## 3. The three defects this shape produces

### 3.1 The tail stall ("still a bit stally at the end")

Two things compound at the end of a track, both structural:

- **The window is empty by construction at the tail.** Mid-track a lost page is invisible —
   30 other pages are in flight and bytes keep landing while the hole waits out its 4s. At the
    tail there is nothing ahead to ask for, only holes behind. The remaining time is *pure*
     timeout: each surviving hole costs a full 4s, serially, with the wire idle. This is the
      classic TCP tail-loss problem, which needed two separate mechanisms (fast retransmit off
       dup-acks, then Tail Loss Probe) precisely because a timer alone is this bad. We have
        neither, and the RTO is a constant.
- **The landing is a stop-the-world barrier fired at exactly that moment.** `Heist.g:1687`
   `await this.Heist_land(...)` is inline on the beat. The instant a track completes, the beat
    blocks for the whole write + read-back + sha256, and every 600ms tick is skipped meanwhile.
     During that window the *other* in-flight track issues zero wants, the re-ask timer does not
      run, the parked-want pump does not run, the census ask does not go out. `heist_overlap`=24
       exists to hide the handoff gap, but the landing barrier is far larger than the overlap can
        cover.

So the tail is where loss recovery is at its worst *and* where we schedule the longest blocking
 operation. The crswap fix (§6) shrank the second one ~28×, which is why it went from "stalls"
  to "a bit stally".

### 3.2 The sink is blind to why a want went unanswered

`Repli_park_want` (`Repli.g:476`) mints a source-local `%parked_want` and **replies nothing**.
 `Repli_serve_miss` is a `console.warn` on the *source's* tab. So the sink cannot distinguish:

| truth | right response |
|---|---|
| want lost on the wire | retransmit **now** |
| source parked it behind its transcode frontier | **wait**, stop spending budget |
| source has no record for that id | give up, **re-census** |

Three states wanting opposite responses, collapsed into one 4s timer. The observed
 `◈⚠ transcode STALLED — parked want id=794aa24e… waiting 20s…118s` is the source *knowing* the
  answer for two minutes while the sink re-asked ~30 times. Not a tuning gap — a missing message.

### 3.3 No send-side backpressure, and it costs the connection

`Tribunal.g:97` sends bare:

```
let wire = (frame) => { if (frame && frame.buffer) ws.send(encode_binary(frame)) else ws.send(JSON.stringify(frame)) }
```

`ping`/`pong`, acks, `repli_want`, census/describe replies and 256KB `repli_page` frames all
 share one socket with no gating. A queued page delays a pong; `relay.ts:543` terminates any
  socket that missed one inside 15s. **The missing backpressure does not merely waste memory —
   it kills the connection**, which is the observed `code=1006` → Piers gone → `no Pier … DROPPED`
    flood → desync. `bufferedAmount` *is* read, but only for the WebRTC datachannel
     (`Peerily.svelte.ts:602,609`) — the relay path, which is what local-local uses, reads nothing.

This is also a live suspect for the "looking through the album" census stall: the describe reply
 is a small frame queued behind 256KB pages, and if the socket is reaped mid-flight it is gone.

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

### 4.3 The discipline that makes it actually concurrent

This is the part a reviewer should press hardest on, because getting it wrong buys nothing.

**`do()` is serial.** Moving the heist onto reqs does *not* by itself fix blocking: if
 `req_Land`'s do_fn `await`s the whole write, siblings still block exactly as they do today. The
  rule is:

> A long operation is **kicked off**, and its req **stays unfinished** and returns.
> Completion arrives out of time via `reqyoncile`.

`Housing.svelte.ts:2210/2275` already uses this shape for IO
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

`req:Ask`'s retransmit timer is the one place a ttlilt is arguably right (a genuine "come back in
 ~N ms"), but per the rule above, prefer deriving the wake from arrival and keep the req unfinished
  while any hole is outstanding. **See §7.1 — this is an open question.**

### 4.4 What must not regress

`pick.sc.landed` and `Heist_keep_persist` are stamped immediately after the awaited `Heist_land`
 (`Heist.g:1688`). Once the landing is no longer awaited inline, **they must move into the
  completion seam** or the ledger claims a file that is not yet on disk — and Berth would resume
   as if it were. This is the single highest-risk edit in the refactor.

---

## 5. Staged plan

Each stage is independently landable and independently testable.

### 5.1 Egress classes on the relay socket  *(no refactor needed — do first)*
Split `Tribunal.g`'s `wire` into two lanes:
- **express** — `ping`/`pong`/`ack`/`hello`/census/describe/`repli_want`: sent unconditionally,
   never behind bulk.
- **bulk** — `repli_page`/`repli_lines`: sent only while `ws.bufferedAmount < HIGH`, else queued
   locally and flushed as it drains.

Fixes pong starvation → the 15s reaper → the reconnects; stops describe replies queueing behind
 pages; and gives us the **first genuine congestion signal on the path we actually use.**

### 5.2 Measure throughput at both ends
A rate on the existing `%Transfer` HUD, off the marks already in `Ra_pull_beat` /
 `Repli_serve_want`. Prerequisite for judging 5.4–5.6.

### 5.3 Signal a park back to the sink
A tiny `repli_parked` reply from `Repli_park_want`, so the sink can distinguish parked from lost
 and stop burning budget on an offset the source has already promised. Cheap, and it is missing
  *information* — which usually beats better tuning.

### 5.4 The req refactor (§4)
`%Haul` grows `req:Haul` with `req:Census` / `req:Ask,id` / `req:Land,id` siblings. Landing leaves
 the beat. Watch §4.4.

### 5.5 Measured RTO + tail probe
Replace the fixed 4s with `srtt`/`rttvar` EWMA → `RTO = srtt + 4·rttvar`, floor ~250ms, plus a
 tail probe so the last few holes retry on RTT rather than on a constant. Lands cleanly only after
  5.4, because before that the beat lies about time.

### 5.6 A window that breathes
Replace the constant `B` with a byte window under AIMD: additive increase on timely arrival,
 halve on RTO, floor ~2 pages. Clock issuance on **arrival** as well as the beat. This is where
  "push against the limit slightly all the time" actually lives.

### 5.7 Negotiated chunk size
256KB is fixed everywhere. Once control has an express lane, head-of-line is no longer an argument
 against big frames and local-local wants 1–4MB; a slow remote wants 64KB. Pointless before 5.1.

### 5.8 Get the byte work off the C tree's critical section
The deepest constraint: **the C tree is single-threaded under a mutex and we do second-scale byte
 work inside it.** `Heist_land` holds it for seconds; `Heist_materialise_one`'s whole-file
  `read_range(dir, filename, 0)` held it for 21s (`pcm-read ms:21264`). Same root as the missed
   pong. Windowed materialise first (the read already takes a window — same shape as the write
    fix), then ideally sha256 + FSA writes into a Worker.

---

## 6. Already landed (2026-08-05), for context

- **The O(N²) landing write.** `createWritable({keepExistingData:true})` copies the whole existing
   file into a `.crswap` sibling on *every* open, so an N-chunk file copied N²/2 chunks of bytes.
    A 65MB track took **180.2s** to write. Fixed with a held writer (`bin_writer` in
     `Housing.svelte.ts` / `WormholeOpfs` / `RemoteWormholeNav` + the four session ops in
      `LiesFunk.svelte`): one empty swap, positional writes, one commit. Measured after:
       **19 ms/chunk at 50MB**, ~28× on the 65MB case.
- **The NO PROGRESS watchdog was lying** — a high-water compared against a sawtooth signal, so a
   153-chunk track following a 196-chunk one could never clear the peak and barked through a
    healthy pull. Now compares against the previous value, not the max.
- **Peeroleum CPU melt** — `Peeroleum_rollup_faulty` (one whole-inbox walk) and
   `Peeroleum_bound_inbox` (three) ran after *every* booked frame, and a 256KB `repli_page` is a
    booked frame. The code's own comment documented this melt but had only cured it for
     `repli_want`. Rollup is now gated on `pier.c.faulty_owed`; bound is strided 1-in-50 with
      `RECENT_KEEP` raised to 400 to keep `recent >= done`'s stride overshoot.

## 6.1 Ruled out — do not re-derive

- **Short tail pages are NOT a park bug on the heist path.** `Repli_page_ready`'s particle branch
   clamps `end = Math.min(from + PAGE, total)`, so a short final page serves normally. The
    `rec.c.chunks` (transcode/opus) branch *does* hold a short tail page until
     `chunks.length >= nchunks` — correct by design, but it means a stalled encoder parks the tail
      **forever**, which is what the `◈⚠ transcode STALLED` warning reports.
- **The 16MB ask window is not the bottleneck** (§1.1). The issue rate is.

---

## 7. Open questions for review

1. **Is a ttlilt ever right for `req:Ask`'s retransmit timer?** `Coding_guide.md` says prefer an
    unfinished req, and says a ttlilt is not a keep-alive and does not re-fire a think — so what
     re-drives an asker that is waiting out an RTO with no arrivals? The ambient tick? A `%Haul`
      that stays unfinished and relies on `feebly_ponder`? This is the load-bearing unknown in §4.3.
2. **Does `req:Land` want `maz` above or below `req:Ask`?** LiesStore puts IO *above* its
    consumers (`maz:7` vs Cortex `maz:5`) so the consumer sees settled IO. Here the argument may
     invert: asking is latency-critical and landing is throughput-critical.
3. **Should the inbox drain gain the same treatment?** Peeroleum's `inbox.do()` is already a serial
    req drain, but a 256KB page's handling (sha256 verify + particle mint) is main-thread work
     inside it. Same class of problem, different ghost — in scope or a separate pass?
4. **Per-peer fairness on the relay trunk** is entirely absent. Out of scope here, or does 5.1's
    queue want to be per-peer from the start rather than retrofitted?
5. **Does 5.4 want `%Haul` to stop carrying a `state` string?** It currently does double duty —
    UI form-state (`choosing`/`primed`) and transport state (`pulling`/`done`). The req pile
     arguably owns the second half, leaving `state` purely about what the human is looking at.

---

## 8. Fixture cost

§5.4 changes what a `%Haul` looks like in a snap, so `Heistation` and `Sounditron` need live
 re-records — **from a live runner** (`scripts/runner_ask.mjs`), never `Story_cli_run.mjs`. Worth
  sequencing against the pending `%Haul`/`%Heist` swap and the `%pub`→`fullpub` rename in
   `Heist_todo.md §0`, which churn the same fixtures; three separate churns of the same files is
    two too many.
