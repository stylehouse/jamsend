# Waft spec

---

## Goal

Gain decoration powers before gaining fuzzy-matching powers.

The existing system can already route Points from Lies→Lang, resolve them against the
compiled methods index, fold the doc to reveal them via Lang_apply_openness, and scroll
the view.  What it cannot do yet is express *how* a Point should be presented —
enlarged, annotated, surrounded by a glow, with non-ancestor regions folded down to
representative leading lines rather than vanished.  And it has no time-domain concept:
all Points on a Doc are equally present, equally now.

This spec covers:

- Point style schema (Matstyle defaults + fold/decoration behaviour)
- The `...` leading-lines convention for "squished" regions
- The **Flock** — the time-domain container that groups Points into one moment
- `pause | rwnd | +time` transport and how Flocks cell-divide
- Ghost-decay: old Flock Points that quietly shrink unless rescued
- Waft hierarchy elaboration (`Waft/What/Doc/Flock/Point`)
- Minimap engagement: which Points are concurrently focused
- CM decoration infrastructure: what coordinates need tracking, what's already there

Fuzzy matching, multi-Lang-per-Lies, and Cyto-space animations remain out of scope.
Everything here is achievable in a single-Doc codemirror show.

---

## Point style schema

A Point currently carries only `method` (or `Point:serial`, `label`).  It needs an
optional style bag.  Style is opt-in — absent keys fall back to system defaults, which
themselves fall back to the Matstyle for the Point particle type.

```
Point:1, method:'Lang_apply_openness'
  style                              — optional; absent = all defaults
    fold_surround:squish             — 'squish' | 'hide' | 'open' (default: squish)
    fold_leading_lines:2             — how many leading lines to show per squished region
    enlarge:1                        — make the target line larger in CM (default: 1)
    enlarge_factor:1.8               — line height multiplier (default: 1.8)
    glow_color:#c8a0f0               — CSS color; default: lavender (#c4aaee)
    glow_radius:12                   — px blur radius for the glow decoration
    context_text:'applies openness'  — short annotation shown above/beside the line
    context_pos:'above'              — 'above' | 'inline' | 'gutter' (default: above)
    opacity:1.0                      — for ghost-Points from prior Flocks (0.0–1.0)
    scale:1.0                        — for ghost shrinkage (0.0–1.0, applied to height)
```

These are persisted on the `%style` child particle, not on the Point's own sc, so the
Point's sc stays clean for identity (`method`, `label`, serial).  The style child is
omitted from the snap when it carries only defaults — encoder skips it if style equals
the canonical default set.

### Matstyle integration

The `%Point` matstyle gives the gold dot its background-color, shape, and size in the
minimap.  That's the *node* style — what Cyto and the minimap strip see.

The new style bag above is the *decoration* style — what the CM editor sees.  The two
are parallel, not merged.  `glow_color` in the style bag is independent of
`background-color` in the matstyle, though an editor might default `glow_color` to
the matstyle's background-color when absent.

MatstyleEditor will grow engagement rows for: `fold_surround`, `enlarge`,
`glow_color`, `context_text`.  For now, the values are edited directly on the Point's
style child in the Waft UI (Waft.svelte grows a small style sub-form per Point).

---

## The squish convention: `...`

When `fold_surround:squish`, non-ancestor regions are not fully hidden.  Instead each
squished region is represented by `fold_leading_lines` (default: 2) visible lines,
followed by the CM fold hiding the rest.  This is analogous to:

```
//#region e
async e_Lang_editorBegins(A, w, e) {
  .....
//#region doc routing helpers
Lang_doc_from_event(w: TheC, e: TheC): TheC {
  .....
//#region w:Lang
async Lang(A: TheC, w: TheC) {
  .....
  if (thing) {
     .....selected = line + what(was, on_it)   ← the target line, enlarged + glowing
```

The `...` are not literal — they are CM's fold widget for the hidden span, styled as
a muted ellipsis with the squish aesthetic.  The user sees structural breadcrumbs
(region label + first 2 lines) rather than an opaque collapsed blob.

Implementation: `Lang_apply_openness` already dispatches `foldEffect`; the squish
variant keeps `fold_leading_lines` lines visible by folding from `header_line.to +
leading_char_count` instead of from `header_line.to`.  The fold widget CSS needs a new
`.cm-foldPlaceholder.squished` class that renders `·····` instead of `···`.

