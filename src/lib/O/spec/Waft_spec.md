# Waft spec

---

## Goal

Gain decoration powers before gaining fuzzy-matching powers.

The existing system can already route Points from Lies→Lang, resolve them against the
compiled methods index, fold the doc to reveal them via `Lang_apply_openness`, and
scroll the view.  What it cannot do is express *how* a Point should be presented —
enlarged, glowing, surrounded by squished crumbs of non-ancestor regions.  And it has
no time-domain concept: all Points on a Doc are equally present, equally now.

This spec covers:

- `What` — the universal container replacing both the old flat `What` heading and the
  old `Flock` time-slice; the whole Waft tree is now `Waft/What**/Doc/What**/Point`
- The `...` leading-lines squish convention for non-ancestor regions
- `pause | rwnd | +time` transport navigating the What tree
- Ghost-decay: prior-What Points that quietly shrink unless rescued
- Active-What tracking (session state, not persisted) and breadcrumb navigation
- Minimap engagement: concurrently focused Points
- CM decoration infrastructure: what coordinates need updating, what's already there
- Encoder / decoder generalised with Travel + mainkey(), throttled writes

Fuzzy matching, multi-Lang-per-Lies, Cyto animations, and Matstyle wiring onto Points
remain out of scope.  Everything here is achievable in a single-Doc codemirror show.

---

## What — the universal container

`What` replaces both the old section-heading `What` and the old `Flock`.  It is a
named attention-seeker that can contain other `What`s, `Doc`s, and `Point`s in any
combination.  The tree grammar:

```
Waft → (What | Doc)*
What → (What | Doc | Point)*
Doc → (What | Point)*
Point → (nothing — leaf)
```

`What` cannot appear inside `Point`.  `Point` is always a leaf.

Because `What` is polymorph it means different things at different depths:

- At the top of a Waft it is a section heading (`setup`, `language`).
- Nested inside a Doc it is a time-slice — the old `Flock` role.  Sibling `What`s
  under one `Doc` are successive moments; `rwnd` and `+time` step between them.
- Nested inside another `What` it is a subsection, possibly one that doesn't involve
  any particular Doc (a global search site — deferred to a later phase).

### Snap shape

```
Waft:Ghost/LakeNets,Ghost/LakeNets
  What:foundationss
    What:story
      Doc:Ghost/test/Story/Peeroleum.g
      Point,method:LakeNetherland
    What:peer
      Doc:Ghost/test/Peeroleum.g
      Point,method:Peeroleum
  What:transport
    What:first look
      Doc:Ghost/test/Peeroleum.g
      Point,method:transport
      Point,method:PeerJS
```

---

## Point class

A Point can carry `class` in its sc alongside `method` (or `label`):

```
Point:1, method:'e_Dock_open', class:'focus'
Point:1, method:'Lang_plan', class:'ghost'
Point:1, method:'Lang_compile'           — no class; defaults apply
```

A small fixed set of pre-defined classes, statically defined in component CSS — not
runtime-configurable.  Avoiding the Matstyle path keeps the decoration system stable
enough to actually use:

| class     | CM decoration                                | minimap dot |
| --------- | -------------------------------------------- | ----------- |
| (default) | enlarge ×1.4, lavender glow                  | gold        |
| `focus`   | enlarge ×2.0, brighter glow, context bar     | bright gold |
| `caution` | amber glow                                   | amber       |
| `dim`     | no enlarge, faint glow                       | grey        |
| `ghost`   | 18% opacity, 40% height scale                | faint grey  |

`ghost` is stamped automatically on Points that belong to prior-What siblings (the
old-Flock role); it is not usually set by hand.  Clicking a ghost rescues it: `class`
is cleared and it moves into the active What's Doc as a live Point.

---

## The squish convention: `...`

Non-ancestor regions in CM are not fully hidden — they are **squished**: the region
header and its first two lines stay visible, and the CM fold hides the rest.  The fold
widget renders `·····` rather than the default `···`.

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
     .....selected = line + what(was, on_it)   ← target line, enlarged + glowing
```

`Lang_apply_openness` currently folds from `header_line.to` (hiding everything after
the header).  The squish variant folds from `header_line.to + leading_char_count`,
where `leading_char_count` is the character span of the first two lines after the
header.  Two leading lines is a system constant — not configurable per-Point.

The `·····` widget needs a CSS override.  `codeFolding()` in CM accepts a
`placeholderDOM` factory; we supply one that returns
`<span class="cm-squish">·····</span>`.  The host stylesheet gives `.cm-squish` a
muted colour.  ⛑️ (Langui.svelte needs the extension wired in.)

---

## `pause | rwnd | +time` transport

The Waft UI gains a transport bar that operates on the **sibling What list** of the
active What.  It sits at the bottom of the minimap strip:

```
  ◀◀ rwnd   ‖ pause   ＋time
