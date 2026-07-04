# Radio_spec — the jamsend streaming platform

The high-level shape of the music-piracy platform and the functions we string together to build it.
 This is the *destination* document: what each stage IS, what's built, and the refinements still owed
  (itemised — pulled out of the `MusuCrate_filaments` test snap, which now only carries the compact
   `stage,of,name,built` map and a pointer back here).

The companion docs: `Music_todo.md` (the older running todo), `Hovercraft.design.md` (req/ttlilt),
 `EntropyArrest.md` (snap-noise taming + the caveat band the transport Books lean on). `Swarm_spec.md` is
  the non-Radio half — the p2p social side (identity, presence, sharing) this streams over.

---

## 1. The one idea

**The platform is one replicated `C**` sync that can see itself in several places, with the edges between
 them.** Every feature is a facet of that:

- a **client** is a replica of the sync;
- an **edge** is a link between two replicas, with a **cost** and a **kind** — `peer` (webrtc, cheap,
   local) or `relay` (the uplink, costly);
- **content routes along the cheapest edges**, not always back through the relay;
- a **listener**, a **DJ-cue headset**, a **mixer deck**, a **cafe mesh** are all the same machine —
   replicate state, route audio along edges.

So "build the whole platform" is not N features; it is *one sync-with-edges*, and each stage below is a
 lens on it.

---

## 2. The data model (recap)

Everything is a particle (`C`/TheC). Persisted scalar strings ride `.sc`; runtime objects/refs ride `.c`
 (never encoded). The audio-specific shapes:

- `%record` — a decoded track. `c.chunks = [Float32Array]` (CHUNK=2400 @ 48000); `sc.artist|title|
   seconds|loudness|nchunks|real`.
- `%Cell` — one playing source in the mixer. `c.chunks`; `sc.deck|bpm|root|measured_bpm|match_rate`.
- the **radiostock** — the audio *source seam*: `Musu_radiostock(kind)` → `{kind}` or an override
   `{chunks}`; `Musu_stock_chunk(stock, seq)` pulls one chunk. Swap the override and every audio Book
    re-grounds on real music. `Crate_radiostock(rec)` wraps a real `%record`.
