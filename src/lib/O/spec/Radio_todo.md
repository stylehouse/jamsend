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

**2026-07-11 (night) — MusuRaChase FIRST-LIT + RECORDED; the whole family green.**
 The CHECK run (all 56 steps, real audio, ~4min) needed NO threshold tuning — every gate passed
  with slack: `chased,at_head=20,warm=16` and `skip:B,at_head=10,warm=16` (gate ≥6),
   `b_heard=0` (gate ≤3, zero drops), decoded `lufs=-14` dead on target. Accepted with the
    %see pre-pin discipline: all 15 Chase sentences survived into the fixtures (verified against
     the pre-pinned set — none fuzz-swallowed). Verify re-runs 56/56 green twice (≈53/≈54 —
      the predicted two-seal AudibleEntropy signature; the ±1 is round= wobble). The owed
       float32-compat runs also green: MusuReplica 14/14 (≈10), MusuReco 11/11 (≈3).
 **Assertion upgrades STAGED, blocked on tab warmth (11:20).** Three of the audit's upgrades are
  BUILT + LocalGen-compiled, fixtures NOT yet re-recorded: `src`+`cands` on the chased AND skip
   rows (Radiation.g — kills both PRNG-luck slip channels; `cands` reads the new runtime-only
    `w.c.ra_dial_cands` stamp in Ra_dial_next), and a post-dark `fanout_dark,of=N` row (gives the
     restock online-gate a line to die on).  Deliberately NOT done: the `keep_ahead=2` pin (with a
      3-candidate catalog it would falsify the fan-out sentence "kept EVERY other preview warm" —
       it belongs in a single-source Book) and the mid-run revoke variant (a new scene, owed).
  RESUME: keep the 49de tab UNFROZEN ~10 min (foreground it / visible window — the browser kept
   freezing it in <2-min windows, killing every dispatch), then: burn-in MusuRaStock → CHECK run
    MusuRaChase (steps ~15/~20 red with the new row fields — verify values sane + deterministic
     across two CHECK runs) → accept → green ×2 → sabotage-prove `fanout_dark` (delete the
      ra_source_live line in Ra_restock_beat, expect red, revert).

 **Adversarial audit (agent + one live sabotage).** The live probe: gate the chase %see on
  `warm >= 99` (Radiation.g:1232 via LocalGen) → the run went RED from exactly step 15 (its landing
   step), then green again on revert — the Book catches its own regression, and a LocalGen disk
    write DOES hot-load into live tabs.  The audit's structural verdict: NO see or marker sits in a
     fuzz-tolerated zone (the ≈53 come entirely from `since:`/`time:`/`sign:`/`round` churn on
      society lines), and a missing/moved line is never swallowable (positional line-zip; length
       mismatch = hard red).  The REAL weakness class: presence gates already satisfied (or never
        challenged) by the time the fixtures were cut — four named slips: (1) `Ra_keep_ahead`'s
         `w.sc.keep_ahead` pin is untested (catalog-minus-playing == the pin, the clamp never
          bites); (2) the restock fan-out's `ra_source_live` gate is dead weight post-dark (every
           preview already whole — deleting it changes nothing); (3) `repli_allow` never refuses
            during a Chase run (consent enforcement rides MusuRaCast's revoke arm alone); (4) the
             chase pick's cross-Pier-ness is enforced by the pinned PRNG, not an assertion
              (deleting the `skip_src` gate can slip if the pinned rand re-picks the same record).
   One-line upgrades (owed, cheap): stamp `src` on the `chased` row; stamp candidate-count on the
    `skip` row; a post-dark `fanout_dark,of=N` row; pin `keep_ahead=2` (below catalog-1) so the
     clamp bites; a mid-run revoke variant so `repli_allow` refuses at least once in-Book.
 Operational lessons of the night (memory: frozen-boot-empty-first-run, editor-think-quiesce-decay):
  a tab that froze right after boot runs its FIRST dispatched Book with EMPTY steps (Creduler
   acquire incomplete — step 1 green, rest red, no `reached:step_N`; self-heals on thaw, so burn
    a cheap green Book first), and the editor's "● connected — no identity / beacons stale" +
     held become_book = idle think-quiesce freezing the in-think roster fold, NOT a transport
      failure (beacons park unfolded on `w.c.beacons`; any think heals; a beacon-driven keepalive
       nudge is BUILT in LiesLies, live-proven over 20 idle minutes).  A SECOND, harder disease
        showed at 09:11: a brief system freeze thaw-WEDGED the editor's belief loop permanently
         (pings alive, thinks dead, no self-heal in 13 min; both runners survived the same freeze)
          — editor-only in-think path, needs the tab console; the wedged tab is a live specimen,
           root-cause in DevTools BEFORE reloading.  Full trail in memory
            editor-think-quiesce-decay.

**2026-07-11 (later) — the proto-VILLAGE: multi-caster Repli + KEEP_AHEAD + the entropy seam +
 skip-by-who-is-online.**
 The restock fan-out (the "natural next" below) landed, and it landed SOCIAL: the new Book
  **MusuRaChase** (Radiation.g — the FIFTH Ra* Book, 15 `%see`; Credence row needsFSA+needMusic,
   brand_new; toc seeded 56 lie steps) is MusuRaStream grown into a little village.  Uno and Duo
    each stock a DISJOINT testsounds slice (`Ra_stock` grew a `from` offset) on their own
     prepub-keyed radiostock; each GENERATES a single-use Idzeug and the Listener REDEEMS both over
      two Lake_links — the real front door, never a promotion shortcut — and the mutual Music grant
       gates every Radio leg.  The listen runs on Uno track A while `Ra_restock_beat` keeps every
        OTHER preview warm across BOTH wires; the dial CHASES to a Duo record (instant start on the
         warm preview, continuation from the SECOND caster's demand-driven transcode); then the
          VILLAGE EVENT — Uno goes DARK (its carrier falls; the presence hook `w.c.ra_source_live`
           = grants + carriers turns false) and the owner SKIPS the playing track mid-cycle:
            `Ra_dial_next` turns the dial ONLY among sources still online, so the pick is forced to
             Duo's remaining record — a track can always be skipped, and the next one comes from
              whoever is really there.  `Ra_dial_next(w, mirror, opts)` is the ONE dial verb:
               opts.skip_src (chase to the other Pier), opts.id (the later "pick one deliberately"
                seam), else the seeded|stirred entropy dial; the same presence hook gates the
                 restock fan-out, so a dark Pier neither warms nor wins.

 **What changed in the engines (all backwards-compatible; the four old Books re-ran green
  first — Cast 12/12 ≈9, Stream 40/40 ≈37, signatures untouched):**
 - **Repli is multi-caster now** (Repli.g): `Repli_register_caster(w, pier, lib)` /
    `Repli_register_rx(w, pier)` + `Repli_src_for`/`Repli_rx_ok` replace the single `w.c.tx`/`w.c.rx`
     identity guards (those remain the legacy default).  The consent hook grew a second argument —
      `w.c.repli_allow(peer, at)`, `at` = the SERVING prepub — so ONE hook answers per-relationship
       (Uno revoking silences Uno's legs and leaves Duo casting).  Mirror %Records get `.c.from`/`.c.rx`
        source breadcrumbs at `Repli_recv_lines` (runtime-only, nothing snaps): the wire follows the
         track.  `Ra_transcode_pump` now serves EVERY registered caster off its own shelf.
 - **The entropy seam** (Ra.g `//#region entropy`): `Ra_rand(w, n)` picks off a per-w PRNG that
    crypto-seeds lazily (the live default), `Ra_seed(w, str)` REPLACES the state (a Book pins the whole
     dial), and `Ra_entropy(w, vals)` STIRS live values in — the way to inject entropy into instances
      that are supposed to be random, without a Book losing determinism.  MusuRaChase probes it mid-run:
       the same pinned state picks differently after a fixed stir, and the fixture reads both picks.
 - **KEEP_AHEAD** = `Ra_keep_ahead(w)` (default 4; `w.sc.keep_ahead` pins) — records-ahead ACROSS the
    catalog; `Ra_restock_beat(w, mirror, budget)` wants the missing preview pages of the next K records
     (want-once, budgeted per beat so it shares the wire, CLAMPED to each preview window — a prefetch
      can never park a want or ignite a transcode).
 - **radiostock pub is a PREPUB, always** (standardised 2026-07-11): MusuRaStock/MusuRaTerm mint
    deterministic identities for their shelf keys — the `'DJ'`/`'raterm.player'` literals retired, and
     the one-time `Ra_stock` sweep now drops old literal-key files in passing.

 **Lifecycle verdict (owner asked: is the old coming-and-going worth keeping?).**  The old
  Radios/Directory lifecycle (random `load_random_records` + FIFO `whittle_stock` + setTimeout magic)
   does NOT come back.  In the new economy the shelf IS one's own collection — no count-bound whittle;
    GC is newest-ts twin supersession + the dead-source drop, both standing (§1.4) — and the listener
     side holds NO cache at all (pulled chunks are ephemera), so ITS coming-and-going is pure
      want-pacing: the session window + the restock fan-out.  The KEEP_AHEAD chase was the old
       machine's last live idea; it now rides Repli offers.  Nothing else there is owed a re-draw.

 **Verification state + next moves:**
 - MusuRaStock re-recorded 5/5 green on the prepub shelf key.  MusuRaTerm re-record and the
    MusuRaChase first CHECK run are IN FLIGHT this session — if you are the next fork: MusuRaChase is
     seeded (56 lie steps + the AudibleEntropy Wref) and registered (Credence + Ality), and needs a
      RUNNER TAB RELOAD before its first dispatch (the total:1 bomb, §2 — and the seeded toc is
       UNTRACKED: a premature dispatch clobbers it; re-seed from the loop in the session notes);
        then a CHECK run tunes the thresholds (warm >= 6 at chase AND at skip, b_heard <= 3, LUFS ±2)
         and the accept follows the %see pre-pin discipline (§1.5 — 15 Chase sentences).  Expect a
          new benign ≈ signature (TWO seals graft double the AudibleEntropy fields).  Float32-path
           compat (MusuReplica/MusuReco re-run) is also still owed.
 - **real `/music`** (§9.1) — point `Ra_stock` at the real library; the ONE mock §3.6 names.
 - **Klepto rung 10.2** (§10) — 2+ real runners; kills the tame in-process wire, the OTHER mock.
 - **§9.2 Shares / §9.4 multicast live edge / §9.5 Sent_Tree** — the live edge is a THIRD encode
    mode (chained, no seek — §1.2's orthogonal cousin); Sent_Se is half-built.

**2026-07-11 — the chunk-particle machine STANDS; nothing in the pipeline is owed.**
 The design is distilled at **§1.1–§1.5** (read those first — they are the machine as it IS).
  All four `MusuRa*` are live-green and re-recorded: Stock 5/5, Cast 12/12, Term 12/12 (≈0,
   deterministic), Stream 40/40. The arc that got here, one line: the preview economy was first
    built as a hand-rolled wire (`rec.c.segs`, `have=` counters) → owner overruled ("how will
     Repli be generic with some .c.bollocks array to manage?") → rebuilt same day on REAL chunk
      particles + generic Repli → four owner rulings folded (preview CONST 32, radiostock
       `<ts>-<pub>-<enid>`, no friend cache, dead-source drop) → re-recorded 2026-07-11.
        Session-level history lives in git (`d26ce069` "Ra Repli", `4add5244`), not here.

 **Bombs a fresh fork must hold** (durable homes: §2 wiring bombs, §1.5 Book discipline):
  LocalGen for spine `.g` edits, never ghost-compile Ra.g against a live editor (§2);
   new Book = seed the toc THEN reload the runner + register in Credence (§2);
    always `--runner=<prefix>`; pre-pin the `%see` set before any accept and confirm after (§1.5);
     sealing Books show PERMANENT benign ≈ on grafted seal fields — do not chase caveat:0 (§1.5);
      the host commits mid-session — re-check the tree after HEAD moves.

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
