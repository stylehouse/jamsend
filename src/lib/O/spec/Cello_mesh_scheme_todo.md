# Cello Mesh — the decodable-field renderer

A sibling scheme to Cello (the main+satellites template renderer). Where Cello asks
 "which one thing are we looking at right now?", Mesh asks "what is the whole field of
  matter, in full, at once?" — and answers by rendering it as a dense, demarcated,
   decodable texture.

## 0. What to get on with next

This is a **design document only** — no code yet. Read it whole before touching any
 render file. The next move when this is ready to build:

- Prove the atom cell in isolation: one `CelloMesh.svelte` (view only) that renders a
   single particle as an atom glyph — mainkey pill + `sc` k:v pebbles + `.c`-link
    feather stubs — no field, no layout, just the atom vocabulary looking right.
- Then tile a small known-static C subtree (e.g. 10–20 particles from a Story snap)
   into the weave layout, confirm the demarcation reads at a glance.
- The twist channel comes third — wire it only after the base field proves legible.

Open questions to resolve with the owner before building:
- Should Mesh be a third glass option (a `UI:'Mesh'` particle beside `UI:'Cello'` and
   `UI:'Vyto'`), or a MODE within Cello (a flag on the main cell)?
- What is the entry point — a Story Book, a dev route, or a panel in Cello's glass?
- How dense is "dense"? The owner should see a static mock first and call the zoom floor.

---

## 1. The arc — what Mesh is for

Cello gives you a proper look at one thing. Mesh gives you the FULL POPULATION at once.
 It is the snap rendered as a field — the same language that `enWaft`/Travel serialises
  to prose, now rendered as a visual texture where:

- **density = population** — more particles, tighter weave; a sparse subtree is a loose
   airy patch; a dense req stack is a tight-packed band of atoms.
- **colour = mainkey** — Matstyle's per-key jewel swatch, the same one Cello and Vyto
   use, so a trained eye reads `%req` bands (steel-blue tangle), `%Radio` (gold anchor),
    `%LE` (a particular tone), without a legend.
- **shape = sc-arity** — few keys → a small round pebble; many keys → a heavier
   rectangular tablet; a keyless particle → a dot.
- **weave direction = tree depth** — root flows left-to-right (or top-to-bottom); depth
   is a reading direction, not a position, so the field isn't a rigid tree diagram.
- **feather stubs = `.c` links** — lightweight dashed connectors below the sc surface,
   quieter than the sc bonds, indicating runtime references without cluttering the field.

The "fibre bundle" property means any particle in the field can be REVEALED: hover or
 tap surfaces the full atom (mainkey + every sc k:v + a `.c` inventory), so inspection
  never destroys the field view — it overlays.

---

## 2. Visual vocabulary — the atom

Every C particle renders as an **atom glyph**:

```
 ┌──────────────────────┐
 │ mainkey              │  ← pill / ribbon on top rim (Matstyle colour)
 │  ·key:val  ·key:val  │  ← sc pebbles (small, readable at medium zoom)
 │  ·key:val            │
 │ - - - - - - - - - -  │  ← separator: above = sc (believed), below = .c (runtime)
 │  ⌁link  ⌁link        │  ← feather stubs for .c refs (dashed, quieter hue)
 └──────────────────────┘
```

### Atom sizing

The atom's width and height are functions of its sc key count (N_sc) and .c ref count
 (N_c), not of semantic importance. This keeps the field honest — a rich particle is
  visibly richer, not bigger because it's "important".

```
  atom_w = BASE_W + N_sc * PEB_W    (clamped to [MIN_W, MAX_W])
  atom_h = BASE_H + ceil(N_sc/COL) * ROW_H + FEATHER_H * ceil(N_c / COL)
```

At field zoom (zoomed out), atom_w and atom_h shrink by a scale factor and the sc text
 drops below a legibility floor — the atom becomes a **mote**: just the mainkey pill + a
  coloured mass whose width still encodes N_sc. The mote is NOT a loss of information —
   it IS the information at field scale, and the full atom recovers on zoom.

### The mainkey pill

The pill is a `cello_blob`-clipped strip on the atom's top rim, coloured by Matstyle's
 per-mainkey swatch. This reuses the charm register from Cello exactly: `cello_blob(seed,
  { points: 8, wobble: 0.04 })` on a small rect gives the pill its organic edge without
   any new geometry. The pill's seed is `cello_seed(mainkey)` — so every `%req` pill has
    the same blob silhouette, reinforcing the colour as a language.

### sc pebbles

Each `sc` k:v pair is a tiny rounded pill inside the atom body, laid in a flow grid:

