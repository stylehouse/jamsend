# Cello Universal Scheme 6 — the Woven Membrane

## 0. What to get on with next

This doc is design-only. No code exists yet. Read it to understand the visual philosophy before
 touching anything. The arc is stated in §1; the first buildable slice is §8.

Open questions to resolve with the owner before building:
- Confirm the "woven thread" stripe direction convention (§3) — vertical stripes or horizontal?
- Does the `.c` count badge (§4) live on the rim or on a tiny tab below the cell?
- Should the twist indicator (§5) be a visible seam line or a corner notch?

---

## 1. The arc — one sentence

**The Woven Membrane renders the C tree as a living textile: every particle is a CELL of woven
 fibres, the warp threads are `sc` key-value pairs, the weft threads are tree depth, and every
  twist or fold in that weave announces itself as an illusion rather than hiding it.**

The metaphor earns its keep because it matches the invariants exactly:
- The fibre bundle persists: a particle's full `sc` is encoded IN the stripe pattern — you can
   read the k:v pairs off the wall of the cell as if reading a woven label.
- Unity: every cell is made of the same thread, whether it is a `%Radio` or a `%req`. The
   single substrate looks single.
- Twisted for effect = warp distortion: a collapsed subtree shows a tightened weave that is
   visually unmistakable as compressed, not absent.
- Decodable: density, colour, and stripe count carry meaning; a trained eye reads structure from
   the texture of the cloth, not from mousing-over tooltips.

---

## 2. The visual language — what the eye sees

### 2a. One particle = one woven cell

Each particle occupies a `cello_blob`-clipped rectangle — the same wobbly-wall clip from
 `cello_blob.ts`, same per-mainkey Matstyle colour from `The/Styles`. The blob wall IS the
  cell boundary. The interior is not a flat fill; it is a **stripe field**.

```
 ┌──────────────────────────────────────────┐
 │  %Radio                                  │  ← mainkey on the top RIM (Cello convention)
 │  ║║║║║║║ │ ░░░░░░░░ │ ░░░░░░░░ │ ░░░░  │
 │  ║║║║║║║ │ ░░░░░░░░ │ ░░░░░░░░ │ ░░░░  │  ← vertical WARP stripes, one per sc key
 │  ║║║║║║║ │ ░░░░░░░░ │ ░░░░░░░░ │ ░░░░  │    width ∝ value string length (the DATA density)
 │  vol:0.8  │  state   │  title   │ +more │  ← key labels sit in the gutter between stripes
 └──────────────────────────────────────────┘
  ↑                                        ↑
  left rim: tree depth (weft accent lines)  right edge: .c count tab (see §4)
```

