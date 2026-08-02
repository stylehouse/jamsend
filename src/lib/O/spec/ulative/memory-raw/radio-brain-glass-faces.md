---
name: radio-brain-glass-faces
description: "Radio.g = continuous listening (dial→stream-decode→AC timeline→auto-advance, all detached) + %Stoker visible provisioning; faces = sc.face OR FACE_MAINKEYS imposition, believed ONLY under commission useFaces (cyto_face_kind(w,n)); ztuffing sub-faces (sub_faces_sync); mold = stuff.scale 1.5× UNCLIPPED, TRUE per-wall bind at paint (mold_max_fit) + sqrt-damped overflow (stuff.damp) inside the stuff.top/bottom band + hover z-lift (vlift); CREWS + %Tuner = show/hide groups of glass cells"
metadata: 
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

Built 2026-07-18 (uncommitted): **`Ghost/M/Radio.g`** — the wire the Ra pipeline never had:
 chunks decoded onto the REAL AudioContext timeline, track after track. ▶ on the RadioFace =
  `Radio_go` (the click IS the autoplay gesture) → era-guarded detached pump (NOTHING under
   beliefs — [[sounditron-wild-book]]'s mutex law) → ONE persistent AudioDecoder per encode
    (reset only at `head` chunks; WebCodecs flush() RESETS state so flush only at run end) →
     `aud.schedule(buf, max(end, now))` frontier chaining → `Ra_dial_next` at the end, forever.
  %Stream transcodes into being BEHIND the playing 32s preview (`Ra_transcode_ensure|advance`,
   self-served); empty shelf resurrects radiostock then ONE meander (never a scan). Starve = 6s
    grace then SPLICE. Detail: Radio_todo §0.

**The faces rail**: a particle wearing `sc.face:'<Kind>'` mounts the component registered in
 `src/lib/O/glass_kinds.ts` in its node overlay and EARNS A VORONOI CELL (registration in
  Cytui's `stuff_mounts` is what seeds cells). nstyle branch sits BEFORE the stuff skins (the
   crusher's blanket `c.stuffy` must not shadow a face). `.face-overlay` stays
    pointer-events:none; only the component's buttons re-arm auto (the glass must pan).
     Props `{ n, H }`; react via `void H?.version` $derived.
 A face can also be IMPOSED BY MAINKEY: `FACE_MAINKEYS` in `glass_faces.ts` — the
  COMPONENT-FREE half Cyto.svelte imports (never glass_kinds.ts: the headless spine must not
   drag .svelte components).  Viewer-side, zero snap change — sealed Books stay Voro-blind
    (%Heist → HeistFace rides this).  Resolution = `cyto_face_kind(w, n)`, worn sc.face wins.

**2026-07-19 — believing is COMMISSION-GATED + ztuffing sub-faces + the 2× unclipped mold:**
 `useFaces: 1` on the Cyto commission (the supports_constraints pattern; Sounditron.g:147
  already carries it) → `w.c.use_faces`; ungated, `cyto_face_kind` returns null for worn AND
   imposed alike — a stray %Heist in a non-radio Book stays a row.  The flag rides every wave
    c-side (`wave.c.use_faces`) so Cytui gates its ZTUFFING SUB-FACES the same way: a faced
     fold|gang MEMBER (never a cy node) mounts its component in a slot along its cell's bottom
      band (`sub_faces_sync`, gang-mirror lifecycle; knobs stuff.subh/subw).  The MOLD renders
       molded overlays at `stuff.scale` (started 2×; the human walked it back SAME DAY to
        **1.5** — "they're too big now… split the difference") and UNCLIPPED (`stuff.clip` 0 +
         `.stuff-overlay` overflow:visible — the bbox rectangle-clipped even without the
          polygon); paint_final ownership mark moved clipPath → `el.dataset.molded`, honoured
           by reposition_overlays for Stuffing AND face overlays (faces used to be fought over).
       The final mold is CLAMPED to an absolute band — `stuff.top` (2) / `stuff.bottom` (0.5)
        knobs: no chunk past top× natural size however huge its cell ("one gets waaay too
         big"), none below bottom×.  And the HOVER Z-LIFT: the cell polygon under the mouse
          (wrap mousemove hit-test, `vlift_move` — glass SVG is pointer-events:none so CSS
           :hover can't fire) lifts its overlay `.vlift` z-index above the overlapping pile —
            "feel your way into them".
       SECOND walk-back same day ("still way too big… bound-to-cell perception must be dead"
        — it WAS half-dead: gather binds with CAPPED 260×200 dims, paint re-clamped TRUE dims
         against only the cell BBOX, and the stuff.bottom floor overrode the bind — floor ×
          unbounded natural size = the monster shelf).  Fix: `mold_max_fit` per-wall loop
           shared gather+paint; paint re-binds TRUE box vs REAL walls; overflow past the bind
            DAMPED `(want/bound)^stuff.damp` (0.5 default → felt overflow √1.5≈1.22×; damp=1
             = old linear).  NEXT: the human wants a fresh session on Vtuffing proper.

**2026-07-19 later — INSTANT-ON + the old ghost's gems:** the dig is PRE-EMPTED three ways:
 `Stoker_preheat` (one churn at glass-commission, radio still off — the COMMISSIONER opts in,
  Sounditron_glass does; sealed Books never dig spontaneously), `Radio_nudge` (a landing pumps a
   `digging` radio NOW via a FRESH era — never call Radio_pump on the live era, two timer chains
    double-pump), and GAPLESS pre-advance (dial turns at `end - 2.0s`; Radio_open never resets
     c.end so the next track lands AT the frontier).  Mined from the legacy quarry
      `src/lib/ghost/Radios.svelte` (mounts only via lib/mostly — a quarry, not a live organ):
       Media Session lockscreen card (Radio_media_now|pause|off; pause KEEPS the card) and
        Stoker_cull (shelf cap 24, heard non-playing records wear out, sc.worn; radiostock on
         disk = one resurrection away).  Gotcha fixed: churn_asked must be consumed in the
          no-disk branch too or the stoker never parks headless.  Still in the quarry for the
           remote leg: live-edge melt, ack_seq spooling, disk cache whittle.

**2026-07-18 late — %Stoker + CREWS/%Tuner (the C-and-D fix):** provisioning is the STOKER's own
 visible loop (Radio.g region stoker) — the dial NEVER digs; it prefers FRESH (`radio.c.heard`
  set → `Ra_dial_next opts.skip_ids`, default-off for sealed Books) and pokes `Stoker_churn` on
   exhaustion (replays counted on sc.replays).  Dig order MUSIC-FIRST: the old testsounds-first
    first-base-wins meander is why only two test tracks ever played.  CREWS: every cell-holder
     tessellates under `cyto_crew(n)` (sc.crew || face kind || stuffed mainkey); cyto_scan
      censuses to %Tuner `.c.crews` + DROPS muted crews at classify (census before drop);
       `Tuner_toggle` = mute flip + unfold-idiom absolute rescan.  Mute/census ride `.c` ONLY
        (Books Voro-blind); the tuner is minted by the COMMISSIONER (opt-in, Sounditron_glass)
         and never mutes itself.

**Why:** the human: "continuously playing music, like a radio, starts going from the start (via
 %Stream) after the first track you leave playing" + "send a UI component into Voro|Cyto for
  laying out, much like it does with Stuffings."

**How to apply:** new glass UI = a face component + one `glass_kinds.ts` line + a particle wearing
 `sc.face` — never a new overlay mechanism. GOTCHA: a live tab must HARD-RELOAD to acquire a
  newly enrolled ghost (a green Book run on a stale tab proves the OLD spine — grep the snap for
   the new particle before believing it). A face is live DOM: shots can't show it; its CELL in
    the `--svg` tessellation is the proof it mounted. TWO BOMBS defused proving the mint: in .g,
     cross-ghost calls MUST ride `top_House()` (`this.OtherGhost_x` on a run House is silently
      undefined — guard-wrapped calls just skip); and headless run Houses have no `c.up`, so a
       mint below an `if (!this.c.up) return` bail never runs headless. Probe with a console.log
        through LocalGen+CredRunner before trusting a silent guard.
