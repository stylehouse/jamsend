# Radio_spec — the jamsend streaming platform

The high-level shape of the music-piracy platform and the functions we string together to build it.
 This is the *destination* document: what each stage IS, what's built, and the refinements still owed
  (itemised here — the stage Books' test snaps carry only the compact `stage,of,name,built`
   map and a pointer back to this doc).

The companion docs, and how they relate: `Radio_todo.md` (the running worklist — being drained INTO this
 doc as each thread lands or is retired), `Radio_multicast_todo.md` (the opportunistic-webrtc swarm design,
  §5A rung 7), `Hovercraft.design.md` (req/ttlilt), `EntropyArrest.md` (snap-noise taming + the caveat band
   the transport Books lean on). `Swarm_spec.md` is the non-Radio half — the p2p social side (identity,
    presence, sharing) this streams over. `Radio_scape_handover.md` is the live session brief for the
     **scape** (§8) — the Voro layer, the demo Books, and the road to Sounditron.

---

## 1. The one idea

**The platform is one replicated `C**` sync that can see itself in several places, with the edges between
 them — and it lives in two planes.** Every feature is a facet of that:

- **The descriptor plane — the culture.** Mags, cards, listings, wants, grants, cursors: the small,
   legible `C**` that says *what music exists, who holds it, what I want, what I'm allowed*. It replicates
    to every peer that shares an interest — cheap, self-describing, seeing itself everywhere. **Repli**
     carries it; a subscriber is just a replica whose interests overlap yours.
- **The content plane — the bytes.** The audio itself: previews and streams, chunk by chunk,
   content-addressed. It does NOT flood; it is materialised **on demand** and **routed along the cheapest
    edges** — pulled from whoever near holds it, transcoded to the grade you asked for, and (where webrtc
     peers exist) fanned out once then forwarded locally so the uplink stays quiet.

An **edge** is a link between two replicas with a **cost** and a **kind** — `peer` (webrtc, cheap, local)
 or `relay` (the uplink, costly). **The descriptor plane floods; the content plane routes.**

Two spines hang off the one sync, meeting at the transport:

- the **culture spine** — identity → magazine → browse → heist → persist → swarm: how music travels
   *between people*.
- the **audio spine** — collection → decode → play → mix → cast → mesh: how a track becomes *sound in a
   room*.

A listener, a DJ-cue headset, a mixer deck, a cafe mesh, a friend's phone across the world are all the
 same machine: replicate the culture, route the bytes, make sound. So "build the whole platform" is not N
  features; it is *one sync-with-edges, two planes, two spines* — and each stage below is a lens on it.

---

## 2. The data model

Everything is a particle (`C`/TheC). Persisted scalar strings ride `.sc`; runtime objects/refs ride `.c`
 (never encoded). A **mainkey** — the first `sc` key — is *what a thing IS*; a reference wears its OWN
  mainkey and carries the id. The cast splits by plane: the descriptor particles (culture) and the content
   particles (bytes).

### 2.1 The homing law — nothing per-Pier floats on `w`

**A world holds many peers' state at once; no equipment may expect anything at `w/*` that is per-Pier.**
 Per-peer state homes under an identity:

- `Peering,name:<self>` — **you, to yourself**: your holdings, your mags, your wants. The UI frames it as
   "mine".
- `Pier,pub:<them>` — **a friend, as you hold them**: what you've learned they have, what they've granted
   you, what you hold of theirs. One `Pier` per public key.
- `Grant` / `%UnGrant` — signed, durable consent facts. A `%UnGrant` is a **tombstone**: a negative
   decision that must NEVER be garbage-collected (absence is ambiguous; a tombstone is not).

The tell you broke this is the MusuBuddy smell — a `Mag:Musica`, a `Kept`, a `Dogear`, telemetry rows all
 lying flat on `w` where nothing says whose they are. Each belongs under a `Peering` or a `Pier` — for
  music, under its `%MusuSelf|%MusuThem` home (§2.2).

### 2.2 The Musu homes — `%MusuSelf` | `%MusuThem` *(re-drawn 2026-07-17 — supersedes the Ray; design, unbuilt)*

