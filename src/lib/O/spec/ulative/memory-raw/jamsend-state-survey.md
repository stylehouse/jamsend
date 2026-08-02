---
name: jamsend-state-survey
description: "2026-07-22 four-part survey of the consolidating Jamsend p2p music-piracy app (the NEW machine = Ghost/M + Swarm + invite trilogy + Radio). Fully Book-proven but ONLY single-runner in-process loopback; the two-runner \"fingers-proof\" (real friend-to-friend crossing) has NEVER run. TWO un-converged connect stacks. Real DSP (deck/glide/Booth) sits BESIDE the live player unintegrated. Music PERSISTS (Berth) but doesn't RESUME (%Rack/%Grasp absent from code). Recommended epoch = cross ONE real wire two-runner over the RELAY."
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Survey (4 parallel gatherers, verified against live `.g`) of the land as it consolidates into **Jamsend**.
Point-in-time; verify before asserting. The whole spring is [[radiobuddies-shebang-unnamed]].

**Honest one-liner:** a fully-built, Book-proven **simulation** of a p2p music-piracy app that has not
 yet crossed a real wire between two people — every proof runs single-runner, in-process, over a loopback.

**Three structural truths (the leadership bits):**
1. **Loopback-only proofs (BUT partly crossed live).** "green×2" everywhere = single-runner in-process; the
    Books flow over the in-process loopback. HUMAN CORRECTION (2026-07-22): the human DID get two live
     /BigSoundland tabs talking over the relay — they saw each other (presence/awareness crossed) but did NOT
      clearly attribute/flow music-FROM-the-other-Pier-as-source. So the gate is narrower than "never crossed":
       presence works live; **source-by-Pier music attribution on the live relay path is the specific observed
        gap** and the next concrete diagnosis. Basic SEAL is live-proven over the relay (QR).
2. **Two un-converged connect stacks** ([[peerily-live-p2p-crypto]]): **Stack A "Peerily"** (`p2p/Peerily.svelte.ts`,
    mounted `Intro.svelte:85`; imported by legacy `ghost/Radios|Records|Pirating|Gardening|Tyranny`) is genuine
     per-frame-signed WebRTC over real STUN/TURN — but it's the OLD pre-Housing machine being retired. **Stack B
      "Swarm/Peeroleum"** (the NEW rewrite carrying the invite trilogy + Radio) rides a real WebSocket RELAY
       (`Tribunal.g Socket_real` `/relay?addr=`, "heading 10"); its WebRTC is a black hole (`Tribunal.g:16` "send
        drops… DataChannel is heading 9"). Relay-first is the INTENDED ship floor (Cluster_spec; the §3.4
         ISP-oppression fallback); WebRTC direct-lane + same-wifi multicast are deliberate LATER rungs.
3. **Real logic beside the player; persist-but-no-resume.** The DJ deck (crossfade/beatmatch/cue, Mixer.g, MusuMix/
    Cue), adaptive glide (Radiola.g Glide/LiveEdge), and taste/ban Booth (Booth.g — DEAD, zero callers) are all
     real-or-dead DSP the live `Radio_pump` never calls → today it's a **gapless auto-DJ radio, not a deck**. On hold:
      bytes persist to a Berth (MusuBerth, live-gate owed) but `%Rack` (interest root + load-on-init) and `%Grasp`
       (durable wishlist/resume) are ABSENT from code — nothing re-homes kept music on wake.

**What genuinely works E2E:** real Opus DSP (−14 LUFS baked → WebCodecs Opus → 2s chunks → gapless muted playback +
 MediaSession); live auto-DJ radio digging real files (Stoker/lineup/crypto-dial); the hard heist (MusuHeist 22/22:
  census→pull→cid+body_hash gates→land→probation→flatten); real ed25519 friendship + invite trilogy (SwarmChain/
   Blotter + PereComplain, all green on the mock carrier); Repli the universal mover (consent-gated). Mag/Cloud
    zine model landed (`%Mag:shuffle > %Cloud,page:N > %Record`; Radio_spec §2.4 "flat" is STALE, Mag_todo supersedes).

