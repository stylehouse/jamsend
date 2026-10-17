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

## 0. What Radio is

*(The owner, 2026-10-15: prefer permanent, uncreased descriptions of a field's wider scope over
 wave-of-work narration. This section states how Radio IS and WHY, not a changelog; §0.1 below
  keeps the 2026-08 log for the arc.)*

### 0.a What Radio is

Radio is jamsend's listen-to-your-friends'-music engine. It is a family of ghosts on Housing+req —
 `Ghost/M/{Ra,Radio,Pool,Heard,Heist,Crate,Orig,Sound}.g` (one sentence each in §0.d) — not a
  bespoke subsystem: a particle, a req, a Story snap works the same way here as anywhere else in
   the machine.

- **The conveyor.** `Stoker_tour` (Radio.g) meanders the filesystem — one FSA random-walk, never a
   scan — and digs tracks into on-disk radiostock, widening a moving WINDOW (default 40 tracks;
    `w.c.tour_window`) rather than filling once and freezing. It RESTS when `Stoker_has_audience()`
     is false — no pier of the live self heard in the last 10 minutes (600000ms) — because rotating
      a full shelf for nobody is pure heat (one whole-file read + an ffmpeg pass per track, every
       round). Filling a short shelf is never gated; only rotating a healthy one is.
- **The heart.** `Radio_like` (Radio.g) is the one control this whole circuit ever asks a person to
   touch. A press stamps `take`/`hearted_at` on the track's Card in the presser's own `%Mag:heard`
    (Heard.g) — durable the instant it lands, nothing to wait for. **There is no unlove, anywhere**
     (the owner's ruling, 2026-09-15): a second press RE-AFFIRMS (re-arms the gave-up clock,
      outdates a stale verdict); it never un-loves. `Heard_take`'s own comment is unambiguous —
       "always loves — there is no unlove" — though `Radio_like`'s header comment still narrates an
        earlier, superseded 2026-09-10 ruling ("the heart is a toggle… a stray tap CAN unlove"); that
         framing is stale code commentary, not the shipped behaviour (a comment to fix next time
          that file is open, not a doc fact). `Radio_nay` is the other reaction: bars a track from
           the pool and evicts its own pool copy on the next steward pass — a heisted (possessed)
            file is never touched. Both superseded the old `%Jam` ledger (`%Jam/%Spin/%Like/%Grab`,
             `Jam.g`), deleted 2026-09-04 — the owner called it *"cursed … a big cancer."*
