---
name: radio-cross-pier-wake
description: Two BigSoundland tabs cross the RELAY (not loopback) and the preview pull WORKS — the "not audible in 1s" bug was Radio:off + NO cross-Pier wake, fixed by w.c.repli_on_land→Radio_nudge; Sounditron now plays the trick muted
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**THE REFRAME (2026-07-28, from Righto/Lefto Step:7 snaps the human pasted).** Two BigSoundland
 tabs on one machine are two JS contexts → they cross the **relay** (`Socket_real`), NOT the
  in-process loopback (`Lake_link`, which is by-reference same-context). The snaps PROVE the
   cross-Pier `%Preview` pull works over the relay — each side holds the other's chunks
    `stage:previewed`. So `Frontier.md §1`'s "nothing has crossed a real carrier between two
     machines" is **more crossed than it admits**: two distinct Piers exchanged real Opus chunks
      over the relay (same box, two tabs, but a real serialized carrier). The bytes were never the
       problem.

**THE BUG was `Radio:off`, not the carrier, not slowness.** The previews landed and just SAT there —
 nothing pressed play, nothing dialed the friend's previewed record. And the local dig nudges a
  digging radio the instant a track stands (`Radio_nudge`, called from `Stoker_look` at the
   resurrection + first-dig-landing seams) — but a friend's chunk crossing the **wire** had NO such
    wake, so the playhead waited out its 3s dig poll (`Radio_pump_soon(...,3000)`). THAT was the "why
     isn't it audible in a second" gap. On the relay (localhost) the chunk arrives in ms; the time
      was a fixed poll paid in full because nothing woke the radio.

**THE FIX (landed, compile-proven; the human live-ran and "radio works!").**
- `Repli_attach_page` (Ghost/N/Repli.g) fires a **generic** `w.c.repli_on_land(w, mirror)` on a real
   chunk landing (a cid **breach** = bytes refused = no fire; presence IS fill state). Repli stays
    music-agnostic; consumers subscribe.
- `Radio_ensure` (Ghost/M/Radio.g) subscribes: `w.c.repli_on_land = (ww) => this.Radio_nudge(ww)`.
   Idempotent (`Radio_nudge` no-ops unless the radio is `'digging'`).
- **WRONG-WORLD BUG (found by the coherence audit, FIXED 2026-07-28):** the hook was REGISTERED on the
   radio/run world but `Repli_arm` runs on the **station world** (`Swarm_station_world`), so
    `Repli_attach_page`'s `w` is the station world and `w.c.repli_on_land` was undefined → the wake was
     DEAD in the live share. Fix: fire on `w.c.repli_mirror_w || w` (the radio world holds the mirror
      crates AND registered the hook; solo/no-share falls back to `w`).

**SOUNDITRON NOW PLAYS THE TRICK (Ghost/Story/Sounditron.g, beat 6).** Presses `Radio_go(radio,
 {mute:1})` — MUTED (a Book's silent listen) + DETACHED (Sound_gat's resume pends on a gestureless
  tab = the step-6 deadlock law: a beat fn never awaits an unbounded promise). Aimed at a friend's
   previewed record via `Radio_dial_pool`→`radio.c.tune_rec` (tune_rec outranks the dial, consumed
    once). The decode+schedule pipeline runs gesture-free (AudioDecoder needs no resume), so
     `radio.c.seq` advances — the **snap-provable** trick — even where muted output reaches no
      speaker (actual audible play = the human's gesture on BigSoundland). New witness %sworn: `the
       music played …` (contract) + `music from a friend played …` (opportunistic). The **4th Heist
        Need "the pull itself"** — never checked before — now `met` via `Sounditron_pulled` (any
         friend record with `Ra_chunk_map[0]` present). See [[sounditron]], [[heist-rulings]].

**BATCH of live-feedback fixes (2026-07-28, from the human running it — all compile-proven, gen
 written, need a runner reload):**
- **peer_live measured the wrong thing** → `peer_wait` timed out at 12s EVERY music run ("still slow").
   `Sounditron_peer_live` now detects a sealed Music pier heard within 30s (`Swarm_pier_live` +
    `heard_at`), keeping the old Lies-lease as fallback. Settles fast when a friend is online.
- **Friend tracks capped at 32s** ("doesn't play well") → `Radio_supply_go` set `cap=P` on a friend
   record because `Ra_transcode_ensure` can't read their disk locally. Fix: `if (rec.c.from) return` —
    a wire record's continuation comes over Repli (`Swarm_share_beat`), never a local transcode; never cap it.
- **The 1s "dementia" tone** = `Lies_audio_probe` (LiesFunk.svelte) routed a 440Hz oscillator straight
   to `ac.destination` for 1.5s to test audio. Fix: `osc → analyser → gain(0) → destination` — the
    analyser still HEARS it (tapped before the gain), the SPEAKER stays silent. (Edited the human's
     in-flight LiesFunk.svelte — surgical, away from the Vyto glass refactor.)
- **Auto-start** (the human: "radio should auto-start") → `Sounditron_listen` now presses play UN-muted
   on ANY stock (friend preferred via tune_rec, else own shelf); `Radio_go` raises the BootGate audio
    tap via `AudioContext_wanted`, so the one tap resumes the AC and music flows — no ▶ hunt. (This
     supersedes the earlier muted/friend-only scoping; solo-with-stock now auto-plays too → fixtures move.)
- **Vyto from step 1** → `Sounditron_drive` now calls `Sounditron_glass(w)` at `n===1` (was beat 2).
- **Still OWED (needs live iteration, designed not built):** break the coarse beats into finer steps so
   a long wait produces "a few snaps just waiting and waiting" — feasible (a NEW run has a 30-step
    budget, `Story.svelte:2120`) but a real drive restructure (phase decoupled from step, re-entrant
     bounded waits); risks a non-terminating run if done blind. Iterate live.

**Consequences for the human (live gestures I can't do):** hard-reload Righto+Lefto (NEW methods
 `Sounditron_listen`/`_pulled` need a reload not HMR) → run → see Radio flip to playing on a friend's
  track. **`Sounditron_listen` is SCOPED**: it early-returns unless `Radio_dial_pool` has a friend's
   previewed track ready, so a SOLO/CI run is byte-identical to before — the committed (solo-shelf)
    fixtures stay GREEN, no re-record needed. Only the two-Pier environment presses play (and that env
     already redded the solo fixtures by construction). DECLARE the 3 new %sworn if you want them as
      gates ([[sworn-assertioning-rulings]]). Soft searching cue (`Sound_searching` +
    `searching` radiostock kind) landed as a PRIMITIVE but the app path never installs synth (only
     Musuation/Mixer do — a no-share tab digs SILENT), so wiring the cue into the dial is still owed
      (Vyto-adjacent + needs audible verify). Full write-up: spec/Sounditron_todo.md §0.
