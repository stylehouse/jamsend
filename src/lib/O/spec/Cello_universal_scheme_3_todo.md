# Cello Universal Scheme 3 — The Weave

*One substrate. One reading. Every layout is a fold of the same cloth.*

## 0. What to get on with next

This document is a design-only brief for the THIRD independent rendition of the universal
C** data model. Read it before touching any render file. The first slice is the
**fibre strip** (§6) — a single row of particles from any live world, printed as
interlocking tiles showing mainkey, sc pairs, and the c-count in one glance.

Vague candidates for the next move (pick what's ripe):
- Prove the fibre strip in a standalone Svelte component that renders off a single TheC.
- Wire the strip as the "raw-C mode" face behind a `{#if Tree}` toggle inside any Cello cell.
- Design the overlay braid animation that connects a tile's mainkey to its nearest
  named Face (the honesty thread made visible).

The arc: this scheme exists as the **language mode** of Cello — a toggle that lifts the
designed Faces aside and renders the living clay they are made of, with nothing hidden and
no lie uncalled out. When Faces are down, the Weave is what a community sees: its whole
computer, readable as prose, tiled and folded in one field.

---

## 1. The philosophical problem this rendition solves

The existing TreeFace (glass_kinds `Tree`) is already honest and recursive, but it reads
**vertically, one particle tall**: mainkey on a line, k:v pairs on that same line, children
indented below. This is legible prose, but it does not *scale* to a field — the moment the
tree is deep it becomes a scroll, and the scroll looks like a log, not like a community's
shared machine.

Cello_todo's charm: **wobbly-walled blobs, one main cell, satellites nestling the edge**.
That works for the designed Faces (RadioFace, DoorFace, …) but it has no language for the
C data itself — the clay the Faces are made of. The question is: what does the CLAY look
like when you lift the faces off?

The answer this scheme gives: **a woven tile field** — every particle a horizontal strip,
its mainkey the warp, its sc pairs the weft threads interlocking to the right, its c-count
a quiet footnote below the strip, and the whole field folded so depth reads as offset,
not as an indented list. The canvas is one rectangle. The language never leaves it.

---

## 2. The visual language — The Weave

### 2.1 The tile — one particle, one horizontal strip

Every particle is exactly one **tile**: a fixed-height horizontal strip drawn as a
rounded rectangle (the same cello_blob squish, but applied to a wide flat rect rather
than a near-circle). The tile has three zones:

```
┌──────────────────────────────────────────────────────────────────┐
│  ▐MAINKEY▌  key₁:val₁  key₂:val₂  key₃:val₃  …  · c:N  [↕ 3] │
└──────────────────────────────────────────────────────────────────┘
  ←warp→      ←──────────── weft ────────────→  ←c→  ←depth→
```

- **Warp** (left band, ~22% of tile width): the mainkey, bold, Matstyle jewel colour, drawn
  against the particle's own swatch background — the same colour-by-mainkey used by Vyto and
  Cello. This is the TYPE and it is always visible, always at the left edge, always the same
  width for any tile at the same depth. A community trained on this field can scan a column
  to read types.

- **Weft** (centre, ~65% of tile width): sc k:v pairs laid out left-to-right as small pills
  (the same `.tf-kv` style from TreeFace — translucent border, monospace, key in dim blue,
  value in near-white). A pill whose value is `1`/`''` (snapped boolean, key IS the fact)
  shows only the key, flagged green rather than blue, matching TreeFace's `flagonly` class.
  The weft overflows gracefully: a `… N more` pill caps the row, never silently truncates.
  Object-in-sc gets `⚠object-in-sc` in alarm red — the mint bug announced, not hidden.

- **c-count** (right of weft, ~8% of tile width): the number of live keys on `.c`, shown as
  `c:N` in dim grey — the same `c{r.cref}` marker TreeFace already emits. The count is NEVER
  zero-suppressed: if `.c` is empty it shows `c:0`, because the absence is part of the
  bundle. The `c` is the part of the bundle that cannot be snapped; its count is the honest
  acknowledgement that something lives below the prose.

- **Depth index** (right edge, ~5% of tile width): a small number and a depth-bar —
  `[↕ D]` where D is the tree depth of this particle. This is NOT indentation; it is a
  direct stamp. The tile's LEFT EDGE is always flush with the canvas edge; depth reads as
  a number and a tiny bar-fill, not as whitespace offset. The warp shifts colour slightly
  darker with depth (a 4% darken per level, capped at 5 levels) so the eye groups near-
  kin tiles without needing indentation.

### 2.2 The field — how tiles stack

Tiles stack top-to-bottom in DFS order: parent immediately above its first child, the
rest of the children below in order, depth-first, exactly as `enWaft`/`Travel` would emit
them. The field looks like a snap — because it IS the snap, now visual.

Child tiles are NOT indented. They are distinguished by:
1. The depth number (direct read).
2. A thin coloured **thread** along the left edge: a 2px vertical line in the parent's
   Matstyle warp colour, running from the parent tile's bottom edge down to the last
   child's bottom edge, at the left edge of the warp zone. This thread is the
   **groupology mark** — it says "these tiles are children of that tile" without moving
   the tiles anywhere.

Multiple threads stack when nesting is deep. At depth 3, the leftmost thread belongs to
the depth-0 ancestor, then depth-1's thread beside it, then depth-2's. The threads form
a **braid** at the left edge, each in its parent's warp colour.

```
depth-colour braid             tile strip
│                              ┌──────────────────────────────────────┐
│                              │  ▐H:Mundo▌  root:1  · c:4    [↕ 0] │  ← depth 0 tile
│┌── (H:Mundo's thread)        └──────────────────────────────────────┘
││                             ┌──────────────────────────────────────┐
││                             │  ▐w:Story▌  self:1  · c:2   [↕ 1] │  ← depth 1
│││── (w:Story's thread)       └──────────────────────────────────────┘
│││                            ┌──────────────────────────────────────┐
│││                            │  ▐Step▌  n:1  ok:1  · c:0   [↕ 2] │  ← depth 2
│││                            └──────────────────────────────────────┘
│││                            ┌──────────────────────────────────────┐
│││                            │  ▐Snap▌  diff:1  · c:1       [↕ 2] │  ← depth 2 sibling
││                             └──────────────────────────────────────┘
```

The braid makes every tile's ancestry immediately legible without any horizontal offset.
A depth-0 thread is the widest (3px), a depth-5 thread is the narrowest (1px), and each
inherits its parent's Matstyle jewel colour.

### 2.3 The fold — depth cap as a deliberate seam

The canvas has a **fold depth** (default 4). At the fold boundary, instead of continuing
to emit tiles, the renderer emits a single **fold tile** — a special placeholder in muted
grey with italicised text:

```
┌──────────────────────────────────────────────────────────────────┐
│  ↓  N children hidden — tap to unfold  (fold at depth 4)   [↕ 4]│
└──────────────────────────────────────────────────────────────────┘
```

The fold tile is the honesty channel for the depth truncation (§4 below). It **names the
cut** — "N children hidden" rather than silently ending — and it is interactive: tapping
unfolds that subtree locally while the rest of the field stays folded. This is TreeFace's
`… N more` elevated to a first-class visual element.

### 2.4 Sized and windowed

The whole field tiles are fixed-height (22px resting, 28px when hovered — enough for the
weft pills to breathe). The canvas itself is scrollable. On a 450px-tall frame, ~20 tiles
are visible at once — a whole medium world fits in two screens, a large one pages.

A **minimap** rides the canvas right edge: a 12px-wide strip of colour bars, one per tile,
in warp-colour, showing the full depth braid at 1px height per tile. The minimap lets a
trained eye navigate the tree without scrolling — the braid pattern at small scale is still
readable because the Matstyle colours are distinctive. Tap a minimap band to scroll that
tile into view.

---

## 3. Designed Faces vs faceless tiles — where each carries the load

### 3.1 The two modes

The Weave and the Faces are not competitors. They are **two modes of the same field**, and
the toggle between them is the system's honesty channel for "I dressed this particle for
you":

- **Face mode** (the default, Cello's normal view): a particle with a resolved Face
  (`FACE_MAINKEYS[mk]` or `sc.face` worn) renders as a Cello blob cell — the blob shape,
  the Matstyle colour, the mounted Face component (RadioFace, DoorFace, …). This is the
  designed view. It knows what a Radio means and draws that meaning.

- **Weave mode** (raw-C mode, toggled in): any particle, designed or not, renders as a
  tile in the field. The Face is withdrawn; the tile shows the mainkey, sc pairs, c-count,
  depth. This is the honest view. It knows nothing about what a Radio means; it draws the
  clay.

The toggle is a **single gesture** — a long-press or a keyboard shortcut (e.g. `Alt+W`)
anywhere in the glass — that switches the entire field into Weave mode. A second gesture
switches back. The glass does not "go dark" during the switch; the blob cells animate to
tiles and back via a CSS transition (clip-path expands from the blob polygon to a rounded
rect).

### 3.2 The Face layer in the field

When a particle HAS a designed Face, the Weave can render it in **inline-face mode**: the
tile expands to a compact height (48px) and mounts a miniaturised Face — the same `<Face n
H />` component, constrained by a `transform: scale(0.4)` so the Face's own layout shows
through without dominating the tile. The warp label stays visible at the left; the Face
fills the weft zone. This is the "community's computer that can zoom its own parts" —
every designed Face is a fold of the same cloth.

In practice: a `%Radio` tile in inline-face mode shows the RadioFace at 40% scale in its
weft zone — play/pause button and album art, compressed — while the warp still says
`Radio` in gold, and the depth thread connects it to its world. A `%Door` tile shows the
DoorFace compressed in the same way. The two modes (tile and inline-face) are both
valid; the toggle decides which default applies.

### 3.3 TreeFace as the fallback, still honoured

Any particle with no resolved Face (`FACE_MAINKEYS[mk]` absent, no `sc.face`) renders
exclusively as a tile in the field — there is no designed alternative. This is TreeFace's
station, elevated: the faceless node is not a gap in the glass, it is the MOST HONEST
tile, because it carries no dressing at all. In the braid, it is indistinguishable from a
particle with a Face (same strip format, same thread colour, same depth number) — which is
exactly the point: the clay is ONE SUBSTRATE and a faceless particle is not lesser clay.

---

## 4. The honesty channel — where twisting is announced

The brief names this invariant: *"it might be able to indicate where the visual language or
illusion is twisted for effect."* The Weave has three explicit twist markers:

### 4.1 The fold tile (depth cap — §2.3)

When the renderer folds a subtree, a fold tile says so. No silent prefix. The count of
hidden children is exact. This is the **cut twist**: the renderer truncated depth for
readability, and it is saying so.

### 4.2 The face-mode badge

When a particle renders as a blob cell (Face mode, not Weave), a small badge appears at
the tile's bottom-right corner in the minimap strip — a tiny icon that says "dressed":

```
minimap strip (12px wide):
  ████   ← depth 0 tile, warp colour
  ███ ✦  ← depth 1 tile with a Face mounted (✦ = "dressed for effect")
  ██     ← depth 2 tile, faceless
```

The `✦` (or a simpler `●`) marks every particle where the glass imposed a Face. In Weave
mode, all `✦` badges disappear — because the twist is removed, nothing to announce.

### 4.3 The c-count always visible

`.c` is NEVER encoded, NEVER snapped. The c-count on every tile is the explicit declaration
that something lives below the prose — runtime refs, backlinks, the House chain. The
count does not expand or follow into `.c` (that would be an infinite cycle). It only
counts. This is the **submerged twist**: the renderer shows the top (sc) and counts the
bottom (.c), and the count is the honest reminder that the snap is not the whole story.
A `c:0` is a complete tile; a `c:8` is a tile with 8 things the field cannot show.

### 4.4 Object-in-sc alarm

An object value in `.sc` is a mint bug — fatal at encode. The weft renders it as
`⚠object-in-sc` in alarm red, same as TreeFace's existing `show()`. This is the
**malformed clay twist**: the renderer shows the crack, not a sanitised value. A developer
looking at a Weave field sees the bug immediately, at the tile, not buried in a console.

---

## 5. How the render seam works

The Weave slots into the same wiring as every other face in the glass:

### 5.1 Registration

```
// in Cello.svelte or Cello_plan(w):
let uis = this.oai_enroll(this, { watched: 'UIs' })
uis.oai({ UI: 'Cello' }, { component: Cellui })
// Cellui internally imports WeaveFace for the raw-C tile field.
```

The Weave is NOT a separate UI registration — it is a mode of Cellui, toggled by a C
particle on the commissioned world:

```
w:Cello
  CelloMode:1  weave:1   ← weave mode active (sc boolean, 1-or-absent)
```

When `weave:1` is present, Cellui renders the tile field instead of blob cells. When
absent, blob cells render. The req machine reads `w.oa({CelloMode:1, weave:1})` and
provides the mode flag; Cellui's `$derived` re-runs on H.version.

### 5.2 Face mount — same contract as Vytui

In inline-face mode (§3.2), the tile expands and mounts the Face declaratively:

```svelte
{#if Face}
  <svelte:boundary>
    <Face n={source} H={H} />
  </svelte:boundary>
{/if}
```

`source = row.c.source_n ?? row` — exactly the Vytui pattern (Cello_todo §4, step 4).
`Face = GLASS_KINDS[kind]` from `glass_kinds.ts`. The `<svelte:boundary>` keeps one
thrown Face from collapsing the field.

### 5.3 The tile scan — simpler than Vyto's mirror

The Weave does NOT build Vyto-style mirror rows with backlinks. It walks the commissioned
world's tree directly via `Travel`, building a flat array of `{ depth, n, mk, pairs, cref,
folded }` descriptors. The array is `$derived` off `H.version` — any change to the world
bumps the version, the tile list re-derives, Svelte re-renders the `{#each tiles}` block.

`Travel` handles the DFS order. The fold boundary prunes at `fold_depth`. The fold tile is
a special descriptor (`{ kind: 'fold', depth, hidden_count }`) in the same array, rendered
differently in the template.

### 5.4 The charm bits — same source as Cello

The tile's rounded rect clip-path comes from `cello_blob(seed, { points: 8, wobble: 0.02,
squish: 0.15 })` — fewer points and much more squish than the near-circular blob, producing
a wide flat rounded rect with a gentle hand-drawn waver on the long edges. Same function,
same seeded per-id determinism, same percentage contract. The charm persists even in the
raw-C mode: the clay is wobbly clay, not a grid.

The warp zone is filled with the Matstyle jewel colour (guarded, the Vytui:1284 pattern):

```ts
const g = matstyle_ground(mk, stylesC)  // the existing memoised Matstyle lookup
const warpColor = g?.jewel ?? '#7f9fc8'
```

No new palette. The same swatch a `%Radio` wears in the blob becomes the warp band it
wears in the tile.

---

## 6. The smallest provable slice — the fibre strip

Before the full tile field, prove ONE tile in isolation.

**The fibre strip** is a single-particle renderer: given one `TheC` node `n`, it renders
exactly one tile — warp, weft pills, c-count, depth index — as a `<div>` with fixed
height and CSS clip-path. No braid threads (those need a parent to thread from). No fold
tiles (depth 0 has no cap). No minimap. Just one horizontal strip, fully legible.

This proves:
1. The warp/weft/c/depth layout fits in 22px height at the font sizes used.
2. `cello_blob(seed, {squish:0.15})` reads as a tile, not as a blob.
3. The Matstyle colour flows into the warp zone from the existing `matstyle_ground` path.
4. The `… N more` pill truncates the weft without overflow.

**To verify it**, render `<FibreStrip n={anyParticle} H={H} depth={0} />` inside Otro.svelte's
dev route, beside the existing TreeFace. A trained eye should immediately read the mainkey
in gold on the left, the sc pairs as pills in the centre, and the `c:N` in dim grey at the
right — in one horizontal glance, no scrolling.

```
  expected render of a %Radio particle (one tile, 22px tall):
  ┌──────────────────────────────────────────────────────────────────────┐
  │  ▐Radio▌  src:rec42  vol:0.8  playing:  nowOn:1  …2more  · c:5  [↕0]│
  └──────────────────────────────────────────────────────────────────────┘
   gold warp    dim pills           green flag  italic    grey  tiny