- **The resident serving body.** `scripts/daemon/main.ts` (jamserve) is a node process that boots
   the whole machine headless and stays up — a peer with no tab-reload lifetime, serving the
    Radiobuddies listen+heist experience. In production it answers at
     `wss://djamsend.duckdns.org:9999` (Caddy in front of this box's own relay).
- **⚠ The wire crosses real machines in prod — it is not loopback-only.** The music plane's
   `repli_*` frames (catalog lines, audio pages, wants, parked/missed) ride `Peeroleum_send`
    straight onto the production relay, and friends' browsers on their OWN physical machines dial
     the daemon over it. The 2026-08-21 identity-split incident is the evidence, not a theory: `no
      Pier for {pulse,ive_got,swarm_hi,pier_accept,repli_ready} from=eed831f1 to=7950f300 —
       DROPPED`, logged on the real `wss://djamsend…:9999` production relay, between a real
        friend's browser and the daemon (`Daemon_todo.md`). The relay's `fromGate`
         (`src/lib/server/relay.ts`, landed 2026-10-13) exists for exactly this reason: it closes
          `header.from` spoofing on that same real wire, because a stranger really could inject
           catalog/audio/want frames onto it. **`Radio_design.md`'s "Remaining frontier #1" — "nothing
            has crossed between two physically separate machines" — is stale against this and is an
             owed edit there (out of scope here: that doc's edit list is "Settled design" only).**
              The narrower claim that IS still true: per-frame cryptographic signing (beyond the
               per-era sender voucher) is still owed — `Trust_todo.md` §1 is the live
                truth of what's real on the wire today.
- **Remote heist.** A heart need not be hauled by the body that pressed it. `Heard_magnet` (the 🧲,
   Heard.g) decides which crew body hauls a given heart, over the pier-less Reach call layer
    (`Swarm_reach_vouched`, Swarm.g) — a `%Remote,heist` handle opened on the station world
     (`RemoteHeist_todo.md`'s G0/G1/R1). Live-only by construction: `Heard_magnet` returns `''`
      inside a Book, so a Book never routes a heart remotely.

### 0.b Where the parts are written

| doc | what's there |
|---|---|
| `Radio_spec.md` | the stage/destination map — §5A culture ladder, §5B audio ladder, §7 open frontiers |
| `Radio_design.md` | the consolidated statement — settled design + the ranked remaining frontier |
| `Radio_circuit_todo.md` | the Heard/♥ circuit — the wire behind the reactions, haggled to one shape |
| `Love_todo.md` | the ♥ rulings — the one intent, three roads, the ledger |
| `Radio_future.md` | the imagination ledger — what the machine knows about listening, and what it could become |
| `Radio_multicast_todo.md` | the swarm design — unbuilt (P0-P4); its cost-routing model `Mesh.g` was deleted 2026-10-16 (§0.d) |
| `Radio_lowlevel.md` + `Radiobuddies_handover.md` | archaeology the owner chose to keep (2026-07-27 override) — the instance-by-instance ladder and the regroup handover |
| `RemoteHeist_todo.md` | remote heisting — Captain forms it, a Cave runs it, the 🧲 decides who |
| `SoundPooling_todo.md` | the pool — press + reach into it, pool-first radio out, cells over it |
| `Daemon_todo.md` | the daemon as a process with no lifetime — boot, GC debt, the production incidents |

### 0.c Still open (verified unbuilt, 2026-10-15)

- **No cross-pub radiostock budget.** `Ra_stock_gc` caps one identity's shelf at `Ra_stock_cap()`
   (256 files) — "the after-a-build sweep of ONE Peering's shelf" (Ra.g). Nothing bounds the SUM
    across many distinct friends' pubs on a long-running daemon.
- **Multicast swarm.** `Radio_multicast_todo.md` P0-P4 (content-hash, advertise, discover, serve,
   full webrtc swarm) — "nothing built yet," confirmed current.
- **The `%Musica` stimuli machine** (§12): the zine verbs `Musica_publish/fold/forget/recast_offer/stand`
   (Heist.g) are Book-proven but have no live caller. (The Booth taste organ that sat beside it is gone:
    §0.d.)
- **Per-frame signing/AEAD on the music plane.** The 2026-10-13 relay from-check closes
   `header.from` spoofing; per-frame integrity and privacy (WT1/WT2 in `Trust_todo.md`
    §0.3) are still owed.
- **Real-time wire playback.** The live radio plays only locally-stocked bytes — `Ra_term_stream_beat`
   / `Ra_pull_beat` (the wire-pulled decode path) have callers only in Book ghosts, never in the
    live brain. Nobody has heard a track decoded live off a wire pull.
- **Daemon GC debt.** No lease/reap mechanism for `%parked_want`s or caster registrations on a
   process with no tab-reload lifetime to clean up after it (`Daemon_todo.md` §11).

### 0.d The ghosts, one sentence each (audited 2026-10-16)

Every `Ghost/M/*.g` is Jamsend's own: the app foundation (crew, wire, trust) lives in `Ghost/S` and `Ghost/N`.
 "Book-only" means a method that only a Book reaches: no live caller, no face, no verb. It's proven, but it
  isn't part of the running app.

| ghost | what it is | Book-only (no live caller) |
|---|---|---|
| `Ra.g` | the pipeline: stock a track (loudness → baked gain → Opus chunk particles), the shelves (Mine, Theirs, pool), the terminal that plays | `Ra_term_decode_pulled`, `Ra_term_stream_beat`, `Ra_decode_packets`: the wire-pulled decode (see §0.c "real-time wire playback"); `Ra_stock` + `Ra_stock_cascade` (the Book's whole-collection pass); `Ra_rec_copy`; `Ra_seed` (a Book's PRNG pin, test-only by design) |
| `Radio.g` | the radio itself: the dial, the Stoker conveyor, the riffle, Yay and Nay, the source chip | `Radio_sound` (the pure "is it making noise" read the Supervisor was meant to consult) |
| `Pool.g` | SoundPooling: the pool's policy, its steward, and the Reach that fills it from a Cave | `Ra_pocket_mirror` (the pool, snap-visible), `Ra_upgrade_scan` (a smuggled lofi copy read as an upgrade queue) |
| `Heard.g` | the Heard Mag: a Card per track per pub, the reactions, the roads, the crew mirror | `Heard_seed`, `Heard_mirror_home_find` |
| `Heist.g` | acquiring: original bytes into the collection, the keep and the haul, the rummage, the Berth, the magazine on disk | `Heist_beat` + `Heist_flatten` (the rung-1 quarantine-mirror loop; live heists ride the keep); **`Heist_vouch_ok`** (the receive-side check of the origin's signature on an offered husk; only `Heist_beat` calls it, so live heists check body hashes (`Heist_xfer_breach`) but NOT who vouched; a `Trust_todo` question); `Heist_meta_dir`, `Heist_marrauding`; the `Musica_*` zine verbs (§0.c) |
| `Crate.g` | digging a collection through a nav: metadata from a path or tags, the transcode, the pile | `Crate_walk`/`Crate_meander` (the tree walk; live uses the Stoker's meander), `Crate_nav_payload`, `Crate_transcode_begin` |
| `Orig.g` | the `%Original` grade layer: a real Ogg/Opus container written back, and its reader | `Orig_ogg_export` (+ `Orig_rec_packets`, `Orig_export_preskip`): the phone-sync `.ogg` export, written but never called |
| `Sound.g` | the audio engine: synth PCM, entropy measure, the real muted device | `Sound_synth_records` + `Sound_synth_tone` (MusuRadio's synth set) |

**Cut 2026-10-16** (the owner: *"hunt everything down"*), each in one sentence so it can be reinvented:
- **`Radiola.g`**: the July cursor model of the old ack-backpressure spool (`%Caster` → `%Terminal`, keep-ahead,
   wear, skip; its Glide rate curve `Glide_decide` moved to `Sound.g`), which proved the streaming spine on pure arithmetic before Ra and Repli
    carried it for real. Its Books went with it: MusuStaple/Stream/Stock/Live/Wear/Skip/Crowd, plus
     MusuSignal/Glide/Edge/Conceal, which were the real-audio underrun, rate and dropout-concealment family, and
      `Sound_real_stream`, the starving pump they drove.
- **`Mixer.g`**: a future Radio direction, the DJ deck (onset/tempo detection, beatmatch by rate, multi-cell sum render,
   equal-power crossfade, a monitored cue), proven by MusuMix and MusuCue on synth beats.
- **`Mesh.g`**: a future App direction, the platform as one sync seen in many places: Dijkstra cheapest-route over
   peer and relay edges, and the multicast stretch (cross the relay once, then fan out over WebRTC), proven by MusuMesh.
    The real version is `Radio_multicast_todo` over Peeroleum.
- **`Booth.g`**: the `tune:` handle and the `%Ban` do-not-play list. It was vetoed and never wired, and it became
   **Yay** (the ♥, `Heard_take`) and **Nay** (`Heard_nay`) (design in `history/Radio_todo_2026-08.md`).
- **`Siphon.g`**: tags as playlists (`%Tag` › `%Tagged,of:`, so a tag's children *are* the playlist; never given a
   face) plus `Siphon_pull`, a one-track press into the pool that `Pool.g` now does itself as `Pool_press_one`.
- **Uncalled methods** (not even a Book reached them): `Crate_open/decode/radiostock_from` (the first crate entry),
   `Ra_home_the`, `Ra_proof`, `Ra_head_map`, `Radio_mag_cursor`, `Radio_shelf_walked`, `Riffle_clear`,
    `Heard_verdict_keys`, `Heist_known_categories`.
- **Docs**: `Follow_todo` (the DJ-monitor follower) and `Phone_instrument_todo` (the phone as an instrument), deleted
   outright as easy to reinvent (one line each in `Radio_future.md`); `Siphon_todo` → `history/`.

---

## 0.1 log

*The 2026-08 evening-by-evening log (~1,900 lines) moved to `history/Radio_todo_2026-08.md` on 2026-10-16.*

---

## 0.9 Parking lot — low-priority fixes (deferred, not blocking any rung)

Known-real problems found in passing that we deliberately DON'T stop the mainline for. Patch them
 opportunistically alongside more relevant work; each names its own proving Book so it lands with a gate.

- **THE INVITE SHOULD OUTLIVE ITS HANDSHAKE — the human's cure for the half-seal (2026-08-06).**
   *"we should remember the Invite until both parties have agreed they have fully processed it, so we can
    keep giving all the Grants until done."* That is the right shape and it is bigger than the bug. Today an
     invite is a MOMENT: `pier_accept` fires once, builds the far side's whole %Pier, and is then forgotten —
      so any single lost frame strands the pair forever, and `Swarm_reaccept_incomplete` is a patch that
       re-drives one specific half from one specific side (and is blind to the other, see §0). A remembered
        invite inverts it: the invite becomes a **standing req** — a thing with liveness that is not finished
         until BOTH ends confirm they hold BOTH grants — and the re-send stops being a special-case repair and
          becomes the ordinary behaviour of an unfinished req. That is the house idiom ([[req-is-where-state-
           belongs]]): *prefer a req over a status string; it carries its own liveness.* It also gives the glass
            something true to show ("sealing with Lefto — 1 of 2 grants confirmed") instead of a link that
             silently half-works. Design owed: what "fully processed" means on the wire (an explicit
              seal_confirm carrying the grant set you hold?), and when the req may finally retire.
   **HALF-DESIGNED + MOVED (2026-08-06) → `Swarm_compact_invite_todo.md` §9** (that doc already owns the
    3-frame seal, and its §7c predicted this exact half-seal on 2026-07-27). Five rungs, each standing
     alone; **rung 1 needs no wire at all** — a side missing its OWN grant re-mints it from its own key.
      The old garden's `Tyranny.svelte` (`Idzeuganise`) is the reference for a handshake that is allowed
       to be slow as long as it narrates what it waits on. Leave this bullet as the pointer; design lives there.
- **UI trims the human asked for 2026-08-06 (space is the scarce resource on the glass).**
   Vyto has too many cells: **drop the "a peer to come online" cell** and **the Crates cell** for now — the
    glass should be about the music, and a cell that is usually idle is spending permanent space on an
     occasional message. **Move the time-alive/uptime readout INTO the list of Piers** — it is networky, it
      belongs beside the peers rather than owning a cell. (`BeatFace` / `CrateFace` / `DoorFace` are the
       organs; `DiagFace` is the opt-in gate they already sit behind.)
- ✓ **DONE — Transfer graph: floor the vertical extent at 200KB/s, and drop the separate up|down bars.**
   Landed in `TransferFace.svelte` (`FLOOR_KBPS = 200` at :60, applied in `sparkPath`; the split bars
    removed, only the merged spark + the numeric `rx↓ · tx↑` head remain). Kept for the rationale:
     autoscaling made 3KB/s of ack chatter draw the same mountain as a real 3MB/s pull — a fixed floor
      makes **tiny amounts look tiny**.
- **SLOW: sprinkle the OLDER Books with `%see:` assertions about clear pointables.** The early Ra*/Musu*
   rungs were written when the snap-fixture diff WAS the whole gate, so most of them assert nothing by name —
    they only claim "these 532 lines are what happened". That is a brittle, illegible gate: it reds on any
     deliberate source change (see §0's four-cause MusuRaChase autopsy — a clock pin, a `path:` stamp, a
      `String()` and an ephemeral reclassification, none of them regressions), and it says nothing about WHAT
       the Book proves. Where a Book crosses a boundary a human can name, name it. The model is
        `RaTesting.g` — `%see:'the playhead crossed the first boundary onto chunks transcoded on demand'`,
         gated on `fed.sc.held > 0`: a once-noticed, self-describing claim that survives re-records because it
          is about MEANING, not bytes. Obvious pointables owed one: the `%Preview`→`%Stream` seam (the
           encode boundary Radio drains and re-opens a decoder across), first-sound, the resume cursor landing
            on the chunk the listener actually reached, a grant going live, a mirror freezing on revoke.
   WHY IT MATTERS BEYOND TIDINESS: a named claim is the only part of a fixture that survives a re-record with
    its meaning intact — so it is what lets us ACCEPT a legitimately-churned snap without the accept being an
     act of faith. Every one added makes the next re-record cheaper and the next autopsy shorter.
   NOT a sweep — do a few whenever you are already inside a Book for another reason. No commas in the
    sentence (the peel parser splits on them; use an em-dash).
- ✓ **RESOLVED for the goner-delete (MusuFreeze — HeistTesting.g).** `Musica_recast_offer` now computes
   `allowed = this.Repli_allowed(w, to, from)` and gates BOTH goner emissions — the cloud delete (Heist.g:1136)
    and the record delete (Heist.g:1150) — so a revoked follower's mirror is frozen, not remotely deletable.
     RESIDUE: the raw `Repli_retire` primitive (Repli.g:308) is still ungated, but gating a Repli **core**
      primitive is the human's call (its only live caller is a Book); left as-is. Original finding, kept for
       context:
- **`Repli_send_lines` bypasses the consent gate — goner DELETES leak to a REVOKED follower.**
   `Repli_offer` (Repli.g:283) is `Repli_allowed`-gated, but `Repli_send_lines` (Repli.g:229) is NOT, and
    `Musica_recast_offer` (Heist.g:706/720) calls it directly for goner `op:delete`s. So the wire refuses to
     ADD to a revoked peer but will still DELETE from their mirror — an asymmetric consent bypass (a revoked
      peer's held copy should be frozen, not remotely editable). Found by MusuBuddy's adversarial review
       (2026-07-14); MusuBuddy's own revoke scene ADDS a card, so it never exercises the leak (see 11 stays
        sound). FIX: gate the two goner-delete `Repli_send_lines` calls in `Musica_recast_offer` on
         `Repli_allowed(w, to, from)` (surgical — leaves the Repli core primitive alone; check other callers
          before gating the primitive itself). PROVE: a delete-after-revoke Book (MusuBuddy's see-11 shape but
           a GONER not a neu) — the dropped record/cloud does NOT reach the revoked mirror + zero frames burned;
            adversarially review AND live-gate (an unrun security assertion is the worst false-green).

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
        the job                -- %Caper,at:<pier> + optional match (absent = klepto = everything); filings pinned as DATA.
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
        flatten                -- the %Caper + mirror delete; nothing attributes who gave what afterward.
        < cohort / cafe (rungs 2-3)  -- one page-stream to N kleptos, then a LAN broadcast tree.

      the app surface  -- where a person drives it.
        < create-a-heist       -- a gesture that points a %Caper at a Pier (today ONLY the test Book mints one).
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

Five Books in `Ghost/Story/RaTesting.g` (24 + Chase's 15 `%see`) — re-record any time the Record shape moves:
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
    pre-pin the set (`grep -aoE "%see:'[^']*'" Ghost/Story/RaTesting.g`), confirm every sentence
     present after. Immediate redispatch after an accept can hit the engaged begun-wedge —
      `release`, wait ~8s, redispatch; no tab reload needed.

---

## 2. The cluster — layout, names, and the wiring bombs

```
Ghost/M/Radiola.g              spine — the reusable mechanism (req_cast, the window)
Ghost/Story/MusuTesting.g        the Musu* Books (Story ghosts are grouped under Ghost/Story/,
                                like PeerTesting.g — the file is the artifact, MusuStaple is
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
| `Ghost/Story/PeerTesting.g` | `Ghost/Story/MusuTesting.g` |
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
       gen; space-separated GFILES for several). Leaf Book ghosts (RaTesting.g) compile live fine.

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
   that keeps this project inside `Ghost/M/` + `Ghost/Story/MusuTesting.g` + the two snaps + this
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

**THE RULE CLIMBED A LEVEL — the PRODUCT Books retire too (2026-07-14).** The re-draw ladder does not
 stop at Ra*: the three standalone Ra* PRODUCT Books proved stock|cast|play in a configuration the
  destination never runs — a stream with no catalog naming it — so once **MusuBuddy** (§0, the
   magazine-driven pipeline where the stream is BORN from a browsed `%Musica` card) stood LIVE-GREEN ×2,
    **MusuRaStock / MusuRaCast / MusuRaTerm were DELETED** (Book code in `RaTesting.g`, their fixtures,
     their Credence + Ality rows). The same discipline governed it: nothing deleted until its re-draw
      stood green. What is NOT redundant and STAYS: **RaStream / RaChase** (the streaming-race — park at
       the boundary, feed past it, the village dial — which the static catalog cannot express),
        `MusuGenerateTestsMusic` (the seeder), and the real-audio lowlevels (MusuSignal/Glide/Tune/Edge/
         Radio/Conceal — the PCM aspect proofs; RaTerm was their consolidation target and MusuBuddy now
          is). `Ghost/M/Ra.g`'s spine verbs are untouched — MusuBuddy rides them. The magazine and the
           pipeline were always the IDENTITY and BITSTREAM halves of one experience, meant to meet, not
            two proofs of one job.

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

> **Vocabulary sync (2026-07-13 — see `Voro_todo.md §The Se process`).**  This section's "the Se"
>  is the ORGAN — canonically a **%Seem** (a particle holding a live `Selection` on `sc.Se`;
>   `i_Seem`/`o_Seem`, parks off-snap).  **%Se** is reserved for the small SNAPPED reading a Seem
>    projects, worn iff a `Selection.process()` produced it (mainkey = provenance).  So below:
>     "the LIBRARY as a Se over a folder tree" = a Seem whose SUBJECT is the folder tree, its
>      neus|goners the offers|retires; "the Se's pairing carries continuity" = the Seem's D-sphere
>       (`bD`).  The prose keeps its old name; the build recipe + honest-projection rules live in
>        `Voro_todo.md §The Se process` and apply here unchanged.

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

Rung 1 (loopback) is BUILT and live-gate-pending: `Ghost/M/Heist.g` (the pure engine) + `Ghost/Story/HeistTesting.g`
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
- **Flatten-off.** The `%Caper` (+ its `%filing` decisions) and the quarantine mirror delete; collections +
   `newlyadded` remain and neither says who gave what.
- **Design/test split.** The machine is first-class on `w` (Peerings/Piers/Grants/Idzeug/Libraries/%Record/
   %Body/%Caper/mirror); every test observation hangs under `w/%testing` (the `heisted:<nick>` node with its
    `on_disk` monitoring, `census`/`sealed`/`newlyadded_shape`/`denied`/`flattened`, the 10 `%see`). Snap reads
     as machine-left, opinion-right.
- **Determinism + hygiene.** The engine stamps NO test markers on the world (a transient FSA hiccup no longer
   leaves a permanent marker). The marrauding namespace `.jamsend/test-marrauding-of-bookrun/<nick>` is swept
    files-only at BOTH start and end (`.jamsend` is gitignored; the repo never keeps WAV bytes; dirs persist
     empty so the next run's FSA handle cache is not poisoned).
- **The wire is loopback** (`Lake_link`, see §10.1): real protocol, mock carrier.

**The edge — what's `<` unbuilt:**

- ✓ **DONE — metadata from tags.** Stale by the time this was read (2026-07-30): `Heist_census` (Heist.g)
   and `Crate_nav_payload` (the radio-stocker, Ghost/M/Crate.g) both now read id3/vorbis/RIFF via
    `Crate_meta_from_tags` (music-metadata@11) first, falling back to `Crate_meta_from_path`'s filename split
     only for an untagged file. The test tones carry real IART/INAM tags agreeing with their filenames
      (`LiesFunk.svelte` `Musu_gen_testsounds`) precisely so this could land without a fixture re-record.
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
- **Remembered denials — CONDEMNED (2026-07-13 ruling; the rip is owed).** Built overnight as
   `%Tombstone` because it was SAFE to build blind (see the honest note below: "additive to fixtures,
    no design fork") — never because it was asked for; the %Ban rebirth was already host-vetoed. The
     human: "I never asked for tombstoned — an overly simple take on what will come that's going to
      confuse us." The kill reasons: the only load-bearing skip is `Heist_held` (what you HOLD); the
       deny ceremony has no real populator (an out-of-band file delete never mints one, so it misses
        the common prune); `%UnGrant`'s never-drop durability is earned by SECURITY (absence
         ambiguous, stakes are trust), not taste; and the §12 world is PULL-shaped (wants/cursors) —
          a blacklist defends against a push that stops happening. Where the concern re-homes:
           per-heist poke-out = the MANIFEST gesture (deselect before a byte moves); durable
            per-relationship narrowing = the §9.2 `%Share` match (the negative space of the match);
             taste bans = the Booth IF a surface ever wants them. Rip checklist = §11.5's migration
              checklist re-purposed (DELETE at each site, not rename); HeistTesting.g loses the retomb
               scene (~steps 20-30), one toc re-seed + reload + re-record.
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
2. tag-vs-filename metadata ✓ done (see above); `<` the real `$artist/$album/$track` landing tree still
    stands (retires the `4t-` prefix).
3. `<` **merge-into-existing** + "already have" surfacing + the directory-listing confirmable — these
    three are one feature: a real library tree the heist reconciles against.
4. `<` **single-track play/skip/decide** session.
5. `<` **repointable** mid-heist.
6. ✗ **remembered denials** — CONDEMNED 2026-07-13 (see above; the %Ban rebirth was vetoed first,
    now the gear itself goes — rip owed); `<` **similarity / format-upgrade** still open.
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

## 11. The Berth (§11.0–11.6, the Booth, retired 2026-10-16)

*The Booth (`Ghost/M/Booth.g`, "taste as standing facts": the `tune:` handle and the `%Ban` list) was vetoed, never wired,
 and deleted 2026-10-16. It became **Yay** (the ♥, `Heard_take`) and **Nay** (`Heard_nay`) on the Heard Mag. Its design
 is kept in `history/Radio_todo_2026-08.md`. §11.7 stays here because the Berth is live.*

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
- **API** — ✓ BUILT 2026-07-12 in `Ghost/M/Heist.g` (region `//#region berth`, LocalGen-green;
   homed at the first consumer, the heist, NOT a new organ ghost as ruled). As built (two refinements
    from the sketch): `Berth_dir(root, prepub, name)` → the on-disk path;
     `async Berth_open(nav, root, prepub, name)` → deWaft the toc.snap into a live C tree (mints an
      empty `%Waft` when absent, a first open is not an error), stashing the dir on `waft.c.berth_dir`
       (runtime-only) so — refinement 1 — `async Berth_save(nav, waft)` needs only the waft;
        refinement 2 — save uses `write_file` (the snap is TEXT, enWaft returns a string) not
         `bin_write`; `async Berth_reset(nav, root, prepub, name)` drops one Waft's toc.snap by name,
          or sweeps the Pier's whole berth via `Heist_sweep` when name is falsy.
   The MusuBerth Book proving the round-trip + reset-with-Story is authored + registered, LIVE-GATE
    OWED (the runner was wedged at build time — dispatch after a tab reload).
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

## 12. The stimuli machine + the magazine — protocols become media between brains (vision-checked 2026-07-13)

The riff that reframes §10's heist and §9's Pier reality as ONE mechanism. Repli already moves
 arbitrary C** (deL/enL, buffer pages, PULL, %Sent_Tree — §1.3); only convention says what it moves
  is %Records. The generalisation: each Pier keeps MAGAZINES — curated C** media — and every
   protocol is magazines moving between Piers, with a STIMULI MACHINE at each end deciding what an
    arrival means. A heist request stops being a protocol verb and becomes a want that replicates
     to the ORIGIN Pier and surfaces on its brain-agenda — the owner's grants, tombstones and taste
      mediate at the owner's end (the anti-klepto inversion; §11.7's front door seen from the other
       side of the wire). The UI and the front door become the same object: a magazine reader.

### 12.1 Beliefs are SERVED, by stance — one brain, and a door per relationship

(Language reset 2026-07-13: the kitchen/counter metaphor is DEAD — "counter" reads as a tally in a
 codebase that counts everything, and the kitchen named nothing that was not already the House.
  The ruling itself stands; only the words moved.)

beliefs()/Selection.process over H/A/w is the giant HIGH-TRUST pool: every ghost method mixes into
 the House (eatfunc), so any req a sweep touches can reach everything. The human's ruling
  (2026-07-13): the House does NOT want carving into per-Pier sandboxes — that is subtractive
   security (take the full pool, remove the knives, hope you found them all), at most an
    experiment. The assuredly-correct cut: **beliefs are SERVED onto the magazine's properties by
     the Se pass, scoped by STANCE** — and the two stances are NOT symmetric instances:
 **for-oneself is not an instance — it is the House.** Publish + evolve the magazine as the
  collection churns (re-census, rename missions minting %Renamed, the curated voice), feed one's
   own listening: one's own House sweeping one's own media, full trust because it is all yours.
    The M-rungs carry the verbs; the standing version is Upkeep-shaped — a standing pass that
     notices drift and republishes, paced over enrolled followers the way Ra_transcode_pump
      already revolves.
 **for-another is THE DOOR — the only new construct.** The narrow per-relationship handler a
  foreign want meets: it decodes the want into plain scalars, asks the grant (repli_allow(peer,
   at) — asked at every leg, cached nowhere), matches READ-ONLY against the magazine, and emits
    streaming legs or a noted refusal. That is its ENTIRE belief set — correctness by
     CONSTRUCTION, not subtraction: foreign input is only ever READ as data, nothing arriving is
      minted into a swept space, so a hostile tree claiming req:/eternal lands INERT — the escape
       routes were never in the room. Many doors revolve while the one House keeps working.
        "Door" is the codebase's own admission word (SwarmDoor, "consulted at the door", "refused
         at the door") — doors are the admission-gate family the way %UnGrant is the
          decision-fact family.
 Prior art in miniature (all live-green): `w.c.repli_allow(peer, at)` is already the
  per-relationship consent answer (Repli.g:249); `Repli_register_caster` enrolls serving Piers;
   `Ra_transcode_pump` (Ra.g:1007) is a demand loop revolving over every enrolled caster. §12
    grows THAT shape from chunk-serving to magazine-serving. And Matstyle is the rhyme for
     property-level serving: it autovivifies STYLE by mainkey classification — the Se pass serves
      BELIEF by property × stance the same way.
 **Said in the Voro voice** (language sync with `Voro_todo.md` ①, the Se-up model — the two docs
  are converging on ONE Se philosophy): a Selection pass over a data space computes READINGS, and
   readings wear `%Se` as PROVENANCE (Se:scape/Se:census/Se:drift there; an Se:serve family here)
    — never to be confused with the space's own content. The magazine is CONTENT (authored voice
     + computed census); the House-work and the door are ONE Se pass in two STANCES, and what they
      produce is the SERVE-MODEL: %Se-worn readings of the same magazine — what is fresh and owed
       a re-publish (for-oneself), what is servable to WHOM under which grant (the door), what moved
        (%Seem resolves report drift; ABSENCE IS THE QUIET READING). The Voro_model pattern
         carries over whole: the full working model rides OFF-snap (c-side), a distillation snaps
          into a diagnostics world, so Books prove the readings without wire or pixels —
           snap-testable serving. One-fact-one-place keeps the seam honest: %Renamed is authored
            FACT in the magazine (content); NOTICING a rename broke a cursor is a READING (Se).
 Open mechanics (the next cooking, deliberately unresolved): what a DOOR IS
  mechanically (a per-relationship w under one serving world? a %Door particle family? — w is
   already the isolation/snap boundary with mutex-frozen reads), and how per-property belief
    binding looks concretely. (`House.subHouse(name)` exists, Housing.svelte.ts:553, but shares
     the FULL pool wholesale — :561 `Object.assign(sub, this.ghosts)`; parked as experiment
      material only.)
 Bombs that SURVIVE the redesign: the wire must NEVER mint live machinery — a decoded foreign
  tree must not graft into ANY swept space (today's "a %req below w never pumps without
   hand-stamped c.up" is an ACCIDENT doing duty as a wall, don't lean on it); HMR re-mixes ghost
    methods, so any construction-captured serving fns go stale on haunt; `sourceHousing` is
     already stamped on cross-House elvis (i_elvistwo :573) if provenance is ever needed.

### 12.2 The magazine — %Musica, the collection sublimed into media

A magazine is a curated C** projection of the filesystem: census walks the disk into %Records,
 crush folds the homogeneous sludge behind husks so it reads as MEDIA, and the Pier's own voice
  (Waft:Map — music-blog material, §11.7) rides beside. It lives as a Berth Waft, so it berths
   per-identity, travels with the music, and Repli moves it like any C** (grants gate it).
    album|title metadata is stored IN the magazine — that is what cursors anchor on (12.3).
     Authored, generated (the Ra entropy seam), or sublimed from disk: same media, same mover.
 **STRUCTURE (built 2026-07-13, M1): still %Records, with a %Cloud layer.** The magazine holds the
  census cards UNCHANGED — `%Record,id,artist,title,album,path,body_hash` (the SAME mainkey+scalars
   the collection holds, minus the %Body byte-slices; NO `genre` — a genre is a FOLDER not a card
    scalar and no census mints one, so the first cut's fabricated `genre` was a shape that cannot
     exist). Records do NOT hang straight off the Waft — they group under a
      **`%Cloud,randomic,created_at`** ARRIVAL BATCH:
```
Waft:Musica
  Cloud,randomic:<id>,created_at:<ts>     ← one publish's new arrivals, stamped when they came
    Record,id:…,artist:…,title:…,album:…,path:…,body_hash:…
    Record,…
  Cloud,randomic:<id2>,created_at:<ts2>   ← a later publish's batch
```
  So every Record wears the time it joined (read up through its Cloud), and a whole era is
   forgotten at once — `Musica_forget(nav, mag, cutoff, pub)` drops old Clouds AND cascades the
    radiostock-unlink to disk (BUILT 2026-07-17, `Ra_stock_cascade`, bias-to-keep; MusuReap green ×2).
     `randomic`+`created_at` are PARAMS not wall-clock: the app passes a real random
     id + Date.now, a Book PINS them (the Heist_marrauding runid pattern) so snaps stay deterministic.
  **`randomic` = a RANDOM DRAW (the human's clarification 2026-07-13):** a Cloud is not "the whole
   collection this tick" — it is a HANDFUL randomly MEANDERED out of a collection that is NEVER fully
    enumerated (`Crate_meander` random-walks the crate track by track — Crate.g). So the magazine is
     random samples accreting over time; `randomic` is the draw's fingerprint (it was randomly pulled),
      NOT merely a batch nonce. A publish that meanders more surfaces a NEW Cloud beside the old ones.
  **`Musica_fold` — the "one brain" (built 2026-07-13, §12.1):** `Musica_publish` split so the PURE
   reconcile-then-add is `Musica_fold(mag, lib, randomic, created_at)` (in-memory, no disk) and
    `Musica_publish` is the Berth wrap (open → fold → save). ONE magazine-building brain now serves both
     the disk publish AND the wire (M2/MusuVend folds in memory and offers over Repli). The fold stamps
      `cloud.c.repli_loc = ['Cloud','randomic']` so a Cloud reconciles by its draw-fingerprint on the
       wire (the default `['Cloud']` loc would collapse every batch to one blur at a follower).
 **Publish is RECONCILE-then-ADD** (`Musica_publish`, Ghost/M/Heist.g), not wipe-and-rewrite: drop
  any published id the collection lost + any emptied Cloud (the recast — a dropped track leaves no
   orphan), then lay the collection ids not yet in any Cloud under a fresh Cloud. `Musica_cards(mag)`
    is the flat catalog view (walk Cloud→Record); the Cloud layer is for GROUPING+forgetting, not
     browsing one era at a time.
 **OBSERVABLE-PLANE DISCIPLINE (the human's ruling, 2026-07-13):** a Book must put the magazine's
  actual Cloud/Record tree ON the snap (MusuMagazine reflects the disk-read handle into w/%Mag), so
   the fixture DIFF shows a card appearing / a second Cloud arriving / a dropped card vanishing — the
    DATA is the proof, %testing counts only accompany it (see [[snap-data-not-judgement]]). A
     judgement-only snap (`published,records=2`) is the drive grading its own homework.
 **BUILT (2026-07-13 night):** (a) the FOLD — `Musica_publish` is proven off MusuHeist's REAL
  census (Uno's landed collection reflected into w/%Mag on the snap; the deny gives a recast on real
   data), so the magazine no longer rides a minted toy; (b) cp-LANDING — `Heist_rel_for` lands at
    `<dest-root>/<source-path>` (`Heist_cp_path` sanitizes `..`), tags are metadata never file-naming,
     the mislabeled see inverted (the file keeps its name, the catalog knows the truth), `Heist_land_rel`
      deleted. MusuHeist 19→22 steps, 16 sees, green ×2. STILL owed (all `// <` at their sites, ride
       real disk / M2): weird tag text clamp; non-audio sibling probe + album-art/kid-safe oracle;
        dedup album+disc+track-else-path; landing-path clash verdict.
 (Was the blessing-owed plan; the human blessed it "build it!" and it landed.  Historic corner-case
  ledger: Corner-case ledger: weird tag text enters snapped
         scalars (clamp control chars + cap length); non-audio sibling in a picked-up dir (probe
          audio, parked `// <` at Heist_census); album-art needs an oracle (parked `// <` in
           Crate.g); landing-path collision → skip+`clash` verdict on the manifest.
 **The corner-case answers (the human, 2026-07-13 — all captured as `// <` at their code sites):**
  - **Non-audio siblings NEVER copy** (kid-safe): a heist moves AUDIO only, never `cover.jpg`/`.nfo`/
     stray images a stranger placed in the directory. Same rule as embedded album art — visual bytes
      need an ORACLE authority before they ride the wire, and v1 carries none (marks joined at
       Heist_census KID-SAFE + Crate_meta_from_tags ALBUM ART).
  - **Dedup must NOT drop a distinct track** (the Muslimgauze problem: 12 `Muslimgauze - Untitled` all
     share artist+title, so today's `Heist_held` collapses 11 as "already held" and eats them). The
      fix is layered and BIAS-TO-KEEP: (1) widen identity to artist+title+**album+disc+track** when
       tags carry them; (2) SENSE a thin identity — when those are absent so multiples cannot be
        separated, DO NOT dedup on it (a wrong drop loses music; a dupe costs one delete); (3) the
         **filename/path** is the reliable fallback axis — cp-landing keeps the original name, so
          `01 Untitled.flac`..`12 Untitled.flac` already distinguish on disk, and a same-path collision
           at the destination is the true-dupe/clash signal. So: dedup by rich-enough tag-identity ELSE
            by path, never drop on a thin tag-identity alone. (Rides the cp-landing wave — `Heist_held`
             mark.)
 Renames: a Pier that reorganises (retitles an album, splits an artist) mints %Renamed redirect-
  facts beside the renamed node — from:, to:, at: — IN the magazine, so followers receive the
   redirect through the same pipe as the content. (Naming note: "breach" is taken — it is the
    body_hash integrity fail in Heist_land. %Renamed is a NEW fact family — cousin of the
     %Tombstone/%UnGrant decision-facts, but a POSITIVE redirect and WINDOW-able: markers may
      supersede/expire, unlike tombstones which never drop.) Followers can then run renaming
       missions over their own filed copies — optional per Pier, a later rung.
 **BUILT (M3, 2026-07-14 — MusuRename, LIVE-GREEN ×2):** `Musica_rename(mag, id, key, to, at)` is the reorganise
  gesture — apply the retitle AND mint the `%Renamed` beside the card in ONE stroke (never a rename without its
   redirect). The marker + the retitled card ride the SAME Repli pipe to a follower; the card updates in place
    (loc `['Record','id']`, `title` a merge prop — no fork) and a follower's stale cursor heals through the
     replicated marker. `Renamed_mint` stamps `repli_loc:['Renamed','key','from']` so multiple markers stay
      distinct on the wire (the default `['Renamed']` loc would blur them). Missions stay on merge-PROP keys
       (`title`/`album`/`artist`) for now — a rename of a LOC key (id) crosses as add-not-move until
        delete-propagation is wired to the fold (`Musica_forget`'s PROPAGATION `// <`).

### 12.3 Cursors — a stack of matches, healed by rename markers

A %Cursor is a serialized STACK OF MATCHES — a descent path of o()-queries ({Musica:1} →
 {album:'X'} → {title:'Y'} → a seq window) — not indices. It is the native query algebra, all
  scalar: cursors SNAP, berth, and replicate like anything else. Resolution walks the stack
   re-finding each match; a failing level consults RECENT %Renamed markers and retries with the
    redirect (the heal), noting what it healed. This is where-we're-up-to for any follow/browse/
     replication-resume — resumable, showable (the gathering-performance UI), per-relationship
      (berthed). Prior art rhymes: Point,text: (content-addressed cursor, the text substrate) and
       %Map rel offsets — the Point re-anchoring problem class, solved once, deliberately.
 NOT a rebuild of Repli's inseq/pages — wire-level sequencing stays; a cursor is the MEANING-level
  position. Scope to magazine-follow first.
 **BUILT + LIVE-GREEN ×2 (C1, 2026-07-13 — modelled on `%lematch` per the human's steer):**
  the serialized name is a `%Dogear` (the mainkeys `%Cursor`/`%cursor` are taken — LiesKeep focus-history +
   LangCurse Interest), a linear spine of `%curs` match-segments (one `o()`-query each). `Cursor_*` in
    `Ghost/M/Heist.g`: `Cursor_make(home, into, queries)` mints it, `Cursor_resolve(dog, root)` walks the
     stack re-finding each level and returns `{ok, at, depth, landed}` or `{ok:false, at, depth, missing}` —
      the CLEAN-fail verdict is the exact seam C2's `%Renamed` heal plugs into. Snap-safe wildcard: the type
       rides as `wild:<Type>` (re-inflated to `{Type:1}`), literal pins flat, so it round-trips without the
        `Cloud:"1"` footgun and is KEY-AGNOSTIC (absorbs the §0 Cloud-model change). Proven by **MusuCursor**
         (three sees: lands-on-leaf, lands-on-a-level, clean-fail), LIVE-GREEN ×2.
 **C2 THE HEAL — LIVE-GREEN ×2 (MusuHeal, 2026-07-14):** `Cursor_resolve` grew a heal branch — a failing level
  consults recent `%Renamed,key,from,to` markers beside the last node reached (`Cursor_heal`) and retries with
   the redirect, landing on the moved node and recording `heals:[{key,from,to}]`. `Renamed_mint` lays a marker
    beside the renamed node IN the magazine (a positive, window-able cousin of `%Tombstone`/`%UnGrant`, `at:`-
     stamped, newest-wins). The heal is transparent to an un-renamed cursor (no marker → empty `heals` → C1's
      verdict unchanged). MusuHeal proves it with a marked/unmarked twin: the marked cursor heals to the new
       identity, the unmarked one fails cleanly — the marker is provably load-bearing.
 **C3 THE RESUME — LIVE-GREEN ×2 (MusuResume, 2026-07-14):** a `%Dogear` homed INSIDE a magazine survives a full
  `enWaft`→`deWaft` round-trip (the disk-less core of Berth save+open; MusuBerth owns the real FSA disk) and still
   resolves to the record it named — the resumable browse. Runs on ANY runner (no FSA), deterministic. `Cursor_resolve`
    walks DOWN via children (never `c.up`, which doesn't survive decode), so it resolves cleanly against a freshly-
     decoded tree; the `%Dogear`/`%curs` spine encodes with zero protocol work (the enWaft vocabulary gate is parked —
      any mainkey rides). Discrimination: a live-only bookmark under `%testing` does NOT ride the snap (re-decoded
       magazine carries exactly one Dogear); independence is gated on the re-decoded cloud being a DISTINCT node
        object — an adversarial hardening, since `deWaft` structurally can't alias so the earlier `!old.ok` leg was
         tautological.

### 12.4 The jobs ladder — little, Book-gated, mostly independent starts

Gate 0 (owed): MusuHeist accept to 15/15 + MusuBerth first live run — bank the substrate.
 **M — magazine**: M1 Musica_publish (census + crush → a %Musica Berth Waft, metadata in-magazine) ✓;
  M2 two-Pier magazine replication (the existing Repli pipe, grants gate) ✓ LIVE-GREEN ×2 2026-07-13
   (MusuVend Book — magazine folds in memory, Repli_offers whole husk, grant on↔off↔on, forget; 11/11
    caveat:0, 6 sees); M3 ✓ %Renamed markers minted by a rename mission + replicated with the magazine
     (MusuRename Book, LIVE-GREEN ×2 2026-07-14 — `Musica_rename` = apply+mint one gesture; the marker rides the
      pipe and a follower's stale cursor heals through it; `Renamed_mint` `repli_loc` keeps markers distinct;
       9/9 caveat:0, 5 sees, all SOUND adversarially).
 **D — the door** (12.1; the K rungs DISSOLVED 2026-07-13 with the metaphor): D1 the
  door-hardening Book — the for-another serving path over the magazine, grown from the existing
   consent hook (repli_allow + register_caster + the pump); its Book includes the SABOTAGE scene —
    a hostile stream claiming req:/eternal mainkeys lands INERT, because the door only reads
     want-shapes; an ungranted want is refused with the refusal noted (was K1). The for-self
      standing evolve is House-work, so it files under M as **M4** — census-diff re-publish
       (✓ its wire heart — MusuRecast, LIVE-GREEN ×2 2026-07-14: `Musica_recast_offer` folds + offers neus +
        crosses a path-carrying op:delete per goner at BOTH the record and cloud level, no orphan; ✓ made STANDING —
         MusuStanding, LIVE-GREEN ×2 2026-07-14: `Musica_stand` fingerprints the census and re-publishes only on a
          real change, an unchanged census puts ZERO frames on the wire),
           rename missions as a standing Upkeep-shaped pass (owed), the revolving service pacing over
            enrolled followers (Ra_transcode_pump generalized — the roster FAN-OUT, needs per-follower mirror
             routing, owed) (was K2).
  **D1 SPLIT (2026-07-13): part b LANDED (MusuDoor, LIVE-GREEN ×2, `f76b3d7e`); part a OWED.** The
   recipe below was followed for part b (the sabotage wall) with ONE correction from the build: the
    canary is NOT an immediate-child check (an adversarial review caught that as a false-green — it
     misses a deep-walking-sweep regression) but a DYNAMIC `req_sabotage` handler that flips `w.c.pwned`
      if the buried req is ever PUMPED, proven live by a control that pumps an identical req through a
       throwaway holder world. Part (a) below (the crypto door) is the remaining rung.
  **D1 BUILD RECIPE (teed up 2026-07-13 — build once M2 is live-gated):** fork MusuVend (the wire +
   two Piers + the grant seam are proven there). (a) HARDEN the grant: swap MusuVend's Book-owned
    `w.c.grants` toggle for the LIVE Swarm verdict — copy MusuHeist's shape
     (`w.c.repli_allow = (peer, at2) => Swarm_pier_live(Swarm_peering(ident).o({Pier:1,pub:peer})[0], 'Music')`
      via `SwarmStaple_ident`/`Swarm_mint_idzeug`/`Swarm_redeem`); NOTE this reintroduces seal wall-clock
       → the fixture needs an EntropyProfile (Wref:Trope/Ra/AudibleEntropy or a fresh seal-tolerant one)
        + a warming re-accept — MusuVend's determinism is deliberately NOT carried into D1. (b) THE
         SABOTAGE SCENE (the §12 heart, the anti-klepto inversion): a hostile origin offers a magazine
          whose card carries a grafted `req:`/`eternal` child; the follower merges it (Repli_merge reads
           it as plain data). ASSERT it lands INERT — a canary the malicious req WOULD set (a w.c flag, a
            minted particle, a side-effect) stays UNSET across a full belief pass, because the wire never
             stamps c.up into a swept world. Make it BREAKABLE: if the merge stamped c.up + pumped, the
              canary flips → the see drops. BOMB (§12.1): today's inertness is "an ACCIDENT doing duty as
               a wall" (a decoded req has no c.up into a swept space, so it never pumps) — the sabotage
                see PINS that accident so a future change that starts pumping foreign trees goes red; the
                 REAL construction-level wall (a merge that provably cannot graft live machinery) is the
                  deeper owed rung the see guards toward. (c) keep MusuVend's ungranted-refusal scene.
                   Do NOT ship the sabotage see without a LIVE run — an unrun security assertion can be
                    vacuously green, the worst false-green; adversarially review AND live-gate it.
 **C — cursors**: C1 the %Dogear primitive + resolver (resolve | fail cleanly, own Book scenes) —
  BUILT + LIVE-GREEN ×2 as MusuCursor (§12.3, 2026-07-13);
   C2 ✓ heal via recent %Renamed (MusuHeal, LIVE-GREEN ×2 2026-07-14 — the `%Renamed` fact-shape + `Cursor_heal`
    landed here; M3 mints the same markers from a real rename mission later); C3 ✓ cursor as follow-progress,
     berthed (MusuResume, LIVE-GREEN ×2 2026-07-14 — a berthed %Dogear survives an enWaft→deWaft round-trip and
      resumes the browse). **The cursor arc C1·C2·C3 is complete** — and M3 (MusuRename, LIVE-GREEN ×2 2026-07-14) has now
       exercised the heal on LIVE wire-replicated markers, so the remaining cursor-flavoured work is U (the
        magazine reader turns wants into cursors).
 **S — stimuli surfacing**: S2 the agenda bridge (a want the door accepted mints an %Errand on
  the Brink — the owner SEES the want); S3 the heist rides it — the want-driven front door
   (§10.2 #4 merges here: genre starts + the origin's Waft:Map advice; klepto demotes to one
    mode).
 **U — the magazine reader** (Big*land family): browse a replicated %Musica, wants become cursors;
  build AFTER the rungs give it real data.
 (P — the projected subHouse — PARKED as experiment material per the 12.1 ruling; do not build.)
 Dependencies: M1 ✓ (landed + live-recorded 2026-07-13); M2 ✓ (LIVE-GREEN ×2 2026-07-13); D1 part b ✓
  (MusuDoor, the sabotage wall, LIVE-GREEN ×2 2026-07-13); C1 ✓ (MusuCursor cursors, LIVE-GREEN ×2 2026-07-13);
   C2 ✓ (MusuHeal, the %Renamed heal, LIVE-GREEN ×2 2026-07-14); C3 ✓ (MusuResume, the berthed-cursor resume,
    LIVE-GREEN ×2 2026-07-14 — the whole cursor arc is done); M3 ✓ (MusuRename, LIVE-GREEN ×2 2026-07-14 —
     `Musica_rename` mints `%Renamed` from a real reorganise gesture + replicates it, the heal now proven on live
      wire markers); M4 (first rung) ✓ (MusuRecast, LIVE-GREEN ×2 2026-07-14 — `Musica_recast_offer` crosses a goner
       as a path-carrying op:delete at the record AND cloud level, no orphan on the wire); M4 (standing) ✓
        (MusuStanding, LIVE-GREEN ×2 2026-07-14 — `Musica_stand` fingerprints the census and re-publishes only on a
         real change, a quiet census sends zero frames). The OPEN rungs, in rough order of readiness:
     **M4 (rest)** — the roster FAN-OUT: standing over N enrolled followers (Ra_transcode_pump generalized), which
      needs per-follower mirror routing (Repli_mirror_lib keys off one `w.c.repli_mirror_pier` today) — plus
       rename missions as a standing Upkeep pass; the census-diff wire heart AND the single-relationship standing
        pass are now proven, this is the roster shell around them; **D1 part a** (harden the grant toggle into the
         live Swarm_pier_live door — one
        revoke-mid-relationship scene, best folded into MusuHeist; reintroduces seal entropy, so needs an
         EntropyProfile + a warming re-accept, ATTENDED) is the remaining door rung; S3 needs D1 + M2 + S2; **U**
          (the magazine reader — wants become cursors) needs M2 ✓ + C1 ✓ and is now UNBLOCKED (the whole cursor
           stack it leans on is green).

### 12.5 The heist wriggles in — every gear re-homes into making | replicating | responding

Nothing built is thrown away; each existing gear has a §12 home waiting:
 - `Heist_census` (disk → %Records + husks) → **MAKING**: the House's sublimation step. Census
    stops being per-heist prep and becomes the standing publish (M1, then M4's standing
     republish) — a landing that changes the collection re-publishes the magazine. This is now BUILT:
      `Musica_recast_offer` (M4/MusuRecast) re-folds and crosses BOTH the neus and the goners (a lost card
       = a path op:delete, a lost era = a cloud op:delete); and `Musica_stand` (M4/MusuStanding) is the
        standing pass over it — it fingerprints the census and re-publishes ONLY on a real change (an
         unchanged census sends nothing), so a follower's mirror tracks the collection's drift with no
          orphan and no wasted wire. Remaining: drive the pass off a real Upkeep + fan it out over a
           follower roster.
 - `Heist_offer_all` + the mirror → **REPLICATING**: the mirror IS a replicated magazine slice
    already; the bespoke offer verb is the first thing to RETIRE (at M2) into a Repli pull of the
     %Musica subtree. Husks/crush carry over unchanged.
 - `Heist_manifest` → **RESPONDING, follower side**: the want evaluated against one's own
    collection (it already reads (job, mir, own_lib)); it grows into the reading a browsing
     follower sees BEFORE wanting — look-before-commit becomes the reader's verdict column.
 - `%Caper,at:` job scaffolding → the WANT-BUNDLE: short-lived, cursor-pointed into the magazine
    (C1/C3); "exists for as little time as possible" already matches the stimulus shape.
 - `Heist_beat` / `Heist_land` (streaming, body_hash + breach, filing, the verdict rows) →
    **UNCHANGED**: the serving legs the door drives (D1) and the landing side the wanter keeps;
     the verdict rows stay the job's honest ledger (holds/fresh once the tombstone rips).
 - `%Tombstone` → CONDEMNED (2026-07-13, §10.2): it rips out entirely — a refusal is the door's
    noted MOMENT (not a ledger); per-heist poke-out is the manifest gesture; durable narrowing
     waits for the §9.2 `%Share` match.
 - `newlyadded` → `Waft:Listening` (the §11.7 migration): probation feelings become Berth document
    rows; the arrival LOG stays honest beside it.
 - `Heist_marrauding` + `Heist_sweep` → unchanged: the Books' reset floor (MusuBerth proves the
    berth rides it).
 - grants / `repli_allow(peer, at)` → the door's gate (D1): per-relationship consent
    generalizes from chunk legs to magazine serving.
 What DIES: the tombstone (ripped, §10.2) — then offer retires at M2, and klepto "everything you
  offer" demotes to one mode at S3.

---

## 13. The toplevel — /BigSoundland, where it all comes together

The one place every spring above surfaces as a page a human actually touches: `src/lib/V/BigSoundland.svelte`
 (the scape) + the glass under it (Vytui, `%Heist`/`%Radio`/`%Stoker`/… faces) + the InvitePanel strip. Every
  other section here builds an organ; this is the body they get worn on. Items land here when they are about
   the **assembly** — what a person sees when the parts are all present — rather than about one engine.

Expect this section to want an ironing-out pass of its own before long (owner, 2026-08-05: "it probably
 needs another ironing out soon but not yet") — the two view modes below have drifted apart and no single
  ruling governs what shows in which. Don't do that pass piecemeal; do it as one sitting, with the page open.

### 13.1 The two views, and the ActionButtons (owner, 2026-08-05)

✅ **FIXED, in place — the ask itself landed 2026-08-30.** `BigSoundland.svelte`'s sprawl view now
 carries a per-House `scape-house-acts` rack (no `show_actions`/cog gate, no `active`-only
  restriction) beside every House heading, exactly the owner's ask below; the old triple-gated
   `scape-panel` rack (`sprawl && show_actions && active`) still exists alongside it for a
    different job (the single focused-House panel). The rest of this entry is kept for its
     reasoning about the two-views split, which is still unsettled.

**The ask: show the ActionButtons for each H automatically — "they are too useful."** Today the rack is
 triple-gated at `BigSoundland.svelte:247` — `{#if sprawl && show_actions && active}` — so it needs the ▦
  sprawl, then the ⚙ cog, and even then shows only the *active* House's actions. Ungating it to
   one-rack-per-House is small; the reason it is filed rather than done is that it lands on the wrong side
    of an unsettled line:

- **The dev/working view** — where the ActionButtons belong, on sight, per House, no cog.
- **The end-user view** — "everything invisible except the Vyto and the Invite interface, the only non-Vyto
   thing hovering over the top, as the actual users will find it." The owner reports this as a mode that is
    **default off**. It is NOT in the tree under any name I could find: the nearest thing is sprawl-*off*,
     which is already the default and still shows the header bar, the glass badge, the House chips, the
      InvitePanel and the whole diagnostic surface. So either the mode is remembered from elsewhere, or it
       is owed — and it has to exist before "show everything useful by default" is safe, because it is what
        keeps the useful clutter off a real user's screen.

So the order is: **settle the two views first, then ungate the rack into the dev one.** Doing the rack
 first just moves clutter into the view that has no escape hatch. Related and already mapped:
  `UI_seams_todo.md` S1 (quiet the resident glass) is the same question asked of the Vyto cells, and its
   `?diag` gate proposal is a candidate shape for the end-user mode.

## TODO — the dial should FLY (the human 2026-08-07)

**"react to clicking Heist (and next-track too — push a TODO for making this fly around the available
 tracks super pleasingly — it might even want to be on a separate thread)."**

Two halves, and the first is the general lesson:

- **Every glass control must move on the CLICK, not on the pass.** `post_do` defers the write to the next
   belief pass, so a control shows nothing until then — and an unmoved control invites a second click,
    which is exactly how the LOFI tickbox ended up unticking itself right as ▶ start was pressed
     (HeistFace `toggleLofi`, fixed there with a local `wish` + an ABSOLUTE value rather than a toggle read
      late). ⇊ Heist and next-track want the same treatment. Audit the rest of the glass for controls whose
       only feedback is a model round-trip.
- **Next-track should fly around the available tracks.** Not a cut — a visible traversal of the pool
   (ShuffleFace already draws it as pips, lit = chunk 0 landed = dialable). The human's read is that it may
    want its own thread, i.e. it must not share the belief loop's mutex: a traversal that stutters whenever
     a pass runs long is worse than no animation. Worth checking whether the wave/grawave timing Cyto
      already uses can carry it before reaching for a worker.

Related, same session: `avoid loading half of the Record/Preview until we start playing it` — `Ra_keep_ahead`
 (default 4) pre-pulls the FULL preview window of that many upcoming records, so the pool sits at ~50% held
  before anything is chosen. Wanted: seed depth ≈ chunk 0 (enough to be dialable, which is all
   `Radio_dial_pool` gates on), full preview only for the track under the needle. NOT attempted — it moves
    MusuStock / MusuRadio / MusuReplica fixtures and wants a session with the whole suite in reach.

## TODO — BOOT TAKES ~35s BEFORE ANY MUSIC CAN MOVE (measured 2026-08-07)

The human: *"refreshing Righto after a while, it doesn't connect Radio for a while there... but then
 eventually, 30s later or so, comes right"* + *"why does this boot take so long"*.  Their read was
  "we're loading too much Record data before we get around to playing" — **measured false**, twice:
   from `crate-born` to `first-sound` was **250ms**, and from `page-first` to `first-feed` **36ms**.
    No byte transfer is involved in the delay at all.  Do NOT optimise the pull path for this symptom
     (that is what the `Ra_keep_ahead` item above would have done — it addresses the 250ms).

**The chain.**  `Swarm_share_up` (Swarm.g:1751) bails with `share-no {why:'radio world not standing
 yet'}` until `top.c.radio_w` is stamped, and `Stoker_ensure` (Radio.g:1148) — reached only from
  `Radio_dial` — is the sole place that stamps it.  So between the seal and the first dial the tab has
   no share loop: it can neither offer its own stock nor register an rx for the friend's cast.  Sealed,
    Music-granted, happily playing its own shelf, and completely deaf.

Righto's boot ring (`wormhole/_trace/runner-f5da6599b8505881-1786093330013.jsonl`):

     +5.0s   seal → station-up → share-no {radio world not standing yet}
     +5.0s   advertise piers:1 granted:1 told:0 records:0 cw:0 selfs:0 homes:0 stocks:0
     +20.6s  advertise ... records:0 cw:0        (still nothing, 15s later)
     +24.3s  boast-heard {of:96d0cf88, records:0}   ← the friend says "I have nothing"
     +35.0s  share-up
     +35.2s  boast-heard {of:96d0cf88, records:8}   ← the truth, 11s after the lie
     +40.9s  tour dug:8 stock:8 · advertise records:8 artists:3 cw:1 selfs:1 homes:1 stocks:1

Lefto's ring is the mirror image (seal +20.5s, share-up +28.0s, true advertise +35.1s).

**Two fixes, independent.**

1. **ORDERING — arm the share on the radio WORLD, not the first dial.**  Nothing about
    `Swarm_share_up` actually needs the dial to have spun; it needs the world the stoker shelves in.
     BigSoundland already knows the resident world at boot (`boot_param('B') || 'Sounditron'`), so
      `radio_w` can be stamped when that world stands.  Keep `Stoker_ensure`'s stamp as the idempotent
       backstop — losing that race is the 2026-08-06 bug its comment describes, and this must not
        re-open it.

2. **TELL NO FALSE FACT — suppress the count, don't send a zero.**  For 30 seconds each peer
    advertises `records:0` with `cw:0`, and `cw:0` means `census_w` was never pointed at the radio
     world, so that zero is *known false at the point of sending*.  Righto wrote Lefto's "records:0"
      down at +24.3s and only unlearned it because a later boast happened to land.  While `census_w`
       is unset, `Swarm_gossip_music` should send **no count** rather than a zero — a peer that says
        nothing is honest, a peer that says "0" is lying and the lie gets recorded.  Same "not yet
         reported as never" shape as `Radio_supply_go` (Radio.g:727) reading the first null from
          `Ra_transcode_ensure` as `'preview only — source unreadable'`; see Sounditron_todo.

**3. THE STEP CLOCK — and it is a TIMER, not work (measured 2026-08-07, second pass).**  The
 resident Sounditron world's steps pace the whole thing, and the marked work in a step is
  `quiesce 0.25s` + `snap-cost 41ms` + `vyto-wait 60ms` ≈ **350ms of 7.8s**.  The gaps had no marks
   of their own — but the two electrodes already planted (`advance`'s `resolve`/`to_step`, and
    `quiesce`→`snap-cost`) bracket them exactly, and reading them settles it.  Per step, on
     Righto (`...1786093330013`) and Lefto (`...1786095853919`), every step, both tabs:

     advance→quiesce      0.25s     the drive itself: free
     quiesce→snap-cost    3.64s     ← gap A
     snap                 0.04s
     vyto-wait            0.06s
     vyto-wait→advance    3.80s     ← gap B   (to_step 3801 / 3800 / 3803, resolve 0)

**`to_step` is 3801 ms ±3 on two independent machines across every step.  That is a timer.**  A
 backlog jitters; a fixed constant is a clock.  The constant is `reset_interval()`'s ambient tick —
  `interval || 3.6` at `Hovercraft.svelte:72` — plus `AMBIENT_MAIN_TICK_MS` (200), the `main()`
   throttle.  3600 + 200 = 3800.  `resolve:0` clears the Runstepped callbacks outright, and the
    fixed 200 ms in `schedule()` hides *inside* the interval rather than adding to it.

**The shape.**  Both gaps are the same event: a `post_do` sitting in a todo that nothing drains.
 `post_do` (`Housing.svelte.ts:834`) only pushes and bumps `todo_version`; the drain is the
  `$effect` at `:561`.  A healthy drain is `ANSWER_CALLS_TICK_MS` 50 ms, or 4 ms galloping — three
   orders off what we measure.  So the wakeup is being lost, and the item then waits for the ambient
    heartbeat, which `_really_answer_calls` **re-arms inside the mutex on every drained item**
     (`:1103`).  Lose the wakeup and you pay a *whole fresh* 3.6 s, every time.  Two `post_do`s per
      Story step (`do_step`, `snap_step`) ⇒ 7.2 s of a 7.8 s step is the tab waiting for its own
       heartbeat.  **~93% of the resident step clock is a lost wakeup, not work** — which is exactly
        why every electrode aimed at work came back cheap.

**The watchdog for this already exists and cannot fire here.**  `Story.svelte:2424` documents the
 lost wakeup and re-drives the drain — but it re-drives `Run.answer_calls()` under a
  `Run.todo.length` guard, while `story_drive` posts both phases with **`H.post_do`** (`H = this as
   House`, the Story ghost's House — `Run` is a different House with its own todo).  Wrong queue,
    and the guard therefore reads 0 forever.  It is also only reachable from inside `poll_step`,
     which is not running during either gap.  Doubly inert, silently.

**Why Books never showed it:** MusuReco steps at ~1.1 s on the same runner in the same minute.  So
 the wakeup is NOT universally lost — something about the *resident* tab (live glass, live organs,
  `trickle`, a contended top-House mutex) loses it.  Nailing that last inch is one cheap electrode,
   not a theory: stamp the push time in `post_do` and compare it at drain against the `c.drain_at` /
    `c.drain_tried_at` / `c.drain_why` that `_really_answer_calls` already writes.  It forks clean —
     **`drain_tried_at` stale by ~3.6 s ⇒ the `$effect` never fired** (fix: make `post_do` self-
      driving, `this.answer_calls()` after the push — re-entrancy-safe, since the mutex branch bails
       and re-arms its own 50 ms retry); **`drain_tried_at` fresh with a `drain_why` ⇒ it fired and
        was gated**, and `drain_why` names the holder.  Do not apply either fix before that fork is
         read — they are different bugs with the same face.

**IT IS NOT CPU, AND The/TimeSpool SAYS SO OUTRIGHT.**  Sounditron's own spool carries
 `TimeTotal:beliefs,avg=0.077` and `TimeTotal:step,avg=0.011` — **77 ms of belief-mutex time summed
  across every step of a whole run**, against a boot of ~60 s.  `collect_time_sample` sums
   `sum_beliefs_time` over every step with a `Run_trace`, so that is the total thinking the machine
    does.  There is no work to optimise and no "turbo mode" to switch on: 99.9 % of the boot is the
     machine waiting for permission to run the next 11 ms.

**ELECTRODE PLANTED 2026-08-07 — `drain-lag` (Housing.svelte.ts).**  `_push_todo` stamps `e.c.push_t`
 plus a snapshot of three new monotonic counters, and the successful shift in `_really_answer_calls`
  emits a `drain-lag` mark for any item that waited past `DRAIN_LAG_MS` (300).  `.c` only, so it
   cannot reach a snap; the `world` printer is generic, so it renders with no CLI change.  The three
    counters are the fork — `calls` (answer_calls entries: did the `$effect` fire at all?), `gated`
     (…bounced off `answer_calls_waiting`), `tries` (`_really_answer_calls` entries: did anything
      actually LOOK at the queue?), reported as deltas since the push.  Reading key is inline at the
       emit site.

**First live reading, and it refutes the leading hypothesis:**

     drain-lag  H=Mundo tag=think waited=567 calls=6 gated=5 tries=1 depth=3
                why=beliefs mutex held 0s by H:Mundo think

 **The `$effect` is NOT lost — it fired 6 times.**  What is lost is the drain: *5 of 6 wakeups
  bounced off the `answer_calls_waiting` throttle, and only ONE look at the queue happened in 567 ms*
   — against a 50 ms gate that should have allowed ~11.  So the suspect moves from "the Svelte wakeup
    never arrives" to **`answer_calls`'s own throttle swallowing its re-drives**, and `post_do`-goes-
     self-driving would NOT have fixed it (a self-drive lands on the same throttle).  Good thing the
      fork was read before the fix was applied.
 Caveat, stated so nobody over-reads one sample: this is `H:Mundo` on a **compile-busy tab with 0
  piers**, not a resident Sounditron boot.  It proves the electrode works and it rules one branch
   out; it is not yet the boot measurement.  **Next: a Sounditron boot with the electrode live** —
    read `calls`/`gated`/`tries` on the `fn:story_step` and `fn:story_snap` marks specifically.
 (The edit lands in a `.svelte.ts`, which has no HMR boundary — every live tab full-reloads.  Here
  that is convenient rather than costly: a fresh boot is exactly the thing being measured.)

### THE READING, off Righto reloading (2026-08-08) — and it is TWO bugs, not one

**A. The step clock: the queue is simply never looked at again.**  Every `H:Story` mark, every step:

     H=Story tag=fn:story_snap waited=3600 calls=2 gated=0 tries=2 depth=1 why=
     H=Story tag=fn:story_step waited=3600 calls=2 gated=0 tries=2 depth=1 why=
     H=Story tag=fn:story_snap waited=3712 calls=2 gated=0 tries=2 depth=1 why=

 `gated=0` acquits the `answer_calls_waiting` throttle.  Empty `why` acquits the mutex — nothing was
  blocking.  `calls=2` in 3600 ms against a 50 ms gate that allows ~72.  **Two looks, neither
   blocked, and the item still sat for a full ambient interval.**  With `depth=1` the picture is
    exact: look #1 drained the item AHEAD of ours and left ours standing; look #2 was the 3.6 s
     heartbeat.  Nothing in between.
 So the failure is the "come back for the rest" self-restart at `Housing.svelte.ts:1129-1130` —
  `// we should come back to the rest of them` / `this.todo_version++`.  It runs **synchronously
   inside the `$effect`'s own call stack** (`$effect` → `answer_calls` → `_really_answer_calls`, not
    awaited, and the bump precedes the first `await`), i.e. it is a write to the effect's own
     dependency from inside that effect — and the measurement says it does not reschedule anything.
      `gated=0` is the proof: had the effect re-run and bounced, `gated` would be ≥1.  It never ran.
 **The queue therefore advances one item per EXTERNAL wakeup**, and on a quiet resident boot the
  only reliable external wakeup is the 3.6 s tick.  Books escape it because a Book run is a constant
   rain of external wakeups (elvises, `ponder_now` off every disk settle) that keep poking the queue.
 **The fix is the shape already proven next door:** the mutex-held branch re-drives out-of-band
  (`setTimeout(() => this.answer_calls(), gate)`) and *that* path spins fine — see the contended
   Mundo marks below with `tries` in the thousands.  Do the same after a successful drain instead of
    trusting the reactive self-bump.  Not applied yet.

**B. AN 11-SECOND BELIEFS-MUTEX HOLD ON `H:Mundo` DURING BOOT — new, and not small:**

     H=Mundo tag=fn:handle_inbound waited=10529 calls=3439 gated=1721 tries=1718 why=beliefs mutex held 11s by H:Mundo fn:?
     H=Story tag=fn:story_step   waited=10698 calls=2222 gated=1110 tries=1112 why=beliefs mutex held 11s by H:Mundo fn:?
     H=Sounditron tag=think      waited=10744 calls=380  gated=190  tries=190  why=beliefs mutex held 11s by H:Mundo fn:?

 Three Houses, one holder, ~10.7 s each.  Note `tries` in the thousands here — the retry chain works
  perfectly when something drives it, which is exactly what makes (A)'s `tries=2` damning.
 **This is real work, and TimeSpool did NOT see it** — `collect_time_sample` sums
  `sum_beliefs_time` over the *Story Run's* steps only, so an 11 s cycle on Mundo by a non-Story fn
   is invisible to it.  Correct the "there is no work" claim above to: *no work in the steps*.
 **Prime suspect, already instrumented:** `Swarm.g:1809`'s untagged `post_do` around
  `Swarm_share_beat` — its own `beat` electrode logged **ms=5286, 2564, 1534** during exactly this
   boot window.  `fn:?` is the tell that the `post_do` carries no `see`, so the drain cannot name it.
    **DONE 2026-08-08 — every `post_do` in the tree now carries a `see`.**  Note for anyone auditing
     this the way I first did: **grepping the `post_do(` line is wrong** — the `extra` sits on the
      CLOSING line of a multi-line closure, so a line-grep reports a dozen false positives and hides
       the real ones.  Paren-match from `post_do(` to its close and test the tail.  Doing that over
        all 333 files of `src/ Ghost/ scripts/` found **10 genuinely untagged sites**, now tagged:
         `Swarm.g` (`swarm_share_beat` — the suspect), `Tribunal.g` ×2, `Peeroleum.g` ×2,
          `PeerTesting.g` ×2, `SwarmTesting.g` ×2, `MachPeerily.svelte` (`keygen_<side>`).
           Five `.g` ghost-compiled, 5/5 ✓.
  **AND A TRAP WORTH THE TRIP: `src/lib/pinned_stable/{Peeroleum,Tribunal}.go`.**  A deliberately
   FROZEN copy of the spine, still untagged and left that way on purpose.  `Lies_transport_up`
    returns early on `role !== 'editor'`, so it is the **editor's bootstrap alone** — the editor
     cannot ride the spine it is editing.  Consequences to hold on to: a `.g` edit to
      Peeroleum/Tribunal **never reaches the editor's own channel** (promotion is a hand
       `cp gen/N/ → pinned_stable/`), and conversely a player tab is unaffected by it.
  **Why the tag did not appear immediately on Righto:** HMR swaps the module, not the live closure —
   the transport `port` object was built at boot from the pre-tag code, so the running `send`/
    `deliver_soon` are still the old ones.  **The holder names itself on the next reload**, not before.

### FIXED AND MEASURED 2026-08-08 — the drain now comes back for its own queue

One line at the tail of `_really_answer_calls`, after the mutex releases:

    if (this.todo.length) setTimeout(() => this.answer_calls(), this._gallop_gate_ms())

Before → after, both tabs, off the trace rings:

     to_step               3801 ms  →  200-213 ms   (200 is schedule()'s OWN setTimeout;
                                                      the queue latency is now ~0-13 ms)
     quiesce→snap-cost     3.64 s   →  0.02-0.11 s  (what is left IS the snap: 19-86 ms)
     step interval         7.8 s    →  ~0.48 s      (~16×)
     share-up              +30 s    →  +7.9 / +8.4 s

**The `~30 s sealed-but-deaf` window is now ~8 s.**  The `H:Story fn:story_step` / `fn:story_snap`
 drain-lag marks stopped emitting entirely — they no longer clear the 300 ms floor.

**WHAT REMAINS IS `swarm_share_beat`, AND IT NOW NAMES ITSELF** (the `see` tags landed):

     H=Mundo tag=fn:handle_inbound waited=5238 … why=beliefs mutex held 5s by H:Mundo fn:swarm_share_beat
     H=Story tag=think             waited=1750 … why=beliefs mutex held 5s by H:Mundo fn:swarm_share_beat

 Its own `beat` electrode agrees: single beats of **5189 ms and 7935 ms**.  That is the one step in
  each run that still costs 3.01 s / 2.04 s instead of 0.48 s — the whole residual.  `Swarm_share_beat`
   holding the beliefs mutex for 5-8 s is now the top item on this TODO, and unlike everything above
    it, it IS work: go read what the beat does per pass before assuming it is another wait.

**Do not "fix" this by shortening the 3.6 s interval.**  That is the thermostat, not the fault, and
 lowering it just makes a lost wakeup cheaper while leaving every other consumer of the ambient tick
  paying a faster clock.  The wakeup is the bug.

**Read the table right: the SNAP is 41 ms, not 3.64 s.**  `run.c.snap_t0` is stamped at the top of
 `snap_step` and `snap-cost` is `Date.now() - snap_t0` at the end, so the encode|compare|store is the
  `snap 0.04s` row.  The `quiesce→snap-cost 3.64s` row is the wait *before `snap_step` starts* — it
   brackets the `post_do`, not the snap.  The only two things standing between the `quiesce` mark and
    the `H.post_do(snap_step)` are `Run.c.on_step_ending` (MachPeerily:480 — clears an interval,
     drops two particles, synchronous) and `Run.c.runtime = false`.  Both free.  This misreading is
      worth guarding against because it points the fix at the encoder, which is innocent.

**`waitVyto` REMOVED from Sounditron's toc (2026-08-07, the human's call).**  It was the only toc
 carrying it, so this is scoped to the resident world and touches no other Book.  Be clear about
  what it buys: **60 ms of a 7800 ms step**, i.e. not the boot fix.  The instinct behind it was
   sound but one day stale — waitVyto genuinely WAS the villain until 2026-08-06, when the old
    `painted >= stir` chase was found never to converge against the resident glass (which grapples
     Stoker levels, Session counters and the Heist, all stirring every heartbeat) and every step
      took the full `CEIL_MS` 8000 ms.  Latching `target` on the first poll took it to 60 ms.
  **The reason to drop it anyway is structural, not arithmetic:** gating a world's step clock on a
   glass that never stops stirring is wrong even when it is cheap, and keeping it leaves an
    8 s-per-step cliff one regression away.  The follow-on the human named — *"some other process
     animating Vyto sensibly over the long run"* — is the right shape: the resident glass should be
      paced by its own clock (the wave/grawave timing Cyto already uses is the candidate), not by
       whether a Story step is willing to advance.  Not built; filed here so it is not lost.

### 2026-08-30 — THE POLE MOVED UPSTREAM: the Creduler standup, not the step clock

With the drain fix landed the steps run at ~0.5 s — and the boot still felt long, because the Radio
 cannot even BEGIN until the resident Story starts, and Auto holds the Story on `%Creduler_pending`
  (Auto.svelte:1144 "⏳ Creduler loading spine…").  Live boots put "🧪 Creduler ready — 35 ghost(s)
   live" at **16.4 s and 26.3 s** — a third to two-thirds of the whole 35 s before any music can move,
    spent before a single step runs.  Two causes found, two fixes landed:

- **SERIAL SPINE IMPORTS (the big one).** `Creduler_ensure` loaded the 35 gen modules with
   `for (const p of unmet) await H.Lies_ghost_set(p)` — one dev-server fetch+transform per ghost,
    in a row, INSIDE the beliefs pass (the trace rings' "beliefs mutex held 7s by H:Mundo think"
     during boot is this).  Fixed (LiesLies.svelte, Creduler_ensure): a parallel warm loop fires
      every unmet `import()` first — one module record per URL, so the kept ORDERED loop then awaits
       work already in flight.  Standup goes from sum(imports) to ~max(imports); enrolment order
        (watched:UIs) is unchanged, so nothing observable reorders.
- **GHOSTLIST ON THE MUSIC PAGE.** A humdinger's Creduler Lies wears no `runner:1` (the dispatch-
   seat carve-out, Auto:890), so it read as a *bare* Lies and seeded the editor's file index:
    a wormhole/GhostList/toc.snap load + 3+ `LiesStore_listing` walks of src/ + Ghost/ every 8 s —
     the live "🗂⚠ wormhole … overran 5000ms — retrying" lines — contending the one Wormhole queue
      exactly while the shelf and the resident Story load.  Fixed (Lies.svelte:860): the GhostList
       gate now also skips `Lies_humdinger(w)`.  Book-inert both ways: runner tabs are non-humdinger
        and a humdinger is never a recorded Book's tab.
- **NOT the pull path, still:** census restore at 35.4 s trails the same Creduler delay (Crate_nav
   is ghost-deposited, so `restore()`'s nav-gate can't pass until the spine is live + FSA restored);
    it biases the wander, it does not gate the Radio.  Expected to pull in with the fixes.

**What remains, scoped not landed:** `Swarm_share_beat`'s 5-8 s beliefs-mutex hold (above — still
 the top REAL-work item, Swarm.g); and the structural one — the resident Sounditron check pass
  (8 steps) still stands between boot and the Radio surface, so the floor is Creduler + ~8×0.5 s +
   the share beat.  Moving the resident Book off the boot path (Radio world stood at once, the Book
    checking beside it) is the restructure the "paced by its own clock" note above points at; it
     moves fixtures and wants its own session.  Verify these fixes by a real /BigSoundland reload:
      "Creduler ready" should land in low single digits, no 🗂⚠ list overruns on a music page, and
       the splash should now plausibly make its 7 s cap to the Radio beginning.
