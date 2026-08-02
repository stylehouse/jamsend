---
name: source-attribution-relay-gap
description: "The two-tab \"music-from-friend-X not attributed over the live relay\" gap is ROOT-CAUSED — the mirror Record's only source handle is rec.c.from, a .c runtime ref that NEVER snaps/crosses the wire; works in Books ONLY because the loopback shares one process. Fix = snappable rec.sc.from + carry onto now-playing radio.sc.by. Plus a real hazard: two tabs share read-only /music so friend ids collide with own ids → dedup folds friend tracks into \"mine\"."
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Diagnosis (2026-07-23) of the human's observed gap: two live /BigSoundland tabs SEE each other but don't
 clearly attribute music FROM the other Pier as source. The MVP blocker on [[jamsend-state-survey]]'s epoch.

**Crate-level attribution DOES cross the relay** (not the bug): `Swarm_share_up` sets
 `w.c.repli_mirror_by_from=1`+`repli_mirror_pier=me` (Swarm.g:1254-1256); the frame's `header.from` is
  preserved on the wire (Socket_real serializes it, relay routes on `.to` only); `Repli_mirror_lib` keys
   `Ra_home_them(rw, String(from))` = source prepub (Repli.g:471-474); CrateFace labels the friend correctly.

**THE DROP — two coupled causes:**
1. **The record's only source handle is `rec.c.from`** (Repli.g:489) — a `.c` runtime ref: per CLAUDE.md it
    NEVER snaps and NEVER crosses the wire. Works in Books ONLY because tx/rx are one same-`w` `Lake_link`
     pair (Radiation.g:107-108) → sender+receiver share ONE process → `.c` refs are live. Over the REAL relay
      the tabs are SEPARATE processes: `rec.c.from` is stamped locally on the receiver, invisible to every
       live face, never round-trips. The Books attribute via `pick.c.from === w.c.<x>_pre` (Radiation.g:536,
        596,634,708,738) — the loopback-only channel. **"green on loopback, silent on wire."**
2. **The dial drops the one live label at play-time.** The durable label is transient `card.sc.by = pool.key`
    (=crate `home.sc.pub`, Radio.g:476), shown as the 8px "· from X" in LineupFace:41. But `Radio_dial`
     returns bare `head.c.rec` and `lu.drop(head)` (Radio.g:384-389), discarding `card.sc.by`; `Radio_open`/
      `Radio_tune`/`Radio_media_now` never set `radio.sc.by`/`.from`. So once a friend track PLAYS, now-playing
       has no source at all. (`card.sc.by=` at Radio.g:476 is the ONLY by/from assignment anywhere.)

**Secondary live-only hazard:** two BigSoundland tabs share the read-only `/music` mount → friend record ids
 == listener's own ids → the `lined`/`heard` id-dedup in `Radio_lineup_fill` (Radio.g:429,435,444-445) folds
  friend tracks into "mine" (no `by`), erasing attribution before it can show.

**STATE after 2026-07-26 session — tree GREEN, primary fix LANDED, hardening STAGED:**
1. **LANDED (neutral, green)** the Radio.g in-session attribution. `Radio_dial` stashes the dropped Lineup
    card's `by` onto `hrec.c.play_by` before `lu.drop`; `Radio_open` (the ONE play funnel — dial AND tune
     both flow through it) computes `src = rec.c.play_by || rec.sc.from || Ra_pub_of(rec)` and sets
      `radio.sc.by = src` when `src !== me`, else `delete radio.sc.by` (guarded, boolean-clean). **Proven
       neutral: NO Book drives the live Radio pump — `Radio_open` is never called in any Book** (grep empty),
        so `radio.sc.by` touches zero fixtures; it only lights up in live `/BigSoundland`. NO display edit
         (RadioFace/LineupFace are Vyto's zone) — pure data; Vyto renders it later. LocalGen-clean.
2. **STAGED, held back (would go red unattended)** the Repli.g root-cause hardening. `Repli_recv_lines`
    would stamp snappable `c.sc.from = String(frame.header.from)` beside `c.c.from`, GATED on
     `w.c.repli_mirror_by_from` (only `Swarm.g:1255` prod + `Swarmation.g:1064` SwarmShare set it). That
      moves **SwarmShare's** mirror-record fixtures → red until re-recorded, and the re-record needs a live
       spine-ghost runner reload (the unattended hazard). So the one-liner is left as an OWED comment at the
        `Record` branch in `Repli_recv_lines`, and the paired beat-4 SwarmShare swear (*each mirrored record
         wears its source prepub as a snappable from*) is an OWED comment at `Swarmation.g` beat-4. Land
          BOTH + re-record + `declare` in ONE attended runner sitting (the Radio.g `|| rec.sc.from` fallback
           already reads it — forward-compatible). Until then, cross-tab attribution rides `play_by` (in
            session) + `Ra_pub_of` climbing the snapped `%MusuThem` crate (survives reload — c.up rebuilt
             from snap), so it already largely crosses without the stamp; the stamp is belt-and-suspenders.
3. `radio.sc.by` end-to-end has NO Book yet (no Book runs the live pump). A radio-drive scene playing a
    FRIEND track → `radio.sc.by` wants a runner to record live (attended).
**Secondary live-only hazard UNADDRESSED (needs two-tab):** shared read-only `/music` → friend ids ==
 own ids → `lined`/`heard` dedup folds friend tracks into "mine". Handle at fingers-proof time.
