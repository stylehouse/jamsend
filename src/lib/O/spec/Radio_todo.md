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

**Won 2026-07-07 — rastock SHIPS (§3.2, live-verified).** RaStock is green, ttlilt-free, and
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
     real loudness regression still diffs). RaStock Wref's it. ONE consumer today; the moment
      RaCast/RaTerm prove a pulled/played segment they are the SECOND → Wref it, do NOT re-inline
       (owner called this recurrence 2026-07-07).

**THE BOMB — publish-at-arm (anyone touching an `expecting`/Story hold MUST carry this).** A
 ttlilt lives in THREE places: **arm** (`i_req_ttlilt` → `{ttlilt}` on the world req), **publish**
  (agency_officing → flat `Run.i({ttlilt,of_w})` copies at the H-root), **read** (`poll_step`
   scans ONLY those H-root copies, unmutexed, no tree dive). `beliefs()` publishes in attend
    BEFORE `reqdo_sweep` arms → a sweep-armed hold is invisible its own tick; on a parked Story
     Run (no heartbeat, an `expecting`'s async_fn mints no thinks) officing never re-runs → the
      pass snaps MID-FLIGHT with a live un-timed-out ttlilt frozen in (the "random snap timing").
       Fix: `i_req_ttlilt` now SEEDS the H-root copy at the arm (fresh-arm only, same House =
        `this`). DON'T "fix" it with a heartbeat — that spins the belief loop at ~20Hz and inflates
         `self,round` (the tell: with publish-at-arm, `self,round` is a flat 3, deterministic across
          runs). Blast radius = every `expecting` caller; memory `ttlilt-in-snap-means-timeout`.

**Loose thread — CLEARED.** `MusuGenerateTestsMusic` + `MusuBounce` (the other `expecting` callers
 publish-at-arm flipped) are re-recorded and green. No longer owed.

**RaCast v1 PROVEN WORKING LIVE — green pending fixture-accept (2026-07-08).** Ran the full multi-beat
 Book on a live fsa runner and READ THE SNAPS: DJ stocked a REAL 39-segment opus Record (Cosmic C, 78s,
  1290003 bytes), sealed a mutual Music grant, cast the husk, and the listener PULLED THE WHOLE RECORD —
   `have=39 got=39 total=39`, byte-faithful — then a revoke shut the gate (silence). FOUR of five `%see`
    fired at their exact gates (n=2/4/8/10); beat-6 was the only miss, now FIXED (BOMB 2). Steps are red
     ONLY because it is a first CHECK run (no accepted fixture / lie diges), NOT a mechanics failure. Artifacts:
  - **`Ghost/M/Ra.g` `#region cast`** — the shared cast mechanics (`Ra_cast_arm/offer/catalog/
     serve_want/want/pull_record/recv_lines/recv_page/attach/jam/allowed`). THE DESIGN CALL: a page is
      ONE raw opus segment off the `.jam`, so it REUSES Repli's byte-agnostic parts (`Repli_fragment`
       husk-encode + `Repli_merge` mirror-upsert + the Peeroleum sha256 transport) and OWNS only the
        page path — NOT `Repli_pack_chunks`/`Repli_unpack_page` (those reinterpret Float32; opus crosses
         unaltered, decoded at the terminal). Generalising Repli's codec is the THIRD consumer's job
          (the AudibleEntropy first-inline discipline). Grant gate INJECTED (`w.c.racast_allow`) so Ra
           imports no Swarm. Compiles clean; `gen/M/Ra.go` written via LocalGen (BOMB 1). UNCOMMITTED.
  - **`Ghost/Story/Radiation.g` `RaCast` Book** — transport-real sealed pair (SwarmWire seam: `Lake_link`
     + `Swarm_arm` + `mint_idzeug(Music)`/`redeem`); DJ stocks one real `.jam` Record, casts the husk,
      listener pulls it WHOLE (byte-faithful), a revoke shuts the gate (silence). Five `%see` at
       n=2/4/6/8/10 (gate beats are GUESSES — BOMB 2). Compiled clean via `ghost-compile`; host committed it.
  - **`wormhole/Credence/toc.snap`** — `of_Book:RaCast,needsFSA:1,brand_new:1` (host committed).
 BOMB 1 — DON'T `ghost-compile` an Ra SPINE-ghost change against a live editor: it HANGS. HMR-remixing
  the depended-on Ra spine into the live runtime wedges it (proven — even a trivial valid method hangs;
   only the pristine no-op hash replies). Leaf Book ghosts (Radiation.g) slip through. Use **LocalGen**
    for spine `.g` edits: `GFILES='Ghost/M/Ra.g' CHECK=1 npx vitest run -c scripts/Story_cli.vitest.config.mjs
     scripts/LocalGen.spec.ts` (browserless, no HMR; drop `CHECK=1` to write the gen). That built `gen/M/Ra.go`.
 BOMB 2 — a brand-new Book runs Prep-only (`total:1`): the runner runs the Book it ACQUIRED AT BOOT and
  CLOBBERS a mid-session disk `toc.snap` seed. So seed `wormhole/Story/RaCast/toc.snap` with ~10
   `step,dige:lieN` lines, THEN RELOAD the runner so Creduler re-acquires it → the beats fire. The `%see`
    gate beats are now TUNED off the live run: 2/4/8/10 fire as authored; beat-6 was WRONG — it asserted
     `got===0` (husk with no bytes yet), but RaCast_flow pulls the INSTANT the husk lands, so by n=6 `got`
      was already 39 — FIXED to assert the head ARRIVED (`total>0`), not that it is empty. Endpoints
       confirmed live: source `Library,pier:dj.prepub` + mirror `pier:lis.prepub` both hold the same
        Record; sealed `%Pier` routing + `w.c.tx`=`link[0]` all worked.
 NEXT MOVE (human, fsa-live :9091 runner): (1) RELOAD the stuck runner (it wedged mid-run — eternal
  wrangle won't settle to `done`; release didn't clear it) so it re-acquires the beat-6-fixed gen
   (`ghost-compile Ghost/Story/Radiation.g` is a LEAF Book — safe HMR when NO run is active; both gens
    already on disk via LocalGen). (2) re-run RaCast → confirm all FIVE `%see` now fire (2/4/6/8/10).
     (3) ACCEPT the fixtures to record the baseline → GREEN; install `%see` via CHECK-run + manual install,
      NEVER CredRunner ACCEPT. (4) THEN §3.4 raterm — decode-proof the pulled segment (the SECOND
       `AudibleEntropy` consumer → Wref it, do NOT re-inline).

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
 - **Book: `RaStock`** — real `/music` in, uniform stock out, and the audio-proof: decode a
    produced segment on the muted AC and the measured loudness lands within tolerance of
     TARGET; a second run is idempotent (stock already standing is recognized, not rebuilt).

