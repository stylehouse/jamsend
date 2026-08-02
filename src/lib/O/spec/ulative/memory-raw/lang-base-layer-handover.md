---
name: lang-base-layer-handover
description: Lang base-layer handover doc (the editor/compile/index machine) + the dock.c.state three-role seam — NOW CUT (role #2+#3, headless-verified, browser-verify owed)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6ec014c4-9aa0-4ac9-bea1-d82dc3ea4ff6
---

`src/lib/O/spec/Lang_handover.md` (→ becomes `Lang_doc.md`) is the **base-layer** handover for
the Lang machine — the layer *under* Editron/Lens/Interest. §1–6 = orientation (the edit→compile→
%Map→minimap/fold/.go loop; the ghost family table Lang/Langui/LangCompiling/lang/compile.ts/
LangRegions/LangPoint/LangGraft/LangWhatwhere/LangLang/LangSion + lang/registry; the dock model
`{dock:path}` under w:Lang, single `dock.c.state` writer at Lang.svelte:413; the Waft→What→Doc→
Point tree).

§7 is the load-bearing part: **`dock.c.state` serves three roles indifferently** — #1 display
(wants view.state), #2 compile-source (wants its own `lang(path)` parser, decoupled), #3 index-
oracle (wants the frozen compiled-against snapshot). #3 splits into 3a-fold (live, → view.state)
and 3b-Mapanchored (→ snapshot). All four recurring editor bugs (lang-reconfigure lag, channel
one-round-lag, remote-compile-mounts-a-dock, first-open-extra-step) are this one fusion. The `#`-
retained single minimap row proves first-open indexes a non-markdown state (collector strips `#`,
compile.ts:198). **The cut**: build compile-source from `lang(path)` for every compile + stamp
`job.c.source_state`; repoint 3b readers (LangRegions×3, whatsthis) to it, 3a+text to view.state.
Risk concentrates in 3b (offset drift). Do role #2 first (retires 3 masks), role #3 second.

**THE CUT IS NOW DONE (role #2 + #3), 2026-06-24, type-clean + headless-verified, browser-UNVERIFIED.**
`Lang_compile_source_state` rewritten to guarantee the `lang(path)` parser for EVERY compile —
cheap form: reuse `dock.c.state` when its grammar already matches (`Lang_state_lang_is(state,want)`
in compile.ts, positive identity so never a false-positive reuse), synthesize fresh only on parser
mismatch (no per-settle EditorState.create). `Lang_compile_dock` routes the normal path through it.
3b readers repointed to `Lang_index_state(dock)` (=`job.c.source_state ?? dock.c.state`): def-at-
offset + tap + point-nav (LangRegions), whatsthis (Lang.svelte). 3a fold (LangPoint) + gen-text
(LangLang) → view.state. parser-gate (Lang:1916) left as belt-and-suspenders (guards "no parser",
not "wrong parser"; comment updated). NO offset-WRITER touched (LangGraft rides CM StateField .map).
Verified: `node scripts/LakeRace.run.mjs` 3/3 — warm+cold+recv branches on real Peeroleum.g.
Browser-verify still owed (§8): .md first-open extra-step gone (mask #4), 3b bookmark round-trip
(type above a bookmark, jump — must still land). The `md_*` TEMP diagnostics in
Lang_collect_markdown_regions are now STRIPPED (first-open verify is purely visual now).

FOLLOW-ON landed (staleness axis): stored Map offsets go stale on edit until req:compile's ~6s
keyboard-settle. e_Lang_tap + e_Lang_point_navigate now reindex the LIVE buffer at the gesture
(`Lang_compile_dock(w,dock,view.state)`, points-only only — .g skipped, a .g reindex re-runs
GEN→.go→runner) so nav never waits on the settle timer; re-stamps job.c.source_state=view.state so
the Lang_index_state reads resolve in the frame the fold/selection dispatches onto. Leans on
Lang_map_span's region_path+rel_* reconstruction (meaning-over-offset). Same view.state-vs-
stateCompiled split on the *time* axis. type-clean, LakeRace still 3/3, browser-unverified.
Also removed the `🟦 tiles N bookmarks` see-line (Lang.svelte whatsthis block).

ALSO landed this session (Lang/Langui, uncommitted, browser-unverified):
- **Slow-open overlay** (Langui): a big centred spinner veils the editor when a Doc open exceeds
  0.2s, driven off the existing furnish|text_load %Languinio spinners (`slow_open` $effect + a 200ms
  timer; cached re-opens set neither spinner so a fast switch never flashes it). Verify: appears on a
  slow open, not on a fast/cached switch.

**NEXT MOVE (the open Lang bug) — Point RE-ANCHORING on recompile.** Type above a Point and the text
shifts (CM maps the LIVE decoration so it follows) but the bookmark's STORED from/to + the jump
target don't follow, and recompile rebuilds %Map/Navicade with fresh method offsets WITHOUT
re-anchoring the bookmark → the bookmark `vanished`s + MiniMap goes stale (seen live: bm_10263_10289
method:Peeroleum_on vanished after an edit; Navicade had transport at the new line=223). Fix: on
recompile, re-anchor each bookmark to its method's current %Map span by NAME (look it up in the fresh
Map, update from/to) — leans on Lang_index_state + Lang_map_span's region_path+rel_* (this cut's work).

Adjacent NON-Lang work this session: Output-mung for Editron snaps → [[editron-verdict-phase2]];
log:source_write drop-Entcase in the Lies NormalEntropy Trope → [[entropyarrest-spay-design]];
want-drain cap in Lies_resolve_wants → [[want-drain-cap]]. Related: [[map-rel-offsets]] (the seed of
3b done right), [[nong-pointing-todo]], [[langui-lang-detection]].