```

### rwnd

Steps the active What backward among its siblings (same parent).  Un-engages Points in
the current What, re-engages those in the prior sibling.  Stops at the first sibling.

Useful for finding "the start of a trail": scan backward through sibling What slices
looking for where a given method first appeared.

### pause

Stops any automatic audience-paced advance.  Not implemented yet — button renders;
advance is manual-only in this phase.

### +time (cell-division)

Creates a new sibling `What` immediately after the current active one, which becomes
the new active:

1.  A new `What:1,label:''` (empty label; user names it) is inserted after the current
    What in the parent's child list.

2.  Points from the current What that are presumed to carry forward (see heuristic
    below) are **copied** into the new What.  The current What is left intact.

3.  Points in the prior What that were not copied receive `class:'ghost'` stamped on
    their sc.  The minimap and CM decoration layer render them at 18% opacity.

4.  Ghost Points not clicked within 10 s (wall-clock timer in Waft.svelte `$state`)
    shrink further and are eventually dropped from the prior What's in-memory state
    (omitted from next snap write).  A clicked ghost is rescued: `class` is cleared and
    it moves into the active What's Doc as a live Point.

### Carry-over heuristic

When +time fires: Points that were **engaged** in the old What are copied into the new
one.  Points added within the last ~30 s (`created_at` in Point sc) are treated as
belonging to the new What — they move rather than copy and are not ghosted.  Everything
else ghosts in the old What.

`created_at` is a session-only sc field — stripped from snap writes (see encoder).

---

## Minimap engagement

Engagement is which Points are currently driving the fold layout and CM decorations.
Session state: `let engaged: Set<string> = $state(new Set())` in DocMinimap.

Multiple Points can be concurrently engaged (soft cap 3; a constant, not a setting).
A small lock glyph on an engaged minimap row prevents MRU eviction.

When engagement changes, DocMinimap fires `e:Lang_point_navigate` for newly engaged
Points and `e:Lang_point_deactivate` for newly disengaged ones.

`Lang_apply_openness` is extended to accept an array of `point_from` offsets.  The
union of their ancestor chains determines which regions stay open; everything else
squishes.  Where Points have conflicting fold preferences the more-open one wins.

---

## Encoder / decoder

is enWaft() etc. uses Lies_waft_save with a per-waft JS throttle() closure on w.c, posting via post_do.

---

## CM decoration infrastructure

### What already exists

- `foldEffect` / `unfoldEffect` dispatch (`Lang_apply_openness` in LangRegions)
- Bookmark `StateField` — CM remaps `from/to` via `RangeSet.map` on every doc change
- `EditorView.scrollIntoView` for navigation

### What needs adding

**Line enlarge + glow**

`Decoration.line({ attributes: { class: 'cm-point-engaged cm-point-focus' } })` adds
a CSS class to the whole line's DOM element.  The class drives enlargement and glow via
static stylesheet rules — no per-Point CSS variable needed since the classes are a
fixed set.

```css
.cm-point-engaged {
    box-shadow: inset 0 0 12px #c4aaee33;
    font-size: 1.4em; line-height: 1.96em;
    transition: font-size 0.15s, line-height 0.15s;
}
.cm-point-focus {
    box-shadow: inset 0 0 20px #c4aaee66;
    font-size: 2em; line-height: 2.8em;
}
.cm-point-ghost {
    opacity: 0.18;
    transform: scaleY(0.4);
    transition: opacity 1s, transform 1s;
}
```

A `StateField<DecorationSet>` (`pointDecorationField`) holds the current engaged-Point
decorations; a `StateEffect` replaces them atomically on each engage/disengage cycle.
Ghost decorations live in a second `StateField` at lower precedence so engaged Points
always paint over ghosts.

**Context bar**

A `Decoration.widget` with `side: -1` at the line's `from` offset renders a narrow
`<div class="cm-point-ctx">` floating above the target line — the Point's `label` or
`method` name as a dim annotation.  `WidgetType` subclass, rendered only when the
`focus` class is in effect.

**Squish fold widget** — see squish section above.

### Coordinates

- **Bookmark from/to**: tracked by CM's `RangeSet.map`; `e_Lang_update_bookmarks`
  pushes positions back to `bm.sc` on each debounce.  Points backed by bookmarks
  (`bm.sc.point_serial`) inherit this for free.
- **Method-name Points**: no stored `from/to` — resolved fresh from the compile index
  at navigation time.  Stale until recompile; flagged as unresolved in the minimap.
- **Ghost decorations**: resolved at render time.  No persistent coordinates.
- **Line glow**: `decos.map(tr.changes)` inside `pointDecorationField.update` remaps
  line-from offsets automatically when lines are inserted or deleted above the target.

No new coordinate-sync infrastructure is needed.

### Selection.process() and Dip

`Selection.process()` (from the `regroup()` note in Lang.svelte) is the planned
Map-building pass — collecting function calls, IO expressions, and type names into a
Dexie-backed index.  `Dip` (from `caving()`) is a depth-and-position address scheme
for dive targets.  Neither has been written.  Neither is needed for the decoration
system: method-name resolution and bookmark coordinates are sufficient.  Both belong to
the later Map-building phase.

---

## What we can show now

With a single Doc and one working codemirror:

- Open a Waft pointing at `Ghost/Lang.svelte`.
- Add a `What:1,label:setup` with Points for `Lang_plan`, `Lang_compile`.
- Add a sibling `What:1,label:routing` with Points for `e_Dock_open`,
  `Lang_doc_from_event`.
- Click `e_Dock_open` in the minimap → CM folds to show only the `e` region, squishing
  everything above to 2-line crumbs, with the target line enlarged and lavender-glowing.
- Press +time → a new sibling What appears; `routing` Points ghost to 18% opacity.
  Add `Lang_apply_openness` and `Lang_build_regions` to the new What.
- Press rwnd → `routing` Points come back; new Points ghost.
- Click a ghost → it rescues into the active What.
- Multi-engage two Points → CM holds both their regions open simultaneously; the
  minimap shows both lit.

Drifting through a doc's architecture with time-layered annotations and fold-based
dramatic framing — no multi-Lang or fuzzy matching required.

---

## Particle layout summary

```
// Persisted (snap) — encoder uses Travel + mainkey(), SESSION_KEYS stripped
w/{Waft:'Ghost/Tour'}
  /{What:1, label}                      — section / time-slice / subsection; unlimited nesting
    /{What:1, label}
      /{Doc:1, path}
        /{Point:1, method, class?}      — leaf; class in static set above
      /{Point:1, method, class?}        — Point in a What (global search site; deferred)
    /{Doc:1, path}
      /{What:1, label}                  — time-slice Whats under a Doc
        /{Point:1, method, class?}
      /{Point:1, method, class?}        — Points directly on Doc

