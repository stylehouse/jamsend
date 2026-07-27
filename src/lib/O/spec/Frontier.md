# Frontier.md — where the work actually is (2026-07-27)

One doc to answer "what's left." Distilled from a six-agent, grep-grounded sweep of the
 whole `spec/` shelf against live `.g`/`.svelte`/`.ts` (gen ignored) on 2026-07-27. This is
  the **verified, production-critical cut**; `Everything_todo.md` stays the sprawling
   exotica and deeper quests for research on how things want to be longer term,
   whereas this document is a one day roadmap to production for Jamsend the music sharing webapp.

**Verification basis (read this).** `[LIVE]` = a real caller exists in shipped `.g`/`.svelte`
 (not a def, a comment, a gen `.go`, or a Story Book). `[BOOK]` = built and green in a Story
  Book but with **no live caller**. `[OWED]` = not built. A few credits rest on module +
   recorded-snap existence rather than a fresh live-runner pass — flagged where it matters.
    The trustworthy honesty rule the sweep kept hitting: an optimistic `[built]` in an old
     doc almost always means **"Book-green over the loopback wire"**, never "live
      cross-machine."

---

## 1. The one gate: loopback → a real carrier between two machines

Four independent cluster sweeps (Radio, Transport, Sharing, Heist) hit the **same wall**.
 Almost everything is built and green — but only over an **in-process loopback wire**
  (`Lake_link`: frames passed by reference, no serialization, no network, no NAT, no
   reconnect). Nothing has crossed between two physically separate machines over a real
    carrier. Every music-path frontier below is a facet of this one crossing:

- The live radio plays **local transcoded stock**; the real cross-wire stream/pull beats
   (`Ra_term_stream_beat`, `Ra_pull_beat`) are `[BOOK]` only.
- The share glue (`Swarm_share_up/loop/beat`) is `[LIVE]`-wired from `InvitePanel.svelte:57`
   but has **only ever run over loopback**.
- Production WebRTC is a **deliberate black-hole** — `Tribunal.g`'s PeerJS carrier drops
   every frame; real `RTCDataChannel` exists only in the retired prototype `Peerily`. **The
    working cross-machine carrier is the relay websocket** (`Socket_real`), already carrying
     editor↔runner traffic daily. Direct P2P is a later optimization, not the near path.
- Per-frame transport crypto is a **mock**: only the society layer (Swarm grants/vouchers)
   and editor↔runner control frames are really ed25519-signed. `header.sign` on the transport
    envelope is `[OWED]`; `hear_hello` = `startsWith(pub)`, `hear_trust` = no-op, `body_hash`
     unkeyed. The crypto **"unblocks the moment any flow crosses the relay."**

**The forcing move:** port the husk→preview→stream repli flow from `Lake_link` onto
 `Socket_real`, seal two real tabs, watch bytes cross. Streaming, heist rung-2, multicast,
  fingers-proof, and the transport crypto **all unblock off that single crossing** — they are
   one gate, not five tasks.

---

## 2. What's LIVE (the surprising amount already built)

Your suspicion — "we maybe have most of it built" — is confirmed. Over the loopback wire,
 these run for real:

- **Radio brain** `[LIVE]`: continuous listen loop (`Radio_go/pump/dial`), the meander dig
   (`Crate_nav_meander` → `Stoker_dig`), Riffle deck + dial-pool + Faves zine, mediaSession
    lockscreen.
- **Opus DSP** `[LIVE]`: `rastock→racast→raterm` — OfflineAudioContext decode → −14 LUFS
   meter → baked gain → WebCodecs Opus → ~2s `.jam` segments; demand transcode parks/ignites.
    Real bytes. Only remaining mock: the **source is synth tones, not `/music`**.
- **Mag model** `[LIVE]`: `%Mag:shuffle > %Cloud,page:N > %Record` at 6/page, one-door mint
   (`Ra_rec_home`), **recursive census** (`Ra_recs_deep`/`Ra_rec_find_deep` — nests any depth,
    ruled+built 2026-07-26), Mag-as-Repli-husk, warm-start, cursor. `%Original|%Lossy` quality
     split proven green×2.