---

## Flock — the time-domain container

A **Flock** is a set of Points at one moment of the tour.  Currently Points live flat
under `Doc`.  The new layout interposes `Flock`:

```
Waft:'Ghost/Tour'
  Doc:1, path:'Ghost/test/Hello.g'
    Flock:1, active:1              — current moment
      Point:1, method:'Lang_compile'
      Point:1, method:'e_Doc_open'
        style
          glow_color:#c0e0ff
    Flock:0                        — prior moment (ghost)
      Point:1, method:'Lang_plan'
        style
          opacity:0.18
          scale:0.4
      Point:1, method:'Lang_compile'   — also in Flock:1; still here (not forgotten)
        style
          opacity:0.18
          scale:0.4
```

`Flock:N` — N is a monotonically increasing integer.  `active:1` on the highest N only.
Prior Flocks are kept in the snap for the history they represent; their Points are
rendered at reduced opacity and scale in both the minimap strip and the CM decoration
layer.

A Doc with no Flock children is treated as if it has one implicit active Flock
containing all its Points — backward-compatible with the existing snap format.  The
encoder only writes explicit `Flock` particles when more than one exists, or when the
Point carries a non-default style.

### Autovivification

When Lies opens a Waft with the old flat layout (Doc → Points → Point), it leaves it
flat.  The active Flock is autovivified in-memory (not written to snap) at first use —
i.e. the first time the user clicks +time or the UI needs to engage a Point.

---

## `pause | rwnd | +time` transport

The Lies/Waft UI gains a small transport bar when a Doc is engaged:

```
  ◀◀ rwnd   ‖ pause   ＋time  →
```

These are per-Doc (or per-Waft if no Doc is selected), living in Waft.svelte's local
state initially.  They do not need to be persisted — they are session UX.

### pause

Stops the automatic audience-paced advance (if any; see below).  No-op if not running.

### rwnd

Steps backward through the Flock list — moves `active:1` to the previous Flock,
un-selecting all Points in the current one and re-engaging whichever were active in
the prior one.  If on Flock:0 (the oldest), wraps to the newest or stops.

Useful for finding "the start of a trail of thing" — scan backward through Flocks
looking for where a given method first appeared as a Point.

### +time

Cell-divides the current moment:

1.  The existing active Flock's Points are **copied** into a new Flock (N+1) that
    becomes the new active.  The copy carries only Points the system guesses should
    persist (see below).

2.  The old Flock is de-activated (`active:1` cleared) and its Points receive ghost
    style: `opacity:0.18, scale:0.4` stamped onto their `%style` children.

3.  Points in the new Flock start *unselected*.  Normally unselected = invisible, but
    since this is a Flock-replace transition, the ghost rendering of the old Flock acts
    as the visual reminder — the user sees spectral echoes of where the tour was.

4.  The new Flock's Points that were unselected for >10 s (wall clock, tracked in
    Waft.svelte `$state` with `setInterval`) shrink further — `scale` animates from
    0.4 → 0.0, then the ghost Point is dropped from the *prior* Flock's persistent
    state (not written to snap next save).  The user can rescue a ghost by clicking it;
    a rescued ghost moves into the active Flock as a selected Point with full opacity.

### Carry-over heuristic

When +time fires, which Points does the new Flock inherit?

