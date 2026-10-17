# Radio_design.md — the listen-to-your-friends'-music engine (2026-07-27)

Consolidates the settled parts of `Radio_todo.md` (the pipeline §1-3, the programme-director
 design §9-12), the destination doc `Radio_spec.md`, and the swarm plan
  `Radio_multicast_todo.md` into one readable statement. Written for read + preen; **not
   self-blessed spec**. `Radio_todo.md` §3.6 / §10.1 stay the honest running ledgers, and
    `Heist_design.md` owns the heist/klepto engine — this doc cross-references it, never
     duplicates it.

> **⚠ 2026-10-15:** the "nothing has crossed between two machines" framing below dates from 2026-07-27 and is now false. The music plane (`repli_*` over Peeroleum, through the relay) runs cross-machine in prod: the jamserve daemon serves real listeners on other boxes. Still owed on that road is a *cross-machine Book* (a gate, not the crossing itself) and per-frame signing (`Trust_todo.md` §0). Read `[BOOK]` below as "Book-gated over loopback; live crossing is walked by hand".

**Verification basis:** `[LIVE]` = a real caller in shipped `.g`/`.svelte`; `[BOOK]` = green in
 a Story Book only, no live caller; `[OWED]` = not built. Engines are `Ghost/M/Radio.g` (the
  listening brain) and `Ghost/M/Ra.g` (the stock/stream pipeline); line numbers current to
   2026-07-27. **The organizing axis is loopback vs cross-machine.** Every `[LIVE]` item below
    runs same-world / in-process; the wire under every `[BOOK]` is `Lake_link` — an in-process
     by-reference loopback (frames passed by reference, no serialization, no loss, no NAT, no
      WebRTC). Nothing here has crossed between two physically separate machines. An old
       `[built]` almost always means "Book-green over loopback," never "live cross-machine."

---

## What it is

A peer-to-peer **"listen to your friends' music"** engine — Svelte 5, WebRTC/relay for the
 wire — sitting as three layers on the Repli/Peeroleum transport floor:

- **The listening brain** (`Ghost/M/Radio.g`) — a continuous, era-guarded, detached listen loop
   (`Radio_pump`) that dials a `%Record`, feeds an Opus decoder, and spills PCM onto the
    Web-Audio timeline track after track; plus a background **Stoker** organ that meanders a
     filesystem collection (random-walk, never fully enumerated) and digs tracks into on-disk
      stock. This is the true "meander brain" — the collection gets walked *because* the radio
       listens.
- **The stock/stream engine** (`Ghost/M/Ra.g`) — the `rastock → racast → raterm` pipeline: a
   real Opus DSP path (OfflineAudioContext decode → K-weighted −14 LUFS meter → baked gain →
    WebCodecs Opus → ~2s `.jam` segments), a demand-driven transcode that parks on a want and
     ignites from source, and a paced terminal that decodes what it holds.
- **The scape / faces** (`src/lib/O/glass_kinds.ts` → `ui/*Face.svelte`, hosted by Cytui/Vytui,
   top-level `V/BigSoundland.svelte`) — the whole machine rendered as Voronoi stained-glass
    cells, each subsystem a face overlay on its particle.

And a fourth, **planned** layer: an opportunistic WebRTC **multicast swarm** for chunk-sharing
 (`Radio_multicast_todo.md`) — content-addressed audio chunks routed along the cheapest edges so
  a cafe's relay uplink is crossed once, not once-per-listener. **Not built.**

---

## Settled design

### The meander brain (`Radio.g`)

- **The listen loop** `[LIVE]` — `Radio_go`/`Radio_pump`/`Radio_dial`/`Radio_skip`/`Radio_pause`/
   `Radio_toggle`. RadioFace buttons drive `H.Radio_toggle`/`Radio_skip`; a first gesture resumes
    the AudioContext (`Sound_gat`); mediaSession wires the lockscreen. Every loop is a detached
     `setTimeout` chain guarded by `c.era` — **nothing runs under `beliefs()`** (the mutex law) —
      so pause/skip/replay bump the era and the stale loop falls silent on its next look.