- **Invite + seal** `[LIVE]`: compact token (`prepub16*serial*n*presig16`) + QR, `?Iz`
   scan-to-join + born-today auto-join + pin, 3-frame seal (`pier_hello/accept/confirm`),
    mutual `%Pier` + both `%Grant` atoms, real ed25519 vouchers per era. (Live-proven as **two
     tabs over the relay** for the older full-atom form; the **compact** form is Book-green,
      live two-tab proof still owed.)
- **Heist engine** `[BOOK]`: the **klepto** arcs (hard job → land/verify/catalogue; soft wish →
   leads → condense) fully green in `Heistation`, plus the Berth persistence — but **no live trigger**.
    ⚠ **klepto is now PARKED post-production** (human 2026-07-27); the production heist is the simpler
     **directory grab** — keep the folder the playing track came from, the old `ghost/Pirate` reborn,
      with a directory-structure chooser that is `[OWED]`. The built engine's landing/pull verbs feed it,
       but the chooser + inflate + driver are unwritten. See `Heist_design.md`.
- **Identity persist** `[LIVE Dexie / BOOK disk]`: identity mints + persists to Dexie live;
   the `.jamsend` disk mirror (keys ride the snap in clear, owner-local) is green×2 in
    `SwarmDisk` but **not written live**.

---

## 3. The production-critical frontier (ranked)

