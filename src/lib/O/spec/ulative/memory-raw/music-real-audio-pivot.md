---
name: music-real-audio-pivot
description: "Musu tests pivoting from cursor-arithmetic sims to REAL muted Web-Audio, real-time, browser-only, fanned across a parallelised runner fleet"
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

The cascade Musu Books (see [[music-cluster-kickoff]]) are **cursor-arithmetic simulations**
 of the Radiola spine, and an adversarial audit ([[adversarial-test-agent]]) confirmed the
  user's "this is fake" read: **MusuSignal = theatre** (the spine is replaceable by a one-line
   `decoded = delivered-1` and every witness still passes — "decode" is an int cursor, never a
    codec), **MusuSkip = tautology** (asserts auds `MusuSkip_seed` hand-created), **MusuWear**
     floor is real but play/idle columns never separated. Retransmission / ack-hole = ZERO
      coverage AND unbuildable (ack is a high-water int, no hole representation).

**The pivot (user 2026-06-29):** "I need reality involved! the browser should be playing
 audio — muted in the audio graph." Real Web Audio, **real-time**, **browser-only**, fanned
  across a **parallelised Lies%runner** so 50 slow tests run concurrently (slowness stops
   mattering). "how much more design?" → less than feared; the big objects already exist.

**The big objects (his past work) that already express it:**
 `Audiolet` (`Audio.svelte.ts:72`) already has TWO gain nodes `gainNode→gainNode2→AC.destination`
  (`:87-94`) → **mute = `gainNode2.gain=0`, real graph, silent**. `check_live_edge_delta`
   (`Radios.svelte:327`, throttles 0.8× within 3.141s of the broadcast cursor) = the real
    live-edge object. `radio_hear`/`listening`/`progress`/`enqueue` = the real read-ahead chain.
     Runner spine: Rungo/become_book, relay @channel claim/subscribe, `Storyrun` uid ledger,
      `awaiting_wave_done`/`awaiting_anim_done` (`Story.svelte:1630`) = real wall-clock pause-gates.

**The ONE missing object = `AnalyserNode`.** The app plays but never listens to itself (no
 analyser anywhere). A test that asserts "noisy, no gaps" IS an analyser tapped before the
  mute gain. Graph: `ctx → source → AnalyserNode(tap) → GainNode(0)(mute) → destination`.

