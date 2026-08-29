# Cello — universal scheme 2: the fibre-band field

## 0. What to get on with next

This doc designs a **third visual language** for the C** substrate — a sibling to `Cello_todo.md`
(main+hovering blobs) and `Cello_tree_scheme_todo.md` (bracket nesting). Those two schemes are
already fully specified. This one is different in kind: it is not a template and not a tree. It is
a **field** — every particle present at once, at its true structural depth, with the fibre bundle
(mainkey + sc k:v + .c count) legible AT EVERY POINT without navigation. The tree scheme requires
you to open nodes; the field shows everything at once, density and arrangement carrying the
structure.

Arc: the C** snap IS a spatial field. The snap encodes depth as indentation, type as mainkey, and
child-count as breadth. The field renderer maps those three quantities directly to spatial channels
— y-axis depth, x-axis breadth, and z-axis visual weight — yielding a picture in which the WHOLE
state is simultaneously present and in which a trained eye can read any particle's full bundle
without clicking.

Candidates for the next move (pick what's ripe):
- Prove the sc-band as a horizontal text strip that reads like a snap line but rides inside a
  cello_blob clip — the atom of the scheme.
- Produce the first field slice: one depth-0 blob spanning the full width, two depth-1 children
  beneath it (narrower blobs, slightly lower y), their sc bands readable as prose.
- Wire as `UI:'CelloField'` alongside Cello and CelloTree in Otro — it shows there with zero
  selection logic, like all the others.

---

## The philosophical brief, translated

The owner's words: *"through every groupology|brackology|layout mesh, the fibre bundle of C**
language must persist in clarity … the sum total of all the language … it will have great unity
when perfected, it will prevent mindless separation … it might be able to indicate where the visual
language or illusion is twisted for effect."*

The three earlier schemes (Voro, Cello, CelloTree) are PROJECTIONS of the C** field:

- Voro projects by MEANING — semantic clumping, voronoi regions, loudness as area.
- Cello projects by FOCUS — one main thing foregrounded, the rest hovering.
- CelloTree projects by CONTAINMENT — brackets, nesting, parent encloses children.

All three sacrifice something to gain their projection. Voro loses structural depth; Cello loses
the unfocused rest; CelloTree loses the simultaneous whole.

**The field scheme sacrifices none of those.** It maps the snap line-for-line into 2D: every
particle is present, every particle's bundle is readable, and the spatial position IS the
structural fact — not a metaphor for it. The penalty is density: when the tree is large, the field
is dense. But density IS information: a dense region means a structurally rich subtree, and that
is exactly the signal a community computer's operator needs.

---

## The visual language

### The basic unit: the fibre band

A single particle renders as a **fibre band**: a horizontal strip whose width is proportional to
its structural breadth (number of siblings at this depth), whose height is fixed (one band-height
`BH`, roughly 28px at depth 0), and which is clipped by a `cello_blob` polygon seeded from the
particle's id — so the edges are organically wobbly but the band is recognisably a horizontal
stripe.

Inside the band, left to right, the FULL bundle:

```
  ┌──────────────────────────────────────────────────────────────────────────────┐ ← cello_blob clip
  │ Radio  ·  src:/music/track.flac  pos:42  vol:0.8  active  ·  c4 ··········  │
  └──────────────────────────────────────────────────────────────────────────────┘
     ↑MK     ↑────────────────── sc k:v ───────────────────────↑  ↑── .c count ──↑
   (bold,    (monospace 9px, TreeFace palette, runs horizontally       (dim, rightmost)
   Matstyle   until it hits the band's right edge; clips if too wide)
   jewel col)
```

This is the snap line, visually. `enLine` produces `Radio  src:/music/track.flac  pos:42  vol:0.8
active` — that is exactly what the sc band shows, in the same reading order. The field IS the snap,
drawn.

The mainkey occupies the leftmost `MK_SLOT` (64px, bold, Matstyle jewel colour — the same gold/
purple palette as Cello/CelloTree). The sc k:v run fills the remaining width monospaced. The `.c`
count (`c4`) sits flush-right, dimmer, separated by the same `·` dot TreeFace uses. A flag-only
key (value = `1`, snapped boolean) renders as just the key name in a faint capsule (TreeFace's
`flagonly` style). An `⚠object-in-sc` is the mint-bug marker, same as TreeFace.

### The field: bands stacked by depth and breadth

The full C** tree becomes a 2D field by two rules:

1. **Y = structural depth.** Depth-0 particles (world roots) sit at the top. Each level of children
   sits one `(BH + GAP)` lower. Depth is the y-axis; the tree grows downward.

2. **X = breadth among siblings.** Siblings at the same depth are laid out LEFT-TO-RIGHT, each
   band's width proportional to its `subtree_weight` — the total number of descendants + 1 — so a
   large subtree takes more horizontal space than a leaf. This makes subtree density VISIBLE: a wide
   band means a rich subtree; a narrow band means a leaf.

```
  CelloField layout (ASCII, not to scale)

  ├─ H:Mundo ──────────────────────────────────────────────────── depth 0, full width ────────┤
  │  H:Mundo  ·  (no sc beyond mainkey)  ·  c8 ···············································  │

  ├─ H:LeafFarm ─────────────────────────┤├─ w:Story ──────────────┤├─ w:Supervisor ─────────┤  depth 1
  │  H:LeafFarm  ·  active  ·  c3 ·····  ││  w:Story  ·  c12 ····  ││  w:Supervisor  ·  c2   │

  ├─ w:plate ──────────┤├─ A:drum ──┤├─ │├─ The ─────┤├─ This ─┤  ···                          depth 2
  │  w:plate  round:21 ││  A:drum   │    │  The  c48  ││  This  │
  │  self:1   c1 ···   ││  crew:α   │    │            ││  c11   │

  ├─ req:fetch ─┤   ···             ├─ Steps─┤├─Styles┤ ···                                    depth 3
  │  req:fetch  │                   │  c30   ││  c8   │
  │  ok:1  c0   │
```

The horizontal bands at the same depth are flush: they tile the full field width with no gaps
(gap is inside the blob clips as breathing room within each band's box). The wobbly clip-paths
mean the tiles LOOK gapped — the organic edges don't meet cleanly — but structurally they are
a partition of the width. That reading (structurally contiguous, visually hand-drawn) is the charm.

### Matstyle colour fills

Each band's background is the Matstyle jewel for its mainkey, at 18% opacity — the same guard
Vytui:1284 uses. This means:
- `H:*` bands are one hue (housing grey/blue),
- `w:*` worlds another (world amber),
- `req:*` a third (req dim green),
- `Radio` gold, `Door` purple, etc.

The depth-stacking means a parent's hue UNDERLIES its children visually — the parent band is
wider, the children sit below it and slightly overlap its bottom edge (via a negative margin of
`BH * 0.15`). This overlap makes the containment feel physical: the children emerge from the
parent rather than sitting on a separate shelf.

The `.c` count strip at the right of each band is coloured dim (40% of the Matstyle jewel),
making it readable as "below the waterline" — structurally present but visually recessive, the
same hierarchy as `c` vs `sc` in the data model itself.

---

## Where designed Faces mount vs. TreeFace raw-C

In the field scheme, Faces work differently from CelloTree (where they mount in the blob fill
area). Here a Face does not REPLACE the fibre band — it HANGS BELOW it, as an expanded organ.

A particle whose mainkey is in `FACE_MAINKEYS` gets a **face organ** attached below its band:

```
  ├─ Radio ───────────────────────────────────────────────────────────── depth N
  │  Radio  ·  src:/music/track.flac  pos:42  vol:0.8  active  ·  c4  │  ← fibre band (always)
  │  ┌──────────────────────────────────────────────────────────────┐  │
  │  │           [RadioFace — album art, transport, pill row]       │  │  ← face organ (below)
  │  └──────────────────────────────────────────────────────────────┘  │
```

The face organ clips with the SAME `cello_blob(seed)` polygon as its band (so they look kin), but
its height is variable and it overflows the grid — it floats in front of the children beneath it,
with a subtle drop shadow separating the layers. Children of a Face-bearing particle are drawn
BELOW the face organ's bottom edge, not below the band.

A particle without a Face just shows the fibre band. The children start below it directly.

This means:
- The fibre bundle (mainkey + sc + .c) is ALWAYS present — even for a designed Face, the band
  comes first and is never hidden.
- The designed Face is additive, not substitutive. The sc band is not collapsed by default (no
  expand/collapse state here — the field IS the state).
- A raw-C particle (no Face in FACE_MAINKEYS) reads identically: one band, children below.

The "faceless face" convention of TreeFace is already satisfied by the band itself — the band IS
the TreeFace content (mainkey + sc rows + .c count), just laid horizontally rather than vertically.
No separate TreeFace mount is needed in the field scheme.

---

## The honesty channel

### Principle

The field scheme has one invariant it must never break: **every band you see corresponds to
exactly one particle at exactly its structural depth and position.** The honest channel is the set
of visible marks the renderer places whenever it has bent that invariant.

### 1. Subtree weight capping (the most common bend)

When a particle has more than `kid_cap` (default 12) children, the renderer shows the first 12
children as bands and replaces the rest with a single **overflow band**:

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ ▸ … 8 more  (siblings omitted; structural position held)                │
  └─────────────────────────────────────────────────────────────────────────┘
```

The overflow band:
- Has a **DASHED blob stroke** (vs solid for a real band) — dashed means "this boundary is a
  display artifact, not a structural one." Same signal as CelloTree's collapsed blob stroke.
- Has no Matstyle fill (neutral grey background) — it carries no mainkey colour because it is not
  one mainkey.
- Has its text in the `.c` dim colour — it is below the waterline of the real picture.

### 2. Depth cap (the structural floor)

At `depth_cap` (default 6), bands continue to be rendered as bands, but their child area is
replaced by a single **depth floor strip** — a horizontal line the full width of the parent band,
drawn as a dot-dash (`─ · ─ · ─`) in the `.c` dim colour, with the text `↓ N deeper` riding it:

```
  ──────·──────·──────·──────·──────·──────·──────·── ↓ 14 deeper
```

The dotted line reads as "the field continues below the visible surface" — it is geometrically
honest (it occupies the position where the next band would go) and visually recessive (it does not
look like a band). The dashes are the texture of something that exists but is not drawn. Clicking
it reveals the next depth level.

### 3. .c refs followed (diagnostic mode)

The `.c` count strip (`c4 ···`) on each band is interactive in diagnostic mode. Tapping it
**opens a `.c` panel** that lists each runtime ref key and, where it's a particle, shows a
**tether line** from the parent band's right edge to the ref's band elsewhere in the field
(or, if the ref is outside the scanned world, a floating band at the field margin).

Tethered-ref bands have:
- **Orange half-tone fill** (exactly as specified in CelloTree §honesty channel §3).
- A `→ .c:<key>` prefix in the MK_SLOT instead of the real mainkey.
- A **bezier tether line** connecting back to the originating band's `.c` strip.

These ref bands are OUTSIDE the structural grid — they float at the field margin, connected only
by the bezier. They are not in the grid because they are not structural children. This is the
most important distortion mark in the whole scheme: anything orange-halftone was reached via a
runtime ref that enWaft would never serialise.

### 4. Face organ overlap (the smallest bend)

When a face organ hangs below a band and overlaps the children beneath it, those children's bands
slide down by the face organ's height — a PUSH rather than an OVERLAP. The pushed children each
carry a **rim hairline** at their top edge in the parent's Matstyle colour, reading as "this band
was pushed downward; its structural y-position is above where it sits." One pixel, one colour —
the lightest possible honesty mark.

---

## The reveal path: overview to one particle's full bundle

The field is a complete picture at maximum zoom-out. Reading it at that scale, the eye sees:
- **Hue bands** (horizontal regions of colour) = the mainkey taxonomy at each depth.
- **Width variation** within a depth band = relative subtree weight.
- **Text density** = sc richness (a particle with many scalars has a longer sc band; it reads
  as visually heavier even though the band height is fixed).

Zooming in (or: clicking a band to focus it) reveals:
- The mainkey label clearly.
- The sc k:v pairs as a readable prose strip.
- The `.c` count.
- The face organ below (if any).
- The full width band of each child.

No navigation is required to see any particle's full bundle — it is always there, just smaller
at full-field zoom. The field is a **zoomable prose document** whose columns are subtree breadth
and whose rows are structural depth.

---

## Field-level unity: preventing mindless separation

The field scheme makes one structural claim visible that no other scheme does: **everything is made
of the same clay.** At maximum zoom-out, the entire running machine reads as one continuous
horizontal-banded surface — Radio and req:fetch and H:LeafFarm and w:Story all show the same
band geometry, the same font, the same `.c` strip placement. The only variation is hue (mainkey
type) and width (subtree weight). There is no visual hierarchy EXCEPT depth-y and breadth-x. A
designer cannot accidentally treat a `req:fetch` as a different kind of thing than a `Radio` when
both are the same band shape.

This is "prevent mindless separation" made architectural: the field refuses to give any mainkey a
special layout that would isolate it from the rest of the matter.

The face organ (the additive expansion below a Face-bearing band) is the only exception — and it
announces itself as an addition, not a replacement. The band is always there first.

---

## How it fits in the render seam

### Registration

`Cello_field.svelte` (logic ghost) + `Cellfieldui.svelte` (the view), parallel to Cello/Cello_tree.

In `Cello_field_plan(w)`:
```
let uis = this.oai_enroll(this, { watched: 'UIs' })
uis.oai({ UI: 'CelloField' }, { component: Cellfieldui })
```

Props: `let { H } = $props()` — the commissioning House. Nothing else.

### Face mount

Same seam as Cello and CelloTree:
```js
const mk   = Object.keys(row.sc)[0]
const kind = row.sc.face || FACE_MAINKEYS[mk]
const Face = GLASS_KINDS[kind]
const source = row.c.source_n ?? row
```
Inside each face-organ div: `{#if Face}<svelte:boundary><Face n={source} H={H} /></svelte:boundary>{/if}`.

The face organ has a fixed slot height; faces are clipped to it. `<svelte:boundary>` keeps a thrown
face from white-screening the field (Vytui:4106 pattern, verbatim).

### The field scan

The scan walks the commissioned world's C tree (same `client_w` the Cello scheme uses), depth-first,
collecting `{ particle, depth, sibling_index, sibling_count, subtree_weight }` rows. `subtree_weight`
is a single pre-pass: `weight(p) = 1 + sum(weight(ch) for ch in p.o({}))`. One linear walk before
the render pass; no layout engine.

Band width = `parent_band_width * (this_weight / sum_sibling_weights)`.
Band y = `depth * (BH + GAP) + face_organ_pushdown_above`.

That is all the layout arithmetic. One pass, no loops, no simulation.

### Charm bits (verbatim from cello_blob.ts)

- **Wall clip**: `cello_blob(seed, { wobble: 0.04, squish: 0.96 })` — less wobble than a satellite
  (0.06) because a band needs its horizontal reading intact; too much wobble and it reads as a blob
  rather than a stripe. The wobble is horizontal-biased (the vertical component is halved by the
  squish) so the band stays recognisably a band.
- **Stroke**: inset SVG `<path>` tracing the same polygon, solid for real bands, dashed for overflow,
  dot-dash for depth-floor. Stroke colour = Matstyle jewel at 55% opacity.
- **Colour fill**: Matstyle jewel at 18% opacity (same Vytui:1284 guard).
- **Label**: mainkey in Matstyle jewel at full saturation, bold, in MK_SLOT (64px, left-aligned).
- **sc strip**: TreeFace's monospace style verbatim — `ui-monospace, SF Mono, Menlo` at 9px,
  `#cdd6e0` text. The sc strip IS the TreeFace band row, laid horizontal instead of indented-vertical.
- **Minimum band height**: `BH = 28px` at depth 0; shrinks by `0.88^depth` — so depth 4 bands are
  `28 * 0.88^4 ≈ 17px` (still readable at 9px font). Bands below 12px height drop to mainkey-only
  (icon-only convention from Cello, applied to bands).

---

## The smallest provable slice

One `%H:LeafFarm` with two `%w:plate` children, each with a few sc keys, one `%req:fetch`
grandchild. Rendered as a field at 500px wide:

```
  ┌────────────────────────────────────────────────────────────────────────────┐  depth 0
  │ H:LeafFarm  ·  active  ·  c3 ················································  │
  └────────────────────────────────────────────────────────────────────────────┘
        │                                         │
  ┌─────────────────────────────────────┐  ┌─────────────────────────────────┐    depth 1
  │ w:plate  ·  self:1  round:21  ·  c1 │  │ w:plate  ·  self:1  round:20 c1 │
  └─────────────────────────────────────┘  └─────────────────────────────────┘
        │
  ┌─────────────────┐                                                               depth 2
  │ req:fetch  ok:1 │
  │  c0             │
  └─────────────────┘
```

That's:
- Three depths of fibre bands.
- Subtree-weight-proportioned widths (left `%w:plate` is wider because it has the req child).
- Matstyle hue per mainkey (housing colour, world colour, req colour).
- sc k:v inline, readable as prose.
- `.c` count strip at the right of each band.
- No navigation required to see the full bundle of any particle.

If the sc strips read as clearly as a TreeFace row but inside a wobbly band, the scheme works.

---

## Where this fits among the three Cello schemes

| Scheme       | Projection     | Sacrifice         | When to use                              |
|--------------|----------------|-------------------|------------------------------------------|
| Cello        | Focus          | The unfocused rest| Live music page — one main thing         |
| CelloTree    | Containment    | The simultaneous  | Drill-down on one subtree                |
| CelloField   | Totality       | Intimacy          | System-wide overview; diagnostic reading |

The three are not competing — they are complementary projections of the same field. "Running
them side by side" (CelloTree's §Where this fits) is the most honest reading: Cello for the
music-page FOCUS, CelloField for the whole-machine STATE, CelloTree for the SUBTREE drill-down.
The same `Radio` particle is a satellite blob in Cello, a nested sub-tree in CelloTree, and a
depth-1 fibre band in CelloField — and the unity of the clay is what makes that triple-reading
trustworthy.

CelloField is the one that earns the owner's claim most directly: *"it will have great unity when
perfected, it will prevent mindless separation."* Because you cannot look at the field and not see
that everything is made of the same clay — the same band shape, the same font, the same `.c` strip
— at every depth, for every mainkey, without exception.

---

## The unifying invariant, stated once

**The snap is the picture.** `enWaft` walks the C tree depth-first and emits one line per particle.
CelloField does the same walk and emits one band per particle, at the same depth and in the same
left-to-right order. The two outputs are isomorphic: every line in the snap corresponds to exactly
one band in the field, at the same position. Reading the snap and reading the field are the same
act; one is prose, the other is geometry.

This invariant makes the honesty channel precise: any band that does NOT correspond to a snap line
(a `.c`-ref tether, an overflow stub, a depth-floor marker) is marked orange/dashed/dotted, because
it would not appear in the snap. Any snap line that does NOT have a visible band (depth-capped,
kid-capped) has a dotted or dashed marker at its expected position, because something real is there.
The field is a lossless projection of the snap, with every loss announced.
