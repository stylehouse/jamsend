# Radio_todo.md — the music-piracy cluster, reborn on Housing+req

The one living doc for the MAIN conceptual spring of the whole machine — not a side quest
 (owner 2026-07-07: the old "narrow mini-project" framing was misleading). Every instrument
  here — particles, req, Story, Peeroleum, Swarm, Repli, Voro — exists to converge into the
   **Radiobuddies experience**: friends' libraries flowing to each other and playing. The work
    reimplements the old music-piracy machine (`src/lib/ghost/Radios.svelte` and its
     `src/lib/ghost/` neighbours) as `Ghost/M/*`, written in stho/LangTiles on Housing+req.
      The EARLY rungs pulled the old workings into view one instance at a time as pure cursor
       simulations pinned by `Musu*` Books; those low-level proofs were the ladder, not the
        destination — expect them to be REPLACED by higher-level re-draws as the layers ball
         together (Peering+Repli, Library→rastock|rastream, §9), and do not treat any of them
          as "nailed": the generic Peering/Pier substrate is open to innovation.

This file is the destination + the bombs + the next move. Keep it current; it is the memory
 the next fork would otherwise re-derive.

---

## 0. Latest handover — fold into the sections below as it's absorbed

### 2026-08-11 — THE RADIO STOPS BEFORE IT STARTS, AND A SKIP ALWAYS FIXES IT

**The night's actual headline, seen three times on live tabs and still not explained.** A booted
 Sounditron sits with a full friend pool standing — `radio.remote ✓ 8 playable of 8 from Lefto`,
  `radio.fresh ✓ 8 fresh of 8` — and **nothing plays**. One press of next-track starts it instantly,
   every time. The owner, the second time: *"all I had to do in there was hit next-track to get it to
    play, of course… so, watch out for that opportunity, and take it."*

**What is NOT the cause** (each read, not guessed):
- *A dead pump.* `Radio_pump_soon` reschedules 800ms on a null dial, and `Radio_pump` reschedules **on
   throw** as well (:375-380, written for exactly this fear). A chain that died would have to die in a
    way both of those miss.
- *An empty pool.* The census said 8 playable at the moment of the stall.
- *Exhaustion.* The `all` replay rung (:944) sits above the local rung; all-heard replays.
- *A false `'playing'` state.* Real, fixed today (below) — but this recurred AFTER that fix, with the
   AudioContext already running. So it is a second, separate stall.

**The live suspect, UNPROVEN: background-tab timer throttling.** `Radio_pump_soon` is a bare
 `setTimeout` (:367-368) and there is **no `visibilitychange` or `document.hidden` handling anywhere in
  Radio.g or Sound.g**. Chrome throttles background-tab timers hard, which would produce precisely this
   — a tab that boots unfocused never gets its next look, and ANY interaction revives it. It also fits
    "a skip always works", since a skip re-enters the pump synchronously off a real gesture. Related:
     [[jsdom-says-someone-is-looking]] (headless `document.hidden` is false, so Books can never catch
      this). **Next move: stamp the pump's wake times and compare a focused boot with a backgrounded
       one.** One measurement decides it.

**Meanwhile the recovery is taken, not suggested** (`Sounditron.g`, the `arrive.playing` patience
 block). At the give-up seam, if no record is open and the census says something is playable, the
  registrar calls `Radio_skip` itself, once, and says *"nothing had started — nudged the dial for
   you"*. Guards: once per episode (`c.skipped`), only with `!rad.c.rec` so it can never cut audible
    music, only with a genuinely playable pool, and only at a moment already conceded. **It is a
     RECOVERY, not a fix — when the cause is found it should be deleted, not extended.**

⚠ **Instrument trap paid for while writing it:** the guard was nearly `!probe.rms`, which would have
 been **dead forever**. `Lies_audio_probe` builds its own `osc → analyser → gain(0) → destination`, so
  `rms` says whether the AudioContext can process audio — ~0.705 on every healthy tab, playing or not.
   `radio.c.rec` is the real "is music coming out". [[audio-probe-rms-is-its-own-tone]]

### 2026-08-11 — A STATE WORD SET BEFORE IT WAS EARNED (fixed, and proven booting through `digging`)

`Radio_go` wrote `Radio_state(radio,'playing')` **above** `await Sound_gat()`, whose AC resume needs a
 user gesture — so a gestureless tab sat in `'playing'` with no device, no record and a suspended
  context. Measured: `probe {"state":"suspended","rms":0}` under `poke Radio_skip →
   {"was":"playing","now":"playing","title":null}`. Three readers trusted the word:
    `Radio_toggle` (:116) called `Radio_pause` — **the play button paused**; `Radio_nudge`'s pump gate
     refused to restart; and `Sounditron_music_why`'s gesture branch was gated on `off|paused`, making
      the one correct diagnosis unreachable in the state it describes. Every instrument read calm
       (`loud:0 amiss:0`) over a dead page. Four fixes: park in `'digging'` until the device is real;
        `Radio_toggle` presses play when there is no `c.gat` (and that press IS the gesture the resume
         waits on, so the button that looked broken is the one that cures it); `music_why` tests the AC
          before the state word; and the give-up advice goes live + carries a `remedy` word.
 **Proven live**: `Radio:digging,face:Radio` (bare) → `Radio:playing,title:High A,by_name:Lefto`.
  [[a-state-word-set-before-it-is-earned]]

**Still owed here:** the `Radio_toggle` guard and the widened `music_why` gate can only fire in the
 deadlock the first fix now prevents — so exercising them means reproducing it deliberately. A fix
  nobody has seen work gates nothing ([[mutation-test-every-claim]]).


A rolling brief: the newest work sits here first, then gets baked into its home section
 (§3.x, §9) once it is no longer "latest". An empty §0 means the doc is caught up.
Dated session diaries live in `history/Radio_buildlog.md` — this section stays a BRIEF, not a log.

### 2026-08-09 — "IT WON'T STREAM FROM LEFTO" IS EXHAUSTION, NOT ABSENCE (diagnosed on the live pair)

The owner, on the tab at `?I=f5da6599b8505881`: *"observe why it won't stream from Lefto, Lefto can
 stream from Righto."* **The wire is fine.** The pier is MUTUAL and sealed both ways, the mirror is
  fully previewed, and the tab was serving Lefto at `xfer 0↓ / 11↑ KB/s` the whole time it "couldn't
   stream". Nothing is broken between the tabs. The friend POOL is empty, and the reason is an
    id-collision the heard-set cannot see.

**The chain, each link checked against the live snap or the source:**
1. The tab has already diagnosed itself — the snap carries `error,of:96d0cf8852651a73,say:no music
    coming across from Lefto`, minted by `Radio_lineup_errors` (Radio.g:1212) when a live granted
     pier contributes NO pool.
2. `Radio_lineup_fill` (1110) builds those pools, filtering friend records by
    `radio.c.heard[rec.sc.id]` (1163).
3. **`radio.c.heard` is keyed by the BARE record id, with no owner** (`Radio_heard_add`, 723).
4. Both tabs are on the same box reading the same files, so their ids are the same ids. Measured
    from the live snap: **16 of 16** of this tab's own record ids also appear in its 24-record mirror
     of Lefto — a total overlap, not a partial one.
5. So **playing your own copy of a track marks the friend's copy heard.** Your own listening drains
    the friend pool.
6. The eviction that would re-admit them is `Radio_heard_cap()` = 100 (718) — but the entire
    universe here is 24 distinct ids, so the roll-over **can never fire**. The pool stays empty for
     the life of the tab.
7. Corroboration in the same snap: `Mag:Lineup,up_next:9` against `AHEAD = 20` — the fill cannot
    reach its target. The queue is draining and cannot refill.
8. `radio.sc.own` is absent, so the lineup is in SOURCE-EXCLUSIVE friends mode (the 2026-07-28
    ruling, 1145). There is no fallback to your own shelf: pool-empty is silence, not a switch.

**THE ASYMMETRY IS NOT REAL — BOTH TABS HAVE IT, and Lefto is the WORSE one.** Checked Lefto's own
 world in the same session, and it carries the mirror-image row: `error,of:f5da6599b8505881,say:no
  music coming across from Righto`. The numbers:

| | Righto `f5da6599` | Lefto `96d0cf88` |
|---|---|---|
| lineup `up_next` | 9 | **0** |
| Stoker `fresh` / `stock` | 9 / 16 | **0** / 16 |
| xfer | 0↓ / 11↑ | 19↓ / 0↑ |
| mirror of the friend | 24 recs, `flat=8` | 16 recs, `flat=0` |

Lefto has heard **everything it owns** (`fresh=0`) and has **nothing queued** (`up_next=0`). It looks
 healthy only because it happens to be mid-track on a Righto record it is still pulling (hence 19↓);
  when that track ends there is no next card. Righto looks broken only because its current track is
   one it already holds in full, so nothing needs to arrive (hence 0↓). **The download difference is
    a per-track accident, not a capability difference.** The owner's read — "Lefto can stream from
     Righto" — is what a working radio and an empty queue look like from outside.

The whole universe is **16 tracks that BOTH tabs already own** (16/16 id overlap), so "the friend's
 collection" is identical to your own. Hearing your 16 heards theirs. There is no round two.

**The message is a misattribution, and the fix for that already exists elsewhere in this file.**
 `Radio_dial_pool` (1284) carries an `all` flag for exactly this distinction, and its comment says
  why: *"the caller cannot tell 'no friend music has landed' from 'I have played all of it', and
   those want opposite answers (an honest note vs. a replay)."* `Radio_lineup_errors` never got that
    fix, so it blames the friend for a shelf the listener finished.

**Not the cause, but seen while looking:** the mirror holds 24 Lefto records while Lefto boasts 16
 (`boast-heard of=96d0cf88 records=16`) — 8 rows in the mirror that Lefto no longer offers. Related
  to [[one-sided-reload-breaks-serving]]; harmless here, worth its own look.

**The candidate fixes — owner's call, NOT applied** (and Radio.g had a concurrent editor at the time,
 mtime moving mid-session, so nothing was touched):
- **(a) Exhaustion → replay**, matching the `Radio_dial_pool(all)` idiom the codebase already chose:
   when a friend's heard-filtered pool is empty but their unfiltered pool is not, clear those ids
    from `heard` and say "round two" rather than minting an error. Fixes the message and the silence
     in one move.
- **(b) Own the heard key** (`hp + ':' + id`) — cheap, but it means hearing the same track twice,
   once as yours and once as theirs, which may be worse than the disease.
- **(c) Scale the cap to the collection** rather than a flat 100 — the flat number is only ever
   correct for a library much larger than the room.
(a) is the recommendation: it is the distinction the code already knows it needs.

### 2026-08-10 — `Radio_crossover` — THE FIRST FRIEND TRACK NOW CUTS IN (the 08-09 ask, landed in part)

*The owner, restating it a third time: "it should switch to playing from the peer's stream when their
 first track becomes ready."* The two entries below recorded this as design-only. The **first track**
  half is now implemented in `Radio_nudge`'s playing branch (`Radio_crossover`, Radio.g).

**Why it needed writing at all, given "a playing radio is not deaf" (2026-08-08) already landed.** That
 fix restaled the LINEUP — and a lineup entry is the NEXT track. So the friend's music was correctly
  queued and the listener still sat through the rest of a stopgap first. Waiting is right for every
   later track and wrong for the first, because the first friend track is the moment the app becomes
    what it is for.

