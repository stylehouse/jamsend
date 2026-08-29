# Cello Universal Scheme 1 — the snap IS the rendering

## 0. What to get on with next

This doc is a design for a universal C** renderer that is neither the Cello
main+satellite template (`Cello_todo.md`) nor the nested-blob tree
(`Cello_tree_scheme_todo.md`), though it shares their charm register verbatim.
It is a THIRD projection of the same clay — one where the snap-text (the
language already written by `enWaft`/`enLine`) is the primary visual citizen,
and the blob-wall geometry annotates rather than contains it.

**Arc:** The snap IS the rendering. The scroll of `k:v` peel-lines, indented by
depth, IS the most complete picture of the C** machine that exists — `enWaft`
walks every particle, reads every `sc` key, counts every `.c` ref, and writes a
line per particle. The visual scheme here makes that prose legible by growing blob
brackets out of the indentation structure, painting each mainkey token in its
Matstyle jewel colour, and laying the `.c` strip as a quieter sub-column beside
the sc text. Designed Faces mount inline — replacing the bare text of a particle
line with a live component — so a `%Radio` line becomes a play-transport inside the
flowing score.

Arc in brief: **a living musical score**, where every particle is a line in the
score, every child is an indented sub-staff, every designed Face is a notation
cluster mounted on its line, and the blob-wall is the bracket at the left margin
that says "this system belongs together."

