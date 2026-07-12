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
Dated session diaries live in `history/Radio_buildlog.md` — this section stays a BRIEF, not a log.

**NOW (2026-07-13, post-push): three §10.2 gears LANDED compile-clean (live-gate owed on all);
 the Booth/Ban thread is VETOED-and-parked; persistence is ruled — §11.7 (the Berth).**
 - **Landed in the working tree** (opus-agent waves; every .g LocalGen-green): **#1
    stream-to-disk** — `Heist_land` streams each %Body via a new `nav.bin_append`
     (Housing.svelte.ts:2260) behind a capability probe (FSA streams; OPFS/remote/node fall back
      whole-buffer, `<`), verify-after-write vs body_hash, breach → delete + tally. **#2
       metadata + the real tree** — the census feeds its body_hash bytes to
        `Crate_meta_from_tags` (WAV INFO + ID3v2.3/2.4) and lands at
         `<genre>/<Artist>/<Album>/<Title>.<ext>` (album-less drops the level; genre stays the
          top folder — that fork is still the human's). **#3 partial** — `held,tune:` surfacing
           on the job per already-held skip + `Heist_manifest(job, mir, lib)` → [{path, verdict}]
            (the look-before-you-commit; resume side `<`).
 - **VETOED**: the %Tombstone→%Ban rename (host checkout reverted Heist.g/Heistation.g/LiesLies
    to the tombstone baseline — LEAVE IT). `Booth.g` exists unwired/unenrolled — read §11's
     STATUS block before touching anything taste-shaped.
 - **FRANKEN-FIXTURES (urgent, 2026-07-13 late)**: the accepted MusuHeist fixtures record a
    CROSS-WIRED HUNG run — the tab ran the stale `encore` Book gen (HMR'd in before the host's
     checkout) against the `tombstone` engine gen: the flow's completion read `banned` (never
      written) while the engine tallied `tombstoned` → the retomb job hung at skipped=7 from step
       ~19 to 42. Proof in the fixtures: `offered:encore` + `reached:job_encore` present;
        `heisted:retomb`/`flattened` ABSENT — see #11 silently vanished from the roster. Recipe:
         RELOAD the tab (kills stale gen) → clean run → TRIM the toc to last-edge + ~3 headroom
          (the 42-seed leaves ~18 dead steps — the human: "just sitting there from step 20") →
           re-record + accept + confirm the see roster. Also landed meanwhile: `bin_append` is a
            FULL 4-backend contract (the host built OPFS/node/remote + the serve op; agent-audited
             correct, old-editor degrade honest) and @noble/hashes rides `Heist_land` as an early
              wire-hash tripwire (`Hashly.ts`; the read-back stays the unconditional
               bytes-on-disk gate).
 - **THE LIBRARY CATCH** (the human: "didn't we have a library for that?"): package.json ships
    **music-metadata@11** — the hand-rolled tag parser in Crate.g duplicates it. Swap
     `Crate_meta_from_tags`' internals to an IMPORT() of music-metadata (parseBuffer; the
      .g-imports-ts pattern exists for exactly this). KEEP `Crate_wav_with_tags` — the WRITER —
       music-metadata cannot write tags and tests must synthesize tagged files.
 - **OWED, in order (the next fork's fleet)**: (1) **Book scenes** for the landed gears —
    manifest-counts scene, held_named on the reuno row, the tagged-WAV tags-beat-filenames scene
     (synthesize via Crate_wav_with_tags into the share at census + delete at flat; count cascade
      uno 2→3 / reuno+retomb 8→9 / skipped 7→8 / no_reland 7→8 / newlyadded uno 2→3 — TRACE ALL),
       a `streamed:1` telemetry marker on the uno row iff nav.bin_append existed; a first attempt
        died at the session limit mid-edit and was REVERTED — re-run clean. Steps grow ~42→~52:
         re-seed the toc THEN reload the runner (total:1 bomb). (2) the music-metadata swap.
          (3) **the Berth** (§11.7) — build + a Book scene proving reset-with-Story. (4) **the
           live gate**: LocalGen sweep → CHECK on 49de → accept (pre-pin the 11 sees; expect big
            path churn — every landing deepens by Artist[/Album]) → sabotage-proofs (tombstone
             door → false must drop see #11; a wrong body_hash must breach not land). (5) then
              §10.2 #4 the single-track/want-driven session (the anti-klepto front door +
               Waft:Map advice, §11.7), #5 repointable, similarity-upgrade.

 **Bombs a fresh fork must hold** (durable homes: §2 wiring bombs, §1.5 Book discipline):
  LocalGen for spine `.g` edits, never ghost-compile Ra.g against a live editor (§2);
   new Book = seed the toc THEN reload the runner + register in Credence (§2);
    always `--runner=<prefix>`; pre-pin the `%see` set before any accept and confirm after (§1.5);
     sealing Books show PERMANENT benign ≈ on grafted seal fields — do not chase caveat:0 (§1.5);
      the host commits mid-session — re-check the tree after HEAD moves.

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
        the job                -- %Heist,at:<pier> + optional match (absent = klepto = everything); filings pinned as DATA.
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
        flatten                -- the %Heist + mirror delete; nothing attributes who gave what afterward.
        < cohort / cafe (rungs 2-3)  -- one page-stream to N kleptos, then a LAN broadcast tree.

      the app surface  -- where a person drives it.
        < create-a-heist       -- a gesture that points a %Heist at a Pier (today ONLY the test Book mints one).
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
- **Flatten-off.** The `%Heist` (+ its `%filing` decisions) and the quarantine mirror delete; collections +
   `newlyadded` remain and neither says who gave what.
- **Design/test split.** The machine is first-class on `w` (Peerings/Piers/Grants/Idzeug/Libraries/%Record/
   %Body/%Heist/mirror); every test observation hangs under `w/%testing` (the `heisted:<nick>` node with its
    `on_disk` monitoring, `census`/`sealed`/`newlyadded_shape`/`denied`/`flattened`, the 10 `%see`). Snap reads
     as machine-left, opinion-right.
- **Determinism + hygiene.** The engine stamps NO test markers on the world (a transient FSA hiccup no longer
   leaves a permanent marker). The marrauding namespace `.jamsend/test-marrauding-of-bookrun/<nick>` is swept
    files-only at BOTH start and end (`.jamsend` is gitignored; the repo never keeps WAV bytes; dirs persist
     empty so the next run's FSA handle cache is not poisoned).
- **The wire is loopback** (`Lake_link`, see §10.1): real protocol, mock carrier.

**The edge — what's `<` unbuilt:**

- `<` **Metadata from tags.** Artist/title/album come from the FILENAME (`Crate_meta_from_path` splits
   `Artist - Title.ext` / `Artist/Album/NN Title`). Nothing reads a container tag, and the test tones carry
    none. Real path: read RIFF `INFO`/ID3 where present, fall back to filename — or filename-first with tags as
     an override.
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
- **Remembered denials — BUILT + accepted as `%Tombstone`, being REBORN as `%Ban` on the Booth (§11).**
   A dropped identity used to re-offer on a later heist (catalog dedup skips only what is HELD); now the
    listener's drop mints a standing refusal the door consults beside `Heist_held`. The first cut shipped
     live-green but its DESIGN was rejected (unexplained name, heist-local thinking) — §11 is the settled
      family; tier 1 (§11.5) migrates this gear onto `Ghost/M/Booth.g`.
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
2. `<` **metadata**: filename-first + tag override, and the real `$artist/$album/$track` landing tree
    (retires the `4t-` prefix).
3. `<` **merge-into-existing** + "already have" surfacing + the directory-listing confirmable — these
    three are one feature: a real library tree the heist reconciles against.
4. `<` **single-track play/skip/decide** session.
5. `<` **repointable** mid-heist.
6. ✓ **remembered denials** — BUILT + accepted; REBORN as `%Ban` per §11 tier 1 (in progress);
    `<` **similarity / format-upgrade** still open.
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
    collection — an opinion belongs to the collection, not to any job, so it survives every %Heist
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
- **API** (a small verb set; home it where the first consumer lives, NOT a new organ ghost):
   `Berth_open(nav, root, prepub, name)` → deWaft the snap into a live C tree (mint empty when
    absent); `Berth_save(nav, root, prepub, waft)` → enWaft + bin_write (whole-file replace —
     these documents are small; crash-safe temp+rename is a `<` later gear);
      `Berth_reset(nav, root, prepub, name?)`.
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
