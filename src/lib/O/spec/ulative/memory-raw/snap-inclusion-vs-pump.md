---
name: snap-inclusion-vs-pump
description: "snap inclusion = tree reachability (H**), orthogonal to off-pump/unswept req-pump state — do not conflate"
metadata: 
  node_type: memory
  type: project
  originSessionId: adc85dac-7c1b-4e93-b5ed-22e12fd629bc
---

A particle is in the snap iff it is **reachable in the live C tree** — `enWaft`
is `Travel + enLine` (Text.svelte ~117+), a depth-first walk that encodes every
particle it reaches under H**. The only sc-level exclusions are `SESSION_KEYS`
(`active/created_at/new/not_found`, via `omit_sc`) and `.c` refs (never in the
tree). A particle leaves the snap only once it is no longer in the tree (dropped).

**Off-pump / unswept is a DIFFERENT, orthogonal thing.** The req *pump*
(`reqy_recurse`/`do`/sweep) descends only `%req` children, so a wrapper hosted
under a non-`%req` mainkey (e.g. `%fs_op`, the wormhole off-pump queue in
Housing.svelte.ts ~1712) is not *driven* by the pump — but it is still fully
*snapped* while it sits in the tree. Off-pump governs whether work runs, NOT
whether it persists.

**Why:** I kept asserting "off-pump/unswept ⇒ isolated from the snap" — wrong, a
repeated "lie" the user corrected. Snap = in H**; pump-supervision = which `%req`
children get pumped. Never infer snap-exclusion from pump-exclusion.

**How to apply:** when reasoning whether a transient/queue particle is snapped,
ask only "is it still in H** at snap time?" — not "is it pumped/swept?". Concrete
fallout: anonymous `%req` wrappers must use `oai({req:1})` (mints a serial
`%req:2,3,…`) not `i({req:1})` — being off-pump does NOT prevent two literal
`%req:1` siblings colliding in the snap. See [[req-migration]].