**Four gates, each load-bearing** (the failure mode being avoided is "cuts a track at random"):
 once a sitting (`radio.c.crossed`, runtime-only so a reload re-arms — this is an ARRIVAL, not a
  policy) · only out of solo (`sc.solo` set ⇒ we are on our own shelf; cutting a friend's track to
   start another friend's is just random skipping) · only when `Radio_pool_census().playable` is
    non-zero (`Radio_playable`'s real test — chunk 0 warm plus the first seconds — not "a card
     exists"; a cut to a husk is silence) · **throttled 1.5s, and this one is not politeness**:
      `Radio_nudge` runs PER LANDED CHUNK and its own comment insists on O(1), while
       `Radio_pool_census` walks every crate and record — this is the exact shape of the 2026-08-06
        per-chunk burn. After the crossover the latch makes it free forever.

It calls `Radio_skip` (which blends rather than cuts, 2026-08-07) and lets the dial's existing friend
 preference choose, rather than growing a second opinion about what to play.

**⚠ THE BOMB — RE-AIMED 2026-08-10 (late). The conclusion was right and the fuse was wrong; the
 paragraph that stood here would have sent you to the wrong function.** What it said: the crossover
  gates on `playable` (heard-blind) but fires a `Radio_skip` that lands in
   `Ra_dial_next(… skip_ids: radio.c.heard)`, so an all-heard friend crate burns the latch back onto
    your own music. **That mechanism cannot fire**, for two independent reasons, both already in the
     file it accused:
- `Radio_dial` reaches `Ra_dial_next` ONLY inside the `radio.sc.own` branch (:917) and the last "mine"
   rung (:982). The friend path goes lineup → `Radio_dial_pool` (fresh, :928) → **the exhaustion rung
    `Radio_dial_pool(w, radio, 1)` (:944)**, which drops the heard gate (:1524) and REPLAYS. That rung
     is the 2026-08-06 "exhaustion is not starvation" fix, and it sits *above* the local rung on
      purpose. All-heard costs one honest replay (counted in `sc.replays`), never own music.
- `Radio_pool_census` (:1577) and `Radio_dial_pool` (:1526) apply the SAME `Radio_playable` over the
   same `MusuThem` crates, so a census that said `playable > 0` cannot be followed by an empty
    exhaustion pool. And `Radio_lineup_fill` is source-exclusive (:1367/:1375), so the lineup cannot
     hand back own music either.

**THE REAL FUSE: `Radio_source_toggle` never clears `sc.solo`.** `sc.solo` means one precise thing
 everywhere it is read — *on my own shelf INVOLUNTARILY* — minted only on the mine rung (:996, which
  `own` makes unreachable) and retired only in `Radio_open` when a friend's track opens (:695). The
   source switch (:1293–1308) deletes `sc.note` and **not** `sc.solo`. So boot alone → solo set → flip
    to "my records" → `own=1 && solo` stands for the rest of the sitting. A friend's first chunk then
     lands, the crossover's three gates all pass, `crossed` burns, `Radio_skip` fires, and the dial
      takes the `own` branch at :917 — **your own record, latch spent, and the listener's explicit
       source choice overridden for nothing.** Second harm, same cause: `Radio_dial_solo` (:1141) reads
        that stale flag, so the roster says *"listening alone"* over a deliberate own-mode.

**The fix is one line in the toggle, and deliberately NOT in the crossover.** Clear `sc.solo`/`solo_by`
 where the meaning changes, restoring the invariant at its only breach point; then `own=1 ⇒ solo
  absent` holds structurally and every consumer is right for free. Rejected: an `sc.own` gate inside
   `Radio_crossover` (a second copy of one fact, free to drift, and it leaves the roster still lying);
    a refundable latch (to refund, the crossover must observe what the dial chose — exactly the second
     opinion about what to play that :1634 exists to refuse). Open, and the owner's call, not a bug:
      whether `c.crossed` should permit a RE-arrival hours later when a friend leaves and returns.

**SEEN FIRE — TWICE, 2026-08-10 late, on Righto beside Lefto.** Two independent boots, same arc, from
 `runner_ask world --player=<pub>`:

```
radio.solo ◐  "listening alone — your own music while we gather"
   +1382ms / +284ms   crossover   playable=2 of=Lefto
radio.solo ·  "with a friend"
```

The solo mark, the cut-in, and solo clearing because `Radio_open` opened a friend's track — the whole
 designed causality, reproduced. So this is **proven, not written** ([[mutation-test-every-claim]]:
  still owed its RED half — flip to own, bring friend music in, confirm it does *not* fire and
   `crossed` is not burned. That negative test is the one that gates the fix above).
⚠ **Instrument note, paid for once:** `trace` is REFUSED on a `--player` (allowed: ping probe world
 supervisor state rungos runners socklog dump poke reload snap steps assertions). A `trace … | grep
  crossover` greps an error message and returns silence that reads exactly like "never fired". Use
   `world`. [[the-instrument-was-blind-to-the-molds]]

### 2026-08-09 — "jump to the friend's stream when it comes available" (owner, same session)

Restated tighter than the boot-policy ruling below and worth keeping in its own words: *"we need to
 jump to the Friend's stream when it comes available."* This is ruling 1 below with the emphasis
  moved from BOOT to ANY MOMENT — a friend coming online mid-session should pull the radio over, not
   only decide what a fresh tab opens on. Note it interacts with the exhaustion bug above: today a
    friend "becoming available" contributes nothing if their records are already in `heard`.

### 2026-08-09 — THE BOOT POLICY, in the owner's words (design only — nothing implemented)

Dropped mid-session while working the Vyto glass; recorded here because it is RADIO policy, not
 glass policy. Three connected rulings about what a fresh tab should PLAY:

1. **"we should switch to a friends stream when they come online, perhaps even play nothing until
    it's determined no peer is online, so we can start playing new music."** — presence-first: the
     friend's stream outranks local shuffle, and the boot may hold silence briefly rather than
      commit to old music it will immediately abandon.
2. **"it should start with %oldMusic and %newMusic,pending and you can throw attention light into
    either direction... but %oldMusic is what's already here so it could actually be faster... to
     jump into without networking."** — the boot choice as TWO CELLS in the glass, decided by the
      attention currency (heat), not by a setting: %oldMusic (local radiostock — playable with zero
       networking, so it can be INSTANT) vs %newMusic,pending (waits on peers/share arming ~30s).
        The user throws light at the one they want; absent a throw, presence decides (ruling 1).
3. **"perhaps it starts before there's a %Radio"** — the glass can commission before the Radio organ
    exists. That race is now at least SAID (Vyto_normal's presence check, Supervisor_todo §9) but
     the honest fix is boot-order: the two boot cells above could BE the pre-%Radio state — the
      glass is never organ-less, it opens on the choice itself.

Next move when this is picked up: mint %oldMusic/%newMusic as real particles the Sounditron
 commissions at boot, wire heat-throw to the dial, and let ruling 1 auto-resolve the pending cell.

### 2026-08-07 — ONE OF ANYTHING, ON THE WIRE TOO (the 61/638 report)

**The destination this serves:** the numbers a listener reads off the glass have to be the truth. The
 owner, on a long-open player tab: *"it's in 'all heard' and has been for ages, and the set of them …
  is at 61/638, dunno why it keeps accumulating on its own"* — against a **62-track** crate.

**The bomb: `Repli_merge` enforced one-of-anything only within the ARRIVING PARENT.** It located a
 `%Record` under the `%Cloud` the frame happened to name, so it answered *"is this record on this
  page?"* when the ruling it exists to enforce is *"there is only one of anything on this SHELF"*
   (`Ra_rec_home`, the landing-Mag ruling). The sender's own shelf **churns** — the tour drops and
    re-stocks tracks, and `Ra_mag_page` always lands a re-stocked one on the LAST page — so a track
     that crossed on page 1 crosses again later on page 8, misses the page-local census, and mints a
      **twin**. Measured live on Righto: **65 records over 53 distinct ids across 11 pages**, `a14602e5`
       on pages 1 AND 8, `dc8eac48` on 1 AND 9.

**The two symptoms were one bug.** The same trace showed `serve-miss … no record for id — materialise
 gone` repeating forever for two ids, and **`ba8bb2c3` was one of the duplicated ones**: the sink was
  re-asking a stale twin of a holding the source had long since re-paged, and the source could only
   keep saying no. A phantom record is not cosmetic — it inflates every census the listener reads AND
    it is what the dial then picks.

Fixed at both ends. `Repli_merge` escalates the `%Record` census from the arriving parent to
 **`mirrorTop`** — the crate root — so the wire asks the same shelf-wide question `Ra_rec_home` asks
  locally: one door, one answer, both sides. The found record **stays where it sits** rather than
   moving to the named page; paging is a listening ramp, not identity (`Ra_recs` walks `Mag**`
    regardless), and tearing a head out from under its landed chunks to satisfy a page number would
     cost real bytes. `Ra_crate_dedupe` then clears the twins a long-open tab is *already* holding,
      keeper = the copy holding the most chunk bytes, and the record the radio is **playing** is
       protected outright. It uses `drop(n)` not `rm(pattern)`: `rm` locates by query and with twins
        standing under one parent the query cannot say which — it could take the keeper.

Verified live on Righto, no reload: `recs=68 distinct=55` → **`recs=56 distinct=56`**, nothing lost.
 `RepliUpsert` (7/7), `RepliSplit` (5/5) and `RepliShadow` (5/5) all green — and their own assertions
  are the property that was strengthened (*"an identical resend located itself and changed nothing — no
   twin was minted"*, *"the second pass located the standing mag and cloud spine"*).

**Tooling that found it, and keeps it findable:** `runner_ask world` grew a **`crate_census`** —
 `%MusuThem` homes, per-shelf `recs` vs `distinct_ids`, mags, clouds. It states the two leaks
  *separately*: `homes > pubs` means one crate counted many times by any reader that loops homes;
   `recs > distinct_ids` means the same track standing twice in the tree. They are different bugs and
    look identical in a total. The same op's `world_snap` was ALSO a lie worth knowing about — its
     comment claimed it encoded "the resident world so Radio/Musu/MusuThem show", but it encoded
      `Lies_runner_story_w()`, the **Story** world; on a tab that has run a Book you got its recorded
       step snaps and not one live particle. The two coincide only on a virgin player tab, which is why
        it read as working for so long. `resident_snap` is now its own key.

### 2026-08-07 — THE SHUFFLE POOL WAS NEVER THE CRATE (the "same 10 tracks" report)

**The destination this serves:** hitting skip repeatedly should walk the whole collection, and the
 tracks should blend. The owner: *"it keeps playing the same 10 tracks"* — with 62 tracks in reach.

**The bomb, for whoever reads this next: `Radio_dial_pool` admits a record only once chunk 0 is
 PRESENT.** A husk plays silence, so presence IS playability — which means *the warm window is the
  dial's entire domain*. Anything the restock beat declines to warm is not slow to start, it is
   INVISIBLE to the shuffle. Two defects compounded on that fact, both in `Ra_restock_beat`:

1. **Wants were fired once, ever** — latched on the bare `ra_wanted` boolean, no retry timer. That is
    the exact shape `Ra_pull_beat`'s own header names as the bug it fixed ("a want lost to a
     dropped|parked serve was NEVER re-asked... the record wedged forever") — and this beat is cited
      *there* as the proven sibling for the BUDGET half, while never receiving the RE-ASK half. One
       dropped want-reply froze a record as a husk for the session, permanently outside the dial.
2. **A contiguous window against a uniform dial** — candidates were the K catalog-successors of the
    playing record, but the dial picks uniformly at random. So the warm set grew only by successors of
     records already played (a slowly-spreading clump) while `heard` retired its members until the pool
      emptied and the caller fell through to the `all` replay. No amount of skipping escapes it: a skip
       advances the frontier by at most K.

Fixed together — either alone still leaves the pool small. Half the window now steps a **golden-ratio
 cursor across the whole catalog** (the crate wander's trick); scattering is right rather than wasteful
  *because* the gate is chunk 0 alone — one landed page makes a record dial-able and the live pull
   deepens whatever gets picked. Both halves gated on `humdinger`. The re-ask is gated **not merely to
    spare fixtures**: it is wall-clock driven, so inside a Book whether it fires would depend on machine
     speed — a want sequence that flaps with load is worse than one that never re-asks.

**%PREVIEW-MIDDLE LANDED** (was parked in `Sounditron_todo.md` "not built blind — needs the human's
 ear"; the owner asked for it directly). `Ra_preview_offset` cuts the offer 30–70% in, deterministic
  off the **enid** — which is the content hash, so every Pier and every reboot agree; a random roll
   could not be re-derived when a card resurrects, and two peers disagreeing would hand one id two
    different timelines. `seq` stays 0-based (offer seq *i* = source segment `off+i`), so the page grid,
     want stride and %Stream seam are untouched; the offer's chunk count is `total-off` and the
      continuation opens at `off+P`. Three other sites follow it: `Ra_record_from` (stamps `pv_off`,
       **absent when 0** so nothing snaps differently), `Ra_transcode_ensure`, `Ra_term_decode_pulled`'s
        last-chunk remainder, and `Radio_open`'s `sc.of`. The resurrect gate now also requires the card's
         cut point to match, so pre-existing stock rebuilds itself once.
 **The seam is fine by construction** — it is an encode boundary, marked `head`, and both the Book
  decoder and the live player reset the decoder there and drop that encode's preskip; both halves carry
   the same baked gain. **What is UNVERIFIED is the track START**: the first preview chunk now opens
    mid-waveform, so the encoder begins from silence at a non-zero sample. Needs an ear, not a Book.

**Heist UI: `music/Unfiled/` was not only a lie, it was CREATING the folder.** `HeistSetup.commit()`
 *and* `Heist_keep_commit` both defaulted the genre to the literal string `'Unfiled'`, which
  `Heist_filing_for` then returned as a real category — landing a folder the 2026-07-29 ruling
   explicitly forbids ("I don't want anything prepended"). Both now leave it absent. The `music/` prefix
    was invented display (there is no such root), and the row showed only the basename, claiming the
     album folders get flattened — they don't (`Heist_cp_path` preserves the source path). Also:
      `Repli_serve_chunks` writes `x.serves[id]` on every advance and **never removes it**, so a finished
       upload kept its ⇈ row at 100% forever *and*, being among the four most recent, crowded out rows
        that were genuinely moving. Rows now carry `done`, sort behind live ones, and age out.

**NEW CELL — `%Shuffle` / `ShuffleFace`** (the owner: *"perhaps we can get a visual on that. should be
 on the page, in Vyto!"*). One pip per record in reach, lit only when the dial could pick it, filled by
  preview-held fraction, dimmed once heard. The wall of hollow pips beside a small lit cluster IS the
   report — seen instead of inferred. Rides with the deck (yields to an open heist).

**BOOK STATE, attributed properly (the controlled revert, twice).** MusuStock 1.0, MusuRaTerm 1.0,
 MusuHeist 1.0 (the ungated re-ask had cost it 0.95 — gating restored it). **MusuMag and MusuRaStream are
  PRE-EXISTING RED, not this work**: with `Ra.g` reverted to HEAD they measure *identically* (MusuMag 0.1
   vs 0.1, ×3 and ×2 runs; MusuRaStream never settles on either build). Both remain to be diagnosed.
 **Trap worth keeping:** MusuMag read 0.7 before the radiostock wipe and 0.1 after, on BOTH builds — the
  Books lean on standing stock, so a cache deletion mid-session will look exactly like a regression.
   Always re-baseline after touching `.jamsend/radiostock/`.

**radiostock had no disk-side GC.** 237 files / 116MB for 62 distinct tracks: the filename carries the
 writing peer's pub, so every fresh browser identity re-wrote the whole crate (15 generations).
  `RADIOSTOCK_CACHE_LIMIT` whittles only the in-memory record set — nothing ever culls the files except
   the source-gone drop. Wiped at the owner's request (also required by the preview re-cut). **A real
    disk-side cap is still owed.**

**NEXT:** the owner's ear on (a) the mid-track track-START, (b) the blend; their eye on ShuffleFace;
 then diagnose MusuMag/MusuRaStream, and cap radiostock on disk.

**2026-08-07 — THE SMALL POOL THAT WOULDN'T ROLL OVER. THE ANSWER WAS THE WHITTLE, NOT THE MEANDER.**

The owner: *"it should be easy to find every album in a 5 album collection like this but somehow two of
 them only have one track each"*, then *"still stuck in a small pool of radiostock that wont roll over"*.
Simulated the algorithm rather than guessing at it (scratchpad `meander_sim.mjs` / `window_sim.mjs`), and
 the simulation **refuted the standing hypothesis** — the draw weighting was never the cause.

- **The shelf is a moving window, so its composition is an EQUILIBRIUM, not an accumulation.** Album *i*
   gains at its draw probability p_i and loses at held_i/W, because the whittle drops the globally oldest
    record and knows nothing about albums. That settles at **held_i = W·p_i**. For [40,20,12,4,2] at W=24
     the algebra predicts [12.3, 6.2, 3.7, **1.2**, **0.6**]; simulation measured [12.5, 6.2, 3.7, **1.05**,
      **0.48**] — the owner's report to the decimal. With an unbounded shelf every scheme collects every
       album, so the meander was never the illness.
- **This kills the obvious fix.** Weighting the draw by each album's REMAINING tracks changes nothing: at
   equilibrium remaining is itself proportional to total, so it reduces to the same proportional rule. No
    draw weighting can fix an album-blind whittle — but a fair whittle fixes it under EVERY weighting, and
     costs the big album nothing (shelf → [6,6,6,3,2], P(album ≤ 1 track) 52%/75% → 0%/0%).
- **Landed: `Stoker_tour` retires the oldest record of whichever album is currently fattest** (`sc.album`,
   or the path's dirname when untagged). Max-min allocation done the cheap way.
- **THE CRATE IS BIG AND DEEP** — but see the ground-truth count later in this entry, which splits this
   claim in two: the TREE is big and deep (528 directories, five levels, 82% of it `wormhole/`) while the
    MUSIC really is small (62 files in 7 directories). So "the small collection read was wrong" is only
     half right, and the half that matters for the wander is the tree. **The tour mark now carries**
   `dirs`/`known`/`open`/`top` off the meander's own learn map, and `top` named the tree:
    `0 spawn/- folks/- west/Calexico and Iron & Wine In the Reins:13`. Five levels down. A 12-hop budget
     that RESET TO THE ROOT on every dead end could barely reach an album at all. Now 24 hops, and a dead
      end steps UP one level instead of unwinding — both behind the `learn` (humdinger) predicate, since
       they change the draw sequence and a driven world must keep walking byte-identically.
- **Three defects found by simulation, not by reading**, all pulling the wander into empty structure:
   the learn map keyed one directory two ways depending on base (so a third of digs saw an explored tree
    as unvisited); `est` floored at 1 PER DIRECTORY, so barren structure out-weighed real music; and past
     depth 6 it returned the unvisited prior instead of what it had learned.
- **THE INSTRUMENT-WAS-THE-BUG CLASS CLAIMED TWO MORE.** (a) `learn[here] = {...}` sat BELOW the
   `if (!branches)` guard, so a spent leaf album and a genuinely empty directory — the two cases the map
    exists to record — were the two it never wrote. `open` could never reach 0; empty folders kept the
     prior of 8 for ever. Moving the write above the guard: picks=0 26% → 10%, throughput +22%.
      (b) The first roll fired on `dug > 0`, and live it read `dug=1 dropped=1` on every tour with stock
       pinned at 20 against a window of 40 — the conveyor had become a CAP. The roll must stay strictly
        slower than the dig (`dug > 1`) or it cancels it. **That is five for five this week: every one
         of these looked like normal operation from the outside.**
- **A spent branch returns in proportion to what it holds**: floor `ceil(sqrt(true tracks))`, not 1, so a
   momentarily-shelved 200-track album isn't priced like an empty folder. Best measured revisit latency of
    four floors tried (20.5 → 9.7 tours). Integer by construction — `prandle` is `floor(random*n)`, so a
     fractional weight would collapse its remainder into the last bucket and bias the final branch.
- **Thread (b) — "163 directories for 48 tracks" — RESOLVED, and it was the biggest thing here.**
   The dead-end **step-up** added the same day (climb one level instead of resetting to the root) fixed
    the four-wasted-descents problem and bought a far worse one: stepping up out of a barren leaf lands
     on a parent whose ONLY branch is the leaf just abandoned, so the very next draw descends straight
      back into it. Traced hop by hop in simulation — `misc9/a/x DEAD -> up -> misc9/a/x DEAD -> up`
       eleven times, **22 of 24 hops oscillating between two directories, on 91% of digs**. That is what
        `picks=0 got=0` always was: not a wander that failed to find music, a wander that never got to
         look. Sixth instrument-was-the-bug of the week, and the only one that was a *dead loop*.
   **Fix: deadness PROPAGATES.** A directory is dead when it is learned, holds no audio of its own, and
    every sub is dead; dead branches are pruned from the draw, so a node whose branches are all dead
     becomes dead itself and its parent prunes it — the corridor unwinds instead of trapping the walk.
      Two deliberate non-properties: unknown space is never dead (no learn entry ⇒ false, so there is
       always a way into what has not been seen), and a SPENT album is never dead (it reads `audio`, the
        true count, never `open`), so whittling always brings it back and no track is written off.
   Simulated on the owner's shape (201 dirs / 995 tracks / 130 albums, 400 digs × 40 seeds):
    albums reached **26 → 122** of 130, tracks **70 → 487** of 995, empty digs **364 → 152** of 400,
     dirs walked **83 → 193** of 201 — and hops **DOWN** 8926 → 6266, so it is cheaper as well.
- **CORRECTION, FOUND IN A COLD RE-READ OF MY OWN DIFF: THE PRUNE WAS INERT ALL NIGHT.**
   `live = dirs.filter(d => !dead(here + '/' + d, dm))` — but a `dirs` element is a directory HANDLE, and
    every other line in the function spells `String(d.name)`. Interpolating the handle built the key
     `<here>/[object Object]`, which is in no learn map ever, so `dead()` took its `if (!e) return false`
      exit on every call and **nothing was pruned from the moment it landed**. It fails in the SAFE
       direction — nothing wrongly written off — which is exactly why nothing threw and the numbers still
        went up. Ninth of the week, and the first where the silent mechanism was my own new code.
   **What this changes about the attribution, which matters more than the fix:**
   · The SIMULATION was testing the intended algorithm correctly (its `dirs` are `Object.keys(...)`,
      i.e. strings), so albums 20.5 → 110.4 on the repo shape stands — **as a prediction, still untested
       live.**
   · The LIVE results — 49 → 62 discovery, the 38–40 limit cycle, the shelf composition — are real but
      were produced by the **φ slot cursor, the dry-tour roll, and the cold learn map after the reload**.
       Not by deadness. Every sentence in this entry crediting the prune for a live number is wrong.
   · The ping-pong trap traced in simulation is REAL and was **never actually fixed live**. Discovery
      still reached 62/62 despite it, so on this tree it costs hops rather than coverage.
   · Therefore expect a further improvement once the fixed build runs — but a MODEST one, see below.
- **AND THE SIMULATION'S SHAPE WAS WRONG, WHICH INFLATED EVERY HEADLINE IN THIS ENTRY.** The synthetic
   crate was built before the share had been counted: 995 tracks in 130 albums, against a reality of
    **62 tracks in 7 directories**. Finding 130 needles is a different problem from finding 7, so the
     "albums 20.5 → 110.4" and "26 → 122" figures **do not transfer to this owner's share**. Rebuilt the
      harness to the counted shape (520 dirs, 62 tracks, albums 18/13/11/8/8/3/1, 408 dirs of
       `wormhole/Ting/<date>/<time>`, `scratchpad/real2.mjs`) and re-measured what actually ships:
   | metric | was-live (cursor only) | shipped (+prune+confirm) |
   | music dirs reached | 7/7 | 7/7 |
   | tracks found | 62/62 | 62/62 |
   | **digs to complete discovery** | 120.7 | **110.1** (−9%) |
   | **hops to complete discovery** | 2262 | **2010** (−11%) |
   So on THIS share the prune is a ~10% speedup, not a transformation, and final coverage is unchanged —
    which is precisely why the cursor-only build reached 62/62 live without it. The big numbers were real
     for the shape they were measured on and that shape is not the owner's. **Count the crate BEFORE
      choosing the harness shape; a simulation calibrated to an imagined input measures an imagined
       system.** Second time in one sitting that the sim's shape, not its logic, was the thing that lied.
- **Thread (a) — MEASURED, and the partial-listing hypothesis is REFUTED.** `flap` counts revisits where
   a directory's audio count disagrees with the last visit, `flapd` the same for its subdir count (the
    more dangerous half — a short directory listing omits a music-bearing child from `subs`, and deadness
     only checks the subs it was told about, so a parent whose real children were never seen could be
      pruned and take a branch out of reach). Both sat at **0** across many tours on both players.
       So `known=49` is honest and the share really does hold ~49 tracks in 184 directories — low music
        density, but the truth of it. The original one-off tick-down (50→49) stays UNEXPLAINED; it simply
         does not recur under measurement, which is worth knowing but is not the same as solved.
- **`picks=0 got=0` ON EVERY TOUR MARK WAS AN ARTEFACT, NOT A FINDING.** `st.c.dig_*` are per-CALL and
   the round loop breaks on the first dry round — so the round the trace read was, by construction,
    always the one that found nothing. Marks were printing `dug=1 ... picks=0 got=0`: an instrument
     contradicting itself within a single line, for as long as the mark has existed. It cost this session
      a wrong "the wander cannot reach the free tracks" theory, chased almost to a speculative fix, before
       the contradiction was noticed. Now summed across rounds. **Seventh of the week, same shape** — and
        the first one that was actively *arguing the opposite of the truth* rather than staying silent.
   **Still not the whole truth, and worth knowing before trusting these fields.** `Stoker_dig` loops over
    three bases (`['music', '', 'testsounds']`) and RE-ASSIGNS `dig_picks/got/hit/dup/bad` inside that
     loop, so one call's counters describe only the LAST BASE it tried. Summing across rounds therefore
      gives the last-base value of each round, not the true total — an undercount, in the same direction
       as the bug it replaced. Left alone deliberately: making it exact means changing per-base semantics
        that a nearby comment says are load-bearing ("the shelf count ACROSS THIS ONE CALL is the exact
         test"), and that is not a change to make while the live pair is unreachable. **Read `dug` as the
          authority for what a tour actually landed; treat `picks/got` as a lower bound.**
- **Thread (a)'s insurance, kept anyway** — deadness still requires a second opinion.
   Pruning is permanent, so a single short `expand()` on a real album would write it off for the life of
    the page. Deadness therefore needs a second opinion: `z` counts consecutive audio-free visits and a
     directory must look empty TWICE. Costs warm-up speed only (tracks by dig 50: 58 → 38) and converges
      to the same ceiling (121 vs 122 albums). Still worth confirming (a) directly — log `audio_all.length`
       for one known-size album across repeat visits — because if listings really are partial, `known`
        and every weight derived from it are under-counting everywhere, not just here.
- **EVERY DIRECTORY CARRIES ITS OWN SLOT CURSOR** (the owner: *"some kind of balanced tree that grows to
   find every directory evenly, by magic... a Dip assigned tree of directories"*, *"walk evenly into the
    unknown space"*, *"roughness"*). An iid draw is a coupon collector — seeing all K branches of a node
     takes ~K·lnK visits with a heavy tail, so the wander kept re-treading the branch it had just come
      back up from. The node now steps its OWN cursor by φ across the weighted CDF, the same shape as
       `Dip_assign` claiming `parent.sc.i++` (Hovercraft.svelte) but proportional instead of round-robin:
        successive visits land ~0.618 apart, so K roughly equal branches are covered in K visits with no
         repeat and no gap, and a branch worth 3× another still gets 3× the slots. Discrepancy
          O(log n / n) against iid's O(√n). φ specifically because its continued fraction is all 1s, so
           the sweep can never fall into lockstep with a branch count. The cursor is born at a random
            offset — the **roughness** — so no two nodes are in phase. Worth **+16 albums and +17 dirs**
             on top of pruning. It is not one of the old wearing-out cursors and cannot become one: it
              indexes BRANCHES at one directory, never tracks, the track pick stays a fresh draw, and it
               lives on the `.c`-only learn map so it never encodes and dies with the page.
   Sharp edge, found before it shipped: that map SURVIVES HMR, so a live page carries hundreds of entries
    minted by the previous build with no cursor. `undefined + 1` is NaN, `NaN >= w` is false, and the CDF
     walk then stops at k=0 — every one of those nodes would have picked its first branch for ever, on
      the live pages only, with nothing thrown to say so. Hence `if (node.n == null)`, not `if (!node)`.
- **THE DRY TOUR IS THE ONE THAT MOST NEEDS THE ROLL** — the deadlock behind the owner's actual sentence.
   Yesterday's `dug > 1` guard reads a dry wander as "there is nothing out there". Usually it means the
    opposite: the wander came up dry BECAUSE the shelf holds everything within reach, and the skip set
     built from that shelf is what emptied the pool. Supply is not absent, it is *held*. Both players sat
      in exactly this: `dug=0 dropped=0 stock=34` tour after tour against a window of 40 — never full so
       no over-the-window whittle, never digging so no roll. Dropping un-barrens the path, so at
        saturation the whittle is the ONLY source of supply. Now `dug < 1` rolls one as well, and it is
         self-limiting without a rate of its own: drop one on a dry tour, the next tour finds exactly
          that one, `dug === 1` blocks the roll — the shelf sits at its ceiling and rotates a record
           every couple of tours instead of freezing. The measured case the `dug > 1` guard exists for
            (`dug=1 dropped=1` pinning a growing shelf) still takes neither branch.
   Live on both players within minutes: `dug=0 dropped=1 stock=33` → `dug=1 dropped=0 stock=34`, over and
    over, with `barren` falling 8 → 1 as the drops un-barren paths and the re-digs then succeed.
   **Settled into a stable limit cycle, the same one on both players independently:**
    `40 → 39 → 38 → 39 → 40 → 39 → 38 → 39 → 40` — up to the window, down two on the whittle + dry roll,
     straight back on the dig. It does NOT drift toward the floor, which was the one failure mode this
      change could have had; and the shelf now reaches a FULL window of 40, against 23–34 before. Two
       independent players converging on the identical cycle is the tell that it is a property of the
        mechanism rather than a lucky sitting.
- **THE DIAL BLENDS RATHER THAN CUTS** (the owner: *"it should be very effective at rapidly skipping
   tracks. getting them to blend together a little even"*). `Radio_skip` used to `close()` the voice on
    the spot, severing a graph mid-sample — a click, and a burst of them on a fast run of skips. The
     outgoing voice already has audio scheduled AHEAD of the playhead, so ramping its gain down while the
      incoming voice ramps up gives a real overlap: skip a primed track and the two genuinely cross.
       Un-primed, the same ramp degrades to a clean fade instead of a click — the safe direction to fail.
   `Audiolet.fade_in(secs)` is the new half; `fade(1, secs)` could NOT do it, because it anchors on the
    CURRENT value and a fresh voice sits at gain 1 — the incoming track would land at full volume.
   The outgoing voice is closed on a timer, and any voice still fading when another skip lands is closed
    AT ONCE — the stack is bounded at one however fast the dial is turned, which is what keeps rapid
     skipping cheap rather than an accumulation of dead graphs. Live pages only: a timer and a gain ramp
      are wall-clock, and a driven world must tear its voice down synchronously or every Book that skips
       would be racing a `setTimeout`. **Unverified from here** — a blend is pixels-and-ears, and neither
        round-trips a fixture; `runner_shot` cannot hear. Wants the owner's ear on a fast run of skips.
- **GROUND TRUTH OF THE SHARE, finally measured — the share is /app ITSELF.** The `died=` electrode (a
   `.c` string naming where a give-up walk ended) came back `died=src/routes h24`,
    `died=Ghost/test/Story/Lake h24`, `died=wormhole/Ting/2026-07-02/160434 h24` — the wander was
     spending its whole 24-hop budget inside the source tree. So the crate is the repo working tree,
      with the owner's music in `0 spawn/` inside it. Counted from the container:
   | directories | 528 (435 of them under `wormhole/`) |
   | directories holding audio | **7** |
   | audio files | **62** |
   Album sizes 18, 13, 11, 8, 8, **3**, **1**. **Part of the founding complaint was ground truth, not a
    defect**: *"somehow two of them only have one track each"* — the last two directories are
     `Charif Megarbane - Tayyara Warak (2022) [FLAC]` appearing TWICE, once with 3 tracks and once
      holding a single file. That copy really does hold one track. Before theorising about a crate,
       count it; the container can see this share even though it cannot see an FSA-picked one.
   This also sizes the remaining work honestly: the wander must find 7 music directories among 528, and
    `wormhole/` alone is 82% of the tree. Deadness collapses it bottom-up, but every barren leaf needs
     two visits (the `z` confirmation), so convergence is on the order of ~1000 directory visits.
- **A THEORY KILLED BY SIMULATION BEFORE IT WAS EVER TYPED INTO THE GHOST.** `est` prices an unvisited
   directory at 8 and sums over subs, so a directory with 20 unexplored subdirs estimates 160 tracks and
    out-weighs any real album ~12:1 — and source trees are the branchiest thing there is. That reads like
     an obvious bomb. It is not: an EXPLORE arm (unvisited prior 0 plus a flat per-branch curiosity
      bonus) measured WORSE on a repo-shaped share — 98.8 albums against 110.4. The per-descendant prior
       is not a bug, it IS the exploration drive, and flattening it costs discovery. **Simulate first;
        this is the second standing hypothesis this week that the data refused.**
   The same run is the evidence for what DID land, on the shape that actually matters — a repo-shaped
    share of 904 dirs with music buried beside a big source tree: albums reached **20.5 → 110.4** of 130,
     tracks **54 → 358**, empty digs **372 → 217**, at lower hop cost.
- **THE COVERAGE CLAIM IS NOW LIVE EVIDENCE, NOT SIMULATION.** Counted off Lefto's real shelf of Righto's
   shared stock (33 records), against the disk truth above:
   | testsounds 8/8 · Deadfly 8 of 11 · Calexico 7 of 13 · Resonating 5 of 8 · Marzipan 4 of 18 ·
    Tayyara(arabia) 1 of 3 · Tayyara(dup) 0 of 1 |
   **Every album is represented except the one-track duplicate**, and the distribution is the OPPOSITE of
    proportional-to-size — the biggest album on disk (Marzipan, 18) holds the fewest (4) while the 8-track
     testsounds holds all 8. That is the album-fair whittle doing precisely its job: it drops from the
      currently-fattest album, so a big album cannot crowd out a small one. Nothing is stranded at one
       track any more except the folder that genuinely contains one file.
   Method note worth keeping: the world snap embeds records in TWO forms — plain snap text and, when a
    title or directory holds a comma, escaped JSON. A `grep -oE 'path:[^,]*'` silently drops both classes
     (truncates at the comma, misses the backslash-escaped ones) and undercounted by a third here, hiding
      a whole album. `tr -d '\\'` first, then match to `,sr=`.
- **COMPLETE DISCOVERY, MEASURED AGAINST DISK TRUTH.** Righto reached `known=62` — every audio file in
   the share — from a COLD learn map in ~13 minutes: 27 → 40 → 43 → 44 → **62**. The old code plateaued
    at 48–49 after hours and stopped there. That number is not a proxy or a ratio: the crate holds
     exactly 62 files (counted above), so `known == 62` IS total coverage. This is the gate the whole
      §0 entry was reaching for, and it is now a measurement rather than a simulation.
   Lefto sat at 49 through the same window, and 62 − 49 = 13 = exactly the Calexico album — i.e. one
    music directory its own wander had not yet entered (its SHELF holds 7 Calexico tracks, but those
     arrived over the wire from Righto, not from its own walk). A testable prediction, not a worry:
      `known` should step to 62 when it lands there, and its `dirs` was still climbing (111 → 131).
   **Confirmed at 02:46** — Lefto went 49 → **62** in a single step, i.e. +13 exactly, the Calexico album,
    the moment its wander entered that folder. So BOTH players reached complete discovery of the share
     from cold maps, and the one player that lagged did so for the predicted reason rather than a second
      cause. Stock settled at 39 against a window of 40 on both. Note Righto found all 62 having learned
       FEWER directories than Lefto (119 vs 139): the win is not "walk more", it is "stop re-walking the
        barren", which is exactly what deadness + the slot cursor were for.
- **Still open — REVISED at the end of the sitting, because most of this bullet was overtaken.**
   `open` fixing wasted hops but not coverage still holds, and the fair whittle is still the only thing
    that moves shelf composition. But "the coverage claim wants more live turns than it has had" is no
     longer true: both players reached 62/62 against counted disk truth, and the shelf distribution was
      read off the live snap (biggest album fewest records). **Coverage is settled; do not re-litigate it.**
   What is genuinely still open:
   · **The visualise-the-scrolling-Mag idea** — untouched, and the owner said only *"perhaps"*. Face work,
      unprovable from the container (pixels or it didn't land), so it wants a steer before it is started.
   · **The blend wants an ear.** Proven ACTIVE rather than inert — it rides the same `humdinger` gate as
      the learn map, which is demonstrably populated — and proven leak-free by construction, but whether
       it SOUNDS like a blend is not a question this container can answer.
   · **Sounditron 0.29 → 0.14 red**, caused by these changes and expected (it is resident on the live
      tabs where the new meander runs); its re-record is still blocked on stock nondeterminism.
   · **§0 is ~950 lines across five dated entries** and wants folding into §3.x/§9 — the doc's own rule,
      and an editorial call for the owner rather than something to do unilaterally.
   · **THE WARM WINDOW AND THE DIAL DISAGREE ABOUT WHAT MATTERS — an efficiency question, NOT a bug.**
      `Ra_restock_beat` warms the next `Ra_keep_ahead` (4) records **in catalog order**, rotated to start
       after the playing one; its comment assumes sequential play ("so the NEXT track starts instantly").
        `Ra_dial_next` picks **uniformly at random** across the whole catalog. With ~33 records that is a
         ~12% chance a dial turn lands on something already warm — so ~7 turns in 8 pull cold, and a
          SKIP is a dial turn, which bears directly on the owner's "very effective at rapidly skipping".
      **Measured before believing it, and it is not currently biting**: zero `starve`/`unstarve` marks on
       either player's ring across a session with 140–194 skips, and `primed [id]` → `primed-open [id]`
        shows the prime being spent on the fast path. A loopback pair pulls fast enough to hide it. On a
         real wire it would not hide. Options if it ever surfaces: have the dial PREFER records whose
          preview is whole (uses what was already paid for, but narrows variety toward the window), warm
           a random sample instead of a sequential run (matches the dial's distribution, same hit rate),
            or simply raise `keep_ahead`. **A design call for the owner — do not just change it.**
      Read both functions before touching either; this subsystem punished three plausible readings in one
       sitting (page clumping "breaks the shuffle" — the dial is random; "only 5 dial candidates" —
        `preview` is PROMISED not landed, so husks are candidates; and the branchiness bomb).

**2026-08-07 — "ONLY 3 TRACKS COME OVER". TWO BUGS, BOTH MEASURED, BOTH FIXED, BOTH LIVE-PROVEN.**
 The owner's report was exact and the two causes are independent — one at each end of the wire. Between
  them a listener heard the first three tracks of a friend's crate and then nothing new, forever, while
   every instrument said the share was healthy. **This is the shape to remember: the CATALOG crossed in
    full and the dial looked fine; only the BYTES were pinned.** A census of what arrived would have
     shown 15 records and declared victory.
 · **(1) THE KEEP_AHEAD WINDOW NEVER ROTATED — a two-world read.** `Ra_restock_beat` anchors its
    rotation on `w.c.play`, which is the PACED LISTEN's playhead (`Ra_term_stream_open`) — the Books'
     cursor. Live there is no paced listen: the real playhead is `radio.c.rec`, and **the radio lives in
      the RADIO world while the share beat calls the restock with the STATION world.** Two different
       particles, so `w.c.play` was permanently undefined, `at` stuck at 0, and the window sat pinned to
        the first four records of the catalog for the whole session.
    MEASURED: Righto mirrored 15 of Lefto's records and fired exactly **four `want-first` marks** — all
     within four seconds of boot — then never wanted another. Three of the four ever played.
    FIXED: `Ra_playing_id(w)` — paced-listen cursor first (so every Book keeps its pinned cursor and no
     fixture moves), the live radio second, null if neither stands. One line at the call site.
    PROVEN: four NEW `want-first` marks in the first three minutes after the fix.
 · **(2) BOTH STOKERS HAD GONE PERMANENTLY TO SLEEP — the wrong organ was asked about sharing.**
    `Stoker_look` digs only while `fresh < 8`, where `fresh` counts records MY radio has not heard this
     sitting. But the default radio is SOURCE-EXCLUSIVE (friends' collections, not my own), so my own
      records are never heard, `fresh` never falls, and **the dig gate never opens again**. The gate is
       right for what it guards — my own listening never running dry — it is simply the wrong question
        to ask about what I SERVE.
    MEASURED: `advertise records=21` on Righto and `records=15` on Lefto, dead flat for entire sessions,
     with the collection barely sampled.
    FIXED: **`Stoker_tour` — the conveyor.** The owner's ruling: *"Mag:shuffle seems to have an end, but
     it can spawn more at the end constantly, and whittle off the top."* One ordinary dig, then whittle
      the oldest back to a window of 24 (`w.c.tour_window`), every 90s (`w.c.tour_floor_ms`). The Mag
       stops being a list that fills once and freezes and becomes a MOVING WINDOW over the collection.
    PROVEN: stock 21 → 23 → 24 within three minutes, `advertise records=` moving for the first time.
 · **NO CURSORS, and none were needed** (the owner: *"the old cursors were terrible, careful with that.
    wearing out tracks, etc."*). The old `Radios.svelte` machine kept a per-client cursor on the
     broadcaster, `KEEP_AHEAD=5` against `co_cursor_N_least_left`, `orecord` remote-cursor reports every
      other seq, and a wear-out ledger. **The conveyor needs none of it**: the supplier rotates its own
       window on a plain clock and the ordinary catalog diff tells every friend what came and went — no
        per-listener state, nothing to get out of step, nothing to resume. A listener who misses a track
         meets it again on a later turn of the wheel. Keep it this way.
 · **Live-only by construction, deliberately with ONE gate.** `Stoker_tour`'s only caller is the share
    beat, which cannot run in a Book (`Swarm_share_up` is reached only behind `!w.sc.w` and from
     InvitePanel's `$effect`, which no Book mounts) — the same argument `Ra_shuffle_cull` already rests
      on. A humdinger check was written and then REMOVED: humdinger is the end-user-PAGE stamp, so a tab
       booted `?B=` — which the owner's own pair answers to — would silently never tour, and that failure
        looks exactly like the bug being fixed. One gate, in one place, checkable.
 · The offer `mark` gained the tour count: add-one-drop-one leaves the record count identical, so a
    pure-count mark would call a completely different catalog "unchanged" and sit on it until the 60s
     floor tripped.
 · **THE WHITTLE HOLD — "no Pier can be cursoring that Record before we can whittle it" (the owner,
    same sitting). And it needed NO cursor.** The fact was already ours, locally: `rec.c.want_ts` is
     stamped by `Repli_serve_want` every time any Pier asks for a page of that record (it exists for
      the release-after-serve sweep, which holds a rec's bytes while a sink is still asking). So the
       whittle skips any record wanted within `w.c.tour_hold_ms` (default 10 min — a listener pulls a
        whole preview then plays it for minutes without asking again, so a tight hold would whittle
         the very track they are mid-way through).
    **THIS IS THE WHOLE DIFFERENCE FROM THE OLD MACHINE.** `Radios.svelte` kept a per-client cursor ON
     THE BROADCASTER, advanced by `orecord` reports over the wire, and got out of step exactly as often
      as the wire did. Here nothing crosses, nothing is remembered per listener, and nothing can
       disagree — we observe our OWN serving and draw the obvious conclusion. A quiet Pier simply stops
        holding records. If every record is held the wheel does not turn that time and the Mag grows a
         little; that is the safe direction to fail in. `held=N` rides the tour mark.
 · **THE CONVEYOR THEN STALLED — and the electrodes named it in two reads, which is the point of them.**
    First read: `picks=2 got=2 dug=0` — the wander returns tracks, they stock fine, the shelf does not
     grow. Two causes fit that equally and want opposite fixes, so the second electrode was ONE number
      (`hit` — picks that were in the skip set) to separate them. Read: **`hit=0`** — the path filter
       was working perfectly; the picks were genuinely not already-shelved paths.
    THE CAUSE, from `p0`: the wander at **base `''`** returns `testsounds/The Sines - Deep A.wav`, while
     those same records were shelved under base `testsounds` with `sc.path` = the BARE filename. Same
      file, two path spellings, so no path-keyed skip can ever match — and the identity is a sha256 of
       the BYTES, so the duplicate is unknowable until the whole file has been read. The tour re-read
        the same audio every 90s to land nothing.
    FIXED with the only thing that can work here: **learn the barren path**. When a pick stocks and its
     id was already held, remember that path (fully qualified, on the House, bounded 4096) and the
      wander looks past it forever after. Self-correcting, needs no new sc key, and covers every path
       spelling by construction rather than by enumerating them. `dup=N` rides the tour mark.
    (The meander also now tests BOTH a bare and a fully-qualified key, which catches the easy half
     directly. Records carry no base, so that alone could never have been sufficient.)
    **AND THE LADDER STOPPED ONE RUNG EARLY — the actual reason it stayed stuck.** `Stoker_dig` walks
     three bases (`music`, ``, `testsounds`) and used to `break` on the first that returned ANY picks,
      regardless of whether they landed. So once the wander settled into a crate already held in full,
       every turn ended there and the other bases were never reached. Measured on Lefto: four turns of
        `base=testsounds picks=2 got=2 dug=0` against a testsounds of EIGHT files, all shelved — then
         the one turn that happened to start at base `''` dug 2 immediately (17→19). **The wander was
          never the problem.** Now it breaks only on a base that actually added something.
    The barren test also changed to the honest one: the shelf count ACROSS A SINGLE `Ra_stock_one`
     call, rather than comparing the returned id against a pre-built map. That map read `dup=0` while
      the shelf visibly refused to grow — a measurement disagreeing with the thing it measured, which
       is never worth keeping. [[comments-assert-unmeasured-properties]]
 · **A DRY TOUR USED TO BE SILENT — fixed within the hour, and it is the same bug as everything above.**
    The first cut marked only `dug > 0 || dropped > 0`, so a tour whose wander found nothing left no
     trace, and a conveyor that had quietly stopped looked identical to one running fine. Caught by
      reading the live ring: `advertise` still beating (so the share beat, and therefore the tour, was
       certainly running) with not one `tour` mark behind it. Now every turn marks, `dug=0` included —
        that is the honest signal that the tour has run out of collection to tour. ~40 marks an hour
         against a 1200 ring; the silence was never worth the room it saved.
 · **LANDED, same sitting — `mirror-merge` now counts BIRTHS, not touches.** It counted every Record a
    frame touched, and a CHUNK frame touches its record too, so it fired ~1/sec for the life of a tab
     and said `recs=1` every time. The ring caps at 1200 marks, so ~20 minutes of ordinary transfer
      traffic evicted every advertise/tour/want-first/page-first behind it — the marks that carry the
       story (read live: **37 `mirror-merge` against 4 `want-first` in one dump**). It also made the
        mark's own comment false: "records actually landing" describes a BIRTH, and a re-touch is not
         one. One `.c` latch. The chunk path keeps its own once-each marks (`page-first`,
          `stream-first-chunk`). [[comments-assert-unmeasured-properties]]

**2026-08-07, same sitting — THE PLAYER'S FEEL: four owner rulings, landed.** ("the players" is now the
 owner's word for the Sounditron tabs.)
 · **⎵ skips, ⏎ heists** — page-level in BigSoundland, because on a radio your hands are not on a
    widget and hunting for the ⏭ button is the thing the keys exist to remove. Guarded against
     stealing a typed key: any editable target (input/textarea/select/contenteditable) or a modified
      press passes straight through, else ⎵ would skip a track per word while renaming a friend.
 · **⏎ takes the ALBUM, and that is the settled model, not a shortcut.** `Heist_keep_pick_all/_none/
    _seed` were REMOVED 2026-07-30 ("let's not support single tracks... we are doing that already") —
     a %Heist seeds on ONE record id and `Heist_keep_default_pick` keeps the whole folder it describes.
      `Radio_heist_now` mints the keep **primed, not pulling**: the beat rummages and default-picks,
       the human still presses ▶. A key you can hit by accident must not start writing files into a
        collection. Idempotent per record — the seed IS the identity.
 · **Tracks tune in part-way through** (`Radio_start_seq`) — a radio you switch on is already mid-song;
    every track opening at 0:00 is the tell of a playlist. ONLY inside chunks already held, never past
     the first half of them, always leaving runway: a start that had to fetch its own first chunk would
      trade the feel for a stall. The pump already supported a non-zero entry (the mid-encode resume
       path). **The non-obvious half:** `radio.sc.at` is not cosmetic — `Swarm_share_beat` derives its
        want-ahead window from it (`head = at / seg_s`), so tuning in late had to carry a `c.at0`
         offset or every full-length pull would have aimed at the wrong part of the song.
 · **The next track is decoded before you ask for it** (`Radio_prime` / `Radio_peek_next`) — the owner:
    "try to always have one very ready to go, there's a lag between click and sound". The lag is
     DECODE, all of it after the keypress. So while the current track has >4s decoded ahead, the next
      one's opening chunks are decoded into plain planar Float32 and held. **RAW PCM, NOT SCHEDULED
       AUDIO, is the whole trick**: a skip replaces `radio.c.aud` with a fresh audiolet, so anything
        already scheduled would die with it — Float32 belongs to nobody and lands on the new audiolet
         the instant it exists. Priming also FIXES the random start seq, so prime and open cannot
          disagree about where the needle lands. `Radio_peek_next` walks the lineup READ-ONLY (the dial
           consumes its head, so priming must never call it). Marks: `primed`, `primed-open`.

**PROVEN LIVE ON BOTH PLAYERS at the end of the 2026-08-07 sitting** — the marks to look for, and what
 a healthy pair reads like:
 · `tour dug=N dropped=N held=N stock=24 skip=32 dup=2 barren=9` — the conveyor turning, the whittle
    HOLDING records a Pier is pulling, and the barren set genuinely learning (skip = records + barren).
 · `primed [id] start=1 chunks=3` then `primed-open [id] seq=4` — the next track decoded before it was
    asked for, and then SPENT at open. Both marks on both players is the lag actually being gone.
 · Lefto grew 17 → 24 and stopped at the window; Righto sits at 23–24 whittling. Flat `records=N` in
    `advertise` for minutes on end is the tell that the stoker has gone back to sleep.
 **Books at close:** LakeTiles 9/9, MusuRadio 9/9 c0, MusuStock 5/5, SwarmShare 9/9, RepliUpsert 7/7 —
  all `ok_pct=1`. MusuHeist reads `ok_pct=0.95` while every one of its 22 steps reports `ok=1` and **not
   one of its 001–022 fixtures moved** — an aggregate disagreeing with its own per-step reading, worth
    chasing someday as a REPORTING bug, not a regression. Attribute by fixtures, never by ok_pct alone.

**THE SERVE SIDE RETRIES A HOPELESS DECODE FOREVER — found live 2026-08-06 by the new lane, minutes
 after arming it. THIS IS THE NEXT REAL FIX.**
 Measured on Righto (read-only): **1087 `pcm-decode-start` marks against 2 `pcm-decode-done`**, while
  two of the asker's wants sat `park-stall off=16 secs=480` — eight minutes. Both dead records now say
   why in one word: **`pcm-nosource why="no card"`**.
 THE CHAIN: `Ra_source_pcm`'s first gate is `Ra_card(w, rec)`, which is `Ra_stock_find(nav, pub, id)` —
  no radiostock file ⇒ null. It returned null **with no mark, no latch and no memory**, and
   `Ra_transcode_ensure`'s `.then()` clears `pcm_pending` UNCONDITIONALLY, so the next pump beat re-kicks
    the same doomed decode ~600ms later, forever. The want stays parked; the ASKER sees only a want that
     never lands. A serve that can NEVER succeed is indistinguishable from a slow one — the §0 silent-fact
      shape exactly, and a fourth sibling of the decoder corpse.
 **THE DEEPER ONE, and it indicts a documented safety property.** `Ra_stock_gc` caps radiostock at 256
  files per pub and wears the oldest off; the ruling that made that safe (§0, 2026-07-26) is *"a dropped
   file is one re-dig from source — `Ra_stock_one` is idempotent"*. **Nothing on this path re-digs.**
    `Ra_source_pcm` just fails at the gate. So the GC's stated regenerate-on-demand property is asserted
     in a comment and not implemented here — [[comments-assert-unmeasured-properties]] again. (PROVEN: the
      stock file is absent and the retry is unbounded. NOT proven: *why* it is absent — GC eviction vs the
       dead-source `Ra_stock_drop` in this same function vs never minted. Electrode that, don't guess.)
 **LANDED:** `pcm-nosource` — the fact made visible, once per record per reason, the latch read by the
  next line so it cannot rot into a write-only one. **NOT landed, deliberately — the design call is the
   human's:** (a) the retry policy (a hard latch would make a genuinely transient missing-nav permanent —
    wants backoff, not a stop), (b) **re-dig instead of fail**, which is what the GC ruling already
     promises, and (c) TELL THE ASKER — `repli_missed` (landed 2026-08-06) is the ready-made lane and this
      is precisely its meaning.

**LATE 2026-08-06 (a second thread, "Puck") — the two-tab-loop build. ALL COMPILED (LocalGen) and
 live-proven on the pair; nothing committed.** The plan (approved): iterate the live pair with minimal
  human gestures — HMR ghost-compile needs NO tab reload, so the tap tax only falls on reloads.
 **PROVEN THIS SESSION: a `.g` edit reaches the human's MANUAL tabs with no reload and no gesture** —
  the new marks appeared in Righto's live ring minutes after LocalGen wrote the gen. That is the whole
   iteration loop, and it costs the human nothing.
 · **Both §0 items below are now CODE, awaiting compile+live proof:** (a)'s trace gap got the
    **crate-birth lane** — `boast-heard` (Swarm_ive_got) → `crate-born` (Repli_mirror_lib) →
     `mirror-merge recs=N` (Repli_recv_lines) → `want-first` (Repli_want_next, the one funnel) →
      `page-first` (Repli_attach_page, latches `rec.c.first_page_t`) — one unbroken ring story from
       advertise to dial; (b)'s meander now draws **weighted by lazily-learned subtree counts**
        (`M.c.meander_learn`, zero extra IO, unvisited→prior 8) — GATED to `humdinger` pages so every
         Book's prandle sequence is byte-identical, **no re-record needed** (dodges the fixture CARE).
 · **The live wander was never random — the owner's hunch was exact.** `Radio_prod_seed`'s gate
    `if (w.sc.w) return` short-circuits on /BigSoundland because the resident world IS `w:Sounditron`
     (BigQualand stamps the default), so every real boot walked the fixed `[1,2,3,4]` wander. Fixed:
      the predicate is now the PAGE not the world — `top_House().c.humdinger` (boot_qualand's
       end-user stamp) seeds crypto entropy; machine tabs (editor, ?B=, grid) keep the pin.
 · **Instruments hardened:** `tracelog.mjs` now REFUSES unknown args (the evening-costing mtime
    footgun), takes `--runner=<pub-prefix>` + both `--file` forms — verified against the live dumps.
     `runner_ask` grew CLI plumbing for three new ops — `socklog [on|off] [--reload]`, `dump` (skip
      the ~5s throttle), `poke <allowlisted verb>` — the runner-side `Lies_runner_ask_recv` branches
       are WRITTEN INTO THE PLAN but not yet landed (LiesFunk HMRs into live tabs; held with compiles).
 · **Rig facts worth keeping:** an end-user page = `humdinger` is the durable prod-vs-driven
    predicate; `pw_drive.mjs --cdp` + the flock droids (`--autoplay-policy=no-user-gesture-required`,
     remoteWormhole grant is one-time+infinite) are the path to a ZERO-gesture pair when the manual
      loop gets annoying. Commit points: (1) tracelog+runner_ask CLI, (2) the .g trio once compiled
       and live-proven.

**NEXT SESSION STARTS HERE (2026-08-06, end of day).** Two items, in this order.

**(a) GET REAL RADIO TRACES — the owner's ask, and the tooling now mostly supports it.**
 Two instrument bugs were found and fixed at close of play 2026-08-06; read both before trusting a
  trace, because each produced a confident wrong diagnosis first.
 · **`tracelog.mjs` has no `--runner` flag** and silently ignores unknown args, defaulting to the
    newest dump BY MTIME. `tracelog.mjs --runner=f5da6599b8505881` therefore pulled nothing and
     printed **58517's** ring (an idle grid runner, no piers) whose honest `starved why=nobody
      homes=0 recs=0` I spent an evening attributing to Righto. Righto's own dump said
       `18 why:"gathering"` throughout. The tool does not pull at all: the TAB dumps
        `wormhole/_trace/<role>-<pub>-<boot>.jsonl` every ~5s through its own FSA share, and ONLY
         once 🪪 Id hatch → **socklog** is armed on it. `--file` takes a SPACE, not `=`. Check the
          filename in the header line against the runner you meant; `--list` names them. Over the
           relay, `runner_ask world` is the op that reaches a live tab's ring.
 · **Console `+Δms` was ring-relative and therefore lied under `grep`** (dropped lines silently widen
    every gap — this is what produced a bogus "advertise fires every 601ms"). FIXED: `fmt()` now
     prefixes an absolute `@Nms` anchored to the first shown mark, so a filtered line still says when
      it happened. Deltas are computed after `keep`, so tracelog's OWN `--heist`/`--life` filters were
       always honest; only downstream `grep` broke them.
 With that, the first real measurement lands: Righto's dial→starve loop runs at a **flat 800ms**
  cadence. What we still cannot see is the interesting part — WHY a radio with a live sealed pier
   reads `gathering` (live peer, every record a husk). That is the trace to build next: the owner
    wants "really good traces of the radio behaviour", and the honest gap is between `advertise
     homes=1 stocks=1` (the census's view of MY OWN home) and `starved homes=0 recs=0` (the dial's
      view of `w.o({MusuThem:1})`, the FRIENDS' shelves). **Those two `homes` count opposite sides
       and must never be read as contradicting each other** — that near-miss cost an hour tonight.

**(b) Then §3.x #33 — the collection wander samples branches, not tracks.** `Crate_nav_meander`
 (`Crate.g:212`) does `prandle(dirs.length + (audio.length ? 1 : 0))`, i.e. a uniform pick over
  CHILD DIRECTORIES with all of a directory's audio collapsed into ONE outcome. So a deep sparse
   branch and a 200-track album are equally likely, and the owner's report stands: whole albums that
    are ⅔ of the collection are never reached by pressing next. Weight the pick by subtree track
     count. **CARE: `prandle` is the Book determinism source — changing the draw order moves every
      fixture that wanders.** Re-record in the same commit or the Books go dark (that is exactly how
       MusuRaChase/MusuRaStream went red for a month).

**STATE OF THE TREE at handover.** ~224 uncommitted insertions across five ghosts (Swarm, Radio,
 Repli, Peeroleum, Heist), all compiled, and now **live-verified read-only on Righto**: `1 pier,
  1 mutually sealed` (half-seal healer holds), `advertise records=20→21→22 artists=14 cw=1 selfs=1
   homes=1 stocks=1 told=1` (the boast re-fires on census change and the peer is told; `cw=1`
    retires the "census_w is never set" misread, which was boot ordering), no `share-no` trace (the
     share arms from `Stoker_ensure`, not the UI `$effect`). NOT verified: the 30s floor's
      SUPPRESSION timing — needs the unfiltered measurement in (a). **This is a commit point.**
 `MusuRaStream` fixtures are back at HEAD (owner ran the restore 21:33); `MusuRaChase`'s three
  `toc.snap`s carry only `TimeSpool` samples, which any run leaves. **Re-record RaChase/RaStream
   INSIDE the commit that carries the ghost changes** — fixture follows the code decision. The
    completion-gated runner script is `scratchpad/book.sh` (polls `phase` to `done|failed|
     ledger_timeout` AND gates on `run.book`, because `run --watch` returning is not completion and
      a concurrent agent can own the runner).
 Per the reviewing agent: the discovery findings + the design-questions checklist below belong in
  **`Composition_todo.md`** (its scope note claims the not-the-transfer-loop failures); leave this
   day's arc and the mechanism-local fixes (CPU, decoder corpse) here with a pointer. Not yet moved.

**WHERE WE ARE, 2026-08-06 (written for a reviewing agent — read this first).**
 The day started on CPU burn and ended on discovery. The arc, so the diff makes sense:
 · **Morning — the downloader burned CPU and transfers crawled.** Named by a devtools profile, not by
    guessing: `array_prototype2.includes` 83% total, `get_proxied_value` 80%. `.svelte.ts` compiles
     through Svelte, which rewrites `.includes()`/`.indexOf()` into proxy-aware helpers that dispatch
      per element — so a linear scan in `Stuff.svelte.ts` is linear × proxy dispatch. Fixed with a
       `Set` in `o_query`, a `vmaps` Map index behind `TheX.v_index`, and three
        materialise-for-a-presence-test bugs (`Ra_chunk_map` → `Repli_chunk_at`/`Ra_chunk_have`).
         Step times fell ~7.7s → 2.5–4.5s and the human confirmed heisting felt fine.
 · **Afternoon — with the bytes moving, the DISCOVERY layer turned out to be the real illness.** That
    is the three-bug section below, and it is the load-bearing part of this entry.
 · **Live rig**: Righto `f5da6599b8505881` + Lefto `96d0cf8852651a73`, `BigSoundland?I=<id>`, Invited to
    each other. Read-only probes only (`runner_ask world`, `tracelog.mjs`) — never run a Book on them.
     Everything below was found on that pair; no Book reproduces any of it, which is the point of §4.

**THE BOOK GATE IS PARTLY BLIND — know this before trusting a green (2026-08-06).**
 · **Green and trustworthy** on runner `58517b484a8e896d`: MusuHeist 22/22, RepliUpsert, RepliSplit,
    RepliShadow, MusuStream, MusuResume, MusuRadio, SwarmShare, MusuStock, LakeTiles.
 · **A runner can lie.** `a67a5d04a04fd334` settled EVERY Book all-red including `LakeTiles`, which
    touches nothing under test, while `58517b` gave the same Book green in the same minute. Both answer
     `ping` identically. **Run one control Book your change cannot affect before believing a red sweep.**
 · **A Book with no recorded fixture mints one on the spot and reports green.** `Radiation` and a
    mistyped `MusuRepli` both did — a vacuous 1/1. A `done:1 total:1` result gates nothing; check
     `wormhole/Story/<Book>/` exists before counting it as evidence.
 · **MusuRaStream / MusuRaChase were red for a month and nobody noticed.** Not a code fault: their
    fixtures were last recorded 2026-07-08 and had missed three later, intended changes — the swarm
     clock pin (`w.sc.now`, Radiation.g:78, commit 7935704a), seq becoming a STRING everywhere (so a
      literal query never trips the `{k:1}` presence wildcard), and `repli_want` no longer booking an
       inbox unemit (the documented want-bypass). Every one of those is already green in MusuBuddy,
        MusuMag, MusuHeist and MusuBay — `grep -ho "unemit[=:]" wormhole/Story/<B>/0*.snap` dates any
         fixture in one line. Re-recorded 2026-08-06.
 · **Still unexplained: MusuMag sits at 0.7** (7/10) with an up-to-date fixture, so it is a real
    failure and the one honest unknown in the set.
 · **Attribute before you blame yourself.** A controlled revert of all five ghosts to HEAD reproduced
    MusuRaStream's step-1 dige `9304f7107d9abdfb` byte-for-byte — proof the day's work was invisible to
     it. Books are deterministic; this costs ten minutes and settles authorship absolutely.

**THREE SILENT-FACT BUGS IN ONE AFTERNOON (2026-08-06) — and they are the same bug.**
 All three were found on the live Righto|Lefto pair, all three are compiled, **none is yet verified
  live** (the tabs were mid-reload; the Book sweep on `a67a` is the regression gate, not the proof).
 1. **The music boast had exactly ONE trigger.** `Swarm_gossip_music` was called only from
     `Swarm_hear_hi`, on a non-reply `hi` — i.e. at standup, which is the one moment the census is
      *guaranteed* wrong, because both things it counts stand LATER than the handshake (`radio_w` when
       the dial first runs `Stoker_ensure`; `census_w` when `Swarm_share_up` arms). So a tab boasted
        `records:0` and nothing ever recomputed it. **The tell was not the zero — it was that a tab up
         for eight minutes held three `advertise` marks, all inside its first 40s.** Cure:
          `Swarm_boast_floor`, the twin of the re-offer floor already sitting in `Swarm_share_beat`.
 2. **The live share armed from a UI `$effect`.** `Swarm_share_up`'s only caller was
     `InvitePanel.svelte`'s effect, which polls on `H.version` and had to *happen* to run after
      `Stoker_ensure` stamped `radio_w`. Lose that race and the tab arms no share loop — so it never
       offers its stock AND never registers an rx for the friend's cast. It can neither send music nor
        receive it while looking perfectly healthy: sealed, Music-granted, happily playing its own
         local shelf. Cure: arm it in `Stoker_ensure`, at the instant the precondition becomes true,
          Book-gated on `w.sc.w` (the share starts a wall-clock pump; `Swarmation.g:1000` forbids that
           in a Book). Plus `Swarm_share_no` — the refusing verb now names which guard failed.
 3. **The serve MISS never travelled.** `Repli_serve_miss` logged on the SOURCE; its own comment
     conceded it — *"if a sink stalls, look at the friend's console for this"*. The sink was told
      nothing, so an unservable want looked exactly like a slow one, and the repair was Heist's blind
       ladder: 3 unanswered asks at 4s behind a 20s throttle. Measured: `heist-noprogress asked:12
        landed:1 of:8 secs:46`, then full-speed serving the moment the re-census landed. Cure:
         `repli_missed`, the exact twin of `repli_parked` — same lane, same shape, opposite meaning.

 **THE SHAPE, and the brief for any mega-do-up of this spine.** In every one of the three, *one side
  already knew the fact* and there was no path for it to reach the side that needed it; the missing
   path was then papered over by a repair that **inferred** the fact from timeouts. Note that the
    half-seal entry below is a fourth instance of the same family — a repair keyed to the wrong
     predicate — and the CLI's `world` could see in one line what the healer could not.
 So the design questions worth a session, in order of how much they'd buy:
  - **Which facts does one peer know that the other cannot?** Enumerate them. Every one is a candidate
     silent-death bug. `parked` and `missed` are now both told; what else — revoked grant, swept lib,
      full disk, a want past the frontier that will NEVER be reached?
  - **Which repairs infer a fact instead of asking for it?** Each is a latency floor at best and a
     permanent hole at worst. Grep for the shape: an `asks_out >= N` or a `Date.now() - ts > MS` gate
      guarding a repair.
  - **Which capabilities arm from a component rather than from the belief loop?** #2 was one; the
     `$effect` latch trio in `InvitePanel.svelte` (`self`/`stood`/`shared`) is load-bearing p2p state
      living in a UI panel. A req carries its own liveness and shows up in the snap — a `$state`
       boolean in a component does neither.
  - **Which change-triggered marks have no floor under them?** `offered_mark` has one and says why;
     the boast had none. A mark that is wrong-but-stable is a silent permanent hole.

**THE SEAL SELF-HEAL CANNOT SEE THE HALF-SEAL IT IS STANDING IN (2026-08-06) — live blocker.**
 A heist sat at *0 of 3 landed after 100 asks, 425s*, while Repli reported a cheerful 50KB/s both ways.
  `runner_ask world` named it in one line: `1 pier, 0 mutually sealed` →
   `→ one-way (half-seal) Lefto 96d0cf88 grants:[96d0cf885265→Music]`. **Our %Pier holds only THEIR
    grant.** So asks leave (outbound needs nothing), the source answers, and the answers die on our
     doorstep — `🛰☠ deliver: no Pier` — which is why both ends read as merely SLOW rather than broken.
 **Why it never heals.** `Swarm_reaccept_incomplete` (`Swarm.g:707`) is exactly the cure for a half-seal,
  but its first test is `if (pier.o({Grant:1, by: theirPub})[0]) continue  // already complete`. Ours HAS
   their grant, so it is judged complete and skipped — it never reaches the `mineC` probe. The function's
    own comment states the assumption it rests on: *"Cannot false-positive: a redeemer's %Pier is born
     with BOTH grants (Swarm_accept), so only an issuer half-seal ever matches."* That invariant is
      violated here. This is the MIRROR of the bug the healer was written for, and the healer is blind to
       it by construction.
 **The lesson worth more than the patch:** the healer tests for *the half it expected to be missing*, not
  for *completeness*. A repair keyed to one direction of an asymmetry will sail past the other direction
   forever. The predicate should be "do I hold BOTH grants?" — the same question `world` already asks to
    print `mutually sealed`, which is why the CLI could see in one line what the healer could not.
 **FIXED (2026-08-06) — this entry is kept for the lesson, not the bug.** `Swarm_reaccept_incomplete`
  now tests WHOLENESS (`mineC && theirsC` ⇒ skip) and heals both directions: a missing grant of MY OWN
   is re-minted **locally** (my signature, no wire, no security surface — the same mint `Swarm_accept`
    does at seal), and a missing grant of THEIRS re-sends `pier_accept` reusing my already-signed atom
     rather than re-minting one. Verify with `runner_ask world --runner=<id>`; the tell was
      `0 mutually sealed` against a non-zero pier count.

**THE PUMP WAS UNKILLABLE; THE DECODER WAS NOT (2026-08-06).**
 `📻⚠ Radio_pump threw … Cannot call 'decode' on a closed codec` every 400ms forever, radio stuck
  `starved`, real dead air. Not a wire fault: **WebCodecs closes an `AudioDecoder` ITSELF when a decode
   errors**, delivering the error to the callback — `Radio_dec_open` latched it (`st.bad = e`) and
    *nothing in the file ever read it*. So `radio.c.dec` kept pointing at a corpse, and since every
     re-open branch is guarded `if (!radio.c.dec)`, a dead decoder is strictly WORSE than no decoder —
      it is the one state that can never heal. `Radio_pump`'s own comment had already reasoned about
       "a malformed packet reaching `Radio_dec_feed`'s AudioDecoder" and made the **loop** survive it;
        the missing half was making the **decoder** survive it. The loop's survival is what hid it:
         a healthy-looking retry cadence with zero progress behind it.
 Cure (landed): `Radio_dec_dead(st)` — `st.bad` OR `st.dec.state === 'closed'` — checked at the top of
  the feed loop; drop the corpse, count a drop, let the existing branches re-open dirty. Plus a
   **poison guard**: if the same `seq` kills a SECOND fresh decoder the packet is bad, not the codec,
    so splice past it (`dec_bad_at`), because re-opening forever on a bad chunk is the very
     never-progresses shape, only churning objects.
 **The bomb for the next person:** a `.c` latch that nobody reads is not diagnostics, it is a silent
  failure mode with a comment on it. Grep for the other write-only latches before trusting one.
**MusuRaChase/MusuRaStream ARE RED FOR A DULLER REASON — STALE FIXTURES, NOT A REGRESSION (2026-08-06).**
 Chased as a §5.x backpressure regression, then as a knock-on of the decoder corpse above. It is
  neither. `MusuRaChase_drive` (`Radiation.g:378`) pins the swarm clock — `w.sc.now = 1751990000 + 10*n`,
   the same determinism cure MusuBuddy got — and that pin landed **2026-08-05 in `7935704a`
    "reductionistic Repli?"** *without a re-record*. **No MusuRaChase fixture carries `now=` at all**
     (`grep -l 'w:MusuRaChase,now=' … | wc -l` → 0). The world-root line is in EVERY snap, so every one
      of the 56 steps mismatches on that single key: step 1's whole diff is
       `w:MusuRaChase` vs `w:MusuRaChase,now=1751990010`, `error:null` throughout.
 **The trap this sets:** 0% with no errors reads like catastrophe and invites a hunt for a deep
  regression — but "red from step 1, identical one-key diff, no errors" is the signature of a fixture
   that predates a deliberate source change. **Diff step 1 FIRST**; it costs one call and would have
    saved two sessions of suspicion. Corollary: a determinism pin is a fixture-invalidating edit —
     re-record in the same commit or the Book is dark until someone does.
 **THE CLAIM IS FINE — that scare is dead.** `%see:'the playhead crossed the first boundary…'`
  (`Radiation.g:719`) is PRESENT in the live snaps at 14, 30 and 56, exactly as in the fixtures. The
   earlier "a claim went missing" reading came from a comparison already invalid at step 1; it was
    wrong, and nothing is lost. Two consecutive runs also produced identical diges (`edd9f464`,
     `37e6902f`, …), so the pin achieved what it was for: the Book is deterministic again.
 **The residue decomposes into FOUR committed changes, none of them from the backpressure work** —
  swept over all 56 steps, then categorised by mainkey (`unemit` 255, `emit` 90, `Stream` 29 at the
   step-56 plateau):
   1. the clock pin above — `now=`, `Pier,since:`, `Grant,time:` **and its ed25519 `sign:` recomputed
       over that time**, `Edge,at:`, `self,round=`;
   2. `path:` now stamped on EVERY `%Record`, not just heisted ones (`Heist.g:2120`);
   3. `Peeroleum.g:761` `String(u.sc.seq)` — rows encode `unemit:2` (string) where fixtures hold
       `unemit=2` (number). One committed edit, 255 diff lines;
   4. `repli_page`/`repli_lines` reclassified EPHEMERAL (`c72d9613`, 2026-07-29) — **`emit` rows
       80 → 10**, i.e. the stranded reliable-emit backlog the policy was written to kill.
  And a behavioural delta on top: **`Stream` chunks landed by step 56 went 16 → 45.**
 **Why these are still NOT accepted, despite the claim being safe.** A re-record now would bake that
  16→45 / 80→10 improvement into the fixtures while the tree still holds UNCOMMITTED backpressure
   work — so the snaps would encode a mix of four committed changes and four uncommitted ones, and
    no later reader could tell which caused what. **Fixtures follow the code decision; they do not
     precede it.** Re-record after the working tree is committed, in the same commit, and the
      accept becomes honest.

**THE GLASS STOPPED TEARING ITSELF DOWN (2026-08-05) — and §13 is new.**
 The bug that made the Keep/directories editor "snap shut" mid-typing was never a Heist bug: `replace()`
  PUBLISHES the empty half of its transaction, `agency_officing` (`Hovercraft.svelte:133`) replaces every
   actor's `w:` children every tick, and Vytui's `{#each vyto_worlds() as w (w)}` therefore got a 0-length
    list once per tick — destroying stage + faces + every face in the family's glass, once per tick, all
     along. Fixed at the reader (`ui/micro/hold.ts`, both Vytui structural gates); `replace()` untouched
      by ruling. Chain + the three cures + the light-cone note: `reactivity_docs.md` § "The transacting-empty
       render". **Live proof owed** (type in a fresh keep's directories editor across several trickles).
        Worth knowing for every face this family draws — any UI that walks `A`/`w` during render has been
         eating this. NEW: **§13** is the toplevel/BigSoundland assembly zone (the ActionButtons ask lives
          there, filed behind settling the dev-vs-end-user views).

**THE WIRE-CROSSING RUNG SCOPED (2026-07-26) — music over the REAL relay is a PORT, not a build.**
 A three-agent investigation nailed the carrier layer. The swappable-carrier seam ALREADY EXISTS:
  `%Peering.active_transport.c.connection` (interface = `send(frame)` + inbound→`Peeroleum_deliver`,
   optional `reliable`/`claim`/`subscribe`), and `Tribunal_activate_websocket` already does the one-line
    swap `at.c.connection = ws.c.port`. `Socket_real` (`Tribunal.g:57`) is the REAL relay carrier —
     binary-framed (`[header JSON]\n[raw buffer]`), auto-reconnect, carrying editor↔runner DAILY; friends
      already seal live tab-to-tab over it (2026-07-07, SwarmDoor manual). The gap is narrow: **the
       music-repli flow has only EVER run over `Lake_link`**, an in-process by-reference loopback that is a
        Story-test mock (`Peregrination.g:202` — its "Lake" name a Peregrination theme, UNRELATED to the
         LakeTiles Lies/Lang family; genuinely rename-worthy). No Book installs `Socket_real`; Sounditron
          alone touches the real relay and only proves channel *capability* ("frames CAN cross"), not a
           round-trip. **THE NON-OBVIOUS RISK:** every music Book settles frames "over post_do between beats"
            (the reliable mock) — the repli/want machinery has NEVER faced a mid-beat round-trip, while the
             real relay is async, ~400–900ms RTT, reconnect-mid-stream. THAT is the load-bearing gate, not a
              formality.
 THE RUNG (one coupled move): stand the MusuVend-style husk→preview→stream flow over `Socket_real` between
  two real tabs; the instant frames cross the untrusted relay, land `header.sign` on emit + real
   `verify_trust` on the handshake (the `Peerily.svelte.ts` 672/1011 port, reusing the Idento key that
    already signs grants). Signing a loopback is theater; over the relay it is the point — the crypto is
     UNBLOCKED the moment any flow runs over the relay. Prove MANUALLY with fingers first (does it survive
      RTT + reconnect?), THEN a distributed two-runner Book (Cluster_spec §5) as the durable gate — don't
       block the first "real" on building distributed-Story. BONUS: a working `verify_trust` on the
        handshake IS Peeroleum §5's Tyrant seam → filling it makes the mock Tyrant doubly obsolete; this
         goes AHEAD of the Tyrant cleanup. COORDINATION: the carrier swap is plain wire-side (mine to
          drive); the sign/verify half touches the trust layer → coordinate with the security thread first.
 THE CONCRETE LADDER — "two BigSoundland tabs each running Book:Sounditron, talking" (mapped 2026-07-26):
  The gap made precise: **Sounditron never sends-and-asserts-arrival.** Its beats are liveness+census only —
   beat 3 `Sounditron_channel_live` (`Sounditron.g:70`) returns a boolean "socket up"; beat 4 counts
    addressable `%Possibility` rows ("the choose-which-peer layer that does not exist yet"); beat 5
     `Sounditron_peer_live` (`:296`) = "someone holds an engagement lease OR a warm Runner row exists". Its
      sworn sentences say frames **"can cross"** (`:473`), never *did*. The ONLY real tab↔tab traffic in the
       whole file is the detached, **fire-and-forget presence pulse** in `Sounditron_trickle_look` (`:230`,
        `Swarm_pulse_all` — which by contract runs "never in a Book"), whose sole "proof" is the far side's
         hear-funnel stamping `heard_at` (`Swarm.g:380`) which `Sounditron_friends` (`:365`) reads into a
          `here` UI dot. THAT un-asserted pulse is the rung to make real. Anchors: real carrier `Socket_real`
           (`Tribunal.g:57`, send `:112`/recv `:146`→`Peeroleum_deliver`); `Peeroleum_deliver` DROPS a
            `to:<prepub>` frame unless a `%Pier` exists — first contact only via `pier_hello` (`Peeroleum.g:441`);
             the ONLY real seal path is the manual **InvitePanel join** (`InvitePanel.svelte:204` →
              `Swarm_station_up`→`Swarm_redeem`→`pier_hello`→`Swarm_hello` mutual `%Pier`+cross-signed grants).
   The three rungs, in order:
   - **(R1) MANUAL FINGERS PROOF (needs the human — I can't open/seal tabs).** Open two `/BigSoundland` tabs
      (page is `src/lib/V/BigSoundland.svelte` — NOTE moved from `L/`; `?B=Sounditron` default, `role:'sound'`
       runner), InvitePanel-join them (the live seal), watch each light the OTHER's `here` dot. This proves the
        real relay carries tab↔tab bidirectionally TODAY — it just isn't asserted. Cheapest first real.
   - **(R2) THE ASSERTED ECHO ROUND-TRIP (the actual new rung).** There is NO delivery-assert primitive today
      and NO scriptable seal/echo — `runner_ask` ops are read/run/state/declare/…, none pulse or seal. So R2
       needs: a tiny echo frame type (A→B `echo?`, B→A `echo!`) over the sealed Pier (model it on the
        corr-routed `runner_ack` reply, `LiesFunk.svelte:2494` — the one genuine real-wire request/reply that
         already works, but CLI↔runner not tab↔tab), + a Sounditron beat that sends it and SWEARS receipt
          (`got_echo_from:<prepub>`), superseding the "can cross" sentence with "did cross". This is new wire
           surface on the trust boundary → build WITH the security thread (it wants `header.sign`+`verify_trust`
            landing here anyway — R2 and the crypto are the same touch).
   - **(R3) DISTRIBUTED TWO-RUNNER BOOK (durable gate, deferred).** Cluster_spec §5. Drive two sealed tabs as
      two `runner_ask --runner=<A>`/`--runner=<B>` calls (no built-in cross-runner choreography — the harness
       gives independent addressing, `ping.self`=prepub, not a duet). Don't block the first real on building
        distributed-Story. A scriptable `redeem` op would also unblock automated R1/R2 but is itself a
         security-coordinated build (it scripts the seal).
   SPLIT: carrier/observe + the echo beat = mine to draft; the seal-scripting + sign/verify = security-thread;
    two LIVE sealed tabs for R1 = the human. NEXT PHYSICAL MOVE = ask the human to do R1 (two tabs + join +
     watch the dots), which both proves the wire tab↔tab and de-risks R2's frame shape before any code lands.
 SIDE-LANDINGS this session (the "state of Radio" review): (a) every wire-relevant Book now carries a terse
  `wire:` clause in `wormhole/Credence/toc.snap` (least-churn home vs a per-Book `Waft:Cluster` which is
   max-churn) — the census made the sim/real line legible: loopback/mock everywhere, Sounditron the lone
    real-channel Book. (b) The Sounditron "disk accumulates" nondeterminism got a real primitive, not a
     bless: `spec/Story_hygiene_todo.md` — a pre-Story `The/Hygiene/%Reset` sweep (an Assertion's inverse),
      landed opt-in in `Story.svelte`, PROVEN live (MusuLossy green ×3 + a planted decoy deleted at step-1
       start); Sounditron is the WRONG first customer (pin the probe, don't wipe the user's cache) — the
        heist/Musu family is.

**RADIOSTOCK ZOMBIE-PROOFED (2026-07-26) — a plain per-pub disk cap, no reference-tracing.**
 The on-disk `radiostock/` was the one monotonic leak: `Stoker_cull` bounds the in-memory SHELF (44 live)
  and `Ra_stock_find` culls same-enid TWINS, but nothing bounded the DIR — one file per distinct track ever
   dug, forever. Now `Ra_stock_gc(nav,pub)` (`Ra.g`, called once per landed churn in `Radio.g` beside
    `Stoker_mag_draw`) keeps only this pub's newest `Ra_stock_cap()`=**256** files and wears the oldest off
     (`Ra_stock_ls` is newest-first → `slice(cap)` is the oldest tail). The human's ruling made it SIMPLE:
      **no Mag-reference-tracing** — a `%Card` refers by id and the byte-cache regenerates (a dropped file is
       one re-dig from source; `Ra_stock_one` is idempotent, Radio.g:832), so keep-what's-referenced would be
        needless bookkeeping. Per-pub (a shared `.jamsend` never lets one identity evict another's shelf);
         best-effort (no-ops on a read-only proxy via `Ra_stock_drop`); NO sc telemetry (a gone-count is
          disk-history-dependent = fixture noise). Proven: MusuStock green ×2, MusuWear + MusuStanding green —
           the cap is a **no-op below 256** so no test that digs <256 tracks is perturbed. NOTE this bounds
            PRODUCTION disk; it does NOT make TESTS deterministic (they never reach 256) — test determinism is
             the hygiene hook's job. `radiostock` remains the ONLY timestamped disk filename in the whole
              codebase (verified) — every other disk write is deterministic-named + overwrite-idempotent, so
               once radiostock is handled, disk determinism has no other timestamp source.
 **HOW MANY BOOKS SHOULD USE THE HYGIENE HOOK (the survey):** a HANDFUL, not the suite. The natural customer
  set is the ~8 heist/marauding Books that ALREADY hand-code a `Heist_sweep(test-marrauding-of-<X>)` at
   start+end — **MusuHeist, MusuBreach, MusuBreach_wire, MusuOgg, MusuReap, MusuSoft, MusuBay, MusuLossy**
    (+ the Berthation Books) — for them the hook is a DECLARATIVE cleanup of a sweep they already run (moves
     it from imperative-in-step-1 to a toc-resident `%Reset`, an Assertion's inverse), plus uniform
      abortive-safety; it is NOT a bug-fix (they're already deterministic via the hand-coded start-sweep).
       Everything else needs NOTHING: most Books write deterministic-named idempotent-overwrite files (e.g.
        MusuLossy's wav/opus/mp3), and radiostock (the only timestamped path) the human has ruled we TOLERATE
         in tests (differently-named, non-colliding, already absorbed by the EntropyArrest Entcases). So:
          convert ONE heist Book first to prove the pattern end-to-end, then roll the ~8; do NOT touch
           Sounditron (real user cache) or the broad suite.

**THE INVITE TRILOGY LANDED (2026-07-22) — chain, blotter, back-signal, all green ×2, uncommitted.**
 The three invite kinds now part cleanly and each is Book-proven on the live runner:
 - **(1) Re-assignable ReInvite chain** — the SHARE-QR invite that threads A—B—C—D, the TIP (not the
    issuer) grants each newcomer, `%ChainRoot` is the light lineage ref, `reinvite_ok` is tip-signed.
     `Ghost/S/Swarm.g #region ReInvite`, Book **SwarmChain** (Swarm_spec §6.3a).
 - **(2) One-time serial SHEET (blotter)** — `Swarm_mint_blotter` → N plain single-use serials under a
    `%Blotter`; claimed count DERIVED from members' spend flags (never a snapped counter); legacy `######`
     door-parse pinned. `Ghost/S/Swarm.g #region blotter`, Book **SwarmBlotter** (Swarm_spec §6.2).
 - **(3) Protocol back-signal (Peeroleum Robustness Organ 2)** — an unenabled frame type draws a
    `no_protocol` complaint when the peer is READY (acked so the retry stands down — no wedge), but is
     HELD (`%faulty` `startup-hold`, no ack) DURING the handshake window so the retx re-delivers once a
      handler attaches. `Ghost/N/Peeroleum.g` (`Peeroleum_deliver` + `req_unemit`), Book **PereComplain**
       (reconciled in `Cluster_spec.md §1`). Display side (share icon, blotter A4 QR sheet) is Vyto's.

**FOLLOWER PLAYER commissioned (2026-07-22) — a new sub-build, its own doc `Follow_todo.md`.**
 A client takes a QR and enters FOLLOW mode: a dumb player mirroring a leader-DJ's playhead (and, later,
  the DJ's private monitor channel while they play a different main stream). It's a new invite flavor (a
   `%Follow` Feature grant) riding the `@channel` fan-out + `Peeroleum_offer_stream` handover that already
    exist. GATED behind the 2026-07-22 invite-crypto QA (harden the mint/grant foundation first). The
     first-run onboarding UX the human also raised (username + open-share + the BigSoundland speech-bubble
      reframing the FSA "FaceSucker") is MOSTLY-BUILT Svelte already (`InvitePanel`/`BootGate`/`Shares`) →
       a UI-orchestration job in Vyto's zone; the wire side is a thin first-run-state contract only.

**INVITE-CRYPTO HARDENED (2026-07-22) — one real HIGH hole found + fixed + proven, uncommitted.**
 Two Sonnet audits of `Ghost/S/Swarm.g`/`Peeroleum.g`. The load-bearing finding: `Swarm_seal` bound the
  verified key (`page.pub`) but NEVER the routing address (`page.prepub`), so a `pier_hello` could forge a
   victim's prepub while holding its own key and HIJACK/overwrite an identity slot (the voucher gate that
    should stop this exempts pre-seal `pier_hello`). FIX: a `Swarm_page_bound(page)` guard
     (`prepubOf(page.pub)===page.prepub`) at all 5 seal entries + a `Swarm_seal` backstop, proven RED→GREEN
      by the adversarial Book **SwarmSpoof** (green×2; the forged `%Pier` seen in bytes then gone) with
       SwarmChain/Staple/Blotter non-regressed. Also downgrades the audit's F1 (reinvite_honour grant oracle).
        Then a follow-on sweep (human: "check everywhere") + the runners' recovery landed THREE more, all
         proven/handled: **verify-first** — refuse forged/not_ours/spoofed hellos LOCALLY before minting a
          transport route (closes F3's forged-hello bloat + stops a spoof spamming the forged victim; SwarmSpoof
           beat-4b, green×2, whole family non-regressed); **G1** — `Swarm_heard_hi` dropped a forgeable
            `header.from` fallback that let a page-less hi bypass the voucher gate and poke a real friend's route
             (fixed + non-regressing; adversarial station-Book proof optional/owed); **R1** — `Repli_attach_page`
              gained the rung-0 `sha256(bytes)===cid` gate on chunk arrival, mirroring Heist's landing check so a
               chunk streamed for live playback can't decode tampered bytes silently (Book **RaBreach**, green×2).
                NOT touched: F5 voucher-era freshness — the [[Trust_audit_handover]]-retracted wrong-layer item.
                 Full record: memory `swarm-seal-prepub-binding-hole`.

**STORY GATES YOUR ORGANS NOW (2026-07-19) — a cross-thread brief from the Story side.**
 Sounditron (the /BigSoundland resident diagnostic: machine → relay → possibilities → peer →
  sound → report, the user a reporting test-probe) hosts the whole Radio family in its run
   world — and its `Opt/wild` record-not-check regime is DEAD (the human: "I wanted both").
    It now records AND fixture-checks like every Book, so **%Radio/%Stoker/%Tuner/%Door and
     the stock shelf are load-bearing fixture bytes**.  What this thread must know:

 - **Two live couplings into your code.**  (1) Sounditron's beat 2 holds its snap until
    `Sounditron_stock_settled(w)`: `%Stoker` state ∈ `idle|spent` AND `sc.stock != null`.
     Rename a Stoker state or the census counters and the hold breaks → racing frames → red
      churn.  (2) The meander's finds mint SORTED (bound 12) so snap order is stable.  Touch
       either seam → recompile, re-run Sounditron, expect an Accept.
 - **The noise law**: EntropyArrest forgives wobbling VALUES on a stable line (an `Entcase`
    in the toc, e.g. `re:Session.alive={INT},tol:any` — the standing caveat:1).  It can NEVER
     forgive appearing/vanishing ROWS — structural drift needs a deterministic seam (a
      settle-hold, a sorted mint) or a re-record.  A new sc key you stamp on any family
       particle churns every fixture that world touches — budget the Accept.
 - **The assertion toolkit is yours too** (any Musu*/Radio Book): a witness swears
    `this.story_swear(w, 'sentence — em-dashes never commas', subjectC?)` — idempotent per
     run, no oa guards; the subject microsnaps what the claim points at (NEVER a %Grant or
      sealed key material).  Evidence rides the off-snap `ave/%Assertioning` shelf — zero
       fixture bytes, forever.  DECLARED contract = toc `step=N/%Assertion:slug,sentence:…`
        (the hosting step is the by-when); a missing declared proof REDS the run even at
         100% steps, un-maskable by entropy.  UNDECLARED sworn show amber ◇ "wants declaring"
          — the human promotes via the explorer's `declare ↑` (or
           `runner_ask declare '<sentence>'`); code never self-promotes.  `%see`/`%seen` are
            EXTINCT; the word is sworn/contract/evidence, never "roster".  `i %desc:'a few
             words'` per beat labels the pip.
 - **Verify rails**: `runner_ask assertions` prints ✓/✗ contract + ◇ undeclared + ⌖
    microsnaps, exit 1 on gaps.  **ALWAYS `--runner=<full-prepub>`**: fixtures pin ONE
     runner's environment — an auto-courted foreign tab reds everything honestly (live
      incident 2026-07-19; nothing was Accepted over it, keep it that way).
 - **What the human sees** (Storui): assertion DIAMONDS beside the pips
    (pending→latched→overdue amber→red pulse at run end), the `sworn N/M ◇K` button on the
     run bar, `[s]` swaps the whole panel to sworn mode (total mutex with the diff), and a
      missing assertion stands as a red GHOST LINE in the diff where its sworn would be.

**THE STATE (2026-07-19, uncommitted — the robusticise marathon).**  The v1.0 seam is wired:
 music flows friend-to-friend live, reconnect heals itself from either side on both channels,
  and the glass is being remade to show MUSIC first.  One line per organ — the code is the detail:

 - **Live share**: `Swarm_share_up/_beat/_loop` (Swarm.g) — stock husk-casts to granted friends,
    per-friend `%MusuThem` crates mint in the RADIO world, the dial plays the pool, and the
     keep-ahead leg wants full-length pages off the REAL playhead.
 - **Reconnect**: `Swarm_station_routes` + the `swarm_hi` era-reset greeting (swarm channel);
    ping-borne boot epoch + spine re-ack + `pinned_stable` promotion (Lies channel).
 - **Voucher**: per-era identity-signed `{prepub,pub,era}` on swarm frames, verified against the
    SEALED pier before `heard_at` — the relay stays untrusted (the human's ruling).
 - **%Suggest** store-and-forward (offline-safe, both piers, stash lane); **Faves** zine
    (`Musica_pop`/`%Zine` cell); **riffle** = open/flip/close dealing the DEEP subtree;
     naming at the door (`thang_put` upsert) + the ?Iz→?I swap at redeem.
 - **THE LINEUP**: `%Mag:'Lineup'` — up to 20 tracks past the listened-to cursor, every crate
    contributing round-robin, the dial consumes the head, STARVE = a real `%error` row per
     granted friend giving nothing playable (Radio.g lineup region; LineupFace).
 - **THE GLASS ALLOWLIST** (the "remake the model" cut): a `use_faces` world tucks every
    UNDRESSED cell-holder under 'system' (`cyto_crew`, Cyto.svelte) — the model VoroCyto gets
     is the user's, not the machinery's.  CrateFace spreads `%MusuSelf|%MusuThem` records as
      little cards (▶ auditions); gang mirrors label by member mainkey, never 'gang_of'; the
       Sounditron probe %Caper wears `crew:system`.
 - **Draw-Mags**: `Stoker_mag_draw` — every landing churn mints a `%Cloud` of `%Card`s on the
    `radiostocking/%Mag` (spec §2.3 — the culture trace; stock stays FLAT by the §2.4 ruling,
     Mags REFER).  Stoker floors raised for the 20-ahead: resurrect 24 · dig floor 8 · churn
      goal 20 · cull 44.
 - **Meander starvation killed + probe-proven** (branch-weighted `Crate_nav_meander`): 200
    walks → 58 distinct tracks, 50 deep — every album the human listed surfaces.
 - **Books PereReborn + SwarmShare — SWORN, gaps 0, green ×2** (delegated agent, 2026-07-19):
    declared contracts at their beats (PereReborn 3 — the collision claim re-gated n>=5 after
     the agent caught it latching toothlessly on the PREP acks; SwarmShare 4).  The spine's
      collision re-ack + epoch reset; per-friend mirror keying, %Suggest store-and-forward,
       the hi rebirth reset.  Core regression green (SwarmStaple · PereStaple · MusuRaStream).
 - **Health-sweep reds to eyeball (the human's re-record call):** VoroScape 0.17 + PereProof
    0.09, both pure dige-drift, error:null throughout.  PereProof likely the DELIBERATE spine
     re-ack (a collision now emits an extra ack frame the old fixtures lack); VoroScape's
      fixtures were already cleared-for-re-record at the Voro rename.  Diff-eyeball, then
       accept if the drift is the expected shape.

**Live gates owed:** the two-tab fingers-proof (seal → husks in the friend crate → preview →
 pool dials it → full track → suggest-while-offline round trip → refresh either tab, dots
  re-green ≤15s, crates refill); an eyeball of CrateFace + the Lineup on /BigSoundland.
**Sounditron re-record BLOCKED on stock non-determinism** (the agent tried accept→rerun —
 every step's dige differs per run; the futile fixtures were reverted).  Three sources, in
  weight order: (1) DISK ACCUMULATION — each run's digs grow the on-disk radiostock the next
   run RESURRECTS, so run N+1's settled stock includes run N's finds (no seed fixes this);
    (2) the beat-2 settle-hold (Sounditron.g:106, 10s budget) now TIMES OUT mid-churn under
     the raised floors and pins a racing frame — lengthen it if determinism is chased;
      (3) the dial randoms — now CURED:
     every Math.random in Radio.g rides `Ra_rand(w,n)` (per-world, crypto-live, `Ra_seed`
      pins it for a Book, `Ra_entropy` stirs it live).  The human's call: bless red-on-dige
       as the big-share environment tell (the assertion contract stays the portable verdict —
        the §1 Sounditron_todo stance) OR summarize/exclude the stocked-record set from
         Sounditron's snap.

**THE MAG PIVOT IN FLIGHT (2026-07-19, human-steered agent thread — unpreened):**
 `spec/Mag_todo.md` proposes `%Mag**/%Record` — Records living UNDER Mags, EXPLICITLY
  superseding `Radio_spec §2.4`'s flat-stock ruling — plus Mags-over-Repli, shuffle
   warm-start pages, and the show|hide → crawlable topic-limb graph (retiring the flat
    %Tuner mute).  Until the human preens it, §2.4 stands and Mag_todo is the challenger;
     a reader of either doc should know the other exists.

**Owed ledger (landed rungs' remainders — full detail in `history/Radio_buildlog.md`):**
 - D1a crypto door: swap MusuDoor's grant toggle for live `Swarm_pier_live` (attended —
    entropy profile + warm re-accept).
 - M4 remainder: the WIRE goner via the Berth forget path; rename-as-standing-Upkeep;
    roster fan-out over N followers.
 - `%Original` master + `%Blob` re-home into the shop; the prod signer + `hid` derivation
    (rung 7's app path — today only Books set a signer).
 - Berth: the `%Rack` + load-on-init; the MusuBerth live-gate.  Heistlet `cursor · backoff`
    legs + a true two-runner return trip.
 - ✓ **DONE** — music-metadata swap inside `Crate_meta_from_tags` (`parseBuffer` from music-metadata@11,
    imported Crate.g:14, drives the field-by-field fallback at Crate.g:383; `Crate_wav_with_tags` writer
     kept hand-rolled — the lib is read-only).
 - Cloud-model redirect (the human, 2026-07-13): `randomic` → `shuffle|ctime|mtime` partitions
    of ~20 at the real rastock→magazine seam.
 - Captured idea: the invite as the DJ's CUE — an Idzeug redeemed at the deck headphone-monitors
    the next track (design seam for deck-UI × invite).

**Posited unknowns (the final figure-out):**
 - **The wire crypto audit → `Trust_audit_handover.md` (rewritten 2026-07-26).**  The `.g` comms suite
    (`Swarm.g`/`Peeroleum.g`/`Tribunal.g`) IS the production wire (not a sim — an earlier note here mislabelled
     it; corrected).  Its crypto is **split-personality**: the **society** layer (`Swarm.g` invites/grants/
      reinvites/vouchers) is **real ed25519** and Book-green (single-use spend + blotter + chain all built); the
       **transport** layer (`Peeroleum.g` per-frame + hello/trust handshake) is **deliberate mock v1** — no
        per-frame signature (`header.sign` is a landed-later seam), hello-verify is `startsWith`, trust-verify is
         a no-op.  `src/lib/p2p/Peerily.svelte.ts` (the previous-gen prototype) is the REFERENCE for the owed
          port: land per-frame `emit`-signing + a real `verify_trust` onto the Peeroleum handshake (its
           per-connect rebuild scaffolding — `reset_handshake` keeps `%Ud` — is already correct).  The detached
            per-era voucher is per-era link-auth by design, not a forgery bug.  (Heist-landing `id`-homing is a
             fine hardening IF records auto-merge — but "eyeball incoming music" is the intended model anyway.)
 - BootGate on a device whose AudioContext never inits: the gate stands forever; fingers-check.
 - watch_c migration for face reactivity (today faces poll H.version + a 1s tick).
 - Scale seams: FSA names-only expand (3000-file dirs); whole-stock husk re-offers want the
    neu/goner Selection once stocks grow; live-channel unemit rows never cull (the hi-reset
     bounds it; a standing sweep is owed).

**Bombs (durable homes: §2 wiring bombs · §1.5 Book discipline · CLAUDE.md · memories):**
 LocalGen for spine .g; seed the toc THEN reload the runner; always `--runner=`; pre-pin the
  assertion set before an accept; sealed real-audio Books keep benign ≈; the host commits
   mid-session — re-check the tree after HEAD moves.


---

## 0.9 Parking lot — low-priority fixes (deferred, not blocking any rung)

Known-real problems found in passing that we deliberately DON'T stop the mainline for. Patch them
 opportunistically alongside more relevant work; each names its own proving Book so it lands with a gate.

- **THE INVITE SHOULD OUTLIVE ITS HANDSHAKE — the human's cure for the half-seal (2026-08-06).**
   *"we should remember the Invite until both parties have agreed they have fully processed it, so we can
    keep giving all the Grants until done."* That is the right shape and it is bigger than the bug. Today an
     invite is a MOMENT: `pier_accept` fires once, builds the far side's whole %Pier, and is then forgotten —
      so any single lost frame strands the pair forever, and `Swarm_reaccept_incomplete` is a patch that
       re-drives one specific half from one specific side (and is blind to the other, see §0). A remembered
        invite inverts it: the invite becomes a **standing req** — a thing with liveness that is not finished
         until BOTH ends confirm they hold BOTH grants — and the re-send stops being a special-case repair and
          becomes the ordinary behaviour of an unfinished req. That is the house idiom ([[req-is-where-state-
           belongs]]): *prefer a req over a status string; it carries its own liveness.* It also gives the glass
            something true to show ("sealing with Lefto — 1 of 2 grants confirmed") instead of a link that
             silently half-works. Design owed: what "fully processed" means on the wire (an explicit
              seal_confirm carrying the grant set you hold?), and when the req may finally retire.
   **HALF-DESIGNED + MOVED (2026-08-06) → `Swarm_compact_invite_todo.md` §9** (that doc already owns the
    3-frame seal, and its §7c predicted this exact half-seal on 2026-07-27). Five rungs, each standing
     alone; **rung 1 needs no wire at all** — a side missing its OWN grant re-mints it from its own key.
      The old garden's `Tyranny.svelte` (`Idzeuganise`) is the reference for a handshake that is allowed
       to be slow as long as it narrates what it waits on. Leave this bullet as the pointer; design lives there.
- **UI trims the human asked for 2026-08-06 (space is the scarce resource on the glass).**
   Vyto has too many cells: **drop the "a peer to come online" cell** and **the Crates cell** for now — the
    glass should be about the music, and a cell that is usually idle is spending permanent space on an
     occasional message. **Move the time-alive/uptime readout INTO the list of Piers** — it is networky, it
      belongs beside the peers rather than owning a cell. (`BeatFace` / `CrateFace` / `DoorFace` are the
       organs; `DiagFace` is the opt-in gate they already sit behind.)
- ✓ **DONE — Transfer graph: floor the vertical extent at 200KB/s, and drop the separate up|down bars.**
   Landed in `TransferFace.svelte` (`FLOOR_KBPS = 200` at :60, applied in `sparkPath`; the split bars
    removed, only the merged spark + the numeric `rx↓ · tx↑` head remain). Kept for the rationale:
     autoscaling made 3KB/s of ack chatter draw the same mountain as a real 3MB/s pull — a fixed floor
      makes **tiny amounts look tiny**.
- **SLOW: sprinkle the OLDER Books with `%see:` assertions about clear pointables.** The early Ra*/Musu*
   rungs were written when the snap-fixture diff WAS the whole gate, so most of them assert nothing by name —
    they only claim "these 532 lines are what happened". That is a brittle, illegible gate: it reds on any
     deliberate source change (see §0's four-cause MusuRaChase autopsy — a clock pin, a `path:` stamp, a
      `String()` and an ephemeral reclassification, none of them regressions), and it says nothing about WHAT
       the Book proves. Where a Book crosses a boundary a human can name, name it. The model is
        `Radiation.g:719` — `%see:'the playhead crossed the first boundary onto chunks transcoded on demand'`,
         gated on `fed.sc.held > 0`: a once-noticed, self-describing claim that survives re-records because it
          is about MEANING, not bytes. Obvious pointables owed one: the `%Preview`→`%Stream` seam (the
           encode boundary Radio drains and re-opens a decoder across), first-sound, the resume cursor landing
            on the chunk the listener actually reached, a grant going live, a mirror freezing on revoke.
   WHY IT MATTERS BEYOND TIDINESS: a named claim is the only part of a fixture that survives a re-record with
    its meaning intact — so it is what lets us ACCEPT a legitimately-churned snap without the accept being an
     act of faith. Every one added makes the next re-record cheaper and the next autopsy shorter.
   NOT a sweep — do a few whenever you are already inside a Book for another reason. No commas in the
    sentence (the peel parser splits on them; use an em-dash).
- ✓ **RESOLVED for the goner-delete (MusuFreeze — Heistation.g:2081).** `Musica_recast_offer` now computes
   `allowed = this.Repli_allowed(w, to, from)` and gates BOTH goner emissions — the cloud delete (Heist.g:1136)
    and the record delete (Heist.g:1150) — so a revoked follower's mirror is frozen, not remotely deletable.
     RESIDUE: the raw `Repli_retire` primitive (Repli.g:308) is still ungated, but gating a Repli **core**
      primitive is the human's call (its only live caller is a Book); left as-is. Original finding, kept for
       context:
- **`Repli_send_lines` bypasses the consent gate — goner DELETES leak to a REVOKED follower.**
   `Repli_offer` (Repli.g:283) is `Repli_allowed`-gated, but `Repli_send_lines` (Repli.g:229) is NOT, and
    `Musica_recast_offer` (Heist.g:706/720) calls it directly for goner `op:delete`s. So the wire refuses to
     ADD to a revoked peer but will still DELETE from their mirror — an asymmetric consent bypass (a revoked
      peer's held copy should be frozen, not remotely editable). Found by MusuBuddy's adversarial review
       (2026-07-14); MusuBuddy's own revoke scene ADDS a card, so it never exercises the leak (see 11 stays
        sound). FIX: gate the two goner-delete `Repli_send_lines` calls in `Musica_recast_offer` on
         `Repli_allowed(w, to, from)` (surgical — leaves the Repli core primitive alone; check other callers
          before gating the primitive itself). PROVE: a delete-after-revoke Book (MusuBuddy's see-11 shape but
           a GONER not a neu) — the dropped record/cloud does NOT reach the revoked mirror + zero frames burned;
            adversarially review AND live-gate (an unrun security assertion is the worst false-green).

---

## 1. Destination

### 1.0 The whole machine, at a glance

One line per submachine; read the indent as containment. `<` (down the left margin) marks an unbuilt edge —
 the `// <` lack mark. What has a Book behind it is real; the rest is `<`. Detail: the streaming half in
  1.1-1.5, the heist half in §10.2, the wire's honesty in §10.1 (all built parts are terser than they read).

```
    jamsend  -- peers keep their own music and heist each other's over a trust-gated p2p wire.

      identity & trust (Swarm)  -- which of your keypairs you are, and who each may reach.
        %Account,of:<vault>  -- a stored vault a page loads; a page may hold MANY.
        %Identity,prepub     -- the keypair you act AS; its prepub is your address, the thing you sign.
        %Peering             -- that Identity's relationship hub (named by your own prepub).
        %Pier,pub:<prepub>   -- YOUR view of another peer, held under your Peering; "the Pier" = our Pier FOR them.
        %Grant / %UnGrant    -- a capability the peer signed you (or a durable revoke tombstone).
        Invite               -- a QR scan-to-join mints the Pier (SwarmDoor).

      the wire (Peeroleum)  -- ordered, repaired frames over a sealed channel (handshake, then seq/inseq/retx).
        < real carrier         -- still a by-reference loopback (Lake_link); WebRTC/relay untested by any Book.

      replication (Repli)  -- walk a peer's C** by cursor: reach into paths, get lost in the maze like a user, offer each husk, pull its bytes on want (body_hash per page).

      %Library,pier:<prepub>  -- ONE per Pier (prepub = the Pier's key): a peer's collection of cards + stock.
        %Record                -- a track's card: catalog identity (artist+title) + byte promise (bytes/total/hash).
                                    its chunks are minted by whoever fills it -- the twin (listen) or the heist (grab).
        radiostock             -- the card's on-disk served form (<ts>-<pub>-<enid>); enid = content id, ts = mint.
        < proactive first-stock -- render the first radiostock BEFORE the first user arrives, so track one is instant.
        < load_random_records   -- sample an unbounded catalog, never slurp it whole.
        < FIFO whittle_stock    -- evict the oldest when the library fills; a cache, not a hoard.

      the streaming twin (rastock -> racast -> raterm)  -- SHIPPED; each is a system:
        rastock  -- make a track SERVABLE: one uniform encode set, on disk.
          decode once          -- OfflineAudioContext, no gesture; the full PCM feeds the encoders.
          loudness-level       -- measure LUFS, gain the WHOLE track to -14 / -1 dBFS ceiling.
          preview encode       -- ONE opus encode of the first 32s (Ra_preview_secs), sliced on the 2s grid into %Preview.
          the boundary         -- the preview/stream seam, pinned to the want-page grid (multiples of 4s).
          radiostock file      -- <ts>-<pub>-<enid> on disk; ts = mint (newest wins, GC twins), enid = content id.
          idempotent           -- a standing .jam resurrects instead of re-encoding; a dead-source stock is litter, deleted.
        racast  -- serve the stock to Piers at listening rate.
          offer husks          -- cards cross first; %Preview wants serve instantly (the chunks pre-exist).
          parked-want transcode -- a %Stream want has no chunk yet, so it PARKS -- the park ignites the 2nd encode (boundary->end).
          serve as it appears  -- Repli_serve_parked releases each stream chunk the instant it transcodes; no rate flag.
          the ramp             -- want-pacing only: a PAGE=2 server stride + the terminal's ahead-window.
          grants gate it       -- repli_allow admits per-relationship; a revoke refuses the next offer.
        raterm  -- play WHAT CROSSED, nothing local.
          two decoders         -- %Preview and %Stream are separate encodes: one decoder each, reset only at the seam.
          preskip              -- the decoder DROPS ~6.5ms (312 samples @48k) of encoder warm-up at each fresh open: a sample count in the OpusHead, NOT bytes to strip.
          gapless concat       -- chunks decode in seq order into continuous PCM; silence where one is absent.
          starve surfaces      -- the honest playhead-vs-frontier race, no hidden buffering.
          track change         -- an owner act runs a fresh cycle from seg 0.
        < live edge            -- a THIRD mode: one chained continuous encode you join and follow, no seek (§9.4).

      the player (the deck)  -- what a listener does with the streams.
        multi-stream           -- many streams from ONE library at once: decks, cue, crossfade (MusuMix / MusuCue).
        < tempo / pitch        -- play a stream at a chosen tempo and pitch, independently (time-stretch).
        wants more             -- the terminal pulls ahead of the playhead; the demand IS the parked want.
        interest wears         -- a stream you stop attending ages out (wear): the buf drops, the husk stays.
        < listen-through       -- consume the library in a stable random order keyed by radiostock ts; know when all's heard.

      the heist  -- point a job at a Pier and pull its music into your library; MAY be klepto. rung 1 built.
        census                 -- a DIRECTORY CURSOR walks the Pier's filesystem into %Records; rolling, not a fixed set.
          %Body,seq            -- born HERE: the ORIGINAL file bytes, chunked whole -- the heist's byte-faithful payload.
        the job                -- %Caper,at:<pier> + optional match (absent = klepto = everything); filings pinned as DATA.
        the pull               -- paged at heist rate; each offer dedup-checked at the door by catalog identity.
          < bandwidth control  -- a real throttle on the pull rate (uncapped today).
          < progress           -- a per-record download bar that renders as pages land.
          < stream-to-disk     -- write each chunk at its offset as it arrives; no in-memory assemble.
        landing                -- assemble, verify body_hash, write byte-faithful into the library.
          < $artist/$album/$track from tags  -- today filename-derived under a seeded genre prefix.
          < merge into an existing tree + surface what you already hold on a second heist.
          < repointable mid-heist  -- re-anchor the hierarchy, checksums still pass.
        probation              -- .jamsend/newlyadded logs each arrival; love graduates, drop = deny = delete.
          ✓ remembered-denials tombstone  -- %Tombstone on drop; refused at the door (live-gate owed, §0).
        flatten                -- the %Caper + mirror delete; nothing attributes who gave what afterward.
        < cohort / cafe (rungs 2-3)  -- one page-stream to N kleptos, then a LAN broadcast tree.

      the app surface  -- where a person drives it.
        < create-a-heist       -- a gesture that points a %Caper at a Pier (today ONLY the test Book mints one).
        < progress + bandwidth HUD  -- the download bar and the rate dial, on screen.
        < boxy floats          -- each thing a vaguely-boxy Cyto node you float; fullscreen or open the larger ones.
        < heist bloom          -- census + pull rendered as cytonodes ERUPTING into place (the heist as a flower?).
        Cyto / Matstyle        -- the live particle view every submachine renders into for free.
```

`Radios.svelte` is 1500 lines of pre-Housing machinery: a hand-rolled spin loop over
 `Modus`, cursors smeared across `.sc`/`.c`, backpressure as an inline `if … cool it`, the
  whole streaming algorithm tangled with real `MediaRecorder`/WebAudio/disk I/O so you can
   never *watch* the algorithm — only hear its output (or its silence). The new tech exists
    precisely because that hurt:

- **a req that bows out IS backpressure** — no spin guard, no `waits`/`see`/`satisfied`
   bookkeeping; the spool req simply finds no chunk it may send and makes no progress.
- **particles are legible** — `%Caster`/`%Terminal`/`%Chunk`/`%cursor` snap, so Cyto draws
   them and Matstyle swatches them with zero new view code; the algorithm becomes a picture.
- **simulatable** — divorced from codecs and the wire, the seq/ack model runs headless and
   deterministic, so a Book can drive it beat by beat and a witness can assert each beat.

The end state is not "port every line." It is: the *interesting* behaviours of music piracy,
 each lifted into a runnable, watchable, witnessed simulation on the new machine — and the
  old `Radios.svelte` left to do only the irreducibly-real part (transcode bytes, push them
   over WebRTC) if anything at all.

### 1.1 The record on the observable plane

*What snaps, replicates.* A `%Record`'s chunks are REAL child particles, flat under it —
 no config-head layer — and the bytes ride `.sc.buf`, which the snap encoder MUTES to a
  visible description (`ref:{buf:"Uint8Array()"}`), never hides:

```
Record,id:<enid16>,title,artist,seconds,lufs,gain,sr,br,seg_secs,preskip…
  Preview,seq=0,head     {ref:{buf}}    ← opens the preview decoder
  Preview,seq=1 … 15                    (preview = 32s ⇒ 16 chunks; Cyto CRUSH folds the sprawl)
  Stream,seq=16,head     {ref:{buf}}    ← a SEPARATE encode; opens the second decoder
  Stream,seq=17 …                       (come into being as the frontier transcodes — watchable)
```

- Global `seq` continues across the boundary: the first `%Stream.seq` = the last `%Preview.seq`+1.
- **Particle presence IS fill state** — no `have=` counters; resume-from-partial = want the first
   missing seq you can see. Wear (§9.6) = drop the buf, keep the husk ("was here, released").
- `Ra_preview_secs` is a **product constant, 32** — not a knob, not 33: the boundary must sit on
   the want-page grid (2s segs × PAGE 2 ⇒ multiples of 4s) or the even stride never visits an odd
    P and "first stream want == P" is unmintable.
- Binary `.sc` is snap-visible and wire-replicable but must NEVER ride a Waft toc-persist (the
   storage encoder rightly errors on refs) — the disk home is the radiostock file (§1.4); stream
    chunks have no disk home at all, by design.

### 1.2 One encode per side of the boundary

The preview is ONE opus encode, made at stock time; its bytes slice into the `%Preview`
 particles at the 2s packet grid; the far side concatenates them IN ORDER into ONE
  `AudioDecoder` → continuous PCM, gapless, because it IS one stream. The `%Stream` side is a
   SEPARATE on-demand encode (boundary→end) with its own `head` — a second decoder. Two decoders
    per track, reset only at the seam. A chunk is a transport slice, not an encode unit.
 - Framing: raw u16-length-prefixed opus packets inside each buf — the RFC-7845 Ogg mux is
    deleted (WebCodecs opus needs only `{codec,sampleRate,numberOfChannels}`).
 - **Preskip** has ONE canonical statement, the `Ra_encode_open` comment: the encoder's
    convergence ramp (312@48k) dropped at each fresh decoder open; carried on the card + the two
     `head` chunks because we deleted the container. NOT a time offset — time-into-track is
      seq × seg_secs.
 - The LIVE edge (§9.4, later) is a THIRD mode: one chained continuous encode you join and
    follow — no seek, no independence. Orthogonal; don't fold it into this model.

### 1.3 The pull is Repli; the economy is park/serve

Ra owns NO wire. Repli carries chunks with three GENERIC gains (nothing Ra-shaped in them):
 a binary `.sc` value is a buffer leaf (bytes ride a page frame, `bufk` restores the key);
  husk offers; a consent hook `w.c.repli_allow?.(peer)` in serve — the Keep's seam (§9.7).
   The Float32 `.c.page_bytes` path stands untouched (MusuReplica/MusuReco).
 The whole preview→stream economy falls out of Repli's park machinery, no boundary
  enforcement anywhere:
 - **Preview chunks pre-exist** (minted from radiostock) → their wants serve instantly.
 - **Stream chunks do not exist until transcoded** → a stream want PARKS, and the parked want
    IS the demand that ignites `Ra_transcode_*` — the encode runs to completion at the encoder's
     REAL pace, `Repli_serve_parked` releasing chunks as they appear. No rate flag (`racast_rate`
      is dead); a starve is the honest race of playhead vs frontier. No source ⇒ no stream.
 - **The ramp** ("gently the first 4s, then quickly more") is want-pacing, not mechanism: fixed
    small server stride (PAGE=2 chunks) + the terminal pipelining wants up to its ahead-window.
 - The terminal decodes WHAT CROSSED (`Ra_term_decode_pulled` off the mirror particles, silence
    where absent) — never local stock. Pulled chunks are EPHEMERA: no friend-download cache;
     radiostock is for one's OWN collection; actually moving music is a later economy.

### 1.4 Radiostock on disk

One file per Record: **`<ts>-<pub>-<enid>.jamsend_radiostock`** — preview window only,
 json header + length-prefixed bufs, deliberately nothing that reads as media (it lives in the
  user's library dir).
 - `enid` = sha256 of the WHOLE source bytes, first 16 hex — content identity, never locked to
    the pub or path that found it. (`Ra_id` path-hash and `src_hash` are dead.)
 - `ts` = mint time, so newest wins: `Ra_stock_find` GCs older twins in passing; `Ra_stock_gc`
    drops superseded renders. `pub` = the owning Peering's pier key — many Piers share one
     `.jamsend` in tests, each filters its own (`Ra_stock_ls`).
 - **Dead-source rule**: a stock whose source is gone can never make up its %Stream — litter;
    `Ra_source_pcm` deletes it and a later pass re-stocks what the collection now holds.
 - LUFS/gain stay WHOLE-track on the card (target −14, −1 dBFS ceiling) so the preview→stream
    seam is loudness-uniform.

### 1.5 The Books that gate it (and their discipline)

Five Books in `Ghost/Story/Radiation.g` (24 + Chase's 15 `%see`) — re-record any time the Record shape moves:
 - **MusuRaStock** (5 steps) — mint shape + idempotent re-pass; **MusuRaCast** (12) — offer →
    preview pull → boundary ask → parked-want transcode → revoke via `repli_allow`, `body_hash`
     pins byte identity; **MusuRaTerm** (12) — local decode honesty (gain survives the round
      trip, starve surfaces, clean run clean), fully deterministic; **MusuRaStream** (40) — THE
       session: ramp in, hold at the boundary, ask == P exactly, fed past the boundary on demand,
        then the owner-act track change → B runs a full fresh cycle from seg 0; **MusuRaChase**
         (~56, brand-new) — the proto-VILLAGE: two source Piers sealed by real Idzeug redeems,
          the grant gating per-relationship, the KEEP_AHEAD fan-out warming previews across both
           wires, the entropy-seeded dial chasing to the other Pier for a warm instant start —
            then one source goes DARK and a mid-cycle SKIP turns the dial among the online only.
 - **Caveat signature (permanent, understood 2026-07-11):** a Book that SEALS shows benign ≈ on
    exactly the `AudibleEntropy`-grafted fields (Pier `since:`, Grant `time:`+`sign:`, Edge
     `at:`) every re-run — `tol:any` tolerates, it does not canonicalize. Stream ≈37, Cast ≈9,
      Stock ≈2, Term ≈0. Do not chase caveat:0; each Book's count is its stable signature.
 - **Accept discipline:** `runner_ask accept` only (never CredRunner-auto for %see Books);
    pre-pin the set (`grep -aoE "%see:'[^']*'" Ghost/Story/Radiation.g`), confirm every sentence
     present after. Immediate redispatch after an accept can hit the engaged begun-wedge —
      `release`, wait ~8s, redispatch; no tab reload needed.

---

## 2. The cluster — layout, names, and the wiring bombs

```
Ghost/M/Radiola.g              spine — the reusable mechanism (req_cast, the window)
Ghost/Story/Musuation.g        the Musu* Books (Story ghosts are grouped under Ghost/Story/,
                                like Peregrination.g — the file is the artifact, MusuStaple is
                                 the Book identity)
wormhole/Ghost/Music/Ality/toc.snap   the overlay Waft (Musicality) — curates the cluster,
                                        the twin of wormhole/Ghost/Net/Easy
wormhole/Story/MusuStaple/toc.snap     the Book's step fixtures (lie diges till a real run)
src/lib/O/spec/Radio_todo.md           this doc
```

Names mirror the `Pere*`/`N`/`Net/Easy` family so the parallel reads at a glance:

| network (the template) | music (this project) |
|---|---|
| `Ghost/N/Peeroleum.g` (spine) | `Ghost/M/Radiola.g` (spine) — *working name; rename freely* |
| `Ghost/Story/Peregrination.g` | `Ghost/Story/Musuation.g` |
| Book `PereStaple` | Book `MusuStaple` |
| `Waft:Ghost/Net/Easy` | `Waft:Ghost/Music/Ality` |
| `Lake_*` (the scenario verbs) | `Musu_*` (the scenario verbs) |

**BOMB — registration order.** A ghost is enrolled in `CREDULER_GHOSTS`
 (`src/lib/O/LiesLies.svelte`, ~line 51). The runner's `Creduler_ensure` loads each entry's
  *gen* `.go` and waits on `%Creduler_pending` until every `Ghostmeta_*()` reports live. **A
   gen `.go` that does not yet exist hangs the runner boot.** So the M cluster is NOT in
    `CREDULER_GHOSTS` yet, and must not be until each `.g` has been ghost-compiled. That edit
     is the one unavoidable touch *outside* `Ghost/M/`; it is deferred to the human and listed
      as the next move (§7). Until then nothing in `Ghost/M/*` is live; the source is inert.

**BOMB — ghost-compile needs a live editor, and HANGS on a SPINE ghost.** There is no
 standalone `.g→.go` CLI. `npm run ghost-compile -- <file.g>` signs a ticket to the in-app
  editor on `:9091`, which force-loads the dock, compiles, writes
   `src/lib/gen/<cluster>/<File>.go`, and HMRs it. But HMR-remixing a DEPENDED-ON spine ghost
    (Ra.g — proven, even a trivial method) wedges the live runtime: spine edits go through
     **LocalGen** instead — `GFILES='Ghost/M/Ra.g' [CHECK=1] npx vitest run -c
      scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts` (browserless, writes the
       gen; space-separated GFILES for several). Leaf Book ghosts (Radiation.g) compile live fine.

**BOMB — a brand-new Book runs Prep-only (`total:1`).** The runner runs the Book it ACQUIRED
 AT BOOT and clobbers a mid-session disk `toc.snap` seed: seed
  `wormhole/Story/<Book>/toc.snap` with ~N `step,dige:lieN` lines FIRST, then reload the runner
   tab so Creduler re-acquires it — and register the Book in `Waft:Credence` (unlisted =
    invisible on the board).

**THE NAMING RULE (owner 2026-07-08).** Book-specific code is FULLY-NAMED with the long prefix
 (`MusuRaTerm_witness`, `MusuRaCast_seal`); the shared engine stays SHORT `Ra_*` (`Ra_stock`,
  `Ra_term_*`) — never `MusuRa_*` on an engine verb. A fully-named Book method drives a short
   engine verb, the same way the `Musu*` Books drive `Sound_*`.

**BOMB — don't bump outside the cluster.** Cyto and Matstyle auto-discover by mainkey
 (`cyto_scan` + `cytyle_classify`; Matstyle autovivifies a `matstyle:<key>`), so new
  particle types appear in the graph with swatches and *no* view-code edits. That is the lever
   that keeps this project inside `Ghost/M/` + `Ghost/Story/Musuation.g` + the two snaps + this
    doc, plus the single deferred `CREDULER_GHOSTS` line.

---

## 3. The pipeline — rastock → racast → raterm  (the basicness, named 2026-07-07)

The whole product in three verbs, each a stage with its own Book and face: **rastock** builds
 uniform stock from the library, **racast** casts it to Piers, **raterm** is the terminal that
  plays it. Everything else in this doc serves one of these three. This section is the working
   sketch for the build session.

### 3.1 The codec decision — Opus, and Safari is alienated WITH AN EXPLANATION

**[owner 2026-07-07] Opus, not AAC:**
 - the library IS already `.opus` (the `/music` mount) — same family end to end;
 - the ENCODER matters as much as the decoder (every user's node encodes its own stock), and
    Opus encode is everywhere free: MediaRecorder (webm/opus) and WebCodecs `AudioEncoder`
     (bundled libopus — works on Linux Chrome where AAC encode does NOT). No ffmpeg.wasm pull;
 - simple licensing wins — the open 20-year standard over the patent pool.

Safari/WebKit refuses Ogg|WebM Opus — and **Chrome-on-iOS IS WebKit** (Apple mandates the
 engine; the EU-DMA alternative-engine door is a rounding error), so it inherits the refusal.
  We show an **explanation face**, never silence: "your browser refuses the open audio
   standard — ask its vendor why." Two honest escape hatches for later, NEITHER a re-encode:
 - **CAF remux** — Safari decodes Opus FRAMES inside a CAF container; same bytes, new wrapper;
 - **WebRTC** — Opus is mandatory in RTP and Safari decodes it there; a live racast leg over a
    PeerJS track reaches an iPhone today.

### 3.2 rastock — uniform stock from the library  — ✓ SHIPPED 2026-07-07

*[2026-07-10 supersede: the ~2s unit survives as the CHUNK GRID, but each side of the boundary
 is now ONE continuous encode — no per-segment encoder reset (§1.2); random access is per-SIDE
  (preview from 0, stream from P), not per-segment. And chunks ARE particles (§1.1) — the
   "snap bulk" fear below was overruled by the owner. The codec choice, LUFS decisions, and the
    stock pass all stand.]*

The stock is the library made SERVABLE: loudness-uniform, seekable, chunked, snap-described.
 Even from `.opus` sources we RE-ENCODE — the transport unit is the **nice little ~2s frame**
  (independently decodable segments, the old `radiostock/*.webms` shape). Why independent:
   **playback starts in the middle more often than not** (tune-in, seek, resume), and Opus
    packets are chained prediction — mid-stream entry needs OpusHead config + ~80ms pre-roll
     bookkeeping, where a segment whose encoder RESET at the boundary just decodes. WebCodecs
      honesty (owner asked 2026-07-07): chunk-fed `AudioDecoder` IS reliable in Chromium now —
       explicit backpressure (`decodeQueueSize`), feed-as-slowly-as-you-like by design — so the
        segments are chosen for **random access, fault isolation (a bad chunk poisons 2s, not a
         stream), and unit-alignment** (segment = Repli page = wear unit = the want-cursor's
          count), not out of decoder fear. Continuous WebCodecs decode is the LIVE-edge tool
           (§3.3) where you join once and follow — and equally the FROM-THE-START tool [owner
            2026-07-07]: a listener taking a whole track from zero rides ONE continuous WebCodecs
             stream fed segment after segment, no per-segment decode tax at all; `decodeAudioData`
              per segment stays the dumb fallback that works everywhere we deign to support.
 - **measure**: needles (`@domchristie/needles`, the `Records.svelte` prior art) on the decoded
    PCM — LUFS per track. `TARGET_LUFS` is ONE constant (the old machine ran **-8** — hot,
     radio-style; streaming platforms normalize to -14). **Decided at build 2026-07-07: -14,
      with a -1 dBFS peak ceiling** — the gain is BAKED into the PCM, so an up-gain that would
       clip instead caps at the ceiling (`capped:1` stamped; that track sits honestly quieter).
        A -8 target would cap half a real library and defeat the uniformity it exists for.
         Stamp BOTH `lufs:<measured>` and `gain:<applied dB>` on the `%Record`.
 - **the pass**: nav `bin_read` → decode ONCE (OfflineAudioContext, gesture-free — the
    `Crate_transcode_begin` seam) → apply gain to the PCM → WebCodecs Opus encode →
     cut at ~2s boundaries → segments to the share (`§9.1b` heuristics: `.jamsend/` corner or
      `testmusic/` in-repo) + `%Record`/`%Stream,name:opus` rows that SNAP (per-segment `%Chunk`
       particles would be snap bulk — the segment FILES are the chunk rows, `%Stream.total`
        counts them, and Repli pages them onto the wire later).
 - **Book: `MusuRaStock`** — real `/music` in, uniform stock out, and the audio-proof: decode a
    produced segment on the muted AC and the measured loudness lands within tolerance of
     TARGET; a second run is idempotent (stock already standing is recognized, not rebuilt).

### 3.3 racast — the stock cast to Piers  — ✓ SHIPPED 2026-07-08

Casting is **Repli, never RPC** (the all-pervading rule): the catalog crosses as a replicated
 husk to sealed Piers (the §9.1c re-draw — MusuGot territory), Records cross as Repli pages on
  the pull, and the LIVE edge — hear what I hear NOW — rides `@channel` multicast (§9.4) from
   a station in `role:music`. The grant gates every leg (§9.7): no Music grant, no husk, no
    pages, no edge.
 - **Book: `MusuRaCast`** — a sealed pair; stock stands at A; B pulls one Record whole (pages,
    sha256-verified) and tunes A's live edge; a revoked B hears nothing new.

### 3.4 raterm — the terminal that plays  — ✓ SHIPPED 2026-07-08, live-verified GREEN

The Musu cursor machinery finally earns its keep as the REAL spool: want-ahead keyed off the
 playhead (§9.3), one `AudioDecoder` per encode side split at the `head` chunks (§1.2),
  the uniform gain already baked, crossfade at track joins (MusuMix's deck math). Faces:
   BigSoundland + the Voro radio tuner as the dial.
 - **the ISP-oppression warning [owner 2026-07-07]**: when Piers cannot WebRTC (CGNAT, blocked
    UDP, symmetric NAT) and traffic falls back to the relay, SAY SO — a Brink badge + a face
     line: *"your ISP is likely oppressing direct peer connections — you are riding the shared
      1Gbps relay."* Detection = the PeerJS connection state we already watch; sustained
       relay-leg traffic where a direct lane should be is the tell.
 - **Book: `MusuRaTerm`** — segments in, honest playback out: gain applied, spool starves and
    recovers without lying (the MusuSignal claim redone on stock we actually made).

### 3.5 What retires

The tiny aspect proofs become `Radio_lowlevel.md` material as `Ra*` goes green — the
 higher-level re-draws: MusuCrowd's many-listeners claim re-proves ON racast, the spool slices
  re-prove INSIDE raterm, MusuSignal's starve gate inside MusuRaTerm. Nothing is deleted until its
   re-draw stands.

**THE RULE CLIMBED A LEVEL — the PRODUCT Books retire too (2026-07-14).** The re-draw ladder does not
 stop at Ra*: the three standalone Ra* PRODUCT Books proved stock|cast|play in a configuration the
  destination never runs — a stream with no catalog naming it — so once **MusuBuddy** (§0, the
   magazine-driven pipeline where the stream is BORN from a browsed `%Musica` card) stood LIVE-GREEN ×2,
    **MusuRaStock / MusuRaCast / MusuRaTerm were DELETED** (Book code in `Radiation.g`, their fixtures,
     their Credence + Ality rows). The same discipline governed it: nothing deleted until its re-draw
      stood green. What is NOT redundant and STAYS: **RaStream / RaChase** (the streaming-race — park at
       the boundary, feed past it, the village dial — which the static catalog cannot express),
        `MusuGenerateTestsMusic` (the seeder), and the real-audio lowlevels (MusuSignal/Glide/Tune/Edge/
         Radio/Conceal — the PCM aspect proofs; RaTerm was their consolidation target and MusuBuddy now
          is). `Ghost/M/Ra.g`'s spine verbs are untouched — MusuBuddy rides them. The magazine and the
           pipeline were always the IDENTITY and BITSTREAM halves of one experience, meant to meet, not
            two proofs of one job.

### 3.6 What is REAL and what is a MOCK in the Ra Books (honest ledger)

Owner asked (2026-07-08) to keep the mock boundary explicit: the `%see` claims say "real opus
 Record", which is TRUE of the bytes but invites a misread. Precisely — **it IS real music
  processing; only the SOURCE tones and the transport WIRE are stubbed.**

**REAL (the substance — genuine audio, not a by-reference stub):**
 - **the whole DSP path** — `OfflineAudioContext` decode → needles K-weighted LUFS meter →
    baked gain → WebCodecs Opus encode → ~2s segments → `.jam` on real disk → `decodeAudioData`
     back → muted Web-Audio playback. The −14 LUFS target genuinely survives the opus round trip
      (MusuRaTerm reads it back). Real bytes, real loudness math, real codec.
 - **the transcode clock (2026-07-10, redrawn same day)** — a stream want PARKS and IGNITES the
    on-demand encode from source (`Ra_transcode_*`, §1.3), which runs to completion at the
     encoder's REAL pace — no rate knob at all (`racast_rate` is dead); the MusuRaStream race is
      a genuine producer-vs-playhead race.
 - **the terminal's substrate (2026-07-10)** — measurement decodes the PULLED segments
    (`Ra_term_decode_pulled` off the mirror), never the local stock: loudness and gaps are read
     from the bytes that crossed the wire.
 - **storage** — real `.jam` files through the FSA-share nav (`Ra_pack`/`Ra_unpack`).
 - **protocol** — frames, per-Pier `seq`, sha256 `body_hash` per page, fixed-stride paging,
    husk/catalog offer, park/serve (the Repli/Peeroleum floor).
 - **consent/crypto** — Swarm mints|verifies REAL grants; the seal is a real signature (it
    varies → harvested into `AudibleEntropy`); a revoked peer genuinely gets silence.

**MOCK (two deliberate stubs, each with a named path to real):**
 - **the SOURCE material** — NOT `/music`. The tracks are pure-sine WAV tones synthesized in
    `src/lib/O/LiesFunk.svelte` (`TEST_TONES` + `wav_bytes`; "Cosmic C" = a 1046.5 Hz sine, artist
     "DJ Oscillo", 78s), written to a `testsounds` share and then really stocked. Chosen so the
      frequency IS the label (an FFT decodes which tone played) and the loudness spread exercises
       BOTH gain directions (Dorian D at amp 0.2 boosts up, the rest attenuate down). **This is the
        ONE thing §9.1 makes real: point the same `Ra_stock` at real `/music` files instead of the
         synth `testsounds`.** Everything downstream is already real. (§9.1's "Musu_synth output"
          is this same synth source under an older name.)
 - **the transport WIRE (MusuRaCast)** — `Lake_link` pairs two in-process ports and carries
    `frame.buffer` BY REFERENCE: no serialization, no real loss (adversaries INJECT it), no
     congestion, no NAT, no WebRTC datachannel. The protocol riding it is real; the carrier is
      tame. Full ledger + the forcing function (Klepto rung 10.2 — 2+ real runners) live in §10.1.

So "real opus Record" means real opus STOCK (vs a by-reference stub), not a `/music` file yet.

---

## 4.–8. The ladder (moved)

The instance-by-instance history — the old workings (§3-old), the slices (§4), simulation &
 animation (§5), the `Musu*` Books + the runner interface (§6, §6.1, §6.2), the status log
  (§7), and the presentation map (§8) — moved verbatim to **`Radio_lowlevel.md`** (2026-07-07,
   original § numbers preserved there): the ladder we climbed, kept for regression hunts, not
    the direction. Board twin: `What:Musu / What:lowlevels`.

---

## 9. Pier reality — taking Repli from the loopback to the world

The replication protocol is real (Repli_* + the Se, §6/MusuReplica — live-green 2026-07-03), but its
 world is a demo: two Piers in one w, three synthetic Records, a beat-loop pull. This section is the
  idea set for making Piers REAL — each idea grows from a seam that already exists, named so a session
   can pick one up and go. The oldest statement of the destination sits at the top of
    `src/lib/mostly/Selection.svelte.ts` ("Selections are then sendable to particular Piers. So it
     mostly moves whole folders... replicate the meaningful folder structure above the selected
      stuff") — written before the Se existed; now the %Sent_Tree IS a Selection, so the sentence can
       finally mean something executable.

> **Vocabulary sync (2026-07-13 — see `Voro_todo.md §The Se process`).**  This section's "the Se"
>  is the ORGAN — canonically a **%Seem** (a particle holding a live `Selection` on `sc.Se`;
>   `i_Seem`/`o_Seem`, parks off-snap).  **%Se** is reserved for the small SNAPPED reading a Seem
>    projects, worn iff a `Selection.process()` produced it (mainkey = provenance).  So below:
>     "the LIBRARY as a Se over a folder tree" = a Seem whose SUBJECT is the folder tree, its
>      neus|goners the offers|retires; "the Se's pairing carries continuity" = the Seem's D-sphere
>       (`bD`).  The prose keeps its old name; the build recipe + honest-projection rules live in
>        `Voro_todo.md §The Se process` and apply here unchanged.

**9.1 The real library.** A's `%Library` today is `Musu_synth` output; reality is the `/music` mount
 (read-only) arriving through the FSA share gate (`H.c.disk_gated` + `open_dir` — the granted-share
  path, since ?E=/?B= boots forbid the OPFS shadow disk). A walk mints `%Record`s from files (id =
   path-hash, title/artist off tags or path parts) with `%Stream` handles that decode lazily —
    `MusuReco` (via `Crate_transcode_*`) already fetch+decodes real audio, so the decode seam exists; what's new is the
     LIBRARY as a Se over a folder tree ("hierarchise FileLists"), whose neus|goners are files
      appearing|vanishing on disk. The same `repli_on_neu` hook then offers REAL music with zero new
       protocol.

**9.1b The share-dir heuristics (owner 2026-07-07).** What KIND of directory did the FSA grant open?
 Sniff, don't ask:
 - **No `wormhole/` and no `.git/` inside** ⇒ it is an actual MUSIC COLLECTION. The app's own
    bookkeeping must not litter someone's record shelves: **rewrite every `wormhole/` request to
     `.jamsend/wormhole/`** inside the granted dir — the hidden corner is ours, the collection stays
      theirs. (One rewrite at the nav layer; the four-backend contract stays intact —
       `full-contract-no-subset-gaps`.)
 - **We are IN the project git repo** (`.git/` + `wormhole/` present) ⇒ dev mode: **`testmusic/` is
    the actual share.** The same code path serves the developer and the stranger — the dual purpose
     is the point, not an accident.
 - **Consent is mostly all-or-nothing, granted gradually:** the FSA picker IS the consent gesture,
    and its unit is a directory — a user who wants to share less points the grant at ONE
     sub-location of their collection (exactly how `testmusic/` works in-repo). No per-file
      checkbox forest; the filesystem hierarchy is the consent UI.
 - **The download side is a HIERARCHY too**, not a bucket: received music lands under
    `<share>/.jamsend/downloads/<friend>/…` (possibly `<username>/`), so what came from whom stays
     legible on plain disk and a wipe of one friendship is one `rm -r`.

**9.1c IveGotMusic — the reachable-music tally (owner 2026-07-07). [BUILT 2026-07-07]** Once two
 BigSoundlands seal (the §10.1 front door — LIVE now), a friend's collection COUNTS: "the music
  I've got" = my library + every sealed `%Pier`'s counted collection, one number that grows when a
   friendship does — the front door's payoff made visible. NOT the full tree: each side offers a
    tiny **collection summary** (counts, no Records) that rides the same wire and lands under the
     `%Pier` as `%IveGot,by,count` facts. The full pull (9.2's Selections) stays deliberate; the
      tally is the appetite for it.
 The build (`Swarm.g #region ive got`, Book **SwarmGot** 9/9): `Swarm_music_census(w, ident)`
  counts `%Library,pier:<prepub>` (the Musu Library shape keyed by WHOSE — a key, not a nickname;
   this is now the census convention the real `/music` library must land as). `Swarm_gossip_music`
    is the DELIBERATE boast — an additive `ive_got` frame to every live sealed Pier (the
     `Swarm_pier_live` gate: a revoked Pier hears nothing — Book-proven, a post-revocation boast
      never crosses). `Swarm_ive_got` lands facts ONLY under an already-sealed Pier (a stranger's
       boast = `%rebuff,ive_got_stranger` and nothing else — gossip never opens a door); facts
        update IN PLACE (one per dimension). `Swarm_ive_got_tally` folds own census + every live
         friend's last boast; `InvitePanel` shows the tally + a per-friend ♪ chip and boasts once
          per new seal (zeros send — an empty shelf is an honest boast, and it proves the live
           wire). Owed: the real `/music`-share census feeding a live `%Library,pier:` (§9.1);
            signing the boast (it rides the authenticated link, but the fact itself is unsigned
             v1); a re-boast cadence when the shelf changes (today: on new seals + deliberate);
              revocation PROPAGATION (one-sided today — the revoked side still counts the last
               boast heard, SwarmGot beat 9 says so honestly).

**9.2 Selections sendable to Piers.** The share unit is not the library, it's a SELECTION of it — a
 genre, an artist folder, an occasion. Concretely: a `%Share,label:<name>` particle holding a match
  (what subset) and a to (which Pier|channel), whose own Se runs over just that subset — its neus
   offer, its goners retire (unshare without delete: the record leaves the SELECTION, not the
    library). `Repli_lines_of` already recurses a subtree, so the meaningful folder structure above
     the selected stuff replicates for free — the mirror sees `genre/artist/album/track`, not a flat
      pile.

**9.3 The pull rides the playhead. [BUILT 2026-07-10 — the Ra machine]** MusuReplica pulls on a beat
 loop; a real listener pulls because they are LISTENING. Radiola modelled the shape
  (`req_streamability` arms `%want:stream` at the `want_left` floor); the REAL machine now runs it:
   `Ra_term_stream_beat` wants ahead of the playhead, clamped to the %Preview window until the
    streamability latch, then streams from right after the last preview while `Ra_cast_serve_want`
     transcodes the continuation from the source at `racast_rate` (§0 — replication rate = listening
      rate against a real transcode clock; MusuRaStream is the Book). The remaining half — keep_ahead
       across RECORDS (the next-track prefetch) — landed 2026-07-11 as `Ra_restock_beat` +
        `Ra_keep_ahead` (§0), proven multi-source in MusuRaChase.

**9.4 Catalog gossip over multicast.** Offers today are unicast `to:'Crowd'`; the relay already fans
 out `to:@channel` topics (Peeroleum multicast, PereProof step 29). An offer published once to
  `@<cluster>` reaches every subscriber; a Pier arriving late gets the current catalog as its
   subscribe baseline and live neus after — the Se's noticing becomes the cluster's noticing.

**9.5 A %Sent_Tree per peer — the availability map.** In the demo, one tree per side. In a swarm, A
 keeps a tree PER KNOWN PEER (`Sent_Tree,pier:<pub>`): "how much of each Record is where" becomes the
  routing table. `Mesh_route` (cheapest-route, MusuMesh) can then answer "who do I want page N from"
   — multi-source pulls, different pages from different holders, the torrent shape grown from parts
    we already run.

**9.6 Wear makes the mirror a cache.** MusuWear reaps worn records; applied to a mirror, `got`
 REGRESSES when pages are reaped — and the Se's pairing already carries continuity (bD), so a
  regression is visible history, not a fresh unknown. Replication stops meaning "copy forever" and
   starts meaning "lease-shaped cache": re-pullable, wearable, honest about what is actually held.

**9.7 The Keep gates what enters.** Repli verifies bytes (sha256 per frame) but not INTENT. The
 cluster-trust layer (signed frames, the cluster Idento) says who a Pier IS; the Keep (attention ×
  crypto × acceptance) decides what it ACCEPTS: a mirror is quarantine until kept. Swarm.g already
   mints|verifies grants — a `want` without a grant for that Share is refused; an offer is an
    invitation, not an obligation. This is where music-sharing stops being promiscuous replication
     and becomes consent all the way down.

**9.8 The tree is the resume.** A reconnecting Pier must not re-pull from zero. The %Sent_Tree
 persists (it is C**, it can snap — dontSnap is per-fixture hygiene, not a persistence ban), so
  `want from:have` resumes where the wire broke — the same baseline-adoption shape that fixed the
   inseq reload. The D** with continuity IS the cursor state; no separate bookkeeping to invent.

**9.9 Retire as a first-class social act.** op:delete crossing the wire (MusuReplica beat 13) means
 a shared thing can be WITHDRAWN — mistakes, rights, dedup, moderation. Generalised: a goner in a
  Share retires at subscribers of that Share only; a goner in the library retires everywhere. The
   un-replication path is tested and symmetric with the offer — keep it that way as the semantics
    grow.

**9.10 The audio-proof cherry.** Deferred from MusuReplica deliberately: B PLAYS its replicated
 copy on its own (muted, tapped) context — MusuBounce already runs two contexts. The first full
  end-to-end: a real file picked on A (9.1), offered through a Share (9.2), pulled at listening rate
   (9.3), heard at B. That demo IS the app; everything above it is how it stays honest at swarm
    scale.

The order that suggests itself: 9.1 (real library) → 9.10's spine (offer→pull→play with one real
 file) → 9.2 (Shares) → 9.4 (multicast) → then 9.5–9.8 as the swarm grows peers. 9.7 (Keep) tracks
  `spec/Backbone_plan.md` — don't fork its design here.

## 10. Klepto mode — the heist points at a Pier

Today the unit of want is a Record: offer → want → pages, pulled at listening rate (9.3). **Klepto
 inverts the aim: point the heist at the Pier itself** — "everything you have" — and the mirror is
  the destination. The catalog is already the offer set (9.4's subscribe baseline); klepto walks it
   and pulls at HEIST rate — what the wire and disk afford, not the playhead — `Repli_want_next`
    grown a second gear. `Repli_mirror_lib` is the seed; mirror-everything is its grown-up form.

**Many kleptos, one read.** A Pier heisted by N must not do N disk sweeps. The host serves the heist
 as a BROADCAST: one sequential sweep of the library, each page read ONCE and published to a heist
  `@channel` (`Peeroleum_offer_stream` — the established 1:1 Pier hands each arriving klepto the
   stream pointer; bulk rides multicast, spec §18). Everyone present rides the same bow wave — the
    shape MusuReco already proves (stream off the transcoder's bow wave) — and a latecomer tunes in
     live, then backfills the pages it missed with ordinary 1:1 wants (the per-peer %Sent_Tree, 9.5,
      knows exactly which). The host is a radio station whose playlist is "my library, in order"; a
       klepto is a tuner with a backfill cursor. Disk IO is O(library), not O(library × N).

**The cafe tree.** Kleptos co-located on a LAN (the coffeeshop) should cost the WAN one copy: the
 source sends into the LAN once; the receiver relays to two, who relay to two. `Mesh_broadcast_stretch`
  IS this tree (minimum-cost broadcast rooted at the source) and `Mesh_cafe_spec` is the canonical
   scenario, already written — the missing rung is DETECTION: how do Piers learn they're co-located?
    The honest first answer is the relay's-eye view — two Piers behind the same public IP share a NAT,
     and the relay already sees every address; it stamps same-origin groups. (Finer, later: RTT
      clustering — sub-5ms neighbours; ICE local candidates are mDNS-obfuscated and need a real
       probe.) Same-origin → cheap LAN edges in the Mesh graph → stretch computes the tree → pages
        route down it.

**Klepto is not exempt from consent.** The heist takes everything OFFERED, not everything held —
 grants (9.7) bound the catalog a klepto even sees, and wear (9.6) makes the mirror a cache, not a
  hoard. The name is cheeky; the Keep still gates.

**The rungs, in order:**

1. **Heist v1, loopback** — a Book: point the heist at the DJ Pier, mirror everything at heist rate,
    assert the whole-library mirror byte-faithful (`body_hash` per Record). Extends MusuReplica's
     world; no new wire.
2. **The cohort** — 2+ kleptos on one host: one page-stream on a heist @channel; assert the host
    emitted each page ONCE while every mirror completes. This is the rung that finally forces the
     wire real (§10.1): the first Book whose claim is ABOUT shared delivery, so a by-reference mock
      flatters it — run it over 2+ real runners with real Piers (brief §6's milestone).
3. **The cafe** — same-public-IP detection at the relay + stretch routing; assert the WAN edge
    carried one copy while every LAN klepto completes.

### 10.1 How real is the wire today (honest ledger)

The PROTOCOL is real — frames, seq, inseq/retransmit, sha256 `body_hash` per page, paging,
 park/serve, op:delete — the same verbs the product will run. The WIRE under the Books is not:
  `Lake_link` pairs two in-process ports (`porta.partner = portb`) and the mock carries
   `frame.buffer` BY REFERENCE — no serialization, no real loss (adversaries INJECT loss:
    whittle/perturb), no congestion, no NAT. Peeroleum's own comments name the deferred seam:
     serialization is "the carrier's job — `Socket_real/relay`". Meanwhile the machinery itself
      (dispatch, r2r, gen_write) DOES run the real `/relay` websocket all day — real reconnects,
       real seq gaps (the inseq baseline bug was real networking pain). So: real protocol, tame
        wire; the WebRTC datachannel path the streaming app uses is untested by any Book. Rung 2
         above is the designated forcing function.

### 10.2 The heist as built — rung 1's edge, and the `<` unbuilt (map, 2026-07-12)

Rung 1 (loopback) is BUILT and live-gate-pending: `Ghost/M/Heist.g` (the pure engine) + `Ghost/Story/Heistation.g`
 (Book **MusuHeist**). This is the honest map of where the real machine STOPS — read it as the roadmap.
  Legend: **`<`** marks an unbuilt edge — the `// <` lack-of-development mark, carried into prose.

**What's real (the built spine), walked in order:**

- **Divided census off ONE shared disk.** Real files under `testsounds/` walked into `%Record` cards, each
   with `%Body,seq` chunks holding the ORIGINAL bytes (`body_hash` = full sha256). An artist whittle (Uno:
    The Sines + DJ Oscillo; Duo: Fourier Four) makes each Pier seem to hold different music — the dedup trap
     dissolved. The census DISCOVERS (walks whatever's there), so it is already a rolling filesystem cursor,
      not a fixed six.
- **The seal.** One `Idzeug` redeem grants the pair a mutual Music grant; every wire leg is gated live by
   `w.c.repli_allow -> Swarm_pier_live` (real Swarm crypto + handshake, so a revoke shuts the legs).
- **Three jobs — uno, duo, reuno — paced ONE EDGE PER SNAP** (`acted_step` on `step_n`). Offer casts the
   source catalog (klepto v1, no match); each husk is dedup-checked at the door by catalog identity, the rest
    pulled at heist rate; a record whose every chunk arrived LANDS.
- **Landing straight into the collection, byte-faithful.** Assemble the pulled chunks, re-hash, verify against
   `body_hash` (a mismatch tallies `job.sc.breached` and lands nothing), `bin_write` under a genre dir, then
    catalogue the landed card at ITS OWN path (never the source's) — which is what makes the next heist's dedup
     notice it.
- **Probation + deny.** `.jamsend/.../newlyadded` logs `<seq> <feeling> <entry>`, never a source; `love`
   graduates in place, `drop` = deny = delete the file off disk + retire the card.
- **Flatten-off.** The `%Caper` (+ its `%filing` decisions) and the quarantine mirror delete; collections +
   `newlyadded` remain and neither says who gave what.
- **Design/test split.** The machine is first-class on `w` (Peerings/Piers/Grants/Idzeug/Libraries/%Record/
   %Body/%Caper/mirror); every test observation hangs under `w/%testing` (the `heisted:<nick>` node with its
    `on_disk` monitoring, `census`/`sealed`/`newlyadded_shape`/`denied`/`flattened`, the 10 `%see`). Snap reads
     as machine-left, opinion-right.
- **Determinism + hygiene.** The engine stamps NO test markers on the world (a transient FSA hiccup no longer
   leaves a permanent marker). The marrauding namespace `.jamsend/test-marrauding-of-bookrun/<nick>` is swept
    files-only at BOTH start and end (`.jamsend` is gitignored; the repo never keeps WAV bytes; dirs persist
     empty so the next run's FSA handle cache is not poisoned).
- **The wire is loopback** (`Lake_link`, see §10.1): real protocol, mock carrier.

**The edge — what's `<` unbuilt:**

- ✓ **DONE — metadata from tags.** Stale by the time this was read (2026-07-30): `Heist_census` (Heist.g)
   and `Crate_nav_payload` (the radio-stocker, Ghost/M/Crate.g) both now read id3/vorbis/RIFF via
    `Crate_meta_from_tags` (music-metadata@11) first, falling back to `Crate_meta_from_path`'s filename split
     only for an untagged file. The test tones carry real IART/INAM tags agreeing with their filenames
      (`LiesFunk.svelte` `Musu_gen_testsounds`) precisely so this could land without a fixture re-record.
- `<` **A real `$artist/$album/$track` landing tree.** Landings file under `<seeded-prefix>-<genre>/`
   (the `4t-...` you saw — a placeholder so a test can't collide with real curation). The real destination is the
    tag/name-derived hierarchy.
- `<` **Similarity / format-upgrade dedup.** `Heist_held` matches EXACT artist+title only. "Same track,
   better format (to flac)" and fuzzy-title matching are ungrown; v1 skips an exact hold and re-offers the rest.
- `<` **Single-track mode — the listening session.** play -> skip -> decide-to-download-THIS-one (no folder
   structure), from both ends. Today it is bulk-catalog klepto (offer everything, pull everything unheld). Needs
    a "listen" surface, not just the klepto sweep.
- `<` **Merge into an existing tree + "you already have these."** `reuno` proves catalog dedup skips a
   whole held catalog, but there is no merge INTO a pre-existing real directory structure, and no surfacing to
    the user of what they already hold on a second heist from an artist.
- `<` **The directory-listing confirmable.** A `$artist/$album/$track` listing shown as the heist BEGINS,
   and found again as it RESUMES — the look-before-you-commit — is unbuilt.
- `<` **Repointable mid-heist.** Change the destination hierarchy of an in-progress heist and have its
   checksums still pass. The landing path is computed once at land time; there is no re-anchoring.
- `<` **Stream-to-disk.** `Heist_land` assembles the whole file in memory (`Uint8Array(size)` + `set`)
   then writes once. Streaming each `%Body` to a growing file offset as it lands drops the memory high-water AND
    clears the `req:awaitbuf` pile-up (the "hundreds of lines of waste / 22s step").
- **Remembered denials — CONDEMNED (2026-07-13 ruling; the rip is owed).** Built overnight as
   `%Tombstone` because it was SAFE to build blind (see the honest note below: "additive to fixtures,
    no design fork") — never because it was asked for; the %Ban rebirth was already host-vetoed. The
     human: "I never asked for tombstoned — an overly simple take on what will come that's going to
      confuse us." The kill reasons: the only load-bearing skip is `Heist_held` (what you HOLD); the
       deny ceremony has no real populator (an out-of-band file delete never mints one, so it misses
        the common prune); `%UnGrant`'s never-drop durability is earned by SECURITY (absence
         ambiguous, stakes are trust), not taste; and the §12 world is PULL-shaped (wants/cursors) —
          a blacklist defends against a push that stops happening. Where the concern re-homes:
           per-heist poke-out = the MANIFEST gesture (deselect before a byte moves); durable
            per-relationship narrowing = the §9.2 `%Share` match (the negative space of the match);
             taste bans = the Booth IF a surface ever wants them. Rip checklist = §11.5's migration
              checklist re-purposed (DELETE at each site, not rename); Heistation.g loses the retomb
               scene (~steps 20-30), one toc re-seed + reload + re-record.
- **The FSA reload caveat — self-heal BUILT.** A dead directory handle in `WormholeNav._cache` (a `mkdirp`
   walking a stale entry) throws `NotFoundError` on landing. `bin_write` now catches a stale-handle error
    (`_is_stale`: `NotFoundError`/"not be found"), force-re-walks each level via `mkdirp_fresh` (refreshing the
     handles off live disk), and retries ONCE (Housing.svelte.ts); a second failure is a real fault and
      propagates. The happy path is exercised every landing; the heal branch fires only on a poisoned handle
       (a pre-poisoned tab from BEFORE this shipped still needs one reload). A runner is now leave-up-able.
- `<` **The real wire (rung 2+).** Loopback mock today; the cohort rung (§10 rung 2) is the forcing
   function, then the cafe tree (rung 3).

**Proposed roadmap** (the order I'd sort the `<` — pending your read):

1. `<` **stream-to-disk** — bounded, and it pays off the awaitbuf waste + memory high-water.
2. tag-vs-filename metadata ✓ done (see above); `<` the real `$artist/$album/$track` landing tree still
    stands (retires the `4t-` prefix).
3. `<` **merge-into-existing** + "already have" surfacing + the directory-listing confirmable — these
    three are one feature: a real library tree the heist reconciles against.
4. `<` **single-track play/skip/decide** session.
5. `<` **repointable** mid-heist.
6. ✗ **remembered denials** — CONDEMNED 2026-07-13 (see above; the %Ban rebirth was vetoed first,
    now the gear itself goes — rip owed); `<` **similarity / format-upgrade** still open.
7. ✓ **FSA `bin_write` self-heal** — BUILT (Housing.svelte.ts; the reload-per-session fallback is retired
    except for a tab poisoned BEFORE it shipped).
8. **rung 2 (cohort)** — the wire's forcing function (§10 rung 2).

**Where I'd point next after the §11 tier-1 gate** (still `<`, still pending your read): **#1
 stream-to-disk** is the highest-value remaining engine-realness item BUT it is load-bearing — it needs
  incremental sha256 (SubtleCrypto can't stream a digest), per-page landing, and breach-after-write
   semantics on the CENTRAL byte-faithfulness invariant, so it must be proven LIVE, not built blind. Then
    **#2 metadata + the real `$artist/$album/$track` tree** (has a genre-vs-tree design fork that is yours
     to call: does genre stay a top folder above the tag tree, or does the tree replace it?) and re-records
      the 4t- fixtures. Neither was safe to land in a no-live-verify overnight; the tombstone was (reuses an
       established shape, additive to fixtures, no design fork).

## 11. The Booth — taste as standing facts (the programme director organ)

Born from the %Tombstone post-mortem (built unexplained, named in graveyard-speak, thought
 heist-locally). The fix is a FAMILY designed together, so every fact answers — where it is
  defined — the four questions the tombstone never did: **what is it, how long does it live,
   who consults it, how is it lifted.** Adversarially vetted (record: §11.6).

**STATUS (2026-07-13, the human's rulings — read BEFORE building anything in this section):**
 - **%Tombstone STAYS in the engine.** The Ban rename was built then REVERTED by the host
    ("you're just changing the name") — Heist.g/Heistation.g/LiesLies are back on the tombstone
     baseline. `Ghost/M/Booth.g` exists, compiles, and is deliberately UNWIRED + UNENROLLED — the
      human vetoed it then softened ("maybe I was too harsh"): the likely revival is Booth's door
       probe over §11.7's Waft:Taste (the document as the store), NOT the line-ledger. Still: no
        wiring without a fresh ruling.
 - **The taste data model is unsettled, and klepto-mode is what warps it** ("why would I ban a
    track I started heisting?"): in a want-driven heist — genre starting points + the source
     Pier's advice (§11.7 Waft:Map) — most refusal-memory dissolves. Build toward want-driven;
      revisit refusal-memory only after that exists.
 - **Persistence is RULED: §11.7 (the Berth).** The Waft is the project-standard mutable robust
    document; the Booth's raw-line `.jamsend/booth` ledger is superseded — do not extend it.
 The family vocabulary below (the tune handle, the door table, rest/wanted shapes) survives as
  design material; the ORGAN packaging (Booth/Ban verbs, the ledger) is the vetoed part.

**The model in three sentences.** Every opinion the listener forms lives as a fact on the
 collection, pointing at music through one handle (`tune:`/`artist:` — §11.1). The **calls**
  (§11.2: Ban, Rest, Wanted, rotation, Setlist) are consulted by the machine's doors — acquiring
   (heist), programming (racast), playing (raterm), being-browsed — each at its own gate. The
    **evidence** (§11.3: spins, the airplay log, and their readers charts + Hunch) feeds the calls
     but never gates anything itself.

### 11.0 One track's life through the family

A husk is offered on a heist; the door checks the collection — already held? banned? — and only
 the new and un-refused pull. The track lands on probation (`newlyadded`); the listener loves it
  (graduates, arrives hot in rotation) or drops it (file deleted, card retired, a **Ban** minted so
   the next heist's door refuses that identity). As it plays, **spins** and **skips** tally and the
    **airplay log** keeps the recent tape; the **charts** read the tallies. Too many skips and the
     Booth gets a **Hunch**: rest it — a **Rest** sits the track out for a while and expires on its
      own; a Ban stands until the listener lifts it. What a browsing peer eventually sees is your
       programming — charts, setlists, rotation — never your file paths.

### 11.1 The tune — one way to point at music

Every opinion-fact points at music the SAME way: a **`tune:`** scalar holding the canonical
 **`Artist — Title`** string (single spaced em-dash — the same no-commas convention as %see
  sentences; commas would fight the peel parser).

    Ban,tune:Fourier Four — Query E
    Ban,artist:DJ Oscillo

**Grain is visible by which key rides the line**: `tune:` = one track, `artist:` = the whole
 artist — never a `kind:` enum. Three invariants, each load-bearing:
 - **The split**: `Tune_split` takes the FIRST ` — ` as the boundary, so titles may contain
    em-dashes and artists may not (accepted rarity, stated here so nobody reverse-engineers it
     from a snap).
 - **One normalization site**: `Tune_key(artist, title)` (trim + collapse whitespace; "feat."
    stripping and case-folding are `<` later gears that will land THERE and nowhere else).
 - **Derive, don't assert**: `Tune_of(rec)` derives the handle from a %Record's tags — the record
    keeps `artist:/title:/album:` (facts of the file) and never stores its own `tune:`.
 Accepted cost: "every ban by artist X" is a scan-and-split over `o({Ban:1})`, since `o()` matches
  literally (no prefix match); opinion-facts are few, the scan is fine. Verified encode-safe: an
   em-dash is not in `encode_stringies`' unsafe set, and ` — ` already round-trips live in %see
    sentences. Namesake to hold: lowercase `tune` is a live MAINKEY in Musuation.g test-result
     particles (`{tune:1, kind:'result'}`, :1253) — different world, no query overlap with the
      Booth facts, but grep before assuming `tune:` is fresh anywhere.

### 11.2 The calls — facts the doors consult

| fact      | heist door (acquire)   | racast door (program)  | raterm door (play)       | built    |
|-----------|------------------------|------------------------|--------------------------|----------|
| Ban       | refuse (`job.sc.banned`)| never cast `<`        | never queue `<`          | tier 1   |
| Rest      | · (not its layer)      | skip while resting `<` | auto-skip, manual-ok `<` | `<` t2   |
| Wanted    | pull first / only `<`  | ·                      | ·                        | `<` t2   |
| rotation  | ·                      | weight `<`             | weight auto-play `<`     | `<` t4   |
| Setlist   | ·                      | cast as program `<`    | play locally `<`         | `<` t4   |

(`·` = does not consult, by design. "Already held" needs no fact: a %Record existing IS the fact,
 probed by `Heist_held`. "Loved" needs no fact either: love is a probation VERDICT whose durable
  trace is `rotation:heavy` — the family is not punishment-only, the positive half just lives in
   rotation.)

**Ban — the do-not-play list — TIER 1 (the %Tombstone reborn).** The listener's standing refusal
 of a track or an artist — "is it like a hated tracks?" — exactly that, the real broadcast
  do-not-play ledger (the BBC banned records; so do we). Minted when the listener DROPS a
   probation track (`Heist_feel` calls `Booth_ban`), or by hand at either grain. Lives on the
    collection — an opinion belongs to the collection, not to any job, so it survives every %Caper
     flatten. **A ban stands until you lift it by hand (`Booth_lift`); nothing sweeps it** — not a
      flatten, not any cleanup — because a ban that silently vanished would re-download the very
       track it refused (the machine-side rule is the %UnGrant one: never GC a negative fact —
        the family's only other negative fact, a waved-off Hunch, obeys the same rule). No
         `at:` birthday — history lives in the airplay log, and a timestamp would churn fixtures.
          Probe `Booth_bans(lib, artist, title)` — spelled as the QUESTION it is, unmistakable
           from the act at any call site — checks tune-grain then artist-grain; the
          artist-grain ban is first-class from day one: the door refuses EVERY track by that
           artist, racast/raterm will never surface them, and the census still builds their cards
            (a ban is about what enters/plays here, not about un-knowing what a peer holds).
             Door tallies stay apart — `skipped` (already held) vs `banned` (refused) — so a snap
              reads WHY each husk stopped.
 **Why ban what you chose to heist? (the human's unease, 2026-07-12 — a standing stance, not
  settled).** Klepto v1 pulls EVERYTHING; probation is the selection step, so the Ban is
   bulk-mode's memory of a drop — you never chose the track, the heist did. In a want-driven heist
    (Wanted raids t2 + the single-track session §10.2 #4) the Ban nearly dissolves: you simply
     never re-want it. Direction: build toward want-driven heisting and keep the Ban as bulk-mode's
      small memory. Alternatives weighed and parked: the verdict LEDGER as the sole store (the
       door reads last-verdict-per-tune off `.jamsend`); one mutable `%Stance,tune` card per known
        tune (merges ban/rest/love — C/C/C is cheap so a structured stance home is affordable —
         but a deletable stance loses the never-GC negative-fact clarity).
 **Persistence — where opinion lives when the tab dies.** A collection's CATALOG is derived (the
  census re-walks the disk every boot — nothing to persist); opinion is NOT derivable, so the
   Booth persists in the collection's own meta home: **`.jamsend/booth`** ledger lines
    (`seq ban|lift grain key`, the proven newlyadded mechanics), net state rehydrated onto the lib
     at census, write-through on every ban/lift. The opinion TRAVELS WITH the music — copy the
      folder, keep your bans. A `Waft:Booth` VIEW (the hand-editable board, Credence-style — the
       human's instinct) is the right SURFACE for it later; the Waft displays and edits the same
        ledger rather than being a second home.

**Rest — the temporal sit-out — `<` t2.** "Not now; back in a while" — radio-real: resting an
 overplayed record. A Rest is NOT a weak Ban: you rest a track you LOVE (fatigue management), you
  ban one you refuse (a verdict). `Rest,tune:…,back:2026-07-19` — "rest it, back the 19th": a
   human-readable date, never an epoch (the snap must read as a sentence). Doors READ an expired
    Rest as absent (a pure read, no mutation inside a probe); the particle is actually removed at
     the next Booth WRITE on that collection (any ban/rest/lift sweeps expired Rests in passing —
      a tracked write moment), so expired Rests lie around harmlessly at worst — a fixture may
       carry a benign stale Rest, like the sealing-Books' benign ≈. The heist door does NOT
        consult Rest: acquisition is not playing, and refusing bytes over a mood is the wrong
         layer.

**Wanted — the want list — `<` t2.** Tunes you don't hold and are hunting — the collector's want
 list styled as the heist-land wanted poster: `Wanted,tune:…` (artist-grain allowed). Minted by
  hand (later: from a friend's chart). The heist door pulls Wanted husks FIRST, and a
   `raid:1` job pulls nothing else — klepto narrowed to a raid, named as one. Retired automatically at
    landing — honestly: that retirement is an edit in `Heist_land` (where landing actually
     happens), the same class of door-wiring as the Ban check, not a free lifecycle.

**rotation — programming weight — `<` t4.** `rotation:heavy|light` on the %Record; ABSENT =
 normal (the boolean rule generalized: the default is no key). Love on probation → heavy. Cleared
  by deleting the key (via a tracked replace). The racast picker weights heavy up, light down,
   resting to zero. Only matters once racast is a real programmer.

**Setlist — a programmed set — `<` t4.** A NAMED, ORDERED set of tunes — the radio show. filing
 gives a track one genre home; setlists are many-to-many. (%Crate was the natural name and is
  TAKEN — an opened collection dir; `Show` shadows %showing. Entries are **`Cut,seq:N,tune:…`** —
   a deep cut; DECIDED, owning that `Cut` sits one letter from the live %Cue deck particle — the
    read-aloud quality beat the grep risk.) A Setlist whose tune goes
    banned keeps the entry — the setlist is a document, the Ban is policy, policy wins at play
     time. Removal of a set or an entry = a tracked replace. racast casting a setlist as a program
      is where casting stops being shuffle and becomes radio.

### 11.3 The evidence — feeds the calls, never gates

**spins + skips — `<` t3.** Monotone lifetime tallies on the %Record (`spins:`/`skips:`), never
 reset, dying with their record. raterm bumps `spins` when a play crosses half the track (a guess
  — radio counts at air, streaming at 30s; tune at build), `skips` when the listener bails before
   that. Precedent: Musuation.g:1350 already tallies `sc.spins` on a radio particle. Legitimate stored
    state (a tally is not derivable from anywhere once the moment passes) — but it must stay
     independent truth, never a cache of the airplay log, or the two drift.

**airplay log — `<` t3.** The bounded recent tape — `seq spin|skip tune` lines in
 `.jamsend/airplay.log` (no timestamp column: `seq` alone carries the order the Hunch needs, and
  every column then reads aloud), capped ~500, reusing the proven `newlyadded` log mechanics. Real
   stations keep exactly this. The Hunch reads it (burnout needs ORDER, not totals);
    charts-this-week derives from it.

**charts — a function, not an organ.** `Chart_top(lib, n)` derives the countdown from spins at
 read time; storing a chart would be the assert-vs-derive disease. A %Chart particle may exist
  only as a %testing/view artifact.

**Hunch — the producer's suggestion — `<` LAST, and honestly a MECHANISM.** The machine notices
 and proposes; only the human decides. Two hunches at birth: burnout (a tune skipped 3 of its last
  5 plays → suggest a Rest) and three-bans (three banned tunes by one artist → suggest the
   artist-grain Ban). **The suggested act rides as the KEY** — `Hunch,rest:The Sines — Warm Static`
    / `Hunch,ban:DJ Oscillo` — the same trick as `tune:`/`artist:` grain; no `kind:` enum (the
     shape §11.1 bans). Taken → becomes the real fact, hunch retired; waved off → stays with
      `waved_off:1`, lives on the collection, and is itself never-GC (a waved-off hunch that
       vanished would re-nag — the family's second negative fact, same rule as the Ban). This
        organ quietly needs a rule-sweep loop over the airplay log + that per-subject memory —
         real machinery, which is WHY it is last: build it only after spins + the log are live and
          proven.

### 11.4 Parked surfaces (deferred until there is a surface)

**Liner** (`%Liner,note:…` child of a %Record — liner notes, the human's voice in the interior)
 and **Marquee** (the station's browse-face: what a peer sees is your charts/setlists/rotation,
  never file paths; NOT named "Ident" — Idento is the ed25519 pair, and a radio ident is the audio
   sting). Both are display-only leaves with no door; they return when raterm/browse UI exists.

### 11.5 Tier plan + the %Tombstone→%Ban migration

**Tier 1 is MOOT (2026-07-13): the tombstone is CONDEMNED (§10.2), not migrating.** The %Ban rename
 was host-vetoed already; now the underlying gear goes too — a heist keeps only the held-skip,
  poke-outs are manifest gestures, and IF a taste surface ever wants standing refusals they start
   fresh from Booth vocabulary with a REAL populator (the deny ceremony never was one). The Tier 1
    checklist below is KEPT because it maps every tombstone touch-point exactly — it is the RIP
     checklist now: DELETE at each site instead of renaming, drop the retomb scene instead of
      rewording it, and the two pinned see sentences die with it (the deny-drop sentence and its
       honest-log gate survive — deleting + logging needs no ledger).

**Tier 1 (now, one live-gate)** — one new ghost, `Ghost/M/Booth.g` (no Tune.g litter — six verbs,
 one enrollment): `Tune_key`/`Tune_split`/`Tune_of` + `Booth_ban`/`Booth_bans`/`Booth_lift`
  (both grains from day one; `Booth_bans` is the probe, spelled as a question). Then the migration:
 - `Ghost/M/Heist.g`: `Heist_feel`'s inline mint → `Booth_ban`; `Heist_beat`'s door →
    `Booth_bans`; `job.sc.tombstoned` → `job.sc.banned`; DELETE `Heist_tombstoned`; comment
     sweep (:95-101, :150-157, :254, :270-278).
 - `Ghost/Story/Heistation.g`: `retomb` → `encore` (phase flow comment :96, :110, :118-119;
    bundle :223-229; flow :270, :275, :301, :316; witness :486, :493) + `Tombstone:1` query →
     `Ban:1` (:494) + `ht.sc.tombstoned` → `banned` + BOTH see sentences reworded to (pinned here
      as the quality bar — no commas, radio-land):
      deny (:485): `the listener dropped the track and the Booth banned it — the file gone from
       the disk and the do-not-play card standing on the collection`
      encore (:496): `the same shelf came round again and the banned track stayed refused — the
       collection remembered the ban and pulled nothing`
 - Enrollment order (the bomb): LocalGen BOTH gen `.go` files FIRST, then add Booth.g to
    CREDULER_GHOSTS (LiesLies.svelte :55).
 - Fixtures: exactly 26 snaps (017-042) carry Tombstone/tombstoned/retomb — ONE live re-record
    run + accept refreshes them; pre-pin the %see set (11 sentences, two reworded).
 - Sabotage-proof: `Booth_bans` → `false`, LocalGen → the denied track re-heists
    (`landed=1, banned=0`) → the encore see DROPS → red; restore, recompile, green.
 - Unrelated namesakes stay: `%UnGrant` (crypto ledger), the `%wore_out` record-wear GC
    (Radiola.g:227 prose calls it a tombstone), and Musuation's `{tune:1}` test-result mainkey
     (§11.1) are NOT this and keep their names.

**Tier 2**: Rest + Wanted (the other two door-facts; heist door learns priority/want_only).
**Tier 3**: spins/skips → airplay log → charts (the evidence spine — each lands with a consumer).
**Tier 4**: rotation + Setlist (racast becomes radio) → Marquee/Liner when there's a surface.

### 11.6 Vetting record

Two adversarial rounds (2026-07-12, eight Opus critics total — human-voice, music-land naming,
 particle discipline, YAGNI, coherence, then fresh-eyes re-review). The blow-by-blow of what each
  round changed lives in `history/Radio_buildlog.md`; what belongs HERE is what stops a re-churn:

 **Dissents (kept against a critic, deliberately):** `Rest` keeps its name (critic wanted
  Benched/Cooldown — sports/gamer-speak; "resting a record" is the radio term, and the
   music-notation rest — a written silence — HARMONIZES); `encore` keeps its name (one critic read
    encore as demand-not-refusal; the naming critic called it the best rename in the doc — the
     shelf IS offered again); `Cut` for setlist entries over `Track` (12 live collisions) and
      `Slot` (scheduling-grid speak) — the %Cue one-letter risk is owned.
 **Settled — do not churn:** the `tune:`/`artist:` handle + grain-by-key; the calls/evidence
  two-layer model with the story-first §11.0; the four-question frame per fact; Ban
   stands-till-lifted + never-GC; the Rest≠weak-Ban distinction; the §11.5 checklist.
 **Round 2 verdict: SHIP-WITH-FIXES — all applied**: `Booth_banned`→`Booth_bans` (probe as
  question), Hunch enum killed (act-as-key + `waved_off:`), `until:`→`back:`, `want_only:`→`raid:`,
   airplay `ts` dropped, `Cut` decided, the Musuation `tune` namesake noted, both see sentences
    pinned (§11.5). Migration checklist independently verified against live code: zero line drift,
     26 fixture files exact, em-dash encode-safety proven in 198 recorded snaps.

### 11.7 The Berth — where a Pier's documents live (the persistence ruling, 2026-07-13)

A **Berth** homes one Pier's Wafts — "like Lies does but without the rest of that
 complicatedness" (the human's cut). The Waft is the project-standard mutable robust document;
  what was missing is a HOME for per-identity ones and a reset story for Books. A pier berths
   boats; ours berths documents.

- **Shape**: a Berth is a directory of Wafts, one per Pier —
   `<root>/.jamsend/berth/<prepub>/<Waftname>/toc.snap` — the EXACT wormhole shape
    (Credence/Trope are the prior art: a Waft = a dir with a toc.snap), just homed under an
     identity instead of the repo tree. The "wormhole/ goes to .jamsend/<identity>s-wormhole"
      oddity the human named IS the design: same encoding, different root.
- **Reset-with-the-Story falls out of homing**: the app passes root = the collection (durable;
   the documents TRAVEL WITH the music); a Book passes root = its marrauding namespace, so the
    existing start/end sweep resets every berth for free — no new reset mechanism.
- **API** — ✓ BUILT 2026-07-12 in `Ghost/M/Heist.g` (region `//#region berth`, LocalGen-green;
   homed at the first consumer, the heist, NOT a new organ ghost as ruled). As built (two refinements
    from the sketch): `Berth_dir(root, prepub, name)` → the on-disk path;
     `async Berth_open(nav, root, prepub, name)` → deWaft the toc.snap into a live C tree (mints an
      empty `%Waft` when absent, a first open is not an error), stashing the dir on `waft.c.berth_dir`
       (runtime-only) so — refinement 1 — `async Berth_save(nav, waft)` needs only the waft;
        refinement 2 — save uses `write_file` (the snap is TEXT, enWaft returns a string) not
         `bin_write`; `async Berth_reset(nav, root, prepub, name)` drops one Waft's toc.snap by name,
          or sweeps the Pier's whole berth via `Heist_sweep` when name is falsy.
   The MusuBerth Book proving the round-trip + reset-with-Story is authored + registered, LIVE-GATE
    OWED (the runner was wedged at build time — dispatch after a tab reload).
- **Binding**: to the ENCODERS only — `enWaft` (Text.svelte:351) / `deWaft` (:389) + the 7-method
   nav contract. ZERO Lies runtime — no LiesStore, no Cortex, no docks. Lies can MOUNT a berth
    Waft in the editor grid later (view + hand-edit the same document); the Berth never needs
     Lies to function. That answers "too bound to Lies?": bind to the encoding, not the machine.
- **What lives there — the music listening documents**: `Waft:Listening` (probation feelings +
   history; the raw newlyadded line-file stays as the arrival LOG, the Waft is the structured
    document), `Waft:Taste` (verdict cards the doors `o()` DIRECTLY — the document IS the store:
     no ledger, no rehydration, no Booth — straighter, as ruled), `Waft:Filings` (remembered
      believe/disbelieve defaults — the old Pirating memory), `Waft:Map` (the Pier's OWN
       recommendations — §10's %TreasureMap sibling grown into the heist's FRONT DOOR).
- **The anti-klepto front door** (the "klepto is warping the mind of it" fix): a heist should
   START from (a) the listener's genre starting points and (b) the source Pier's advice — its
    Waft:Map, replicated FIRST and shown as "check out first" (music-blog material as a
     document). A Waft subtree is C**, so Repli moves it like anything else; grants gate it like
      any Radio leg. Klepto "everything you offer" demotes to ONE mode, not the mind-set.
- **Every data file is enWaft — pure C** (the human's ruling, 2026-07-13): no ad-hoc line
   formats, no broken objects. Berth documents already are; `newlyadded` MIGRATES into
    Waft:Listening rather than staying a line file; the unwired booth line-ledger dies unbuilt;
     the §11.3 airplay-log sketch becomes a Waft region when built.

## 12. The stimuli machine + the magazine — protocols become media between brains (vision-checked 2026-07-13)

The riff that reframes §10's heist and §9's Pier reality as ONE mechanism. Repli already moves
 arbitrary C** (deL/enL, buffer pages, PULL, %Sent_Tree — §1.3); only convention says what it moves
  is %Records. The generalisation: each Pier keeps MAGAZINES — curated C** media — and every
   protocol is magazines moving between Piers, with a STIMULI MACHINE at each end deciding what an
    arrival means. A heist request stops being a protocol verb and becomes a want that replicates
     to the ORIGIN Pier and surfaces on its brain-agenda — the owner's grants, tombstones and taste
      mediate at the owner's end (the anti-klepto inversion; §11.7's front door seen from the other
       side of the wire). The UI and the front door become the same object: a magazine reader.

### 12.1 Beliefs are SERVED, by stance — one brain, and a door per relationship

(Language reset 2026-07-13: the kitchen/counter metaphor is DEAD — "counter" reads as a tally in a
 codebase that counts everything, and the kitchen named nothing that was not already the House.
  The ruling itself stands; only the words moved.)

beliefs()/Selection.process over H/A/w is the giant HIGH-TRUST pool: every ghost method mixes into
 the House (eatfunc), so any req a sweep touches can reach everything. The human's ruling
  (2026-07-13): the House does NOT want carving into per-Pier sandboxes — that is subtractive
   security (take the full pool, remove the knives, hope you found them all), at most an
    experiment. The assuredly-correct cut: **beliefs are SERVED onto the magazine's properties by
     the Se pass, scoped by STANCE** — and the two stances are NOT symmetric instances:
 **for-oneself is not an instance — it is the House.** Publish + evolve the magazine as the
  collection churns (re-census, rename missions minting %Renamed, the curated voice), feed one's
   own listening: one's own House sweeping one's own media, full trust because it is all yours.
    The M-rungs carry the verbs; the standing version is Upkeep-shaped — a standing pass that
     notices drift and republishes, paced over enrolled followers the way Ra_transcode_pump
      already revolves.
 **for-another is THE DOOR — the only new construct.** The narrow per-relationship handler a
  foreign want meets: it decodes the want into plain scalars, asks the grant (repli_allow(peer,
   at) — asked at every leg, cached nowhere), matches READ-ONLY against the magazine, and emits
    streaming legs or a noted refusal. That is its ENTIRE belief set — correctness by
     CONSTRUCTION, not subtraction: foreign input is only ever READ as data, nothing arriving is
      minted into a swept space, so a hostile tree claiming req:/eternal lands INERT — the escape
       routes were never in the room. Many doors revolve while the one House keeps working.
        "Door" is the codebase's own admission word (SwarmDoor, "consulted at the door", "refused
         at the door") — doors are the admission-gate family the way %UnGrant is the
          decision-fact family.
 Prior art in miniature (all live-green): `w.c.repli_allow(peer, at)` is already the
  per-relationship consent answer (Repli.g:249); `Repli_register_caster` enrolls serving Piers;
   `Ra_transcode_pump` (Ra.g:1007) is a demand loop revolving over every enrolled caster. §12
    grows THAT shape from chunk-serving to magazine-serving. And Matstyle is the rhyme for
     property-level serving: it autovivifies STYLE by mainkey classification — the Se pass serves
      BELIEF by property × stance the same way.
 **Said in the Voro voice** (language sync with `Voro_todo.md` ①, the Se-up model — the two docs
  are converging on ONE Se philosophy): a Selection pass over a data space computes READINGS, and
   readings wear `%Se` as PROVENANCE (Se:scape/Se:census/Se:drift there; an Se:serve family here)
    — never to be confused with the space's own content. The magazine is CONTENT (authored voice
     + computed census); the House-work and the door are ONE Se pass in two STANCES, and what they
      produce is the SERVE-MODEL: %Se-worn readings of the same magazine — what is fresh and owed
       a re-publish (for-oneself), what is servable to WHOM under which grant (the door), what moved
        (%Seem resolves report drift; ABSENCE IS THE QUIET READING). The Voro_model pattern
         carries over whole: the full working model rides OFF-snap (c-side), a distillation snaps
          into a diagnostics world, so Books prove the readings without wire or pixels —
           snap-testable serving. One-fact-one-place keeps the seam honest: %Renamed is authored
            FACT in the magazine (content); NOTICING a rename broke a cursor is a READING (Se).
 Open mechanics (the next cooking, deliberately unresolved): what a DOOR IS
  mechanically (a per-relationship w under one serving world? a %Door particle family? — w is
   already the isolation/snap boundary with mutex-frozen reads), and how per-property belief
    binding looks concretely. (`House.subHouse(name)` exists, Housing.svelte.ts:553, but shares
     the FULL pool wholesale — :561 `Object.assign(sub, this.ghosts)`; parked as experiment
      material only.)
 Bombs that SURVIVE the redesign: the wire must NEVER mint live machinery — a decoded foreign
  tree must not graft into ANY swept space (today's "a %req below w never pumps without
   hand-stamped c.up" is an ACCIDENT doing duty as a wall, don't lean on it); HMR re-mixes ghost
    methods, so any construction-captured serving fns go stale on haunt; `sourceHousing` is
     already stamped on cross-House elvis (i_elvistwo :573) if provenance is ever needed.

### 12.2 The magazine — %Musica, the collection sublimed into media

A magazine is a curated C** projection of the filesystem: census walks the disk into %Records,
 crush folds the homogeneous sludge behind husks so it reads as MEDIA, and the Pier's own voice
  (Waft:Map — music-blog material, §11.7) rides beside. It lives as a Berth Waft, so it berths
   per-identity, travels with the music, and Repli moves it like any C** (grants gate it).
    album|title metadata is stored IN the magazine — that is what cursors anchor on (12.3).
     Authored, generated (the Ra entropy seam), or sublimed from disk: same media, same mover.
 **STRUCTURE (built 2026-07-13, M1): still %Records, with a %Cloud layer.** The magazine holds the
  census cards UNCHANGED — `%Record,id,artist,title,album,path,body_hash` (the SAME mainkey+scalars
   the collection holds, minus the %Body byte-slices; NO `genre` — a genre is a FOLDER not a card
    scalar and no census mints one, so the first cut's fabricated `genre` was a shape that cannot
     exist). Records do NOT hang straight off the Waft — they group under a
      **`%Cloud,randomic,created_at`** ARRIVAL BATCH:
```
Waft:Musica
  Cloud,randomic:<id>,created_at:<ts>     ← one publish's new arrivals, stamped when they came
    Record,id:…,artist:…,title:…,album:…,path:…,body_hash:…
    Record,…
  Cloud,randomic:<id2>,created_at:<ts2>   ← a later publish's batch
```
  So every Record wears the time it joined (read up through its Cloud), and a whole era is
   forgotten at once — `Musica_forget(nav, mag, cutoff, pub)` drops old Clouds AND cascades the
    radiostock-unlink to disk (BUILT 2026-07-17, `Ra_stock_cascade`, bias-to-keep; MusuReap green ×2).
     `randomic`+`created_at` are PARAMS not wall-clock: the app passes a real random
     id + Date.now, a Book PINS them (the Heist_marrauding runid pattern) so snaps stay deterministic.
  **`randomic` = a RANDOM DRAW (the human's clarification 2026-07-13):** a Cloud is not "the whole
   collection this tick" — it is a HANDFUL randomly MEANDERED out of a collection that is NEVER fully
    enumerated (`Crate_meander` random-walks the crate track by track — Crate.g). So the magazine is
     random samples accreting over time; `randomic` is the draw's fingerprint (it was randomly pulled),
      NOT merely a batch nonce. A publish that meanders more surfaces a NEW Cloud beside the old ones.
  **`Musica_fold` — the "one brain" (built 2026-07-13, §12.1):** `Musica_publish` split so the PURE
   reconcile-then-add is `Musica_fold(mag, lib, randomic, created_at)` (in-memory, no disk) and
    `Musica_publish` is the Berth wrap (open → fold → save). ONE magazine-building brain now serves both
     the disk publish AND the wire (M2/MusuVend folds in memory and offers over Repli). The fold stamps
      `cloud.c.repli_loc = ['Cloud','randomic']` so a Cloud reconciles by its draw-fingerprint on the
       wire (the default `['Cloud']` loc would collapse every batch to one blur at a follower).
 **Publish is RECONCILE-then-ADD** (`Musica_publish`, Ghost/M/Heist.g), not wipe-and-rewrite: drop
  any published id the collection lost + any emptied Cloud (the recast — a dropped track leaves no
   orphan), then lay the collection ids not yet in any Cloud under a fresh Cloud. `Musica_cards(mag)`
    is the flat catalog view (walk Cloud→Record); the Cloud layer is for GROUPING+forgetting, not
     browsing one era at a time.
 **OBSERVABLE-PLANE DISCIPLINE (the human's ruling, 2026-07-13):** a Book must put the magazine's
  actual Cloud/Record tree ON the snap (MusuMagazine reflects the disk-read handle into w/%Mag), so
   the fixture DIFF shows a card appearing / a second Cloud arriving / a dropped card vanishing — the
    DATA is the proof, %testing counts only accompany it (see [[snap-data-not-judgement]]). A
     judgement-only snap (`published,records=2`) is the drive grading its own homework.
 **BUILT (2026-07-13 night):** (a) the FOLD — `Musica_publish` is proven off MusuHeist's REAL
  census (Uno's landed collection reflected into w/%Mag on the snap; the deny gives a recast on real
   data), so the magazine no longer rides a minted toy; (b) cp-LANDING — `Heist_rel_for` lands at
    `<dest-root>/<source-path>` (`Heist_cp_path` sanitizes `..`), tags are metadata never file-naming,
     the mislabeled see inverted (the file keeps its name, the catalog knows the truth), `Heist_land_rel`
      deleted. MusuHeist 19→22 steps, 16 sees, green ×2. STILL owed (all `// <` at their sites, ride
       real disk / M2): weird tag text clamp; non-audio sibling probe + album-art/kid-safe oracle;
        dedup album+disc+track-else-path; landing-path clash verdict.
 (Was the blessing-owed plan; the human blessed it "build it!" and it landed.  Historic corner-case
  ledger: Corner-case ledger: weird tag text enters snapped
         scalars (clamp control chars + cap length); non-audio sibling in a picked-up dir (probe
          audio, parked `// <` at Heist_census); album-art needs an oracle (parked `// <` in
           Crate.g); landing-path collision → skip+`clash` verdict on the manifest.
 **The corner-case answers (the human, 2026-07-13 — all captured as `// <` at their code sites):**
  - **Non-audio siblings NEVER copy** (kid-safe): a heist moves AUDIO only, never `cover.jpg`/`.nfo`/
     stray images a stranger placed in the directory. Same rule as embedded album art — visual bytes
      need an ORACLE authority before they ride the wire, and v1 carries none (marks joined at
       Heist_census KID-SAFE + Crate_meta_from_tags ALBUM ART).
  - **Dedup must NOT drop a distinct track** (the Muslimgauze problem: 12 `Muslimgauze - Untitled` all
     share artist+title, so today's `Heist_held` collapses 11 as "already held" and eats them). The
      fix is layered and BIAS-TO-KEEP: (1) widen identity to artist+title+**album+disc+track** when
       tags carry them; (2) SENSE a thin identity — when those are absent so multiples cannot be
        separated, DO NOT dedup on it (a wrong drop loses music; a dupe costs one delete); (3) the
         **filename/path** is the reliable fallback axis — cp-landing keeps the original name, so
          `01 Untitled.flac`..`12 Untitled.flac` already distinguish on disk, and a same-path collision
           at the destination is the true-dupe/clash signal. So: dedup by rich-enough tag-identity ELSE
            by path, never drop on a thin tag-identity alone. (Rides the cp-landing wave — `Heist_held`
             mark.)
 Renames: a Pier that reorganises (retitles an album, splits an artist) mints %Renamed redirect-
  facts beside the renamed node — from:, to:, at: — IN the magazine, so followers receive the
   redirect through the same pipe as the content. (Naming note: "breach" is taken — it is the
    body_hash integrity fail in Heist_land. %Renamed is a NEW fact family — cousin of the
     %Tombstone/%UnGrant decision-facts, but a POSITIVE redirect and WINDOW-able: markers may
      supersede/expire, unlike tombstones which never drop.) Followers can then run renaming
       missions over their own filed copies — optional per Pier, a later rung.
 **BUILT (M3, 2026-07-14 — MusuRename, LIVE-GREEN ×2):** `Musica_rename(mag, id, key, to, at)` is the reorganise
  gesture — apply the retitle AND mint the `%Renamed` beside the card in ONE stroke (never a rename without its
   redirect). The marker + the retitled card ride the SAME Repli pipe to a follower; the card updates in place
    (loc `['Record','id']`, `title` a merge prop — no fork) and a follower's stale cursor heals through the
     replicated marker. `Renamed_mint` stamps `repli_loc:['Renamed','key','from']` so multiple markers stay
      distinct on the wire (the default `['Renamed']` loc would blur them). Missions stay on merge-PROP keys
       (`title`/`album`/`artist`) for now — a rename of a LOC key (id) crosses as add-not-move until
        delete-propagation is wired to the fold (`Musica_forget`'s PROPAGATION `// <`).

### 12.3 Cursors — a stack of matches, healed by rename markers

A %Cursor is a serialized STACK OF MATCHES — a descent path of o()-queries ({Musica:1} →
 {album:'X'} → {title:'Y'} → a seq window) — not indices. It is the native query algebra, all
  scalar: cursors SNAP, berth, and replicate like anything else. Resolution walks the stack
   re-finding each match; a failing level consults RECENT %Renamed markers and retries with the
    redirect (the heal), noting what it healed. This is where-we're-up-to for any follow/browse/
     replication-resume — resumable, showable (the gathering-performance UI), per-relationship
      (berthed). Prior art rhymes: Point,text: (content-addressed cursor, the text substrate) and
       %Map rel offsets — the Point re-anchoring problem class, solved once, deliberately.
 NOT a rebuild of Repli's inseq/pages — wire-level sequencing stays; a cursor is the MEANING-level
  position. Scope to magazine-follow first.
 **BUILT + LIVE-GREEN ×2 (C1, 2026-07-13 — modelled on `%lematch` per the human's steer):**
  the serialized name is a `%Dogear` (the mainkeys `%Cursor`/`%cursor` are taken — LiesKeep focus-history +
   LangCurse Interest), a linear spine of `%curs` match-segments (one `o()`-query each). `Cursor_*` in
    `Ghost/M/Heist.g`: `Cursor_make(home, into, queries)` mints it, `Cursor_resolve(dog, root)` walks the
     stack re-finding each level and returns `{ok, at, depth, landed}` or `{ok:false, at, depth, missing}` —
      the CLEAN-fail verdict is the exact seam C2's `%Renamed` heal plugs into. Snap-safe wildcard: the type
       rides as `wild:<Type>` (re-inflated to `{Type:1}`), literal pins flat, so it round-trips without the
        `Cloud:"1"` footgun and is KEY-AGNOSTIC (absorbs the §0 Cloud-model change). Proven by **MusuCursor**
         (three sees: lands-on-leaf, lands-on-a-level, clean-fail), LIVE-GREEN ×2.
 **C2 THE HEAL — LIVE-GREEN ×2 (MusuHeal, 2026-07-14):** `Cursor_resolve` grew a heal branch — a failing level
  consults recent `%Renamed,key,from,to` markers beside the last node reached (`Cursor_heal`) and retries with
   the redirect, landing on the moved node and recording `heals:[{key,from,to}]`. `Renamed_mint` lays a marker
    beside the renamed node IN the magazine (a positive, window-able cousin of `%Tombstone`/`%UnGrant`, `at:`-
     stamped, newest-wins). The heal is transparent to an un-renamed cursor (no marker → empty `heals` → C1's
      verdict unchanged). MusuHeal proves it with a marked/unmarked twin: the marked cursor heals to the new
       identity, the unmarked one fails cleanly — the marker is provably load-bearing.
 **C3 THE RESUME — LIVE-GREEN ×2 (MusuResume, 2026-07-14):** a `%Dogear` homed INSIDE a magazine survives a full
  `enWaft`→`deWaft` round-trip (the disk-less core of Berth save+open; MusuBerth owns the real FSA disk) and still
   resolves to the record it named — the resumable browse. Runs on ANY runner (no FSA), deterministic. `Cursor_resolve`
    walks DOWN via children (never `c.up`, which doesn't survive decode), so it resolves cleanly against a freshly-
     decoded tree; the `%Dogear`/`%curs` spine encodes with zero protocol work (the enWaft vocabulary gate is parked —
      any mainkey rides). Discrimination: a live-only bookmark under `%testing` does NOT ride the snap (re-decoded
       magazine carries exactly one Dogear); independence is gated on the re-decoded cloud being a DISTINCT node
        object — an adversarial hardening, since `deWaft` structurally can't alias so the earlier `!old.ok` leg was
         tautological.

### 12.4 The jobs ladder — little, Book-gated, mostly independent starts

Gate 0 (owed): MusuHeist accept to 15/15 + MusuBerth first live run — bank the substrate.
 **M — magazine**: M1 Musica_publish (census + crush → a %Musica Berth Waft, metadata in-magazine) ✓;
  M2 two-Pier magazine replication (the existing Repli pipe, grants gate) ✓ LIVE-GREEN ×2 2026-07-13
   (MusuVend Book — magazine folds in memory, Repli_offers whole husk, grant on↔off↔on, forget; 11/11
    caveat:0, 6 sees); M3 ✓ %Renamed markers minted by a rename mission + replicated with the magazine
     (MusuRename Book, LIVE-GREEN ×2 2026-07-14 — `Musica_rename` = apply+mint one gesture; the marker rides the
      pipe and a follower's stale cursor heals through it; `Renamed_mint` `repli_loc` keeps markers distinct;
       9/9 caveat:0, 5 sees, all SOUND adversarially).
 **D — the door** (12.1; the K rungs DISSOLVED 2026-07-13 with the metaphor): D1 the
  door-hardening Book — the for-another serving path over the magazine, grown from the existing
   consent hook (repli_allow + register_caster + the pump); its Book includes the SABOTAGE scene —
    a hostile stream claiming req:/eternal mainkeys lands INERT, because the door only reads
     want-shapes; an ungranted want is refused with the refusal noted (was K1). The for-self
      standing evolve is House-work, so it files under M as **M4** — census-diff re-publish
       (✓ its wire heart — MusuRecast, LIVE-GREEN ×2 2026-07-14: `Musica_recast_offer` folds + offers neus +
        crosses a path-carrying op:delete per goner at BOTH the record and cloud level, no orphan; ✓ made STANDING —
         MusuStanding, LIVE-GREEN ×2 2026-07-14: `Musica_stand` fingerprints the census and re-publishes only on a
          real change, an unchanged census puts ZERO frames on the wire),
           rename missions as a standing Upkeep-shaped pass (owed), the revolving service pacing over
            enrolled followers (Ra_transcode_pump generalized — the roster FAN-OUT, needs per-follower mirror
             routing, owed) (was K2).
  **D1 SPLIT (2026-07-13): part b LANDED (MusuDoor, LIVE-GREEN ×2, `f76b3d7e`); part a OWED.** The
   recipe below was followed for part b (the sabotage wall) with ONE correction from the build: the
    canary is NOT an immediate-child check (an adversarial review caught that as a false-green — it
     misses a deep-walking-sweep regression) but a DYNAMIC `req_sabotage` handler that flips `w.c.pwned`
      if the buried req is ever PUMPED, proven live by a control that pumps an identical req through a
       throwaway holder world. Part (a) below (the crypto door) is the remaining rung.
  **D1 BUILD RECIPE (teed up 2026-07-13 — build once M2 is live-gated):** fork MusuVend (the wire +
   two Piers + the grant seam are proven there). (a) HARDEN the grant: swap MusuVend's Book-owned
    `w.c.grants` toggle for the LIVE Swarm verdict — copy MusuHeist's shape
     (`w.c.repli_allow = (peer, at2) => Swarm_pier_live(Swarm_peering(ident).o({Pier:1,pub:peer})[0], 'Music')`
      via `SwarmStaple_ident`/`Swarm_mint_idzeug`/`Swarm_redeem`); NOTE this reintroduces seal wall-clock
       → the fixture needs an EntropyProfile (Wref:Trope/Ra/AudibleEntropy or a fresh seal-tolerant one)
        + a warming re-accept — MusuVend's determinism is deliberately NOT carried into D1. (b) THE
         SABOTAGE SCENE (the §12 heart, the anti-klepto inversion): a hostile origin offers a magazine
          whose card carries a grafted `req:`/`eternal` child; the follower merges it (Repli_merge reads
           it as plain data). ASSERT it lands INERT — a canary the malicious req WOULD set (a w.c flag, a
            minted particle, a side-effect) stays UNSET across a full belief pass, because the wire never
             stamps c.up into a swept world. Make it BREAKABLE: if the merge stamped c.up + pumped, the
              canary flips → the see drops. BOMB (§12.1): today's inertness is "an ACCIDENT doing duty as
               a wall" (a decoded req has no c.up into a swept space, so it never pumps) — the sabotage
                see PINS that accident so a future change that starts pumping foreign trees goes red; the
                 REAL construction-level wall (a merge that provably cannot graft live machinery) is the
                  deeper owed rung the see guards toward. (c) keep MusuVend's ungranted-refusal scene.
                   Do NOT ship the sabotage see without a LIVE run — an unrun security assertion can be
                    vacuously green, the worst false-green; adversarially review AND live-gate it.
 **C — cursors**: C1 the %Dogear primitive + resolver (resolve | fail cleanly, own Book scenes) —
  BUILT + LIVE-GREEN ×2 as MusuCursor (§12.3, 2026-07-13);
   C2 ✓ heal via recent %Renamed (MusuHeal, LIVE-GREEN ×2 2026-07-14 — the `%Renamed` fact-shape + `Cursor_heal`
    landed here; M3 mints the same markers from a real rename mission later); C3 ✓ cursor as follow-progress,
     berthed (MusuResume, LIVE-GREEN ×2 2026-07-14 — a berthed %Dogear survives an enWaft→deWaft round-trip and
      resumes the browse). **The cursor arc C1·C2·C3 is complete** — and M3 (MusuRename, LIVE-GREEN ×2 2026-07-14) has now
       exercised the heal on LIVE wire-replicated markers, so the remaining cursor-flavoured work is U (the
        magazine reader turns wants into cursors).
 **S — stimuli surfacing**: S2 the agenda bridge (a want the door accepted mints an %Errand on
  the Brink — the owner SEES the want); S3 the heist rides it — the want-driven front door
   (§10.2 #4 merges here: genre starts + the origin's Waft:Map advice; klepto demotes to one
    mode).
 **U — the magazine reader** (Big*land family): browse a replicated %Musica, wants become cursors;
  build AFTER the rungs give it real data.
 (P — the projected subHouse — PARKED as experiment material per the 12.1 ruling; do not build.)
 Dependencies: M1 ✓ (landed + live-recorded 2026-07-13); M2 ✓ (LIVE-GREEN ×2 2026-07-13); D1 part b ✓
  (MusuDoor, the sabotage wall, LIVE-GREEN ×2 2026-07-13); C1 ✓ (MusuCursor cursors, LIVE-GREEN ×2 2026-07-13);
   C2 ✓ (MusuHeal, the %Renamed heal, LIVE-GREEN ×2 2026-07-14); C3 ✓ (MusuResume, the berthed-cursor resume,
    LIVE-GREEN ×2 2026-07-14 — the whole cursor arc is done); M3 ✓ (MusuRename, LIVE-GREEN ×2 2026-07-14 —
     `Musica_rename` mints `%Renamed` from a real reorganise gesture + replicates it, the heal now proven on live
      wire markers); M4 (first rung) ✓ (MusuRecast, LIVE-GREEN ×2 2026-07-14 — `Musica_recast_offer` crosses a goner
       as a path-carrying op:delete at the record AND cloud level, no orphan on the wire); M4 (standing) ✓
        (MusuStanding, LIVE-GREEN ×2 2026-07-14 — `Musica_stand` fingerprints the census and re-publishes only on a
         real change, a quiet census sends zero frames). The OPEN rungs, in rough order of readiness:
     **M4 (rest)** — the roster FAN-OUT: standing over N enrolled followers (Ra_transcode_pump generalized), which
      needs per-follower mirror routing (Repli_mirror_lib keys off one `w.c.repli_mirror_pier` today) — plus
       rename missions as a standing Upkeep pass; the census-diff wire heart AND the single-relationship standing
        pass are now proven, this is the roster shell around them; **D1 part a** (harden the grant toggle into the
         live Swarm_pier_live door — one
        revoke-mid-relationship scene, best folded into MusuHeist; reintroduces seal entropy, so needs an
         EntropyProfile + a warming re-accept, ATTENDED) is the remaining door rung; S3 needs D1 + M2 + S2; **U**
          (the magazine reader — wants become cursors) needs M2 ✓ + C1 ✓ and is now UNBLOCKED (the whole cursor
           stack it leans on is green).

### 12.5 The heist wriggles in — every gear re-homes into making | replicating | responding

Nothing built is thrown away; each existing gear has a §12 home waiting:
 - `Heist_census` (disk → %Records + husks) → **MAKING**: the House's sublimation step. Census
    stops being per-heist prep and becomes the standing publish (M1, then M4's standing
     republish) — a landing that changes the collection re-publishes the magazine. This is now BUILT:
      `Musica_recast_offer` (M4/MusuRecast) re-folds and crosses BOTH the neus and the goners (a lost card
       = a path op:delete, a lost era = a cloud op:delete); and `Musica_stand` (M4/MusuStanding) is the
        standing pass over it — it fingerprints the census and re-publishes ONLY on a real change (an
         unchanged census sends nothing), so a follower's mirror tracks the collection's drift with no
          orphan and no wasted wire. Remaining: drive the pass off a real Upkeep + fan it out over a
           follower roster.
 - `Heist_offer_all` + the mirror → **REPLICATING**: the mirror IS a replicated magazine slice
    already; the bespoke offer verb is the first thing to RETIRE (at M2) into a Repli pull of the
     %Musica subtree. Husks/crush carry over unchanged.
 - `Heist_manifest` → **RESPONDING, follower side**: the want evaluated against one's own
    collection (it already reads (job, mir, own_lib)); it grows into the reading a browsing
     follower sees BEFORE wanting — look-before-commit becomes the reader's verdict column.
 - `%Caper,at:` job scaffolding → the WANT-BUNDLE: short-lived, cursor-pointed into the magazine
    (C1/C3); "exists for as little time as possible" already matches the stimulus shape.
 - `Heist_beat` / `Heist_land` (streaming, body_hash + breach, filing, the verdict rows) →
    **UNCHANGED**: the serving legs the door drives (D1) and the landing side the wanter keeps;
     the verdict rows stay the job's honest ledger (holds/fresh once the tombstone rips).
 - `%Tombstone` → CONDEMNED (2026-07-13, §10.2): it rips out entirely — a refusal is the door's
    noted MOMENT (not a ledger); per-heist poke-out is the manifest gesture; durable narrowing
     waits for the §9.2 `%Share` match.
 - `newlyadded` → `Waft:Listening` (the §11.7 migration): probation feelings become Berth document
    rows; the arrival LOG stays honest beside it.
 - `Heist_marrauding` + `Heist_sweep` → unchanged: the Books' reset floor (MusuBerth proves the
    berth rides it).
 - grants / `repli_allow(peer, at)` → the door's gate (D1): per-relationship consent
    generalizes from chunk legs to magazine serving.
 What DIES: the tombstone (ripped, §10.2) — then offer retires at M2, and klepto "everything you
  offer" demotes to one mode at S3.

---

## 13. The toplevel — /BigSoundland, where it all comes together

The one place every spring above surfaces as a page a human actually touches: `src/lib/V/BigSoundland.svelte`
 (the scape) + the glass under it (Vytui, `%Heist`/`%Radio`/`%Stoker`/… faces) + the InvitePanel strip. Every
  other section here builds an organ; this is the body they get worn on. Items land here when they are about
   the **assembly** — what a person sees when the parts are all present — rather than about one engine.

Expect this section to want an ironing-out pass of its own before long (owner, 2026-08-05: "it probably
 needs another ironing out soon but not yet") — the two view modes below have drifted apart and no single
  ruling governs what shows in which. Don't do that pass piecemeal; do it as one sitting, with the page open.

### 13.1 The two views, and the ActionButtons (owner, 2026-08-05)

**The ask: show the ActionButtons for each H automatically — "they are too useful."** Today the rack is
 triple-gated at `BigSoundland.svelte:247` — `{#if sprawl && show_actions && active}` — so it needs the ▦
  sprawl, then the ⚙ cog, and even then shows only the *active* House's actions. Ungating it to
   one-rack-per-House is small; the reason it is filed rather than done is that it lands on the wrong side
    of an unsettled line:

- **The dev/working view** — where the ActionButtons belong, on sight, per House, no cog.
- **The end-user view** — "everything invisible except the Vyto and the Invite interface, the only non-Vyto
   thing hovering over the top, as the actual users will find it." The owner reports this as a mode that is
    **default off**. It is NOT in the tree under any name I could find: the nearest thing is sprawl-*off*,
     which is already the default and still shows the header bar, the glass badge, the House chips, the
      InvitePanel and the whole diagnostic surface. So either the mode is remembered from elsewhere, or it
       is owed — and it has to exist before "show everything useful by default" is safe, because it is what
        keeps the useful clutter off a real user's screen.

So the order is: **settle the two views first, then ungate the rack into the dev one.** Doing the rack
 first just moves clutter into the view that has no escape hatch. Related and already mapped:
  `UI_seams_todo.md` S1 (quiet the resident glass) is the same question asked of the Vyto cells, and its
   `?diag` gate proposal is a candidate shape for the end-user mode.

## TODO — the dial should FLY (the human 2026-08-07)

**"react to clicking Heist (and next-track too — push a TODO for making this fly around the available
 tracks super pleasingly — it might even want to be on a separate thread)."**

Two halves, and the first is the general lesson:

- **Every glass control must move on the CLICK, not on the pass.** `post_do` defers the write to the next
   belief pass, so a control shows nothing until then — and an unmoved control invites a second click,
    which is exactly how the LOFI tickbox ended up unticking itself right as ▶ start was pressed
     (HeistFace `toggleLofi`, fixed there with a local `wish` + an ABSOLUTE value rather than a toggle read
      late). ⇊ Heist and next-track want the same treatment. Audit the rest of the glass for controls whose
       only feedback is a model round-trip.
- **Next-track should fly around the available tracks.** Not a cut — a visible traversal of the pool
   (ShuffleFace already draws it as pips, lit = chunk 0 landed = dialable). The human's read is that it may
    want its own thread, i.e. it must not share the belief loop's mutex: a traversal that stutters whenever
     a pass runs long is worse than no animation. Worth checking whether the wave/grawave timing Cyto
      already uses can carry it before reaching for a worker.

Related, same session: `avoid loading half of the Record/Preview until we start playing it` — `Ra_keep_ahead`
 (default 4) pre-pulls the FULL preview window of that many upcoming records, so the pool sits at ~50% held
  before anything is chosen. Wanted: seed depth ≈ chunk 0 (enough to be dialable, which is all
   `Radio_dial_pool` gates on), full preview only for the track under the needle. NOT attempted — it moves
    MusuStock / MusuRadio / MusuReplica fixtures and wants a session with the whole suite in reach.

## TODO — BOOT TAKES ~35s BEFORE ANY MUSIC CAN MOVE (measured 2026-08-07)

The human: *"refreshing Righto after a while, it doesn't connect Radio for a while there... but then
 eventually, 30s later or so, comes right"* + *"why does this boot take so long"*.  Their read was
  "we're loading too much Record data before we get around to playing" — **measured false**, twice:
   from `crate-born` to `first-sound` was **250ms**, and from `page-first` to `first-feed` **36ms**.
    No byte transfer is involved in the delay at all.  Do NOT optimise the pull path for this symptom
     (that is what the `Ra_keep_ahead` item above would have done — it addresses the 250ms).

**The chain.**  `Swarm_share_up` (Swarm.g:1751) bails with `share-no {why:'radio world not standing
 yet'}` until `top.c.radio_w` is stamped, and `Stoker_ensure` (Radio.g:1148) — reached only from
  `Radio_dial` — is the sole place that stamps it.  So between the seal and the first dial the tab has
   no share loop: it can neither offer its own stock nor register an rx for the friend's cast.  Sealed,
    Music-granted, happily playing its own shelf, and completely deaf.

Righto's boot ring (`wormhole/_trace/runner-f5da6599b8505881-1786093330013.jsonl`):

     +5.0s   seal → station-up → share-no {radio world not standing yet}
     +5.0s   advertise piers:1 granted:1 told:0 records:0 cw:0 selfs:0 homes:0 stocks:0
     +20.6s  advertise ... records:0 cw:0        (still nothing, 15s later)
     +24.3s  boast-heard {of:96d0cf88, records:0}   ← the friend says "I have nothing"
     +35.0s  share-up
     +35.2s  boast-heard {of:96d0cf88, records:8}   ← the truth, 11s after the lie
     +40.9s  tour dug:8 stock:8 · advertise records:8 artists:3 cw:1 selfs:1 homes:1 stocks:1

Lefto's ring is the mirror image (seal +20.5s, share-up +28.0s, true advertise +35.1s).

**Two fixes, independent.**

1. **ORDERING — arm the share on the radio WORLD, not the first dial.**  Nothing about
    `Swarm_share_up` actually needs the dial to have spun; it needs the world the stoker shelves in.
     BigSoundland already knows the resident world at boot (`boot_param('B') || 'Sounditron'`), so
      `radio_w` can be stamped when that world stands.  Keep `Stoker_ensure`'s stamp as the idempotent
       backstop — losing that race is the 2026-08-06 bug its comment describes, and this must not
        re-open it.

2. **TELL NO FALSE FACT — suppress the count, don't send a zero.**  For 30 seconds each peer
    advertises `records:0` with `cw:0`, and `cw:0` means `census_w` was never pointed at the radio
     world, so that zero is *known false at the point of sending*.  Righto wrote Lefto's "records:0"
      down at +24.3s and only unlearned it because a later boast happened to land.  While `census_w`
       is unset, `Swarm_gossip_music` should send **no count** rather than a zero — a peer that says
        nothing is honest, a peer that says "0" is lying and the lie gets recorded.  Same "not yet
         reported as never" shape as `Radio_supply_go` (Radio.g:727) reading the first null from
          `Ra_transcode_ensure` as `'preview only — source unreadable'`; see Sounditron_todo.

**3. THE STEP CLOCK — and it is a TIMER, not work (measured 2026-08-07, second pass).**  The
 resident Sounditron world's steps pace the whole thing, and the marked work in a step is
  `quiesce 0.25s` + `snap-cost 41ms` + `vyto-wait 60ms` ≈ **350ms of 7.8s**.  The gaps had no marks
   of their own — but the two electrodes already planted (`advance`'s `resolve`/`to_step`, and
    `quiesce`→`snap-cost`) bracket them exactly, and reading them settles it.  Per step, on
     Righto (`...1786093330013`) and Lefto (`...1786095853919`), every step, both tabs:

     advance→quiesce      0.25s     the drive itself: free
     quiesce→snap-cost    3.64s     ← gap A
     snap                 0.04s
     vyto-wait            0.06s
     vyto-wait→advance    3.80s     ← gap B   (to_step 3801 / 3800 / 3803, resolve 0)

**`to_step` is 3801 ms ±3 on two independent machines across every step.  That is a timer.**  A
 backlog jitters; a fixed constant is a clock.  The constant is `reset_interval()`'s ambient tick —
  `interval || 3.6` at `Hovercraft.svelte:72` — plus `AMBIENT_MAIN_TICK_MS` (200), the `main()`
   throttle.  3600 + 200 = 3800.  `resolve:0` clears the Runstepped callbacks outright, and the
    fixed 200 ms in `schedule()` hides *inside* the interval rather than adding to it.

**The shape.**  Both gaps are the same event: a `post_do` sitting in a todo that nothing drains.
 `post_do` (`Housing.svelte.ts:834`) only pushes and bumps `todo_version`; the drain is the
  `$effect` at `:561`.  A healthy drain is `ANSWER_CALLS_TICK_MS` 50 ms, or 4 ms galloping — three
   orders off what we measure.  So the wakeup is being lost, and the item then waits for the ambient
    heartbeat, which `_really_answer_calls` **re-arms inside the mutex on every drained item**
     (`:1103`).  Lose the wakeup and you pay a *whole fresh* 3.6 s, every time.  Two `post_do`s per
      Story step (`do_step`, `snap_step`) ⇒ 7.2 s of a 7.8 s step is the tab waiting for its own
       heartbeat.  **~93% of the resident step clock is a lost wakeup, not work** — which is exactly
        why every electrode aimed at work came back cheap.

**The watchdog for this already exists and cannot fire here.**  `Story.svelte:2424` documents the
 lost wakeup and re-drives the drain — but it re-drives `Run.answer_calls()` under a
  `Run.todo.length` guard, while `story_drive` posts both phases with **`H.post_do`** (`H = this as
   House`, the Story ghost's House — `Run` is a different House with its own todo).  Wrong queue,
    and the guard therefore reads 0 forever.  It is also only reachable from inside `poll_step`,
     which is not running during either gap.  Doubly inert, silently.

**Why Books never showed it:** MusuReco steps at ~1.1 s on the same runner in the same minute.  So
 the wakeup is NOT universally lost — something about the *resident* tab (live glass, live organs,
  `trickle`, a contended top-House mutex) loses it.  Nailing that last inch is one cheap electrode,
   not a theory: stamp the push time in `post_do` and compare it at drain against the `c.drain_at` /
    `c.drain_tried_at` / `c.drain_why` that `_really_answer_calls` already writes.  It forks clean —
     **`drain_tried_at` stale by ~3.6 s ⇒ the `$effect` never fired** (fix: make `post_do` self-
      driving, `this.answer_calls()` after the push — re-entrancy-safe, since the mutex branch bails
       and re-arms its own 50 ms retry); **`drain_tried_at` fresh with a `drain_why` ⇒ it fired and
        was gated**, and `drain_why` names the holder.  Do not apply either fix before that fork is
         read — they are different bugs with the same face.

**IT IS NOT CPU, AND The/TimeSpool SAYS SO OUTRIGHT.**  Sounditron's own spool carries
 `TimeTotal:beliefs,avg=0.077` and `TimeTotal:step,avg=0.011` — **77 ms of belief-mutex time summed
  across every step of a whole run**, against a boot of ~60 s.  `collect_time_sample` sums
   `sum_beliefs_time` over every step with a `Run_trace`, so that is the total thinking the machine
    does.  There is no work to optimise and no "turbo mode" to switch on: 99.9 % of the boot is the
     machine waiting for permission to run the next 11 ms.

**ELECTRODE PLANTED 2026-08-07 — `drain-lag` (Housing.svelte.ts).**  `_push_todo` stamps `e.c.push_t`
 plus a snapshot of three new monotonic counters, and the successful shift in `_really_answer_calls`
  emits a `drain-lag` mark for any item that waited past `DRAIN_LAG_MS` (300).  `.c` only, so it
   cannot reach a snap; the `world` printer is generic, so it renders with no CLI change.  The three
    counters are the fork — `calls` (answer_calls entries: did the `$effect` fire at all?), `gated`
     (…bounced off `answer_calls_waiting`), `tries` (`_really_answer_calls` entries: did anything
      actually LOOK at the queue?), reported as deltas since the push.  Reading key is inline at the
       emit site.

**First live reading, and it refutes the leading hypothesis:**

     drain-lag  H=Mundo tag=think waited=567 calls=6 gated=5 tries=1 depth=3
                why=beliefs mutex held 0s by H:Mundo think

 **The `$effect` is NOT lost — it fired 6 times.**  What is lost is the drain: *5 of 6 wakeups
  bounced off the `answer_calls_waiting` throttle, and only ONE look at the queue happened in 567 ms*
   — against a 50 ms gate that should have allowed ~11.  So the suspect moves from "the Svelte wakeup
    never arrives" to **`answer_calls`'s own throttle swallowing its re-drives**, and `post_do`-goes-
     self-driving would NOT have fixed it (a self-drive lands on the same throttle).  Good thing the
      fork was read before the fix was applied.
 Caveat, stated so nobody over-reads one sample: this is `H:Mundo` on a **compile-busy tab with 0
  piers**, not a resident Sounditron boot.  It proves the electrode works and it rules one branch
   out; it is not yet the boot measurement.  **Next: a Sounditron boot with the electrode live** —
    read `calls`/`gated`/`tries` on the `fn:story_step` and `fn:story_snap` marks specifically.
 (The edit lands in a `.svelte.ts`, which has no HMR boundary — every live tab full-reloads.  Here
  that is convenient rather than costly: a fresh boot is exactly the thing being measured.)

### THE READING, off Righto reloading (2026-08-08) — and it is TWO bugs, not one

**A. The step clock: the queue is simply never looked at again.**  Every `H:Story` mark, every step:

     H=Story tag=fn:story_snap waited=3600 calls=2 gated=0 tries=2 depth=1 why=
     H=Story tag=fn:story_step waited=3600 calls=2 gated=0 tries=2 depth=1 why=
     H=Story tag=fn:story_snap waited=3712 calls=2 gated=0 tries=2 depth=1 why=

 `gated=0` acquits the `answer_calls_waiting` throttle.  Empty `why` acquits the mutex — nothing was
  blocking.  `calls=2` in 3600 ms against a 50 ms gate that allows ~72.  **Two looks, neither
   blocked, and the item still sat for a full ambient interval.**  With `depth=1` the picture is
    exact: look #1 drained the item AHEAD of ours and left ours standing; look #2 was the 3.6 s
     heartbeat.  Nothing in between.
 So the failure is the "come back for the rest" self-restart at `Housing.svelte.ts:1129-1130` —
  `// we should come back to the rest of them` / `this.todo_version++`.  It runs **synchronously
   inside the `$effect`'s own call stack** (`$effect` → `answer_calls` → `_really_answer_calls`, not
    awaited, and the bump precedes the first `await`), i.e. it is a write to the effect's own
     dependency from inside that effect — and the measurement says it does not reschedule anything.
      `gated=0` is the proof: had the effect re-run and bounced, `gated` would be ≥1.  It never ran.
 **The queue therefore advances one item per EXTERNAL wakeup**, and on a quiet resident boot the
  only reliable external wakeup is the 3.6 s tick.  Books escape it because a Book run is a constant
   rain of external wakeups (elvises, `ponder_now` off every disk settle) that keep poking the queue.
 **The fix is the shape already proven next door:** the mutex-held branch re-drives out-of-band
  (`setTimeout(() => this.answer_calls(), gate)`) and *that* path spins fine — see the contended
   Mundo marks below with `tries` in the thousands.  Do the same after a successful drain instead of
    trusting the reactive self-bump.  Not applied yet.

**B. AN 11-SECOND BELIEFS-MUTEX HOLD ON `H:Mundo` DURING BOOT — new, and not small:**

     H=Mundo tag=fn:handle_inbound waited=10529 calls=3439 gated=1721 tries=1718 why=beliefs mutex held 11s by H:Mundo fn:?
     H=Story tag=fn:story_step   waited=10698 calls=2222 gated=1110 tries=1112 why=beliefs mutex held 11s by H:Mundo fn:?
     H=Sounditron tag=think      waited=10744 calls=380  gated=190  tries=190  why=beliefs mutex held 11s by H:Mundo fn:?

 Three Houses, one holder, ~10.7 s each.  Note `tries` in the thousands here — the retry chain works
  perfectly when something drives it, which is exactly what makes (A)'s `tries=2` damning.
 **This is real work, and TimeSpool did NOT see it** — `collect_time_sample` sums
  `sum_beliefs_time` over the *Story Run's* steps only, so an 11 s cycle on Mundo by a non-Story fn
   is invisible to it.  Correct the "there is no work" claim above to: *no work in the steps*.
 **Prime suspect, already instrumented:** `Swarm.g:1809`'s untagged `post_do` around
  `Swarm_share_beat` — its own `beat` electrode logged **ms=5286, 2564, 1534** during exactly this
   boot window.  `fn:?` is the tell that the `post_do` carries no `see`, so the drain cannot name it.
    **DONE 2026-08-08 — every `post_do` in the tree now carries a `see`.**  Note for anyone auditing
     this the way I first did: **grepping the `post_do(` line is wrong** — the `extra` sits on the
      CLOSING line of a multi-line closure, so a line-grep reports a dozen false positives and hides
       the real ones.  Paren-match from `post_do(` to its close and test the tail.  Doing that over
        all 333 files of `src/ Ghost/ scripts/` found **10 genuinely untagged sites**, now tagged:
         `Swarm.g` (`swarm_share_beat` — the suspect), `Tribunal.g` ×2, `Peeroleum.g` ×2,
          `Peregrination.g` ×2, `Swarmation.g` ×2, `MachPeerily.svelte` (`keygen_<side>`).
           Five `.g` ghost-compiled, 5/5 ✓.
  **AND A TRAP WORTH THE TRIP: `src/lib/p2p/pinned_stable/{Peeroleum,Tribunal}.go`.**  A deliberately
   FROZEN copy of the spine, still untagged and left that way on purpose.  `Lies_transport_up`
    returns early on `role !== 'editor'`, so it is the **editor's bootstrap alone** — the editor
     cannot ride the spine it is editing.  Consequences to hold on to: a `.g` edit to
      Peeroleum/Tribunal **never reaches the editor's own channel** (promotion is a hand
       `cp gen/N/ → p2p/pinned_stable/`), and conversely a player tab is unaffected by it.
  **Why the tag did not appear immediately on Righto:** HMR swaps the module, not the live closure —
   the transport `port` object was built at boot from the pre-tag code, so the running `send`/
    `deliver_soon` are still the old ones.  **The holder names itself on the next reload**, not before.

### FIXED AND MEASURED 2026-08-08 — the drain now comes back for its own queue

One line at the tail of `_really_answer_calls`, after the mutex releases:

    if (this.todo.length) setTimeout(() => this.answer_calls(), this._gallop_gate_ms())

Before → after, both tabs, off the trace rings:

     to_step               3801 ms  →  200-213 ms   (200 is schedule()'s OWN setTimeout;
                                                      the queue latency is now ~0-13 ms)
     quiesce→snap-cost     3.64 s   →  0.02-0.11 s  (what is left IS the snap: 19-86 ms)
     step interval         7.8 s    →  ~0.48 s      (~16×)
     share-up              +30 s    →  +7.9 / +8.4 s

**The `~30 s sealed-but-deaf` window is now ~8 s.**  The `H:Story fn:story_step` / `fn:story_snap`
 drain-lag marks stopped emitting entirely — they no longer clear the 300 ms floor.

**WHAT REMAINS IS `swarm_share_beat`, AND IT NOW NAMES ITSELF** (the `see` tags landed):

     H=Mundo tag=fn:handle_inbound waited=5238 … why=beliefs mutex held 5s by H:Mundo fn:swarm_share_beat
     H=Story tag=think             waited=1750 … why=beliefs mutex held 5s by H:Mundo fn:swarm_share_beat

 Its own `beat` electrode agrees: single beats of **5189 ms and 7935 ms**.  That is the one step in
  each run that still costs 3.01 s / 2.04 s instead of 0.48 s — the whole residual.  `Swarm_share_beat`
   holding the beliefs mutex for 5-8 s is now the top item on this TODO, and unlike everything above
    it, it IS work: go read what the beat does per pass before assuming it is another wait.

**Do not "fix" this by shortening the 3.6 s interval.**  That is the thermostat, not the fault, and
 lowering it just makes a lost wakeup cheaper while leaving every other consumer of the ambient tick
  paying a faster clock.  The wakeup is the bug.

**Read the table right: the SNAP is 41 ms, not 3.64 s.**  `run.c.snap_t0` is stamped at the top of
 `snap_step` and `snap-cost` is `Date.now() - snap_t0` at the end, so the encode|compare|store is the
  `snap 0.04s` row.  The `quiesce→snap-cost 3.64s` row is the wait *before `snap_step` starts* — it
   brackets the `post_do`, not the snap.  The only two things standing between the `quiesce` mark and
    the `H.post_do(snap_step)` are `Run.c.on_step_ending` (MachPeerily:480 — clears an interval,
     drops two particles, synchronous) and `Run.c.runtime = false`.  Both free.  This misreading is
      worth guarding against because it points the fix at the encoder, which is innocent.

**`waitVyto` REMOVED from Sounditron's toc (2026-08-07, the human's call).**  It was the only toc
 carrying it, so this is scoped to the resident world and touches no other Book.  Be clear about
  what it buys: **60 ms of a 7800 ms step**, i.e. not the boot fix.  The instinct behind it was
   sound but one day stale — waitVyto genuinely WAS the villain until 2026-08-06, when the old
    `painted >= stir` chase was found never to converge against the resident glass (which grapples
     Stoker levels, Session counters and the Heist, all stirring every heartbeat) and every step
      took the full `CEIL_MS` 8000 ms.  Latching `target` on the first poll took it to 60 ms.
  **The reason to drop it anyway is structural, not arithmetic:** gating a world's step clock on a
   glass that never stops stirring is wrong even when it is cheap, and keeping it leaves an
    8 s-per-step cliff one regression away.  The follow-on the human named — *"some other process
     animating Vyto sensibly over the long run"* — is the right shape: the resident glass should be
      paced by its own clock (the wave/grawave timing Cyto already uses is the candidate), not by
       whether a Story step is willing to advance.  Not built; filed here so it is not lost.
