# Composition_closed_2026-08.md — the long-form closed findings of 2026-08-08

> **Historicity notice.** This is not a retired doc; it is the **archive shelf for
>  `Composition_todo.md`'s closed sections**, moved here 2026-08-08 when that doc outgrew a
>   fresh reader. Each finding below was **CAUSE FOUND AND FIXED** on the day it was written,
>    and is reproduced **verbatim** — every console paste, every measurement, every "NOT
>     established" — because the evidence is what makes the lesson believable.
>
> **The living content is in `src/lib/O/spec/Composition_todo.md`**, which keeps the same
>  section numbers (§3.7, §3.8, §3.9, §3.12) as stable anchors and carries each finding
>   compressed to its durable lesson plus whatever part of it is still open. Read that first.
>    Come here only when you want the reading the conclusion was drawn from.
>
> Nothing here should be cited as current state: the fixes described *as shipping* have since
>  been built on. In particular §3.8's headline — *"`ra_missed` has exactly one reader, and it
>   is not the music path"* — was **true when written and is now false**: `Repli_missed_hot` is
>    that reader (see §3.9 item 2, and `Ra.g`'s `Ra_mag_warm` / `Ra_restock_beat`).

---

## 3.7 A JANITOR WAS HOLDING THE MUSIC HOSTAGE (2026-08-08, MEASURED — cause found and fixed)

**The reading**, off the human's live tab, three separate beats in one console paste:

    last beat: cull=8475  tour=0 peers=0 keep=0 (ms)
    last beat: cull=29671 tour=0 peers=0 keep=0 (ms)
    last beat: cull=12327 tour=0 peers=0 keep=0 (ms)

Three phases at **zero**, one at up to **29.7 seconds**, against a 600ms cadence. `×221` skipped ticks
 in the same paste, and the radio reaching `Radio:starved|of:138`. The split did not narrow the field;
  it collapsed it.

**The cause.** `Ra_shuffle_cull` (`Ra.g:780`) calls `Ra_source_alive` **per record**, and that verb is
 an awaited FSA directory `expand()`. Serially, over the whole shuffle Mag, on a crate whose census is
  **539 directories**. Its 30s throttle bounds how *often* it starts — it says nothing about how long it
   *holds the beat*, and at 29.7s it very nearly ran back-to-back with itself.

**Why that starves music specifically.** Everything the radio eats is downstream of that one `await` in
 `Swarm_share_beat`: `Ra_transcode_pump` (so the encoder frontier stops advancing — **this is the 32s
  preview ceiling the human hit**), `Ra_mag_warm`, `Ra_restock_beat`, and the full-length lead pass. A
   janitor sweep was holding the entire supply chain for up to half of every sixty seconds.

**The fix (`Swarm.g`, compiled `fc39dd10f0a0d3c1`): the cull flies detached.** Nothing in the beat reads
 its return value, and its own comment already concedes "a cull re-offers by itself" — the drop changes
  the offer mark on a *later* beat regardless. So the `await` bought nothing and cost the music.
   `Swarm_cull_detached` kicks it single-flight (`cull_flying` holds the start stamp) and bows out;
    `Swarm_cull_done` clears the latch on **both** settle and throw, because a latch left standing would
     silently retire the cull for the life of the tab. Its duration still reports, as `cull_bg` in the
      same skip line — *detaching a slow thing must not also make it invisible.*

**Two environments, two different culprits — do not merge them.** The daemon agent measured a separate
 `beliefs mutex held 8s by fn:swarm_share_beat` on the **jamserve** box and correctly ruled the cull out
  *there*: `scripts/daemon/main.ts` `share_arm()` stamps `ra_cull_floor_ms = 1e15` unless `CULL=1`, so on
   the daemon the cull takes its early return every beat. Both readings are true of their own box. The
    daemon's remaining 8s hold is **still unattributed** (their leading suspect is `Stoker_tour` doing
     native ffmpeg stocking inline) and is **a single sample** — a strong lead, not a baseline.
- **The cheap next cut for the daemon:** `w.c.beat_split` is already populated in-process every beat.
   Read `tour` off it from `main.ts` rather than monkey-patching verbs — the instrument is already there.
    (It will not show on the `/status` port, which dumps `sc`; `beat_split` lives on `.c`.)

**What is NOT yet shown.** That the detach alone lifts the 32s ceiling. It removes a large, measured
 blocker of `Ra_transcode_pump`; whether the pump then keeps up is the next reading, not a conclusion.

## 3.8 `ra_missed` has exactly one reader, and it is not the music path (2026-08-08 — SOURCE-READ, deliberately NOT fixed yet)