- Any Point that was **selected** in the old Flock is tentatively copied.
- A Point that was **just created** (within ~30 s, tracked by `created_at` on the
  Point's style child) is presumed to belong to the new Flock, not the old one —
  so it moves rather than copies, and is not ghosted.

This is a heuristic, not a contract.  The user corrects it by clicking ghosts (rescue)
or clicking active Points (unselect → they ghost on their own timer).

### Audience pacing

A future `audience_speediness` scalar (0–2, default 1) scales the inter-Flock dwell
time.  `pause` freezes it; `rwnd` is manual.  Not implemented in this phase — the
transport bar renders the buttons but advance is manual-only.

---

## Waft / What / Doc / Flock / Point hierarchy

The current hierarchy is `Waft / Doc / Points / Point`.

`What` is a named section within a Waft — a heading that groups Docs thematically.
It is purely organisational; it has no wormhole path of its own.

```
Waft:'Ghost/Tour'
  What:1, label:'setup'
    Doc:1, path:'Ghost/Housing.svelte.ts'
      Flock:1, active:1
        Point:1, method:'H_plan'
  What:1, label:'language'
    Doc:1, path:'Ghost/Lang.svelte'
      Flock:1, active:1
        Point:1, method:'Lang_compile'
    Doc:1, path:'Ghost/LangCompiling.svelte'
      Flock:1, active:1
        Point:1, method:'_collect_line'
```

`What` nesting is unlimited — `Waft/What/What/What/What/Point` is legal for a deeply
annotated side-note.

A Point under a `What` with no `Doc` ancestor is a **global** Point — it references
something not tied to a specific file.  This must be a global regex search, a method
name across all loaded Docs, or a compiler-generated metadata key.  In this phase,
global Points are rendered as unresolved (warning style in the minimap) and deferred.
The infra accepts the schema; the resolution logic is not written yet.

The snap format gains `What` particles:

```
Waft:Ghost/Tour
  What:1,label:setup
    Doc:1,path:Ghost/Housing.svelte.ts
      Flock:1,active:1
        Point:1,method:H_plan
  What:1,label:language
    Doc:1,path:Ghost/Lang.svelte
      ...
```

Existing Wafts without `What` continue to work — all Docs are treated as top-level.

---

## Minimap engagement

The minimap strip (DocMinimap.svelte) currently shows all Points for the active Doc
as gold dots.  "Engagement" is the state where one or more Points are *focused* —
driving the fold layout and decorations in CM.

### Mutex / multi-engagement

Multiple Points can be concurrently engaged, subject to a soft cap (configurable,
default 3).  The minimap renders engaged Points with a brighter dot and a wider label.
A small lock icon on an engaged Point prevents it from being displaced when a new one
is engaged; unlocked engaged Points follow a most-recently-used eviction.

The engagement set is local state in DocMinimap — `let engaged: Set<string> = $state(new Set())`.
It is not persisted (it is a session view concern, not a Waft concern).

When engagement changes, `DocMinimap` calls `e:Lang_point_navigate` for each newly
engaged Point, and calls `e:Lang_point_deactivate` for each newly disengaged one.
The CM decoration layer then applies the union of all engaged Points' fold layouts,
which may conflict — a Point in region A and a Point in region B will each want
regions folded that the other needs open.  The resolution is: any region that *any*
engaged Point needs open, is open.  All others are squished or hidden per the
most-restrictive Point's `fold_surround` setting.

`Lang_apply_openness` is extended to accept an array of `point_from` offsets and
produces the union of their ancestor chains.

### Minimap transport integration

The transport bar (`pause | rwnd | +time`) is rendered at the bottom of the minimap
strip rather than inline with Waft.svelte, so it is always adjacent to the visual
representation of Points.  It dispatches to Lies via elvists; Lies mutates the Flock
particles and bumps the Waft.

---

## CM decoration infrastructure

### What already exists

- `foldEffect` / `unfoldEffect` dispatch (LangRegions — `Lang_apply_openness`)
- Bookmark decorations (`addBookmarkMark`, `clearAllBookmarks`, `StateField`)
  — `from/to` are remapped automatically by CM's `RangeSet.map` on every doc change
- `EditorView.scrollIntoView` for navigation (DocMinimap — `go_to`)
- Line enlargement: not yet — `Decoration.line` with custom CSS class is the path

### What needs adding

**Line glow + enlarge**

CM supports `Decoration.line({ class: 'cm-point-glow' })` — a line-level decoration
that adds a CSS class to the entire line's DOM element.  This is the right primitive:

```typescript
// in the CM extension set (alongside the bookmark StateField):
const pointDecorationField = StateField.define<DecorationSet>({
    create: () => Decoration.none,
    update: (decos, tr) => {
        // remap on doc change; replace when new point_ranges arrive via effect
        decos = decos.map(tr.changes)
        for (const e of tr.effects) {
            if (e.is(setPointDecorationsEffect)) return e.value
        }
        return decos
    },
    provide: f => EditorView.decorations.from(f),
})

// Per engaged Point: one Decoration.line at the target line's from offset,
// with class 'cm-point-engaged' (glow + enlarge via CSS on the host page).
// The class carries a CSS custom property --cm-glow-color set inline on the element
// via a ViewPlugin that reads the engaged Points' glow_color from Lies's state.
```

`--cm-glow-color` is set per-line via the `attributes` option on `Decoration.line`:

```typescript
Decoration.line({ attributes: { class: 'cm-point-engaged', style: `--cm-glow-color: ${glow_color}` } })
```

CSS:

```css
.cm-point-engaged {
    box-shadow: inset 0 0 var(--cm-point-glow-radius, 12px) var(--cm-glow-color, #c4aaee33);
    font-size: calc(1em * var(--cm-point-enlarge, 1.8));
    line-height: calc(1.4em * var(--cm-point-enlarge, 1.8));
    transition: font-size 0.15s, line-height 0.15s;
}
```

**Context text (above-line widget)**

`Decoration.widget({ widget: new ContextWidget(text), side: -1 })` at the line's
`from` offset produces a floating annotation above the line.  `side: -1` places it
before the line's content in the document order.

`ContextWidget` is a `WidgetType` subclass that renders a `<div class="cm-point-ctx">`.
Width is kept narrow (max 40ch) and it overlays the gutter.

**Ghost Point decorations (prior Flocks)**

Prior Flock Points are rendered at their resolved `from` offset with
`Decoration.line({ attributes: { class: 'cm-point-ghost', style: `opacity: ${opacity}; transform: scaleY(${scale})` } })`.

Ghost decorations are lower priority than active decorations — the `DecorationSet` for
ghosts is provided at a lower precedence than the one for engaged Points.

**Squish fold widget**

The default CM fold widget is overridden in the extension config:

```typescript
foldGutter({ openText: '▾', closedText: '·····' })
// — or override placeholderDOM on codeFolding() extension
```

The `·····` widget gets class `cm-fold-squished` when the fold was applied by
`Lang_apply_openness` in squish mode (tracked by a decoration on the fold's widget
position).

### Coordinates that need updating

The main concern: do we hold any Point-level from/to offsets that need to be
continuously synced as the doc changes?

- **Bookmark from/to**: already tracked by CM's `RangeSet.map` via the bookmark
  `StateField`.  `e_Lang_update_bookmarks` pushes them back to the `bm.sc` on every
  debounce / `saveEffect`.  Points that are backed by bookmarks (`bm.sc.point_serial`
  set) inherit this for free.
- **Points by method name**: these are *resolved at navigation time* from the compiled
  methods index — there are no stored from/to coordinates on the Point particle.
  Resolution is always fresh.  No tracking needed; stale if the doc changes without
  recompile, which the existing `⚠ unresolved` warning already covers.
- **Ghost decorations**: ghost Points are likewise resolved at render time.  No
  persistent coordinates.
- **Line glow decorations**: the `setPointDecorationsEffect` is dispatched once per
  engage/disengage cycle from `e_Lang_point_navigate`.  CM remaps the `DecorationSet`
  internally on every doc change via `decos.map(tr.changes)`.  This is correct for
  line decorations whose anchor is a line `from` offset — edits inside the line do not
  move the line's `from`.  Edits that insert or remove whole lines above the target
  *do* move it, and `RangeSet.map` handles that automatically.

**Conclusion**: no new coordinate-update infrastructure is needed.  The existing
bookmark-sync loop covers positional anchors; method-name resolution covers everything
else.  Ghost state decays by wall-clock timer, not by doc change event.

### Selection.process() and Dip

`Selection.process()` is referenced in the `regroup()` note in Lang.svelte as the
planned Map-building pass: collecting function calls, IO expressions, and type names
into a Dexie-backed index.  It is not yet written.

"Dip" is mentioned in the `caving()` note alongside "Wip" — Dip is presumably an
ordering/depth system analogous to the Wip (position-within-parent) scheme, providing
stable addresses for dive targets so that "opening a hive of realities" doesn't lose
track of where it is.  In the current codebase there is no `Dip` particle or method;
the concept lives in the aspirational comments only.

For the Waft decoration system, neither is needed.  The current `from/to` bookmark
coordinates and method-name resolution are sufficient.  Dip and Selection.process()
belong to the later "Map building" phase.

---

## What we can show now

With a single Doc, one working codemirror, and the above infra in place:

- Open a Waft pointing at `Ghost/Lang.svelte`.
- Add Points for `Lang_plan`, `Lang_compile`, `e_Doc_open`, `_collect_line`.
- Click `e_Doc_open` in the minimap → CM folds to show only the `e` region, squishing
  everything above to 2-line crumbs, with `e_Doc_open` enlarged and lavender-glowing.
- Press +time → the four Points ghost to 18% opacity.  Add two new Points for
  `Lang_apply_openness` and `Lang_build_regions`.
- Press rwnd → ghosts come back at full weight; new Points ghost.
- Click a ghost → it rescues into the current Flock.
- Multi-engage two Points → CM holds both their regions open simultaneously; the
  minimap shows both lit.

This is enough for a compelling show: drifting through a single doc's architecture,
with time-layered annotations and fold-based dramatic framing, without needing
multi-Lang or fuzzy matching.

---

## Particle layout summary

```
w/{Waft:'Ghost/Tour'}                    — loaded Waft container (existing)
  /{What:1, label}                       — optional section heading
    /{Doc:1, path}                       — document entry (existing; What is new parent)
      /{Flock:N, active:1?}             — time-domain container (NEW)
        /{Point:1, method}               — individual point (moved from Points:1)
          /{style}                       — optional decoration params (NEW)
            sc: fold_surround, fold_leading_lines, enlarge, enlarge_factor,
                glow_color, glow_radius, context_text, context_pos,
                opacity, scale, created_at
  /{Doc:1, path}                         — top-level Doc (no What parent; existing)
    /{Flock:N, active:1?}

// Backward compat: Doc without Flock children
  /{Doc:1, path}
    /{Points:1}                          — old layout; still read; autovivified to Flock on first +time
      /{Point:1, method}

// CM extension additions (not particles — CM state)
pointDecorationField                     — DecorationSet of line glows for engaged Points
ghostDecorationField                     — DecorationSet for prior-Flock Points
setPointDecorationsEffect                — StateEffect<DecorationSet>: full replace on engage/disengage
setGhostDecorationsEffect                — StateEffect<DecorationSet>: full replace on Flock change

// Minimap state (Svelte $state — session only, not persisted)
engaged: Set<string>                     — set of engaged Point method specs
locked:  Set<string>                     — Points locked against MRU eviction
ghost_timers: Map<string, number>        — setInterval ids for shrink countdown per ghost spec
```

### What the snap format gains

```
Waft:Ghost/Tour
  What:1,label:setup
    Doc:1,path:Ghost/Lang.svelte
      Flock:1,active:1
        Point:1,method:Lang_compile
          style
            glow_color:#c0e0ff
            context_text:translates stho to TS
        Point:1,method:e_Doc_open
      Flock:0
        Point:1,method:Lang_plan
          style
            opacity:0.18
            scale:0.4
```

The encoder omits `%style` when all its values are defaults.  The decoder autovivifies
a default style in memory when `%style` is absent.  `active:1` on the highest Flock
only.

---

## Open questions

- **Fold widget CSS**: the `cm-fold-squished` class needs the host page's stylesheet.
  Langui.svelte currently mounts CM without a custom theme for fold widgets — this
  needs a `codeFolding({ placeholderText: '·····' })` override or a ViewPlugin that
  patches fold placeholder DOM nodes after render.  ⛑️

- **Flock snap position**: `Flock:N` children of `Doc` need to encode in `encode_wh_lines`.
  Currently only `Points:1 → Point:1` is in the encode path.  The encoder walks
  `Doc → Points → Point`; it needs extending for `Doc → Flock → Point → style`.  ⛑️

- **Ghost cleanup policy**: Points that decay to `scale:0.0` and are dropped from the
  prior Flock's in-memory state — do they get written out of the snap on next save, or
  do they stay until the Waft is explicitly saved?  Last-write-wins on the snap means
  "not written = not there next load" is safe, but only if we always write the full
  Waft.  ⛑️

- **Global Points (no Doc ancestor)**: schema accepted, resolution deferred.  The
  minimap renders them as unresolved red dots.  No search infrastructure yet.

- **Multi-Lang per Lies**: not in scope.  All Points reference the one open Doc in
  the one active Lang.  The path is clear (Waft/What/Doc maps to a Lang instance by
  Doc path) but wiring is not done.
```
