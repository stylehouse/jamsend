---
name: radio-pipeline-opus
description: "The rastock→racast→raterm pipeline (Radio_todo §3, the build brief) + the codec decision: OPUS not AAC (alienate Safari WITH an explanation face); 2s independent re-encoded segments even from .opus sources; needles LUFS baked at encode; ISP-oppression warning wanted"
metadata:
  node_type: memory
  type: project
  originSessionId: ff56d2b0-d35b-4e33-96b4-b8f73a68a322
---

**Owner decisions 2026-07-07, the brief for the big build session** (sketch = `Radio_todo.md §3`):

**Codec = OPUS, not AAC.** Reasons: the /music library IS already .opus; the ENCODER matters as
 much as the decoder (every user's node encodes its own stock) and Opus encode is free everywhere
  — MediaRecorder + WebCodecs AudioEncoder bundled libopus incl. Linux Chrome, where AAC encode
   does NOT exist — no ffmpeg.wasm pull; "simple licensing wins". Safari/WebKit refuses Ogg|WebM
    Opus and **Chrome-on-iOS IS WebKit** (mandated engine) so no help there — the stance is
     **alienate Safari WITH AN EXPLANATION face** ("your browser refuses the open standard").
      Escape hatches later, neither a re-encode: CAF remux (Safari decodes Opus FRAMES in CAF)
       and WebRTC (Opus mandatory in RTP — Safari decodes it there; a live leg reaches iPhones).

**The pipeline names:** `rastock` (library → uniform stock) → `racast` (cast to Piers: catalog
 husk via Repli, Records as Repli pages, live edge via @channel multicast, ALL grant-gated) →
  `raterm` (the playing terminal: playhead want-cursor, decode per segment, crossfade). Books:
   RaStock / RaCast / RaTerm. Casting is Repli never RPC.

**2s independent segments, re-encoded even from .opus sources** (owner: "we still have to
 re-encode to produce these nice little 2s frames we like to transport around"): playback starts
  MID-track more often than not; Opus packets are chained prediction (mid-stream entry needs
   OpusHead + ~80ms pre-roll unless the encoder reset at the boundary). WebCodecs honesty: chunk-
    fed AudioDecoder IS reliable in Chromium now (explicit decodeQueueSize backpressure) — the
     segments are for random access + fault isolation + UNIT-ALIGNMENT (segment = Repli page =
      wear unit = want count), not decoder fear. Continuous WebCodecs decode = the live-edge tool.

**Loudness:** needles (`@domchristie/needles`, prior art src/lib/ghost/Records.svelte) LUFS per
 track, gain BAKED into PCM before encode; stamp measured lufs + applied gain on the %Record;
  TARGET_LUFS one constant (old machine -8 hot; streaming norm -14; decide at build).

**ISP-oppression warning (owner):** when Piers cannot WebRTC (CGNAT/UDP-blocked) and fall back
 to the relay, SAY SO — Brink badge + face line ("your ISP is likely oppressing direct peer
  connections — you are riding the shared 1Gbps relay").

**Emit-flood answer** (owner asked "50 emits without 50 beliefs()?"): YES — `Lies_deliver_soon`
 (LiesLies.svelte:894) coalesces inbound frames into w.c.inbound_batch, ONE post_do drain, one
  belief pass; also stamps `socket_heard` OFF-think so throttled tabs don't false-dead. Send-side
   emits queue on the outbox within the beat's cascade. A segment flood is safe by design.

**Doc split 2026-07-07:** `Radio_lowlevel.md` = the ladder (old §3–§8: workings/slices/sim/Musu
 Books/runner iface/status/presentation, original § numbers preserved); `Radio_todo.md` = spring
  framing + §3 pipeline + §9 Pier reality + §10 klepto. Credence: What:Musu = real music (top) +
   What:lowlevels (cursor models | real audio | the platform). Retirement rule: a low-level Book
    retires only when its Ra* re-draw is green ([[musu-test-consolidation]]).
 See [[radiobuddies-shebang-unnamed]] (layer story), [[invite-front-door]] (the Swarm side).
