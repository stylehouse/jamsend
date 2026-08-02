---
name: accept-targets-active-run
description: "runner_ask accept IGNORES @uid — it re-records the tab's ACTIVE engagement, not the held run you name"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 587585e3-e873-4c0a-926a-ee486cbe4df5
---

`node scripts/runner_ask.mjs accept @<uid>` does **not** honor `@uid` — the runner's accept
handler re-records whatever run is the tab's **active engagement** (`this.c.run`), which may be a
*different* Book that got dispatched after yours. I named `@08e256c4` (a done MusuHeist) but the
active engagement had flipped to a **failed VoroMitosis**, so accept recorded the failed run over
VoroMitosis's fixtures — clobbering the human's uncommitted Voro toc work (unrecoverable; only
`git checkout` back to HEAD was possible).

**Why:** accept trusts the live engagement, and a tab can be re-dispatched to another Book between
your run and your accept. A failed-run recording is silent corruption.

**How to apply:** before `accept`, **re-dispatch YOUR Book** so it is the active engagement, then
`state` to CONFIRM `run.book` + `engagement.book` are yours, THEN accept — fast, before anything
flips the slot. `accepting:0` with the right book just means nothing structural to accept (benign
entropy ≈, don't chase). Related: [[verify-via-live-runner]], [[entropy-samples-fuzzok]].
