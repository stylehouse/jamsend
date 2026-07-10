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

A rolling brief: the newest work sits here first, then gets baked into its home section
 (§3.x, §9) once it is no longer "latest". An empty §0 means the doc is caught up.

**BUILT + LIVE-CHECKED 2026-07-10 (late) — FOUR OWNER RULINGS folded in on top of the chunk-particle
 rebuild (all four Books re-ran on the live runner after: EVERY %see minted, now 24/24 — Stock 6,
  Cast 6, Term 5, Stream 7):**
 - **`Ra_preview_secs` is a PRODUCT CONSTANT now — 32, hard-coded, no `w` param** ("a huge constant,
    not something a Book decides"). NOT 33: the boundary must sit on the want-page grid (seg 2s ×
     PAGE 2 ⇒ multiples of 4s) or P is odd, the pre-ask clamp strands the tail chunk and "first
      stream want == seg P exactly" is unmintable (the even want-stride never visits an odd P).
       MusuRaStream's 12s Book-window died with the knob; its cycle just runs longer inside the same
        40 steps (live: ask@head14, want=16==P, fed@18, switch@20, `a_drops=0 b_heard=0 lufs=-14.01`).
 - **Radiostock files are `<ts>-<pub>-<enid>.jamsend_radiostock`** (awkward extension on purpose —
    nothing in `.jamsend/` may read as media). `ts` = mint time, so old ones can be DELETED (newest
     wins; `Ra_stock_find` GCs older twins in passing, `Ra_stock_gc` also drops superseded renders of
      the same path after a build). `pub` = the OWNING Peering's pier key — many Piers share one
       `.jamsend` in tests and each filters for its own (`Ra_stock_ls`). `enid` = **sha256 over the
        whole source bytes, first 16 hex** — content identity, no pub, no path: a record is never
         locked to the Pier or location that found it ("we pull in entire tracks and dige them").
          `Ra_id` (path-djb2) and `Ra_bytes_hash`/`src_hash` are DEAD — the id IS the content hash.
           A one-shot MIGRATION sweep in `Ra_stock` deletes legacy `*.jam` stocks (remove the block
            when shares are clean).
 - **NO friend-download cache** — `Ra_term_stash` + `.jamsend/downloads/<friend>/` DELETED (reverses
    §9.1b's downloads corner): pulled chunks are EPHEMERA; a Peering keeps radiostock of its OWN
     collection only, for the speedy run-around; actually moving music is a later economy — this is
      just listening. (The Stream Book's stash row + its %see died with it: 24 sees, was 25.)
 - **The DEAD-SOURCE RULE** — a radiostock whose source can't be found anymore can never make up its
    %Stream, so it is litter: `Ra_source_pcm` drops the file (`rec.c.card_file`, remembered at
     `Ra_card` load) and returns null; a later pass re-stocks what the collection now holds.
 DONE 2026-07-11: the re-record of all four LANDED — Stock/Cast/Term by the owner, Stream via
  `runner_ask accept` (7/7 %see pre-pinned and confirmed present after — the drop-hazard didn't bite);
   verify re-runs ALL GREEN: Stock 5/5, Cast 12/12, Term 12/12 **caveat:0**, Stream 40/40. The caveat
    signature is now understood: a Book that SEALS shows permanent benign ≈ on exactly the
     AudibleEntropy-grafted fields (Pier `since:` / Grant `time:`+`sign:` / Edge `at:` — tol:any
      TOLERATES change, it does not canonicalize, so re-runs always ≈ there); Term seals nothing ⇒ 0.
 PRESKIP now has its one coherent statement in the code — the
   `Ra_encode_open` comment (it is the opus encoder's convergence ramp the decoder drops at each fresh
    open, 312@48k; it WOULD ride OpusHead bytes 10-11 but we deleted the container, so we carry it on
     the card + the two head chunks; NOT a time offset — time-into-track is seq × seg_secs).

**BUILT + LIVE-CHECKED 2026-07-10 (same day, forks all ruled — (c) demand-driven per owner) — the
 preview economy REBUILT on REAL CHUNK PARTICLES + generic Repli.  All four MusuRa\* ran on a LIVE
  runner same evening: EVERY %see minted (25/25 — Stock 6, Cast 6, Term 5, Stream 8) — Cast's pulled
   row read `chunks=39 parked=12 unparked=12` (the demand economy end to end), Term read
    `healthy=0 gaps / starved=320 / lufs=-14.03` (one-decoder continuity: PERFECTLY gapless), Stream
     ran the whole arc (ask at head 4 inside the preview → first want seg 6 == P → fed at 8 →
      owner-act switch at 10 → B full fresh cycle → `a_drops=0 b_heard=0 lufs=-14.03`) with IDENTICAL
       numbers on a rebuild-run and a resurrect-run.  Re-record DONE 2026-07-11 (see the block above).
        WHAT SHIPPED:
   Repli.g gained the three generic things below (binary `.sc` buffer leaf + `bufk` restore, husk
    offers, `w.c.repli_allow` consent, particle-mode `page_ready`/`serve_chunks` — Float32 path
     untouched, MusuReplica/MusuReco unaffected); Ra.g lost the WHOLE `Ra_cast_*` wire + the RFC-7845
      Ogg mux and gained ONE-encode-per-side (`Ra_encode_open/feed/drain` + `Ra_chunk_cut` at the 2s
       grid, u16-length-prefixed packet framing, `fmt:'pkt'` .jam bump so old stocks rebuild once) +
        the demand-driven transcode (`Ra_transcode_ensure/advance/pump` — a PARKED want ignites it,
         it runs to completion at the encoder's real pace; `racast_rate` is DEAD) + the chunk-map
          terminal (`Ra_chunk_map`/`Ra_term_decode_pulled` decode RUNS through one AudioDecoder,
           split at `head` chunks, preskip dropped there; pipelined page wants in the stream beat);
            Radiation.g's four Books re-drawn on Repli_arm/repli_allow/Ra_transcode_pump (MusuRaStream
             now proves fed-past-boundary then the OWNER ACT — hit next track → B runs a full fresh
              cycle from seg 0; the engineered starve claims died with the rate flag).  LocalGen'd
               clean (never ghost-compile Ra.g against a live editor).  The design that ruled it:**
 The preview economy (the BUILT block just under this one) worked — the owner's live MusuRaCast run
  crossed 17 preview + 22 stream = 39 — but it hand-rolled a parallel wire (`sizes[]`/`seg0` page
   headers, `rec.c.segs`, `have=` counters) that duplicates what Repli does generically AND hides
    the payload off the observable plane (`.c.segs` is invisible without our tools). Owner's
     verdict: *"how will Repli be generic if it has some .c.bollocks array to manage as well?"* +
      *"I just want multiple real actual %Record/%Preview"* + *"lots of particles in snap+Cyto is
       fine"*. So the rebuild:

 - **The principle:** *what snaps, replicates.* Chunks become REAL child particles; their bytes
    ride a `.sc` value. Verified at `src/lib/O/Text.svelte` enLine: an object/typed-array in `.sc`
     is NOT fatal at SNAP — it routes to `objecties.ref[k] = objectify(v)`, a muted description
      (`"Uint8Array()"`, ~12 bytes), visible on the observable plane. (CLAUDE.md's "fatal at
       encode" is the STORAGE/toc encoder — you can't resurrect bytes from a description — NOT the
        snap encoder. Disk home stays the `.jam`; a library subtree with sc-bufs must never ride a
         Waft toc-persist. State this at the edit site.)

 - **The shape** — the OLD flat shape (owner: "they used to get 15 %Previews and a hundred or so
    %Streams"): chunk particles are `%Preview,seq` / `%Stream,seq` DIRECTLY under `%Record`, no
     config-head layer:
    ```
    Record,id:848b,title:Cosmic C,artist:DJ,seconds=78,lufs=-7.33,gain=-6.67,sr=48000,br=128000,seg_secs=2,real
      Preview,seq=0,head   {ref:{buf:"Uint8Array()"}}   ← opens the preview decoder
      Preview,seq=1        …
      …                    (17 Previews — Cyto CRUSH folds the sprawl)
      Stream,seq=17,head   {ref:{buf}}                   ← SEPARATE encode → opens a 2nd decoder
      Stream,seq=18        (come into being as the frontier transcodes — you WATCH them land)
    ```
    Global seq continues across the boundary (first `%Stream.seq` = last `%Preview.seq` + 1, the old
     contiguity). The `head` flag (1-or-absent) marks the two boundary particles where a decoder
      opens. `have=` DIES — particle presence IS fill state; resume-from-partial is free (want the
       first missing seq you can see). Wear (§9.6) = delete the buf, keep the husk chunk ("was here,
        released").

 - **Cast DISSOLVES into Repli.** `Ra_cast_offer/catalog/serve_want/recv_*/tally/page_out/pull_record`
    all DIE → Repli. Repli gains three GENERIC things (nothing Ra-specific): (1) an `.sc` binary
     value is a buffer leaf — extend `Repli_lines_of`'s existing `.c.page_bytes` trigger to any
      `Uint8Array`/`ArrayBuffer` `.sc` value (Float32 `.c.page_bytes` path stays for
       MusuReplica/MusuReco); (2) a consent hook `w.c.repli_allow?.(peer)` in serve (my
        `racast_allow` generalized — also the Keep's seam §9.7); (3) NOTHING for the frontier —
         `Repli_page_ready`/`Repli_park_want`/`Repli_serve_parked` ALREADY model "a want that
          outran the producer PARKS, releases as the frontier advances" (MusuReco's bow wave).
       So the whole economy falls out of park/serve: **preview chunks pre-exist** (minted from the
        `.jam` at stock/resurrect) → preview wants serve instantly, never park. **Stream chunks
         don't exist until transcoded** → a stream want PARKS; the parked want IS the demand that
          drives `Ra_transcode_advance` (decode source once, gain off the card, fresh encoder per
           2s, mint `chunk,seq=N` with bytes); serve-parked releases as chunks appear. `racast_rate`
            dissolves into the encoder's real pace — the starve is the playhead outrunning a parked
             want, not a flag. The boundary needs NO server enforcement: nothing past preview
              EXISTS until a want parks for it. (`held_past` probe stays as the witness it holds.)

 - **ONE encode per side, chunks are transport slices, ONE decoder per encode** (owner 2026-07-10:
    "one opus stream that blobs into several %Preview that hop sides and concatenate into a single
     decoder on the other end... the %Preview->%Stream jump will have another header of course, as
      that's a separate encode"). The preview is ONE opus encode (at stock); its bytes slice into the
       `%Preview` particles; far side concatenates IN ORDER, feeds ONE decoder → continuous PCM, NO
        per-chunk boundary so NO glitch (the decoder holds state across the whole preview because it
         IS one stream). The stream is a SEPARATE encode (on-demand transcode, boundary→on) → its own
          decoder, its own header at the `head` chunk. TWO decoders per track, reset only at the seam.
       A chunk's `buf` is a byte-slice of the one encode at a packet boundary; keeping self-framing Ogg
        pages vs stripping to raw length-prefixed packets is a small IMPLEMENTATION choice / clean
         follow-up (owner's earlier "delete the RFC-7845 mux"), NOT a design fork. (Deleted from the
          earlier draft: "fresh encoder per 2s / per-chunk independence / per-chunk decoder / glitch
           fallback" — that solved a problem THIS model doesn't have. A single continuous LIVE-EDGE
            encode is a later mode, orthogonal.)

 - **The ramp** ("gently the first 4s then quickly more") needs no new mechanics: fixed small server
    stride (`repli_page=2` chunks = 4s, keeps parked offsets aligned) + terminal pipelines wants up
     to its ahead-window (old `STAY_AHEAD_OF_ACK_SEQ`). First page → play on ~4s → wants pipeline →
      buffer fills fast. TCP slow-start worn as want-pacing, every step a chunk landing in a snap.

 - **Survives:** `Ra_stock` + the `.jam` format (preview-only, whole-track LUFS/gain card — it now
    ALSO mints the 17 preview chunk particles), `Ra_lufs`/bake, `Ra_term_stash` (pack preview chunk
     bufs → `downloads/<friend>/`), `Ra_term_spool`/`Sound_measure`, the Book arcs, AudibleEntropy.
   **Dies:** all `Ra_cast_*` wire, `rec.c.segs`, the Ogg mux (→ stock-legacy). `Ra_term_decode_pulled`
    becomes "decode the chunk particles present, silence where absent" via the raw-packet decoder.

 - **Book arc:** MusuRaCast = offer → preview pull → boundary ask → parked-want transcode completes
    → per-frame `body_hash` still pins byte-identity → revoke via `repli_allow`. MusuRaStream = the
     session, ~40s proving the stream FEEDS PAST THE BOUNDARY, **then track B from seg 0** (a full
      fresh preview→ask→stream cycle on the change — owner: "hit the next track which should then
       %Stream from the start"). All four re-record (already owed).

 - **FORKS** — all RULED. (a) FLAT (owner 2026-07-10: chunks are `%Preview,seq`/`%Stream,seq` directly
    under `%Record`, `head` flag on the two boundary particles — no config-head layer). (b) framing
     DOWNGRADED to an implementation detail — built as raw u16-length-prefixed packets (the Ogg mux
      deleted, per the owner's earlier "delete the RFC-7845 mux"). (c) RULED DEMAND-DRIVEN (owner
       2026-07-10, built same day): the stream encode starts when the first `%Stream` want PARKS and
        runs to completion — honours "no-source ⇒ no-stream" and the honest clock; no rate flag.
     Risk ledger: frame count/beat ~40 lines+pages vs today's ~10 fat frames (coalesced delivery
      holds it; `repli_page` is the relief valve; first thing a CHECK run watches); `body_hash` rows
       still pin real bytes (a Chromium libopus drift = a real re-record, not a red herring); a
        missing mid-stream chunk = STALL until filled (the want machinery), decode never runs past a
         hole.

 - **Wider arc this slots into** (so next moves are visible): (1) THIS rebuild; (2) radiostock
    fan-out for real — the listener KEEP_AHEADs *preview records across the catalog* (Radiola's
     `req_restock` on Repli offers) so next-track is instant, the moment "most of a %Record waits on
      the remote Pier" is true at catalog scale; (3) §9.2 Shares / §9.4 multicast gossip / §9.5
       per-peer Sent_Tree (half-built as `Repli_sent_se`) + wear-as-cache on husks + the Keep behind
        `repli_allow`; (4) live edge — the chained-encode second mode + BigSoundland's tuner playing
         a real mirror.

**BUILT 2026-07-10 (morning) — the PREVIEW ECONOMY — MECHANISM SUPERSEDED the same day by the
 chunk-particle rebuild above (the ECONOMY claims below all still hold; the `Ra_cast_*` wire /
  `rec.c.segs` / `have=` machinery this block describes is GONE — read it as the why, not the how).
   (owner 2026-07-08: "Records are always Record/Preview first, those are the parts that cache in
    radiostock/, then Record/Stream involves streaming the track from the point right after the last
     Record/Preview")**
 The Record model went preview-first end to end, drawn from `src/lib/ghost/Radios.svelte` (the
  complication-enforcer: `radiopreview`→`rastream` offset+`preview_duration` contiguity, `streamability` /
   `MIN_LEFT_TO_WANT_STREAMING`, the radiostock preview cache, "don't trust leftover %stream"):
 - **stock** — `radiostock/<id>.jam` now holds ONLY the preview window (`Ra_preview_secs`, default 33s ⇒
    17 segs; the header gains `total` + `preview_secs` + `base`, and standing REQUIRES them — old
     whole-track cards rebuild once). The %Record mints `%Preview,name:opus` (total|bytes — the cached
      part) + `%Stream,name:opus` (**from == the preview's total** — the continuation head, no bytes: its
       segments do not exist yet). LUFS/gain stay WHOLE-track so the seam is loudness-uniform. Standing
        also checks the WINDOW (`preview_secs`), so Books with different windows stay deterministic
         against each other (MusuRaStream shrinks to 12s; the others keep 33).
 - **cast** — `Ra_cast_serve_want` honours THE BOUNDARY: a preview want pages the cached window off the
    .jam and STOPS at it; a want AT|PAST the boundary IS the streaming ask, answered by **on-demand
     transcode from the SOURCE** (`Ra_cast_transcode`: source PCM once per Record with the card's gain
      baked, fresh encoder per 2s seg on the SAME boundaries, cached on `rec.c.stream_segs`) — so
       `racast_rate` now bounds REAL encoder work: the slow transcode clock is honest, and no-source ⇒
        no-stream (the rapiracy economy). Mirror pages land in `rec.c.segs` (ONE index space across the
         boundary); `Ra_cast_tally` keeps `%Preview.have`/`%Stream.have` legible. `Ra_cast_pull_record`
          = want 0 + want P. The dead page-loop in `Ra_cast_send_lines` is tidied (lines only).
 - **term** — `Ra_term_stream_open/beat` got the handoff: want-ahead CLAMPS to the preview window until
    the un-played preview tail ≤ `want_left` (22s ⇒ 11 segs default), then the ask latches (never
     un-asks) and the first stream want is exactly seg P. A fully-held preview HOLDS at the boundary
      (Radios' preview-and-HOLD, emerging). **`Ra_term_decode_pulled`** decodes WHAT THE MIRROR HOLDS
       (missing seg = embedded silence + a listed drop) — the terminal finally decodes the PULLED bytes,
        never the local .jam (the owner's direct question — it did not, now it does). `Ra_term_stash`
         caches a fully-held preview to `.jamsend/downloads/<friend>/<id>.jam` (§9.1b) with a read-back
          proof.
 - **Books** — MusuRaStock asserts the preview-first mint shape (+1 %see); MusuRaCast's whole-pull =
    preview byte-faithful vs the husk-promised `%Preview.bytes` + continuation present in full;
     MusuRaTerm plays ACROSS THE SEAM (cached preview + locally-transcoded continuation through
      `Ra_term_decode_pulled` — LUFS spans the seam); MusuRaStream is the flagship session: preview in →
       HOLD → ask at the floor → stream want at seg P (observed into `stream_ask`/`stream_want` rows) →
        slow transcode clock starves the tail (rate→1 past 40%) → switch → measure ON THE PULLED BYTES
         (`a_heard` vs `a_rest` vs `b_heard` + LUFS off B's pulled render) + the preview stash row.
          Seven %see. Knobs: preview_secs=12 (P=6), cap=20, prime6/floor4/play2/want_left3, rate 4→1.
 **OWED:** a live runner (all three registry keys were dead beacons this session — needs a human tab on
  `:9091`, then `runner_ask run <Book> --watch --runner=<prefix>`), CHECK-run knob tuning on MusuRaStream
   (the starve window), then re-record all four (they share the Record shape; accept order free, but
    pre-pin the %see set per Book — `grep -aoE "%see:'[^']*'" Ghost/Story/Radiation.g`). Gens are
     current on disk via LocalGen (spine-BOMB honoured — no ghost-compile of Ra.g against a live editor).

**STATUS 2026-07-08 — the three-verb pipeline (§3 rastock→racast→raterm) is COMPLETE and live-verified GREEN.**
 All three `MusuRa*` Books re-recorded green under the rename (verdicts in the MusuRaTerm block below). The next
  frontier is Pier reality (§9) — the suggested order is 9.1 real `/music` library → 9.10's spine (one real file
   offer→pull→play) → 9.2 Shares → 9.4 multicast — and §10 Klepto (heist-at-a-Pier). Pick one and go; nothing in §3
    is now blocking.

**Won 2026-07-07 — rastock SHIPS (§3.2, live-verified).** MusuRaStock is green, ttlilt-free, and
 proven on a live runner. Three things landed with it:
 - **The `.jam` stock format** — one file per `%Record`, shaped `json-header + \n + length-
    prefixed buffers` (`Ra_pack`/`Ra_unpack`). Nothing in `.jamsend/` may LOOK like media (it
     lives inside the user's library dir), so a json header + no audio magic replaces the old
      `radiostock/<id>/*.opus` + `stock.snap` spread. Buffers are still ogg-opus blobs for now →
       swapping them for raw Opus packets (delete the RFC-7845 mux) is a clean follow-up.
 - **-14 LUFS uniform, baked** — a src-hash freshness guard (`Ra_bytes_hash`) killed a stale
    cache that had been serving old gains; stock now re-reads whenever source content changes.
 - **`Waft:Trope/Ra/AudibleEntropy`** — a SHARED entropy profile grafting the `%proof` line's
    `ms:r{}d{}l{}` wall-clock noise (`tol:any` on r/d/l only; `seconds`+`lufs` stay literal so a
     real loudness regression still diffs). MusuRaStock Wref's it. ONE consumer today; the moment
      MusuRaCast/MusuRaTerm prove a pulled/played segment they are the SECOND → Wref it, do NOT re-inline
       (owner called this recurrence 2026-07-07).

**Won 2026-07-08 — MusuRaCast SHIPS (§3.3, live-verified GREEN).** The middle verb stands. On a live fsa
 runner: DJ stocked a REAL 39-segment opus Record (Cosmic C, 78s, 1290003 bytes), sealed a mutual Music
  grant, cast the husk; the listener PULLED THE WHOLE RECORD byte-faithful (`have=39 got=39 total=39`);
   a revoke shut the gate (silence). All five `%see` fire at 2/4/6/8/10; fixtures accepted → GREEN. Three
    refinements landed on top of the first working run:
  - **Batched pull (the perf rework).** The naïve pull flooded the belief queue — ~39 `racast_want` + ~78
     line/page frames = ~120 todos, a ~15s beat. Now ONE `racast_want` draws the whole tail and the server
      strides it in `PAGE=8`-segment `racast_page` frames (1 husk-`racast_lines` + ~5 pages for 39 segs).
       Each page carves `frame.buffer` by a header `sizes[]` into `.c.segs[seg]` by TRUE index (sparse-safe);
        `have=got=` count of non-null segs. `self,round` fell 59→17. Knob: `w.c.racast_page`.
  - **Entropy: HARVESTED, not pinned.** The Swarm seal stamps wall-clock into `since`/`at`/`time` + a
     signature `sign`. I proposed pinning `w.sc.now`; owner OVERRODE — there is no clock system to base that
      on, so the pin is DROPPED. Instead the seal-field noise is harvested into `Waft:Trope/Ra/AudibleEntropy`
       (Entcases graft `since`/`at`/`time` `tol:any`; a `{TOK}` swallows `sign` — the crypto is tested
        separately). MusuRaCast Wref's the SAME profile (line 6 of its `toc.snap`) — the SECOND consumer, exactly
         as §3.2 predicted; do NOT re-inline. In a diff these show `Dif:change,spay:graft` = tolerated, green.
  - **beat-6 `%see` FIXED** — it asserted `got===0` (empty husk), but `MusuRaCast_flow` pulls the INSTANT the
     husk lands, so by n=6 `got` was already 39. Now asserts the head ARRIVED (`total>0`).
 Artifacts: **`Ghost/M/Ra.g` `#region cast`** (shared cast mechanics, reuses Repli's byte-agnostic parts —
  `Repli_fragment`/`Repli_merge` + Peeroleum sha256 — and owns ONLY the opus page path, NOT the Float32
   `Repli_pack_chunks`/`unpack_page`; grant gate injected via `w.c.racast_allow` so Ra imports no Swarm);
    **`Ghost/Story/Radiation.g` `MusuRaCast` Book**; `wormhole/Story/MusuRaCast/toc.snap` (12 steps + the Wref);
     `wormhole/Trope/Ra/AudibleEntropy/toc.snap` (the harvested seal Entcases); Credence entry. Both gens on
      disk via LocalGen / `ghost-compile`. UNCOMMITTED (host reviews the diff).
 LOOSE ENDS (small): (a) **general `sign` snap-omit** — owner floated "ignore the signature in snap in
  general" (a protocol-level omit like the body_hash Organ-2 mask) as an alternative to the per-Entcase
   `{TOK}` graft; UNSCOPED — touches Text encode `omit_sc`. (b) dead page-loop in `Ra_cast_send_lines` (the
    husk sender; harmless — empty bufmap) — tidy on the NEXT Ra.g touch, not a standalone compile+record.
**SHIPPED + LIVE-VERIFIED GREEN 2026-07-08 — MusuRaTerm (§3.4, the LAST verb); the Ra*→MusuRa* rename LANDED and all three MusuRa* Books re-recorded green.**
 The terminal that PLAYS: decode the stocked opus back to real PCM and prove honest playback. Ran clean on a live
  fsa runner (12/12 beats, no step errors) and READ THE SNAP: Cosmic C stocked (source -7.33 LUFS + a -6.67 dB
   bake = -14 exactly), decoded whole — `heard,seconds=78,segs=39,lufs=-14,healthy=0,starved=320,dropped=8`: the
    played-back LUFS reads the -14 target BACK (baked gain survived the opus round trip), zero phantom gaps on the
     whole track, and withholding 8 middle segments surfaced as 320 gap-windows (16s / 50ms). ALL FIVE `%see` fired
      at 2/4/6/8/10; every threshold guess held first try; the numbers are deterministic (no Wref, as designed).
       Steps read red ONLY for want of an accepted baseline (the seed diges). Design calls:
 - **Two generic primitives in `Ghost/M/Ra.g` `#region term`** (append, ~lines 809-880): `Ra_term_decode(w,
    nav, id)` reads `<id>.jam` and `decodeAudioData`s EVERY 2s opus segment (the `Ra_proof` per-segment carve),
     concatenating per channel into one continuous track → `{channels, sr, seconds, segs, per}`; `Ra_term_spool(
      channels, per, drop)` downmixes to mono and PUNCHES the `drop` segment indices to SILENCE — the honest
       hole. No new analysis: measurement REUSES `Ra_lufs` (the meter that set the gain) + `Sound_measure`
        (`Ghost/M/Sound.g` — MusuSignal's underrun `gaps` gate). Radiobuddies discipline: no scenario words.
 - **`Ghost/Story/Radiation.g` `MusuRaTerm` Book** — NO transport (crossing is MusuRaCast's proven job; MusuRaTerm stocks
    locally via `Ra_stock` take=1 and plays — the pulled mirror is byte-identical). Beats: 2 STOCK, 4 HEAR
     (one held `expecting`: decode + LUFS + healthy/starved spool renders, cache scalars on `w.c.term`, stamp
      a `heard` row), then witness-only 6 GAIN / 8 STARVE / 10 CLEAN. Five `%see`.
 - **The claims** (`MusuRaTerm_witness`): (2) a real opus Record stands; (4) decoded seconds ≈ stocked source (±4);
    (6) played-back LUFS within ±2 of the -14 target = *the baked gain survived the opus round trip*; (8)
     `starved_gaps > healthy_gaps + 3` = *the spool starved without papering over the hole* (a ~1/5 middle run
      withheld); (10) `healthy_gaps <= 3 && starved > healthy + 3` = the same spool runs clean when whole (the
       MusuSignal not-vacuous guard, redrawn on real stock).
 - **DETERMINISTIC snap, NO AudibleEntropy Wref** (departs from the §3.2 prediction on purpose): decode + LUFS
    + gaps are pure functions of the stock, so the `heard` row is stable run-to-run. The wall-clock `ms` is
     deliberately NOT stamped. Only if the live CHECK shows a field wobble do we harvest it (the MusuRaCast way) —
      do not pre-Wref. `wormhole/Story/MusuRaTerm/toc.snap` seeded (12 `seedNN` step lines, NO EntropyProfile);
       Credence `of_Book:MusuRaTerm,needsFSA:1` registered under `What:mostly` (the renamed home).
 **THE RENAME (2026-07-08, owner call).** The Ra* Book SUITE is stemmed under Musu*: `RaStock`→`MusuRaStock`,
  `RaCast`→`MusuRaCast`, `RaTerm`→`MusuRaTerm` (Book identity + world name + `<Book>_*` fns + `wormhole/Story/<Book>/`
   dirs + Credence rows all done; gen rebuilt via LocalGen). **THE NAMING RULE (owner, 2026-07-08):**
    test-specific Book code is FULLY-NAMED with the long prefix — `MusuRaTerm_witness()`, `MusuRaStock_stock()`,
     `MusuRaCast_seal()`; the shared/common ENGINE in `Ghost/M/Ra.g` stays SHORT `Ra_*` — `Ra_stock`, `Ra_cast_*`,
      `Ra_term_*`, `Ra_lufs` — NEVER `MusuRa_*` (snake). So a fully-named Book method DRIVES a short engine verb
       (`MusuRaTerm_hear` → `Ra_term_decode`), the same way the `Musu*` Books drive `Sound_*`. Consequence: MusuRaStock + MusuRaCast were green as RaStock/RaCast and the name is baked into their
      snaps (`H:RaStock`→`H:MusuRaStock`), so all three go red and re-record together.
 DONE 2026-07-08 (verified this session on the live runner `49dee91d61a9de64`, released after): the tab had been
  reloaded, all three re-ran green, baselines accepted, host committed. Live verdicts — **MusuRaStock** 5/5
   ok_pct:1 (2 entropy-caveats), **MusuRaCast** 12/12 ok_pct:1 (9 entropy-caveats), **MusuRaTerm** 12/12 ok_pct:1
    (0 caveats — deterministic, no Wref, as designed). All five `%see` per Book are installed and recorded (Term
     fires 2/4/6/8/10 on `heard,seconds=78,segs=39,lufs=-14,healthy=0,starved=320`). The pipeline (§3) is COMPLETE;
      the frontier is §9 (real library) then §10 (Klepto). The two BOMBs below stay — they are durable Ra gotchas.
 BOMB 1 — DON'T `ghost-compile` an Ra SPINE-ghost change against a live editor: it HANGS. HMR-remixing
  the depended-on Ra spine into the live runtime wedges it (proven — even a trivial valid method hangs;
   only the pristine no-op hash replies). Leaf Book ghosts (Radiation.g) slip through. Use **LocalGen**
    for spine `.g` edits: `GFILES='Ghost/M/Ra.g' CHECK=1 npx vitest run -c scripts/Story_cli.vitest.config.mjs
     scripts/LocalGen.spec.ts` (browserless, no HMR; drop `CHECK=1` to write the gen). That built `gen/M/Ra.go`.
 BOMB 2 — a brand-new Book runs Prep-only (`total:1`): the runner runs the Book it ACQUIRED AT BOOT and
  CLOBBERS a mid-session disk `toc.snap` seed. So seed `wormhole/Story/MusuRaCast/toc.snap` with ~10
   `step,dige:lieN` lines, THEN RELOAD the runner so Creduler re-acquires it → the beats fire. (Same trap
    for any NEW Book, incl. MusuRaTerm.) Endpoints confirmed live: source `Library,pier:dj.prepub` + mirror
     `pier:lis.prepub` both hold the same Record; sealed `%Pier` routing + `w.c.tx`=`link[0]` all worked.

---

## 1. Destination

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

**BOMB — ghost-compile needs a live editor.** There is no standalone `.g→.go` CLI.
 `npm run ghost-compile -- <file.g>` signs a ticket to the in-app editor on `:9091`, which
  force-loads the dock, compiles, writes `src/lib/gen/<cluster>/<File>.go`, and HMRs it.
   `Ghost/M/Radiola.g → src/lib/gen/M/Radiola.go`; `Ghost/Story/Musuation.g →
    src/lib/gen/Story/Musuation.go`. `scripts/LakeRace.*` exercises an *already-compiled*
     spine headless — it is not a compiler. So: author here, compile in the browser.

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

### 3.2 rastock — uniform stock from the library  — ✓ SHIPPED 2026-07-07 (§0)

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

### 3.3 racast — the stock cast to Piers  — ✓ SHIPPED 2026-07-08 (§0)

Casting is **Repli, never RPC** (the all-pervading rule): the catalog crosses as a replicated
 husk to sealed Piers (the §9.1c re-draw — MusuGot territory), Records cross as Repli pages on
  the pull, and the LIVE edge — hear what I hear NOW — rides `@channel` multicast (§9.4) from
   a station in `role:music`. The grant gates every leg (§9.7): no Music grant, no husk, no
    pages, no edge.
 - **Book: `MusuRaCast`** — a sealed pair; stock stands at A; B pulls one Record whole (pages,
    sha256-verified) and tunes A's live edge; a revoked B hears nothing new.

### 3.4 raterm — the terminal that plays  — ✓ SHIPPED 2026-07-08, live-verified GREEN (§0)

The Musu cursor machinery finally earns its keep as the REAL spool: want-ahead keyed off the
 playhead (§9.3), `decodeAudioData` per 2s segment (a from-zero full-track listen may instead
  ride one continuous WebCodecs decode — the §3.3 live-edge tool pointed at a whole track),
   the uniform gain already baked, crossfade at track joins (MusuMix's deck math). Faces: BigSoundland + the Voro radio tuner as the dial.
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

### 3.6 What is REAL and what is a MOCK in the Ra Books (honest ledger)

Owner asked (2026-07-08) to keep the mock boundary explicit: the `%see` claims say "real opus
 Record", which is TRUE of the bytes but invites a misread. Precisely — **it IS real music
  processing; only the SOURCE tones and the transport WIRE are stubbed.**

**REAL (the substance — genuine audio, not a by-reference stub):**
 - **the whole DSP path** — `OfflineAudioContext` decode → needles K-weighted LUFS meter →
    baked gain → WebCodecs Opus encode → ~2s segments → `.jam` on real disk → `decodeAudioData`
     back → muted Web-Audio playback. The −14 LUFS target genuinely survives the opus round trip
      (MusuRaTerm reads it back). Real bytes, real loudness math, real codec.
 - **the transcode clock (2026-07-10)** — a stream want is answered by ENCODING the continuation
    from the source on demand (`Ra_cast_transcode`); `racast_rate` bounds real encoder work per
     want, so the MusuRaStream starve is a genuine producer-vs-playhead race. (The *rate NUMBER* is
      still a knob — a real deployment's rate is whatever the CPU affords — but the work is real.)
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
      rate against a real transcode clock; MusuRaStream is the Book). Remaining from this idea:
       keep_ahead across RECORDS (the next-track prefetch — radiostock fan-out at the session layer).

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