**Parked out of the critical path:** UI (Voro+Cyto BigSoundland) BEING REPLACED = ignore ([[vyto-refactor-avoid-display]]);
 **Radio_multicast** = SPINOFF for another agent (routing brain proven green in `Ghost/M/Mesh.g` — Dijkstra/Prim
  cafe-stretch; only the WebRTC transport unbuilt; the human's "no scavenger hunt for a bit / if music is there it
   can be got" resolves its one open decision AGAINST per-chunk content-id, FOR catalog identity); **Follow** = human-
    deferred to post-production; the invite-crypto hardening + **RaBreach** cid gate = the OTHER (security) agent, all
     UNCOMMITTED (needs the human to land on main); the rung-7 **prod signer / content-id** (#3) = human DROPPED it.

**RULINGS (human, 2026-07-23):** (1) Play-order = **bounded ~100 recent-heard-id window** (was unbounded
 `radio.c.heard`, Radio.g:41/291 — won't scale); the per-Mag cursor is **DERIVED** = skip ids in the window,
  the furthest one present in a given Mag** IS the cursor. **Browsing-history feature DROPPED** ("silly").
   (2) Heist land tags `%Record/%Original` (lossless src: flac/wav/aiff/alac) vs `%Record/%Lossy` (already-lossy:
    mp3/opus/aac/ogg) — a `%Body`→`%Original|%Lossy` mainkey split at Heist.g:122 (churns heist Books' fixtures).
     (3) **Shuffle-seed gap found:** the meander's `H.prng` (Housing.svelte.ts:427) defaults to FIXED [1,2,3,4] and
      nothing seeds it fresh in PROD (old machine did at ghost/Radios.svelte:1138; new stack dropped it) → prod
       shuffles identically every boot. FIX = crypto-seed H.prng at prod boot, gated OFF under Story (Musu_seed
        still pins Books). The DIAL (Ra_rand/w.c.prng) is already crypto-fresh in prod. (4) Human wants HIGH
         autonomy — [[high-autonomy-overnight]]; run the queue, don't check in.

**Recommended epoch = cross ONE real wire, two-runner, over the RELAY** (relay is real, seal already live-proven);
 first build = a two-runner harness/Book that flows music seal→share→play→reconnect over `Socket_real`, NOT the
  in-process loopback the Books use today (`Radiation.g:107` `w.c.tx/rx` link-pair). Then `%Rack`+load-on-init so
   kept music resumes. Then (optional) wire the built deck/glide into the live player. WebRTC + multicast = later.

**2026-07-27 SIX-AGENT DOC SWEEP — thesis CONFIRMED + sharpened; the current map is `spec/Frontier.md`.** A
 grep-grounded sweep of all 62 spec docs vs live code re-confirmed the one-gate finding: everything green is
  LOOPBACK-only; the ONE frontier is porting the music-repli flow onto `Socket_real` (the relay) between two real
   machines — streaming, heist rung-2, multicast, fingers-proof, and per-frame crypto ALL unblock off that single
    crossing (one gate, not five tasks). Sharpened facts: production `.g` WebRTC is a deliberate black-hole
     (`Tribunal.g` PeerJS drops frames) → the RELAY is the only working cross-machine carrier. Per-frame transport
      crypto is a MOCK — `header.sign` OWED, `hear_hello`=`startsWith(pub)`, `hear_trust`=no-op, `body_hash`
       unkeyed; only the society layer (Swarm grants/vouchers) + editor↔runner control frames are really
        ed25519-signed (crypto "unblocks the moment any flow crosses the relay"). UNDER-COUNTING confirmed (the
         human was right "most is built"): Mag §4 recurse RULED+BUILT 2026-07-26 (`Ra_recs_deep`/`Ra_rec_find_deep`
          recurse `Mag**`), Keeping D7 renames live (`LiesKeep`/`LangHold`/`LangCurse`; `LiesHold`/`Interest.svelte`/
           `LiesEnd` gone), LangSion IOing oracle built-but-unwired, spay/EntropyArrest live, LakeSearch Book
            recorded. Consolidation docs written for read+preen: **`Frontier.md`** (the map), **`Heist_design.md`**
             (no home doc existed — 7 rulings to make BEFORE any live build; klepto rides the SAME wire gate),
              **`Mag_design.md`**, + `Radio_design.md`/`Sharing_design.md` (agent-drafted, under my review).
               Retire-candidates (NOT executed — human reads first): `Radio_lowlevel`+`Radiobuddies_handover`+Mag
                preen+`Stemdex_todo`+`Seemables_todo` → `history/`; **`Wire_spec.md` is a render doc, not transport**;
                 `Covenant_design`/Tyrant is a PARALLEL trust arch the live spine doesn't use. See [[ui-seams-todo]],
                  [[heist-rulings]], [[mag]], [[invite]], [[sign-real-carrier-not-loopback]].