- **The Stoker dig organ** `[LIVE]` — `Stoker_ensure`/`Stoker_wake`/`Stoker_look`/`Stoker_dig`/
   `Stoker_tour`. `Radio_go` wakes it, StokerFace mounts it, InvitePanel can arm it. It resurrects
    standing radiostock first (cheap), then meanders and stocks what the wander finds; it digs
     when fresh-this-sitting tracks run low and churns faster when the set exhausts. `Stoker_tour`
      widens the stock into a moving WINDOW (`w.c.tour_window`, default 40) rather than filling
       once and freezing — a connected friend tours the whole crate instead of hearing its first
        few rooms forever. **The audience gate** (`Stoker_has_audience`, added 2026-10-07): a full
         shelf stops ROTATING — not filling, which is never gated — when no pier of the live self
          has been heard in the last 10 minutes; rotating a healthy shelf for nobody is a whole-file
           read + an ffmpeg pass spent on no one.
- **The meander** `[LIVE]` — `Crate_nav_meander`, an FSA random-walk (one wander down, never a
   scan — the no-enumeration law), called at `Radio.g:852` inside `Stoker_dig`.
- **The older blob variant** `[BOOK/dead]` — `Crate_meander`/`Crate_radiostock_from`; superseded
   by the nav meander, kept only for archaeology.
- **The deck + pool + zine** `[LIVE]` — the Riffle deck (`Riffle_flip`/`tune`/`deal`/`enter`/
   `blat`, the one-button rifle of a collection), the dial-pool (`Radio_dial_pool`, unheard
    friend-crate previews whose bytes have begun to land), and the Faves pocket zine
     (`Radio_mag_pop`).

### The heart + the Heard Mag (`Heard.g`)

