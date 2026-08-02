---
name: stream-continuation-starve-fix
description: "%Stream continuation starved at 32s on friend tracks — FIXED (non-blocking decode + lead pump). 2026-07-29b: the residual 'minute' PINNED — bin_read's per-chunk for-await slurp of a BIG file (66MB/15.8min track = 64s under want-storm congestion) → swapped to read_range native single-slice at 4 whole-file sites. Earlier Book measured a SMALL 78s file (~160ms read) so missed it. MusuRaStream fixtures 13-40 drifted post-lead-pass (re-record owed)."
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**2026-07-29b — THE RESIDUAL PINNED (live `world` on the human's heisting tab 56fbce).** The earlier
 "decode is fast (~350ms), suspect the wire" measured a SMALL 78s LOCAL Book track. The LIVE dump is a
  **947s / 66MB track with `pcm-read = 64257ms`** — sixty-four seconds in `nav.bin_read`, which slurps the
   whole file via `for await (chunk of reader.iterate())` (~1000 chunks); under the repli_want-storm the event
    loop is congested so each await drags → a **feedback loop** (want-storm → slow read → %Stream late → starve
     at seq=16 → re-ask → more want-storm). `wire=1` in the starve trace is just a BOOLEAN (`rec.c.from ? 1 : 0`
      = "remote track"), NOT a window. **FIX:** swap `bin_read` → `read_range(dir, fname, 0)` (len-omitted =
       whole file, ONE native `file.slice().arrayBuffer()` — no per-chunk loop; read_range is the nav-contract
        big-asset primitive, already used by Ra_stock_peek, fallback kept) at the FOUR whole-file source reads:
         `Ra_source_pcm` (Ra.g ~1333, the streaming transcode) · `Ra_stock_one` (Ra.g ~1072, ingest) ·
          `Heist` read-back-verify (Heist.g ~493, EVERY landed track) · `Heist` materialise-meta (Heist.g ~903).
           Ra.go/Heist.go compiled (LocalGen). BEHAVIOR-identical (same bytes), fallback to bin_read. **NOT yet
            live-verified** — needs the human's tab RELOADED (perf is congestion+file-size-dependent, un-repro
             headless). Follow-ups: whole-track `decodeAudioData` still ~7.5s/track on the 947s track (secondary
              to the 64s read); the census read Heist.g:107 is the same class (left, verify hot first); want-storm
               intensity for a whole-COLLECTION heist (B=6/LEAD=32 per rec × many recs) may still need a global cap.

