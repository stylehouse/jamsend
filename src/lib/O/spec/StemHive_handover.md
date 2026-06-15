# StemHive / method-map — handover

The "methodmap" work: a stem-clustered, button-hive view of a doc's methods that has
 **replaced** the old minimap region+methods strip, plus the editor-side fold UX that
 goes with it. Written across a long iterative session; this captures the durable shape
 and the open threads so the next session can pick up without re-deriving it.

## Status / where the code is

- `src/lib/O/ui/StemHive.svelte` — **new**, the reusable hive. Committed (clean).
- `src/lib/O/ui/DocMinimap.svelte` — promoted to use the hive; old def-chip strip gone.
   Committed (clean).
- `src/lib/O/Langui.svelte` — fold markers + Ctrl+Q + clean-copy. **Uncommitted** in the
   working tree as of handover (human commits on the host).

## StemHive — what it is

A generic, Lang-agnostic component. Props:
- `items: { id, label }[]` — id is whatever the caller navigates by (we pass the method's
   char offset, `String(mapule.sc.from)`).
- `pointed?: Set<id>` — ids to light amber (working Points). Kept apart from `items` so a
   highlight toggle never re-clusters.
- `styles?: Map<id,string>` — per-button inline style (the minimap's heat box-shadow halo).
- `onpick?: (id) => void` — fired on click of a method (DocMinimap routes to `record_goto`).
- `title?` — optional heading.

### Clustering (the core)
- Tokenise each name on `_` and CamelCase boundaries
   (`/[A-Z]+(?![a-z])|[A-Z][a-z]+|[a-z]+|[0-9]+/g`).
- Anchor each cluster on the **longest shared contiguous token-run (n-gram)** — *bigger
   stem better*: `Idzeugi_advice` beats bare `Idzeugi`. Ties break toward the run more
   names share.
- **Edge-only**: a run only counts if it sits at a name's **start or end**, so the split is
   a clean prefix or suffix, never an awkward interior stem
   (`…trustclaim_Idzeug_number…` won't cluster on its interior `Idzeug`).
- Greedy: pick best run → its members leave → recurse. Clusters sort by earliest member
   (source order preserved). Each name lands in exactly one cluster.
- **Singletons** (nothing shared) are bucketed *in place* (runs of consecutive ones wrap
   compactly), not dragged to the end.

### Layout (per cluster, flexbox)
The stem's horizontal position signals where leaves cling:
- **both sides** (`.hive-both`): prefixes left-leaning in the left column; the stem is
   absolutely anchored to the right column's left edge (`right: calc(100% + 5px)`, the spot
   just left of the right leaves) and dropped low (`bottom: 3px`); right leaves stack. A
   `min-width` left zone (`.hive-leftcol`) pushes the right leaves to a consistent x.
- **left-only** / **right-only**: stem centred beside the single stack (stem ends up on the
   right of left-leaves, or left of right-leaves).
- **bare**: just the stem (a name that IS the stem; clickable).
- Sub-stems that are themselves names link out inside the **stem** text (e.g. `Idzeugi`
   inside `Idzeugi_advice`); leaves render plain text (no leaf-in-leaf), and the linked name
   also stands alone as its own single.

### Styling notes / knobs
- Method text wears the legacy minimap pink `rgba(225,195,245,0.88)`; the stem stays neutral.
- Cell: rounded blue border, `min-width: 184px`, `margin-right: 10px`.
- Pointed (working Point): amber `#ffd86b`, `font-size: 1.2em`.
- Each method button carries `data-mid={id}` — used by the minimap viewport puck (below).
- Tight vertical throughout (`line-height: 1.1`, small gaps).

## DocMinimap — the promotion

The `.lmm-strip` is now: a top-level StemHive (no band), then **per region** a band header
 (chevron-collapse / goto label / fold-in-editor `f`) followed by that region's StemHive.
 The old `.lmm-def-*` chip columns and the separate "second representation" block are gone.

- **Heat**: `heat_style(m, wide=true)` gives the hive a centred halo a couple px wider than
   the button (the strip's own right-gutter streak variant is `wide=false`, untouched).
- **Viewport puck** (`.lmm-vp`): no longer scroll-fraction (which can't line up with the
   non-linear hive). It reads the editor's visible line range (`lineBlockAtHeight`), finds
   the on-screen methods, and spans the puck across their measured DOM rects (via `data-mid`),
   clamped to the scroll window. **Folded-away methods don't count** (skips offsets inside
   `foldedRanges`). Re-measures on editor scroll, strip scroll, resize, and `contentDOM`
   resize (fold/unfold). Hides when no method headers are on screen.
- **Current-region heading zoom**: `current_region_key` tracks the region the viewport top is
   in; that region's `.lmm-label` text enlarges (`transform: scale(1.16)`), Waft-Ting-style.
   Only the heading text scales, not the band/hive.

## Langui — editor fold UX (uncommitted)

- **One fold type**: `placeholderDOM` always renders the `↤Nlines↦` count arrows; the faint
   `⋯` invisible-stub variant is gone.
- **Markers bigger + always shown**: `.cm-fold-marked` `scale(1.6)`, `.cm-refold-handle`
   `scale(2)` at `opacity: 0.85` (was a faint 0.45). Scaled via transform (not font-size) so
   they don't lift the header line height. Both `user-select: none` so the glyphs can't reach
   a copy.
- **Ctrl+Q** (`fold_q`, bound `Ctrl-q` — literal Ctrl so Mac's Cmd-Q quit isn't shadowed):
   toggles the **innermost indent-block** at the cursor (press again unfolds). A tiny
   innermost block (`< FOLD_UP_UNDER = 6` lines) is skipped for its **enclosing** block — but
   it stays a toggle, not a climb. Routes through `fire_fold_toggle`, which marks the range, so
   an opened fold keeps its `↦` handle and folds up again. To fold a region, Ctrl+Q on its
   `//#region` header line.
- **Clean copy** (`copy_clean`, wired via `EditorView.domEventHandlers`): copy/cut writes the
   selection's `sliceDoc` text — folds expand to real code, marker widgets never appear.
   Single-range only; multi-cursor/empty fall back to CM default.

## Open threads / next

- **Copy-over-fold warning**: a `<` hook is left in `copy_clean`. When a warnings surface
   exists, fire a warning on a copy that spans a fold, offering "copy the collapsed form
   instead" (rewrite the clipboard). Deferred — no surface to render into yet.
- **`↦` handle on every region from the start**: currently the open-state handle only shows
   for regions in `markedRegions` (folded at least once). Putting one on every region needs
   the region ranges wired into `refoldHandles` (the minimap has them via Mapulen; the editor
   doesn't).
- **Ctrl+Q targeting**: uses indentation blocks (like `block_lines`/`fire_seek`), not Lang's
   actual region/Mapule ranges. Fine for indent-nested code; wiring the region list in would
   make `//#region` targeting exact.
- **Fold-into-chunks idea** (raised, not started): cluster a method's *internals* and fold
   them into ~3 chunks — sub-method auto-chunking, a peer of the stem clustering but inside a
   body rather than across names.
- **"Scribbles"** (direction, undefined): annotation/marginalia layer over the doc — capture
   when it firms up.
- StemHive layout knobs to tune by eye: `.hive-both` stem `right: calc(100% + 5px)` /
   `bottom: 3px`, `.hive-leftcol` min-width, cell `min-width`, `FOLD_UP_UNDER`.

## Resuming

Open a fresh session and read this doc plus the three files above (StemHive.svelte,
 DocMinimap.svelte, Langui.svelte). The notation conventions are in `O/spec/NOTATION.md`.
 The data the hive feeds on is `dock/%Navicade/%Mapule` (kind=`def`/`region`, `sc.key`,
 `sc.from`) — see DocMinimap's `rebuild()` and `items_of()`.