// Not persisted — session state
ave/{active_what:1}
  sc.path: string                       — Waft sc.Waft
  c.what: TheC                          — direct ref to the active What particle

// CM state (not particles)
pointDecorationField                    — StateField<DecorationSet>: engaged Point glows
ghostDecorationField                    — StateField<DecorationSet>: prior-What ghost decorations
setPointDecorationsEffect               — StateEffect<DecorationSet>: full replace
setGhostDecorationsEffect               — StateEffect<DecorationSet>: full replace

// Minimap (Svelte $state — session only)
engaged: Set<string>                    — engaged Point method specs
locked:  Set<string>                    — Points locked against MRU eviction
ghost_timers: Map<string, number>       — setInterval ids for 10 s shrink per ghost spec
```

---

## Open questions

- **Squish fold widget DOM**: `codeFolding({ placeholderDOM })` needs wiring in
  Langui.svelte's extension list.  ⛑️

- **`C.children()` order**: the encoder calls `C.children()`.  Confirm TheC exposes an
  ordered child iterator that preserves insertion order (or use `o({})` with a mainkey
  filter).  ⛑️

- **Ghost cleanup on save**: ghost Points that have decayed (timer elapsed, dropped from
  in-memory state) are omitted from the next snap write because `encode_waft` walks
  live in-memory state.  If the user saves immediately after +time the ghosts are still
  present; they'll decay next session.  Acceptable — but worth noting.  ⛑️

- **Global Points (no Doc ancestor)**: schema accepted, resolution deferred.  Minimap
  renders them as unresolved red dots.

- **Multi-Lang per Lies**: not in scope.  Path is clear (each Doc maps to a Lang
  instance by path) but wiring is not done.