```
  [ key:val ]  [ key:val ]  [ key:val ]
  [ key:val ]  [ key:val ]
```

At field zoom the text collapses; the pebble becomes a coloured dot whose hue is a
 deterministic function of the KEY (not the value), so `sc.ok:1` and `sc.ok:true` both
  read as the same hue (= the "ok key" hue). This means a trained eye reads the sc
   composition of a mote from its dot pattern, not from text.

Key-hue is a simple hash: `hue = (djb2(key) * 137.508) % 360` — the golden-angle spread
 ensures well-distributed hues for typical key names with no collisions at close range.

### Feather stubs (the .c substrate)

`.c` refs are drawn BELOW the separator as short dashed connectors pointing outward toward
 the referent atom (if visible in the field) or toward the field edge (if not). They are
  always QUIETER than sc — lower opacity, dashed, half the weight of sc bonds. This is the
   visual rendering of "`.c` is below `.sc` everywhere, never snapped."

The connector is a bezier curve that bows gently outward — not a straight line — because a
 straight line implies a logical relationship equal to an sc bond, and it is not. The bow
  is consistent (always curves away from the reading direction) so it reads as a convention,
   not noise.

---

## 3. The weave layout

The field is a **kinship weave**, not a force-directed graph and not a tree diagram. The
 layout rule is:

1. **Band by containment depth.** Atoms at depth 0 (H:Mundo, the root) anchor the left
    edge (or top, in portrait). Each depth level is a BAND: depth-0 band, depth-1 band,
     depth-2 band, etc. Bands are separated by a visible demarcation gap — a thin ruled
      line the colour of the Matstyle base, not white/grey.

2. **Within a band, group by mainkey.** All `%req` atoms cluster together, all `%LE`
    atoms cluster, all `%Step` atoms cluster. The cluster boundary is a slightly heavier
     demarcation: a subtle halo or edge shadow in the mainkey colour. This is the
      "groupology" — visible kinship without hard borders.

3. **Within a cluster, lay atoms in a grid flow.** No physics, no forces. Columns are
    fixed; atoms wrap. The grid uses the same arithmetic as Cello's template slots: N atoms,
     M columns, each cell = MAX_ATOM_SIZE + gap. Simple, clickable, never wedges.

```
  BAND 0 (depth 0)
  ┌───────────────────────────────────────────────┐
  │ [H:Mundo]                                     │
  └───────────────────────────────────────────────┘
  ─ ─ ─ ─ ─ ─ ─ ─ depth band gap ─ ─ ─ ─ ─ ─ ─ ─
  BAND 1 (depth 1)
  ┌─── w:Story ──────────┐┌─── w:Lies ────────────┐
  │ [%w:Story] [%w:...] ││ [%w:Lies]              │
  └──────────────────────┘└──────────────────────-┘
  ─ ─ ─ ─ ─ ─ ─ ─ depth band gap ─ ─ ─ ─ ─ ─ ─ ─
  BAND 2 (depth 2) — the bulk of the field
  ┌── %req cluster ──┐┌── %Step cluster ─┐┌── %LE ─┐
  │ [r] [r] [r] [r] ││ [s] [s] [s]      ││ [e][e] │
  │ [r] [r] [r]     ││ [s] [s]          ││ [e]    │
  └──────────────────┘└──────────────────┘└────────┘
```

