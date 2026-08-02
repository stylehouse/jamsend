---
name: lies-lang-recleave-by-layer
description: "deliberate re-cleave of the Lies*/Lang* modules by LAYER not lineage; where things live NOW — LiesHold (Understanding+workon), LiesFunk (runtime, was LiesWaft), LiesRun (runner, carved from LiesCortex)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5cc0cd68-8ccd-4b37-bc05-d53e3569ab8a
---

The Lies*/Lang* split was **lineage** (which ancestor ghost spawned a method), not layer. An ongoing program (2026-06-24/25) re-cleaves by layer. Guiding rule: **Lies = the document machine (model→understand→compile→run pipeline); Lang = the language + its view.** All moves are working-tree (human commits); each is type-clean via svelte-check but **browser-verify owed**. Cross-file calls all resolve through the one H.* eatfunc table, so a method works regardless of which file holds it.

**Where things live NOW (the load-bearing part):**
- **LiesHold.svelte** (was LiesEnd) — the Understanding: Seem / LE_* + the `req:workon` driver & stages (`req_understanding/ingredients/furnishing/instrumentation`), pulled in from Lang. The workon SEEDING stays in `Lang_plan`; only the do_fns moved. Dual-mounted (Lies + Lang).
- **LiesFunk.svelte** (renamed from LiesWaft) — the dynamic-web runtime (Funkcions / Waft_dip / Ballistics / editor↔runner verdict / StoryTimes). Freed "Waft" for the model. See [[lieswaft-dynamic-web-home]].
- **LiesRun.svelte** (carved from LiesCortex) — the run pipeline downstream of a settled compile: `Pantheate`/`req_include`/`e_Pantheate_run_method`/`req_run_method` (w:Pantheate) + `req_Rundown`/`req_BlatDo`/`e_Rundown_arm`/`e_Rundown_leash` (w:Lies). **Debug the runner in LiesRun now, not LiesCortex.** Mounted by Lies.svelte beside LiesCortex.
- **LiesCortex.svelte** — now the compile FOREMAN only: `req:Cortex`/`req:Codebit` + gen-path/codetype helpers.

**Correction the survey forced:** the original blueprint said "carve the document MODEL into a (reclaimed) LiesWaft" — WRONG on contact. `Lies.svelte` already IS the model (open/close/foreground/rename Waft + particle layout + surprise/merge); carving it would gut the `w:Lies` world ghost. So the model STAYS in Lies; the LiesWaft reclaim collapsed to just freeing the name (the LiesFunk rename).

**How it's done mechanically:** anchor-based node script extracts method spans verbatim (NO global blank-collapse — that pollutes the diff), then fix the two mount sites in Lies.svelte + stale `lives in <oldfile>` comment refs, then svelte-check (grep the edited file's ranges, not the total — it drifts run-to-run). Remaining: the view sub-family (LangRegions/Graft/Whatwhere/Point) is already clean. Related: [[aw-req-level-uniformity]].