Candidates for the next move (pick what's ripe):
- Produce the first visible slice: one `%H:LeafFarm` section rendered as a scored
  column — the peel-text of its sc, the `.c` count aside, and a bracket blob
  running down the left of its child section.
- Wire the `UI:'CelloScore'` particle and a `CelloScore.svelte` ghost + `Scorui.svelte`
  view, parallel to Cello/Cellui and CelloTree/Celltreeui.
- Prove the Face-mount-inline seam: a `%Radio` peel line with `RadioFace` replacing
  its text content, `sc` rows still visible as a collapsed toggle above/below it.

---

## The philosophical frame

### The snap is the universal language

`enWaft`/`enLine`/`Travel` (Text.svelte) already produce a universal serialisation
of the C** machine: every particle, its mainkey, every sc key:value, the `.c` count
as metadata, all in a human-readable peel format:

```
H:LeafFarm active
  w:plate self:1 round:21
    req:fetch ok:1 ttlilt:buf
  A:drum crew:alpha
```

This IS the "sum total of the language." Every other renderer (Cello templates,
CelloTree nesting, Cyto graph) is a PROJECTION of this language — a rearrangement,
a re-parenting, a selective emphasis. But the snap-text already contains EVERYTHING.
Any rearrangement in another renderer is a distortion (hopefully an honest one).

The Universal Scheme 1 makes this explicit: it starts FROM the snap-text, as prose,
and adds exactly the visual annotation needed to make it a *living* readable artefact
rather than a static dump. This means:

- the prose itself is readable (you can diff a running renderer the way you diff a
  snap file),
- designed Faces mount INLINE where the prose would be (the Face replaces the
  text for that particle — but the text is available as a collapse),
- the blob-bracket at the left margin is the only new visual primitive added.

### The score metaphor, precisely

A musical score has:
- **Staves** — horizontal bands, one per voice/instrument. Here: one band per
  particle at each nesting depth.
- **Brackets** — vertical lines at the left margin connecting staves that belong to
  the same system (orchestral bracket). Here: the blob-wall runs down the left of a
  group of child staves, its organic curve showing they belong to one parent.
- **Notes** — the content on each staff. Here: `k:v` peel-pairs rendered as tokens
  on the line, the mainkey token in Matstyle jewel colour.
- **Dynamics, annotations** — marks that modify interpretation. Here: the honesty
  channel marks (collapsed indicator, followed-.c marker, re-parented lift badge).

What makes this a SCORE rather than just a log: it is LIVE — the token values
update reactively off `H.version`, the brackets redraw when children arrive or
depart, and a designed Face animates on its staff band like a notation cluster that
is itself musical.

---

## The visual language: element by element

### 1. The staff band — one particle, one horizontal band

Each particle in the tree occupies one **staff band** — a horizontal rectangle of
fixed height (24px default, collapsible to 14px at depth > 2, icon-only at < 48px
width). The staff reads left to right:

```
  ┌────────────────────────────────────────────────────────────────────┐
  │ Radio    src:/music/t.flac  pos:42  vol:0.8  active    │ c4 ····  │
  └────────────────────────────────────────────────────────────────────┘
   ▲────────────────────────────────────────────▲           ▲────────▲
   MAINKEY  sc k:v tokens (peel format)          sep        .c column
    (Matstyle jewel colour, bold)
```

- **Mainkey token** — leftmost, in Matstyle jewel colour, bold. This is "what the
  thing IS." Same colour as the blob bracket to its left (they are the same identity).
- **sc k:v tokens** — the scalar children in peel format, each rendered as a small
  pill: `key:value` with a muted border (matching TreeFace's `.tf-kv` style). A
  flag-only key (value = 1) shows as a flag pill with no colon (matching
  `.tf-kv.flagonly`). Overflow tokens wrap to a second line within the band.
- **Separator** — a thin vertical rule at 80% of the staff width, in the same dim
  hue as the `.c` strip. It marks the boundary between sc (left) and .c (right).
- **.c column** — rightmost 20% of the band. Shows `c<N>` in a muted, smaller font
  followed by `···` dots proportional to cref count (max 5 dots; more = one `+`).
  Always present even at cref=0 (`c0` in a nearly-invisible tone), making the
  sub-surface stratum structurally visible whether or not it carries refs.

### 2. The bracket blob — left margin of a child group

When a particle has children, a **bracket blob** runs vertically down the left
margin of the child section — from the first child's top edge to the last child's
bottom edge. This is the groupology element: the bracket IS the parent's wall,
rendered vertically as a left-edge clip.

The bracket is produced by `cello_blob` with `{ squish: 0.15, wobble: 0.04,
points: 10 }` — very low squish so it is tall and thin (a bracket, not a circle);
low wobble because a bracket carries many lines and too much wobble becomes noise.
Its colour is the parent's Matstyle jewel at 40% opacity (present but not
dominating; the children's own colours carry their identity).

```
                 (horizontal staff bands)
  ⌒|  H:LeafFarm  active           │ c3 ···
   |  ════════════════════════════════
   |    w:plate  self:1 round:21   │ c1 ·
   |      req:fetch  ok:1          │ c0
   |    A:drum  crew:alpha         │ c0
  ⌒|  (bracket spans all children)
```

The `⌒` at top and bottom of the bracket are the organic bumps where the clip-path
curves around the group's extent. They are purely Matstyle-coloured and do not
interfere with the text area.

When there are no children the bracket collapses to zero width (the particle is a
leaf; its mainkey band has a small `·` leaf mark, matching TreeFace's `.tf-leaf`).

### 3. Depth indentation — the hierarchy made spatial

Each nesting level is indented by `(depth × 16px) + 8px` from the left edge of the
scroll area (the 8px is left margin inside the bracket). The bracket itself lives in
that `16px` indent column. So at depth 0 the bracket occupies pixels 0–16 of the
staff width; at depth 1 the inner bracket occupies 16–32; and so on.

This is THE layout algorithm: a single CSS `padding-left` expression. No forces, no
layout engine, no coordinates. It is deterministic from the depth counter in the
tree walk — one multiplication.

```
  depth 0:  H:LeafFarm ...
              ← bracket at 0–16px →
  depth 1:    w:plate ...
                ← bracket at 16–32px →
  depth 2:      req:fetch ...   (leaf, no bracket)
```

### 4. Designed Faces mount inline — the notation cluster

A particle whose mainkey is in `FACE_MAINKEYS` (or which wears `sc.face`) has its
designed Face mounted **inside the staff band**, replacing the peel-text with a live
component. The staff grows in height to accommodate the Face (min 80px for an inline
Face). The bracket beside it grows proportionally.

The sc peel-text does NOT disappear — it collapses to a thin `▸ sc` toggle bar
below the Face (expanding shows the raw k:v tokens above the Face's inline area).
The `.c` column remains in its 20% column to the right.

```
  ┌──────────────────────────────────────────────────────┬──────────┐
  │ Radio   ┌──────────────────────────────────────────┐ │ c4 ····  │
  │         │ [RadioFace — album art + transport]       │ │          │
  │         └──────────────────────────────────────────┘ │          │
  │         ▸ sc: src:/music/... pos:42 vol:0.8 active   │          │
  └──────────────────────────────────────────────────────┴──────────┘
```

This is the "designed Face vs TreeFace raw-C" boundary, expressed inline rather than
as two separate rendering paths: every particle gets the same horizontal-band layout;
the Face-mounted ones simply grow taller and collapse their sc text.

A particle without a designed Face gets the TreeFace raw-C layout: its peel-text IS
the content, already readable on the band. Nothing special is needed — the band IS
the TreeFace row, just with a bracket at its left.

### 5. Colour register — same as Cello, verbatim

- **Mainkey token**: Matstyle jewel colour (autovivified per mainkey, same palette
  as Cello/Vytui). The one place per-mainkey hue is applied at full saturation.
- **Bracket blob**: same jewel at 40% opacity.
- **sc tokens**: TreeFace palette — muted blue (`#8fa8c4` key, `#e8eef4` value,
  `rgba(127,159,200,0.12)` pill background). Unity with TreeFace.
- **.c column**: `#6a7280` (TreeFace's `.tf-c` colour). Structurally present but
  dim — reads as "below the waterline."
- **Flag-only pills**: `rgba(127,232,191,0.14)` (TreeFace's `.tf-kv.flagonly`).
  A snapped boolean rides as key-only; the colour signals "the key IS the value."
- **Separator rule**: `rgba(127,159,200,0.22)` — a hairline, not a hard wall.

Font: `ui-monospace, 'SF Mono', Menlo, monospace` at 9px for sc tokens and .c
column, matching TreeFace exactly. Mainkey token at 11px, weight 700 — slightly
larger so the type-identity reads at a glance.

---

## The honesty channel

Where the picture has been SHAPED — a subtree folded, a particle omitted, a `.c`
ref surfaced — the mark appears in the SAME TEXT COLUMN as the deformation. It does
not float off to a legend or a tooltip. This keeps the honesty mark inside the
"score" rather than outside it.

### 1. Collapsed subtree — the fold rune + count

When a user collapses a group's children, the child bracket disappears and the
parent's staff band acquires a **fold rune** `⊞` immediately after its mainkey
token, followed by a dim pill showing the child count: `⊞ 7↓`. The fold rune is
in the Matstyle jewel colour at 60% opacity — same family, diminished. The child
count pill is in the `.c` column colour.

```
  H:LeafFarm  ⊞ 7↓   active            │ c3 ···
```

`⊞` was chosen because it looks like a closed bracket — the thing that the fold
REPLACED. It is not the same as `▸` (which means "expand in a tree"); it means
"there is a folded SYSTEM here, not a leaf." A reader who knows the score knows
immediately that structure was collapsed by choice.

### 2. Depth truncation — the depth-cap dot

When `depth >= depth_cap`, the bracket stops and a single **depth-cap staff** is
drawn below the last visible line — a staff with only a dotted-line top border, no
bracket, and the text `↓ deeper (N particles)` in the muted `.c` column colour.
Clicking it re-renders with an increased `depth_cap`.

The dotted-top border is the honesty mark: "the tree continues below this surface;
the renderer chose a cutoff."

```
  req:fetch  ok:1  ttlilt:buf       │ c0
  ·················· ↓ deeper (3 particles)
```

The dotted line has the same visual grammar as an ellipsis in prose — the rhythm
of the score continues but I'm not writing it out here.

### 3. Followed .c ref — the tilde prefix

In diagnostic mode (toggled by clicking the `.c` column header), the renderer
follows specific `.c` ref keys (`source_n`, `up`, `client_w`, etc.) and renders the
pointed-to particle as an EXTRA staff band immediately below the particle that held
the ref, prefixed with `~.c:<key>→`. The tilde `~` is the honesty mark: it signals
"this line was reached via a runtime ref, not the snap walk — it would NOT appear
in a plain `enWaft` encoding."

```
  Spin  of:abc123              │ c2
  ~.c:up→  A:drum  crew:alpha  │ c0    ← dimmer background, tilde prefix
```

The `~.c:up→` staff is drawn at a LOWER opacity (`background: rgba(0,0,0,0.15)`
overlay) and uses an ORANGE mainkey colour (not the Matstyle jewel) to confirm it
is a surfaced ref, not a structural child. The bracket to its left is dashed rather
than solid.

### 4. Re-parented display node — the lift chevron

If the renderer re-parents a particle (lifts a single-child chain, flattens a
pass-through container) the affected staff gets a `↑` chevron as a prefix on its
mainkey token, in the dim `.c` colour. One character, same line. The bracket that
would have been its structural parent is replaced by a dashed bracket at the same
position.

---

## Overview vs drill-down — the reveal path

The design must work at two scales: the whole-machine overview and the single-particle
bundle. Here is the reveal path:

**Overview (scroll, all depth-0 bands visible):**
```
  H:Mundo      ⊞ 12↓  H:root              │ c1 ·
  H:LeafFarm          active              │ c3 ···
    [bracket]   w:plate  self:1  round:21 │ c1 ·
                  req:fetch  ok:1          │ c0
                A:drum  crew:alpha         │ c0
  A:Vyto       ⊞ 3↓                       │ c5 ·····
  w:Story              running            │ c2 ··
    [bracket]   Step:0  dige:d2ef...      │ c0
                Step:1  dige:847d...      │ c0
                ·················· ↓ deeper (18 particles)
```

At overview: the mainkey tokens (gold/purple/blue/green per type) read as a
colour-coded index of what IS. The `.c` column dots give density at a glance. The
`⊞ N↓` fold runes show where big subtrees are tucked away.

**Drill-down (one particle expanded, Face mounted inline):**
```
  w:Story  running                               │ c2 ··
    [bracket,
     Matstyle   Radio    ┌─────────────────────┐ │ c4 ····
     blue,              │ [RadioFace live]     │ │
     40% opacity]       └─────────────────────┘ │
                         ▸ sc: src:... pos:42... │
    [bracket]   Heist  pub:xyz  ⊞ 2↓            │ c1 ·
                A:Vyto  ⊞ 3↓                    │ c5 ·····
```

At drill-down: a designed Face fills its band, sc rows collapse to a toggle, the
bracket beside it grows to match its height. The prose around it stays readable —
the score continues above and below.

---

## What this scheme adds that the tree scheme does not

`Cello_tree_scheme_todo.md` makes the C** tree legible as **nested containment**:
cells within cells, groupology as literal spatial nesting. This scheme makes it
legible as **scored prose**: a reading order, a rhythm, a line-per-particle that
is already the universal language.

The two are complementary projections:
- CelloTree: spatial containment, good for "what contains what, how deep."
- CelloScore (this scheme): temporal/reading order, good for "what is the machine
  saying right now, line by line."

Both honour the same fibre bundle. In CelloScore the bundle is explicit as text; in
CelloTree it is explicit as nesting. Running CelloScore alongside CelloTree produces
the "prevent mindless separation" effect: the same particle readable two ways, both
in the same visual register (blob brackets, Matstyle, TreeFace sc typography).

---

## Design invariants (the three laws, this scheme's expression)

**1. Fibre-bundle completeness — always three columns, always readable**

The staff band is ALWAYS three columns: mainkey (what it IS), sc tokens (what it
holds), .c count (what's below). No layout move can drop a column to look tidy;
the minimum staff (icon-only, < 48px width) still shows: `Radio │ c4`. The three
columns are the fibre bundle made spatial. They always coexist.

**2. Unity of clay — same staff for all particles**

A `%Radio` and a `%req:fetch` and a `%H:LeafFarm` and a `%see:'sentence'` all get
the same horizontal staff band, the same three-column layout, the same bracket
geometry. The only variation is Matstyle colour on the mainkey token and the presence
of a designed Face. This is the "things made of the same clay look kin" requirement:
the grammar of the staff is universal. A designed Face is not a DIFFERENT kind of
cell — it is a TALLER staff with a notation cluster inside.

**3. Twisted for effect = marks in the score itself**

Every honesty mark lives inside the text column — `⊞ 7↓`, `~.c:up→`, `↑`, `↓
deeper (N)`. No legend, no sidebar, no tooltip-only explanation. A trained reader
decodes the marks from the score the same way a musician reads dynamics from a score:
the mark is part of the language, not a footnote. This makes the score
self-describing: you can read the mark and understand what was done to the picture.

---

## Charm register — reuse from Cello, verbatim

The scheme adds nothing to the charm register. It REUSES:

- **Wall shape**: `cello_blob(seed, { squish: 0.15, wobble: 0.04, points: 10 })`
  for the bracket blob. The bracket is a cello_blob with extreme squish (very tall
  and thin); the same function, different parameters.
- **Colour**: Matstyle per-mainkey, same palette as Cello/Vytui. No new swatches.
- **sc typography**: TreeFace's `ui-monospace` 9px palette verbatim — the sc tokens
  look exactly like TreeFace rows because they ARE TreeFace rows, just laid
  horizontally rather than vertically.
- **Face mount**: `FACE_MAINKEYS` → `GLASS_KINDS` → `<Face n={source} H={H} />`
  mounted inline in the staff band. Same chain as Cello and CelloTree, different
  geometry (inline vs template slot vs blob fill).

The bracket blob is the one new shape in this scheme. It is produced by the same
`cello_blob` function with `squish: 0.15` — a thin vertical organically-wobbly
column, the cello_blob family member that happens to look like a bracket. No new
math, no new dependency.

---

## The smallest provable slice

A self-contained slice that exercises the full scheme without building the whole:

One `%H:LeafFarm` with sc `{ active: 1 }` and two children:
- `%w:plate` sc `{ self: 1, round: 21 }`, one child `%req:fetch` sc `{ ok: 1 }`.
- `%A:drum` sc `{ crew: 'alpha' }`, no children.

Rendered as:

```
  H:LeafFarm  active                     │ c3 ···
  ⌒ [bracket, grey, 40%]
    w:plate   self  round:21             │ c1 ·
    ⌒ [bracket, blue, 40%]
      req:fetch  ok                      │ c0
    A:drum    crew:alpha                 │ c0
  ⌒ [bracket end]
```

That's two levels of organic bracket, three staff bands with sc tokens and .c
counts, and no physics, no coordinates, no layout engine. If that reads correctly
as a score — bracket down the left of the children, peel-text on each staff — the
rest is just recursion.

The slice is buildable as a static Svelte template first (hardcoded particles, no
scan, no reactive walk): render the four bands with inline CSS `padding-left` for
depth and a single div-with-clip-path for the bracket. Once that looks right,
replace the hardcoded data with a recursive walk of the commissioned world's C tree.

---

## Wiring (build recipe, when the time comes)

The wiring mirrors Cello's recipe exactly:

1. **Ghost**: `CelloScore.svelte` with `{ M }`, `M.eatfunc({ CelloScore_plan, ... })`
   in `onMount`; `CelloScore_plan(w)` stamps `uis.oai({ UI: 'CelloScore' }, { component: Scorui })`.
2. **View**: `Scorui.svelte` receives `{ H }`. It walks the commissioned client world's
   C tree recursively via `Travel` or a hand-written depth-first walk (same source as
   TreeFace's `walk()` function). Each particle produces one staff-band div. Children
   produce a bracket-blob div wrapping their staff bands.
3. **Face mount**: identical to Cello — `FACE_MAINKEYS[mk]` → `GLASS_KINDS[kind]` →
   mount inside the staff band. Staff height grows to accommodate; sc row collapses to
   a toggle.
4. **Charm**: bracket is `clip-path: cello_blob(parent_seed, {squish:0.15, wobble:0.04})`;
   mainkey token is `color: matstyle_ground(mk).jewel`; sc tokens use TreeFace CSS.
5. **Dev route first**: `Otro.svelte` renders every `UIs.ob({UI:1})` side by side —
   CelloScore appears with zero selection work, same as Cello and CelloTree.

---

## Where this fits in the larger picture

Three renderers, three projections of the same clay:

- **Cello** (main+satellites): the SOCIAL shape of the running machine. Who is
  present, what the main thing is, who hovers. Good for the music page, the
  operational moment.
- **CelloTree** (`Cello_tree_scheme_todo.md`): the SPATIAL shape. What contains
  what, how deep the structure goes, nesting as literal containment.
- **CelloScore** (this scheme): the TEXTUAL shape. What the machine is saying,
  line by line, in the universal language that enWaft already speaks. Good for
  Story-step inspection, debugging, "what does this world say right now."

All three honour the same invariants. All three reuse the same charm register. None
introduces a second substrate — the C** particle remains the atom everywhere. The
difference is ONLY in how "where each cell goes" is answered: template slot (Cello),
nesting position (CelloTree), line in the score (CelloScore).

Running all three simultaneously (in Otro, side by side) is the demonstration that
the clay is one and the renderings are projections — the same Radio particle is a
satellite blob, a nested sub-cell, and a staff band, and none of the three views
contradicts another.
