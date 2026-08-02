---
name: story-step-lines-drive-steps
description: "Story Book toc.snap — the step=N,dige lines (not Preps alone) decide how many steps run"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c60bfb9d-149f-44b1-82ae-ac208dab6e3e
---

In a Story Book's `toc.snap`, the `step,dige:` / `step=N,dige:` lines are what decide **how many
steps execute** — a `Plan/Prep=N` only fires if there is a matching `step=N` line. Adding Preps
alone does nothing; you must add a `step=N,dige:<placeholder>` line per step you want to run.

- The **numbering matters** (sequential: `step` is 1, then `step=2`, `step=3`, …).
- The **dige is a lie** until recorded — put any 16-hex placeholder (e.g. `0000000000000007`);
  the runner computes the real dige on the next run and replaces it (disk-dige mismatch → promote).
- The runner does **not** auto-add a trailing/quiesce step beyond the step lines authored.

Why this bit me: I assumed steps mapped 1:1 to Preps automatically and that the runner owned all
`step=` lines (the "don't hand-edit step,dige" gotcha is about not faking RECORDED diges to pass a
gate — but you DO hand-author step lines with placeholder diges to *enable* new steps). The Story
runner is browser-driven (:9091); the human records the real diges. Related: [[interest-channel-graduated]].