**Filed as a lead, not a finding.** §3.6 is one section above as a standing reminder of what happens
 when I ship a plausible story. This one is *structurally* verifiable (a grep), but its causal link to
  the observed starvation is **not**, and I have not built on it.

**What is verifiable right now.** When a source cannot resolve a wanted id it answers `repli_missed`;
 the sink's `Repli_recv_missed` (`Repli.g:585`) stamps `w.c.ra_missed[id] = Date.now()`. Grep the tree
  and that stamp has exactly two consumers:

| reader | file | what it does |
|---|---|---|
| the heist pull beat | `Heist.g:1912` | reads `told`, **deletes the entry**, re-censuses the source folder |
| peer rebirth | `Swarm.g:874` | `delete w.c.ra_missed` — a told miss described the previous id map |

**Nothing on the radio/music path reads it.** So a music want for an id the source has explicitly
 disclaimed is re-asked on the ladder interval (1.5s when dry, 4s otherwise) for the life of the tab.

**What the 2026-08-08 console shows.** `serve want id=2f101e4b@0` and `id=e9c41e4f@0` missing on the
 human's tab all session, at `@0`, `@4`, `@8`; and the same tab *receiving* a steady stream of
  `repli_missed` from its friend. **The failure is symmetric** — each tab is asking the other for ids
   the other cannot serve. That is a much better fit for "both starving easily" than anything one-sided.

**What is NOT established, and why I stopped.**
- That the disclaimed ids are the ones the radio is *playing*. The misses carry 8-hex ids
   (`2f101e4b`); the radio's `Radio:starved|of:138` carries a short ref. **I did not confirm they are
    the same id space**, and assuming it is exactly the §3.6 mistake.
- That these asks consume the lead pass's `budget`. The lead pass asks only for `playing.sc.id`, so a
   dead id burns budget **only if the playing record is the dead one** — which is the unconfirmed point
    above. Elsewhere the music asks from `Ra_restock_beat`/`Ra_mag_warm`, which live in `Ra.g`.
- Why the source advertised an id it cannot serve at all. `Ra_crate_dedupe`'s own comment predicts
   exactly this symptom from page twins, and the shuffle cull's comment says the "Se goner-diff tells
    the friend their mirror copy is dead too" — **whether that diff is actually firing is unchecked.**

**The one-question test — RETIRED (2026-08-08, same day): it was unrunnable as written.** A source read
 settled it: `Radio%of` is a DURATION in seconds (`Radio.g:632` — "the OFFER's length, not the file's"),
  and `%Radio` carries no record id at all. The lifetell label `Radio:starved|of:138` is Vyto's tok
   recipe (`Vyto.g:248-251`: mainkey + value + whichever join keys exist in sc) picking up the track
    length. The comparison I proposed compared a duration against an id space. The rest of this section
     stands — and the deeper answer arrived with it, in §3.9.

**Two corrections to the bullets above, from the same read:**
- A dead mirror id burns wants **whether or not it is playing** — `Ra_mag_warm` (`Ra.g:1032`, off:0 for
   the first 2 records per Mag) and `Ra_restock_beat` (`Ra.g:2733`, every hole inside preview) walk the
    whole mirror crate. Worse, `Ra_mag_warm` arms `mag.sc.warm` from `rows[0]` only (`Ra.g:1042-1055`):
     **an unservable id in rows[0] means the mag NEVER goes warm and re-asks `@0` for the life of the
      tab** — which matches the observed `@0` misses exactly.
