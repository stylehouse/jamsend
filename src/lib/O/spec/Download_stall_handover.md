# Download stall — handover (2026-07-29)

Continuation brief for the p2p music **heist DOWNLOAD** not working. Fold into `Heist_todo.md` /
 `Radio_todo.md` once triaged; retire to `spec/history/` when the download is proven end-to-end.

## Destination

Two live BigSoundland/Sounditron tabs, mutually sealed (friends). One presses ⇊ on the other's
 album/collection → the tracks actually **pull over the wire and land on disk**. Today: "%Stream (live
  play) works, but DOWNLOADS DON'T HAPPEN" (the human) — the heist want-storms and never completes.

## The bomb (know this or you'll chase ghosts)

- **NOTHING this session is live-verified.** The whole class only shows up on **a busy networked system
   running for a few minutes** — which the test suite never does (that's *why* it slipped). Compile-green
    and headless Books CANNOT prove these fixes. The only proof is: reload BOTH tabs, run a real heist a
     few minutes, watch `node scripts/runner_ask.mjs world`.
- **`runner_ask`/`runner_shot` reach the HUMAN's LIVE tab** (RUNNER_URL → whichever tab is the runner;
   this session it was `56fbce`, earlier `77d26228`). **Do NOT `runner_ask run <Book>` on it** —
    `become_book` HIJACKS their session and kills the very heist you're watching. Diagnose with the
     read-only `world` op; never drive a Book on a human tab.
- **Both tabs need the gen reload.** The slow read is on the SOURCE side (the tab that HAS the music and
   serves it); each tab is both source (serves the friend) and sink (pulls). A fix only lands per-tab on
    hard reload; a wedged/stale tab shows the OLD behaviour ([[hmr-socket-dead-tell]]).
- **The two `toc.snap`s in the working tree are the live tab's own churn, NOT edits** — leave them.
- **The host commits mid-session** (this session: `6e93bab9 "telling it to get it together!"` swept the
   earlier elvis/AREA_BASE/Cyto work into history). Re-check HEAD before assuming your diff is the tree.

## The arc — what was wrong, and the fixes (ALL uncommitted, compiled via LocalGen)

1. **Source can't feed the wire.** Remote tracks starve at `seq=16` (the preview boundary): the source's
    on-demand `%Stream` transcode couldn't produce in time. Cause: `Ra_source_pcm` read the whole 66MB
     source via `bin_read`'s per-chunk `for await` loop — **64s** under want-storm congestion (a feedback
      loop: storm congests the loop → slow read → late %Stream → starve → re-ask → storm). **FIX:**
       `bin_read` → `read_range(dir,f,0)` (one native `file.slice().arrayBuffer()`) at 4 whole-file reads:
        `Ra_source_pcm`, `Ra_stock_one` (Ra.g), Heist read-back-verify + materialise-meta (Heist.g).
         (`wire=1` in the starve trace is a BOOLEAN "remote", not a window — red herring.) See
          [[stream-continuation-starve-fix]].
2. **`SHARE BEAT THREW — giant stuff` (index 'z' 6011 LIVE rows).** The Pier `%outbox` booked one `%emit`
    per sent frame, culled only on ack; in the live app nothing culled them (no Story-step reset) and a
     stalled peer never acks → unbounded LIVE growth → the beat dies → downloads stop. **FIX (3 layers):**
      (a) `repli_want` made **ephemeral** in Peeroleum_send — no emit booked, no log (the pull re-asks
       every 4s at the app layer, so transport retransmit is dead weight); (b) on ack, `box.drop(emit)`
        so acked emits leave the outbox; (c) **general** `drop()`-count → `compact()` at 500 in
         Stuff.svelte.ts (`DROP_COMPACT_AT`) — sync, transaction-free, re-indexes live children via `i()`
          (NOT `replace()`, which throws "nested replace" inside a do_fn). A 6000-spike is now structurally
           impossible for any drop-churned C. See [[drop-leaves-index-giant-stuff]].
3. **~3000 log lines/min** drowned the console. `repli_want` gated out of Peeroleum_send + Tribunal `ws
    SEND`/`ws RECV` (data REPLIES still log, so you can still see downloads landing).
4. **Also landed (tangential):** `feebly_i_elvisto` → `vaguely_ponder` — a non-throwing optional cross-ghost
    poke (`_target_present()` predicate; `_house_of` guts shared with the still-fatal `_find_house`). Fixes
     the "no House has A:Cyto" wedge (was an unhandled rejection that paused the tab under pause-on-exceptions).

## The next move

1. **Live-verify #1+#2** (the whole point): reload both tabs, start a heist, run a few minutes.
    - `runner_ask world` → `pcm-read` ms should fall from ~64s toward ~1s; `seq=16 starve` gone.
    - console quiet; no `SHARE BEAT THREW`.
    - the heist should actually advance (tracks land). If it still stalls with a QUIET console, THAT is
       the real remaining bug — now visible.
2. **If it still stalls:** the source-side producer timing is next — is `Ra_pull_beat`/`Repli_serve_want`
    parking wants the transcode frontier never reaches? `world --runner=<source-tab>` and read the marks.
