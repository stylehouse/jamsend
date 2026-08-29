# Cello Tree — the bracket/groupology rendition of C** matter

## 0. What to get on with next

This doc designs the TREE renderer: a sibling to Cello (main+hovering blobs, see
`Cello_todo.md`) but organised around hierarchy, containment and nesting — "groupology and
brackology" — so the SAME C** substrate that Cello renders as satellites becomes legible as
a living tree. Design only; code lives in a companion Cello_tree component to be built later.

Arc: the C** tree IS the layout. Every particle is a cell. Containment is literal nesting.
The renderer reuses cello_blob clip-paths, Matstyle colour, and the existing Face/GLASS_KINDS
seam — it only changes what "where each cell goes" means: nesting/indentation replaces the
main+satellite template. The result should look like a hand-drawn bracket diagram whose cells
happen to be wobbly blobs — organic containment, not a rigid box tree.

Candidates for the next move (pick what's ripe):
- Produce the first visible bracket slice: one parent blob + two nested child blobs, with sc
  rows reading inside each, `.c` shown as a quieter stratum, and the honesty-channel mark when
  a subtree is collapsed.
- Wire the `UI:'CelloTree'` particle and `Cello_tree.svelte` ghost alongside Cello.
- Get TreeFace absorbed into the blob cells so the "faceless raw-C" look rides inside the charm
  rather than beside it — TreeFace already knows how to render sc/kids/cref; the scheme just
  wraps it in a blob-wall instead of a monospace row.

---

## The philosophical brief, translated to layout decisions

The owner's words: *"through every groupology|brackology|layout mesh, the fibre bundle of
C** language must persist in clarity … try the most elegant possible rendition of that
universal thing … it will have great unity when perfected, it will prevent mindless separation
… it might be able to indicate where the visual language or illusion is twisted for effect."*

Three design laws drawn from that brief:

1. **Fibre-bundle completeness.** At every node in the tree, the full local truth of the
   particle — its mainkey (what it IS), its `sc` k:v scalars (what it holds), and a count of
   its `.c` runtime refs (what's below the waterline) — must be readable. No layout move may
   amputate part of the bundle to look tidy. If a subtree is collapsed, the reader must KNOW it
   is collapsed and know what was omitted.

2. **Unity of clay.** Things made of the same C** substrate should look kin. A Radio and a
   Heist and an error node are the same material; the tree makes that sameness visible
   (identical blob geometry, same font for sc rows, same `.c` count mark) even while Matstyle
   colour tags the mainkey type. This "prevents mindless separation" — a designer can't quietly
   pretend two particles are different kinds of thing when the tree shows they're both blobs on
   the same clay.

3. **Honesty channel.** Where the picture has been SHAPED — a subtree collapsed, a node moved
   to a different display parent, a `.c` ref followed that the snap would omit — the renderer
   marks the distortion explicitly rather than lying silently. This is the "twisted for effect"
   signal: a visible scar or badge on the affected region that says "structure bent here."

---

## The tree layout

### The basic geometry: nesting blobs

Each particle occupies one **blob cell**: a rectangle with a `cello_blob(seed)` clip-path,
seeded from its id so the shape is stable across renders. Child particles are placed INSIDE the
parent's blob cell, indented and smaller, their own wobbly walls visible against the parent's
fill — cells within cells.

```
  Cello Tree — the bracket rendition
  ┌─────────────────────────────────────────────────────┐
  │ ⌒ H:LeafFarm                                       │  ← parent blob, mainkey title on RIM
  │   sc: active·new  ────────────── sc row band        │
  │   c3 ────────────────────────── .c count strip      │
  │   ┌──────────────────────┐  ┌───────────────────┐  │
  │   │ ⌒ w:plate             │  │ ⌒ A:drum          │  │  ← children nest INSIDE parent blob
  │   │   sc: self:1 round:21 │  │   sc: crew:α      │  │
  │   │   c1                  │  │   c0               │  │
  │   │   ┌──────────────┐   │  │                   │  │
  │   │   │ ⌒ req:fetch   │   │  │                   │  │
  │   │   │   sc: ok:1    │   │  │                   │  │
  │   │   │   c0          │   │  │                   │  │
  │   │   └──────────────┘   │  │                   │  │
  │   └──────────────────────┘  └───────────────────┘  │
  └─────────────────────────────────────────────────────┘
```

Children at the same depth are laid out in a HORIZONTAL ROW inside their parent, flowing to a
new row when they don't fit — like a flex-wrap — so the blob shape of the parent naturally
brackets them. This is the "groupology": the group IS the blob, the containment IS the wall.

When a node's children count exceeds `kid_cap` (default 12, inheriting TreeFace's cap), the
overrun is shown as a truncation cell — a small grey blob with `… N more` — rather than a
silent prefix. A silent cut reads as "that's all there is", which TreeFace already calls "the
expensive kind of lie."

### Three visual strata inside each blob cell

```
  ┌───────────────────────────────────────────┐
  │ ⌒ Radio                         Matstyle  │  ← 1. MAINKEY BAND: type label on rim (blob
  │                                  gold fill │       wall, seeded wobble, per-mainkey colour)
  │  ═══════════════════════════════════════  │
  │   src: /music/track.flac                  │  ← 2. SC BAND: k:v scalar rows, readable prose
  │   pos: 42  vol: 0.8  active               │       active = flag-only (key IS the value)
  │  ───────────────────────────────────────  │
  │   c4 ·········· runtime refs / backlinks  │  ← 3. .C STRIP: ref COUNT only, never followed;
  │                                  (dimmer)  │       dimmer hue so it reads below the sc band
  │  ═══════════════════════════════════════  │
  │   ┌─────────────┐  ┌──────────────────┐  │  ← 4. CHILD AREA: nested blob cells in a flex
  │   │ ⌒ Spin       │  │ ⌒ Like           │  │       row; overflow → `… N more` truncation cell
  │   └─────────────┘  └──────────────────┘  │
  └───────────────────────────────────────────┘
```

The dividers (`═══` / `───`) are drawn as HAIRLINES inside the blob, not as separate DOM
elements — they are the seam between strata. The `.c` strip is always present even when
`cref = 0` (it shows `c0` in a muted tone), making the stratum legible as a structural layer
rather than an optional annotation. This is the "fibre-bundle completeness" requirement: `.c`
rides below `.sc` everywhere; the strip makes that architectural fact visible.

### Depth and bracketing

At depth 0 a particle's blob fills the cell area. At depth 1 each child blob is roughly 75%
the parent's width, inset by one blob-border's width on each side. At depth 2, 75% again —
so a three-level tree is clearly nested without the innermost cells becoming illegible. Beyond
`depth_cap` (default 3) the cell's child area is replaced by a single `↓ deeper` truncation
cell; expanding it re-renders that subtree.

The 75%-per-level shrink is deterministic, not physics — it is one multiplication, not a
layout engine. This is the Cello principle applied to groupology: arithmetic, not simulation.

### The faceless default and the designed Face

This scheme exactly parallels Cello's Face/GLASS_KINDS seam:

- A particle whose mainkey is in `FACE_MAINKEYS` (or which carries `sc.face`) gets its
  designed Face mounted INSIDE the mainkey band (in the blob's fill area, above the sc band).
  The designed Face knows what the thing MEANS and draws that meaning — album art, transport
  controls, the Door pill roster. The sc band below it remains visible but is collapsed to a
  thin bar by default ("I have a Face; my raw scalars are available on expand").
- A particle with no designed Face gets the **TreeFace raw-C layout**: mainkey, sc k:v rows,
  .c count — the "faceless face" that knows nothing and draws the particle exactly. TreeFace
  already exists and does this well; here it rides inside a blob cell rather than a monospace
  indent row.

```
  With a designed Face:            Without a designed Face (TreeFace):
  ┌──────────────────────┐         ┌──────────────────────┐
  │ ⌒ Radio              │         │ ⌒ req:fetch           │
  │ ┌──────────────────┐ │         │   ok:1               │
  │ │ [RadioFace here] │ │         │   ttlilt:buf          │
  │ └──────────────────┘ │         │   c2                  │
  │ ▸ sc (collapsed)     │         │   (no children)       │
  │   c4 ···             │         └──────────────────────┘
  └──────────────────────┘
```

This is the "legible as raw k:v" promise kept: even a node with a designed Face exposes its
sc data; even a node with no Face is rendered with the same blob charm.

---

## The honesty channel

The "twisted for effect" mark is the load-bearing design novelty of this scheme. Four
situations where the picture has been shaped, and the exact mark for each:

### 1. Collapsed subtree

When a node's children are collapsed by user action, the child area is replaced by a
**collapsed indicator blob** — a small, visually CRUSHED blob (squish < 0.5, so it reads
as a squashed lozenge rather than a full cell) with the text `▸ N children` and the same
Matstyle colour as the parent. The shape itself signals compression: a blob that looks
squeezed is not the same as a blob that looks empty.

```
  ┌─────────────────────────────────┐
  │ ⌒ H:LeafFarm          (open)   │
  │   ...                           │
  │  ══════════════════════════════ │
  │  ╔═══════════╗                  │
  │  ║ ▸ 7 chldr ║  ← CRUSHED BLOB │  squish=0.35; dashed wall stroke; same Matstyle hue
  │  ╚═══════════╝                  │
  └─────────────────────────────────┘
```

The dashed wall stroke (vs solid for a real cell) is a second signal: "this boundary is a
display artifact, not a structural one."

### 2. Depth truncation

When `depth >= depth_cap` and a node has children, the child area shows a single
**depth-cap cell** — a narrow horizontal blob with `↓ deeper (N)` and a dotted top edge
(the opposite of dashed — dotted means "the tree continues below the visible surface, not
that we chose to hide it"). Expanding re-renders that subtree at an increased depth_cap.

### 3. .c refs followed (future, for diagnostic mode)

The `cref` count strip normally just counts runtime refs. In a diagnostic mode (toggled by
a tab-click on the `.c` strip) the renderer CAN follow specific `.c` refs — e.g.
`source_n`, `up` — and render them as **satellite blobs** floating OUTSIDE the blob's wall
but connected by a thin bezier line. These external-to-wall blobs are marked with a
**orange half-tone fill** (not a solid Matstyle fill) and a label `→ .c:<key>` on the rim,
signalling "this node was reached via a runtime ref that would not appear in a snap."

This is the explicit honesty mark for "visual language twisted for effect": any time the
picture shows a particle that wouldn't be there in a plain enWaft walk, the orange fill
makes the distortion visible.

```
  ┌──────────────────┐
  │ ⌒ Spin           │──────────── (thin bezier)
  │   of: abc123     │                          ╔══════════════╗
  │   c2  ← tapped   │                          ║ → .c:up      ║  ← orange half-tone fill
  └──────────────────┘                          ║ ⌒ A:drum     ║     dotted wall stroke
                                                ╚══════════════╝
```

### 4. Re-parented display node

When the tree renderer chooses to display a particle under a DIFFERENT visual parent than its
actual `o({})` parent in the C tree (for readability — e.g. hoisting a single-child chain,
or flattening a passthrough container), the affected cell gets a **rim chevron badge** `↑`
indicating "this node was lifted from its structural position." The badge appears on the
top-right of the blob rim, in the same dim hue as the `.c` strip.

This is the lightest possible honesty mark: one character, visible without overwhelming the
cell, but present so the picture can't lie silently.

---

## Layout algorithm (arithmetic, not simulation)

The layout is FULLY DETERMINISTIC from the C tree. No forces, no relaxation, no voronoi
seeds. Given a blob cell of width W and height H:

1. The mainkey band takes `min(24px, H * 0.12)` at the top (where the rim label lives).
2. If the particle has a designed Face: the Face area takes `H * 0.45`; the sc band takes
   `min(20px, H * 0.10)` collapsed by default; the `.c` strip takes `12px`; the child area
   takes the rest.
3. If the particle has no Face (TreeFace layout): sc band takes `min(sc_row_count * 13px,
   H * 0.30)`; the `.c` strip takes `12px`; the child area takes the rest.
4. Children are laid in a `flex-wrap` row inside the child area, each child sized to
   `(child_area_width / sqrt(kid_count)) × 0.92` (square-ish; the 0.92 gives breathing room
   between wobbly walls). Minimum cell size is `48px` square (below that: show only the
   mainkey label, no sc rows — the icon-only convention from Cello).
5. Depth shrinks the font and border by `0.85^depth` — so a depth-3 tree stays legible
   without arithmetic overflow.

One pass, no layout loops. This is the point — same Cello principle, different geometry.

---

## Charm register (reuse from Cello, verbatim)

- **Wall shape**: `cello_blob(seed, { wobble: 0.05, squish: 0.97 })` — slightly less wobble
  than a Cello satellite (0.06) because many cells tiling inside a parent needs less chaos.
  Collapsed cells use `{ squish: 0.35 }` to make the crushed shape.
- **Stroke**: inset `box-shadow` or SVG `<path>` tracing the same polygon; same colour as
  the Matstyle jewel but at 60% opacity so the stroke reads as the wall, not the fill.
- **Colour**: Matstyle per-mainkey — `matstyle:<key>` under `The/Styles`. Same palette as
  Cello; same guard as Vytui:1284. No new palette.
- **Label**: mainkey on the top rim, in the Matstyle jewel colour at full saturation. When
  the cell is below the min-size floor (48px), only the mainkey label shows — no sc rows,
  no children, just a named blob.
- **sc band typography**: `ui-monospace, SF Mono, Menlo` at 9px, matching TreeFace's existing
  style — so the sc band inside a blob looks exactly like TreeFace's rows, just framed in
  charm rather than in a flat monospace column.

---

## The smallest provable slice

The simplest thing that exercises the full scheme without building the whole renderer:

One `%H:LeafFarm` particle with two child `%w:plate` particles, each with a few sc keys and
one grandchild `%req:fetch`. Rendered as:

```
  ┌───────────────────────────────────────────────┐
  │ ⌒ H:LeafFarm                      (grey blob) │
  │   active                                       │
  │   c2 ··                                        │
  │  ════════════════════════════════════════════  │
  │  ┌───────────────────────┐  ┌───────────────┐ │
  │  │ ⌒ w:plate  (blue)     │  │ ⌒ w:plate     │ │
  │  │   self:1  round:21    │  │   self:1 r:20 │ │
  │  │   c1 ··               │  │   c1 ··       │ │
  │  │  ═══════════════════  │  └───────────────┘ │
  │  │  ┌─────────────────┐  │                    │
  │  │  │ ⌒ req:fetch     │  │                    │
  │  │  │   ok:1          │  │                    │
  │  │  │   c0            │  │                    │
  │  │  └─────────────────┘  │                    │
  │  └───────────────────────┘                    │
  └───────────────────────────────────────────────┘
```

That's three levels of wobbly blob, sc rows inside each, `.c` strip at the bottom of each sc
area, and the Matstyle colour distinguishing the mainkey types — all from reused primitives.
If that one cell looks right, the rest is just recursion.

---

## Build recipe (how this wires into the existing render seam)

The wiring mirrors Cello's recipe exactly (see `Cello_todo.md §Build recipe`):

1. **Ghost registration**: `Cello_tree.svelte` receives `{ M }`, calls
   `M.eatfunc({ Cello_tree_plan, ... })` in `onMount`; `Cello_tree_plan(w)` stamps
   `uis.oai({ UI: 'CelloTree' }, { component: Celltreeui })`.
2. **View component**: `Celltreeui.svelte` receives `{ H }`. It scans the commissioned client
   world's C tree recursively (same scan as Cello, but instead of placing cells in a
   main+satellite template, it builds nested blob cells).
3. **Face mount**: identical to Cello's — `FACE_MAINKEYS[mk]` → `GLASS_KINDS[kind]` → mount
   inside the blob fill area. For mainkeys NOT in FACE_MAINKEYS, mount `TreeFace` (GLASS_KINDS
   already has `Tree: TreeFace`). This is the "faceless face" seam already built.
4. **Charm bits**: `cello_blob(seed)` from `cello_blob.ts` for each cell's clip-path; Matstyle
   jewel for colour; TreeFace's monospace style for sc rows — zero new primitives.
5. **Dev route first**: `Otro.svelte` renders every `UIs.ob({UI:1})` side by side — CelloTree
   shows there with zero selection work, gated by a `UI:'CelloTree'` particle, same as Cello.

---

## Where this scheme fits in the larger picture

Cello (main+satellites) shows the SOCIAL shape of the running machine: who is present, what
the main thing is, who hovers. CelloTree shows the STRUCTURAL shape: what contains what, how
deep the matter goes, where the fibre bundle is dense or thin.

They are two projections of the same clay. Running them side by side — Cello for the
music-page focus, CelloTree for a diagnostic or story-step drill-down — is where "prevent
mindless separation" becomes visible: the same Radio particle is a satellite blob in Cello and
a nested sub-tree in CelloTree, and the unity of the clay is what makes that double-reading
trustworthy.

The honesty channel (crushed collapse blob, dotted depth-cap cell, orange `.c`-ref satellite,
rim `↑` lift badge) is the one design element that has no equivalent in Cello. It is not charm
— it is a claim about what the picture is doing, made visible in the picture itself.
