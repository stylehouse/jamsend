# Cello Universal Scheme 4 — the fibre-bundle reading

## 0. What to get on with next

The design is COMPLETE — this is a pure design document, no code is changed.
The next move, when authorised, is to prove the seam with a single particle:
one `%Tree`-rooted rectangle wearing a `cello_blob` clip, with `sc` rendered as
the layered-strata within it, and `.c` count rendered as a submerged stripe below
the waterline. If that ONE particle reads correctly, the full scheme assembles from
repetition.

Candidates after that (pick what's ripe):
- Wire into `Otro.svelte` dev route to show the universal view alongside existing glasses.
- Add the fibre inspector drawer — tapping any cell opens its full bundle side-by-side.
- Extend the honesty channel: animate the TWIST token on compressed/re-parented cells.

---

## The arc

The C** data model has ONE universal property: every particle is a named fibre bundle —
a mainkey (what the thing IS), `sc` (the persisted truth, scalar k:v), and `.c` (the live
underside, runtime refs, never snapped). THREE distinct layers, always present, always in
that priority order.

Every existing renderer — TreeFace, Cytui, Vytui — handles this bundle incompletely.
TreeFace shows `sc` beautifully but buries it in a prose list, giving mainkey no
spatial sovereignty. Cytui and Vytui show the *face* a particle wears (RadioFace,
DoorFace) while hiding the raw bundle behind it entirely. Neither shows `.c` at all
except TreeFace's cref counter.

Scheme 4 renders the bundle as its GEOMETRY. The blob-cell is not a container for
content — it IS the three-layer bundle, spatialised. The mainkey rides the rim (what
the thing IS, held at the boundary). The `sc` k:v pairs are horizontal strata filling
the cell's interior (the persisted truth, legible in place). The `.c` live refs are a
submerged zone below a waterline inside the same cell (runtime underside, visible but
below). A designed Face (RadioFace, DoorFace) can replace the `sc` strata for its
mainkey without removing the other layers — the rim label and the `.c` waterline remain.

The whole field of particles is then a community of these bundle-cells: a flock of blobs
where kin particles look kin (same Matstyle colour, same strata rhythm), compound
particles nest child-cells inside parent-cells (containment IS the C tree), and the
twist channel announces every place the renderer bent truth for effect.

Unity is structural, not decorative. The ONE substrate looks one because every cell
carries the same three-zone geometry. There is no gutter between "the Cello app UI" and
"the universal C data view" — they are the same picture at different zoom/face settings.

---

## The visual language

### The three-zone blob cell

Every particle, regardless of mainkey, is rendered as a blob-clipped rectangle divided
into three horizontal zones. From top to bottom:

```
  ┌────────────────────────────────────────────────────────┐
  │  Radio              ← RIM LABEL (mainkey, Matstyle)   │ ← clip-path: cello_blob(seed)
  ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
  │  src: /music/orbit  ← SC STRATA (sc k:v pairs,        │
  │  vol: 0.8             the persisted truth)             │
  │  active              ← boolean = key alone             │
  ├ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ WATERLINE ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┤
  │  c·4                ← .C ZONE (count of live refs,    │
  └────────────────────────────────────────────────────────┘    never followed)
```

**Zone 1 — the rim (mainkey).**
The mainkey is not a label inside the content — it is inscribed ON the wall, riding the
top rim of the blob outline the same way Vytui's labels ride the voronoi boundary.
Matstyle colour per mainkey (the same swatch the Cello charm register already uses).
This is the BOUNDARY declaring what the thing is; it cannot be lost to a scrolling
interior.

**Zone 2 — the strata (sc k:v).**
The `sc` body is rendered as horizontal bands, one per key-value pair, in declaration
order (declaration order = first-key-is-mainkey, already the type; remaining keys are
the particle's truth). Each stratum is a thin coloured line with the key name on the
left and the value on the right. Boolean presence (value `1` or absent) renders as a
key alone with a soft highlight — the stratum exists but has no right side.

Strata density reflects truth density: a particle with 8 sc keys has 8 visible bands; a
bare marker (`{Radio:1}`) shows one transparent band with just the rim. A trained eye
reads "this particle is dense / sparse" from the zone height before reading the words.

When a designed Face mounts (RadioFace inside a Radio blob), it REPLACES the strata zone
— the Face takes the interior, but the rim label and the waterline zone below remain.
The bundle is never amputated; the Face is a LENS SWAP for zone 2 only.

**Zone 3 — the waterline (.c).**
A narrow strip at the bottom of every cell, separated from zone 2 by a double-rule
(the "waterline" line). Inside: a small `c·N` counter (N = count of non-null keys on
`.c`) in a muted colour. Optionally, when a particle is tapped, the waterline expands
to name each `.c` key — but never follows the refs (they are cycles, backlinks, the
house). The visual message: there is always an underside; it is always countable; it is
never hidden, only submerged.

### The honesty channel — the TWIST token

Wherever the renderer bends the true structure for visual effect — collapsing a deep
subtree, re-parenting a cell for layout convenience, hiding a particle because it is a
`system` crew member, capping strata at N lines — the TWIST token appears.

The token is a small diagonal hatch mark (╲) in the top-right corner of the blob wall,
rendered in the wall's Matstyle colour but at 40% opacity. It is small enough not to
read as content; large enough that a trained eye always sees it. Its tooltip/drawer
names exactly what was twisted: "collapsed 12 children", "system crew hidden", "strata
capped at 8 of 11".

A cell where nothing was bent has no TWIST token. The PRESENCE of the token is an
announcement; the ABSENCE is a guarantee: what you see is what the particle is.

This is not a warning — it is the renderer honouring the invariant that an illusion
announces itself. The Homethink posture says "indicate where the visual language or
illusion is twisted for effect"; the TWIST token is that indicator, made concrete and
mechanical.

```
  ┌────────────────────────────────╲  ← TWIST token (diagonal hatch, muted)
  │  Heist                        ·  │
  │  ...                             │
  │  … 7 more (sc capped)           │ ← stratum showing the cap itself
  ├ ═ ═ ═ ═ waterline ═ ═ ═ ═ ═ ═ ┤
  │  c·3                            │
  └─────────────────────────────────┘
```

### Containment = the C tree

A compound particle (one that has children in `o({})`) renders its children as NESTED
blob-cells inside its zone 2 interior. The parent's `sc` strata appear at the top of
zone 2; below them, child blobs tile the remaining space (smaller, same three-zone
geometry recursively). The nesting IS the tree; containment is not a separate layout
decision.

```
  ┌─────────────────────────────────────────────────────────┐
  │  Library                   ← rim label (mainkey)        │
  ├─────────────────────────────────────────────────────────┤
  │  name: Personal            ← sc strata (zone 2 top)     │
  │  ┌──────────────┐  ┌──────────────┐                     │
  │  │  Record      │  │  Record      │  ← child cells tile │
  │  │  artist: Oren│  │  artist: A.  │    zone 2 remainder │
  │  ╞══waterline═══╡  ╞══waterline═══╡                     │
  │  │  c·2        │  │  c·1        │                      │
  │  └──────────────┘  └──────────────┘                     │
  ├ ═ ═ ═ ═ waterline ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ┤
  │  c·6                                                     │
  └─────────────────────────────────────────────────────────┘
```

Depth is capped (same `depth_cap` as TreeFace, default 3) and TWIST-marked when cut.
Children beyond `kid_cap` show a "… N more" stratum rather than disappearing silently.

### The field — a flock of kin particles

At the overview scale (before any cell is tapped), the renderer shows the commissioned
world as a flock of blob-cells. Proximity = C tree depth: root particles float near the
edges, deep children cluster inside their parents. Matstyle colour makes kin particles
look kin: all `%req` particles share the system-crew tint, all `%Record` particles share
their swatch. The field is DECODABLE as a population picture — mainkey colour encodes
type, size encodes child-count (dose_drives style, a la Matstyle), strata density
encodes sc richness.

This is not a force-layout or voronoi. It is a simple grid/flow of blob-cells inside the
commissioned world's bounding rectangle, with nesting handled by containment. No
computation, no settle — template arithmetic, the Cello principle.

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │  w:Sounditron                                                        │
  │                                                                      │
  │  ┌───────────┐  ┌───────────┐  ┌──────────────────────┐             │
  │  │ Radio [◆] │  │ Door  [◆] │  │ Library              │             │
  │  │ src:…     │  │ id:…      │  │ name: Personal       │             │
  │  │ vol:…     │  │ ╞═══╡     │  │  ┌──────┐ ┌──────┐  │             │
  │  ╞═══════════╡  │ c·3       │  │  │Rec.  │ │Rec.  │  │             │
  │  │ c·4       │  └───────────┘  │  ╞═╡    │ ╞═╡    │  │             │
  │  └───────────┘                 │  │c·1   │ │c·1   │  │             │
  │                                │  └──────┘ └──────┘  │             │
  │  ┌───────────┐  ┌───────────┐  ╞══════════════════════╡             │
  │  │ req   [╲] │  │ Machine   │  │ c·6                  │             │
  │  │ (sys) [╲] │  │ (sys)     │  └──────────────────────┘             │
  │  ╞═══════════╡  ╞═══════════╡                                        │
  │  │ c·2       │  │ c·1       │                                        │
  │  └───────────┘  └───────────┘  ← system-crew tint + TWIST (hidden)  │
  └──────────────────────────────────────────────────────────────────────┘
                 [◆] = designed Face mounted (zone 2 replaced, rim + waterline stay)
```

### The reveal path — overview → one particle's full bundle

1. **Overview.** All cells in the commissioned world at once. Colour = mainkey swatch.
   Size ~ child count (dose_drives). Strata visible but small (8px text). TWIST tokens
   visible as hatch marks. `.c` waterline visible as a stripe at the bottom of each cell.

2. **Hover.** The hovered cell brightens; its rim label grows; zone 2 strata text
   becomes readable (12px). If a designed Face is mounted, it activates (the Face's own
   hover logic fires — it is inside the cell, not replaced by the renderer's hover).

3. **Tap.** The tapped cell opens a FIBRE INSPECTOR beside it: a side-by-side panel
   showing the full bundle in raw form (mainkey: large; sc k:v: one per row, all keys
   including DULL ones; `.c`: each key named and counted, with a "(never followed)"
   annotation). This is TreeFace's territory — the panel IS a TreeFace instance, mounted
   beside the cell. The cell itself does not change; the inspector is additive.

4. **Deep tap.** Inside the fibre inspector, a child row can be tapped to promote that
   child's particle to its own inspector column (a growing breadcrumb of bundle panels
   to the right). This is the reveal path from overview to any node's full truth,
   without ever losing the field.

---

## Where designed Faces mount vs where raw-C carries the node

**Designed Face (GLASS_KINDS entry):** mounts when `mainkey ∈ FACE_MAINKEYS` or
`sc.face` is worn. The Face REPLACES zone 2 (the strata interior) for its cell.
The rim label (zone 1) and the waterline (zone 3) are the renderer's responsibility,
NOT the Face's — they stay in every cell regardless of what Face is mounted. This is
the invariant: the bundle geometry persists even when a Face is showing.

**TreeFace / raw-C:** carries every particle whose mainkey is NOT in FACE_MAINKEYS and
which wears no `sc.face`. The strata zone IS TreeFace rendered inline — a compact form
of TreeFace's prose list, horizontally laid as bands. The same DULL key suppression, the
same "… N more" for overflow, the same `c·N` waterline. TreeFace is not a fallback; it
is the universal layer that designed Faces are punched through.

The design face/raw-C boundary is VISIBLE in the field: a cell with a designed Face has
a solid interior (the Face fills zone 2); a raw-C cell has visible strata bands. You can
see at a glance which particles the community has designed a face for and which live in
their own raw truth.

---

## Reuse of the render seam

**Registration** (identical to Cello_todo build recipe):
```
let uis = this.oai_enroll(this, { watched: 'UIs' })
uis.oai({ UI: 'CelloUniversal' }, { component: CelloUniversalui })
```

**Props contract:** `let { H } = $props()` — the commissioning House. Cellui convention.

**cello_blob:** `clip-path: cello_blob(cello_seed(particle.sc.pub ?? particle.sc.id ?? mainkey))`
on every cell div. Shape persists across renders (deterministic per seed), varies between
cells. The seeded jitter is the whole of the hand-drawn feel — no new wobble added.

**Matstyle per mainkey:** `matstyle_colour(mk, H)` (same guard Vytui:1284 uses) for zone
1 rim colour and the blob wall stroke. The system-crew tint for CREW_MAINKEYS members.

**Face mount:** declarative, inside each cell's zone 2:
```svelte
{#if Face}
  <svelte:boundary>
    <Face n={source} H={H} />
  </svelte:boundary>
{/if}
```
where `source = row.c.source_n ?? row`. The `<svelte:boundary>` keeps a thrown Face from
white-screening the glass (Vytui:4106 pattern).

**Cells source:** scan the commissioned world's tree for face-bearing particles
(`mainkey ∈ FACE_MAINKEYS || sc.face`) and all remaining particles visible at depth ≤
depth_cap. A `{#each cells as cell (cell.key)}` keyed by stable id drives mount/unmount.

**The fibre inspector panel:** a mounted `<TreeFace n={selected} H={H} />` in a side
column, opened by tap. The existing TreeFace component, unchanged — it is already the
right tool for this job.

---

## The TWIST token — mechanics

```ts
type TwistReason =
  | { kind: 'capped_strata'; shown: number; total: number }
  | { kind: 'capped_children'; shown: number; total: number }
  | { kind: 'crew_hidden'; crew: string }
  | { kind: 'subtree_collapsed'; depth: number; count: number }

// computed per cell during the scan:
const twist: TwistReason[] = []
if (sc_keys.length > STRATA_CAP) twist.push({ kind: 'capped_strata', shown: STRATA_CAP, total: sc_keys.length })
if (kids.length > KID_CAP) twist.push({ kind: 'capped_children', shown: KID_CAP, total: kids.length })
if (CREW_MAINKEYS[mk]) twist.push({ kind: 'crew_hidden', crew: CREW_MAINKEYS[mk] })
```

The hatch mark (╲) is a small SVG `<line>` drawn in the top-right corner of the cell's
bounding box, using the Matstyle wall colour at 40% opacity. Its `title` attribute lists
each TwistReason as a human sentence. No animation — it is either present or absent,
truthfully.

---

## The unifying invariant

**Every cell, at every scale, carries the same three-zone geometry: rim (mainkey) + strata
(sc) + waterline (.c). A designed Face replaces zone 2 only. The TWIST token marks any
bend. Nothing may amputate any zone to look tidy.**

This is one sentence that governs every rendering decision in the scheme. A layout choice
that would require hiding the waterline to fit is the wrong layout. A Face that wants to
own the rim label is the wrong Face. A compression that drops strata silently (no TWIST
token) is a lie the design forbids.

The scheme does NOT enumerate mainkeys; it does NOT hardcode colours; it does NOT special-
case any particle. Everything that looks different between a `%Radio` cell and a `%req`
cell comes from Matstyle (per-mainkey swatch) and FACE_MAINKEYS (face mount vs raw-C).
The geometry is the same clay.

---

## The smallest provable slice

One rectangle. One `%Tree` particle (the world root). Three visible zones.

```
  Particle: { Tree: 1, src: 'w:Sounditron' }  — a bare %Tree marker
  
  ┌─────────────────────────────────┐
  │  Tree  ← rim label, Matstyle   │  ← clip-path: cello_blob(cello_seed('Tree'))
  ├─────────────────────────────────┤     wall stroke in Tree's Matstyle colour
  │  src: w:Sounditron             │  ← one stratum (sc minus mainkey)
  ├ ═ ═ ═ ═ waterline ═ ═ ═ ═ ═ ═ ┤  ← double-rule separator
  │  c·1                           │  ← .c count (tree_root ref)
  └─────────────────────────────────┘
  
  If Tree is in FACE_MAINKEYS (it now is, via glass_faces.ts:Tree:'Tree'):
    zone 2 is replaced by <TreeFace n={source} H={H} />
    rim label (Tree, matstyle colour) stays
    waterline (c·1) stays
    TWIST token: absent (nothing was bent for this minimal case)
```

This slice proves:
1. The blob clip renders (cello_blob.ts, existing, no change).
2. The three-zone geometry is drawable (div layout, no new dependencies).
3. A designed Face (TreeFace IS in GLASS_KINDS) mounts in zone 2 while rim + waterline
   remain the renderer's (not the Face's) concern.
4. The TWIST token is absent when nothing was bent (the honesty channel is truthful by
   DEFAULT, not by exception).

Everything else in the scheme is repetition of this one cell at different mainkeys,
face-levels, and nesting depths.

---

## ASCII field map — full scheme at a glance

```
  COMMISSIONED WORLD (one blob per particle, kin particles kin-coloured)
  ┌────────────────────────────────────────────────────────────────────────┐
  │                                                                        │
  │  ┌──────────────────────────┐    ┌─────────────┐  ┌─────────────┐   │
  │  │  Radio          [Face◆]  │    │  Door  [◆]  │  │  Diag  [◆]  │   │
  │  │  ╔══════════════════════╗ │    │  id:…       │  │  open       │   │
  │  │  ║   RadioFace          ║ │    ╞═════════════╡  ╞═════════════╡   │
  │  │  ║   (zone 2 replaced)  ║ │    │  c·3        │  │  c·1        │   │
  │  │  ╚══════════════════════╝ │    └─────────────┘  └─────────────┘   │
  │  ╞══════════════waterline═══╡                                         │
  │  │  c·4                     │    ┌─────────────────────────────────┐ │
  │  └──────────────────────────┘    │  Library                        │ │
  │                                  │  name: Personal                  │ │
  │  ┌─────────────┐                 │  ┌──────────┐  ┌──────────┐    │ │
  │  │  req    [╲] │ ← TWIST         │  │  Record  │  │  Record  │    │ │
  │  │  (system)   │   (crew hidden) │  │  artist… │  │  artist… │    │ │
  │  ╞═════════════╡                 │  ╞══wl═╡    │  ╞══wl═╡    │    │ │
  │  │  c·2        │                 │  │  c·2  │  │  │  c·1  │  │    │ │
  │  └─────────────┘                 │  └──────────┘  └──────────┘    │ │
  │                                  ╞═════════════════════════════════╡ │
  │  [tap any cell → FIBRE INSPECTOR │  c·6                            │ │
  │   panel opens beside it,         └─────────────────────────────────┘ │
  │   showing full bundle raw]                                            │
  └────────────────────────────────────────────────────────────────────────┘

  LEGEND
  [Face◆]  designed Face mounted in zone 2 (zone 2 is the Face's; rim + waterline stay renderer's)
  [╲]      TWIST token — this cell bent the true structure for effect (hover/tap for reason)
  ╞══wl═╡  waterline separator, .c count below
  (system) crew tint — CREW_MAINKEYS member, shown at reduced opacity
```

---

## Why this is the most elegant rendition

The existing renderers hide the substrate behind the face they chose for it. This scheme
SHOWS the substrate and makes the face a transparent lens — zone 2 is the lens swap, not
the truth. The result is a renderer that is simultaneously:

- **The app UI** (designed Faces in zone 2, rim labels, satellite layout from Cello).
- **The universal C data view** (strata bands, waterline, TWIST tokens, nesting).
- **The honesty channel** (the token announces every bend; its absence is a guarantee).

These are not three views that swap — they are the SAME picture at three levels of
attention. A musician sees the RadioFace. A developer sees the strata. A builder sees
the TWIST tokens. All three are looking at the same three-zone blob. That is what
"prevent mindless separation" means: there is no mode switch between "the app" and "the
data model" — they are the same legible living matter, rendered once.

The scheme is buildable from existing primitives: `cello_blob.ts`, `Matstyle`, the Face
mount chain from Cello_todo, `TreeFace`, `GLASS_KINDS`, `FACE_MAINKEYS`. No new layout
engine. No new physics. The genius is in what the three zones MEAN, not in any novel
machinery.