**2026-07-29 — SOURCE-SIDE INSTRUMENTED + a first live measurement (reframes the whole problem).**
Added `Radio_trace` marks to the friend-serve producer path (which had NONE — `Radio_supply_go` returns early
 for `rec.c.from`, so the pump/decode/advance ran untraced): `pcm-decode-start` (want arrived, decode kicked) →
  `pcm-read` (bin_read ms+bytes) → `pcm-decode-done` (**decode ms** + track secs + samples) → `stream-first-chunk`
   (seq 16 minted). All push to `M.c.supply_trace` (`.c`, **never snapped** → can't drift a fixture) and are
    co-resident-safe (`this.Radio_trace` resolves in Ra.g — M-cluster ghosts share the House, proven by
     Radio.g↔Ra.g cross-calls). The `world` op prints them with inter-event Δ. Ra.go @2db4814, Radio.go @a9d763c5.
**Measured live** (MusuRaStream on ★claude, reloaded fresh gen): want→first-stream-chunk ≈ **334–415ms** (read
 ~160–186ms, decodeAudioData ~157–206ms for a ~78s track, first-chunk ~17–23ms). **The source decode+transcode
  is FAST — not the minute.** So the live "gets stuck / takes a minute" on real Sounditrons is NOT the source
   producer; prime suspects now: (a) the **WIRE** — friend is across the relay (want→park→serve→deliver round-
    trips), the Book source was LOCAL; (b) **Vyto mutex-contention** — the live glass tessellates under the
     beliefs mutex, starving the pump (the re-commission churn-cut this session targets exactly this). NEXT live
      diagnosis: `world --runner=<source>` and read the new marks — if start→first-chunk is fast there too, the
       loss is on the wire (chase `ra_wanted`/park/serve timing + `Swarm_share_present` liveness gate), not the CPU.
**Aside:** MusuRaStream steps 13–40 go RED (`error:null` — snap DIFF, not a throw; machinery healthy in the snap:
 `parked_want from_idx:16/18`, repli_want acked). Cause is fixture DRIFT — the lead pass produces MORE %Stream
  chunks ahead per step than the pre-fix fixtures recorded. Streaming is fine; the FIXTURES lag. Re-record owed
   on a live runner (confirm with the human first — [[force-clean-rerecord]], [[entropy-samples-fuzzok]]). Steps 1–12 green.


**Symptom (live, `world`-snapped on the listener):** a FRIEND track plays its 16-chunk preview (~32s) then
 STARVES at seq 16 — the first CONTINUATION chunk — and mostly never recovers (one track crawled to 28, one
  oscillated starve/unstarve). `total=95 preview=16 wire=1`, so the range exists; the SOURCE's on-demand
   %Stream transcode just wasn't producing in time. NOT the heist census (reproduced with no heist) — a
    separate, same-CLASS bug in the core streaming producer. The human: "the old one [prototype] did all this
     pretty good" — the prototype served PRE-ENCODED segments (no on-demand transcode-from-PCM), so never froze.

**The path:** friend track ⇒ `Radio_supply_go` returns early (Radio.g, `rec.c.from`); continuation comes from
 the listener's head+16 want (Swarm.g FULL-LENGTH leg, re-ask every 4s) → PARKS at the source → the source's
  `Ra_transcode_pump` (run on `Swarm_share_beat`, under the beliefs mutex) must transcode it.

**TWO root causes (both DEFINITE, a subagent + I agreed):**
1. **Whole-file decode on the beat mutex.** `Ra_transcode_ensure`→`Ra_source_pcm` (Ra.g) did `await
    bin_read(whole file) + await decodeAudioData(whole file) + a per-sample bake`, AWAITED under the beliefs
     mutex, COLD-STARTED at the seq-16 seam — seconds of freeze that starved the pump + inbound frame delivery
      ([[sigill-bin-read-nsquared]]/[[boot-20s-stoker-gate]] are the same class: seconds of sync work on the beat).
2. **Break-even production.** The pump advanced a rec only when a `%parked_want` was currently parked, and
    only `stride`(=2) chunks/advance, once/beat; the listener re-asks each offset every 4s ⇒ ~2 chunks/4s =
     **0.5 chunks/s = the exact playback consume rate**. Zero margin — any hiccup starved it permanently.

**FIX (Ra.g, compiled, NOT committed):**
- `Ra_transcode_ensure`: **non-blocking decode** — kick `Ra_source_pcm` off DETACHED (`.then`, `rec.c.pcm_pending`
   latch stops the await-gap double-decode race), return null this beat, open the encoder a later beat once
    `rec.c.pcm` lands. NEVER await the whole-file decode under the beat mutex. Registers the rec in `w.c.ra_hot`.
- `Ra_transcode_pump`: **lead pass** — advance every open `w.c.ra_hot` transcode toward `LEAD`(=24) chunks past
   the SERVED frontier (`rec.c.sent`), capped `ra_lead_cap`(=6) advance-calls/beat so no beat runs long; frees
    the decoded pcm+encoder of tracks that finish or age past 4 hot recs. Then re-serve parked wants.
- Knobs: `w.c.ra_lead` / `w.c.ra_lead_cap`.

**VERIFY (two live BigSoundland/Sounditron tabs — an agent can't):** reload BOTH, play a friend track past 32s
 (should continue; source CPU near-idle), re-run `node scripts/runner_ask.mjs world --runner=<listener>` and
  confirm the seq-16 `starve` line is gone. Residual suspects if it persists: source can't re-read /music at
   continuation time (ensure-null swallowed — `rec.c.pcm_why` now stamps it), or a want dropped when the frame's
    pier ≠ the registered caster (Repli_src_for null). Source-side `%parked_want`/`rec.c.ra` only visible in a
     `world` snap of the SOURCE tab. See [[verify-via-live-runner]], [[radio-pipeline-opus]], [[musurastream-real-streaming]].