- Free-standing find from the same read: the tok includes the mainkey VALUE and `of`, and Vytui's
   `{#each}` keys cells by tok — so every `playing↔starved` flip and every track change **re-keys the
    Radio cell and destroys/remounts the mold**. The `life mount mold` churn in the console is the tok
     recipe, not the wire. (Fix would be dropping `of` from the join list at `Vyto.g:249` — but that
      re-keys cells across every Vyto Book's fixtures, so it is a recorded-fixture change, not a patch.)

## 3.9 THE GONER-DIFF NEVER RUNS LIVE — sources silently retire records and no one tells the mirror (2026-08-08, SOURCE-VERIFIED)

**This is the disease behind §3.8's symptom, and it explains the symmetry in one mechanism.**

**The protocol has a delete half, and it is wired only in Books.** `Repli_sent_se` (`Repli.g:1228`)
 resolves goners and fires `repli_on_goner` → `Repli_retire` (`Repli.g:457`, one `op:delete` line).
  **Every caller in the tree is `Ghost/Story/Musuation.g`.** Same for the heist-side
   `Musica_stand`/`Musica_recast_offer` (`Heist.g:3504/3436` — callers only in `Heistation.g`). The live
    offer path, `Ra_offer_stock` (`Ra.g:972`), is upsert-only — zero delete lines ever cross.

**Meanwhile three live mechanisms remove records from a source's shelf:**
1. **`Stoker_tour`** — the conveyor, every ~90s on a HEALTHY tab (`Radio.g:1722-1725` rolls even under
    the window), dropping via `Ra_rec_drop` at `Radio.g:1819`. Its only guard, `rec.c.want_ts`
     freshness, protects an actively-pulling sink — not a mirror that merely lists the record.
2. **`Ra_shuffle_cull`** (`Ra.g:808`) — source gone.
3. **Page twins** (`Ra.g:847`, sink-side dedupe) — the stale half keeps being asked.

So: both tabs tour, both silently retire, both mirrors go stale, both answer `materialise gone` —
 **both starve, one mechanism, no second bug needed.** And `Ra_shuffle_cull`'s own comment ("lets the
  ordinary Se goner-diff tell the friend their mirror copy is dead too", `Ra.g:773`) asserts a mechanism
   that is not running — §2's pattern, again, in a comment I quoted approvingly in §3.7.

**Ids are content-stable** (sha256 of source bytes, `Ra.g:528-533`), so reloads don't re-mint the id
 space — verified, one less suspect.

**The fix, in dependency order:**
1. **SHIPPED 2026-08-08 — the tour seam is wired.** The whittle ledgers every dropped id on
    `stock.c.retire_due` (`Radio.g`, `a3a7863525517496`); the share beat flushes it right after the tour
     via new `Repli_retire_flush` (`Repli.g`, `a09d8367c1d3755e`; call in `Swarm.g`, `9441de33ee8c87e9`)
      — one op:delete line per id per registered caster, whose receive side already handles paged
       mirrors (`Repli.g:296-303`, hardened long ago and never fed). Drain-before-send, so a mid-flush
        throw costs one batch of tells, bounded by the status quo (a stale mirror is what we already
         had). Trace: `{ev:'retired', id, piers}`. The live tell to watch for: the per-id
          `serve want … no record for id` storms should stop RECURRING for newly-dropped ids —
           existing stale ids only heal when their record next drops or the mirror is reborn.
     **The cull seam landed too (2026-08-08, `Ra.g` `194a5920df997267`)** once ownership of `Ra.g`
      passed over: `Ra_shuffle_cull`'s goner loop pushes to the same `retire_due` ledger, so both live
       retirers — the tour whittle and the cull — share one ledger and one flush.
2. **SHIPPED 2026-08-08 — the bounded backoff on told misses.** `Repli_missed_hot(w, id)`
    (`Repli.g` `b85a7196c9b5fa38`) is the shared, **self-expiring** read: disclaimed within
     `ra_missed_hold_ms` (60s) ⇒ skip; past it the key is deleted and the next ask goes through. A
      backoff, never a ban — and self-expiry also stops the map growing unbounded, which a blacklist
       would not. Wired at the two crate-walking sites, which is where a stale mirror becomes a storm:
   - `Ra_mag_warm` — skips a disclaimed row rather than re-asking `@0` on the RTO ladder forever.
   - `Ra_restock_beat` — skips **before** `considered` increments, so a dead id no longer burns one of
      the K slots per pass and crowd out records that can actually arrive.
   - **The `rows[0]` single point of failure is fixed too, surgically**: the warm gate falls through to
      the next non-disclaimed row **only when row 0 has been disclaimed** — a state no Book can reach
       (`ra_missed` is empty there), so every recorded fixture stays bit-identical. A merely-slow row 0
        still gates the mag exactly as before.
   - **Left alone on purpose:** the `Swarm.g` lead pass (the single playing record). Gating that would
      silence a track rather than move past it; a disclaimed *playing* record wants the radio to skip
       on, which is §4.8's job, not a want gate's.
3. Not established: WHICH path retired `2f101e4b`/`e9c41e4f` (tour, cull, or twin — the serve-miss line
    can't tell them apart; the `source-gone`/`shuffle-cull`/tour traces carry the id and a tracelog dump
     would settle it). The fix above is right under all three, so this is curiosity, not a blocker.


---

## 3.12 THE PCM BELT LIVELOCKS — and it is the 32s ceiling, the pinned CPU, and the dropped music frames, all at once (2026-08-08, MEASURED + SOURCE-CONFIRMED)

**The reading** (Righto, one paste, repeating every ~10s for twelve minutes):

    ◈⚠ transcode STALLED — parked want id=dc1bd424 from_idx=16 waiting 724s — the encoder frontier never reached it
    …seven more, all from_idx=16, waiting 22s → 724s, none ever advancing…
    🛰☠ inbox backstop: pier editor holds 2050 unemits (cap 2000) — dropped oldest seq=… type=repli_lines
    ◈ Repli  rx 30p/635KB  tx 6p/127KB  231KB/s

**EIGHT records, every one stalled at exactly `from_idx=16`, none ever advancing.** Including
 `b5045a8e`, which twenty minutes earlier I had watched climb `off=16→18→20→22→24`. It advanced, then
  wedged. **So this is not a per-record wedge (§3.10 item 1) — it is total.** Every record that crosses
   the preview boundary on this tab dies there. Correcting myself: I called §3.10's sticky-`ra.done`
    the likely cause off a partial reading; the fuller log refutes that as the *dominant* one.

**The mechanism, confirmed from source.** `Ra_pcm_sweep` (`Ra.g:1845`) runs a belt:
 `CAP = ra_pcm_cap || 402653184` — *"~384MB — roughly 4 tracks decoded at once"* — over `rec.c.pcm`,
  the decoded whole-file PCM, which is **~92MB per record** ([[pcm-pinned-on-records]]).

    8 records wanting PCM  ×  ~92MB  =  ~736MB   against a 384MB cap

The belt sheds oldest-touched first. An open encode is shed *last* but explicitly **never vetoed**
 (*"a belt that can be vetoed is not a belt"*, `Ra.g:1869`). So each shed record's next
  `Ra_transcode_ensure` sees `!rec.c.pcm`, kicks a fresh whole-file decode, 92MB lands, the belt is
   over cap again, and it sheds another. **Nothing ever survives long enough to encode two chunks.**
    This is precisely [[a-belt-without-admission-livelocks]] — *the cap sheds successful decodes that
     instantly re-kick, and `Ra_pcm_backoff` only brakes FAILURES, so a successful-then-shed decode
      re-kicks with no brake at all.*

**One cause, four symptoms** — which is why nothing else explained the whole log:
| symptom | why |
|---|---|
| every track dies at 0:32 | chunk 16 is the first that needs PCM; none ever gets it |
| CPU pinned | continuous whole-file `decodeAudioData` of ~92MB payloads, forever |
| `inbox backstop … dropped … repli_lines/repli_page` | **music data frames DISCARDED** — the CPU is too busy for unemits to drain, so the inbox hits its 2000 cap |
| bytes flowing at 231KB/s the whole time | the wire was never the problem, which is why every rate reading looked innocent |

**§3.6 was closer than I credited it.** Its instinct — *"the music's asks are queued behind the heist's
 work"* — is right in **spirit**: a heist pulling 11 tracks demands 8+ records past the preview
  boundary at once, and that demand is what overruns the belt. It named the wrong *mechanism* (the
   share beat) and I refuted it on that basis, correctly, but the composition it pointed at is real.
    **The heist's demand destroys the radio's supply, via the PCM belt, not via the beat.**

**The fix is ADMISSION CONTROL, and it is in `Ra.g` — a handoff, not our edit.** The belt is eviction,
 and [[window-shelf-fairness-lives-in-eviction]] applies in reverse here: you cannot fix a livelock by
  changing *what* you shed, only by refusing to *start* work you cannot hold. Concretely: before
   kicking `Ra_source_pcm`, check whether admitting ~92MB would exceed the cap; if it would, **do not
    start** — leave the want parked and let an existing decode finish. Serialise rather than thrash.
     Prefer the record the radio is PLAYING when choosing who gets admitted.

**What we shipped on the demand side (helps, does not cure):** the restock gate (§0 item 0) stops the
 sink asking speculatively while its own playhead is under 16s banked, which lowers how many records
  compete for the belt. It cannot fix a source whose belt is already thrashing on a heist's demand.

**Not established:** the `×2` on every `ws RECV` line in that console. Two sockets legitimately exist
 per tab (`?addr=<prepub>` from `Swarm_station_up`, `?addr=runner` from `LiesLies`), so two
  `control:hello_ok` are expected — but a `repli_missed` addressed to one prepub appearing twice is
   not obviously explained by that, and `reused-seq collision` in the same log is the tell of
    duplicate delivery. `runner_ask runners` reads the editor's registry, not the relay's live bind
     table, so it cannot settle this. **Do not build on it until someone reads the relay's binds.**
