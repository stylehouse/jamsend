---
name: desc-on-steps
description: "%desc step annotations LIVE-PROVEN: beat emits i %desc:'few words' (no commas) → harvested The-side pre-encode → toc step line + Storui + steps op"
metadata: 
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

Landed 2026-07-18 (uncommitted): a Book describes its own step with `i %desc:'a few words'` (NO
 COMMAS — em-dash) at the beat. `story_harvest_desc` (Story.svelte, called in
  snap_step_after_wave BEFORE story_snap) moves it The-side and drops it from the flora — %desc is
   metadata ABOUT the step, never snap bytes, so retrofitting descs onto recorded Books never
    churns a fixture. Toc line: `step=N,dige:…,desc:…` (both codecs round-trip it with zero codec
     work). Shown in Storui (pip title + `.sr-pdesc` panel header) and the `steps` op (The-side
      join in LiesFunk).

**Why:** the human: "steps can have %desc when meaningfully created — should have existed
 already; a few words about what happens per step."

**How to apply:** emit on the flora w only (a req**-buried %desc would leak into the snap).
 Harvested-desc overwrites; hand-authored toc desc with no emission stays. WART: step 1
  re-encodes as bare `step` (numeric 1 → presence form) — decodes fine. Proven live: the runs
   wrote descs into wormhole/Story/Sounditron/toc.snap. See [[sounditron-wild-book]].