The **warp stripes** run vertically (or horizontally — owner's call; vertical reads as columns):
- One stripe per `sc` key. Order: mainkey first (widest, dominant colour), then remaining keys.
- Stripe width is proportional to `String(value).length`, floor of 8px, ceil of 60px.
- The mainkey stripe is the cell's jewel colour (Matstyle). Non-mainkey stripes are 30% lighter
   variants, distinguished by a subtle tonal shift between adjacent stripes.
- A snapped boolean (`{k:1}`, key-is-the-fact) renders as a NARROW stripe — 4px — in the
   mainkey hue, almost a hairline. Its label is the key alone, no value. This is visually
    meaningful: a boolean is a thin fact.
- Stripe VALUE is printed as a small label in the inter-stripe gutter (2px gap between stripes),
   rotated 90° for vertical stripes, in 8px monospace. Long values truncate to 16 chars + `…`.

The **weft accent** is NOT drawn inside the cell — it runs at the cell's LEFT RIM as a stack of
 coloured hairlines, one per level of tree depth. Depth 0 = one hairline; depth 3 = four
  hairlines. These lines are the "horizontal threads" that bind the tree together visually —
   the weft of the cloth, woven through every blob on the canvas. They share a single thread
    colour (a neutral warm-white at 50% opacity) so the depth count reads without fighting the
     cell's own colour.

### 2b. The mainkey badge — the particle's type, prominently

The mainkey is PRINTED on the top rim of the cell in the same way Cello already plans it:
large, the cell's dominant colour, weight 700. It sits ABOVE the warp stripes like a label
sewn onto the cloth. This is what a cell IS, said first, before you read the fabric.

```
  Radio                                ← mainkey badge, top rim, gold if Radio
  ┌──────────────────────────────────┐
  │ ║  ║  ║  │  ░  │  ░░  │  ░░░░  │  ← warp stripes: sc keys as columns
  │ ║  ║  ║  │     │      │        │
  │ vol│  st │ tit │ from │  +3   │  ← key abbreviations in inter-stripe gutters
  └──────────────────────────────────┘
```

### 2c. Children = nested cells inside the parent's blob

When the tree is expanded (open = true), child particles are rendered as SMALLER blob cells
 INSIDE the parent blob, arranged as a horizontal row below the stripe field. The parent's
  warp stripes occupy the UPPER half of the cell; the children occupy the LOWER half, like a
   pocket woven INTO the cloth.

```
  Radio
  ┌────────────────────────────────────┐
  │ ║  ║  │  ░░  │  ░░░░  │  ░░░░░░  │  ← parent sc stripes, upper zone
  ├────────────────────────────────────┤  ← fold line (the "weave fold")
  │  [Spin]  [Spin]  [Spin]  [+12…]  │  ← children, each a miniature blob
  └────────────────────────────────────┘
```

Children NEVER overflow the parent blob visually — they are clipped to it. The fold line
 (a hairline across the full width, same neutral-warm-white as the weft accent) is the seam
  that signals "the cloth folded here; there is more below." Child blobs are tiny (32–40px
   height), showing only their mainkey badge, no stripes (too small). They stack horizontally;
    overflow truncates to a `+N more` pill.

### 2d. Faceless vs. Designed — the same cloth, different resolution

- **Designed Face** (RadioFace, DoorFace, etc.): the blob molds the Face component inside it
   normally, exactly as Cello already plans. The warp stripes are SUPPRESSED — the Face IS the
    cell. Only the mainkey rim badge and the .c count tab remain visible at the blob boundary.
    This is a cell of the same cloth, but the face has resolved its own reading — the weave
     serves the Face without competing with it.
- **Faceless (Tree mode)**: the full stripe field renders in the blob. The cell IS the cloth,
   unresolved — pure `sc` structure, legible as textile, with children folded below. This is
    TreeFace's natural home, now given visual authority rather than monospace apology.

The distinction is VISUAL: a Designed cell looks finished, smooth. A Faceless cell is visibly
 woven — textured, striped, the data showing through. A trained eye immediately knows which
  resolution the cell is at. This is not a hierarchy; it is two reading modes for the same clay.

---

## 3. The whole-field view — the canvas as cloth

At the overview scale (many particles visible), the Woven Membrane looks like a PATCHWORK:
 each blob is a patch of cloth with its own stripe direction and colour, nestled organically
  against its neighbours (Cello template: one main + orbital satellites), their wobbly walls
   touching but not merging.

The **weft hairlines** (depth indicators on left rims) form a VERTICAL RHYTHM across the whole
 canvas — a column of hairlines on the left edge of every cell, aligned to a shared depth
  baseline. From the overview, this reads as a faint left-to-right depth gradient: shallow
   cells have thin left rims, deep cells have thick ones. You can see the tree structure in
    the rhythm of rim widths even before reading any text.

The SATELLITE cells (Door, Player, contextual) are smaller blobs. Their stripe fields are the
 same system, but the stripe count matches their actual `sc` key count — a `%Door` with 4 sc
  keys has 4 stripes, visually compact compared to a `%Radio` with 8. Size difference is
   honest: a satellite is smaller because it IS simpler, not because it was arbitrarily shrunk.

---

## 4. The `.c` count tab — the runtime-below signal

`.c` holds runtime refs that are never snapped. The Woven Membrane does NOT draw them (same
 discipline as TreeFace: `.c` is counted, never followed). But it makes the count VISIBLE as a
  small tab on the cell's right edge — outside the blob boundary, below the rim, a tiny
   rounded pill reading `c:N` in the neutral grey of a footnote.

```
                                                    ┌──┐
                          [Radio blob body]         │c:4│  ← .c tab, right edge, outside the clip
                                                    └──┘
```

This tab is the **honesty channel for the runtime layer**: the full sc structure is in the
 stripes; the c count tells you there is more below, how much, and that you cannot read it
  here (it is a runtime ref — it exists but does not snap). The tab asks nothing of you; it
   simply refuses to pretend `.c` is zero.

When `.c` is zero (most cells), the tab is absent. No clutter.

---

## 5. The "twisted for effect" honesty indicator — the warp distortion mark

When the renderer has bent true structure for visual effect, it SAYS SO with a **warp
 distortion mark**: a visible fold crease on the affected edge of the blob.

Concretely:

- **Collapsed subtree** (children hidden): the fold line (§2c) is DOUBLED — two hairlines
   instead of one — and a small downward chevron `⌄` sits at its right end. This says: "the
    cloth is folded here; children are real and present but folded away." One key press unfolds.
- **Depth-capped node** (tree walk hit the cap): the fold line turns DASHED, and the `+N more`
   pill is red-tinted. Dashed = the cut was imposed, not chosen. Red tint = something is not
    being shown that EXISTS.
- **Re-parented / moved cell** (a cell placed in a visual location that doesn't match its tree
   position — e.g., a child shown as a satellite for layout reasons): a SEAM LINE on the blob's
    left rim, a single contrasting-colour hairline crossing the weft hairlines, with a small
     arrow pointing toward the true parent. The seam says: "this cloth is cut from elsewhere."

No distortion mark = the visual structure IS the tree structure, one-to-one. The marks are NOT
 decorative. They are load-bearing honesty — every illusion announces itself.

---

## 6. The reveal path — overview to one particle's full bundle

A trained eye reads the canvas at three altitudes:

**Altitude 1 — Patchwork overview**
The canvas is blobs. Mainkey badges name the types. Weft hairlines on left rims show depth
 rhythm. Stripe density (narrow stripes = boolean-heavy; wide stripes = value-heavy) signals
  complexity at a glance. Matstyle colours name the community (gold = Radio, purple = Door,
   etc.). Distortion marks flag illusions without mousing.

**Altitude 2 — Single cell, fabric reading**
Hover or tap a blob. The blob gently expands (CSS transition, no physics). The stripe field
 sharpens — key labels appear in the gutters, value text becomes readable. The mainkey badge
  grows. The `.c` tab shows its count. The fold line appears if children are present, with the
   child mini-blobs visible below. This is the full `sc` bundle, visually resolved.

**Altitude 3 — Deep read / tree walk**
Tap the fold line to unfold children. Each child expands into its own stripe field, recursively.
 The parent's stripe field compresses into its upper half (the pocket-in-cloth model). The weft
  hairlines grow — each unfolded level adds a hairline to the left rim of every descendant cell.
   The whole subtree reads as a wider piece of cloth, with more weft threads, more depth.

To exit: tap the mainkey badge of any ancestor to fold back up. The transition is a CSS
 clip-path morph (blob shrinks back, stripes compress, child blobs vanish into the fold line).
  One transition. No settle physics.

---

## 7. Integration with the render seam

This scheme reuses every existing seam:

- **`cello_blob(seed, opts)`** — the clip-path, unchanged. The blob IS the cell boundary.
- **Matstyle** — per-mainkey jewel colour, drives the dominant stripe and the rim badge.
- **GLASS_KINDS / FACE_MAINKEYS** — face resolution unchanged. A Designed cell mounts its Face
   inside the blob exactly as Cello plans. The Woven stripes are simply suppressed when a Face
    is present.
- **`uis.oai({ UI: 'Cello' }, { component: Cellui })`** — registration unchanged.
- **`<Face n={source} H={H} />`** inside a `<svelte:boundary>` — unchanged.
- **TreeFace** — remains the fallback for any faceless cell, but in scheme 6 it is re-styled:
   the TreeFace's monospace rows are REPLACED by the Woven stripe field. TreeFace becomes a
    Woven cell. The recursive walk is the same; the visual language is the new one.

New primitive needed: **`warp_stripes(sc)`** — a pure function taking a particle's `sc` map,
 returning an array of `{ key, value, width_px, is_boolean, colour }` descriptors that the
  Svelte template renders as stripe `<div>`s. This is the only new mechanical piece. It has no
   DOM dependency and is trivially testable.

---

## 8. The first buildable slice

**One blob, fully woven, no children, no Face.**

Prove the visual idea in isolation before touching Cello's layout or commission wiring:

1. Create a standalone Svelte component `WovenCell.svelte` that accepts `{ n, H }`.
2. Apply `cello_blob(cello_seed(n.pub ?? 'test'))` as the `clip-path` on a bounding div.
3. Call `warp_stripes(n.sc)` to get stripe descriptors.
4. Render each stripe as a flex child `<div>` with `background: <colour>; width: <width_px>px`.
5. Render the key label in the gutter below each stripe (a small `<span>` in the inter-stripe gap).
6. Render the mainkey badge on the top rim.
7. Render the `.c` count tab on the right edge if `Object.keys(n.c).length > 0`.
8. No children, no fold line yet — that is slice 2.

Mount this in `Otro.svelte` against any live particle (a `%Radio` or `%Door` is ideal — 4–8 sc
 keys, a designed Face known, so you can compare the Woven reading against RadioFace in the
  same session).

If the one blob looks legible — mainkey named, stripes readable, c-tab honest — the rest is
 placing more of them. The Cello template (one main + satellites) then hands each slot a
  WovenCell, with Face suppression when GLASS_KINDS resolves a designed face.

---

## ASCII sketches

### Sketch A — single faceless particle, full woven cell

```
  Radio                                         ← mainkey rim badge (gold, wt700)
 ┌──────┬──────┬──────┬──────┬──────┬──────┐
 │ ████ │ ░░░░ │ ░░░░ │ ▒▒▒▒ │▒│ ░░ │ ░░░ │  ← warp stripes (vertical)
 │ ████ │ ░░░░ │ ░░░░ │ ▒▒▒▒ │▒│ ░░ │ ░░░ │    filled = wide value
 │ ████ │ ░░░░ │ ░░░░ │ ▒▒▒▒ │▒│ ░░ │ ░░░ │    thin = boolean key
 └──────┴──────┴──────┴──────┴──────┴──────┘c:3  ← .c count tab (right, outside clip)
  state  vol    title  from  ok src   pub
  ← warp labels in inter-stripe gutters, 8px mono →
  ‖‖‖                                             ← weft hairlines on left rim (depth=3)
```

### Sketch B — woven cell with children folded below

```
  Crate
 ╔══════════════════════════════════════╗
 ║ ████ │ ░░░░░░░░░░ │ ░░░░ │ ░░░░░░░ ║  ← sc stripes, upper half
 ╠══════════════════════════════════════╣⌄  ← fold line + chevron (folded children below)
 ║ [Rec] [Rec] [Rec] [Rec] [Rec] +47  ║  ← miniature child blobs, lower pocket
 ╚══════════════════════════════════════╝
  ‖                                        ← one weft hairline (depth=1)
```

### Sketch C — designed cell (RadioFace mounted, stripes suppressed)

```
  Radio
 ┌──────────────────────────────────────┐
 │                                      │
 │    [RadioFace component here]        │  ← Face fills interior; stripes absent
 │    ⏸  ⏭  ⤓  Oren Ambarchi          │    blob wall + rim badge + .c tab remain
 │                                      │
 └──────────────────────────────────────┘c:4
  ‖‖                                       ← weft hairlines still present (depth=2)
```

### Sketch D — canvas overview (patchwork of blobs)

```
                         ┌──────────┐
                        ⌒│          │  ← Door satellite (purple, compact, 3 stripes)
  ┌──────────────────────┤          │
  │                      │   DOOR   │
  │   RADIO (MAIN)      ⌒│          │  ← Player satellite (gold, compact, 5 stripes)
  │   large blob,        │          │
  │   RadioFace          │  PLAYER  │
  │   c:4               ⌒│          │  ← contextual satellite (teal, 2 stripes)
  └──────────────────────┤  LINK    │
   ‖‖‖                   └──────────┘
                          ‖‖‖‖
```

### Sketch E — warp distortion marks

```
  collapsed subtree:
  ╠══════════════════╣⌄   ← double fold line + chevron = hidden children

  depth-capped:
  ╠╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╣ +7 more  ← dashed fold + red-tinted pill

  re-parented cell:
  ╔══════════════════╗
  ╟──────────────────╢ ↑Radio  ← seam line on left rim + arrow to true parent
  ║                  ║
```

---

## 9. The unifying invariant

**A stripe encodes a fact; a hairline encodes a position; a distortion mark encodes an
 illusion. Nothing encodes silence.**

This is why the Woven Membrane cannot amputate the bundle to look tidy:
- Suppressing a stripe removes a visible column → the cloth is shorter → obvious.
- Collapsing children creates a visible fold line → the illusion announces itself → honest.
- Hiding `.c` entirely was never an option → the count tab is the refusal.
- Making depth invisible was never an option → the hairlines are the refusal.

The ONE substrate looks one because every cell — `%Radio`, `%req`, `%Tree` — is cut from
 the same cloth by the same rules. The Matstyle colour marks the KIND; the stripe count and
  width marks the SHAPE; the weft hairlines mark the POSITION in the tree. Three axes, one
   weave, zero special cases.

---

## 10. What this scheme is NOT

- Not a force-directed graph. The Cello template places cells; this scheme only says what
   each cell LOOKS LIKE.
- Not a second data layer. `warp_stripes(sc)` reads the same `sc` TreeFace reads — no new
   encoding, no new storage, no new particle type.
- Not charm erupting for its own sake. The stripe field is DATA. The wobbly walls are REUSED.
   The only visual addition is the inter-stripe gutter labels and the weft hairlines on left
    rims — both are direct encodings of particle structure, not decorative.
- Not a literal weaving animation. The "cloth" is a metaphor for the data model, not a
   spinning-loom screensaver. The cells are static; the stripes are divs; the weft marks are
    CSS border-left. The metaphor earns the scheme its conceptual unity without imposing a
     rendering cost.