### 3.3 racast — the stock cast to Piers

Casting is **Repli, never RPC** (the all-pervading rule): the catalog crosses as a replicated
 husk to sealed Piers (the §9.1c re-draw — MusuGot territory), Records cross as Repli pages on
  the pull, and the LIVE edge — hear what I hear NOW — rides `@channel` multicast (§9.4) from
   a station in `role:music`. The grant gates every leg (§9.7): no Music grant, no husk, no
    pages, no edge.
 - **Book: `RaCast`** — a sealed pair; stock stands at A; B pulls one Record whole (pages,
    sha256-verified) and tunes A's live edge; a revoked B hears nothing new.

### 3.4 raterm — the terminal that plays

The Musu cursor machinery finally earns its keep as the REAL spool: want-ahead keyed off the
 playhead (§9.3), `decodeAudioData` per 2s segment (a from-zero full-track listen may instead
  ride one continuous WebCodecs decode — the §3.3 live-edge tool pointed at a whole track),
   the uniform gain already baked, crossfade at track joins (MusuMix's deck math). Faces: BigSoundland + the Voro radio tuner as the dial.
 - **the ISP-oppression warning [owner 2026-07-07]**: when Piers cannot WebRTC (CGNAT, blocked
    UDP, symmetric NAT) and traffic falls back to the relay, SAY SO — a Brink badge + a face
     line: *"your ISP is likely oppressing direct peer connections — you are riding the shared
      1Gbps relay."* Detection = the PeerJS connection state we already watch; sustained
       relay-leg traffic where a direct lane should be is the tell.
 - **Book: `RaTerm`** — segments in, honest playback out: gain applied, spool starves and
    recovers without lying (the MusuSignal claim redone on stock we actually made).

### 3.5 What retires

The tiny aspect proofs become `Radio_lowlevel.md` material as `Ra*` goes green — the
 higher-level re-draws: MusuCrowd's many-listeners claim re-proves ON racast, the spool slices
  re-prove INSIDE raterm, MusuSignal's starve gate inside RaTerm. Nothing is deleted until its
   re-draw stands.

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

**9.3 The pull rides the playhead.** MusuReplica pulls on a beat loop; a real listener pulls because
 they are LISTENING. Radiola already has the exact shape — `req_streamability` arms `%want:stream`
  when the un-played tail drops to the `want_left` floor — so the want-cursor should key off the
   playhead + keep_ahead, making replication rate = listening rate (the anti-hoard: you fetch what
    you play, plus a safe margin — the same live-edge margin MusuEdge holds).

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