**REUSE decision (user 2026-06-29):** "reuse Audio.svelte.ts that'd be grand; Records.svelte
 is more wanting to be converted; the new system won't have lib/ghost/ or lib/p2p/ unless
  PLUCKED." So: don't write a fresh graph — IMPORT `src/lib/p2p/ftp/Audio.svelte.ts`'s
   `SoundSystem`+`Audiolet` (the real voice). Confirmed by reading it: mute = `gainNode2.gain=0`
    (recorder already does `gainNode2.disconnect()` `// don't hear it` :137); `SoundSystem`
     stands alone (`M:Modus` declared but never deref'd, `new SoundSystem({})`+`.init()` works);
      ONLY missing object = AnalyserNode. ADDED `tap()`/`sample()`/`mute()`/`unmute()` to
       `Audiolet` (additive, :95). Audio.svelte.ts = pluck-candidate (drop the Modus import on
        pluck); **Records.svelte = convert source/decode/loudness to a ghost** (later track, not
         the first slice — first slice synths its own AudioBuffer; "test the music library elsewhere").

**AXIS A FIRST SLICE — BUILT 2026-06-29, browser-verify OWED** (compiles clean, type-clean, NOT yet
 heard). Audio.svelte.ts: added `pcm_buffer(pcm,sr)` (decode-free AudioBuffer from raw PCM) + `schedule
  (buf,when)→endtime` (lay a buffer on the timeline onto the tapped gainNode; a LATE `when` = a real
   silent gap) beside tap/sample/mute — all additive, type-clean (check jumps 77→164, my 97-138 block
    clean). Musuation.g: `IMPORT { SoundSystem }`; `Musu_gat()` (cached `H.c.musu_gat`, returns null with
     no AudioContext → headless-safe, inits + fires `AudioContext_wanted` for GatEnabler tap-to-unmute);
      `Musu_real_stream(gat,kind,total,deliver_ms,mute)` = REAL: deliver a synth chunk every `deliver_ms`
       wall-clock, `schedule` it at max(end,now) so deliver<50ms-play=seamless / >50ms = `now` overtakes
        end = REAL gap (underrun++), analyser sampled every 20ms → `Musu_measure` on the captured PCM.
         The fake cursor `Musu_stream` DELETED. MusuSignal rebuilt: beats healthy(deliver 30) / starved
          (150) / silence / witness; no Terminal/Player/Chunk particles (spine IS the audio graph now);
           `%skipped:no_audio` guard headless. Gen `.go` compiled+written via LocalGen (browserless).
**ADVERSARIAL AUDIT ([[adversarial-test-agent]]) RAN on the rebuild + acted on:** caught that `starves`
 was STILL fake — `sunder` is pure clock arithmetic + `sgaps>0` is satisfied by ANY silence (even a dead
  graph), so it passed without real starvation. FIXED → **differential**: `sunder>0 && sgaps > hgaps+3 &&
   hbits>=4` (starved gapped FAR more than a genuinely-entropic healthy baseline). Also de-faked `streams`
    (dropped the `played===of` tautology + jitter-flaky `hunder===0` → `hgaps===0 && hunder<=1`). `noisy`/
     `separable` were already REAL (≈7 bits at gainNode needs real audio); mute design CONFIRMED correct
      (analyser taps gainNode, mute zeroes gainNode2 downstream — guarded with a comment so nobody zeroes
       the tapped node). STILL-OPEN from the audit: stale 002-005 fixtures record of=48 (now total=24) →
        will diff every beat, RE-RECORD on the browser verify; browser-only = zero headless coverage (the
         skip branch asserts nothing) → the runner-level `%realtime` capability-skip is the real fix.
 **Mute:** default AUDIBLE (`!!H.c.musu_muted`) for the first verify; `H.c.musu_muted=1` silences LIVE
  (no recompile). VERIFY: open :9091 runner, run MusuSignal, HEAR the chord, confirm witnesses streams/
   noisy/starves/silent/separable green → THEN flip default to muted. Then TODO: a runner-level capability
    skip (don't even dispatch a `%realtime` Book headless; the guard only prevents the crash). Next after
     green = real STARVATION is already in (gaps from delivery race), then convert Records.svelte to a ghost.

**GLIDE — graceful live-edge rate control, BUILT 2026-06-29 (slice 1 of the gap-concealment re-model),
 browser-verify OWED.** Came from a gap-audit of Radios+Pirating: Radios' ONLY adaptive trick (Radios.svelte
  :344) HARD-sets playbackRate=0.8 within 3.141s of live + NEVER recovers (no ramp, no hysteresis); underrun
   = stall/stop, NO conceal (no repeat/fade/crossfade/pingpong); Pirating = pure file-download backpressure
    (not audio). So "bring it over" = RE-MODEL better. User picked **rate-controller first**, named **Glide**.
 Doctrine honored: Glide is **code+data, NOT a req pile** — `Glide_decide(frontier,cur,ended)→rate` is a PURE
  stateless curve in **Ghost/M/Radiola.g** (Schmitt band LOW=0.12/HIGH=0.30s, FLOOR=0.80, quick-to-slow /
   gradual-recover); the caller owns the trajectory data. Render primitives added to Audiolet (Audio.svelte.ts):
    `schedule(buf,when,rate=1)` now rate-aware (end += dur/rate) + `fade(to,secs)` (gainNode linearRamp, for
     the next ladder slice). `Musu_real_stream` gained a `glide` arg → consults Glide_decide each tick, records
      min_rate/final_rate/flips. New **MusuGlide** Book (browser-only): beat2 baseline-starved-no-glide vs beat3
       same-starve-glided (90ms deliver / 50ms play), witnesses **backs_off** (min<1, clamped ≥0.78),
        **recovers** (final=1 — fixes Radios' permanent drop), **smooth** (flips≤4 — hysteresis), **fewer_gaps**
         (DIFFERENTIAL + analyser-backed: glided gaps ≥2 fewer than baseline & gbits≥4). Registered: CreduFunk +
          tests + a Glide What in the Ality Waft, Credence board, wormhole/Story/MusuGlide/toc.snap (lie diges).
           Radiola.go + Musuation.go recompiled (LocalGen), Audio.svelte.ts type-clean. NEXT slices (the ladder,
            deferred): repeat-last-frame, reverse-pingpong, crossfade-on-seam, fade-to-silence — need reverse_buffer
             + slice_buffer primitives; + a mid-stream RECOVERY scenario (delivery speeds up → rate climbs back
              mid-run, not just at end); + headless POLICY coverage (Glide_decide is pure → unit-test it without audio,
               closing the browser-only gap). Radios+Pirating gap-extraction findings are the seed list.

**SYNAPSE convergence (user 2026-06-29): the Musu tests are LARP — real audio over a FAKE wire (setTimeout)
 + the Pere/Peeroleum spine is a real wire with FAKE payloads (control frames over a mock carrier).** User
  verdict: "are these tests just LARPing bullshit?" + "build the real application" + "get a bigger streaming
   reality together, even point to point, so that synapse is realistic AND tested." DECISIONS (AskUserQuestion):
    first build = **audio over the perturbable mock**; **KEEP the 7 cursor Books** (don't touch). Sane solution
     = **ONE synapse, TWO carriers**: write the stream loop once (caster pulls audio → Peeroleum_send → carrier
      → Peeroleum_deliver → inseq → Audiolet+Glide), run it over the real relay (realistic, browser) AND a
       perturbable mock (tested, headless) — the mock stops being LARP because it carries the SAME real stream.
 **THE BRIDGE SEAM (found, real): `w.c.on[type]`** — req_unemit (Peeroleum.g:514) hands a verified, in-ORDER
  frame to `w.c.on[h.type](w,pier,frame)`. So a listener registering `w.c.on.audiochunk` gets real sequenced
   integrity-checked (body_hash) audio frames off the real deliver→inseq→retx path. Caster: `Peeroleum_send(w,
    {header:{type:'audiochunk',from,to,seq:Pier_next_seq(pier)}, buffer: pcmBytes})`. Setup: `Lake_link(w,a,b)`
     (Peregrination.g) = two Piers + paired mock ports; perturb by wrapping a partner with `make_lossy_partner
      (port, schedule)` (Reliable.g — drop/dup/delay/blackhole + tick()/held/dropped). **Transport-under-loss is
       ALREADY proven by PereProof** (headless) — the GAP is only audio-payload + listener→Audiolet/Glide bridge.
 **BUILT 2026-06-29 (compile-clean): the radiostock SOURCE seam** — `Musu_radiostock(kind)` (synth default,
  `H.c.radiostock_override` = the "override radiostock" hook the user is prepping test data for) + `Musu_stock_chunk
   (stock,seq)`; Musu_real_stream gained an optional `stock` arg, MusuSignal/MusuGlide now pull THROUGH it (behaviour
    identical until override lands). So real directory-walked records (convert Records.svelte source/decode/loudness
     → ghost — user "very soon", blocked on their collection) re-ground EVERY audio test by setting the override.
 **NEXT (sequence):** (a) build Musu_cast + Musu_hear(w.c.on.audiochunk) + Musu_synapse_up (Lake_link) — audio over
  the CLEAN real Pier link, headless-prove the crossing (count/order via the handler, no AudioContext needed); (b)
   perturb it with make_lossy_partner + retx/tick (PereProof's proven machinery) → Glide copes, measured; (c) real
    records/override radiostock once the collection lands; (d) the relay (two-tab) carrier = the realistic twin.

**THE TESTING STANDARD (user 2026-06-29, "solid policy on writing Books only and testing real actual stuff
 realistically"):** (1) **Books only** — no .spec harnesses for the real tests; they run in the **Lies%runner
  in a browser**. (2) **Real Web Audio, no faking** — every measurement off audio a real context RENDERED
   (Musu_measure on the PCM), never cursor arithmetic. (3) **Determinism per Story run** — seed `H.prng`
    (prandle, xoshiro state default [1,2,3,4]) via `Musu_seed(n)`; combined with OfflineAudioContext render
     (no wall clock) the run is reproducible → STABLE snaps without entropy bands. (4) **Timelapse vs real-
      time, made explicit** — the heavy/repeated work (e.g. a param-search's ~40 trials) renders through an
       **OfflineAudioContext** (real Web Audio computed faster-than-real-time + deterministic = the "x8
        timelapse"); the audible **showcase** plays the result through the ONLINE AudioContext at real time
         (slow is fine; the runner fleet absorbs slowness). Be CLEAR where each is used + why.

**MusuTune — the self-tuning Glide-shower, BUILT 2026-06-29 (the standard's exemplar), browser-verify OWED.**
 User: "gradient-descend various parameters on the audio streaming process to where these perturbances cause
  the least show-wreckage." Glide params are now DATA (`Glide_decide(frontier,cur,ended,p={low,high,floor,step})`,
   defaults stand when p omitted). New engine methods in Musuation.g: `Musu_seed`/`Musu_profile` (deterministic
    warm→starve→recover delivery schedule + seeded jitter), `Musu_render_offline` (DETERMINISTIC TIMELAPSE — walk
     the schedule, lay every chunk on an OfflineAudioContext at its start+Glide-rate, startRendering(), measure
      the real PCM; returns measure + optional buffer), `Musu_wreckage` (loss = gaps*3 + underruns + pitch-drop +
       no-recover penalty), `Musu_descend` (coordinate/pattern descent over low/high/floor — each trial one
        offline render — from an untuned start to least wreckage), `Musu_play_buffer` (play a rendered buffer
         real-time, audible). **MusuTune** Book: beat2 DESCEND+record, beat3 SHOW (audible tuned playback),
          beat4 witness {descended, improved, backs_off, recovers} (deterministic → stable snap). Registered
           (Credence + Ality Waft + toc). Radiola.go + Musuation.go recompiled clean (LocalGen). NEXT: real
            records via the [[radiostock override]] once the user's collection + directory-walker land; the
             Pier-synapse axis (w.c.on.audiochunk) still open; MusuGlide (setTimeout, nondeterministic) is now
              superseded by the offline-deterministic approach — fold/retire later.

**Crate.g — music-collection rifling, BUILT 2026-06-29 (the real-records source), browser-verify OWED.**
 User: "start another .g about rifling through music collections (eg Directory.svelte and meander()),
  redesigned for our modern platform." Modern port of the OLD Directory.svelte tree-walk + Agency.svelte
   `meander()` random-walk: `Ghost/M/Crate.g` (compiles clean, enrolled in CREDULER_GHOSTS after Radiola).
    Tree as C particles — %Crate/%dir (c.handle=FileSystemDirectoryHandle) / %blob (c.handle=FileSystem
     FileHandle, sc.ext) / %record (c.chunks=[Float32Array], sc.artist/title/loudness/seconds). Verbs:
      `Crate_open` (showDirectoryPicker OR an injected handle — tests/override collection), `Crate_walk`
       (handle.values() one level, audio-ext classify), `Crate_meander` (FAITHFUL port — prandle random-walk
        to a track, GIVE_UP bound, dead-end climbs to root; seeded → reproducible), `Crate_decode` (getFile →
         OfflineAudioContext.decodeAudioData → slice ch0 into 2400-sample chunks + RMS loudness + filename
          metadata), `Crate_radiostock`/`Crate_radiostock_from` (→ {kind:'records',chunks} = the [[radiostock
           override]] feed). MODERNISED vs old: raw File System Access API (NO lib/p2p DirectoryListing).
            DELIBERATELY OUT of v1 (the bigger Records.svelte→ghost job): music-metadata tags, LUFS loudness,
             .webms disk cache, preview/stream split, the 200-record whittle catalog. WIRE-UP when the user's
              collection lands: `H.c.radiostock_override = await H.Crate_radiostock_from(crate)` → every audio
               Book (MusuSignal/MusuGlide/MusuTune) streams REAL music. Runner was DOWN when built (artifact-
                only; no browser test yet).

**MusuRadio — ~minute-long real-time SHOWCASE, BUILT 2026-06-29 (user: "see like a minute of activity with
 a few instantly-synthesized ready Record sources").** Distinct from MusuTune (deterministic offline proof):
  MusuRadio is the WATCHABLE real-time show. `Musu_synth_tone(seq,root)` (Musu_synth generalised to any root)
   + `Musu_synth_records(w,n,secs)` instantly mint n READY %record sources (distinct timbres, all PCM pre-
    synthesised on c.chunks — SAME shape as Crate_decode, so they feed the radiostock identically; zero files/
     decode/wait). MusuRadio Book spins them through the real voice for ~a minute, Glide on a cycling
      perturbation, bumping a %Radio particle per chunk so the live Cyto view MOVES. Split across play-beats
       (beats 3-8 ~9s each, NOT one 60s await — kind to the step machine); beat2 load, beat9 witness {ready,
        a_minute (elapsed≥45 via radio.c.elapsed off-snap), many_tracks (spins≥6), glided}. Coarse timing-
         robust witnesses (a show varies run-to-run; MusuTune owns determinism). toc has steps 2-9. Also FIXED
          MusuTune's Credence placement (was dangling 4-space sibling → now inside What:realaudio). Registered
           (Credence realaudio + Ality Waft + toc), Musuation.go recompiled clean. Browser-verify owed.

**TWO BUGS the user caught + FIXED 2026-06-29 (both real, adversarial agents confirmed):**
 (1) **MusuTune "proves almost nothing" — it was tautological.** `descended`/`improved` just say "a coordinate
  descent reduced its own made-up objective from a deliberately-bad start" — they PASS even with Glide INVERTED
   to do the wrong thing; no no-control baseline. FIX: `Musu_render_offline` gained a `ctrl` arg ('none'=rate
    pinned 1.0 / 'invert'=wrong controller speeds UP into a starve / default=glide). MusuTune now renders the
     SAME link 3 ways; new HEADLINE witnesses: **`helps`** (tuned dropouts < no-control dropouts, real-rendered
      gaps+underran — goes RED if Glide useless/harmful) + **`discriminates`** (inverted is WORSE than none → the
       metric has teeth). `descended` demoted to a secondary check. LESSON: an optimizer reducing its own loss is
        NOT proof; prove a DIFFERENTIAL vs no-control + a negative control (inverted) that must fail.
 (2) **MusuRadio "does nothing" — gesture gate + toc collapse.** ROOT: the runner tab's AudioContext is SUSPENDED
  (autoplay policy, no user click) → `Musu_gat` returns null → MusuRadio gated EVERY beat on it → returned at step
   1 → beats never ran → **the runner ERASES step= lines with no dige on re-snap** (Story.svelte encode_toc_snap:
    "skip a step with no dige + no notes") → toc collapsed to 1 step → "does nothing". MusuTune escaped only
     because its core is OfflineAudioContext (gesture-free). FIX: MusuRadio is now GESTURE-FREE — renders each
      track offline (real PCM, no gesture), paces the minute with performance.now + a MusuRadio_animate playhead
       loop (watchable), plays audibly ONLY if a gesture unlocked the voice; witness `helps` (glide<none per track)
        replaces vacuous `glided`. RESTORED its step=2..9 toc lines (the fixed Book will keep them now). KEY RULES:
         online AudioContext needs a user gesture in the runner (OfflineAudioContext doesn't); a Book that does
          nothing loses its toc steps. Musuation.go recompiled clean; browser-verify owed.

**REAL-MUSIC PIVOT — MusuCrate, BUILT 2026-06-29 (user: synth Books are a "lab rig", "empty picture";
 "lets start building and testing for that! pseudo-randomly buffer ./testsounds/ like Radios does").**
  Honest verdict on the synth Books: REAL but a lab rig — MusuGlide gaps 16→9, MusuTune 5-vs-8 dropouts are
   genuine; BUT (a) `discriminates` DIDN'T fire (inv_drop==none_drop==8 — my inverted controller wasn't worse;
    weak negative control, still-open) and (b) the snap is an "empty picture" (work is off-snap; synth+simulated
     perturbation is the ceiling till real music + real link). INGESTION CONSTRAINTS FOUND: Wormhole `rw_op:'read'`
      is TEXT-ONLY (.text()) + OPFS seed = only ['wormhole','Ghost'] → **binary audio CANNOT ride w:Wormhole**;
       a local share needs a picker gesture. SOLVED gesture-free: testsounds are at repo root, NOT served →
        **symlinked `static/testsounds → ../testsounds`** (dev server serves static/ at /) + generated
         `testsounds/manifest.json` (fetch can't enumerate a dir) → **`fetch('/testsounds/<file>')`** = real binary,
          no gesture. Crate.g fetch path: `Crate_manifest`/`Crate_fetch_record` (fetch→arrayBuffer→OfflineAudio
           Context.decodeAudioData→PCM chunks + RMS loudness + filename meta; %undecodable marker on codec fail)/
            `Crate_fetch_some` (prandle pick over manifest, like Radios' load_random_records). **MusuCrate** Book:
             beat2 buffer 3 real tracks, beat3 stream each ~6s Glide-vs-none (offline render), beat4 witness
              {real_records (FLAC actually decoded — RED if codec unsupported), playable (real seconds), helps
               (Glide cut real dropouts)}. The snap now carries REAL %record rows (title/seconds/loudness). FLAC
                decodes on Chrome/Brave (the runner), not Safari. Registered (Credence+Ality+toc), compiles clean,
                 browser-verify owed. NEXT realism axis = the Pier synapse (audio over real transport). KNOWN GAPS:
                  fix the weak `discriminates`; all 31 testsounds are copies of ONE waltz (identical decode).

**2026-06-30 — NO HEADLESS allowed (user): stop LocalGen/vitest. `.g` edits stay INERT in a live runner
 until recompiled (ghost-compile or reload); TS/Svelte HMRs on its own. THE recurring "does nothing" bug =
  a fresh Book's gen+toc aren't in the running runner → RELOAD the runner (re-acquires current gen + re-reads
   wormhole/Story/<Book>/toc.snap). MusuRadio proved this (ran 61s after a reload); MusuCrate needs the same +
    the dev server serving the new static/testsounds symlink + FLAC-decoding browser.
 **bin_read BUILT 2026-06-30 (the binary read primitive the user asked for; TS → HMRs live, NOT verified):**
  `WormholeNav.bin_read` (Housing.svelte.ts, read_file's twin minus TextDecoder) + `OpfsOverlayNav.bin_read`
   (WormholeOpfs.svelte.ts, .arrayBuffer()) + rw_op **`op==='bin'`** branch (Housing ~1905) — additive, existing
    text paths untouched. CRITICAL: binary CANNOT ride `req.sc.reply` (sc=string-only, ArrayBuffer there = fatal
     encode) → the handler parks it on **`req.c.bin`** (off-snap) + replies `{ok,bytes}`; consumer reads
      `req.c.bin`. CAVEAT: bin_read reads the OPFS seed (only ['wormhole','Ghost']) or a local-share DL — so it
       does NOT reach testsounds (unseeded); testsounds stays on the static/fetch path. bin_read is for
        seeded/library/local-share binary.
 **%Good-binary + preview/stream/reap = DESIGNED, NOT built (pump surgery, won't do blind):** LiesStore already
  hosts text `%Good` ({Good:1,type,path}, content off-snap on c.content, `known` dige + `subscribe,Aw,wake`,
   phased req_Store pump at LiesStore.svelte:374-531). Binary extension: a `%Good,type:'bin/audio'` with
    `c.preview`/`c.stream` ArrayBuffers (off-snap), filled via bin_read; PREVIEW = first ~1/3 (slice after read —
     OPFS has no range read; the Records.svelte radiopreview 0.3+0.4*rand model), STREAM = the rest on want;
      REAP = idle-drop mirroring raterminal_recordWear (LISTENING_FOR_LONG_ENOUGH=3 / _DELAY=19, cullable_since →
       drop c.preview/c.stream once a consumer's left it idle). The %Good should SNAP its lifecycle (previewed/
        streaming/idle) so the snap is self-describing (user: "does it describe enough?"). NEEDS user go-ahead.

**POLICY 2026-06-30 (user reversed "no headless"): I COMPILE .g now via `npm run ghost-compile -- <files>`
 (tickets the live editor → HMRs the runner). Editor can go half-open ("no response in 12s") — RETRY, or use
  the alternative (LocalGen) only if the editor's truly down. ALSO: `req.sc.reply` holding an exotic object is
   NOT a fatal encode — the snap shows exotic objects via **mung** (the `{"mung":["age"]}` IS that). So don't
    hide binary in req.c to avoid snaps; sc-with-mung is fine/visible. OPFS "can get fatal" → avoid it for audio
     (use fetch from static/). decodeAudioData is decode-FROM-START always (no seek; preview = keep the first
      chunks of a full decode). bin_read built last turn stands (for seeded content) but testsounds uses fetch.
 **MusuCrate REBUILT around a VISIBLE `rastock` 2026-06-30 (user: synth/flat version "unimpressive"; "it's
  req:rastock that I'm wanting to see — what are its desires, then the Wormhole reads came back, then Records
   being made").** User replaced testsounds with REAL nested music (Big Blood albums, artist/album/track, FLAC+
    MP3, 70 tracks); regenerated `testsounds/manifest.json` RECURSIVE (relative paths). Crate.g: `Crate_meta_
     from_path` (real artist/album/title from the path), `Crate_enc_path`, `Crate_fetch_payload` (fetch nested
      → decodeAudioData → keep first 240 chunks preview + real seconds/loudness), and the VISIBLE builder
       `Crate_rastock_start/_issue/_read_into/_harvest`: a `rastock` particle DESIRES want=4, fills one notch
        per beat — ISSUE a %reading (out), it COMES BACK (payload off-snap on rd.c.result, sc.back), HARVEST →
         a %record (real metadata, chunks on .c). MusuCrate beats: 2 open+issue / 3-6 harvest+issue / 7 stream
          glide-vs-none / 8 witness (real_records≥2, playable≥2, helps≥1). toc step=2..8. Both ghost-compiled
           LIVE. TO RUN: RELOAD the runner (picks up step=2..8 toc + fresh gen; manifest is fetched live each run).
 **REAL PROBLEM to surface next: real-music DYNAMICS confound the gap detector** — Musu_measure counts any 50ms
  window with rms<0.005 as a "gap", but real music has quiet passages → inflated gap counts. The glide-vs-none
   DIFFERENTIAL still isolates DELIVERY gaps (musical quiet is in both), so `helps` holds, but the absolute
    counts are noisy. Distinguishing delivery-silence from musical-silence is the real refinement.

**2026-06-30 — pool=0 ROOT: the `static/testsounds → ../testsounds` symlink was LOST when the user swapped
 the music (replacing testsounds dropped it) → /testsounds/manifest.json 404 → manifest [] → pool=0. RECREATED.
  (New symlink may need a dev-server RESTART to be served.) Lesson: re-check the static symlink whenever
   testsounds changes. ghost-compile is FLAKY (editor goes half-open, "no response in 12s") — retry, and if it
    stays down use LocalGen as the alternative to WRITE the disk gen (then the user RELOADS the runner to pick
     it up). Crate.go ghost-compiled live; Musuation.go via LocalGen (editor was down).
 **PLATFORM FILAMENTS — visible roadmap, BUILT 2026-06-30 (user: "build some real stuff... visible overall
  fillamentations with lots of TODO about refinements... I'm trying to get the creation of this streaming
   platform to happen").** `MusuCrate_filaments(w)` erects the WHOLE pipeline as a particle tree under
    `platform:jamsend`: 5 `%stage` filaments (1 Collection / 2 Rastock / 3 Player — `built:1`, real data flows;
     4 LiveEdge / 5 Pier — not built), each with visible `%todo` rows so the SNAP IS THE BUILD MAP. TODOs (no
      commas — peel splits on them): Collection {meander tree-walk; real Wormhole/bin_read source; tag metadata};
       Rastock {preview→stream; host as %Good in LiesStore; idle-reap}; Player {gap-detector DELIVERY-vs-MUSICAL
        silence; concealment ladder; audible playback}; LiveEdge {real broadcast cursor + stay-behind}; Pier
         {cast→listen over w.c.on.audiochunk; perturbable link; multicast}. The built stages carry live data
          (Collection pool=70 real Big Blood tracks, Rastock fills real %record rows, Player Glide render/measure).
           This is the long project's skeleton — fill stages, strike todos. Reload runner + re-run MusuCrate to see
            the map + real records. Likely next-real-problem (a Player todo): gap-detector vs musical dynamics.

**2026-06-30 — MusuCrate WORKS on real music + 3 fixes + the unifying mesh model.** After the symlink fix,
 MusuCrate decodes real Big Blood tracks (FLAC+MP3), the rastock read→back→record pipeline is VISIBLE, and
  Glide beats no-control on real music with HONEST coverage-gaps (glide_drop 41 < none_drop 52, 40<50);
   witnesses green. **Gap detector is now COVERAGE-based** (Musu_render_offline: gap_secs = uncovered playback
    time where `at>end`; gaps = round(gap_secs/0.05)) — only silence WHERE A TRACK SHOULD SOUND counts; musical
     quiet (covered) ignored. The user's "higher-level representation" = the expected-play/coverage timeline.
 **3 bugs FIXED:** (1) `have=0` never snapped — RAW `ra.sc.have = N` re-mutating an EXISTING sc key does NOT
  re-dige into the snap (NEW keys like glide_drop DO snap raw; changed existing values don't) → use the TRACKED
   `await ra.r({have:N})` (CLAUDE.md: prefer r()/replace over raw sc mutation). GOTCHA worth remembering. (2)
    duplicate reads — Crate_rastock_issue now dedups (skip a path already reading/recorded; prandle collided).
     (3) only 2-of-4 — MusuCrate_fill now async+awaits harvest, MusuCrate_play harvests stragglers first.
 **PLATFORM MAP now 9 visible filament stages** (MusuCrate_filaments): 1 Collection / 2 Rastock / 3 Player /
  4 LiveEdge / 5 Pier / 6 Mixer / 7 DJ-cue / **8 Mesh / 9 Stretch** — each %stage with %todo + %done rows so
   the snap IS the roadmap. **THE UNIFYING MODEL (user 2026-06-30): "it's really just a sync that can see
    itself in several places, and the edges between."** One replicated C** state, N replicas (clients),
     %edges between (webrtc peer-edge cheap / relay-edge = uplink, each a cost); ALL of DJ-cue/listener/mixer
      = routing content along the cheapest edges. **Multicast-STRETCH**: a relay-only peer sends ONCE, a
       webrtc-peered client FORWARDS locally → quiet uplink (the cafe case: many clients, one quiet uplink).
        Builds on the REAL foundation: Peeroleum @channel multicast (turn relay-fanout into peer-forwarding).
         NEXT real build (needs the user's multi-runner verify): Mixer (2 local cells beatmatched) OR the
          mesh/stretch on Peeroleum. COMPILE POLICY: ghost-compile (flaky — retry; LocalGen fallback).

**2026-06-30 — STAGES 6/7/8/9 BUILT (user: "build a whole lot more... max out my usage. tokens nearly
 free"). Two new ghosts + three Books, all pure-logic-VALIDATED in node, compile-faithful, browser-verify
  owed.** Doctrine honored: real DSP/graph algorithms as code+data, NO req piles.
 **Ghost/M/Mixer.g (stage 6 — the cellular mixer):** `Mix_synth_beat(nch,bpm,root)` (kick on a beat grid +
  tonal bed + seeded dither — gives onsets to detect), `Mix_onset_env` + `Mix_tempo` (REAL autocorrelation
   tempo detection: mean-normalised, shortest-lag-within-88%-of-peak to dodge octave error), `Mix_beatmatch`
    (rate=bpmRef/bpmOther, clamped ±25%), `Mix_render_rate`/`Mix_render_sum` (OfflineAudioContext resample /
     N-cell SUM into one destination), `Mix_crossfade` (equal-power vs linear) + `Mix_thirds_dip`, `Mix_align`
      +`Mix_unit` (onset-envelope normalised cross-correlation = beat-GRID PHASE, distinct from tempo).
 **Ghost/M/Mesh.g (stages 8+9 — the sync that sees itself):** `Mesh_build`/`Mesh_route` (Dijkstra cheapest
  path, counts relay/uplink hops), `Mesh_broadcast_naive` (a copy per client → uplink N×) vs `Mesh_broadcast
   _stretch` (Prim min-cost broadcast TREE → uplink ONCE then webrtc-forward), `Mesh_cafe_spec` (relay-only
    source + N peered clients; RELAY_COST 10 ≫ PEER_COST 1). Transport MODELLED (deterministic, 1 runner);
     real-socket cut = Peeroleum @channel multicast (needs 2 runners).
 **Three Books (Musuation.g):** **MusuMix** (beats 2-6: load 120+96 decks / beatmatch+re-render / sum-mix /
  crossfade; witnesses tempo_detected, beatmatched, cells_sum, crossfade_holds + crossfade_discriminates [linear
   dips where equal-power holds — the negative control]). **MusuMesh** (build cafe / route / cast naive-vs-
    stretch / scale to 6; witnesses routes_cheapest, stretch_cuts_relay [naive uplink N, stretch 1], cheaper,
     scales [stays 1 at any crowd]). **MusuCue** (stage 7 DJ-cue: a phone REPLICA holds the cell descriptors
      over a peer-edge + RE-SYNTHS the off-air deck from synced state, beatmatches → beat-grid alignment JUMPS;
       witnesses replicated, cued_offair, monitor_real, cued_matched, synced [Mix_align 0.21→0.95 — same tempo
        AND downbeat], brought_in). **NODE-VALIDATED actual numbers** (/tmp prototype): tempo A=119.7/B=95.3,
         beatmatch 1.25, equal dip 0.872 vs linear 0.714, mesh route cost 2 relays 0, cafe(3) naive 3/stretch 1,
          cafe(6) 6/1, align 0.209→0.954. Enrolled Mixer.g+Mesh.g in CREDULER_GHOSTS (before Musuation.g); toc
           step=2..6 for each Book; registered in Ality Waft + Credence; filament stages 6/7/8/9 marked built.
            Gens written via LocalGen (Mixer.go/Mesh.go/Musuation.go), all faithful (no bare-else mangle, no
             dropped captures, Dijkstra/cross-correlation byte-exact). REMAINING TODO: stage 4 LiveEdge (real
              broadcast cursor, deterministic-buildable) + stage 5 Pier (real transport — needs multi-runner);
               real-socket Mesh/Stretch on Peeroleum @channel; the OfflineAudioContext render legs of the three
                Books (beatmatch re-render, cell-sum, the crossfade renders) need the live :9091 runner to verify.
 **ADVERSARIAL AGENT RAN on MusuMix+MusuMesh (re-implemented the DSP/graph numerically) — verdict: nothing
  fake/tautological; tempo IS autocorrelated from rendered audio, beatmatch IS a real render+re-measure round
   trip, mesh numbers fall out of real Dijkstra/Prim; no key-collisions (witnessed:X scoped per-w), no .g
    gotchas. Found 2 fair weaknesses, BOTH FIXED:** (1) crossfade_holds 0.872-vs-0.85 was thin AND the comment
     overclaimed "≈1.0 flat" (the ~0.13 shortfall is material energy variation — kicks at different phases —
      not the gain law) → gate lowered to 0.8 + comment made honest (the DIFFERENTIAL crossfade_discriminates
       is the real gain-law proof). (2) THE key fix — MusuMesh ran on ONE topology rigged to make
        stretch_relays==1 with no failing counter-case → added a NEGATIVE CONTROL (relay-only topology, NO peer
         edges → the stretch CANNOT cut the uplink, stretch==naive==3) + the **no_free_lunch** witness. Now
          stretch_cuts_relay reds if the MST is broken; the saving is provably the peer edges, not the algorithm
           always yielding 1. LESSON (again): a headline number needs an input where it SHOULD fail and does.
 **STAGE 4 LiveEdge BUILT 2026-06-30 (user: "continue!").** Glide's TWIN at the other end of the stream:
  Glide guards the delivered buffer running DRY; LiveEdge guards the playhead catching the LIVE BROADCAST
   edge (Radios check_live_edge_delta — throttle 0.8 within 3.141s of live). `LiveEdge_decide(margin,cur,
    target,p)` in Radiola.g (beside Glide_decide): margin>HIGH→chase FAST 1.5 (cut latency); margin<LOW→back
     off SLOW 0.8 (rebuild margin); band→gentle chase 1.05 (drifts toward the edge so the throttle keeps
      working). `Musu_render_liveedge(total,stock,controlled,fixed_rate)` in Musuation.g: a virtual
       production clock (chunk s live at s·chunkdur), the listener starts START=1.5s behind, plays at the
        controller rate; reaching a chunk before it's produced = STALL (overrun, coverage gap); renders the
         plan through OfflineAudioContext + measures. **MusuEdge** Book (beats 2-4: baseline fixed-fast-1.5 /
          controlled / witness). NODE-VALIDATED: controlled min_margin 0.6 / final 0.612 / overruns 0 / gaps
           0 / min_rate 0.8; baseline overruns 110 / gaps 36. Witnesses: holds_margin (ctl overruns 0),
            backs_off (min_rate≤0.85), low_latency (0.2≤final≤1.0 — low AND safe, the COMBINATION uncheatable:
             play-always-slow passes holds_margin but fails low_latency; sit-at-rate-1.0 fails backs_off+low_
              latency), baseline_overruns (the negative control — fast chase overran), fewer_gaps (36→0,
               bits≥4-tied). VALIDATION corrected a witness: overruns are a COUNTER not a negative margin (the
                model clamps margin≥0 on stall) → baseline_overruns keys on overruns>0 not min_margin<0. Stage
                 4 filament marked built; toc step=2..4; registered Ality+Credence; Radiola.go+Musuation.go
                  recompiled clean (no bare-else mangle). **STAGES NOW BUILT: 1,2,3,4,6,7,8,9 — only 5 Pier
                   remains (real transport, needs 2 runners).** OfflineAudioContext render legs of all the
                    real-audio Books still need the live :9091 runner to confirm (math validated headless).
 **MusuEdge ADVERSARIAL-FIXED 2026-06-30:** agent caught backs_off was tested on ~1 input (the 0.8 throttle
  fired once at chunk 198/200 — drop total<198 and it reds), holds_margin's `c_min>=0` was tautological (margin
   clamped to 0), and fewer_gaps' "coverage" comment overclaimed (gaps are analytic from the stall model, not
    Musu_measure(rendered).gaps). FIXED: tightened the band (LiveEdge_decide HIGH=target+0.1, CHASE param 1.2,
     START 1.5→0.9) so the throttle OSCILLATES (71 events at total=200, 51-91 across total 150-250 — robust);
      backs_off now asserts a throttle COUNT (≥8) not a single min_rate brush; holds_margin → `overruns==0 &&
       min_margin>=0.3` (real floor — overrun clamps to 0 → reds); fewer_gaps comment fixed (gaps=model stall
        total, bits≥4 is what ties to the render). The low_latency witness is the load-bearing discriminator
         (a play-always-slow controller passes holds_margin+backs_off but final margin grows → fails low_latency).
 **STAGE 5 Pier BUILT 2026-06-30 — the REAL synapse, the piece every other Musu Book LARPed.** Real PCM
  (Musu_synth→Float32→Uint8 bytes) sent as %audiochunk frames over the REAL Peeroleum transport between Piers
   stood up by `Lake_link(w,a,b)` (Peregrination.g) on the mock carrier — the SAME deliver→inseq→retransmit
    path PereProof proves headless. RECIPE (from an Explore agent): `Lake_link`→[txPier,rxPier]; `Peeroleum_arm_
     whittle(w)` arms retx; stamp `rxPier.i({Ud:1,pubkey:<sender>})` both ends (app frames need proven Ud);
      `Peeroleum_on(w,'audiochunk',(cw,pier,frame)=>{pier.c.audio.push(frame.header.seq)})` registers the
       receiver (w.c.on[type], dispatched by req_unemit ~514 AFTER it verifies the sha256 body_hash); send via
        `Peeroleum_send(w,{header:{type,from,to,seq:Pier_next_seq(tx),body_hash,body_len},buffer:bytes})`.
         **MusuPier** Book: beat 2 LINK (clean pair + lossy pair + handler + Ud + arm + tight retx_policy
          {base:1...} + a digest-sensitivity unit check), 3 CAST 5 chunks clean→in order, 4 PERTURB (reliable=
           false both ports, `make_lossy_partner(Lake_port(lrx),{drop:[seq2]})`, `Lake_port(ltx).partner=lossy`,
            send 4→one dropped), 5 SETTLE (retx heals across boundaries), 6 witness {linked, crossed [got==1..5
             in order — only reachable via real verified delivery], verified [digest collision-sensitive +
              crossed], dropped_then_healed [lossy.dropped>0 AND hearer got all 4 in order — retx healed it]}.
               NO Web Audio (payload is bytes; proof is order/integrity/heal). **CANNOT node-validate (composes
                the transport spine) — NEEDS LIVE-RUNNER VERIFY** (unlike the pure-DSP Books). Mirrors Lake_heal_
                 arm exactly. toc step=2..6; registered Ality+Credence; Radiola.go+Musuation.go recompiled clean.
                  **ALL 9 PLATFORM STAGES NOW BUILT (1-9).** Open: real-socket multicast @channel (2+ runners),
                   wire the listener bytes into Player/Glide, + the OfflineAudioContext + transport Books' live
                    runner verification (the math/wiring is validated/recipe-faithful; the runner is the gate).
 **MusuPier ADVERSARIAL-REVIEWED 2026-06-30 (agent read the Peeroleum spine + Reliable + PereProof):
  WIRING CORRECT, TIMING GREEN.** Confirmed: Ud on the right piers, perturb mirrors Lake_heal_arm exactly,
   drop_seq=2 hits the 2nd of 4, and — key — with retx_policy {base:1} the dropped seq retransmits at the
    4→5 boundary (retx_delay=2^0=1 tick) so the heal completes one full settle beat before the witness at 6
     (NB base:1 is REQUIRED — the prod default base:2 wouldn't heal in time; add a settle beat if loosened).
      crossed + dropped_then_healed judged REAL. 3 fixes applied: (1) `verified` was near-tautological
       (digest_sensitive is always 1 for sha256 → verified≡crossed) → REPLACED with a real corruption-
        rejection test (`MusuPier_send_corrupt` sends a frame whose body_hash is the digest of DIFFERENT
         bytes → req_unemit faults it %faulty → its seq never reaches the listener; witness asserts
          got.indexOf(corrupt)<0 — the integrity gate rejects corruption in the real delivery path, what
           PereProof does). (2) removed the snap-boolean violation (`w.sc.digest_sensitive = …?1:0` wrote 0
            untracked). (3) witness now POLLS every pass (was single-shot at n===6 — fragile if the heal is a
             think late). Musuation.go recompiled clean. STILL needs live-runner verify (transport spine).

**2026-06-30 — RUNNER-VERIFIED all 5 new Books + cut Radio_spec.md (user: "I don't know enough to accept
 them... work on that with the runner... look at most of everything raw").** Ran each on the LIVE :9091
  runner via `runner_ask.mjs run <Book> --watch` → `snap <n>` (read RAW snaps) → `accept` → re-run green.
   Flow: a fresh Book runs RED only because its toc has lie-diges (0000…); `accept` records the live snaps
    as fixtures (lands in the REPO: wormhole/Story/<Book>/00N.snap + toc.snap via the dev-server disk
     backend), re-run → green. **All 5 GREEN + accepted:** MusuMix (snap proved tempo 119.7/95.3, beatmatch
      1.25, mix 0.153>solo, equal 0.872/linear 0.714, 6 witnesses), MusuMesh (naive relays=3/cost=30 vs
       stretch relays=1/cost=12, control_no_peers=3/3, 7 witnesses), MusuEdge (controlled overruns=0/
        throttles=71/min_rate=0.8 vs baseline overruns=145/gaps=48, bits 7.26/5.88, 5 witnesses), MusuPier
         (clean inbox unemit=1..5 + corrupt seq6 in FAULTY error:bad-body-hash; lossy hearer got 1..4
          healed; 4 witnesses — DETERMINISTIC across runs, green w/ caveat:2 = retx think-jitter absorbed by
           the entropy band, the PereProof-style transport standard), MusuCue. **ONE REAL BUG the runner
            caught + FIXED: MusuCue `cued_offair` never fired** — single-shot witness at beat 6, but bring_in
             (beat 5) flags deck B on_air by then, so the "cued deck off-air" state (true only beats 2-4) was
              already gone. FIX = POLL the witness every pass (move it out of the did_step guard, like
               MusuSkip/MusuPier) so it latches early. ghost-compile HMR'd the runner → all 6 Cue witnesses
                fire (incl cued_offair) → accepted → green clean. LESSON (3rd time): a witness on TRANSIENT
                 state must POLL, not single-shot. RUNNER GOTCHAS: lease keyed by claude cluster pub (10-min);
                  post-accept immediate re-run sometimes flakes outcome:null (re-run); transient "no reply in
                   8s" half-opens (retry); `release` when done. ALWAYS the live runner, never headless.
 **Radio_spec.md CUT 2026-06-30 (user: "cut a big Radio_spec.md... clarify the high level functions we
  want to string together... pull all these TODOs out... more structured whatevers stage,of,name:Collection,
   built").** `src/lib/O/spec/Radio_spec.md` = the destination doc: §1 the one idea (sync-with-edges), §2
    data model, §3 the pipeline (Collection→Rastock→Player→Pier→Mixer→DJ-cue→Mesh→Stretch high-level
     functions strung together), §4 the controllers (Glide/LiveEdge/coverage), §5 the 9 stages ITEMISED
      (built/done/todo — all the refinement prose pulled from the filaments), §6 the test family table
       (which Book + headline witness proves each stage), §7 open frontiers (multi-runner: @channel
        multicast, real C** sync over Pier, audio-bytes→Player, concealment ladder, live-voice mixing).
         **MusuCrate_filaments SLIMMED** to 9 clean `stage,of,name,built` rows under `platform,name:jamsend,
          spec:src/lib/O/spec/Radio_spec.md` — no more todo/done prose in the test snap (it's in the spec).
 **MusuCrate FIXED + GREEN + accepted + DETERMINISTIC 2026-06-30 (user: "look into that").** Three bugs,
  ONE root: **`r({have:N})` called with one arg builds pattern {have:1} then `i({have:N})` — it CREATES a
   stray `%have` CHILD particle, never touches ra.sc.have** (the prior "fix" was backwards). And the loop's
    `ra.rm(...)` was NOT awaited → (a) a lingering reading got DOUBLE-harvested into a duplicate record, and
     (b) its open replace transaction collided with the r({have}) replace → "nested replace() transactions"
      THROW → harvest threw → MusuCrate_play died before making %report → no `helps`. FIX: `await ra.rm(...)`
       + a record-exists guard (no dup), and `ra.sc.have = N; ra.bump()` (the proven MusuStock_advance raw-
        sc+bump pattern — re-diges; NOT r()). → have=4, no dup, report,played=4,helped=4, all 3 witnesses fire.
 **DETERMINISM (the harder half — real mp3 fetch+decode timing leaked into snaps):** have=2 one run/3 the
  next (race over how many decodes landed by the snap), and the %reading's `back` flag flipped async (a fast
   decode landed before its beat's snap → dige flickered). FIX two parts: (1) **drain-per-beat** —
    MusuCrate_fill now `drain (await all in-flight reads) → harvest → issue`, so each beat adds exactly one
     record (3→1 4→2 5→3 6→4), gradual AND deterministic (Crate_rastock_drain polls c.back, perf.now budget
      20s). (2) **`back` OFF-snap** — `rd.c.back` not `rd.sc.back` (read_into/drain/harvest), so a %reading
       always snaps as just its path regardless of decode timing. Result: all 8 step diges identical across
        3 runs → accepted → green clean. LESSON: async-completion flags that race the beat snaps belong on
         .c (off-snap); drain to a deterministic count before witnessing real-async work. **ALL 6 Musu real-
          audio/platform Books now green+accepted (MusuMix/Mesh/Cue/Edge/Pier/Crate).**

**2026-06-30 — `expecting()` ttlilt LAYER built + MusuConceal (concealment ladder) built+green (user:
 "improve for elegance... try it").** After deeply reading the ttlilt machinery (Hovercraft i_req_ttlilt/
  i_Story_o_req_ttlilt/o_Story_req_ttlilt + Story poll_step, TICK_MS=50): ttlilt = the "ask for time before
   snapping" advisor — NO death timer, poll_step checks until_ts>now each 50ms; two outcomes (RESOLVE: req
    finishes → causal snap; TIMEOUT: until_ts passed → in-progress snap, poll-quantised). The Musu Books had
     been BLOCKING-awaiting inside the eternal wrangle (holds the Atime mutex, bypasses the advisory). BUILT
      **`H.expecting(w, name, secs, async_fn)`** (Hovercraft, the ttlilt region): hangs a FINISHING child
       %req:name to host a ttlilt(secs), kicks async_fn NON-BLOCKING, finishes via reqyoncile on resolve
        (causal) or lets it time out (bounded escape); settle()-guarded against late-Promise-after-teardown
         (finished/!c.up). Converted MusuCrate_fill → `issue + expecting('fill_'+n, 25, drain+harvest)`.
          **KEY DISCOVERY: the codebase ALREADY anticipated ttlilt timing churn** — Story.svelte:877 has a
           graft rule that FORGIVES `self,round` (the per-tick counter churns run-to-run because the ticks a
            step takes is non-deterministic). The expecting-based MusuCrate's dige flickers ONLY on self,round
             (state byte-identical), and that graft forgives it → green w/ caveat:3-4. So ttlilt-timed Books
              are deterministic-in-STATE, the round graft handles the timing. (CPU renders stay blocking —
               they're not waiting on external meaning + blocking keeps round stable/caveat:0.)
 **MusuConceal — the concealment ladder (Player stage 3), GREEN+accepted (caveat:0, deterministic).** Pure
  PCM ops (no Web Audio gate): on a delivery gap, fill with repeat-last-frame or reverse-pingpong instead of
   silence. `Mix_reverse` (Mixer.g) + MusuConceal (Musuation.g, beats 2-5 silence/repeat/pingpong/witness).
    Node-validated + runner-confirmed IDENTICAL: silence silent=4, repeat/pingpong silent=0 (gaps filled),
     bits 7.32 (real fill), **seam: repeat=0.0436 (clicks) vs pingpong=0 (continuous — reverse starts where
      the last frame ended)** → `smoother` differential. Witnesses: has_gaps/repeat_fills/pingpong_fills/
       real_fill/smoother. spec/Radio_spec.md §5 Player concealment todo→done; registered Ality+Credence.
 **NEW-BOOK BOOTSTRAP GOTCHA (cost me a cycle):** a brand-new Book's gen reaches the runner via ghost-compile
  HMR (editor up) OR a runner reload — NOT magically. The runner runs its LOADED gen; if that predates the
   Book (loaded at an earlier reload), `run <NewBook>` finds no <Book>_drive → does nothing → 1 step → the
    re-snap ERASES the authored step=2..N toc down to 1 step. Fix: ghost-compile (HMR the fresh gen) — it was
     just FLAKY ("0 compiled" = editor half-open; RETRY worked) — THEN restore the toc, THEN run. Also: the
      HMR full-page reloads the user saw at "test end" were just Vite reloading on my Hovercraft.svelte
       (core-module) edits + gen rewrites — benign (re-acquires gen+toc on boot), and they were actually
        DELIVERING my changes to the runner. **Musu real-audio/platform Books now green: Mix/Mesh/Cue/Edge/
         Pier/Crate/Conceal (+ the 7 cursor slices).**

**2026-06-30 — REMOTE RUNNER + MusuSignal/MusuGlide migrated online→offline (user: "a lot of MusuSignal
 doesn't like it. test with the remote runner, it's got new features, all yours").** runner_ask.mjs has
  NEW features (docs intact in its usage block + spec/Cluster_runner_handover.md): **`runners`** op lists
   the Waft:Cluster registry (wormhole/Cluster/toc.snap → HostedIdentity:<prepub>,role:runner), and
    **`--runner=<prepub|prefix|friendly>`** courts ONE specific runner with INSIST (retry the same one on
     busy/silence, no failover; RUNNER_INSIST_TRIES/_MS); no --runner = legacy role broadcast. Two runners
      advertised: 77e2fe94 (★ my client = the local tab) + **49dee91d = the remote one ("all mine")**.
       `node scripts/runner_ask.mjs run <Book> --runner=49dee9 --watch` (bump RUNNER_ASK_TIMEOUT_MS for slow
        beats). **DIAGNOSIS: the remote runner is headless/dockerised — no gesture-unlocked audio device →
         the ONLINE AudioContext renders SILENCE** (MusuSignal/MusuGlide read bits=0/rms=0 everywhere → all
          audio-witnesses drop). Those two were the last OLD real-time-online Books (Musu_real_stream +
           Musu_gat); the newer ones (Tune/Mix/Edge/Cue/Conceal/Radio) all use gesture-free OfflineAudio
            Context. **FIX = migrate both to Musu_render_offline** (gesture-free, deterministic, real audio
             on ANY runner): MusuSignal_run → render_offline(uniform deliver_ms profile, ctrl 'none'); Musu
              Glide_run → render_offline(Musu_profile warm→starve→recover, ctrl 'glide'|'none'), total 24→36
               + the `recovered` flag for the recovers witness (24 chunks didn't give Glide room to climb
                back to full; 36 does — matches MusuTune). Both now GREEN on 49dee9 (MusuSignal 5/5 bits=7.41/
                 starved gaps=46-underran=23/silence bits=0; MusuGlide 4/4 glided gaps=1 vs baseline 4,
                  recovered, fewer_gaps), fixtures re-accepted (002-005.snap landed in MY repo — the remote
                   runner writes the shared wormhole disk). **GOTCHA: the remote runner tears its Story world
                    down fast after a run** → `accept` a few seconds later = "no Story world yet"; do run+accept
                     BACK-TO-BACK (one command, RUNNER_INSIST_MS low). **ALL Musu real-audio Books are now
                      gesture-free → run on headless/remote runners.** TODO: MusuRadio uses Musu_gat for the
                       (bonus) audible playback — already gesture-free for measurement, fine; the `Musu_real_
                        stream` online path is now unused by the witness Books (retire/keep for audible demos).

**2026-07-01 — full Musu suite verified green on the remote runner + MusuRadio shortened + the runner-
 capability design.** Swept ALL Musu Books on remote runner 49dee9: the 7 cursor sims (Staple/Stream/Stock/
  Live/Wear/Skip/Crowd) GREEN (caveat:5 = the self,round graft forgiving think-count across runners — their
   fixtures were recorded elsewhere; content matches). **MusuTune was a STALE CONTENT fixture** (NOT flaky —
    proved run-A==run-B byte-identical: start_w=21.8/inv_drop=12/floor=0.82), just not in my accept batch; re-
     accepted → green byte-clean, and `discriminates` NOW FIRES (inv_drop=12 > none_drop=9 — the old 8==8 weak
      spot is gone). **MusuRadio shortened ~60s→~24s** (user "could be 25s?"): 4s synth records × 4s per-beat
       budget × 6 play-beats → deterministic 1-spin/beat (spins=6, helped=6, playhead=80); witness `a_minute`@45
        → `sustained`@18 (honest), many_tracks 6→4, helps 3→2. STAYS real-time (it's the watchable showcase —
         can't/shouldn't go offline); `helps` (the load-bearing proof) is offline-rendered so duration-
          independent. Green+accepted (9/9 caveat:0). **MusuRadio does NOT need real audio** — it works headless
           (offline render + setTimeout playhead); its only sin was length.
 **THE RUNNER-CAPABILITY DESIGN (user: "%realtime tag... going too far to discern runner quality... Identity,
  like a person, might know what it's into"):** the RIGHT model for the ONE Book that genuinely needs real
   audio (a future real-time delivery-RACE test that measures real underruns via the analyser hearing real
    sound — can't run headless): DON'T make the Book probe/discern the runner. The RUNNER self-probes once at
     boot (play a tone, does the analyser hear it?) and ADVERTISES the result as part of its Identity
      (HostedIdentity already carries role/friendly in wormhole/Cluster/toc.snap — add `audio:1`); the Book
       declares a NEED (`needs:audio`); dispatch matches need↔offer. "Identity knows what it's into" = the
        capability is the runner's self-knowledge, advertised once, NOT discerned per-run. Small extension of
         the existing advertise/registry, NOT over-engineering. NOT YET BUILT (cluster-layer; deferred until
          the real-time-race Book exists). **RUNNER OPS LESSONS:** the remote runner is SHARED (PereStaple ran
           on it concurrently — contention, not exclusively "mine"); DON'T hammer it with rapid back-to-back
            runs (I wedged BOTH 49dee9+77e2fe94 with a fast sweep → both refused "busy"; release/ping refused
             too → needed a bounce, recovered on its own); PACE runner requests one-at-a-time. Remote runner
              tears its Story world down fast post-run → accept must be BACK-TO-BACK with the run (one command).

**Plan. Axis A (real audio, 1 Book, browser-verify once) — small:** (1) IMPORT Audio.svelte.ts;
 a thin Musu reality stands up `SoundSystem`, makes a real AudioBuffer from synth PCM, feeds an
  `Audiolet` (chained on `on_ended` for starvation = deliver a chunk LATE → real silent gap the
   analyser reads), `.tap()`+`.mute()`, then `.sample()` to measure. nodes on `.c`. (2) a "play
    3s then sample" beat = finishing `%req`+`%ttlilt` ([[ttlilt-rides-a-finishing-req]])
   or `awaiting_audio_done` gate, (3) a Book capability tag `%realtime`/`needs:audio` so headless
    CredRunner SKIPS it (jsdom has no AudioContext), (4) MusuSignal rebuilt — starve = feed the
     real queue too slow → source runs dry → real silence the analyser reads. **Axis B
      (parallelise runner) = the [[runner-fleet-goal]]:** keystone = per-runner identity
       (`runner-<id>`, today all share addr `runner`, relay role is SET-ONCE `relay.ts:148`);
        then route-by-runner dispatch, `(runner_id,uid)→verdict` map, dispatch/harvest loop.
 Fork RESOLVED by the reuse decision above: reuse the real `Audiolet` voice (not a fresh graph),
  but not the full `radio_hear` chain yet — graduate to that after the first slice greens. Browser-
   verify is the user's (jsdom has no AudioContext; first verify UNMUTED to hear it, then mute by
    default). New audio code in peels not raw JS ([[dsl-over-raw-js]] — `$recs = o Stock/Record`).

## 2026-07-01 — realism gradient settled + merged FSA|AC permission gate BUILT

**Realism gradient (the honest boundary — a green offline board must not masquerade as proof the
 live stream won't stutter):**
- pure-JS PCM/model ops → real for the arithmetic|algorithm, blind to the audio subsystem.
- `OfflineAudioContext` → the REAL Web Audio DSP engine (same nodes/resampling/mixing; a scheduling
   gap = real silence in the buffer) but **fake time** — no wall clock, buffer is always ready
    before the playhead, so it CANNOT test the delivery RACE. Gaps it measures are ones I authored
     into the coverage model, not ones that emerged from a losing race. Proves correctness-GIVEN-a-
      -modeled-gap; that's all.
- online real-time `AudioContext` → the ONLY mode with real time, hence the real race. Meter the
   race with an `AnalyserNode` on the GRAPH (not the speaker) → a device is NOT needed to measure,
    only to hear. **OPEN PROBE (decides the whole audio-runner design):** does the flag-launched
     fleet (`--autoplay-policy=no-user-gesture-required`, null/fake sink, no output device) advance
      `currentTime` at real-time rate? If yes → the automated real-time-race test needs NO gesture,
       NO human tab, NO Brink babysitting — runs on the plain flagged fleet forever. One-shot probe:
        online ctx → resume() → state==='running'? currentTime advances over a real ~1.5s? analyser
         RMS on a synth tone? (build a tiny Book/Mixer fn + run on remote runner).

**Runner audio-capability model (DESIGN, not built — the dispatch/supply side):** split durable
 INTENT from ephemeral FACT (resolves "runner reloads and loses the quality"):
- tickbox → blessed on the `%Identity` (`Waft:Cluster/%HostedIdentity`, which already carries
   role/friendly/favourite_client) = durable "this runner AIMS to provide AudioContext". Survives reload.
- per-load probe → advertise `%RuntimeFeature:AudioContext` **only while actually live**; drop it +
   raise a Brink complaint ([[upkeep-errand-brink]]) on de-permit. Ephemeral is CORRECT here (dodges
    the non-ephemeral advertise outbox-leak gotcha [[clustation-identity-layer]]).
- demand side = `^^What/RunnerAdvice` on the Credence tree (walk-up), dispatch matches it against the
   LIVE feature ad (never the intent). Pool of ~5 blessed tabs → self-healing, hours unattended.

**BUILT — merged FSA|AC permission gate** (`src/lib/O/Otro.svelte`, the ?E=|?B= shell; type-clean,
 MusuStream 5/5 green on runner 77e2fe = shell still boots; GESTURE BEHAVIOUR browser-verify-owed —
  can't test a human tap headlessly). ONE fullscreen FaceSucker button, always labelled "📂 open
   share", gates on `disk_gated || ac_wanted`:
- `ac_wanted` is event-driven off `AudioContext_wanted` (a blocked `SoundSystem`/gat fires it via
   Musu_gat/GatHaving) → **"picky only when expecting AudioContext" needs NO capability flag**: the
    event only fires if audio was actually attempted, so a runner that never plays grows no audio gate.
- `open_share()` kicks BOTH the AC resume|init AND the FSA picker off SYNCHRONOUSLY inside the click
   (Chrome keeps AC suspended / refuses the picker unless each is initiated in the gesture), awaits
    after. When the share is already open it SKIPS the picker → tap just disperses the audio gate
     ("have FSA, need AC" case = the user's ask). One click does both when disk is gated.
- `GatEnabler` (the old separate top-left "tap to unmute") is mounted ONLY in `src/lib/p2p/Intro.svelte`
   (the production streaming surface) — NOT on the Otro ?B= shell, so no double-UI; left as-is for the
    plain listener tab. On the runner surface Otro's gate is now the one that helps.
- self-heals on a flagged container: Musu_gat fires the event (AC_ready false) then awaits init(); if
   the container auto-starts AC, AC_ready→true and the 400ms poll flips ac_wanted false → gate hides.
   NEXT (deferred, user's call): the capability model above (tickbox→Identity→RunnerAdvice dispatch) +
    the real-time probe + a real-time delivery-race Book that lives under the audio `RunnerAdvice` limb.

**BUILT — the `%hasAudioContext` tickbox** (IdHatch had a literal placeholder comment reserving the
 spot next to socklog, line 115 — the codebase anticipated it). Type-clean, MusuStream 5/5 green
  (runner un-ticked → unaffected). Three files:
- `src/lib/boot.ts` → `has_audio()`/`set_has_audio(on)` = localStorage `hasAudioContext` (per-tab,
   survives reload, browser-guarded), the DURABLE INTENT. Sibling to boot_param; same "takes effect
    next reload" model as socklog.
- `src/lib/O/Funk/IdHatch.svelte` (the 🪪 Cluster-identity FaceSucker) → a `.flag` toggle "🔊 provide
   AudioContext" beside "socklog capture". Placed here because IdHatch is where a tab BECOMES its
    %Identity, so its capabilities are declared here. (For now localStorage per-tab, not yet written
     onto the %Identity/advertised as %RuntimeFeature — that's the deferred dispatch/supply build.)
- `src/lib/O/Otro.svelte` → `const want_audio = has_audio()` (once/load). ac_wanted gained a proactive
   branch: a ticked tab shows the gate whenever `!H.c.musu_gat || !AC_ready` (before any Book AND after
    a de-permit). open_share ensures+wakes H.c.musu_gat (the SAME voice Musu Books use) — created INSIDE
     the click so the AudioContext is born within the gesture. So a ticked runner shows "📂 open share"
      on load; one tap resumes → gate hides → lands audio-ready. Un-ticked tabs unchanged (event/disk only).
   GESTURE BEHAVIOUR still browser-verify-owed (needs a human tap at a real ticked tab).

## 2026-07-02 — demand-driven audio interception (proactive nag DROPPED) + UNTRIED verdict

User rejected the always-on proactive popup: a runner "hardly ever does AudioContext tests", so it
 should NOT nag. Instead — DISCOVER the need by intercepting the gat request, sit ~60s (popup on the
  tab + report to the run authority), then ABORT the test. Key design points that landed:
- **Third verdict category "UNTRIED":** `!ok`, has an `error`, but NOTHING WAS TRIED (no assertion
   ran). Must read as "couldn't run here", NEVER "the audio delivery is broken" — same honesty line as
    offline-vs-real-time. Distinct from a normal red.
- **Discovery by interception, no `needs:audio` tag:** the test just calls for the real voice; Story
   catches the ask. A Book never declares it needs audio.
- **Soft vs hard gat (the subtlety I surfaced):** showcase beats (MusuTune_show / MusuRadio_play) call
   the SOFT `Musu_gat` only to play audibly for a human — their assertions run offline — so they must
    keep silently skipping, NOT abort. Only a HARD demand (assertion truly needs real audio) intercepts.

**BUILT (dormant + guarded — inert for every existing Book, so it CAN'T regress; type-clean = baseline
 House-method noise only; MusuStream 5/5 green on runner 77e2fe = non-regression after the runner
  reloaded + re-eatfunc'd Story):**
- `src/lib/O/Otro.svelte` — **REVERTED the proactive gate** (dropped `want_audio` branch + the
   proactive gat-create + the SoundSystem/has_audio imports). Back to purely event-driven `ac_wanted`
    = `pending_gats.some(!AC_ready)`. So the popup ONLY appears when something fires the demand.
    (tickbox + boot.ts helpers KEPT — now dispatch-intent only, no local popup effect.)
- `src/lib/O/Story.svelte` `snap_step_after_wave` — **generic UNTRIED verdict:** `if (w.c.step_blocked)`
   → step.sc.{ok=false, untried=true, error=why}, skip the dige compare, drive on (runner doesn't
    halt). Generic — audio is merely the first caller; `step_blocked` rides w.c (off-snap).
- `src/lib/O/Story.svelte` `Story_demand_audio(w, secs, work)` — the HARD demand (H eatfunc method).
   Probes/creates `top_House().c.musu_gat`; if cold fires `AudioContext_wanted` (Otro's gate catches
    it → "open share" on the tab) and uses **`expecting(w,'audio_demand',secs, …)`** (the ttlilt helper
     I built) to SIT: its async polls AC_ready ≤secs → granted → `await work(gat)` (test runs); else
      → `w.c.step_blocked='AudioContext not granted'` → the UNTRIED verdict. Fire-and-forget (expecting
       is non-blocking; the ttlilt holds Story's snap). The `work` closure is why resume works cleanly:
        the real audio work runs INSIDE expecting so the ttlilt holds Story until it finishes (no
         snap-before-work race). Report-to-rungo for now = poll_step's step_stall blips during the sit +
          the UNTRIED verdict in the run's step record (runner_ask steps); an explicit `awaiting_audio`
           phase is a later nicety.

**OWED (the next focused step — all bundled into ONE .g recompile):** (1) a CALLER to exercise the
 abort path live — either the future real-time-race Book or a tiny demonstrator Book with a short
  timeout (e.g. 3s) so it's fast to verify; abort path is unexercised until then. (2) soft `Musu_gat`
   DE-NAG in Musuation.g — stop it firing `AudioContext_wanted` (+ canonicalize its cache to
    `top_House().c.musu_gat`) so a showcase beat doesn't pop the gate on a human tab. (3) RESUME path
     (grant within the window → test runs) is browser-verify-owed (needs a human tap). DSL risk noted:
      passing the `work` closure from a .g beat may hit the g-authoring closure gotcha — if so, the
       caller Book's audio logic lives in a .svelte ghost, not the .g.

## 2026-07-02 (later) — PIVOT: AC secured PRE-RUN (front door), not during a step

User: "we must know if the testrun needs AC and make sure we have it BEFORE beginning, so we don't have
 the wait-for-AC as part of the run. FaceSucker on the runner, Brink-complain on the editor." So the
  during-run `Story_demand_audio` (last section) is SUPERSEDED for the primary path — the wait moves to
   the run's front door. (`Story_demand_audio` + the generic UNTRIED verdict left dormant/harmless; the
    UNTRIED verdict may still serve a per-step block later.)
- **Marker = `%Storying,needAC`** on the Credence board cell: `wormhole/Credence/toc.snap` →
   `Funkcion:Storying,of_Book:MusuRadio,needAC:1` and `…,of_Book:MusuTune,needAC:1` (both have audible
    play steps: MusuRadio_play / MusuTune_show). Flat marker — NOT the hierarchical `^^What/RunnerAdvice`
     (user: "forget the hierarchical property for now").
- **Gate = `Lies_become_book_drive` (LiesFunk.svelte)** — the runner's SINGLE run front door (both the
   editor's become_book AND `runner_ask run` land here, BEFORE Story starts). New `Lies_secure_audio(w,
    book)`: probe/create `top_House().c.musu_gat`; if cold → FaceSucker on this tab (AudioContext_wanted
     → Otro's gate) + `Lies_runner_phase(w,'awaiting_audio',{book})` (Brink-complain up to the editor) +
      SIT ≤60s for a human tap → live → begin the run; lapse → refuse to begin + phase `audio_blocked`
       ("nothing tried", NOT a failure). Because it's before resetStory, the AC-wait is outside every
        step's clock — the run's timing/verdict is never entangled.
- `Lies_become_book_recv` now passes `!!frame.needAC` through. Type-clean (baseline House noise only);
   MusuStream 5/5 green on 77e2fe (non-regression — all OTHER callers pass 2 args → needAC=false → no
    gate → unchanged; async fire-and-forget).
- **The %rungo/authority sense:** the gate is the run's front door on the runner; the `%rungo`/editor
   holds the wait (run doesn't begin). Confirmed with user that `%rungo` "takes over" the AC-securing.
- **OWED — the editor/networking-agent half (their territory, user runs it in parallel):** editor reads
   `needAC` from Credence and passes it in become_book (today only `frame.needAC` triggers the gate — via
    editor path; `runner_ask run` at LiesFunk:1084 passes 2 args so it doesn't gate → verify via editor
     or add `!!ask.needAC` there) + surface the `awaiting_audio`/`audio_blocked` phases on the editor
      **Brink**. Cross-tab FOCUS caveat (`<a target>`): only works if the editor OPENED the runner tab;
       for independent tabs use runner self-signal (title/favicon) or SW+Notification. Also still owed:
        soft `Musu_gat` de-nag in the .g (so a showcase pop doesn't double the pre-run gate).

**SPEC written → `src/lib/O/spec/NeedAC_spec.md`** — *FINISHED + DELETED 2026-07-03; the needAC arc +
 its design tails (D1 %rungo, lapse policy, RunnerAdvice, cross-tab focus) now live in
  `spec/Runner_quality_handover.md` loose ends.* (Was: for the Networking + Lies agents; it intersects a
 lot). Diagnosis of "still pops mid-Story, nothing in Brink": the marker is authored in Credence but
  NOTHING reads it and carries it to the runner — `Lies_send_become_book` + `storying_run` don't read
   `needAC`, `runner_ask run` passes none → the runner gate's `frame.needAC` is always undefined → never
    fires → MusuRadio runs normally → step-4 SOFT `Musu_gat` pops (never de-nagged). Runner gate =
     built but STARVED + hung on become_book not %rungo + old soft-pop remains = "half sorted". Spec's
      ownership split: me (runner gate ✓ / runner_ask needAC / soft de-nag / UNTRIED verdict), Lies
       (read Credence needAC at launch, route Book runs via %rungo), Networking (%rungo/become_book
        carries needAC, editor Brink surfaces awaiting_audio/audio_blocked). Open D1-D4 in the spec.

## 2026-07-02 (evening) — NeedAC WORKS end-to-end (user-confirmed: FaceSuckers up front)

- **De-nag**: `Musu_gat` (Musuation.g) no longer fires `AudioContext_wanted` + canonicalized to
   `top_House().c.musu_gat` (recompiled via LocalGen). Soft/showcase path never pops — the pre-run gate is
    the only pop. (The step-3 pop was soft Musu_gat.)
- **Threading needAC → runner**: `storying_run` passes `needAC: funk.sc.needAC`; `e_Lies_become_book` reads
   it → `Lies_become_book_drive` (local) / `Lies_send_become_book` (frame `{book, needAC:1}`) → recv → drive
    gates. (Sweep path LiesFunk:1658 left un-gated on purpose — sweeps run needAC books' offline assertions.)
- **Editor Brink beg**: `Lies_run_phase_recv` raises Upkeep `%Errand{kind:'audio'}` on `awaiting_audio`
   (🎤 "needs AudioContext · <book>", Upkeep.svelte new audio case), settles on next phase (story_begun→ok,
    audio_blocked→failed), guarded by `oa({Errand:key})`. Runner also raises one in `Lies_secure_audio`.
- Type-clean; user CONFIRMS runner FaceSuckers at the beginning.
- **OPEN — `<a>` jump-link editor-Brink→runner-tab:** blocked on (1) which-runner (run_phase `from:<pub>`
   demux, networking-deferred; `w.c.run_phase` is a single slot) + (2) `window.name` targeting only FOCUSES
    an existing tab if the editor OPENED it (same BCG) — independent/dockerised tabs get a NEW tab; fallback
     = runner self-signal (title/favicon). Lands once runners are editor-spawned + from-attribution is in.
