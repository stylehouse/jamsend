# Waft** styling — cohere runs of Whats, present doc names honestly

A spin-out task, runnable in parallel with the Point++ work (bookmark→Point via
 the active Interest's LE). **No file overlap** with Point++: that work lives in
  `Lang.svelte` (`e_Lang_shoot_point`) and `ui/DocPoint.svelte` (the bookmark
   row). This task lives in the Waft\*\* tree renderer — `ui/Waft.svelte` (and
    possibly `ui/DocMinimap.svelte`). Stay out of `DocPoint.svelte` and the
     `mark`/`LE` seam and the two won't collide.

## The destination

The Waft\*\* tree (a `Waft → What* → (Doc, Point*)` forest) renders today as a
 literal indented list. Two cosmetic-but-load-bearing wins:

1. **Continuous runs of Whats cohere.** Adjacent sibling Whats that channel the
    **same Doc** currently each repeat their `Doc:path` label. See a real snap,
     `wormhole/Story/LakeNets/013.snap` lines 21-47:
       Waft:Story/LakeNets/Waftily
         What:foundations
           What:story
             Doc:Ghost/test/Story/Lake/LakeAmeliorations.g
             Point,method:LakeNetherland,class:caution
           What:peer
             Doc:Ghost/test/Story/Lake/LakeAntecedents.g
             Point,method:Peeroleum
    The Doc is restated under every What. Cohere a *run* (maximal stretch of
     sibling Whats pointing at one Doc) by drawing the Doc **once** as a shared
      spine and letting the Whats be beads on it — StemHive's stem idiom
       (`ui/StemHive.svelte`) is the precedent. A run breaks when the Doc changes.
        Do NOT change the C tree or the snap — this is render-only; every
         What/Doc stays present (we are deliberately NOT making Waft\*\*/Doc
          sparser — forking Whats must stay cheap and reliably there).

2. **Honest doc names.** A Doc path like `src/lib/O/test/Peregrination.svelte`
    should show `Peregrination` prominently, but **never lie**: render the whole
     real path so select-and-copy yields the truth, and lift the stem
      (basename minus dir and extension) visually — bigger/brighter span — while
       dimming the `src/lib/O/test/` prefix and the `.svelte` suffix. No string
        substitution, no `transform` that lies about geometry. `LangPoint.svelte`
         (lines 38-52) is the precedent: it scales real font-size, not a
          transform, precisely so the text stays honest and copyable.

## Entry points

- `ui/Waft.svelte` — the renderer. Line 72-77 is the Point peel encoding; it
   already classifies `What`/`Doc`/`Point` rows. The run-coherence grouping and
    the name styling both land here (or in a small child component it spawns).
- `ui/StemHive.svelte` — copy the stem/spine visual idiom for the run spine.
- `ui/DocMinimap.svelte` — check whether the same tree is mirrored here; if so,
   the name styling may want to be a shared helper.
- The doc name span helper (split a path into prefix / stem / ext) is pure and
   testable — put it where both Waft and DocMinimap can reach it.

## What "a run" means (the coherence rule)

A run = a maximal sequence of **sibling** Whats whose resolved Doc is the same.
 Resolve a What's Doc the way the cursor does — descendant `Doc` in document
  order, else the `c.Doc` context (see `Waft_src_doc_path` / `find_Doc_from_What`).
   Nested Whats (a What inside
    a What) are their own sub-runs; cohere within a sibling level, don't flatten
     the hierarchy. When in doubt, prefer under-coalescing (show the Doc again)
      over hiding a Doc boundary that's really there.

## Guardrails

- Render-only. No edits to the C tree, the snap, or the encode path.
- Keep all text copyable and truthful — emphasis via styling a real substring,
   never by replacing displayed text with a prettier string.
- Don't touch `DocPoint.svelte`, `e_Lang_shoot_point`, or the `mark`/`LE` seam —
   that's the parallel Point++ task.
- Re-record any affected Story snaps only if the *render* is asserted; the C
   tree shouldn't change, so most snaps should be untouched.
