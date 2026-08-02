---
name: human-scan-label-decisions
description: "The human scans a doc for 'what does Claude want ME to read/decide'. REFINED 2026-07-26: most 'decisions' I surface are NOT substantial to them even when labelled — so DECIDE them, and weave the rare real call (usually taste/naming/priority) into a NARRATIVE pitch, not a question-list they have to hunt."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

When the human opens a todo/handover doc, their eye is hunting for **the bits that are FOR
 them** — decisions only they can make, things I want them to read — and prose buries those,
  so they don't find them.

**Why:** a `## 0.`/next-move section written for a fresh SESSION is not the same as the calls
 that are the HUMAN's; mixing them means the human reads the whole doc to extract their two
  decisions. They told me straight: "looking for whatever you want me to read and not finding it."

**How to apply:** put a **`## HUMAN — the calls that are yours`** block at the very top of a
 working doc (right after the status line, before `## 0.`), listing each decision as a question
  with **my recommended pick as the first line**, and say plainly which single thing I genuinely
   can't decide for them. Tag any decision-sentence deeper in the doc with **`HUMAN call`** so a
    closer scan still lands on it. Keep the rest as "my working map — read only if a why didn't
     land." First applied to `spec/Reqdrop_todo.md`.

**Refinement (2026-07-26) — the deeper lesson.** The human, on being handed a `## HUMAN`-style
 decision list *again*: *"I don't have time to climb around in the docs looking for questions, and
  they're almost never substantial questions for me, even when you point me at them."* So the bar is
   higher than *labelling* the calls — it's **not raising most of them at all**. Almost every fork I
    flag is one I can settle from the code/docs/sensible-default ([[high-autonomy-overnight]]); DECIDE
     those and just say what I did. Reserve surfacing for the genuinely-substantial call — usually
      **taste/naming/priority**, the thing I truly can't pick for them — and **pose it woven into a
       NARRATIVE pitch of the work**, at the natural moment in the telling ("here I'd go X — unless
        you'd rather Y"), so it's answerable in a breath, not a `## Open Decisions` block to hunt
         through. Pitch the WORK as a story; let the one real question dissolve into it. Related:
          [[no-paper-pushing-groove]], [[todo-docs-overstate]], [[high-autonomy-overnight]].
