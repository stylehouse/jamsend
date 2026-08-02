---
name: ballistics-drum-pad
description: Ballistics = havoc drum-machine; %havoc particles authored in the Waft tree render as inline strike pads; HAVOC_LIMBS engine
metadata: 
  node_type: memory
  type: project
  originSessionId: 2a47a269-1da9-4165-9d39-21bcea3120d2
---

**Ballistics** is the testing regime's reusable "havoc drum-machine": a way to *pop a limb
out of the Lies/Store plumbing* on demand. A **limb** is authored as content — a `%havoc`
particle (`{havoc:<kind>}`, + optional `emoji`/`hint`) dropped **anywhere in a Waft tree**
(it's per-test config, lives in the snapped doc tree; the parked vocabulary gate in
`enWaft`/`encode_wh_lines` means an unknown mainkey like `havoc` is NOT fatal — it snaps fine).

- **Rendering**: `Waft.svelte`/`waftitem` detects `C.sc.havoc` and renders it **inline as a
  strike pad** (💥 + kind label); a switcheroo Waft in **raw mode** shows the bare particle
  instead (`havoc_raw`). NOT a separate UI/component, NOT a Funkcion (rejected — Funkcions are
  the auto-pumped Lies behaviours).
- **Engine** (reusable, in `Lies.svelte`): `HAVOC_LIMBS` — a module const map `kind → {run(H,w)}`.
  `e_Lies_strike {kind}` looks up the limb, runs it, wakes a tick. The particle is pure config;
  behaviour lives in the registry. **Add a limb** = add a `HAVOC_LIMBS` entry; the inline pad +
  strike dispatch by kind, nothing else to touch.
- First limb `surprise_read` → `Lies_fabricate_surprise_on(w, path)` targeting the **active doc**
  (`H.Awo('Lang').c.active_dock_path` — the live truth; `examining.sc.active_path` is DEAD,
  nothing writes it anymore). Drives the [[surprise-read-popover]] demo.

**Deferred (the user's "another whole concept")**: a limb that *arms itself* — receives `think()`
while the `What**` it sits in is engaged / not folded away (Lang openness + Scrollability) —
rather than only firing on a manual strike. Structured for it; not built.