- **The heart** `[LIVE]` — `Radio_like` is the one control this whole circuit ever asks a person
   to touch. A press stamps `take`/`hearted_at` on the presser's own `%Mag:heard` card. **There is
    no unlove, anywhere** (the owner's ruling, 2026-09-15): a second press RE-AFFIRMS — re-arms the
     gave-up clock, outdates a stale verdict — it never un-loves. (`Radio_like`'s own header
      comment in `Radio.g` still narrates an earlier, superseded 2026-09-10 "the heart is a
       toggle… a stray tap CAN unlove" framing; that is stale code commentary, not the shipped
        behaviour — `Heard_take`'s own line is unambiguous: "always loves — there is no unlove.")
         `Radio_nay` is the other reaction: bars a track from the pool and evicts its own pool copy
          on the next steward pass; a heisted (possessed) file is never touched. Both superseded
           the old `%Jam` ledger (`%Jam/%Spin/%Like/%Grab`), deleted 2026-09-04.
- **The Heard Mag** `[LIVE]` — `Mag:heard,pub:<me> > Cloud,page:N > Card,id,pub` (`Heard.g`) is the
   one durable ledger every road (heist / FSA / Cave / SoundPool) reads and writes a scalar on;
    `Love_todo.md` is the map, not a second design.

### The stock dig on disk (`Ra.g`)

- **Per-track idempotent stock** `[LIVE]` — `Ra_stock_one` (Ra.g:1061) plus `Ra_stock_ls`/`find`/
   `standing`/`peek`/`drop`/`parse`/`name` over `.jamsend/radiostock/`. A standing `.jam`
    resurrects instead of re-encoding; the live brain digs one track at a time through this door.
- **Per-pub disk cap** `[LIVE]` — `Ra_stock_gc` (Ra.g:522/1142, `Ra_stock_cap()`=256, added
   2026-07-26) keeps only this pub's newest 256 files and wears the oldest off. **No
    reference-tracing by ruling** — a `%Card` refers by id and a dropped file is one idempotent
     re-dig from source, so keep-what's-referenced would be needless bookkeeping. Per-pub (a
      shared `.jamsend` never lets one identity evict another's shelf); bounds PRODUCTION disk
       only, not test determinism.
- **Whole-collection take-N** `[BOOK]` — `Ra_stock` (whole-collection provisioning); called only
   from `RaTesting.g`/`HeistTesting.g`. The live brain uses `Ra_stock_one`, not this.

### The Opus stream pipeline (`Ra.g`)

- **The DSP path** `[LIVE]` — `Ra_source_pcm`, `Ra_lufs` (K-weighted −14 LUFS / −1 dBFS ceiling,
   gain baked into PCM), `Ra_encode_drain` (WebCodecs Opus), `Ra_decode_packets`, `Ra_pack`/
    `Ra_unpack`, ~2s segments. **Real bytes** — one continuous encode per side of the preview→
     stream boundary (preview a const-32s window, stream the on-demand continuation), raw
      length-prefixed Opus packets, no Ogg container.
- **Demand transcode** `[LIVE]` — `Ra_transcode_ensure`/`Ra_transcode_advance` (Ra.g:1382),
   driven live from `Radio_supply_go` (Radio.g:382) while the preview plays, so a track streams
    from the start without ever existing in full. Loopback/local only. The `racast_rate` knob is
     **DEAD** — the encode runs to completion at the encoder's real pace, and a starve is the
      honest race of playhead vs frontier.
- **The live playhead decoder** `[LIVE]` — `Radio_dec_open`/`feed`/`drain`/`close` +
   `Ra_chunk_packets` + `Ra_term_stream_open`. **This is what makes sound** — it plays LOCAL
    transcoded stock, one persistent AudioDecoder per encode, reset only at a `head` chunk (where
     an encode opens and its preskip is dropped).
- **The paced cross-wire beats** `[BOOK]` — `Ra_term_stream_beat` (Ra.g:1784),
   `Ra_term_decode_pulled`, `Ra_pull_beat` (Ra.g:1608). Callers live only in `RaTesting.g`/
    `HeistTesting.g`/`Heist.g`. **The live radio does NOT use them** — it plays local stock, never
     wire-pulled bytes. This is the seam the cross-machine crossing (frontier #1) lights up.

### Share glue + multicast

- **The dial-pool** `[LIVE]` — the unheard friend-crate preview chooser, `Radio_dial_pool` off
   `Radio_dial` (Radio.g:444).
- **The cross-wire share glue** `[LIVE-WIRED]` — `Swarm_share_up`/`loop`/`beat` (Swarm.g:1378) →
   `Repli_arm`, `Ra_offer_stock` (Ra.g:743), `Ra_mag_warm`, `Ra_restock_beat`, `Ra_transcode_pump`.
    Called live from `InvitePanel.svelte:57`, mounted in BigSoundland: stock husk-casts to
     granted friends, per-friend `%Theirs` crates mint in the radio world, the dial plays the
      pool. **⚠ This is NOT loopback-only** — the daemon (`scripts/daemon/main.ts`) runs this same
       glue against real friends over the real production relay (`wss://djamsend.duckdns.org:9999`);
        the 2026-08-21 identity-split incident (`Daemon_todo.md`) is a real `repli_*` frame in
         flight between the daemon and a friend's browser on two separate physical machines, not a
          sim. What is still unproven is a clean, ASSERTED two-tab round-trip under controlled
           conditions — that is "Remaining frontier #1" below, and it is a narrower claim than
            "never crossed a real network."
- **The multicast swarm itself** `[OWED]` — advertise / discover / serve. "Nothing built yet"
   (`Radio_multicast_todo.md`). The routing *policy* exists as `Mesh_route`/`broadcast_stretch`/
    `cafe_spec` `[BOOK]` (MusuMesh green over the mock, no live multi-runner).

### The faces

- **The glass registry** `[LIVE]` — `glass_kinds.ts` maps a mainkey to a face component: Radio,
   Stoker, Tuner, Heist, Door, Riffle, Riff, Zine, Lineup, Crate. Imported by Vytui + Cytui,
    mounted as Voronoi-cell overlays; new particle types get a swatch with no view-code edit
     (Cyto/Matstyle auto-discover by mainkey).

### The programme director (forward design)

- ~~**The Booth taste organ**~~ — deleted 2026-10-16. It was never wired, and it became Yay/Nay on the Heard Mag
   (`Radio_todo.md` §0.d; the design is in `history/Radio_todo_2026-08.md`).
- **The magazine / stimuli machine** `[OWED]` — `Radio_todo.md` §12 (`%Musica`,
   the collection sublimed into media; beliefs served by stance; the jobs ladder) are largely
    forward design, not built.

---

## Remaining frontier (ranked)

The single axis: **loopback → a real carrier between two machines.** Almost everything above is
 built and green, but only over `Lake_link`. The music-repli flow had never crossed a real
  network (2026-07-27; it has since, in prod: see item 1).

1. **`[LIVE by hand, OWED as a Book]` Cross-machine wire-crossing.** *(2026-10-15: crossed. The prod relay carries the repli flow between real boxes daily; what stays owed is R2/R3 below, an asserted, Book-gated crossing, plus `header.sign`.)* Was: **`[OWED]` THE frontier.** Port the husk→preview→stream repli
    flow off `Lake_link` onto `Socket_real` (the real relay, `Tribunal.g:57`, already carrying
     editor↔runner traffic daily) between two real tabs, and land `header.sign` on emit + real
      `verify_trust` on the handshake. Three rungs: **R1** manual two-tab fingers-proof (needs
       the human — an agent can't seal tabs); **R2** an asserted echo round-trip (a new wire
        primitive — no delivery-assert exists today); **R3** a distributed two-runner Book. The
         load-bearing risk: the repli/want machinery has **never faced a mid-beat ~400-900 ms
          round-trip + reconnect** — every Book settles frames "over post_do between beats." The
           transport crypto is unblocked the moment any flow crosses the relay.
2. **`[OWED]` Real collection source.** Point `Ra_stock` at the real `/music` mount instead of
    the synth testsound tones — **the one remaining mock** in an otherwise-real DSP path;
     everything downstream is real bytes.
3. **`[OWED]` Multicast swarm** (`Radio_multicast_todo.md` P0-P4). **P0** — the per-chunk sha256
    content-hash decision — gates the whole layer (a served chunk you can't independently verify
     is a swarm you can't trust). **P1** advertise + **P2** discover are loopback-gateable on one
      runner now; **P3** serve and **P4** the full webrtc swarm need cross-machine and sit behind
       #1.
4. **`[OWED]` Klepto / heist rungs 2-3 (cross-machine)** — the cohort/cafe fan-out and the true
    two-runner return trip. **See `Heist_design.md`** (this doc does not own the heist engine).
5. **`[OWED]` Wire DJ-cue + Mesh onto real Repli-over-Pier; audio-plays-across-wire; the
    concealment ladder (repeat / pingpong / crossfade-on-seam); the live-voice Mixer** (Radio_spec
     §7). Each needs 2+ runners; each is a facet of the one crossing.
6. **`[OWED]` The Booth taste organ + the `%Musica` magazine / stimuli machine** (`Radio_todo.md`
    §11-12) — the programme-director layer, mostly forward design.

---

## What this absorbs (doc map)

- `Radio_todo.md` → the **settled** pipeline (§1-3) and the programme-director design (§9-12) are
   stated above; the doc stays the working worklist, and its **§3.6 / §10.1 are the honest
    ledgers** of real-vs-mock and how-real-is-the-wire — kept referenced, not folded in.
- `Radio_spec.md` → its stage map (§5A culture ladder, §5B audio ladder, §7 open frontiers) is
   absorbed above. **Correct its §5B `[built]` tags:** they mean "Book-green over the loopback
    wire," NOT live cross-machine — §7 of that same spec lists those stages as open, and
     `Radio_multicast_todo.md` says "nothing built yet." Read every §5B `[built]` here as
      `[BOOK]`.
- `Radio_multicast_todo.md` → the swarm design is frontier #3 above; the doc stays the working
   plan for P0-P4 until built.

**Contradictions resolved.** (a) Radio_spec §5B stamps stages 5-9 `[built]` while §7 lists them
 open and multicast_todo says nothing is built — resolved as **`[built]` in §5B = Book-green
  loopback = `[BOOK]`**. (b) Pipeline naming: `Radio_lowlevel.md`/`Radiobuddies_handover.md` use
   the old `Radiola`/`Musu_*`/`Sound_synth` names; the shipped code consolidated to `Ra.g`/`Ra_*`
    — the `Ra_*` names are canonical. (c) The `racast_rate` knob is dead (the encoder paces the
     transcode), superseding the old rate-driven pump. (d) `Lake_link` is confusable with the
      HohoTiles Lies/Lang family — an acknowledged, rename-worthy wart, unrelated to it.

**Retirement recommendation — OVERRIDDEN by the human (2026-07-27): keep both.**
- `Radio_lowlevel.md` — stays where it is (describes the old Radiola `req_cast` / Musuation `Musu_*`
   pipeline, reborn as `Ra_*`; kept for archaeology, the human's call).
- `Radiobuddies_handover.md` — kept with an orienting header: its §5 regroup is done
   (`Sound.g`/`Repli.g` exist, pipeline reborn as `Ra.g`), but §0-1 (the name + the run-without-Story
    Layer-0 destination) and §6 (the frontier) are still live. Concept compost, not history.

Out of scope: `Springcore_meander.md` is **mis-clustered** — a linguistic-core doc with no radio
 content; leave it with the Stuff/Lang family.
