---
name: crossing-is-live-not-loopback
description: "the real relay crossing is ALREADY LIVE (Swarm_station_up→Socket_real, signed bind+voucher); 'loopback only' is a stale doc caveat; real /music digs; what's genuinely left is hot-path/disk hardening that needs two-tab seal to verify"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

2026-07-28: the human was frustrated I kept citing "loopback only" limits. THE CORRECTION (verified in
 code): the real cross-machine music crossing is ALREADY WIRED and works.

- **Carrier is live.** `Swarm_station_up` (Swarm.g:585) calls `Socket_real(w)` (Tribunal.g:57 — a native
   WebSocket to `/relay?addr=<prepub>`, serialises `[header JSON]\n[raw buffer]`, auto-reconnects) +
    `Tribunal_activate_websocket`. `Peeroleum_carrier` reads `%active_transport.c.connection`; frames route
     by `header.to`. Signed relay hello-bind + a per-era `station_voucher` sealed friends verify. Called
      from InvitePanel on seal. Two sealed tabs cross the REAL relay today (matches [[radio-cross-pier-wake]]).
- **Source is real.** `Stoker_dig` bases `['music','','testsounds']` → `Ra_stock_one` → `decodeAudioData`
   of real files. "Synth tones" (Frontier §2) is STALE — [[music-real-audio-pivot]].
- **So `Frontier.md §1`'s Socket_real gate is largely CLOSED.** WebRTC/PeerJS is a deliberate black-hole
   (`Tribunal.g` PeerJS drops frames) and NOT the near path — the relay is the carrier ([[two-p2p-stacks-proto-vs-g]]).

**What's genuinely left (all hot-path or disk, all needing a HUMAN to seal two tabs to verify — an agent
 can't, Frontier §3.1 R1) — so hand off, don't blind-build the night before production ([[fight-back-on-core-changes]]):**
- Per-frame transport crypto: `hear_hello`=startsWith, `hear_trust`=no-op, `body_hash` unkeyed, `header.sign`
   absent. Defense-in-depth ON TOP of the working voucher layer, not a make-it-work gap. Hot path (a bug
    drops EVERY frame).
- The Heist folder-keep driver (Moves 3-4): production landing dir UNBUILT (Book uses a test namespace —
   land into a dedicated `.jamsend/kept/`, never `/music`), mirror-scoping open (manifest reply recommended),
    chooser home = Vyto (human's display zone). See spec/Heist_todo.md. Gesture+resolver BUILT ([[invite]]).
- Frontier §3.3 audit bugs (cold-boot stranger mint, QR-scan misses disk-seed, second-reload stash trap) +
   §3.5 real-relay timing (join sleep(400) guess). Reliability, real-relay-only hazards.

Reliability already hardened this session: fast boot ([[boot-20s-stoker-gate]]), starve self-heal (live
 cross-relay re-ask, Swarm.go 108977c), seal self-heal (Swarm_reaccept_incomplete wired, [[heist-seal-one-way]]),
  friend-exclusive ([[radio-friend-exclusive]]).