3. **Residuals (not blockers):** whole-track `decodeAudioData` still ~7.5s/track (secondary to the read);
    `Heist.g:107` census read is the same `read_range` class (left — verify it's hot first); a whole-
     COLLECTION heist fans `B=6 × many recs` of wants — may need a global want cap.
4. **Watch the core change.** `Stuff.drop()`→`compact()` touches EVERY C. It only fires at 500 drops (rare
    outside the outbox) so existing Books are untouched, but any weird index/query regression → suspect it first.

## 2026-07-29 pm — the cursor instrumentation (uncommitted, compiled)

The stall reproduces exactly as predicted: `Keep,state:pulling,asks=46,landed_n=0,total_n=13` — **46 asks, ZERO
 landed**, quiet console. Not "slow", **nothing coming back**. World marks still show `pcm-read ms≈23.7s` and
  `starve` at 113s, and the pulse seq to the source jumps ~500 per heartbeat = ~500 ephemeral `repli_want`
   frames/beat still flooding the wire.

**The silent death (root of landed_n=0):** `Repli_serve_want` (Repli.g) `return`ed with NO trace on two misses —
 `!lib` (no serve source) and `!rec` (`Repli_find_record` found nothing for the wanted id). The heist pull wants
  chunks under the **keep-id** (`rec.sc.id`, e.g. `c241769d`); the source must have `Heist_materialise_one`'d the
   original under that same keep-id into a `RummageLib` (`Repli_find_record` searches `w.c.rummage_libs` first).
    If that record isn't there (never materialised / wrong id-space / page-not-ready-forever), the want vanishes
     silently and the asker re-asks every 4s forever. The serve-lib sweep is NOT it here (count-swept at 8 libs,
      one album = one lib).

**What I added — the Repli cursor (the human's ask, "higher level cursor moving info"):**
- **Source tab** (holds the bytes): `Repli_serve_miss` — `◈✗ serve want id=… ← from — <why>` (throttled ~once/5s
   per id). This is the tell that was missing: it names WHY a want can't be served. Watch the FRIEND's console.
- **Asker tab** (pulling): in `Ra_pull_beat`, `◈ pull <title> H/T` when the held frontier ACTUALLY advances, and
   `◈… <title> stuck H/T — asked +N, nothing landing` when asking but held is frozen >8s. Progress- or 8s-gated,
    so it never joins the want radiation.

**Noise gated (the "ambient radiation"):** `noisy()` in Tribunal now filters `pulse`/`swarm_hi`/`advertise` AND
 the data frames `repli_page`/`repli_lines` (one line per 32KB chunk was the worst flood), plus Peeroleum_send's
  per-frame `(transport live)` line — all behind a live `w.c.wire_verbose` toggle (set it truthy in console to
   un-gate everything for deep wire debugging). In their place: **`Repli_meter`** coalesces page/lines traffic
    into ONE rollup per ~1.5s of activity — `◈ Repli  rx Np/KB  tx Np/KB  KB/s` — the "cursor is turning, this
     fast" line, both directions, silent when nothing flows.
  **BEHAVIOUR CHANGE to bless:** `pulse` is now **ephemeral** in `Peeroleum_send` (like advertise/swarm_hi) — it
   was booking a reliability `%emit` per heartbeat, culled only on ack: the SAME unbounded-`%outbox` hazard the
    handover fixed for `repli_want`, still live for presence. Ephemeral = no emit, no per-send log; still sent +
     still stamps `heard_at`. If you want log-only (no reliability change), revert that one line in Peeroleum.g.

**Next move:** hard-reload BOTH tabs (gen is stale until then — [[hmr-socket-dead-tell]]), start a heist, watch
 both consoles. Either the asker logs `◈ pull … advancing` (cursor moves — then it's the wire being slow, chase
  the read/congestion) or it logs `◈… stuck` while the source logs `◈✗ serve want … <why>` (the id-space/serve
   handshake — the reason is now printed). That reason is the remaining bug, finally visible.

_(Parked: the human's other thread — heist UI "turns up sluggishly" after the ✓ — is a KeepFace/HeistSetup mount
  timing thing, separate from the download stall; reactivity_docs is the lens. Not chased this pass.)_

## 2026-07-29 evening — THE BREAKTHROUGH: downloads work; the source was crashing

Two consoles finally read together (sink + source) proved the stall is **one bug wearing two faces**, and
 the download machinery itself is **sound**:

- **Sink (downloader) console:** the pull VISIBLY CLIMBS — `◈ pull He Lays in the Reins 2/95 … 64/95`,
   `Prison on Route 41 29/94`, `A History of Lovers 12/84`, `◈ Repli rx … 1714KB/s`, 2.8MB landing. The
    read_range + earlier ephemeral fixes cracked the throughput. Bytes flow and land. Then every track
     FREEZES mid-download (64/95, 29/94, 12/84) and `rx` falls to 0 — the wire goes silent **from the far end**.
- **Source (uploader) console:** dies with `giant stuff: index 'z' reached 6036 LIVE rows` thrown inside
   `Swarm_deliver` for **`type:'ive_got'`**. The Pier `%outbox` books one reliability `%emit` per boast,
    culled only on ack; against a busy peer that never acks the gossip it climbed to 6036 and threw → the
     deliver pump died → the source stopped answering `repli_want`s → **every download plateaued mid-track.**

So the sink was never the problem. `ive_got` (Swarm_gossip_music's shelf boast) is the **THIRD**
 unbounded-`%outbox` culprit after `repli_want` and `pulse` — same law ("gossip never opens a door",
  re-boasts every beat), simply missed in the earlier sweep.

**FIX (landed + compiled, uncommitted):**
- `Peeroleum.g` ~L447: `ephemeral = ephemeral || h.type === 'ive_got'` — the boast no longer books an emit.
   This is the load-bearing half of the download fix: the source stops crashing → keeps serving → the pull
    (already proven to work) runs to completion. Takes effect on the **next tab reload** (gen is stale until
     then — [[hmr-socket-dead-tell]]).
- `Ra.g` ~L1757: the `◈…` stall line now gates on `held > 0` (was `sent > 0`) + 12s — a whole-collection
   heist leaves ~12 records queued at `0/N` waiting their turn on a roughly-serial source, and one
    `stuck 0/N` line per queued record per beat was itself a flood. Only a **mid-track plateau** (started
     then froze) is the real tell now, and it renamed to `stalled`.

**Parallel hardening dispatched (3 background subagents, disjoint files):**
1. **Reliability layer** (Peeroleum/Swarm/Reliable/Stuff): audit + classify every frame type reliable-vs-
    ephemeral (incl. `suggest`/`suggest_got`); a SAFE high-watermark outbox backstop (drop-oldest + one warn
     above ~2000, invisible in normal op) so the giant-stuff cliff is structurally unreachable; throttle the
      `deliver threw` + `reused-seq collision` cascades to ≤1/s. Told NOT to revert the ephemeral block.
2. **Heist front-of-house** (ui/*Face.svelte + Radio.g Keep lifecycle): the cell not popping up (regression
    from the skeleton pass), the setup FORM being skipped (`state:primed,defaulted` jumps straight to
     downloading), and track-skip cross-wiring the Keep into the downloading view. Plus investigate
      persist/resume-on-reload of a kicked-off `%Keep`.
3. **Snap depth limit** (Text.svelte): make the silent `max_child_depth` cut LOUD (the human's alarm), after
    verifying the real blast radius — is any RECORDED fixture actually capped, or only the ephemeral Lies
     `world_snap` debug view? Honest TODO either way (`spec/Snap_depth_todo.md`).

**Next move when the tabs come back up:** watch a heist run a few minutes. Expected: no `giant stuff` on the
 source; the source keeps serving; the tracks that froze at 64/95 etc. run to `✓`. If a track still plateaus
  with the source NOT crashing, the next suspect is roughly-serial serving / want-budget arbitration (the
   `heist_want_budget` B=6 / `heist_want_lead` 32 window), and stream-vs-heist priority — the human's
    confirmed lever, to build once convergence holds.

### Landed since the breakthrough (subagent results + both-ends telemetry) — all compile-green, uncommitted

- **Reliability hardening (subagent):** `no_protocol` made ephemeral too — it booked a **seq-less
   `{emit:undefined}`** row nothing can ack/cull, an extra slow leak on top of `ive_got`. A high-watermark
    **outbox backstop** (drop-oldest + one throttled warn at ≥2000 live emits; healthy is single digits) makes
     the giant-stuff cliff structurally unreachable for ANY frame type. The `reused-seq collision` +
      `deliver threw` floods now throttle to ≤1/s. `suggest`/`suggest_got` deliberately KEPT reliable
       (bounded store-and-forward ≤24/friend, not per-beat). Flagged-not-fixed: the live station arms **no
        retx sweep** (`Peeroleum_arm_whittle` is Book-only) — the deeper reason un-acked emits are culled by
         nothing but the backstop; a lightweight periodic sweep on `w:Swarm` is the real fix, left as a
          recommendation (it touches hot-path wall-clock scheduling — higher risk than the additive guard).
- **Snap depth (subagent):** the ONLY snap/world cap — the Lies `world_snap` `max_child_depth:6`
   (`LiesFunk.svelte`) — is **REMOVED**; `runner_ask world` now reaches the deep Keep after a reload.
    **Recorded fixtures were NEVER capped** (verified: `encode_toc_snap` is infinite-depth; numbered
     `got_snap` uses a non-`enWaft` `Selection.process` encoder the cap can't reach) → **no re-record.** The
      one remaining `depth:0` (LangHold `Seem_toString`) turned out load-bearing for Lang's `dirty`/push-state
       detection (uncapping would spuriously mark clean docs dirty) — kept + flagged. Full write-up:
        `spec/Snap_depth_todo.md`. The human wants the full Story suite run once on a live runner to confirm
         empirically — HELD until a runner is free (become_book would hijack the heist; a run also re-records).
- **Both-ends heist telemetry (main):** sink cursor `heist-open` / `heist-done` / `heist-stall` (Ra.g pull
   beat), source cursor `heist-serve [id] n/of → friend` (Repli.g `Repli_serve_chunks`) — all on the same
    capped `supply_trace` ring the stream marks use, gated to real progress + throttled, so `runner_ask world`
     reports download convergence at a glance WITHOUT deep-tree reading (the Keep sits below the snap's reach).

### Verify recipe (after a reload picks up the gen — the timer cycles ~10 min)
`runner_ask world` on either tab, read the supply marks:
- `heist-done [id] of=N` — one per COMPLETED track; **13 done = the album fully landed** (the convergence win).
- `heist-serve [id] n/of → friend` — the source is feeding (the uploader cursor).
- `heist-stall [id] at/of` — a track started then FROZE; with `ive_got` ephemeral + the outbox backstop this
   should be extinct. If it still appears with a quiet source console, the next suspect is want-budget
    arbitration / roughly-serial serving (`heist_want_budget` B=6 / `heist_want_lead` 32) + stream-priority.
- the now-deep `MusuSelf/shop/Keep` subtree (world snap uncapped by the depth-cap removal).
Gold standard remains a live watch of both consoles: no `giant stuff`, tracks reach `✓`.

### Evening cont. — live pulse, a correction, heist-UI landed

**Live evidence the crash fix holds.** `runner_ask world` (read-only) on 56fbce shows the source **alive and
 serving continuously** — no `giant stuff`, the deliver pump survives. The `ive_got` ephemeral fix is doing
  its job: the source no longer dies mid-serve. (Full heist COMPLETION still unconfirmed — see correction.)

**CORRECTION — my first `heist-serve` read was a misdiagnosis.** The marks I saw (`heist-serve [0df43bb9]
 n=…/474 to=77d26228`, advancing 2 per ~4s) were NOT a heist — `0df43bb9` is the **live-stream** track
  (it's the one in the `pcm-decode`/`pcm-read` marks, a 15.8-min / 947s track, `of=474`). `Repli_serve_chunks`
   serves BOTH heist `%Original`/`%Lossy` AND on-demand `%Stream`/`%Preview` opus, and my mark labelled the
    stream serve "heist-serve". The 2/4s was the **opus transcode rate** for that long track's live cast
     (a known, separate slowness — [[stream-continuation-starve-fix]] notes decode is ~350ms for normal
      tracks; 8.7s here is the 15-min outlier), NOT a heist-download bottleneck. **Fixed:** the `heist-serve`
       mark now gates on `Heist_body_at(rec, from) != null` (Repli.g) so only real heist bodies mark. So there
        is **no evidence of a heist throughput problem** — I nearly blind-tuned the pull for a phantom. The
         true heist rate will only show once a real heist runs with the gated marks (`Ra_pull_beat` is
          heist-only, so `heist-open/done/stall` were always clean).

**Heist-UI subagent landed (Heist.g / Radio.g / Sounditron.g / KeepFace / KeepBarFace):**
- **Cell pop-up:** `feebly_ponder` wakes the belief loop but not the glass — the cell waited for the 2.5s
   trickle. New `Radio_pop_glass()` re-commissions the glass on the ⇊ gesture (via a stashed Run-House handle
    for the correct `this`), idempotent beside the trickle.
- **Form skip + track-skip→downloading (one root):** `Heist_keep_step` auto-flipped `primed→pulling` the
   instant the seed stopped playing. Removed; `primed→pulling` is now **user-confirmed only** via
    `Heist_keep_start` (▶). Track-skip fully decoupled. Copy fixed in the faces + the RadioFace ⇊ tooltip.
- **Persistence/resume — diagnosed, NOT built (the next feature):** the `%Keep` is snap-clean and the resume
   DRIVER (`Heist_keep_beat` → re-materialise + re-pull un-landed picks) is correct. The gap is upstream: the
    resident `/BigSoundland` tab **rebuilds its world C-tree FRESH each boot** (`Sounditron_setup` re-`i()`s
     the organs, re-digs shelves) — only the FSA dir handle + identity/friendship (`.jamsend`) restore, so
      `MusuSelf/shop` and its `%Keep` are simply gone on reload; there's nothing to resume. **Implementation
       sketch (for a verified session — do NOT blind-build, it touches the `.jamsend` ledger that holds
        identity/friendship):** persist the `shop` subtree to `.jamsend` on Keep mint/step, and reload it in
         `Sounditron_setup`. Left for the human/next session because it's unverifiable while out and a wrong
          `.jamsend` write risks the identity ledger. NOTE: not on the critical path — a heist completes inside
           one ~10-min reload window now that the crash is gone (the pull was fast; only the crash stopped it).

## Verify rails (never headless — [[verify-via-live-runner]])
`node scripts/runner_ask.mjs world` (supply pipeline marks) · `ping` (role/self) · `runner_shot --svg`.
 LocalGen for browser-less compile: `GFILES="Ghost/M/Ra.g …" node_modules/.bin/vitest run -c
  scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts`. `.svelte`/`.ts` edits: bundle-fetch
   `http://172.17.0.1:9091/<path>` and grep the transform for compile errors.

## Evening 2 — the un-ack root cause, and instrumentation-first (2026-07-29)

**The ive_got fix stopped the CRASH but the download still stalled at `landed_n=0`.** Two read-only agents
 traced it in parallel; they converged. The headline: **the download was unfixable BY GUESSING because every
  failure on the repli data path is SILENT.** Agent A: the ack fires ONLY on `req_unemit`'s success branch
   (`Peeroleum.g` ~707-712); the failure branch (~713) sets `req.sc.error` and **sends no ack, logs nothing**.
    `ok` is cleared by a `bad-body-hash` on a 256KB `repli_page`, a startup gate, OR an uncaught throw — and A
     found a real throw vector: `Repli_merge`'s delete path (`Repli.g:185`) does a `replace()` inside a do_fn →
      the "nested replace() transactions" throw ([[nested-replace-in-do-fn]]) → **permanent inbox wedge**. The
       *exact* current trigger **cannot be pinned from a snap — and that undiagnosability IS the finding.**
        Agent B: with **no live retx sweep** (`Peeroleum_arm_whittle` is Book-only), a "reliable" repli emit is
         retransmitted by NOTHING — it just piles the %outbox until the backstop drops REAL in-flight bytes.

**LANDED tonight (all `.g`, compiled to gen, working-tree only):**
- **Fix A — `repli_lines`/`repli_page` made EPHEMERAL** (`Peeroleum.g` ephemeral gate + the FRAME RELIABILITY
   POLICY comment moved them RELIABLE→EPHEMERAL). The pull self-heals (4s re-ask, frontier = bytes-present),
    delivery is idempotent (upsert-by-loc + stash-by-bufferid + cid gate), `rec.c.sent` advances at SEND time,
     nothing reads the emit's %acked. 5th instance of the proven pattern. **Removes the flood + backstop-drops-
      real-data.** COST: re-record SwarmShare (005-009) + MusuReco (005-011) — only vanishing source-outbox
       `emit,type:repli_lines` rows the Books don't gate on. (DEFERRED — needs a free live runner.)
- **Loud no-ack** (`Peeroleum.g` `req_unemit` error branch): shouts `🛰⚠ unemit NOT acked seq=… type=…
   — <reason>` (bad-body-hash names the len gap) — throttled, and QUIET on the designed `pre-Ud`/`startup-hold`
    hold. **This is the diagnostic unlock: the next reload TELLS us the real trigger instead of us guessing.**
- **L1 — sink-side heist watchdog** (`Heist.g` pulling branch): announces `⇊ heist STARTED — N tracks` and,
   if `landed` fails to advance for 15s, shouts `⇊⚠ heist NO PROGRESS 15s — 0/13 landed after N asks — the
    SOURCE may have crashed/gone`. Answers the human's "downloads stay 0/13, need more indicators." Per-KEEP
     (Ra's per-record stall warn is gated on held>0, which `landed_n=0` never trips).
- **A#4 no-Pier drop** (`Peeroleum.g` `if(!pier)`): a dropped frame — incl. a dropped ACK that strands an
   emit — now warns (throttled per type/from), was totally silent.
- **L2 transcode-throw** (`Radio.g:474`): the blanket `catch(er){}` on `Ra_transcode_advance` now warns +
   traces (`transcode-throw`) instead of an infinite quiet spin. Loud-only; give-up path unchanged.
- **A#5 consent-refused** (`Repli.g` `Repli_serve_want`): a revoked/wrong-peer grant now calls
   `Repli_serve_miss('consent refused …')` instead of a silent `return`.

**NOT built — deliberately (need a runner / touch core / touch the identity ledger):**
- **The Story ERROR CHANNEL** — the human's explicit ask, fully designed → `spec/Error_channel_todo.md`.
   Empty-in-health, UI'd, snap-gated, captures THROWS (not console — the Radios warn-flood would break
    "empty in health"). Its `req_unemit` wrap also FIXES agent A's latent inbox-wedge (A#1/#3). Spec-worthy
     after the human preens it. BUILD it next (6 files + a proof Book; bundle-verifiable, Book needs a runner).
- **Re-record SwarmShare + MusuReco** (Fix A fixture churn) — live runner only.
- **L3 parked-want age watchdog** (`Repli_park_want`/`Ra_transcode_pump`) — source-side twin of L1.
- **A#3 recv-wrapper honesty** (`Repli.g:689-691` `return true` → return the verdict) — behavioural, do it WITH
   the `req_unemit` wrap under the channel work, verified.

**NEXT MOVE:** on the next reload, WATCH BOTH consoles for `🛰⚠ unemit NOT acked …<reason>` and `⇊⚠ heist NO
 PROGRESS …`. The reason names the true trigger (bad-body-hash → 256KB frames corrupting/oversized over the
  relay, a DIFFERENT fix than the flood; startup-hold/not-them → a routing/consent bug; a throw → the wedge).
   THEN fix that specific trigger. Do NOT declare the download fixed until a heist reaches `✓` on a live tab.

## Evening 3 — the download WORKS; the remaining wall is source-side sha256 CPU (2026-07-29)

**LIVE CONFIRMATION.** After the reload the pull climbs for real: `◈ pull He Lays in the Reins 2→48/95`,
 `Prison 1→36/94`, `A History 3/84`, `rx 3132KB/s`. Every instrument fired: `⇊ heist STARTED — 13 tracks`,
  then the watchdog caught the genuine initial stall (`⇊⚠ heist NO PROGRESS 26s — 0/13 landed after 30 asks`)
   which cleared the instant the editor-reborn reset the stream, then the pull took off. `🛰⚠ deliver: no Pier
    for … DROPPED` and `🛰⚠ unemit NOT acked … not-them` (the unvouched ive_got rebuff — benign) also fired.
     Fix A + the loud net WORK. So the download is no longer stuck; the wall now is THROUGHPUT.

**The wall = source-side pure-JS sha256 (the human's uploader perf trace).** `Heist_materialise_one` was
 **51.8% of the frame (5.5s)**, ~all in noble's pure-JS sha256 — a synchronous freeze per file that stalls
  the belief loop so the source can't serve (the 26s the watchdog caught). Root: `Hashly.ts` was deliberately
   switched noble-sync (no await, no re-materialize) but pure-JS SHA-256 is ~10-50× slower than native.

**LANDED (native hashing, byte-identical — safe for the wire protocol):**
- `src/lib/O/Hashly.ts`: new `async sha256_hex_fast(bytes)` — native `crypto.subtle` (already proven in
   Peeroleum/Ra), noble-sync fallback, `bytesToHex` so output is byte-for-byte the sync path (cids/body_hashes
    keep matching). The SYNC `sha256_hex` stays for the many non-awaiting small-input callers.
- `Heist_materialise_one` (`Heist.g`): per-chunk cid → `await sha256_hex_fast(slice)`; the noble streaming
   `sha256_incremental` wire digest → ONE `await sha256_hex_fast(bytes)` over the whole file (the slices tile
    `bytes` exactly, so sha256(concat) === sha256(bytes)). Compiled; gen verified. Expect ~5.5s → ~0.1-0.3s.

**FLAGGED, not fixed (needs its own care / the human):**
- **`hashC` / the C-tree dige re-hashes `sc.buf` (~2.6s in the trace).** `Heist_body_new` stores chunk bytes
   in `.sc.buf` (260KB × 95 = 24MB); the content-dige (change-detection) hashes them via noble on every
    dige/version over the materialised record — a recurring source freeze. PROPOSED FIX (dige-core, prove in
     isolation): when a chunk carries a `cid`, feed the CID (64 chars) to the dige instead of re-hashing the
      raw `buf` — the cid already IS the content hash, so change-detection stays correct at ~0 cost. Do NOT
       blind-touch the dige core ([[perf-cliffs-latent]]).
- **Landing incremental digest** (`Heist.g` ~446, sink side) stays noble streaming (a deliberate RAM
   tradeoff — native subtle has no streaming API). Less critical (sink, overlapped with disk I/O); revisit if
    the SINK profiles hot.

**NEXT:** re-profile the source after reload — materialise should be gone from the top. If throughput is still
 gated, the `hashC`-over-`buf` dige cliff is next. Download completion to `✓` still the only real gate.

## Evening 4 — HANDOFF: the download's real wall is PARALLEL PULL + source over-holding memory (2026-07-29)

**(Superseded by Evening 5's VERIFIED plan — start there. The diagnosis below stands; the fix sketch below
 was refined after a read of every load-bearing joint found four traps in it.)**

**Symptom (both consoles, live):** the pull climbs across MANY tracks at once — `◈ pull He Lays 55/95`,
 `Prison 27/94`, `A History 24/84`, `Red Dust 30/79`, `Sixteen 32/113`, `Burn 24/116`, `Dead Man's 24/69`,
  `He Lays (stripped) 6/128` — ALL in flight together, yet **`⇊⚠ heist NO PROGRESS 110s — 0/13 landed`**.
   Nothing ever completes. Tells: `◈✗ land page bufferid=NNN — no awaiter (lines/page mismatch); bytes
    dropped` (orphan pages thrown away) and `🛰 ws CLOSE code=1006` in a tight reconnect storm. And the human:
     **"uploader is taking 3g memory."**

**ROOT (the human nailed it): the heist pulls EVERY track in PARALLEL and the SOURCE holds ALL the music.**
- `Heist_keep_step` pulling branch (`Heist.g` ~1192) loops over ALL `Pick`s every beat and calls
   `Ra_pull_beat` for each → all 13 tracks pull concurrently.
- Each asked track makes the SOURCE `Heist_materialise_one` it, holding every chunk's bytes in `b.sc.buf`
   (~25MB/track). 13 in flight → ~325MB raw × serve-copies (`bytes.slice`, `Repli_pack_chunks`, frames) →
    **3GB on the source**. That is "holding more than a reasonable amount of the music" — the human's "that's
     wrong."
- 3GB → GC thrash → ws ping timeout → `1006` reconnect storm → line/page frames split across reconnects →
   the page lands with `no awaiter` → bytes dropped → chunk never fills → **`landed_n` stuck at 0 forever**.
- RULED OUT as the 3GB source: the Tribunal ws send-buffer — it is ALREADY bounded (`Tribunal.g` ~124-128:
   noisy/data frames are DROPPED while the socket is down; real frames cap at `pending.length > 200`). So the
    memory is the materialised bufs, not the socket buffer.

**THE FIX (for the fresh session — this is the next build):**
1. **Serialize the heist to ~1 track at a time** with a SMALL overlap (the human 2026-07-29: "we could
    overlap them a little bit but only for a few seconds, to beat a latency between speedy downloads where we
     ask for another while nothing is coming"). i.e. pull track N to near-done, and a few seconds before it
      finishes pre-ask N+1 so there is no dead gap — cap in-flight at ~1-2 tracks, NOT all 13. This is in the
       `Heist_keep_step` pulling loop: gate how many un-landed picks call `Ra_pull_beat` per beat.
2. **RELEASE a track's bytes after it lands** on BOTH ends: the source should drop a materialised rec's
    `%Body`/`buf` (and eventually its rummage lib) once the sink has the whole record, so source memory stays
     bounded to the ~1-2 in-flight tracks. Today `rummage_libs` caps at 8 libs and never releases per-track
      bytes → the hold grows. (`Heist_register_serve_lib` / the `Heist_keep_beat` sweep is where a lib
       detaches; make it byte-releasing + tied to landing, not just count-capped.)
3. **Orphan-page robustness (secondary):** `Repli_recv_page` stashes by `pier.c.bufs[id]`, yet `◈✗ … no
    awaiter … bytes dropped` (`Repli.g` ~460) still fires under ws churn — a page arrives, its line was lost
     on a reconnect, and the stash isn't catching it. Once memory is bounded and the ws stabilises this should
      largely clear, but consider HOLDING an unmatched page briefly (it may pair when the re-asked line
       arrives) instead of dropping immediately. Confirm whether the 1006 storm is purely memory-driven (GC)
        or also a relay-side limit.

**Instrumentation that PROVED all this (landed this session — keep it):** `⇊ heist STARTED`, `⇊⚠ heist NO
 PROGRESS Ns` (per-Keep, caught the 110s no-land), `Ra` per-record `◈… stalled X/Y`, `◈✗ land page … no
  awaiter`, `🛰⚠ unemit NOT acked`, `🛰⚠ deliver: no Pier`. The loud net did its job — the bug is now VISIBLE.

**Also landed this session (working tree, uncommitted, compiled — see Evenings 2-3):** Fix A (repli data
 ephemeral), loud no-ack, L1 watchdog, A#4/L2/A#5 loud-fails, NATIVE materialise hashing (`sha256_hex_fast` —
  the 5.5s CPU cliff → ~0.2s), and the LIVE FLOW DIAL **wire side** (`keep.c.flow` 0-100 off `w.c.repli_rx_total`,
   0.3s-throttled, no-bump/no-snap — `Heist.g` pulling branch + `Repli_meter`); its DISPLAY render (a jiggling
    bar in `KeepBarFace` reading `keep.c.flow` on a ~300ms poll) is still OWED. Error channel DESIGNED →
     `spec/Error_channel_todo.md` (build it; its `req_unemit` wrap also fixes the latent inbox-wedge).

**Do NOT re-chase Evenings 1-3 (crash, un-ack, CPU) — those are landed. The ONE open wall is the memory:
 parallel-pull + source over-holding → serialize + release-after-land.**

## Evening 5 — THE THINK: the fix is now CERTAIN; four traps found by reading the joints (2026-07-29 late)

**⇒ FRESH SESSION: START HERE — this is Evening 4's fix sketch turned into a verified plan.** The diagnosis
 stands unchanged (parallel pull + source over-holding → 3GB → GC thrash → 1006 storm → orphan pages →
  `landed_n=0`). Every load-bearing joint of the fix was read in code before this was written; the four traps
   below are the difference between this plan and a new wedge.

### The four traps (know these or the fix bites)

1. **`Heist_has_body` counts PARTICLES, not bytes** (Heist.g:52) — and `Heist_materialise_one`'s idempotence
    gate is `Heist_has_body(rec) >= total` (Heist.g:909). Releasing bufs the `Heist_release_buf` way (delete
     the binary key, KEEP the husk particle — Heist.g:201) makes a later materialise return WITHOUT re-reading
      → the sink's wants park forever → permanent wedge. **Release must DROP the body particles**
       (`rec.drop(ch)` per %Original|%Lossy) — then has_body=0 and materialise honestly re-reads. drop() feeds
        the general compactor at 500, so ~95 drops/track is the proven path ([[drop-leaves-index-giant-stuff]]).
2. **Re-materialising over surviving particles would DUPLICATE seqs** — `Heist_body_new` is a bare `i()`
    (Heist.g:41-43), and `Heist_body_at`/`Repli_chunk_at` read `o()[0]` → the stale bufless twin would serve
     first → a chunk line with no binary. Same conclusion as trap 1: release = drop the particles, never
      just the bufs.
3. **The orphan-page warn LIES.** `Repli_recv_page` stashes `pier.c.bufs[id]` BEFORE reconciling
    (Repli.g:588-591), `Repli_open_awaitbuf` attaches from the stash when the lines arrive late (Repli.g:605),
     and the landed path CULLS the stash (Repli.g:655-656). So `bytes dropped` (Repli.g:614) is FALSE —
      page-before-lines already self-heals; the only true loss is lines-lost-forever, and the 4s re-ask heals
       that. Evening 4's "fix #3 hold the unmatched page briefly" is ALREADY the behaviour. Real residues:
        reword the warn + cap the stash (a genuinely orphaned id leaks its 256KB forever under a 1006 storm).
4. **The want-ask answer cap kills any SINK-side heal.** A re-sent materialise-ask upserts the SAME %Rummage
    (oai by want+pier — Heist.g:1020-1027) and the source's serve loop refuses it at `ask.c.answers >= 3`
     (Heist.g:1112-1113). So don't heal released-bytes-vs-late-want from the sink. Heal it SOURCE-side, where
      the demand already parks: a `%parked_want` (Repli.g:359) over a rummage-lib rec with total>0 but no
       bodies IS the re-materialise demand — exactly the transcode-pump producer pattern (Ra.g:1524/1557
        already un-park via `Repli_serve_parked`).

### THE BUILD (A — serialize + release + heal; all .g, LocalGen compile, uncommitted as ever)

**A1 — sink: an in-flight window in `Heist_keep_step`'s pulling loop (Heist.g:1196-1223).** Walk picks in
 order; DRIVE (want-ask | Ra_pull_beat | land — the existing per-pick body) only while a slot is open:
  slot 1 = the first un-landed pick; slot 2 opens ONLY when slot 1's rec is NEAR DONE
   (`total - held <= w.c.heist_overlap`, default ~24 chunks ≈ a few seconds at the observed rate — the
    human's "overlap a little, to beat a latency between speedy downloads"). A pick still waiting on
     materialise keeps the window at 1. Every other un-landed pick: `left++`, NO asks — that alone stops the
      source materialising 13 at once. Knobs: `w.c.heist_inflight` (2), `w.c.heist_overlap` (24).
 + **BENCH a wedged pick** so one bad file can't hold the album: driven but zero progress ~45s →
    `pick.c.bench_until = now+60s` + one warn, skip while benched; if a pass drives NOTHING and un-landed
     remain, clear the benches (never fully give up).
 + **Watchdog progress = landed OR Σheld advance** (keep.c) — a serialized big track lands slower than the
    15s bark, so the NO PROGRESS shout must count climbing chunks as progress, not only whole-track landings.

**A2 — source: release-after-serve in the `Heist_keep_beat` sweep (Heist.g:1084-1095).** Stamp
 `rec.c.want_ts = Date.now()` at serve (top of `Repli_serve_chunks`, Repli.g:502-505). Sweep each rummage
  lib's recs (`Ra_recs`): body particles present && `rec.c.sent >= total` (Repli.g:519 — every page crossed
   at least once; monotone, .c so a reload resets it conservative) && `now - want_ts > ~20s` → new
    `Heist_release_rec`: drop the body particles (traps 1+2; the rec HEAD keeps id/total/body_hash/path —
     the promise stands, the bytes go). One `heist-release` Radio_trace mark + a `◈↯ freed <title>` line.
      BELT: Σ sc.bytes over body-holding recs > `w.c.heist_hold_cap` (~256MB) → release oldest-served
       regardless (guards any future parallel regression; never hit in serialized health ≈ 50-75MB).

**A3 — source: the parked-want PRODUCER (the heal that makes A2 safe).** In the source's beat: for each
 pier's `%parked_want`, resolve its id in `w.c.rummage_libs`; a rec with total>0 but NO bodies → throttled
  (~5s per rec, ≤1 re-read per beat) `Heist_materialise_one` — whose idempotence gate now honestly fails
   after A2's particle-drop, so it re-reads the disk — then `Repli_serve_parked` (Repli.g:373). A late 4s
    re-ask ALSO just serves once the bufs are back; the parked path only makes it prompt.

**A4 — orphan hygiene (small):** reword the orphan warn (the bytes are STASHED and pair when the lines
 arrive — trap 3); cap `pier.c.bufs` (~64 entries, drop-oldest + one throttled warn). Do NOT touch Tribunal —
  the ws send buffer was ruled bounded (Evening 4); the 1006 storm should die with the memory.

### LANDED (2026-07-29 late — all .g, LocalGen compile-green, gen verified, UNCOMMITTED)
- **A1** `Heist.g` `Heist_keep_step` pulling branch: in-flight window (`heist_inflight`=2 / `heist_overlap`=24),
   per-pick bench (`bench_until`, 45s-frozen → 60s bench + warn; all-benched pass clears them), watchdog now
    counts Σheld advance (`pull_seen_held`, re-baselined on every progress incl. a landing — so a slow big
     track doesn't false-bark). A materialise-ask counts as `drove_any`.
- **A2** `Heist.g` `Heist_keep_beat` sweep: per-rec `Heist_release_rec` (new helper — DROPS the %Original/%Lossy
   body particles, not just bufs; traps 1+2) on `sent>=total` + `want_ts` idle 20s; 256MB byte-cap belt
    (oldest-served first); lib TTL widened 10→30min. `Repli.g` `Repli_serve_want` stamps `rec.c.want_ts`.
- **A3** `Ra.g` `Ra_transcode_pump`: intercepts a parked want over a released heist body (`body_hash` &&
   `has_body<total`) → throttled `Heist_materialise_one` (5s/rec) BEFORE `Ra_transcode_ensure`; `Repli_serve_parked`
    ships it. The heal that makes A2 safe.
- **A4** `Repli.g` `Repli_recv_page` caps `pier.c.bufs` (64, drop-oldest + real warn); `Repli_attach_page`'s
   false `bytes dropped` orphan warn reworded to a quiet page-before-lines return (the bytes were stashed).
- **No fixture churn** (verified in code, not assumed): MusuHeist drives `Heist_beat` (Heist.g:329), NOT the
   `Heist_keep_step` path A1 touches; RummageLibs are `dontSnap:1` so A2's body-drop never reaches a snap;
    `want_ts` is `.c`; `Repli_land_warn` is throttled console-only. So **no re-record expected from A1-A4** (the
     Fix-A `repli_lines`/`repli_page` re-record from Evening 2 is still separately owed).

### Verify (live only — [[verify-via-live-runner]]; re-watch, don't one-shot)
LocalGen compile + gen check; hard-reload BOTH tabs; run a whole-album heist a few minutes. Expect: uploader
 memory flat (~2 tracks held, `◈↯ freed` lines trailing the pull), no 1006 storm, `◈ pull` climbing ONE
  track at a time with the overlap handoff, `heist-done` ×13 in the world marks, every track `✓`. A benched
   track names itself. MusuHeist: CHECK whether the Book drives `Heist_keep_step` (keep.sc.asks is snapped)
    before assuming a re-record — `Heist_beat` (the Book's original loop, Heist.g:307-344) is untouched by A1.

### Then B — the Error channel (`spec/Error_channel_todo.md`, design complete, the human's explicit ask)
Build order in its ## 0; bundle-verifiable except the proof Book; its `req_unemit` wrap also fixes the
 latent inbox-wedge (agent A #1/#3). Independent of A — buildable while the heist soaks.

### Deferred (attended / needs a free runner)
Re-records (SwarmShare 005-009, MusuReco 005-011, +MusuHeist only if keep_step-driven); snap-depth
 full-suite confirm; KeepBarFace flow-bar render (display side); %Keep persist/resume (.jamsend —
  human-attended); `hashC`-over-buf dige cliff (prove in isolation); live retx sweep; stream-vs-heist
   priority arbitration (likely moot once serialized — measure first).