This layout has **no layout thinking** (Cello's rule carries forward): it is pure
 arithmetic, depth → band, mainkey → cluster, count → grid. Nothing wedges.

### The reading direction

Default: depth runs LEFT → RIGHT (bands are columns, not rows). Portrait view flips to
 TOP → BOTTOM. This aligns the weave with the natural snap-text reading direction
  (enWaft emits top-to-bottom at increasing indent = increasing depth), so a reader who
   knows the snap feels oriented in the Mesh without re-learning.

### The demarcation register

Three demarcation levels, each visually distinct:

| Level | What it separates | Visual |
|-------|------------------|--------|
| Band gap | depth levels | thin 1px ruled line, Matstyle base-colour, 8px gap |
| Cluster halo | mainkey groups within a band | 2px halo shadow in mainkey jewel colour |
| Atom wall | individual particles | `cello_blob` clip-path outline (same charm as Cello) |

Three levels, no more. The field must be readable as a texture from arm's length, where
 only band gaps and cluster halos are visible — individual atom walls only at medium zoom.

---

## 4. The fibre bundle — zoom reveals, nothing amputates

The Mesh has three zoom levels, each recoverable from the next:

```
  FIELD (zoomed out)
  → motes only: mainkey pill colour + sc dot pattern
  → bands and clusters legible; feather stubs invisible

  MEDIUM (normal reading distance)
  → full atom: mainkey pill text + sc pebble pills (text legible)
  → feather stubs visible as dashed arcs
  → atom wall outline visible

  INSPECT (hover or tap an atom)
  → overlay panel: mainkey + ALL sc k:v (full values, untruncated)
  → .c inventory: each ref listed by name + its own mainkey colour
  → if a .c ref is another C particle in the field, a LIVE highlight
     arc connects them (briefly; the arc fades after 2s to avoid clutter)
```

The inspect overlay is the fibre bundle surface. It does NOT replace the field — it
 floats over it. Closing the overlay returns to the field unchanged. Nothing is destroyed
  for tidiness.

The overlay uses the same Faces mechanism as Cello: if the particle has a `face` in
 `FACE_MAINKEYS`, the overlay mounts that Face (e.g. RadioFace for a `%Radio` particle)
  inside a small inset panel below the raw k:v dump. This means the Mesh can act as a
   second glass into the live UI: inspecting `%Radio` surfaces the actual Radio controls,
    not just its sc keys.

---

## 5. The twist channel — the honesty woven into the texture

The honesty channel is the "twisted for effect" signal. It answers: **where does the
 visual language distort the true C structure?**

### What distorts

Known distortion classes (from the codebase's own tells):

1. **Compound particles** — a particle whose mainkey also nests children (a scope in
    Cytui terms). The Mesh would naively render it as a leaf atom, hiding the children.
2. **`.c` foam** — runtime refs piled on `.c` that are never snapped; the snap shows a
    "clean" particle but the live `.c` is teeming. The field over-reports tidiness.
3. **`undef` markers** — `sc.path` = `undefined` (the mint bug from CLAUDE.md). The atom
    pebble would show `path:undefined` which looks like a value but is a wound.
4. **Finished but un-dropped reqs** — `%req,finished` still in the tree; the field would
    count them as live matter when they are dead scaffolding.
5. **Objects in sc** — a fatal encode error; the field cannot render the value.

### The visual signal

The twist channel uses a **warp overlay on the atom wall**: the `cello_blob` outline is
 drawn NORMALLY for clean particles, and WARPED for distorted ones. The warp is achieved
  by increasing `wobble` from 0.04 to 0.22 (still one call to `cello_blob`, just a
   different option) and adding a **hue shift** to the pill — the mainkey colour rotates
    ~60° toward red/orange (a warning signal that does not eliminate the base hue, so the
     mainkey is still readable).

```
  Clean atom:       normal blob outline,  mainkey jewel colour
  Distorted atom:   wobblier blob outline, hue-shifted ~60° toward amber
```

The warp is graded by distortion severity:

| Distortion | Extra wobble | Hue shift | Label |
|------------|-------------|-----------|-------|
| compound (hidden children) | +0.06 | none | depth marker on rim |
| .c foam (N_c >> typical) | +0.08 | +20° amber | feather stubs pulse |
| undef sc value | +0.12 | +40° amber | pebble turns hollow |
| finished req | +0.10 | +30° amber | atom opacity 50% |
| object in sc (fatal) | +0.18 | +60° red | ⚠ glyph on pill |

The warp ANNOUNCES the distortion but does not destroy the atom. A warped atom is still
 a legible atom at medium zoom — its sc pebbles are still visible, its mainkey is still
  readable. The warp is an honest annotation, not a censorship.

### The "twisted for effect" case

Some distortions are INTENTIONAL — a Face deliberately warps its display for a UX effect
 (e.g. an animated cell that exaggerates size; a hidden compound that is designed to be
  opaque). For these, the warp channel carries a METADATA escape hatch: if a particle
   carries `sc.twist:'effect'` (a snapped annotation), the warp is drawn in **purple**
    (the Door colour, a conventional "this is a door not a wound") rather than amber/red.
     This distinguishes "honest distortion, by design" from "wound, fix it."

The `sc.twist:'effect'` annotation is authored in matter — it snaps, it is legible, it
 is revocable. It does not hide the warp; it reclassifies it.

---

## 6. Unity — one substrate, no gutters

The Mesh's deepest design constraint is: **no mindless separation**.

Enforced by:

- **One SVG/HTML canvas for the whole field.** No iframes, no shadow roots that sever
   the field. The entire population of particles lives in one rendering surface. Bands and
    clusters are demarcated by visual conventions (gap, halo, outline), never by separate
     DOM containers that enforce isolation.

- **The same clay everywhere.** `%req` atoms, `%Radio` atoms, `%Step` atoms — all use the
   same atom glyph grammar. Their colour and shape differ by mainkey; their FORM does not.
    There is no "special" rendering for special mainkeys. The only specialisation is the
     Face mount in the inspect overlay, which is additive, not alternative.

- **The snap IS the field.** The Mesh renders the same tree that `enWaft` serialises.
   What the snap says, the Mesh shows. If a particle is missing from the snap (because it
    has no snappable sc), it shows as a dot with no pebbles — not absent. The only
     particles absent from the Mesh are those absent from the LIVE tree entirely (`.c`-only
      runtime state with no particle backing). These are surfaced as feather stubs pointing
       off-field, with a count label: "`+N unsnapped .c`". The honesty channel.

- **Kinship lines, not membership boxes.** Clusters show kinship by halos, not by hard
   bounding boxes with drop shadows and borders. A particle at the edge of a cluster is
    still visibly kin to its neighbours, not enclosed in a box that separates it from the
     adjacent cluster. The field reads as a CONTINUOUS texture with soft regional identity,
      not a collection of sub-panels.

---

## 7. Relationship to the Cello charm register

The Mesh reuses the Cello charm inventory verbatim:

| Cello charm | Mesh use |
|-------------|----------|
| `cello_blob(seed, opts)` | atom wall clip-path (low wobble); pill clip-path (very low wobble); warp channel (high wobble) |
| `cello_seed(id)` | atom seed (from particle id/pub); pill seed (from mainkey, shared per kind) |
| Matstyle per-mainkey jewel | atom pill colour; cluster halo colour; feather stub colour |
| `FACE_MAINKEYS` / `GLASS_KINDS` | Face mount in inspect overlay |
| `clip_of` (Vytui's percentage clip) | atom wall clip (Mesh computes a local bbox per atom) |

No new charm is introduced. The Mesh's visual character is the same community of ghosts
 wearing its own face as a field, not a separate visual language.

---

## 8. What the Mesh is NOT

- **Not a graph.** No force layout, no edge routing, no fcose, no cytoscape. The weave
   is arithmetic, not physics. It cannot wedge.
- **Not a tree diagram.** Depth → band, but atoms within a band are NOT arranged to show
   parent-child structure. The containment relationship is encoded in the band, not in
    vertical stacking. A tree diagram would impose one reading order; the weave allows
     multiple starting points.
- **Not a debugger panel.** The Mesh is a renderer of C matter, not a debugger. It does
   not provide edit controls, value mutation, or tree restructuring. Inspection (the
    overlay) is read-only. The Lies pipeline handles editing; the Mesh only SEES.
- **Not Vyto.** Vyto is "the town squinting at itself until structure becomes a `%Seem`."
   The Mesh does not compute Seems or run voronoi. It renders the raw population without
    inference. The Mesh is the snap rendered as a field; Vyto is the snap rendered as a
     topology.

---

## 9. The smallest provable slice

Build in this order, stopping when the owner has seen enough to steer:

### Slice 1 — the atom vocabulary (FIRST MILESTONE)
One `.svelte` file, no Ghost machinery, no layout. Takes a single `TheC` particle as a
 prop. Renders:
- The mainkey pill (coloured rectangle with `cello_blob` clip, Matstyle colour)
- The sc pebbles (flow grid of small rounded pills, one per k:v)
- The separator line
- Feather stubs for N_c (as short dashed horizontal marks, no routing)
- The warp overlay on one known-distorted test particle

Owner sees this and calls the visual language.

### Slice 2 — the flat field (SECOND MILESTONE)
Takes a flat array of `TheC` particles. Renders them in a flow grid (no bands, no
 clusters yet). Proves the field texture reads as a decodable language at "arm's length"
  viewing distance.

### Slice 3 — bands and clusters (THIRD MILESTONE)
Introduce the depth-band layout and mainkey-cluster grouping. Wire from a live world's
 `.o()` walk. Prove the demarcation register reads without a legend.

### Slice 4 — the fibre bundle overlay (FOURTH MILESTONE)
Wire hover → inspect overlay. Mount FACE in the overlay for face-bearing particles. Prove
 the field survives inspection (does not re-layout on hover).

### Slice 5 — the twist channel (FIFTH MILESTONE)
Detect the five distortion classes from live matter. Render warped atoms for distorted
 particles. Add `sc.twist:'effect'` purple-warp for declared intentional distortions.

---

## 10. ASCII sketch — the full field at medium zoom

```
  CELLO MESH — full field (medium zoom, 1200×800 canvas)

  ╔═══════════════════════════════════════════════════════════════════╗
  ║ BAND 0 (depth 0)                                                  ║
  ║  ┌─────────────────────────────────┐                              ║
  ║  │ H:Mundo                         │  ← mainkey pill (steel)      ║
  ║  │  ·id:xxx  ·created:...          │  ← sc pebbles                ║
  ║  └─────────────────────────────────┘                              ║
  ╠═══════════════════════════════════════════════════════════════════╣  ← band gap (ruled line)
  ║ BAND 1 (depth 1)                                                  ║
  ║  ┌── w:Story ────┐  ┌── w:Lies ─────┐  ┌── A:Vyto ─────┐        ║
  ║  │[%w] [%OtherS] │  │[%w] [%Cortex] │  │[%A] [%w:Vyto] │        ║
  ║  └───────────────┘  └───────────────┘  └───────────────┘        ║
  ╠═══════════════════════════════════════════════════════════════════╣
  ║ BAND 2 (depth 2) ─ the dense heart of the field                  ║
  ║                                                                   ║
  ║  ┌── %req cluster (steel-blue halo) ────────────────────────┐    ║
  ║  │ [r][r][r][r][r] [r][r][r][r] [r!amber warp][r][r][r][r] │    ║
  ║  │ [r][r][r][r]    [r][r]        [r][r][r]                  │    ║
  ║  └──────────────────────────────────────────────────────────┘    ║
  ║                                                                   ║
  ║  ┌── %Step cluster (teal halo) ──┐  ┌── %LE cluster ──────┐      ║
  ║  │ [s][s][s]  [s][s][s]  [s][s] │  │ [e][e][e]  [e][e]   │      ║
  ║  │ [s][s]     [s]                │  │ [e][e]              │      ║
  ║  └──────────────────────────────┘  └────────────────────-─┘      ║
  ║                                                                   ║
  ║  ┌── %Radio (gold) ──┐  ┌── %Door (purple) ──┐                   ║
  ║  │     [Radio]       │  │      [Door]         │                   ║
  ║  └───────────────────┘  └────────────────────┘                   ║
  ╠═══════════════════════════════════════════════════════════════════╣
  ║ BAND 3 (depth 3)  ─ thin band, mostly req children               ║
  ║  [r][r][r] ··· [s-child][s-child] ···                            ║
  ╚═══════════════════════════════════════════════════════════════════╝

  Legend: [r]=req atom  [s]=Step atom  [e]=LE atom  [!]=warped (distortion)
          ··· = more atoms not shown (motes at this zoom)
          steel/teal/gold/purple = Matstyle jewel colours
```

---

## 11. The atom at inspect zoom (overlay panel)

```
  ┌─────────────────────────────────────────────────────┐
  │ ▓▓▓▓▓▓▓▓ req (steel-blue pill) ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │
  │ ┌────────────────────────────────────────────────┐  │
  │ │  sc (believed structure)                       │  │
  │ │  · req: Store                                  │  │
  │ │  · finished: 1                                 │  │ ← hollow pebble:
  │ │  · of: [id]                            ○ undef │  │   distortion signal
  │ ├────────────────────────────────────────────────┤  │
  │ │  .c (runtime, not snapped)                     │  │
  │ │  ⌁ source_n → %Radio [gold]                    │  │ ← live highlight
  │ │  ⌁ host → %H:LeafFarm [steel]                  │  │   arc if visible
  │ │  ⌁ watcher_fn (fn, unsnappable)   +1 unsnapped │  │
  │ ├────────────────────────────────────────────────┤  │
  │ │  [twist: warp=amber — finished but not dropped] │  │ ← twist annotation
  │ └────────────────────────────────────────────────┘  │
  │ [RadioFace mounted here if face-bearing]             │
  └─────────────────────────────────────────────────────┘
```

---

## 12. Registering Mesh alongside Cello

When built, Mesh registers as a sibling UI particle:

```
  uis.oai({ UI: 'Mesh' }, { component: CelloMeshui })
```

The Mesh view receives the same `H` prop as Cello and Vyto. It walks `H`'s commissioned
 world (the same `client_w` as Cello's `e_Cello_commission` stashes). No new machinery.

The Otro dev route will show all three glasses side-by-side — Cello (focused cell),
 Vyto (voronoi), and Mesh (decodable field) — which is the cheapest way to compare the
  three visual philosophies on the same live data.

---

*This is a design document — DESIGN ONLY. No code was edited. The next session builds
 Slice 1 (the atom vocabulary), then shows the owner.*
