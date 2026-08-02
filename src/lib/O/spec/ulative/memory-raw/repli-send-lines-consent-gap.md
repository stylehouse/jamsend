---
name: repli-send-lines-consent-gap
description: "Repli_send_lines consent gap — Musica goner-delete leg FIXED 2026-07-17 (guard in Musica_recast_offer + Book MusuFreeze green ×2 with sabotage proof); Repli_retire STILL EXPOSED; core-seam choice (gate the primitive?) = the human's call"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0da3cb3b-d094-4c32-8e27-daa138a39d1f
---

**The gap (found by adversarial review of MusuBuddy, 2026-07-14):** `Repli_offer` (Repli.g:283)
gates on `Repli_allowed(w, to, from)` and returns false for a revoked peer — so NEUS/updates never
cross to someone whose grant was pulled. But `Repli_send_lines` (Repli.g:229) does **NOT** consult
`Repli_allowed`; it unconditionally `Peeroleum_send`s. And `Musica_recast_offer` (Heist.g:706 for a
cloud-level `Mag>del Cloud`, :720 for a record-level `Mag>Cloud>del Record`) calls `Repli_send_lines`
DIRECTLY for goner deletes.

**So the consent gate is asymmetric:** you revoke a follower, then drop a record/cloud at the origin
→ the `op:delete` line **crosses to the revoked follower and mutates their mirror**, past a closed gate.
The wire refuses to ADD to a revoked peer but will still DELETE from their mirror. Wrong direction of
trust — a revoked peer's held copy should be frozen, not remotely editable.

**Why it hid:** every M4 Book that crosses a goner (MusuRecast) does so while the grant is LIVE; the
one Book that revokes (MusuBuddy see 11, [[see-is-not-a-latch]]) ADDS a card in its revoke scene, so
`Repli_send_lines` is never reached there. No Book yet exercises delete-AFTER-revoke, so the leak is
un-asserted (vacuously absent, not proven closed).

**FIXED 2026-07-17 (the surgical seam):** `Musica_recast_offer` (Heist.g ~1007) now takes
`let allowed = this.Repli_allowed(w, to, from)` (~:1032) and both goner loops `continue` when
!allowed before their `Repli_send_lines` — receipt arrays still populate (the origin's local census
diff stays honest); nothing crosses the closed gate. **Book MusuFreeze** (Heistation.g after
MusuRecast; 9 steps, synthetic Lake_link loopback, no entropy band) green ×2 on 49dee91d with the
full sabotage discipline: guard neutralised first → `leaked` fired + the revoked mirror LOST t2 +
sees 3-4 red while the granted control stayed green (real discrimination); guard in → `quiet_wire` +
`frozen,t2_frozen` + the mirror keeps the frozen copy. MusuRecast re-verified byte-identical (the
guard is a no-op under a live grant).

**STILL EXPOSED — the human's core-seam call ([[fight-back-on-core-changes]]):** the caller survey:
`Repli_offer` gated (:283); `Repli_serve_want` gated (:380); `Repli_serve_chunks` gated only
transitively (sole caller is serve_want — no check of its own); **`Repli_retire` (Repli.g:292) is
the same raw-primitive pattern with NO gate** — unreached by Musica today, but any future caller
retiring to a revoked peer leaks identically. Options standing: gate Repli_retire too, or move the
gate INTO `Repli_send_lines` (the core primitive — the human's decision, not an agent's). Also owed:
the per-peer discrimination scene (two followers, one revoked one live) — blocked on per-follower
mirror routing (`Repli_mirror_lib` keys off a single global `w.c.repli_mirror_pier`, the M4 rung).
