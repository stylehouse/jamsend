---
name: accept-drops-proof-in-entropy-zone
description: Accept can silently drop a Story %see proof that lives inside EntropySamples fuzz-tolerance; absolute-count assertions drift under traffic-volume changes during reality-extraction — use ratios
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ff56d2b0-d35b-4e33-96b4-b8f73a68a322
---

MusuReplica's owner-Accept (2026-07-06) silently DROPPED its only quantitative crush proof — `%see:'dozens of little bits fold into single-digit chunks…'` gated on `stats.folded >= 24` (Voro_crush_scan's return). It was green through the `regroup` commit (7b5059e0); the `fix networking` commits trimmed frame traffic → `folded` slipped under the magic 24 → the see: stopped firing → Accept baked in its absence. The other 3 fold-see: survived because they read c-side STAMPS (`c.stuff`/`cyto_folded`, boolean presence), not the RETURN ratio.

**Why:** two failure modes compounded. (1) An **absolute-count** assertion (`>= 24`) is brittle to traffic-volume changes — and every reality-extraction in the Radiobuddies regroup shifts traffic. (2) The witness beat sits INSIDE the EntropySamples fuzz-tolerance (live dige ≠ recorded, yet rode as `caveat:1` green), so a vanished proof drops as a caveat instead of a hard red — invisible on Accept. A fold either happens or it doesn't; presence/fold proofs should NOT be fuzz-tolerated. See [[entropy-samples-fuzzok]], [[see-is-not-a-latch]], [[musureplica-crush]].

**How to apply:** (a) State Story fold/compression claims as a RATIO not a magic constant — `count <= 9 && folded >= count*3` = "many→few" that survives volume trims and fails only if the fold truly weakens (folded≈count). (b) Before Accepting a re-record, diff the `see:`/`witnessed:` SET against the prior fixture (git grep the sentence across history) — a green run with a dropped proof still goes green. (c) Suspect any absolute count in an assertion that a reality-extraction could move. Fix applied: Musuation.g L3187 → ratio; awaiting owner record to restore green. Ties to [[radiobuddies-regroup-handover]].
