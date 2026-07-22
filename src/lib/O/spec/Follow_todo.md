# Follow_todo.md — the follower / DJ-monitor player ("enslave a client to my stream")

The one living doc for a discrete new Radiobuddies sub-feature (commissioned 2026-07-22).
 A client takes a QR / invite and enters **FOLLOW** mode: it becomes a dumb music player that
  MIRRORS whatever a **leader** (a DJ) is playing — remotely, the leader drives, the follower
   has no transport of its own. The named-by-the-human case: the follower rides the DJ's private
    **monitor** channel (what's in the DJ's headphones) while the DJ plays a different **main**
     stream to the room. Sits on the invite trilogy (this is a new invite flavor) and on the
      Radio + Peeroleum streaming rails ([[Radio_todo]], `Swarm_spec §6`, `Cluster_spec §18`).

This doc is the destination + the bombs + the next move. Keep it current.

---

## 0. Get on with next

**DEFERRED by the human 2026-07-22: build this AFTER production, not before.** The scope below stands;
 it is warm and ready, but do not start the wire build until the human reopens it post-production.


**GATE CLEARED (2026-07-22).** The invite-crypto QA (two Sonnet audits) ran; its one real HIGH/CRITICAL
 finding — the prepub↔pub binding hole in `Swarm_seal` — is FIXED + proven green×2 (Book **SwarmSpoof**,
  `Swarm_page_bound` guard at all 5 seal entries; [[swarm-seal-prepub-binding-hole]]). The mint/verify/spend
   foundation Follow's `%Follow` grant rides is now hardened, so Follow may build on it. Remaining audit
    items are lower (F3 station_pier %Ud pre-verify DoS — a follow-up; F5 voucher-era is the retracted
     wrong-layer trap, NOT ours). The one open fork before coding: mirror fidelity (see HUMAN decisions).

Build in this order (each a real seam, not a rewrite):
1. **The `%Follow` grant + consent** in `Ghost/S/Swarm.g` — a new Feature kind, minted/gated/consented
    as a TWIN of the Music path (seams below). Revocation reuses `%UnGrant` tombstones for free.
2. **The now-playing broadcast** — leader publishes `{id, at, state, channel}` on an `@channel`;
    `Peeroleum_offer_stream` (already the unicast→multicast handover) hands a follower the pointer.
3. **Follower mode in `Ghost/M/Radio.g`** — drive `radio.c.rec` + `radio.sc.at` off the RECEIVED head
    instead of the local lineup; pace playback with the existing `Ra_term_stream_*` machinery.
4. **The `RadioFollow` Book** — leader plays → follower joins by follow-QR → mirrors → DJ swaps the
    monitor track → follower's mirror follows → DJ revokes → follower detaches. Green ×2 on a live runner.
5. **Monitor vs main** — a SECOND `@channel`, DJ-opt-in. No prior wire art (Mixer's cue/on-air split is
    local render only) — this is the genuinely new bit; do it after the single-channel follow is green.

---

## The arc — why this is one small thing, not three

Everything the feature needs already exists as a rail; Follow is the THIN new layer that couples them:
 the invite machinery admits the follower, a Feature grant scopes what "follow" is allowed to see, the
  `@channel` fan-out already moves one leader's frames to N subscribers, and Radio already paces a stream
   off a playhead. The only genuinely-new wire is **broadcasting the playhead** (today purely local) and
    **a monitor channel distinct from main** (today only a local mixer cue). Keep it that small.

---

## HUMAN decisions (recommendation first — veto any line)

- **Mirror fidelity.** RECOMMEND: **metadata-mirror first** — leader broadcasts `{id, at, state}`, follower
   pulls the track over the existing Repli/Radio stream and plays in rough sync (cheap, reuses everything).
    Then add **audio-relay** (relay the actual monitor bus over the `@channel`) as a second mode once a
     player UI exists to point it at. The relationship + control layer is IDENTICAL either way, so this
      ordering costs nothing. The DJ-monitor case is the audio-relay mode.
