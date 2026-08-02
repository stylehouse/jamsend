---
name: heist-keep-chooser-built
description: "the ⇊ keep-what-you're-hearing heist: SHIP-1 rewrite (2026-07-28 night) — census now METADATA-ONLY + materialise-one-file-on-demand + one-click deferred keep; the folder-census STORM was starving the radio's transcode pump (playback died at 32s)"
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**THE BOMB (code-confirmed 2026-07-28): the heist folder-census was starving live playback.**
 `Heist_rummage_folder`→`Heist_census` read+hashed the WHOLE source folder (twice: body_hash + per-chunk cid)
  INSIDE `Swarm_share_beat`, holding the tick mutex for seconds → the same beat's `Ra_transcode_pump`
   (Swarm.go, serves parked continuation wants by transcoding) ran seconds apart → the listener's continuation
    wants (Swarm.go FULL-LENGTH leg, head+16 live window) parked unanswered → **playback ran out at the
     32-chunk preview ("runs out at 32s")**, source tab at **30% CPU**, folder bytes pinned in RAM. The
      continuation pull itself is SOUND — it was STARVED. One cause, three symptoms.

**SHIP 1 fix (compiled, NOT committed; RELOAD BOTH TABS for new gen — esp. the SOURCE):**
- **Census is METADATA-ONLY.** `Heist_census_heads` walks paths (Crate_nav_paths already audio-gates), mints
   chunkless husks (`husk:1`) under a **keep-id** = `Heist_keep_id(me, base, path)` (sha256 of pub+path).
    ZERO reads. `Heist_census` (used by MusuHeist Books) left untouched.
- **Bytes read once, on demand, at pull.** `Heist_materialise_one(w, nav, me, ref)`: resolve ref (stocked
   content-id via Ra_stock_ls→card→path, OR a describe husk's keep-id→path), read that ONE file, chunk with a
    SINGLE incremental-hash pass. Idempotent. The head crosses `re:<ref>` so the asker matches it back.
- **keep-id ≠ content-id DISSOLVES the seed-opus collision** (the old review's #1 blocker): the original lands
   as its OWN mirror rec, never upserts onto the seed's opus stream rec — so the "exclude the seed" hack is GONE,
    the seed is a normal pick ([[snap-data-not-judgement]] / [[mag]] Card≠Record kinship).
- **`Heist_rummage_ask(...,want)` / `_answer`** gained a `want:<ref>` mode (materialise+offer ONE original,
   full head with total) vs the describe mode (metadata heads). Ra_pull_beat bails on total==0, so the head
    MUST re-cross with total — hence materialise-then-offer, not materialise-on-chunk-want (deadlock).
- Serve-lib sweep now **DETACHES** aged libs (`(rl.c.up||w).drop`) so %Body bytes GC.
- **ONE-CLICK + DEFERRED state machine:** `Radio_keep` mints `state:'primed'`; RadioFace ⇊ no longer opens the
   Panel (clean one-click, ✓ tick = feedback). `primed`→(seed still playing? LINGER)→`pulling`→materialise-ask
    the seed DIRECTLY (no folder census on the default path)→pull+`Heist_land` into `music/<genre>/`→`done`.
     Default keep = the SEED track only; folder-browse (describe) machinery stays wired but DORMANT.

**Serve/pull world consistency (verified):** `Repli_arm(w)`, `Heist_keep_beat(w)`, `Heist_materialise_one(w)`
 all thread the SAME Swarm `w` (the wire world; `rw`=radio_w is where stock/mirrors live). So the serve lib on
  `w.c.rummage_libs` is exactly what `Repli_serve_want` reads. Received heads land in `Ra_home_them(rw, at)`.

**KNOWN v1 edges:** materialise (source) + Heist_land read-back-hash (asker) still run ON the beat — bounded
 ~100-300ms hitch per kept track at a track boundary (time-slice off-mutex later). A source `path` with a COMMA
  is a latent encode hazard (Ra_record_from omits path for this reason; heist NEEDS it for cp-landing).

**SHIP 2 (BUILT 2026-07-28, compiled, NOT committed): the tidy Vyto cell.** The human: "I DO want the Heist UI
 ... in a few Vyto cells ... nodulate down the folder hierarchy ... you don't have to click start, it'll assume
  that at some point ... it folds down when started." Built:
- `KeepFace.svelte` (src/lib/O/ui/) — one cell per %Keep; folder husks NODULATED by directory (not right-aligned
   filenames); genre datalist to tweak the filing dir; per-track ✓/· un-keep; seed marked ♪; folds to a compact
    progress strip when pulling. Props {n,H}, pointer-events:none root + buttons re-arm (HeistFace contract).
   Registered `Keep` in glass_kinds.ts (GLASS_KINDS) + glass_faces.ts (FACE_MAINKEYS).
- Engine (Heist.g): `Heist_keep_step` DESCRIBES the folder on primed (metadata-cheap) so the cell shows it;
   `Heist_keep_default_pick` keeps the heard track (its husk wears re:<seed>); `Heist_keep_pick_toggle` /
    `Heist_keep_set_genre` are the cell's verbs; multi-pick pull (materialise-ask each %Pick,ref); `sc.dose='2'`
     space-favours the cell while primed, deleted on pull (fold down); done keep DROPS itself after 8s.
- Grapple (Sounditron.g — the resident commission): `Sounditron_commission` grapples the shop's %Keeps as their
   own cells; `Sounditron_trickle_look` re-commissions on the keep fingerprint (appear/leave). RadioFace ⇊ no
    longer opens the Panel (HeistSetup now fully dormant — retire later).
- ⚠ Sounditron.g is the human's Vyto-refactor zone ([[vyto-refactor-avoid-display]]) — additive, but may need
   reconcile. Visual is a FIRST DRAFT (built pixel-blind; runner_shot needs the human's reload for new gen).
   spec/Heist_todo.md §0 is the handoff.
See [[crossing-is-live-not-loopback]], [[heist-rulings]], [[radio-cross-pier-wake]], [[boot-20s-stoker-gate]].
