---
name: radio-friend-exclusive
description: "Radio plays friends' collections EXCLUSIVELY by default (own only on click); an honest Radio_reason note replaces the silent own-replay — the fix for both tabs playing their own records"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

The human's intent (2026-07-28): each Sounditron tab is "meant to be listening to each other's collections
 EXCLUSIVELY, unless they click to do so, or Pier finding|connection totally fails, and we tell the user
  there's nobody online". The old `Radio.g` was the inverse: own stock and each friend mirror were
   **co-equal round-robin pools** (`Radio_lineup_fill` pushed `{key:'mine'}` beside every `%MusuThem`, and
    the `Radio_dial` fallback did a 50/50 own-vs-friend coin flip). Since the stoker keeps OWN stock full
     while friend mirrors depend on the wire, both tabs played mostly their own — the reported bug.

**Fix (Ghost/M/Radio.g, built + compiled):**
- **Source-exclusive** via `radio.sc.own` (1-or-absent; default absent = friends). `Radio_lineup_fill` builds
   pools from ONE side: friends' `%MusuThem` by default, or own `%MusuSelf` only when `radio.sc.own`.
    `Radio_dial` fallback ladder likewise: own ladder only if `radio.sc.own`, else friend pool, else park.
- **Honest fallback** `Radio_reason(w, radio)`: friend-exclusive + nothing playable ⇒ writes `radio.sc.note`
   (RadioFace renders it) — "gathering music from <name>" (peer live but all husks), "your friends are
    offline" (Pier known, offline), or "nobody online yet — connect a friend" (no Pier at all). Returns null
     instead of the old silent own-replay. Note clears itself when a track opens (`Radio_open` deletes note).
- **`Radio_source_toggle(radio)`** — the RadioFace ⚯/💿 button: flips `radio.sc.own`, wipes the Lineup
   (`%Mag:'Lineup'` cards) + note so the next dial fills fresh from the chosen side.
- **RadioFace.svelte**: added the source button + `own` flag; "digging the crates…" now suppressed when a
   note is present (the note IS the explanation); first-time/pool teasers reworded friends-first.

Consequence worth remembering: a tab with **no friend Pier now plays NOTHING and shows "nobody online"** by
 default (honest — and it makes a [[heist-seal-one-way]] half-seal VISIBLE instead of masked). The user taps
  💿 for their own records. **Test-fixture risk:** a pure-solo playback Book may now show "nobody online" —
   cross-Pier Musu* Books have friends so they're fine, but re-record on a live runner to be sure. See
    [[verify-via-live-runner]], [[paged-mirror-husk-gate]], [[music-real-audio-pivot]].
