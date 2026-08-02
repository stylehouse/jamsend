---
name: oai-moai-renamed
description: live C verbs are oai(merge-in-place)/roai(new-ref)/doai; moai is dead; several O/spec docs were stale on this
metadata: 
  node_type: memory
  type: reference
  originSessionId: c67a2909-19bd-48ca-8f50-78a33a99ae82
---

The merge-in-place find-or-create verb is now **`oai`** (was `moai`; the old
birth-only `oai` that ignored its 2nd arg is gone). Live verbs:

- `oai(s,c)` — sync, merges `c` in place on a found particle, bumps `version`
  only on a real non-function drift; **same ref** across ticks. Subscribe via
  `.vers` / `.ob()`. Everyday verb.
- `roai(s,c)` — async, replace-on-drift → **new ref** (use only when a consumer
  keys on ref identity, e.g. keyed `{#each (n)}` / Otro UIs mount).
- `doai(c,sc)?.(fn)` — `oai` + one-shot `do_fn`, the `%req` verb.

`moai` is dead everywhere: not a method (`Stuff.svelte.ts` has only oai/roai/doai),
not a grammar token (`stho.grammar` IOness2 = `oai|roai|r|rm`).

Docs were stale and actively misleading (said "oai ignores its 2nd arg, use roai
for live state"). Fixed: `reactivity_docs.md` oai/roai section, `Wire_spec.md`,
`LangSolver_report.md`, `Waft-palmtree-trajectory.md`. Banner-noted (reasoning
left intact): `Hovercraft.design.md`, `LangCompiler_TODO.md`. Still-stale `moai`
in CODE comments (out of that sweep): Langui/Lang/Diffmatication/MachReqy/MachPeerily.

Action-rack reactivity pattern: `wa.oai({action:1,role},{label,cls,fn})` keeps the
ref and bumps the particle's vers; the renderer (`Actions.svelte`) must read
`a.vers` to repaint. `r()`/`roai` there mints a fresh ref each tick → paired `+`/`-`
churn in every snap diff. See [[o-query-wildcards-on-1]].