```

The whole scheme is a repetition of this one strip, stacked, braided, folded.

---

## 7. The unifying invariant — one cloth

The Weave's deep claim: **every layout is a fold of the same cloth**.

- A snap is a sequence of indented lines. The Weave is a sequence of tiles. Same DFS order,
  same k:v vocabulary, same fabric.
- A blob cell is a fold of the cloth into a near-circle, wearing a Face. The tile is the
  same cloth laid flat. The transition between them (blob → tile) is literally a clip-path
  morph: from the blob polygon to the wide flat rect, in CSS, on one element.
- The braid threads are the fold marks — they show WHERE the cloth is creased (parent →
  children), without moving the tiles themselves.
- The `.c` count is the selvedge — the raw edge that cannot be folded into the snap's prose,
  always present, always labelled.
- The fold tile is the dart — a deliberate pinch where the cloth was pulled in to fit.
  It names itself; it is not a rip.

**Mindless separation** (the brief's language) happens when different parts of the same
machine look like they are made of different stuff. The Weave prevents this: a %Radio, a
%req, a %Step, a %Snap — all tile the same strip format, all wear their mainkey in the
same warp position, all count their `.c` in the same right zone. There is no special
format for the "important" particles and a degraded format for the rest. ONE substrate,
one tile, one braid.

---

## 8. ASCII field sketch — a small world in the Weave

```
depth braid           tile field (22px rows)
                      ┌──────────────────────────────────────────────────────────┐
