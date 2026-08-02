---
name: multidocwhat-chosen-doc
description: "What-focus alpha sub-Doc (c.alpha_doc, was chosen_doc) picks which Doc of a multi-Doc What is active; per-Interest in_Doc memory; cross-Doc Point trail is the next phase"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6ec014c4-9aa0-4ac9-bea1-d82dc3ea4ff6
---

Cursor/Interest granularity to pick a particular **Doc within a multi-Doc What** (a "multiDocWhat", e.g. `What:'the spec'` = 3 Docs). Model: focusing a What also picks one of its Docs — the **alpha** sub-Doc — and one Point (in_Point, the sibling axis). The cursor "mildly mentions" the alpha; default = first Doc.

**The problem:** cursor src is a single particle; clicking a Doc-in-a-What lifts to the parent What (full-What LE extent) and dropped which Doc. `Waft_src_doc` (the one shared resolver, `LiesEnd.svelte`) then picked the **first Doc**, so clicking the 3rd opened the 1st.

**DONE (uncommitted, browser-unverified):**
- `what.c.alpha_doc` (renamed from chosen_doc) = a Doc path string, off-snap. `Waft_src_doc` honors it (after "src is a Doc") if still in the live Doc-set, else first-Doc (self-heals on rename/remove). Both consumers read the live What: `Lang.svelte:841` want_doc + `Lang_set_interest` in_Doc.
- `e_Lies_set_cursor` (LiesCurse): a Doc-row click stamps `src.c.alpha_doc`. Sticky per-What memory falls out free — bare What-click (`e_Lies_cursor_what`) reads it back.
- **Per-Interest memory home:** `Lang_set_interest` restores `armed.c.alpha_doc` from the Interest's remembered `in_Doc` (if the live What lost it — e.g. re-decoded Waft — and the Doc is still one of the What's), then `Waft_src_doc_path(armed)` projects alpha?? first back to in_Doc. So the Interest's in_Doc IS the within-session memory.
- Off-snap on purpose: session-sticky, not cross-reload. Persisting = `sc` → hits rename-caretaking (Interest.md per-(Interest,Waft) cursor-memory TODO).

**NEXT phase:** the cross-Doc Point **trail**. `LangGraft` grafts Pmirrors only for the *active* dock; other Docs' Points resolve only when active. Unresolved Pmirror = `%Pmirror` with no `%graft` child (spec unmatched in THIS dock). Surface unresolved + per-Doc Point strata in NaviCado; hop a Point → switch alpha Doc. The What's Doc-set is the trail, alpha = position, in_Point = position-within. Also Point-click `dpath=undefined` gap for direct Points under a multi-Doc What (`Waft.svelte:769`).

Related: [[aside-stance-aware-foreground]], [[map-rel-offsets]], [[nong-pointing-todo]], [[interest-channel-graduated]].
