---
name: map-rel-offsets
description: "%Map child entries now snap region-relative rel_from/rel_to (+ c.abs_* live cache); regions carry body-extent to; readers go through Lang_map_span. Navicade/Mapule layer is the follow-up."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a885348-d794-4531-a60c-b8018bb8a0d8
---

To kill `from=/to=` snap churn in `%Compile/%Map`: child entries (def/call/controlflow)
no longer snap absolute char offsets. They snap **`rel_from`/`rel_to`** (relative to their
enclosing region's `from`, matched by full `region_path`) and carry **`c.abs_from`/`c.abs_to`**
(live absolute, set every compile, never snapped). Region entries stay the absolute anchors and
now carry a real **body-extent `to`** (header line → matching `//#endregion`, else EOF) instead
of the old header-line-only span — which also unblocks the LangPoint "relative locators" TODO
(a `region / method` stack-path can now narrow into the body).

- Emission: `lang/compile.ts` flush loop + the `//#region`/`//#endregion` branches (`open_regions` stack).
- Readers go through **`Lang_map_span(regions, e)`** (LangRegions.svelte): regions → `sc.from/to`;
  others → `c.abs_*` if present, else reconstruct `region.from + rel`. Rerouted: `Lang_resolve_point`,
  `Lang_find_within_range`, `Lang_def_at_offset`, `e_Lang_tap`, and `Lang_build_mapules` (Lang.svelte).
- **The migration missed two readers** (found later, now fixed): `Lang_ensure_graft` (LangGraft.svelte)
  read `def.sc.from/to` to stamp the graft child, and `e_Lang_goto_point` (Lang.svelte) read
  `hit.sc.from` for region-named nav. Both saw `undefined` post-migration. **Tell:** an `undefined`
  offset on a snapped particle forces `encode_stringies` to the JSON-blob fallback (Text.svelte) —
  a `graft` line snapping as `{"graft":1,...}` minus its `from/to` is the visible signature; the
  nav one is silent (jumps to 0). When auditing any `%Map` def/call/cf consumer, the test is: does
  it read raw `.sc.from/.to`, or go through `Lang_map_span`?
- `Lang_Map_report`'s dige already ignored from/to, so the MapReport gate is unaffected.

**The bomb / follow-up:** the noise lives in TWO snapped layers. This fixed `%Map` (Editron-type
snaps). The derived **`%Navicade` Mapulen** (LakeNets snaps ×13) still snap ABSOLUTE from/to —
`Lang_build_mapules` reconstructs absolute so they keep working, but their snaps still churn.
Next step: same rel treatment on the Mapule layer, OR (cleaner, fits the "remove machinery"
doctrine) de-snap the Navicade cache entirely since it's rebuilt every compile.

Human must **re-record** the affected Story snaps (Editron etc.) — entries now read
`rel_from/rel_to` + region body-extent. Verified UIless via the lang-compile CLI + a Map dump
(svelte-check OOMs in this container). See [[host-commits-midsession]], [[snap-inclusion-vs-pump]].