- **Follow = a Feature grant** (`%Grant to:{Follow:1,channel}`), RECOMMEND yes — so revocation, tombstones,
   `pier_live` gating and the whole trust apparatus come for free, and a follower is a first-class (capped,
    revocable) relationship rather than an ephemeral socket.
- **Monitor is opt-in.** RECOMMEND: the DJ must explicitly ARM a followable monitor (a monitor is private
   by default) — exposing your headphones cue to a stranger is a consent act, not a default.
- **Sync tightness.** RECOMMEND v1 = "same track, roughly aligned `at`" (frames settle between beats; good
   enough for a music player). Sample-accurate lockstep is a later knob, not a v1 gate.

---

## Wire seams (grounded — from the 2026-07-22 recon; verify line #s on contact, docs drift)

**The grant** (`Ghost/S/Swarm.g`):
- Mint: `Swarm_mint_idzeug` (~:98), `feature = {Music:1,genre}` today → a `{Follow:1,channel}` feature.
- Gate: `Swarm_pier_live(pier, feature)` (~:1324) gates a Pier by Feature; today only `'Music'` — add the
   `Follow` twin.
- Consent: `Swarm_share_granted` (~:1193) is the Music consent hook — clone for Follow.
- Frame kind: register the new `follow`/`spin` kind in `Swarm_arm` (~:341,:383) additively (the trilogy
   pattern — never widen an existing kind).
- Today's public face is `Swarm_page` (~:53): `pub+prepub+friendly` ONLY — no playback crosses the wire
   yet, so this is a new path, not a re-wire.

**The broadcast** (`Ghost/N/Peeroleum.g`, `Cluster_spec §18`):
- `@channel` multicast: `Peeroleum_claim` (~:258) / `_subscribe` (~:269) / `_publish` (~:282) — one upload
   fans out to N subscribers, per-channel seq.
- `Peeroleum_offer_stream` (~:299) — an established 1:1 Pier hands the peer a stream POINTER (an `@channel`
   to subscribe to): the unicast→multicast handover. This IS "enslave this client to my stream."

**The follower drive** (`Ghost/M/Radio.g`, `Ghost/M/Ra.g`):
- Leader's live state read today at `Swarm.g` ~:1286 (`radio.c.rec`, `radio.sc.at`, `radio.sc.Radio` state);
   the share full-length leg (~:1279) already keeps Repli wants ahead of the LOCAL playhead — a follow-share
    mirrors the LEADER's `at` instead.
- Follower mode BYPASSES the local lineup (`Radio_pump`/`Radio_lineup_*`, ~:380–513) and slaves
   `radio.c.rec`/`radio.sc.at` to received values.
- Paced listen: `Ra_term_stream_open` (~:1713) / `_beat` (~:1739) advance a head over `w.c.play` — drive it
   off the leader's head, not its own.

**Monitor vs main** (`Ghost/M/Mixer.g`): `Mix_crossfade` (~:226), `Mix_thirds_dip` (~:246) are the cue(monitor)
 vs on-air(main) split — but LOCAL render arithmetic only. No monitor channel exists on the wire; a follower
  of the monitor needs its OWN `@channel`, separate from the main broadcast.

---

## Display (Vyto's zone — I scope, I do not touch [[vyto-refactor-avoid-display]])

- `src/lib/O/ui/RadioFace.svelte` — the transport card; natural home for a FOLLOW toggle/indicator.
- `src/lib/O/ui/DoorFace.svelte` — who's-with-me; "following X" / "X follows you".
- The follow-QR and the DJ's "expose monitor / manage followers" panel — new UI, Vyto's.

---

## Not this (scope fence)

- Not a general remote-control protocol — the leader DRIVES, the follower has no transport. One direction.
- Not sample-accurate sync in v1.
- Not touching the Mixer's local cue math — the monitor CHANNEL is new wire, the mixer stays as is.
