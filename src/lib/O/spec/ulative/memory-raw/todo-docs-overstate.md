---
name: todo-docs-overstate
description: spec/handover todo items in this repo consistently overstate difficulty — verify against live code first
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5d12a0a1-2478-4a75-a383-4258f45aa400
---

When picking up an item from a spec/handover/todo doc (e.g. [[Everything_todo]]'s
 src/lib/O/spec/Everything_todo.md), verify it against the live code *before*
  sizing the work — the docs systematically overstate difficulty.

**Why:** in one session, three consecutive items shrank on contact: a Stuffing
 "over-creation" bug was already solved, a "Point nesting reconciliation" was a
  misread (snap and memory shapes actually agreed), and a real "blind bookmark
   export" was fixed by one elvis routing through an existing seam (`e:mark`
    `op:add` → `LE_add_clone`). The gap is usually narrower than written and an
     existing seam usually already covers it.

**How to apply:** grep/Read the relevant code and snaps first; treat the doc's
 per-subsystem status prose as drift-prone and trust its open-decision list more.
  Report the real (smaller) scope back rather than building to the doc's framing.