- a **node**/**edge** — the mesh graph (`Mesh.g`): `%node{id,relay_only}`, `%edge{a,b,kind,cost}`.

Determinism: seed `H.prng` via `Musu_seed(n)`; render through an **OfflineAudioContext** (no wall clock)
 so a run is byte-reproducible. Real-time playback uses the **online AudioContext** (needs a user gesture;
  the runner muted). Transport Books run the **Peeroleum** spine on a mock carrier (deterministic clock).

---

## 3. The pipeline — the high-level functions, strung together

The flow of one track from disk to a roomful of phones:

```
Collection → Rastock → Player ───────(Pier: real transport)──────▶ listener
   library    desire+    decode+        cast %audiochunk frames        Player + Mixer
   walk       fill recs  cope                                          (cells) + DJ-cue
                                                                          │
                                                          Mesh: replicas + edges (route cheapest)
                                                          Stretch: relay once → webrtc-forward (quiet uplink)
```

1. **Collection** rifles a music library into a track list.
2. **Rastock** desires `want` records and fills itself from the collection (preview → stream).
3. **Player** decodes, plays, and *copes* — rate-control (Glide), gap concealment, coverage gaps.
4. **Pier** casts the audio peer-to-peer over the real transport; listeners receive in order, integrity-
    checked, loss-healed.
5. **Mixer** runs N **cells** at once, pitch/rate-bent and crossfaded.
6. **DJ-cue** replicates the deck `C**` to a phone that monitors the off-air cell and beatmatches it in.
7. **Mesh** is the whole thing as replicas + edges; content routes the cheapest path.
8. **Stretch** is multicast over the mesh: the relay sends once, a peer forwards locally.

---

## 4. The controllers (code + data, not req piles)

Pure stateless rate curves in `Ghost/M/Radiola.g`; the caller owns the trajectory data. Two ends of the
 same stream:

- **Glide** (`Glide_decide(frontier, cur, ended, p)`) — guards the *delivered buffer running dry*. Backs
   off toward a floor as the audio ahead of the playhead runs out (Schmitt band, recover gradually). Its
    params `{low,high,floor,step}` are data a coordinate-descent (`Musu_descend`) tunes to least
     "show-wreckage".
- **LiveEdge** (`LiveEdge_decide(margin, cur, target, p)`) — guards the playhead *catching the live
   broadcast edge*. Chases low latency when lagging (FAST), throttles near the edge (0.8 — Radios'
    `check_live_edge_delta`), oscillates safely near `target`.

Wreckage metric: **coverage**. A gap is uncovered playback time — silence *where a track should be
 sounding* (a chunk starts after the previous ends). Musical quiet sits inside a covered span and never
  counts. This replaced the rms-floor guessing.

---

## 5. The 9 stages — itemised

Legend: **[built]** real data/logic flows through it; **[done]** a specific refinement landed; **[todo]**
 owed. The Book that proves each stage is named; all are green on the live `:9091` runner (accepted
  fixtures) unless noted.

### 1 — Collection  *(Book: MusuCrate · Ghost/M/Crate.g)*  **[built]**  *(fixture pending re-record after the 2026-07-02 nav pivot)*
Walk a music library into a track list. Real today by DISCOVERING it through the Wormhole nav: `Crate_nav_paths`
 BFS-walks `dir_at().expand()` → `{directories,files}`, `Crate_nav_payload` reads bytes via `bin_read` +
  OfflineAudioContext decode. Backend-agnostic across the FSA share / OPFS cloud / editor-proxied runner. No
   manifest, no fetch — a collection is a folder of files, like real music.
- [done] directory-tree walk over nested artist/album/track (`Crate_nav_paths`, sorted for determinism).
- [done] a real source via Wormhole `bin_read` — not a static symlink or served fetch.
- [todo] metadata from tags (music-metadata) not just the filename.
- [todo] the picker path (`Crate_open`/`Crate_meander` over a raw FileSystemHandle) for an arbitrary user
   library OUTSIDE the project tree — still the raw-handle route, not yet unified onto the nav.
- [caveat] discovery awaits the nav INLINE — fine for local navs, but a remote `atime_async` nav must route
   via the rw_op actor (see the caveat in Crate.g `Crate_nav`). Fleet-path TODO.

### 2 — Rastock  *(Books: MusuCrate / MusuReco · Crate.g)*  **[built]**
Desire `want` records and fill from the collection, visibly: issue a `%reading` → it comes back → a
 `%record` is made. `rastock_start/issue/read_into/harvest`.
- [done] the preview→stream split: `Crate_transcode_begin/release` — decode ONCE, release the frontier
   progressively (`%preview` children name each span), and the repli serve side streams AS IT GROWS: a
    fixed-stride want the frontier hasn't reached PARKS (`%parked_want`) and `Repli_serve_parked` answers
     it the moment a release passes it. Streaming starts with the FIRST full page, never waits for the set.
- [done] the recommendation layer: `Repli_recommend` — a `%Reco` note is knowledge attached to the
   `%Record` (the C** IS the knowledge graph), carried in the SAME offer fragment; the gate is you may
    only recommend a Record you've STARTED (≥1 transcoded chunk).
- [todo] host as a `%Good` in LiesStore (the `req:Store` IO pump).
- [todo] idle-reap: drop a `%Good` once a consumer has left it idle (mirror `recordWear`).

### 3 — Player  *(Books: MusuSignal / MusuGlide / MusuTune)*  **[built]**
Decode + play + cope. Real Audiolet voice; Glide rate-slew; OfflineAudioContext render + measure.
- [done] gap-detector: the **coverage** model — uncovered playback time is the dropout; musical quiet
   ignored.
- [todo] coverage *per-Cell* once the Mixer lands — each Cell its own expected-play timeline.
- [done] concealment ladder: a gap fills with repeat-last-frame or reverse-pingpong instead of dropping
   to silence; reverse-pingpong's seam is continuous where repeat clicks (`Mix_reverse` + MusuConceal).
- [todo] crossfade-on-seam concealment (the third rung) + wire concealment into the live Glide path.
- [todo] audible real-time playback through the online voice (gesture-gated).

### 4 — LiveEdge  *(Book: MusuEdge · Radiola.g LiveEdge_decide)*  **[built]**
Stay a safe margin behind the live broadcast frontier.
- [done] stay-behind margin off a live production clock — outrunning the edge = a stall.
- [done] throttle 0.8 near the edge — holds safe low latency, where a fast-chase overruns 145× / 48 gaps.
- [todo] wire the margin to a **real** broadcast cursor over the Pier — the production clock is modelled,
   not socket-fed.

### 5 — Pier  *(Book: MusuPier · Ghost/N/Peeroleum.g)*  **[built]**  *the synapse*
Stream peer-to-peer over the real transport. The one piece every other Book used to LARP.
- [done] cast → listen REAL `%audiochunk` frames over the Peeroleum transport (`w.c.on.audiochunk`),
   in order, on the same deliver→inseq→retransmit path PereProof proves.
- [done] perturbable link: a dropped chunk is healed by the retransmit sweep; each frame's sha256
   `body_hash` is verified, and a wrong-hash frame is **faulted** (`bad-body-hash`) and never delivered.
- [todo] multicast: one caster fans out to many listeners (Peeroleum `@channel` — **needs 2+ runners**).
- [todo] wire the real audio payload into the Player/Glide on the listener side (currently bytes only —
   reconstruct the PCM and play it).

### 6 — Mixer (cells)  *(Book: MusuMix · Ghost/M/Mixer.g)*  **[built]**
The cellular world — many sound-sources at once, pitch/rate-bent to mix.
- [done] N Cells render-summed into one OfflineAudioContext — they add at the destination.
- [done] beat detection (onset envelope + autocorrelation) + beatmatch — bend B by bpmA/bpmB, proven by
   re-rendering and re-measuring (96→120 bpm).
- [done] equal-power crossfade holds loudness across the seam where a linear fade dips (0.87 vs 0.71).
- [todo] live online voice: N real Audiolets summing in real time (gesture-gated), not just offline.
- [todo] per-Cell expected-play timeline — coverage/gaps judged per Cell, not globally.

### 7 — DJ-cue  *(Book: MusuCue · Mixer.g Mix_align)*  **[built]**
Live `C**` replication to a phone — the headset deck: monitor + sync before the mix.
- [done] a phone replica holds the cell descriptors and re-renders the off-air deck from synced state
   (no chunks cross — just the descriptor).
- [done] beatmatch the cued deck → the beat-**grid** alignment jumps (onset cross-correlation 0.21→0.89)
   → bring it into the main mix.
- [todo] real `C**` sync over the Pier transport — the descriptor replication is modelled, not
   socket-backed.

### 8 — Mesh (replicas + edges)  *(Book: MusuMesh · Ghost/M/Mesh.g)*  **[built]**
The whole platform as one sync seen in several places, with the edges between.
- [done] `%node` replicas + an `%edge` per link (peer/relay, each a cost) — the graph model.
- [done] content routes the cheapest edges — Dijkstra picks a 2-hop peer path over a costly relay.
- [todo] real `C**` state replication over the transport — the model is deterministic, not yet
   socket-backed.

### 9 — Stretch (multicast over the mesh)  *(Book: MusuMesh)*  **[built]**
A relay-only peer sends once; a webrtc-peered client forwards locally so the uplink stays quiet.
- [done] min-cost broadcast tree: the relay edge is crossed ONCE, then webrtc-forwarded.
- [done] the cafe stays quiet: naive uplink = N clients, but the stretch uplink stays 1 at any crowd
   size (verified at 3 and 6 clients; a negative-control relay-only topology proves the saving is the
    peer edges, not the algorithm).
- [todo] build on the real Peeroleum `@channel` multicast — turn relay-fanout into peer-forwarding
   (**needs 2 runners**).

---

## 6. The test family (where each stage is proven)

All under `Ghost/Story/Musuation.g`, dispatched per-beat off `step_n`, witnessed by idempotent
 `%witnessed:*` latches; the snap-fixture diff is the gate. Verify on the live runner
  (`scripts/runner_ask.mjs run <Book> --watch` → `snap <n>` → `accept`), never headless.

| Stage | Book | the headline witness |
|---|---|---|
| Collection/Rastock | MusuCrate | real_records · playable · helps |
| Rastock preview→stream + reco | MusuReco | recommended · refused_unstarted · started_early · outran_then_served · complete · real_music |
| Player | MusuSignal · MusuGlide · MusuTune · MusuConceal | streams/starves · fewer_gaps · repeat_fills · smoother |
| LiveEdge | MusuEdge | holds_margin · backs_off · low_latency · baseline_overruns |
| Pier | MusuPier | crossed · verified · dropped_then_healed |
| Mixer | MusuMix | tempo_detected · beatmatched · cells_sum · crossfade_discriminates |
| DJ-cue | MusuCue | replicated · cued_offair · synced · brought_in |
| Mesh/Stretch | MusuMesh | routes_cheapest · stretch_cuts_relay · no_free_lunch · scales |

Each witness is differential or has a negative control with teeth (an inverted controller, a relay-only
 topology, a linear crossfade, a wrong-hash frame) — adversarially reviewed so a number we typed can't
  satisfy it.

**Audio-source policy:** seeded synth records for pure-protocol / tick Books (instant, nav-free — the
 payload's content is not the subject, e.g. MusuReplica); `testsounds/` for any Book whose CLAIM involves
  files, decode, or transcode (MusuCrate, MusuReco) — it is deterministic generated music (pure tones via
   MusuGenerateTestsMusic) that still travels the whole real pipeline: nav walk → bin_read → decodeAudioData.
    `/music` is real but per-machine — never fixture-stable; use it for listening, not for gates.

---

## 7. Open frontiers (the real remaining work)

The deterministic / single-runner models are built. What's left needs real plumbing or more runners:

- **Real multicast over the Pier** — `@channel` fan-out (Stretch stage 9, Mesh real-sync stage 8). Needs
   2+ runners to verify; the routing/accounting model is the spec for it.
- **Audio actually plays across the wire** — reconstruct the listener's received `%audiochunk` bytes into
   PCM and feed the Player/Glide (Pier todo). Closes "the synapse carries music," not just bytes.
- **The concealment ladder** — repeat/pingpong/crossfade-on-seam under real dropout (Player).
- **Live-voice mixing** — N real Audiolets summing in real time, gesture-gated (Mixer); per-Cell coverage.
- **Real C** replication** over the transport — DJ-cue + Mesh currently model the descriptor sync.
- **Real collection source** — Wormhole `bin_read` / a library / proper tags, off the static symlink.

The MVP that ties it together: a real caster on the Pier streaming a real `%record` to two webrtc-peered
 listeners through one relay-only source — the cafe, end to end. Everything above is a tested rung toward it.