1. **`[OWED]` Cross the real carrier.** Port the repli flow onto `Socket_real`; seal two real
    tabs; land `header.sign` + real `hear_hello`/`hear_trust`. Three rungs: **R1** manual
     two-tab fingers-proof (needs a human to seal tabs — an agent can't), **R2** asserted echo
      round-trip, **R3** two-runner distributed Book. **The load-bearing gate.** Risk: the
       want/repli machinery has never faced a mid-beat ~400–900 ms round-trip + reconnect.
2. **`[OWED]` Real `/music` source.** Point `Ra_stock` at `/music` instead of synth tones —
    the one remaining mock in an otherwise-real DSP path; everything downstream is real.
3. **`[OWED]` Boot-seed wiring + 3 audit bugs.** Wire `Swarm_boot_seed` into
    `Clustation_ensure_identity` (`Identity_persist_todo §5`); fix (a) the nav-timing latch
     that mints a stranger on cold boot, (b) the fresh-QR-scan path that misses the disk-seed,
      (c) the second-reload stash trap (`Swarm_restash_all` doesn't exist yet). Also
       `Swarm_persist` has no live write hook — disk is never written live.
4. **`[OWED]` `pier_confirm` reconnect re-drive.** Frame-3 is fire-once; a reconnect mid-seal
    drops the reciprocal grant → lopsided friendship (music still flows off each side's own
     grant; the SocialGraph goes asymmetric). The "fingers-proof" fix.
5. **`[OWED]` Real-relay timing.** `join()`'s `sleep(400)` guess, `mint()` opening the QR on a
    null station, unknown-serial ambiguity — all mock-invisible, all real-relay hazards.

---

## 4. The 24-hour forcing move

Everything in §3 sits behind #1. So: **stand up the prod compose on a domain (secure context
 for the relay), port the music repli flow onto `Socket_real`, and get one real byte-stream to
  cross between two sealed tabs.** That single test exercises the seal, the grant gate, the
   stream, the reconnect, and the crypto seam at once — and tells you which owed piece bites
    first, instead of guessing. Real `/music` (#2) can ride in the same session; the rest of
     §3 are fixes the crossing surfaces. It rides the **relay**, not WebRTC.

**The deploy infra is already scaffolded** (`docker-compose.prod.yml`) — standing up the domain
 is a *deploy*, not a *build*: the app runs behind an external Caddy Let's-Encrypt proxy
  (`leproxy`, terminates HTTPS → the secure context WebRTC/relay needs), alongside a `coturn`
   TURN server with `TLS_CERT`/`TLS_KEY` (TURNS for NAT traversal), a PeerJS server, and a UPnP
    forwarder. The one external dependency to confirm: the `leproxy` Caddy volume is
     `external: true`, i.e. it assumes that proxy already exists on the host.

---

## 5. Beyond the music path (the wider horizon)

Owed work the sweep found outside the music clusters — real, but **not on the 24 h path**:
- `[OWED]` **P7 collapse-the-cursor** (`Lies_handover §7`) — retire `%Spotlight`/the `{LE:1}`
   singleton/the double cursor wire; the big attention-machine simplification.
- `[OWED]` **Stemdex v2** — region-partitioned scan + `%Errand` reindex (v1 search is `[LIVE]`).
- `[OWED]` **Engage editor half** — `to:<prepub>` dispatch, hosted-identity registry,
   StoryTimes fan-out (runner half `[LIVE]`).
- `[OWED]` **UIless `.go` include** — run a gen eatfunc with no DOM mount (headless-runner
   blocker).
- `[OWED]` **Stuff_distil re-home into live `Vyto_fold`**; **GhostHMR** manifest + Book; Story
   primitives (per-run reset, `%see`→`%seen`/`%log` split).
- `[OWED]` **Display build-out** — Voro cross-wall alignment, the Vyto new-glass moult, the
   sizing algebra. **The human's Vyto zone — survey only.**
- **3 undecided cross-cutting seams** (`Everything_todo`): which-legs-are-plural taxonomy;
   where standing wires live (`H.ave` vs `Run.c`); the delta-equivalence relation. Each blocks
    several docs and wants a ruling.

---

## 6. Done-but-untracked (the under-counting — docs lag reality)

Credit where the todos under-count: the Mag §4 recurse ruling (built); heist-landing mints now
 page, not flat; the Keeping **D7 renames** + `req:Langoer` (`LiesKeep`/`LangHold`/`LangCurse`
  live; `LiesHold`/`Interest.svelte`/`LiesEnd` gone); the **LakeSearch** Book (recorded);
   the **Stuff** regrouping algebra (green×2); the **LangSion** IOing oracle (built, not yet
    wired into `LangCompiling`); **spay/EntropyArrest** (live); Interest's prod graduation.

---

## 7. Doc consolidation + retirement (the tidy)

Design docs written alongside this map:
- **`Radio_design.md`** ← Radio_todo(settled) + Radio_spec + Radio_multicast_todo. **Human ruling
   2026-07-27: keep both** — `Radio_lowlevel.md` stays put; `Radiobuddies_handover.md` gets an
    orienting header (its §5 regroup is DONE — `Sound.g`/`Repli.g` exist, pipeline reborn as `Ra.g`;
     its live parts are §0-1 the name + the run-without-Story Layer-0 destination, and §6 the
      frontier). Neither retired.
- **`Mag_design.md`** ← Mag_todo §1 + the preen's carve-outs + Radio_spec §2.4's GC invariant.
   Retire the preen after merge.
- **`Heist_design.md`** ← assembled from Radio_todo §10/§10.1/§10.2/§11.7/§12.5 + Radio_spec §4
   (Heist had **no home doc**). Carries **7 questions to rule** before any build.
- **`Sharing_design.md`** ← Swarm_spec + settled todos + Cluster_spec §2/§3.2a. ⚠
   `Covenant_design.md`/Tyrant is a **parallel** trust arch the shipping spine does **not**
    use — do not read it as the live path.
- **Transport:** fold durable facts into `Peeroleum_spec.md`; `Trust_audit_handover.md` owns
   crypto status; **`Wire_spec.md` is a false friend** — it's a render/reactivity doc, not the
    transport wire.

**Human rulings 2026-07-27 — mostly KEEP (concept compost):** `Seemables_todo.md` and
 `Wire_spec.md` are kept as important concept compost, NOT retired (`Wire_spec` is a
  render/reactivity doc, not transport — valued as-is; any rename is optional). `Radio_lowlevel.md`
   and `Radiobuddies_handover.md` stay (above). **`LakeSearch`** (recorded but unseen by the human)
    → a review note lives in `Everything_todo.md`, not a retirement. Only genuine cleanup left: the
     drift-fix — `Keeping_spec.md` + `Interest.md` still name renamed files
      (`LiesHold`/`LiesEnd`/`Interest.svelte`).

**Retirements are recommendations, not executed** — nothing moves to `history/` until you've
 read the consolidations.
