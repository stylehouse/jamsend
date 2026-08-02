---
name: central-stuff-housing-hovercraft
description: Stuff+Housing are the two central modules; Housing.beliefs() is the modern think-loop (was agency_think); i_elvisto replaced legacy i_elvis; Hovercraft = transient %req level between them
metadata: 
  node_type: memory
  type: project
  originSessionId: 5d12a0a1-2478-4a75-a383-4258f45aa400
---

The architecture centers on **two modules**: `data/Stuff.svelte.ts` (the C
substrate — TheC, sc/c, o/i/oai, X-indexes, Travel) and `O/Housing.svelte.ts`
(the House machine on top — H/A/w levels, the think-loop, mutex, Stuffing,
Dexie, Wormhole). **Hovercraft** sits between, owning the transient `%req`
level (reqyoncile/reqonce/reqy_recurse/ttlilt) — "negotiating for more Housing
with Stuff."

Key lineage, easy to get wrong: `Housing.beliefs()` (organise → attend →
reqdo_sweep) **is** the old `agency_think()` (header comment at
Housing.svelte.ts:883 says so). Legacy `ghost/Agency.svelte` was largely
reimplemented natively in Housing — its elvis routing (`i_elvis`/`Modus_i_elvis`
setTimeout routers, `elvised_A_w`, `o_elvis`, `Aw_think`) is superseded by
`i_elvisto`/`_i_elvis` + `_expand_Aw`/`_e_targets_T`/`attend`/`do_fn_for` +
`_deliver_targeted` (handler `e_<elvis>`). **`i_elvis` is not how we do things
anymore** — use `i_elvisto(target, method, …)` + `e_<name>` handlers.

As of 2026-06-19 the **Agency ghost is de-included from `Ghost.svelte`** (the
central-House "island" — where Modus became House). Its hovering helpers were
copied into Hovercraft (`//#region Agency machine` + a `//#region relics` for the
%aim/%satisfied bits) and `prandle` to the House class in Housing. Legacy
`Agency.svelte` is untouched and still mounts on the **p2p Modus**
(`Modus.svelte`, which drives via `Modus.the_main → agency_think`). So Ghost.svelte
mounts are the modern island; ghost/Agency + Radios/Records/Pirating/Directory are
the legacy p2p Modus world.

So when classifying legacy-vs-modern here, **check Housing first** — the central
machine usually already has the modern version; the ghost is the old copy.
Housing.svelte.ts:1202 flags the residual entanglement: a few helpers
(self_timekeeping, agency_officing, Aw_satisfied, w_forgets_problems,
reset_interval, prandle, whittle_N) are still injected by the legacy Agency
ghost and "could move to Hovercraft." Full kept|gone breakdown +
prandle-determinism-channels TODO in spec/Agency_to_Hovercraft_plan.md (pointer
in spec/Everything_todo.md). `i_unemits_o_Aw` is being rebuilt in Peeroleum,
not moved.
