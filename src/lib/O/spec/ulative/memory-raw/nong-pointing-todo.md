---
name: nong-pointing-todo
description: "markdown .md → heading-TOC collector BUILT + verified live (25 regions); 2 downstream gaps remain — language auto-apply on open, and %Map→minimap refresh on same-text recompile"
metadata: 
  node_type: memory
  type: project
  originSessionId: e706066f-325c-4eae-adad-ee0bd28695ab
---

The parse-for-Points path is built. `Lang_collect_markdown_regions` (compile.ts) walks the markdown tree's `ATXHeading1-6`/`SetextHeading1-2` → `region` `%Map` entries (depth=heading level, region_path=ancestor chain, # stripped). **VERIFIED LIVE**: handover.md with markdown wired gives `%Compile/%Map` = 25 region entries, `md_heads=25`, `md_parser:_MarkdownParser`. tsstho (.ts/.svelte) def Map rides the same gates. Gates loosened via `Lang_points_only` (md/ts/svelte). See [[creduler-runner-architecture]], [[map-rel-offsets]].

**Key helper:** `Lang_full_tree(state)` (compile.ts) forces a COMPLETE parse via the language facet's parser when `syntaxTree(state)` is empty/partial (lazy + viewport-driven → empty for an off-view compile, which silently gave 0 headings). Used by the markdown collector AND `whatsthis_txt` (LangWhatwhere.svelte — fixed its "no tree" on markdown; that dump is gated behind `Opt/txtsyntaxdump:1` on `w:Lang`, via `w/Opt/{txtsyntaxdump:1}`).

**TWO OPEN GAPS (both diagnosed, not fixed):**
1. **Language auto-apply** — `lang_for_path('.md')→markdown` detects correctly (toolbar dropdown shows markdown) but the freshly-opened editor STATE keeps the PRIOR dock's grammar (stho/`_LRParser`/Program/Line). Must manually pick markdown (sets `dock.sc.lang_override`, re-fires Langui's reconfigure `$effect` ~633) to wire it. Cause = the reconfigure races view construction: async `lang()` resolves against a since-replaced view. I added a revert-on-view-null guard (Langui ~641, uncommitted) but it doesn't cover the `build_editor` initial path (~1428).
2. **%Map→minimap refresh** — after a recompile rebuilds `%Map` WITHOUT a text change (exactly what a language switch does), the minimap (`dock/%Navicade`) and `%Interest/%MapReport` stay stale (n_region=0). Cause: `req:instrumentation` (runs `Lang_Map_report` + `Lang_build_mapules`) only re-fires when `req_workon`'s `n_sig` changes, and `n_sig` (Lang.svelte:863) = `doc:content_dige:src_serial:LE.version` — keyed on TEXT, not Map content. Fix: add Map dige/`%Compile` version to `n_sig` (Lang_Map_report already digests to `report.c.Map_dige`), OR de-finish instrumentation from compile-settle when the Map moved. TODO phrased for the Interest-system agent (MapReport rides per-checkout `%Interest:Trail`).

**This-session UI fix (LANDED, uncommitted):** `.lte-bar` now renders the language dropdown — was reading the never-populated `H.ave.lang_actions`; now reads `H.actions` (the channel Otro renders) filtered to roles lang_pick/gen_parser.

**Uncommitted (host must commit):** compile.ts (collector + Lang_points_only + Lang_full_tree + **TEMP `md_*` diagnostics on the Compile particle — STRIP once flow lands**), LangWhatwhere.svelte, Langui.svelte. Note [[host-commits-midsession]] already split callers (committed) from compile.ts callees (uncommitted) once — HEAD is inconsistent until compile.ts is committed.