*(Notation here: `/` nests — `A/B` is a child B under A; `|` alternates — `%Preview|Stream` is "a
 `%Preview` or a `%Stream`".)*

`%Library` and the `Ray` dissolve into **one music home per identity**: shallow, so equipment never digs
 a `Peering/Pier/something,deep` path to reach the shelf it wants, yet still obeying the homing law (§2.1)
  because each home wears the `pub`:

- **`%MusuSelf,pub:<me>`** — my music home (correlates to `Peering,name:<self>`).
- **`%MusuThem,pub:<them>`** — a friend's music as I hold it (correlates to `Pier,pub:<them>`); one per key.

Each home carries the same shelves:

```
%MusuSelf,pub:<me>
  radiostocking/%Mag…     ← the ephemeral draws — machine-drawn handfuls, GC fodder
  the/%Mag…               ← the durable Mags — tracks written about, hence never dropped
  shop/                   ← where music is handled, weighed and transferred (§2.4)
```

A `%MusuThem` home is mostly descriptor — their Mags as I've learned them; the bytes I hold all sit in MY
 shop with `from:`/`at:` provenance, so the two planes (§1) map onto the homes. **A card still resolves
  against MANY homes** — you browse the blogs and pull a record from anyone who holds it, a friend or a
   stranger or yourself.

### 2.3 The magazine stack — the GC-able unit

`%Mag` is **the garbage-collectible unit** of the culture. Drop a `%Mag` and all it named is forgettable;
 keep it and it names what to hold.

```
%MusuSelf,pub / radiostocking|the      ← the home's shelves (§2.2): ephemeral draws | durable keepers
  %Mag:Musica                          ← a magazine — music, OR want-of-music (symmetric)
    %Cloud,randomic:<draw>,created_at   ← one draw's arrivals; randomic present ⇒ machine-drawn
      %Card,id,artist,title,album,path,body_hash    ← a catalog LISTING (a referring particle)
```

- a **`%Mag`** carries **music or want-of-music** — one shape, either polarity. The want-polarity now has
   its own name: a **`%Grasp`** — the chosen handful of remote tracks|directories, a durable **wishlist**
    that logs what you're pulling and persists|resumes across a restart; a **`%Heist`** is a Grasp's
     *actively-downloading* leg (transient, Mag-shaped — a manifest of cards that dies on land).
- **`Mag|Grasp|Heist` are Waft-based** — any of them can carry a `What/` doc anywhere inside; writing
   about a track is exactly what promotes its Mag into `the/` (durable, never dropped).
- a **`%Cloud`** with `randomic` present is a machine-drawn handful — a random meander over a collection
   never fully enumerated; omit `randomic` and the cloud is **curated** (hand-kept).
- a **`%Card`** is a *listing*, never a holding: id + metadata + `body_hash`, minus the bytes. The card is
   a **referring particle** wearing its own mainkey; the shared `id` is the free join to the holding.

### 2.4 The shop — where the bytes live *(re-drawn 2026-07-17; as-built today = `%Library,pier:` + census `%Record/%Body` — rung 3 is this re-draw)*

The **shop** (`%MusuSelf,pub/shop/`) is where music is handled, weighed and transferred — the holdings
 counter. Three byte-roles, three mainkeys (identity-per-shelf: a downloaded grade never impersonates the
  master), plus the two Mag-shaped movers:

```
shop/
  %Original,id:<enid>               ← THE master — held where it is GIVEN as such; never travels
     .sc: path,body_hash,sr,nch,…    ← whole-source identity + baked loudness (lufs/gain/preskip)
     %Chunk,seq  .sc: buf,cid       ← the source bytes sliced (today's %Body, re-homed)
  %Record,id:<enid>                 ← the streaming materialisation — stands on its OWN, beside (never
     %Preview,seq  .sc: buf,cid        under) an %Original: a pull lands one of THESE, derived from
     %Stream,seq   .sc: buf,cid        someone's master, and it may never see that master at all
  %Blob,id:<enid>,grade:ogg128      ← a whole-file export grade   .sc: path (one real file on a nav)
  %Grasp…                           ← the chosen handful of remote tracks|directories (persists, §2.3)
  %Heist,at:<pier>                  ← a Grasp's actively-downloading leg (transient, §2.3)
```

- **`%Original`** *wants to be* the original (flac) and **encodes down to** whatever grade a want asks —
   derive lazily, cache per grade, never upsample. A download never *becomes* an `%Original`: masterhood
    is where the file is given, not an upgrade a copy can earn.
- **`%Record/%Preview|Stream`** keeps exactly today's shape — ONE continuous opus encode (`opus128`, const
   32 preview window + on-demand continuation), raw length-prefixed packets: the head FACTS
    (`preskip/sr/nch`) ride the card, and no tags ride in-band (metadata is the `%Card`'s job).
- **`%Blob,grade:`** names codec+bitrate (`ogg128`, `flac`) — the `ogg128` export is where real
   OpusHead+OpusTags pages finally get written (from card metadata): Androids still play `.ogg` more
    happily than `.opus`, so phone-sync ships Ogg. One real file on a nav, not chunk particles.
- every chunk (`%Chunk|Preview|Stream,seq`) carries its **`cid`** (full-sha256 content-address of its
   bytes); the signature (rung 7) keys on the **`%Original`'s** cids — the one deterministic manifest.
- **`radiostock`** = `<ts>-<pub>-<enid>`; `enid` = `Ra_enid`, today a sha256 over the WHOLE source's raw
   bytes (first 16 hex). `body_hash` (whole-file sha256) rides the card.
- the `%Original`/grade-dispatch verbs get their own ghost — **`Ghost/M/Orig.g`** — keeping the pipeline
   (`Ra.g`) and the culture (`Heist.g`) files from swallowing the new layer.

**[P0 — the keystone] Per-chunk content-addressing — the primitive now lands** *(2026-07-15)*. Every chunk
 carries a durable **`cid`** (full sha256 of its bytes): minted where chunks mint (`Ra_record_from` for
  `%Preview`, `Ra_chunk_mint` for `%Stream`, `Heist_census` for `%Body`), carried in the `.jam` header as a
   **`cids[]`** manifest parallel to `sizes[]`, and **verified per-chunk at `Heist_land`** — a localized
    breach that names the corrupt seq *ahead of* the whole-file `body_hash` gate (which still stands as the
     final read-back check). Live-proven on the `:9091` runner: the census mints a `cid` on every `%Body`
      (39 in one snap), no step errors, the heist phase machine still completes to `deny`. **Still owed:**
       the manifest must ride an **origin-signed** card before a stranger's bytes are *trustworthy* — today
        the cid catches corruption, not a lying peer; the signature is the swarm-trust layer (rung 7). Only
         then does the unconditional disk read-back demote to a lazy backstop. (`Hashly.ts` `sha256_hex`; the
          `sha256_incremental` streaming wire tripwire stays.)

### 2.5 The Rack — the super-Mag of interests

**`%Rack`** (name provisional) is the super-`%Mag` at the `%MusuSelf` home (was `Peering/*`): it tracks
 *every* `%Mag` a `Peering` has an interest in — its own and its friends'. It is **loaded on init** and is
  the root of what to re-home and re-subscribe when the app wakes. *(Open: the `radiostocking|the` shelves
   may absorb this job — the shelves ARE the interest list.)*

### 2.6 The audio runtime shapes

Once bytes arrive, the audio spine's shapes take over (unchanged):

- `%record` — a decoded track. `c.chunks = [Float32Array]` (CHUNK=2400 @ 48000); `sc.artist|title|
   seconds|loudness|nchunks|real`.
- `%Cell` — one playing source in the mixer. `c.chunks`; `sc.deck|bpm|root|measured_bpm|match_rate`.
- the **radiostock** — the audio *source seam*: `Musu_radiostock(kind)` → `{kind}` or an override
   `{chunks}`; `Musu_stock_chunk(stock, seq)` pulls one chunk. Swap the override and every audio Book
    re-grounds on real music. `Crate_radiostock(rec)` wraps a real `%record`.
- a **node**/**edge** — the mesh graph (`Mesh.g`): `%node{id,relay_only}`, `%edge{a,b,kind,cost}`.

### 2.7 enWaft carries the descriptors, not the bytes

The descriptor plane travels as a Waft; the content plane never rides inside it. **`enWaft` filters out the
 buf chunks** (`%Mag/Dir/Blob/Chunk,buf`) — the document carries cards and pointers; the chunk bytes live
  in a swarm-shared content store, fetched along edges. That is also what lets a crowd share one set of
   chunks: everyone is served what everyone's getting (the multicast design, `Radio_multicast_todo.md`).

Determinism: seed `H.prng` via `Musu_seed(n)`; render through an **OfflineAudioContext** (no wall clock) so
 a run is byte-reproducible. Real-time playback uses the **online AudioContext** (needs a user gesture; the
  runner muted). Transport Books run the **Peeroleum** spine on a mock carrier (deterministic clock).

---

## 3. The two flows

The culture spine wraps the audio spine: the outer loop moves music *between people*; the inner pipeline
 turns arrived bytes into *sound*.

### 3.1 The outer loop — music between people

```
peer's collection ─▶ publish a %Mag ─▶ browse a home of Mags ─▶ heist ─▶ land ─▶ persist ─▶ resume
   (their disk)       cards, not bytes     over their Pier      offer     into your   %Rack /    a %Grasp
                                                              manifest    holdings    Berth      picks up
                                                                pull
                                                                  │
                                     content-addressed chunks · cheapest edge · transcoded to grade
```

1. **Publish** — a holder folds its collection into a `%Mag:Musica` (`Musica_publish`; `Musica_fold` is the
   pure one-brain that serves the disk publish AND the wire offer).
2. **Browse** — you read a peer's home of `%Mag`s (`%MusuThem`, §2.2) over their `Pier`. Cards, not
   bytes; a card resolves against whoever holds it.
3. **Heist** — the pull, a transient `%Heist,at:<pier>` that exists as briefly as possible:
   - **offer** (`Heist_offer_all`) — the source casts its catalog as chunkless husks: a pointer to every
      file you'd want, no `%buf` opened.
   - **manifest** (`Heist_manifest`) — a look-before-commit read: `held` / `new` per card. *(The RESUME
      side — the same listing re-shown mid-heist off partial fill — is the unbuilt marker.)*
   - **pull** (`Heist_beat` / `Ra_pull_beat`) — ask for the bits you don't hold, dedup-skip the ones you
      do, content-route the rest.
   - **land** (`Heist_land`) — assemble, verify, catalogue into your holdings; the `%Heist` then flattens
      (`Heist_flatten`).
4. **Persist** — the `%Rack` and the **Berth** home what you kept so it survives a restart (§5A rung 5).
5. **Resume** — a `%Grasp` is the durable wishlist; its `%Heist` persists against it and resumes.

### 3.2 The inner pipeline — arrived bytes become sound

Once a track is in your collection, the audio spine (the nine stages, §5B) runs it:

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

The two flows **meet at the Pier** (the one real transport that both the heist pull and the live cast ride)
 and **at content-addressing** (the same per-chunk identity that lets a heist trust a stranger's bytes is
  what lets the swarm forward them).

---

## 4. The controllers and negotiators

Pure, stateless curves in `Ghost/M/Radiola.g`; the caller owns the trajectory data. Two guard the audio
 buffer at opposite ends of the same stream; a third negotiates the grade of the bytes themselves.

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

**Quality on demand — the content-plane negotiator.** Grade is *not* a global toggle; it is a facet of the
 **want**. A want carries the grade its context calls for — a phone on cellular asks low, a mixer deck asks
  lossless. The holder keeps only the `%Original` and serves the best grade *at or below* what is asked,
   **transcoding down lazily** on the first touch of each segment and **caching** the encoded result, so the
    second listener at that grade pays nothing. It never upsamples: a want above what the `%Original` can
     give is served the `%Original`. Grade is negotiated from context, memoised per segment, and *derived* —
      never stored N times.

---

## 5. The two ladders — itemised

Two spines, two build-status ladders. The **audio ladder** is mature — nine green stages on the live
 `:9091` runner. The **culture ladder** is where this doc's live work is.

Legend: **[built]** real data/logic flows through it; **[done]** a specific refinement landed; **[todo]**
 owed; **[P0]** a keystone precondition. The Book that proves a stage is named; audio-ladder fixtures are
  accepted-green on the live runner unless noted.

### 5A — The culture ladder (identity · magazine · heist · persist · swarm)

**0 — Content-addressing** **[built · green ×2, 2026-07-15 · signing owed]** — every chunk carries a durable
 `cid` (sha256 of its bytes): minted at all three chunk-mint sites (`Ra_record_from` / `Ra_chunk_mint` /
  `Heist_census`), a `cids[]` manifest in the `.jam` header, verified per-chunk at `Heist_land` (a localized
   breach ahead of the whole-file gate — and it now records `job.sc.breach_seq`, so the breach NAMES the
    offending chunk the way `body_hash` never can). **MusuHeist** re-recorded 22/22 GREEN with the additive
     `cid` rows on every `%Body`. **MusuBreach** (`Ghost/Story/Heistation.g`, green ×2) is the adversarial
      twin: it lands an honest record clean (the control — the gate discriminates) then flips one byte of a
       middle chunk LEAVING its cid and proves the gate FIRES — breach, no land, file unlinked mid-stream,
        record retained, and the gate's own `breach_seq` matches the poisoned seq. *Owed:* the Ra-path
         (`%Preview`/`%Stream`) + resurrect round-trip proof; and the origin-signature that makes the manifest
          swarm-trustworthy — the cid catches CORRUPTION (proven) not a LYING peer (rung 7). §2.4.

**1 — Identity homing** *(the multi-Pier law, §2.1)* **[todo]** — every per-peer particle under
 `Peering,name:<self>` or `Pier,pub:<them>`; drop the finished transient `buddy_*` reqs at a safe seam;
  nest the loose telemetry rows. The music shape of this law is the `%MusuSelf|%MusuThem` homes (§2.2).
   *(The MusuBuddy snap is the smell that names the work.)*

**2 — Magazine** *(Book: MusuHeist · `Ghost/M/Heist.g`)* **[built · green ×2, 2026-07-14]** —
 `%Mag:Musica > %Cloud,randomic > %Card`; `Musica_publish/fold/cards/forget`; the `%Card` mainkey split
  from the `%Record` holding (a listing is not a holding). `randomic` = a random draw; `c.repli_loc` keeps
   the Cloud layer alive across replication. The browse **cursor arc** (`%Dogear` — resolve, heal a
    `%Renamed`, resume a berthed browse) is green ×2 alongside.

**3 — Holdings + Library dissolve** **[todo]** — `%Library` (and the `Ray`) dissolve into the
 `%MusuSelf|%MusuThem` homes (§2.2); the `shop/` holds `%Original/%Chunk` (the master — today's census
  `%Record/%Body` re-homed), `%Record/%Preview|Stream` standing on its own beside it (a pull lands a
   Record — derived, never a master), and `%Blob,grade:` export grades (`ogg128` for phone-sync). Waking
    a card loads the `%Record`; `%Stream` only in the live copy. New ghost `Orig.g` groups the
     `%Original`/grade-dispatch verbs. *(Re-drawn 2026-07-17, §2.2+§2.4; unbuilt.)*

**4 — Heist** *(`Ghost/M/Heist.g`)* **[built · gate-owed]** — offer → manifest → pull → land; whole-file
 `body_hash` verified at land; cp-landing rulings (copy not rename; non-audio siblings never copy; dedup
  bias-to-keep). *(The manifest's RESUME side is the `<` unbuilt marker; the read-back demotes only after
   rung 0.)*

**5 — Persist (Berth + Rack)** *(Book: MusuBerth — live-gate owed)* **[built · gate-owed]** — the **Berth**
 is the non-Lies Waft host: `<root>/.jamsend/berth/<prepub>/<name>/toc.snap`, bound to the encoders only
  (enWaft/deWaft + the 7-method nav contract), zero Lies runtime; API in Heist.g `//#region berth`. It
   hosts `Waft:Listening` + the `%Rack`. `%Rack` (§2.5) tracks every interested `%Mag`, loaded on init.
    *(Berth built; the MusuBerth live-gate, the `%Rack`, and init are owed.)*

**6 — Marauding (wishlist persist/resume)** **[todo]** — a `%Grasp` (the chosen handful of remote
 tracks|directories, Mag-shaped, Waft-based) logs pulls, persists the heist, and resumes it across a
  restart; the `%Heist` is its actively-downloading leg. *(Re-coined 2026-07-17 — was
   `Ray,self/Mag:marauding`; the resume side is unbuilt — see rung 4.)*

**7 — Swarm (opportunistic webrtc chunk-sharing)** **[routing: design · trust keystone: built ×2 in isolation]**
 — a swarm peer is just another `Repli_register_caster`; **Repli sends `C**` to many overlapping-interest
  subscribers at once**, and Peeroleum §18 already fans one upload out to a `@channel` relay-side. The webrtc
   evolution (a have-bitmap inventory beacon + a cheapest-source chooser) is designed in
    `Radio_multicast_todo.md`, gated on rung 0. This is the content plane's routing made real.
 **The trust keystone — origin-signature over the cids manifest** (the thing that lets you pull a chunk from a
  STRANGER): the per-chunk cid catches CORRUPTION but not a lying peer who recomputes a cid over bad bytes. So
   the origin signs the manifest of cids (ed25519 over `id | cid0.cid1…`, the `Idento` primitive Swarm.g already
    uses) and a receiver who knows the origin key verifies the vouch before trusting a byte. **Proven in
     isolation, green ×2** — `MusuBreach` step 6: the honest vouch verifies; a FORGED manifest (a middleman
      swaps one cid) fails the signature; an IMPOSTER (a different key) is rejected. *Owed:* `[RUNG7-WIRE]` the
       WIRING — carry `sig` + `by` in the `.jam` header / the offer husk, and verify at the offer door before
        any pull (promote `MusuBreach_sign/verify` to `Ra_*` in `Ghost/M/Ra.g`), **keyed on the MASTER's cids**:
         the Ra-path transcode is NOT bit-reproducible (two independent transcodes of one source → different
          bytes → different cids), so the signature must vouch for the deterministic `%Original` (rung 3), never
           each grade's — else no swarm can dedup/verify across peers who transcoded separately. The two gates together — cid keeps an honest peer
         honest, signature keeps a dishonest peer out — are what make a swarm pull safe.

### 5B — The audio ladder (the nine stages)

### 1 — Collection  *(Books: MusuGenerateTestsMusic writes · MusuReco reads · Ghost/M/Crate.g)*  **[built]**  *(MusuCrate retired 2026-07-05 — redundant, folded into MusuReco+MusuGlide)*
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

### 2 — Rastock  *(Book: MusuReco · Crate.g)*  **[built]**  *(MusuCrate + its Crate_rastock helpers retired 2026-07-05)*
Desire `want` records and fill from the collection, visibly: issue a `%reading` → it comes back → a
 `%record` is made. `rastock_start/issue/read_into/harvest`.
- [done] the preview→stream split: `Crate_transcode_begin/release` — decode ONCE, release the frontier
   progressively (`%preview` children name each span), and the repli serve side streams AS IT GROWS: a
    fixed-stride want the frontier hasn't reached PARKS (`%parked_want`) and `Repli_serve_parked` answers
     it the moment a release passes it. Streaming starts with the FIRST full page, never waits for the set.
- [done] the recommendation layer: `Repli_recommend` — a `%Reco` note is knowledge attached to the
   `%Record` (the C** IS the knowledge graph), carried in the SAME offer fragment; the gate is you may
    only recommend a Record you've STARTED (≥1 transcoded chunk).
- [principle] the Repli C** stream is NOT hosted as a `%Good`. It is its own delivery model: a replicated
   *landscape of a single type* (C) with explicit frontiers | paginations and defined methods of navigating
    them — you WALK it, you don't `GET` it. `%Good`/`req:Store` is the legacy request-response RPC floor
     (GET /something); the C** stream is the elegant alternative and must stay orthogonal to it, never fold
      into it. Delivery, availability ("how much is where" — the `%Sent_Tree`), pagination and retirement
       all live in the stream's own vocabulary, not in a Good's fetch-and-cache.
- [todo] idle-reap: drop a replicated Record once a consumer has left it idle — via the stream's OWN wear
   (a goner in the Se — §9.6 "wear makes the mirror a cache"), NOT a `%Good` eviction.

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
| Collection/Rastock | MusuReco / MusuGenerateTestsMusic | real_music · complete *(MusuCrate retired)* |
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
  files, decode, or transcode (MusuReco) — it is deterministic generated music (pure tones via
   MusuGenerateTestsMusic) that still travels the whole real pipeline: nav walk → bin_read → decodeAudioData.
    `/music` is real but per-machine — never fixture-stable; use it for listening, not for gates.

**[todo] Consolidation — many of these Books are scaffolding, not keepers.** Most Musu* Books were built to
 prove ONE aspect of an algorithm as it was written (a rate curve, a fill mode, a spin, a cursor advance).
  That isolation earned its keep *during construction* — but the mature state is a small set of tests that
   exercise the whole algorithm in ONE real-context place, with the trivial single-aspect proofs folded in
    and retired. The signal a Book is scaffolding: its witnesses are soft (something exists / time passed /
     N happened) or its one hard claim is already made by a real integration Book. Concretely:
- **MusuRadio is the first to retire.** Its only differential claim (`helps` — Glide beats no-control)
   duplicates MusuGlide; its other witnesses (`ready`/`sustained`/
    `many_tracks`) are soft; and its genuinely unique bit — real-time audible playback — is unwitnessable
     on a muted, gesture-gated runner. It's a demo in a test's clothing. Fold its intent into **MusuReco's
      audio-proof** (B *plays* its byte-exact real replica through the unlocked voice — §9.10, the demo that
       IS the app): one honest Book, real supply chain AND real playback, replaces the synth showcase.
- **The rate-control / slice family stays — for now.** Signal/Glide/Tune/Edge/Stock/Stream/Conceal each
   isolate one mechanism on a CONTROLLED signal (Conceal's seam measurement, Glide's Schmitt band) where
    determinism is a feature, not a limitation. They are keepers *until* a real-audio integration Book
     exercises the same mechanisms end-to-end on real music over the real transport — at which point re-audit
      each: does it still prove something the integration Book doesn't? If not, retire it too. The aim is
       fewer, realer Books — not a museum of micro-proofs.

---

## 7. Open frontiers (the real remaining work)

The deterministic / single-runner models are built. What's left needs real plumbing or more runners:

- **Real multicast over the Pier** — `@channel` fan-out (Stretch stage 9, Mesh real-sync stage 8). Needs
   2+ runners to verify; the routing/accounting model is the spec for it.
- **Audio actually plays across the wire** — reconstruct the listener's received `%audiochunk` bytes into
   PCM and feed the Player/Glide (Pier todo). Closes "the synapse carries music," not just bytes.
- **The concealment ladder** — repeat/pingpong/crossfade-on-seam under real dropout (Player).
- **Live-voice mixing** — N real Audiolets summing in real time, gesture-gated (Mixer); per-Cell coverage.
- **Wire DJ-cue + Mesh onto real `C**` replication.** The *capability* now exists — **Repli** streams
   `C**` over the real transport to many subscribers with overlapping interests (it is what the whole
    culture plane rides, §1/§5A). What remains is rewiring the two Books that still *model* the descriptor
     sync (MusuCue, MusuMesh) onto Repli-over-Pier, and proving multi-subscriber fan-out with 2+ runners.
- **Real collection source** — Wormhole `bin_read` / a library / proper tags, off the static symlink.

The MVP that ties it together: a real caster on the Pier streaming a real `%record` to two webrtc-peered
 listeners through one relay-only source — the cafe, end to end. Everything above is a tested rung toward it.

---

## 8. The scape — the graph of music, seen as stained glass

Where §1-7 build the *stream*, the **scape** is the *view*: the whole thing as a Cyto graph tessellated into
 **Voronoi stained-glass cells** (Cytui ◈ mode — power-diagram cells coloured by Matstyle; the render is pure
  pixels, so no Book sees it — `voronoi-cells-render`). `lib/V/BigSoundland.svelte` (was Mound) is its toplevel
   (the `/` route Piracy-scape); the human's destination is "Voronoi stained glass graphs of music."
    *Session-continuation brief for this whole area: `Radio_scape_handover.md`.*

**The crush is now a decoupled luxury layer.** The fold that turns a big graph into a few Stuffing chunks
 (`Voro_crush_scan / _walk / _crushable / _clear`) MOVED out of `Musuation.g` into its own family home
  **`Ghost/V/Voro.g`**, enrolled in `CREDULER_GHOSTS` (runner-only — the editor never loads it, so ◈ imposition
   stands down there). Every stamp is **c-side and snap-blind**: `c.stuff` = the fold (Cyto suppresses descent
    past it), `c.stuffy` = the crushed skin — NOTHING is written to `.sc`, so a Story that folds records exactly
     what it would unfolded. There is **no `%Crush_Tree` and no `%Opt`** any more: fold totals come back as a
      live `{folded,count}` return from `Voro_crush_scan(w)`; the demo Books arm the crush **c-side**
       (`w.c.crush_wanted=1`) rather than a `%crushCyto` opt, so nothing is pushed to `w/%Opt` (crushCyto was
        the only For/w: opt, so dropping it drops the whole node). **◈ imposes** the crush on ANY graph
         (`Cyto_crush{on:1}` → `e_Cyto_crush` arms `Scannable.c.crush_wanted` → the crusher runs before each
          scan; off strips via `Voro_crush_clear`). MusuReplica keeps its `%crushCyto` opt and calls the shared
           crusher cross-ghost — the imposition example, and the reason it re-records with the two Voro Books.

**The two demo Books, renamed into the Voro family** (world-name dispatch is ghost-agnostic — `do_fn_for`
 reads `w.sc.w`, so `VoroMitosis(A,w)` in Voro.g just runs; the world MUST be named after the Book):
- **VoroMitosis** (was MusuMitosis) — the render's first gauge: abstract NZ-flora cells that grow, divide,
   and die, crush-folded so each **genus** is one pane. Species are keyed **by genus** (`{Coprosma:'robusta'}`,
    not a flat `%spore` pile), so the fold's Stuffing groups by genus and a speciation split re-keys the
     daughter to its new genus. Watched dividing.
- **VoroScape** (was MusuScape, was live-green 6/6 pre-rename) — the MUSIC twin, with the graph structure
   Mitosis lacks: `%Artist,name / %Track,title` panes (the library), `%Peer,name / %Share,track` (a friend
    and the tracks they share — a share is an EDGE onto a real track), and a **hub** (a track many friends
     share = the power-diagram weight — a hit blazes, a deep cut is a sliver). The graph re-weights LIVE as
      friends come and go; the crush folds every pane at the last beat so the voronoi arms.
- Both now live in `wormhole/Story/Voro{Mitosis,Scape}`; **fixtures were cleared for a fresh live re-record**
   (owed, with MusuReplica — the rename + the c-side flip invalidated the old snaps). Registered in Credence
    `What:Voro` (both `brand_new:1`).

**BigSoundland** (was Mound; the `/BigSoundland` route — the bare `/` 404s now, bots hammer it) boots the machine as a **runner on a music Book**
 (default **VoroScape**, `?B=` overrides) and renders the Cyto UI full-bleed — the run rests in the
  stained-glass state. It is **becoming Sounditron** — the sound twin of Educarium/Editron: a central
   diagnostic Book (NOT a Musu* test, NO Lies+Lang) that lurks in the background, probes the real audio +
    networking environment ("is a track playing? are my people online?"), and surfaces coherent errors so a
     user becomes a reporting test-probe. **First cut, browser-verify OWED** — the `/` tab stalls at Creduler
      spine-load with no identity/share/relay, so BigSoundland.svelte shows a diagnostic surface (boot state +
       the Story-runner UI) while the glass hasn't gathered. NEXT: a LIVE gather (real library via the Crate
        nav + real Piers off the Swarm side, `Swarm_spec §6`) in place of the seeded Book, and a bespoke Voro
         surface; open call for the human — a runner boot joins the relay flock (fine for a live Piracy-scape, but
          `boot_role='editor'` if `/` shouldn't spawn a grid runner).

**Cytui scape UI (2026-07-05):** a **Vexpandy** V-toggle sits in the ◈ bar — it doubles the graph height
 (50vh↔100vh via `class:tall`) and re-fits (`cy.resize()` + `cy.fit`) after the toggle. The layout wave was
  also changed to keep the overlays/cells LIVE through the animation (reusing the drag-frame budget self-heal
   via a `live_layout` flag) instead of hiding them until settle — **owner DISPUTES this holds; UNVERIFIED,
    verify on a live runner or revert** (`Cytui.svelte` `start_live_layout` / `stop_live_layout`).
