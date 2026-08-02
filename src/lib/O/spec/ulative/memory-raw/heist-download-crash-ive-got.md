---
name: heist-download-crash-ive-got
description: heist download saga — crash/CPU/memory-wall FIXED+live-confirmed; Heist_keep_pull is DEAD CODE (the live pull loop is Heist_keep_step's inline 'pulling' branch) — resume_sync+breach-cooldown were built into the dead one first, now correctly wired live; breach root cause still unknown
metadata: 
  node_type: memory
  type: project
  originSessionId: 756959e9-7fe3-49d5-b858-18de4576c696
---

The p2p heist **download** stall was TWO bugs, the first hiding the second.

**Bug 1 (fixed): the ive_got crash.** `ive_got` (Swarm_gossip_music's shelf boast) booked one reliability
 `%emit` per beat in the Pier `%outbox`, culled only on ack; against a busy never-acking peer it climbed to
  6036 LIVE rows → "giant stuff" throw in `Swarm_deliver` → deliver pump dies → source stops serving → every
   download plateaus mid-track. FIX: `ive_got` (and `no_protocol`) made ephemeral in `Peeroleum_send`.
    3rd unbounded-`%outbox` instance after [[stream-continuation-starve-fix]] and [[drop-leaves-index-giant-stuff]].

**Bug 2 (root cause found, fix landed, NOT yet live-confirmed): a SILENT per-frame no-ack.** With the crash
 gone the download STILL stalled at `landed_n=0`. Two agents converged: the ack fires ONLY on `req_unemit`'s
  SUCCESS branch (`Peeroleum.g` ~707); the failure branch (~713) sets `req.sc.error` and **draws no ack, logs
   nothing**. `ok` is cleared by a `bad-body-hash` on a 256KB `repli_page`, a startup gate, OR a handler throw
    (real vector: `Repli_merge` delete → `replace()` in a do_fn → [[nested-replace-in-do-fn]] throw → permanent
     inbox WEDGE). **The exact trigger CANNOT be pinned from a snap — it's silent — so the fix is instrument-
      first, not guess.** And with NO live retx sweep (`Peeroleum_arm_whittle` is Book-only), a "reliable"
       repli emit is retransmitted by nothing — it just piles the outbox until the backstop drops REAL bytes.

**FIX A (2026-07-29, uncommitted): `repli_lines`/`repli_page` made EPHEMERAL** (5th unbounded-outbox instance).
 The PULL self-heals (Ra 4s re-ask; frontier = bytes-present via Ra_chunk_map), delivery is idempotent
  (upsert-by-loc + stash-by-bufferid + RUNG-0 cid gate), `rec.c.sent` advances at SEND time, nothing reads the
   emit's `%acked`. Removes the flood + backstop-drops-real-data. COST: re-record SwarmShare(005-009) +
    MusuReco(005-011) — vanishing source-outbox `emit,type:repli_lines` rows the Books don't gate on (needs a
     live runner — DEFERRED).

**Loud instrumentation landed same night** (all `.g`, compiled): the loud no-ack (`req_unemit` error branch
 shouts `🛰⚠ unemit NOT acked …<reason>`, quiet on the designed pre-Ud/startup-hold hold — THE diagnostic
  unlock), L1 sink-side heist watchdog (`Heist.g` pulling branch: `⇊ heist STARTED` + `⇊⚠ heist NO PROGRESS
   15s` — per-KEEP, because Ra's per-record stall warn is gated on held>0 which landed_n=0 never trips), A#4
    no-Pier drop warn, L2 `Radio.g:474` transcode-throw warn, A#5 consent-refused via Repli_serve_miss.

**Also fixed (Evening 3):** native materialise hashing (`sha256_hex_fast` in Hashly.ts, byte-identical) killed
 the 5.5s pure-JS-sha256 CPU freeze per file. WebCrypto is async-only, so it's a HYBRID — native for bulk-await
  paths, noble-sync stays for the dige/small-input sync callers ([[instrument-before-guessing]] has the "don't
   demand WebCrypto globally" reasoning).

**THE OPEN WALL (Evening 4, un-fixed — the current bug):** the heist pulls EVERY track in PARALLEL
 (`Heist_keep_step` loops ALL Picks → `Ra_pull_beat` each) and the SOURCE `Heist_materialise_one`s them all,
  holding every chunk's `b.sc.buf` (~25MB/track × 13 → 3GB with serve-copies). 3GB → GC thrash → ws 1006
   reconnect storm → line/page split → `◈✗ no awaiter, bytes dropped` → `landed_n=0` forever. The human: "doing
    every track in parallel or holding more than a reasonable amount of the music = wrong." FIX = serialize to
     ~1 track (+ a few-sec overlap to hide ask-latency) AND RELEASE a track's bufs after it lands (rummage_libs
      caps count, never releases bytes). ws send-buffer is ALREADY bounded (Tribunal ~124) — NOT the 3GB.

**PLAN A LANDED (Evening 5, 2026-07-29 late — all .g, LocalGen compile-green, gen verified, UNCOMMITTED; NOT
 yet live-verified — that's the human's, become_book would hijack their heist).** Full write-up in
  `spec/Download_stall_handover.md` "Evening 5". Four code-verified traps shaped it: (1) `Heist_has_body` counts
   PARTICLES not bytes, so a buf-only release slips materialise's idempotence gate → wedge — **release DROPS the
    body particles** (new `Heist_release_rec`); (2) `Heist_body_new` is bare `i()`, so re-materialise over
     surviving particles DUPLICATES seqs — same conclusion; (3) the `no awaiter — bytes dropped` warn LIED
      (`Repli_recv_page` stashes before reconciling; page-before-lines self-heals) — reworded + capped
       `pier.c.bufs`; (4) a sink-side re-ask heal is DEAD (`ask.c.answers>=3` cap) — healed SOURCE-side via the
        parked-want→re-materialise producer. **Built: A1** sink in-flight window (`heist_inflight`2/`heist_overlap`24,
         bench a wedged pick, watchdog counts Σheld re-baselined on progress) **+ A2** `Heist_keep_beat` release
          (`sent>=total`+want-idle 20s, 256MB belt, lib TTL 30min, `want_ts` stamp) **+ A3** `Ra_transcode_pump`
           parked producer **+ A4** orphan hygiene. **No re-record expected** (MusuHeist drives `Heist_beat` not
            `Heist_keep_step`; RummageLib `dontSnap`).

**LIVE-CONFIRMED (2026-07-30):** the human's two live tabs pulled `He Lays in the Reins 12/95 → 95/95 ✓` and the
 SOURCE logged `◈↯ freed He Lays in the Reins (95 chunks) — served, bytes released` — A1 pull + A2 release WORK
  live. The 3GB/nothing-lands wall is GONE. REMAINING wall: an `ive_got` GOSSIP FLOOD (hundreds of frames,
   Swarm_gossip_music re-boasting ~every beat — ephemeral so no outbox leak, but the VOLUME pressures the ws) →
    `ws CLOSE 1006` → the next chunk's `repli_want` DROPPED on the torn socket (`🛰⚠ deliver: no Pier for
     repli_want … DROPPED`) → the "next piece hasn't arrived" stall (4s re-ask heals it, but janky). FIX (next,
      prove first): throttle `ive_got` to on-shelf-change / every-N-seconds, not per beat.

**TRANSFER HUD built (2026-07-30, the human "I keep wanting more transfer visual feedback but I don't see any"):**
 a shared `top_House().c.xfer` telemetry (rates+rx spark from Repli_meter, active pulls from Ra_pull_beat, serves
  from Repli_serve_chunks, freed from Heist_release_rec, DROPS+last_drop from Peeroleum_deliver's no-Pier path) —
   all runtime `.c`, no snap. Surfaced in `runner_ask world` as `xfer` AND rendered by a new `ui/TransferFace.svelte`
    (jiggling rx/tx bars + sparkline + per-track pull/serve progress + freed + a RED "N frames dropped — next piece
     being lost" tell). A persistent `dontSnap %Transfer` cell minted in `Heist_keep_beat` on the radio world,
      imposed by mainkey (glass_kinds/glass_faces). **Grapple bug found+fixed same night:** the cell was dressed
       (FACE_MAINKEYS) but never added to `Sounditron_commission`'s `grapples` array — Vyto only draws grappled
        cells (`%Machine`'s fate is the standing example) — so it rendered nowhere until wired in as an always-on
         organ alongside Radio/Tuner. Needs a hard reload to appear.

**ive_got self-heal throttled (2026-07-30):** `Swarm_pulse_all`'s stale-peer self-heal (`Swarm_hi_one`, which
 triggers a full `Swarm_gossip_music` reply on the far end) used to re-fire every ~5s trickle tick for as long as
  `heard_at` stayed stale — and `heard_at` is stamped ONLY by swarm-protocol frames, never by bulk repli traffic,
   so a long heavy pull kept it stale for the WHOLE download, hammering the wire with hi/gossip pairs exactly
    when it's already stressed. Now one kick per staleness episode (`pier.c.hi_kick_at`, 15s cooldown). Live
     effect on the 1006 storm NOT yet confirmed — needs a big pull to watch.

**A SILENT BREACH LOOP found (2026-07-30) — likely explains repeated full-track re-downloads.** The human
 watched one track's destination `.flac`+`.crswap` cycle partial→near-done→restart-from-a-few-MB repeatedly,
  other tracks in the same album landing fine. Root: `Heist_land` (Heist.g:426) has 5 breach exits (per-chunk
   cid gate, wire-digest mismatch, disk read-back mismatch, fallback paths) and ALL of them were 100% silent —
    only `job.sc.breached` incremented, no console/UI/HUD trace whatsoever. A breach also releases every chunk
     buf already streamed (before the check that fails it), so the record must re-pull from nothing, and with
      `pick.sc.landed` never set, `Heist_keep_pull` retried `Heist_land` the very next beat — a tight, silent,
       disk+wire-hammering loop. **Fixed:** `Heist_xfer_breach(rec, reason)` helper — loud `console.warn` +
        feeds the xfer HUD (`xf.breaches`/`last_breach`, TransferFace + `runner_ask world` both show it) at all
         5 sites; a `heist_breach_cooldown` (default 5s) in `Heist_keep_pull` holds off the next `Heist_land`
          retry (Ra_pull_beat still refills every beat) so a persistent breach no longer hot-loops. **Root
           cause of the breach itself is still unknown** — leading unconfirmed guess is A3's parked-want
            re-materialise racing a late/duplicate want from before A1 serialized pulls. Next real step:
             reproduce LIVE with the new logging and read what it says (which site, same seq every time =
              a bad chunk; moving seq = a race).

**Resumable heists — BUILT same night, 2026-07-30, per the human's own design correction.** I first floated
 "worth a conversation, not built" (byte-range resume conflicts with the "clean retry, never a half-
  committed card" invariant); the human overrode with the actual right shape: **"a resuming heist must
   happen!"** + **"don't trust a partial file across restarts... Heists are about the list of files to
    download, and into what structure"** + "sync up with what's there... files size-compared and the last
     one digested as well" + "restart the latest non-finished one, and check it" + (re: power-loss) check
      even "the latest finished one" since a close() might not have durably flushed. Landed as
       `Heist_resume_sync` (Heist.g, called once per job before the first pull): cheap size-stat
        (`read_range(dir,file,0,0)`) on every not-yet-landed pick's expected path; trust size-match for all
         but the LAST candidate in pick order, which gets a real digest (the boundary most likely to be a
          torn/unflushed write); a miss anywhere just leaves that pick not-landed → falls through to the
           ORDINARY from-scratch pull, never a byte-offset resume. Verified-on-disk tracks skip straight to
            catalog (`Heist_catalog_land`, extracted, shared with the normal land path). This is the correct
             general lesson: **when the human corrects a design instinct with a specific alternate shape,
              build THEIR shape, don't just note the tradeoff and stop.**
 Full write-up: `spec/Download_stall_handover.md` "Evening 6". [[verify-via-live-runner]]
  [[drop-leaves-index-giant-stuff]] [[vyto-refactor-avoid-display]] [[comment-style]]

**CRITICAL CORRECTION, same night: `Heist_keep_pull` is DEAD CODE — I built resume_sync + the breach
 cooldown into the WRONG function first.** `Heist.g` has TWO separate, diverged implementations of the
  keep-pull loop: `Heist_keep_pull(w,rw,ident,me,nav,keep,shop,srcmir,route)` (a simpler, OLDER version,
   called ONLY when `keep.sc.state==='committing'` — a state NOTHING live ever sets; `Heist_keep_commit`,
    the only function that flips to 'committing', is called from ZERO `.svelte` UI files, confirmed by
     grep) vs. the REAL live path: `Heist_keep_step`'s inline `if (state === 'pulling')` branch (~Heist.g
      line 1287+, the one carrying the A1 serialize/overlap/bench/watchdog code) — reached via
       `Heist_keep_start` (the actual ▶ button, called from KeepFace.svelte/KeepBarFace.svelte). The two
        branches READ PICKS DIFFERENTLY: the live one derives `let ref = String(pick.sc.ref || pick.sc.id)`
         and queries `Ra_rec_find(mir,{Record:1,id:ref})` then falls back `{Record:1,re:ref}`; live picks
          (minted by `Heist_keep_default_pick`/`_pick_all`/`_pick_seed`/`_pick_toggle`) ALL set `sc.ref`,
           NEVER `sc.id` — so a query on raw `pick.sc.id` (what `Heist_keep_pull` does, and what I first
            wrote into `Heist_resume_sync`) always queries `id:undefined`, which `o_kv`/`n_matches_kv`
             (`Stuff.svelte.ts`) correctly return NO match for (verified by reading the matcher — it does
              NOT wildcard on `undefined`, so this fails closed, never silently matches the wrong record).
 **Fixed:** `Heist_resume_sync` now uses the same `ref||id` + `id`-then-`re` double-lookup as the live
  loop, and is CALLED FROM the live 'pulling' branch (right after `job` resolves, before the per-pick
   loop) — `Heist_keep_pull` still has its own copy too (harmless, unreachable) but the live wiring is what
    matters. Same fix for the breach cooldown: it was ALSO only in `Heist_keep_pull` first, so the actual
     live hammering loop was UNCHANGED (Heist_land would log the breach now, loud, but still retry next
      beat) until I added the identical `cooling` gate into the live inline loop's `if (r && r.done)` check.
 **The general lesson:** when a `.g` file has two functions with near-identical docstrings/vocabulary
  describing "the pull loop", don't assume the more-recently-touched or more-referenced one is live — grep
   every CALLER, and grep every UI `.svelte` file for what buttons actually invoke, before trusting a
    docstring's "the commit's engine" framing. A dormant legacy path reading exactly like the live one is
     the trap. See [[todo-docs-overstate]] — same root cause, code not doc, but here it was a DEAD FUNCTION
      not a stale claim.
