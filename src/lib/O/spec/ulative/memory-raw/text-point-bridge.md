---
name: text-point-bridge
description: "fine-grained Point,text:<word> kind that resolves to a literal doc occurrence (sub-line), bridging the same shared token across Docs/substrates"
metadata: 
  node_type: memory
  type: project
  originSessionId: ec4d37d1-d9d4-432a-8a44-e895d203fe79
---

New Lang-layer Point kind: **`Point,text:<str>`** — a fine-grained (sub-line) Point that resolves to a
 LITERAL occurrence of a word/phrase in the Doc's own text, not a named def/region/heading. Built for the
  music cluster's "bridge the substrates" ask ([[music-cluster-kickoff]]): the SAME `text:` string lands on
   its own occurrence in each Doc, so a `What` listing two/three Docs each with `Point,text:<token>` lights
    that shared token up across substrates (spec ↔ new `.g` ↔ old `.svelte`). Tokens are *discovered in
     common* via a token-intersection over the Docs (author-time script for now; a live auto-minter is the
      follow-up).

Mechanism (all additive — fires only on a `text:` prefix / `sc.text`, can't affect existing Points):
- `Lang_resolve_point` (src/lib/O/LangRegions.svelte) — a `text:` branch at the TOP (before the `%Map`
   null-check), so it resolves with only `state.doc`, even before a compile. Order: word-boundary exact
    (`\bneedle\b`, only when `/^\w+$/`, so 'want' misses inside 'wanted') → `indexOf` substring → loose
     case-insensitive. Returns `{from, to, line, kind:'text'}` on the token's own char span; null on miss.
- spec extractor: `Lang_point_spec` (src/lib/O/LangGraft.svelte:~389) + the two inline twins
   (Lang.svelte:~1091 Lang_pointed_specs, LiesHold.svelte:~758 clone_spec) now read `sc.text` first →
    `'text:'+sc.text`, else the existing `sc.method ?? sc.label ?? sc.Point` chain.

Status (2026-06-25): resolver HEADLESS-VERIFIED (EditorState.create + Lang_resolve_point: keep_ahead /
 word-boundary want / STAY_AHEAD_OF_ACK_SEQ resolve, miss=null). Browser click-through on :9091 (the
  goto/fold/minimap-highlight path: e_Lang_goto_point→dock.c.seek; Lang_apply_openness fold-around) still
   OWED. Spaced phrases NOT yet (snap value needs quoting; single tokens robust). Uncommitted.
Live demo bridges in wormhole/Ghost/Music/Ality/toc.snap `What:bridges`.