│                     │ ▐H:Run▌  root:1  crew:musu  · c:4                  [↕0] │
│┌──                  ├──────────────────────────────────────────────────────────┤
││                    │ ▐w:Musu▌  self:1  round:21  · c:2                  [↕1] │
│││──                 ├──────────────────────────────────────────────────────────┤
│││                   │ ▐Mine▌  id:rec42  path:/m/…  · c:0                 [↕2] │  ← dressed ✦
│││──                 ├──────────────────────────────────────────────────────────┤
│││                   │ ▐req▌  ok:1  finished:1  · c:1                     [↕2] │
││                    ├──────────────────────────────────────────────────────────┤
││                    │ ↓ 14 children hidden — tap to unfold (fold at 3)   [↕2] │  ← fold tile
│                     ├──────────────────────────────────────────────────────────┤
│                     │ ▐A:Radio▌  src:rec42  · c:3                        [↕1] │
│┌──                  ├──────────────────────────────────────────────────────────┤
││                    │ ▐Radio▌  vol:0.8  playing:  nowOn:1  · c:5         [↕2] │  ← dressed ✦
││                    ├──────────────────────────────────────────────────────────┤
││                    │ ▐req▌  finished:1  · c:1                           [↕2] │
                      └──────────────────────────────────────────────────────────┘
                      minimap (12px, right edge): colour bands in warp colour, ✦ marks, 1px/tile
```

The braid reads left-to-right as a genealogy. The tiles read left-to-right as a prose
snap. The two readings are independent and reinforce each other: a reader who doesn't know
the braid can follow the depth number; a reader who doesn't know the depth number can
follow the braid threads. The minimap carries the whole picture in thumbnail.

---

## 9. What this scheme does NOT do

- **No physics.** No force layout, no spring settle. Tiles stack in DFS order, period.
  The only movement is the blob↔tile clip-path transition (CSS, one frame).
- **No new palette.** All colours come from Matstyle. The warp band is the existing jewel
  colour; the weft pills are the TreeFace `.tf-kv` palette; the braid threads are the
  parent's warp colour, dimmed to 60%. No new swatches, no new decisions.
- **No charm eruption.** The blob edge on each tile is a very gentle wobble (0.02 fraction
  — barely visible). The point is the tile's legibility, not the tile's personality.
- **No second substrate.** `.c` is counted, not walked, not rendered, not followed. Its
  count is the tile's honest suffix. Following it would be infinite recursion into the House
  chain; a count is the correct abstraction.
- **No silent truncation.** Every fold is named. Every overflow is counted. The cursor
  never sees less than it is told it has.
