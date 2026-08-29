# Cello Universal Scheme 5 — the snap as a living score

## 0. What to get on with next

This is a DESIGN doc only. No code exists yet. The smallest provable slice
 (§9) is the right entry point: one particle rendered as a **staff**, proving
  the sc/mainkey/c-below split in isolation before wiring the whole field.

Arc: the C** data model has been serialised to prose (the snap) and rendered
 as a graph (Cyto) and a voronoi foam (Vyto). Neither exposes the FIBRE BUNDLE
  — the fact that every particle is three layers at once (mainkey = TYPE, sc =
   BELIEVED K:V STRUCTURE, .c = LIVE UNDERBELLY never encoded). This scheme
    proposes a third visual language: the **scored field** — where each particle
     is a horizontal STAFF, sc runs as readable notation across it, .c sits
      BELOW the staff line as a quiet undertone, and the whole field reads like
       a musical score a conductor can follow from overview to single note.

The bet it makes: if the snap is "the sum total of the language", then the most
 honest rendering of it is one that feels like reading a score — a structured
  time (here: depth/hierarchy) across the horizontal axis, pitch (here:
   mainkey + value density) on the vertical register, and a wire running below
    every staff that the eye can see without reading.

---

## 1. The visual language — staff-score rendering of C**

### 1.1 Core metaphor: the snap AS a score

A musical score is not a picture of sound — it is a NOTATION for it. It has
 layers (the staff, the clef, the note, the dynamic marking below) and the eye
  learns to read them at different distances: the conductor sees the full page;
   the cellist reads bar 12 note by note. The snap is the same: full-field
    shows density and grouping; zoom shows sc k:v pairs; further zoom reveals
     .c keys as the rumble beneath.

Every particle becomes a **STAFF ROW**:

```
 ┌──────────────────────────────────────────────────────────────────────┐
 │ clef │ mainkey:value ║ k1:v1 │ k2:v2 │ k3 │ k4:v4 …             │ ║│
 │──────┼───────────────╫───────┴───────┴────┴──────────────────────┴─╫│
 │      │               ║ .c: ref1  ref2  ref3  (muted, below staff) ║ ║│
 └──────┴───────────────╨───────────────────────────────────────────────╨┘
```

- **Clef zone** (leftmost, ~24px): the per-mainkey Matstyle colour jewel. No
   text. The clef IS the colour. You see `Radio = gold`, `Door = purple`
    without reading a word, the same way a treble clef tells you what register
     you're in. This is where bespoke Faces (GLASS_KINDS) hang their icon badge.
- **Mainkey bar** (next 80–120px): the mainkey label in bold, followed by its
   sc[0] value if present. The thick DOUBLE BAR (║) separates it from the
    attributes — this is the bar line, and it reads as "after here, the
     properties of the thing named on the left."
- **Sc notation field** (fills remaining width): each k:v pair is a pill
   spanning a proportional width (longer values = wider pill, capped). Pairs
    that carry flag-only keys (value=1, a boolean presence) render as OPEN
     DIAMOND heads — visible, but clearly "this key is the value, no value to
      show." Pairs with strings render as FILLED pill. Pairs with long text
       render as FILLED + a dashed right edge indicating "truncated."
- **Under-staff wire** (below the sc row, ~10px tall): the .c layer. Never
   spelled out, never linked into. Rendered as a MUTED UNDERTONE — a row of
    faintly coloured rectangles, one per non-null .c key, each coloured by
     WHAT KIND of .c ref it is (runtime ref = blue, backlink = amber, House
      chain ref = purple) but NEVER labelled unless hovered. The undertone is
       ALWAYS present even if .c is empty (a blank wire below the staff is its
        own signal: "this particle has no live refs"). The separation of the
         undertone from the staff above is the fibre-bundle honesty: .c is
          always THERE, always BELOW, never blurred with sc.

### 1.2 Depth = indentation = the tree

Children indent by one LEDGER unit (8px) from their parent's left. The tree
 structure becomes the staff-paper indentation you see in a piano grande score:

```
Radio                  ════════════════════════════════
  Spin,of:X            ────────────────────
  Spin,of:Y            ────────────────────
  Heist,of:X         ══════════════════════════════════
    PickFace,id:abc      ──────────────────
```

Thick staff = more sc keys (more information density). Thin staff = leaf node
 or sparse particle. The EYE reads density before it reads content.

### 1.3 Field scale: overview → single particle

Three focal distances, one renderer:

**Overview (full field, zoom out):**
Staffs compress to single-pixel horizontal rules. The clef colour persists.
 Density (sc key count) maps to rule WEIGHT (1–3px). Children stay indented.
  The field looks like a score seen from across the room: you see the GROUP
   STRUCTURE and colour palette, not individual notes. The `.c` undertone
    collapses to a single coloured dot at the left of each rule.

**Reading (comfortable zoom, default):**
The staffs as described in §1.1 — clef | mainkey | pills | undertone wire.
 sc values are readable. .c keys are visible as coloured blocks, unnamed unless
  a hover tooltip fires.

**Inspection (hover/tap a staff):**
The targeted staff expands to FULL HEIGHT (~60px). Its sc pills become full
 pills with complete key and value text (no truncation). The undertone wire
  below expands to show EACH .c key as a named tag (key name + typeof value
   without the value, because showing the live ref itself would break the
    fibre-bundle contract: we indicate, never dereference). A parenthetical
     "(c:5)" in the clef zone at overview counts .c refs so the eye can see
      "this particle has five live runtime threads" without following any.

---

## 2. The unifying invariant: the fibre bundle persists

Every focal distance, every layout, every twist for visual effect — the BUNDLE
 is intact. Specifically:

- **Mainkey is always first, always the clef side.** You cannot misread which
   key is the type key. It is structurally separated by the double-bar.
- **Sc is always the staff body.** Never on the left of mainkey, never below
   the wire. The sc k:v pairs are the believed structure and they live in the
    believed-structure zone.
- **.c is always below the staff, always muted.** It cannot sneak onto the sc
   body. The wire is always visible (even empty = blank wire). This prevents
    the commonest cognitive error when reading live C trees: assuming what you
     see snapped IS all that exists. The undertone wire says: "there is
      runtime state below this. Here is how much."

No other layout may be called a C** score if it breaks this order. This is
 the invariant that makes it an honest rendering rather than a pretty one.

---

## 3. The honesty channel — "twisted for effect"

The renderer MUST be able to bend the true structure for visual effect and
 MUST signal that it has done so. Three classes of twist, each with its own
  mark:

```
Normal:    ════════════════════════════════  (full staff, sc intact, .c wire)
Collapsed: ━━━━━━━━━━━━━━━━━━━━━ ▸ 42      (thin rule, triangle, count)
Re-parented: ─·─·─·─·─·─·─·─·─·─           (dashed staff = not its true parent)
Size-exaggerated: ══════════════════════════════════════════  (extra bold, !)
```

- **Collapsed subtree** — a parent with more than N children may collapse its
   children to a single **▸ N** indicator appended to its own staff's right
    edge. The triangle IS the honesty mark: a viewer sees "there are 42 more
     here, I have not been shown them." Pressing ▸ expands. The count is ALWAYS
      shown — "… more" silently hiding content is the expensive kind of lie
       (TreeFace already says this; we inherit the doctrine exactly).
- **Re-parented staff** — Cello's template sometimes moves a satellite particle
   into a spatial slot that is not its C-tree parent (e.g. Door rendered beside
    Radio even though their tree position is Mundo → Door). When Cello universal
     mode renders such a particle, its staff gets a DASHED style and a
      `(∈ Mundo)` parenthetical at the clef zone — "I am shown here for layout
       but I actually live there."
- **Size-exaggerated staff** — if dose_drives (Matstyle) has inflated a particle
   beyond its information warrant (e.g. a Radio with one sc key rendered huge
    because it is the active focus), the staff carries a `!` badge at the right
     edge in the clef colour. "This is bigger than its data; focus has been
      applied."

These marks together ARE the honesty channel. A viewer who learns to read them
 knows EXACTLY what the renderer did — and can therefore trust what is NOT marked
  as a faithful transcription of the C tree.

---

## 4. Faces vs faceless — the two-regime rule

**Bespoke Face (GLASS_KINDS entry):**
The staff's sc notation field is REPLACED by the Face component itself, mounted
 in the standard slot (same `<Face n={source} H={H}/>` contract). The clef zone
  and undertone wire remain: the Face draws MEANING, but the fibre is still there
   below it. The Face is like a fermata or a direction written above the staff —
    it overrides the note-by-note reading for that bar, but the staff line and
     the undertone wire are still drawn.

**Faceless (TreeFace):**
No replacement. The sc pills render. This is the default for any mainkey not in
 GLASS_KINDS. TreeFace's existing doctrine is honoured: bounded depth, explicit
  "… N more", never follows .c. The staff scheme makes TreeFace more honest than
   it was in isolation: the undertone wire now shows .c keys even for faceless
    particles, making the "c:5" count visible at a glance without TreeFace needing
     to change its own walking logic.

The boundary between the two regimes is legible in the rendering: a Face-mounted
 staff has the mainkey bar present but the sc field is REPLACED (no pills), a
  small `⌖` icon at the right of the mainkey bar signals "bespoke face active,
   sc not shown raw." A hover on `⌖` pops the sc pills temporarily ("show sc
    anyway") — this is the hatch the fibre-bundle invariant requires: you can
     always get back to the raw data.

---

## 5. Field-level grouping — the section bars

A score has section bars (double bar across all staves). Here, the C tree's
 natural groupings generate them:

- **H: (House) boundary**: a thick left-margin bar in indigo running the full
   height of the House's staff group. Houses are the town districts (§2,
    Homethink). Their bar is the district wall.
- **w: (world) boundary**: a medium bar in the world's Matstyle colour.
- **A: (actor) group**: a lighter bar in grey.

These bars are NOT indentation — they run in the LEFT MARGIN alongside the
 clef zone and signal GROUP MEMBERSHIP without consuming horizontal space in the
  sc field. A reader at overview distance sees coloured margin bars = district
   structure; at reading distance sees the bars + clef = "this staff is a Door
    particle inside the w:Lies world inside H:LeafFarm."

The bars obey the honesty channel: if a particle is re-parented (shown out of
 its true group), its margin bar is DASHED in the true group's colour rather
  than the displayed group's colour.

---

## 6. Colour and density — the Matstyle register

Every mainkey already has a Matstyle swatch (`matstyle:<key>` under The/Styles).
 The score uses exactly that palette — no new colours invented. The clef jewel IS
  the swatch jewel. The sc pills are tinted at 20% opacity of the mainkey colour,
   so the WHOLE staff reads as kin to its clef without competing with it.

Density (sc key count) maps to staff height:
- 0–2 keys: thin (8px staff body + 6px undertone = 14px row)
- 3–5 keys: medium (14px staff body + 6px undertone = 20px row)
- 6+ keys: full (20px staff body + 6px undertone = 26px row)

This makes information density VISIBLE before any key is read. A dense particle
 stands taller. An empty particle is a hairline. The field as a whole is a
  density topography — you navigate toward the fat staves because that is where
   the structure lives.

---

## 7. The sc pill vocabulary — seven glyphs

The sc notation field uses exactly seven pill shapes, covering every sc value
 kind TreeFace needs to express:

```
 ◆ key          — boolean flag (value=1/absent), open diamond, mainkey colour tint
 ▣ key:value    — short string (≤12 chars), filled pill
 ▣ key:value…   — truncated string (dashed right edge, tooltip shows full)
 ▣ key:[obj]    — object-in-sc (MINT BUG marker: pill in red, ⚠ prefix)
 ⬡ key:∅        — null/undefined value (muted hexagon, "nothing here")
 ▣ key:1234     — numeric-looking string (pill with monospace font, right-aligned value)
 ◈ key:…        — key present, value too long to show inline (icon only, hover expands)
```

These seven are exhaustive for the C model. An `undef` marker in sc (the mint
 bug brand — Text.svelte `objecties.undef`) gets the red pill with ⚠ — exactly
  what TreeFace already signals for "⚠object-in-sc", now consistent across
   both regimes.

---

## 8. The render seam — wiring to the live system

No new infrastructure. The score mounts through the standard UI particle seam:

```
// in a CelloUniversal ghost's plan(w):
let uis = this.oai_enroll(this, { watched: 'UIs' })
uis.oai({ UI: 'CelloUniversal' }, { component: CelloUniversalui })
```

`CelloUniversalui` receives `{ H }` — the commissioning House — exactly as
 Cellui does. It scans the commissioned world's C tree via Travel (the same walk
  `enWaft` uses for the snap), not an ad-hoc recursive descent, so the walking
   logic is already field-tested.

**Reactive updates** drive off `H.version` (the same $effect path Cytui uses)
 so the score is live — a particle added or changed in the world repaints its
  staff on the next tick.

**Face resolution** is identical to Cello's:
```
const mk = Object.keys(row.sc)[0]
const kind = row.sc.face || FACE_MAINKEYS[mk]
const Face = GLASS_KINDS[kind]
const source = row.c.source_n ?? row
```
The same GLASS_KINDS registry, the same `<svelte:boundary>` guard, the same
 `source_n` backlink convention.

**cello_blob** is NOT used here — the score is rectilinear by design, not
 blobby. It is the COMPLEMENT to Cello's organic blobs: Cello renders a few
  particles beautifully; CelloUniversal renders the WHOLE tree honestly. They
   are siblings, not variants.

---

## 9. The smallest provable slice — one staff

Before any field logic, prove the visual language with a SINGLE PARTICLE rendered
 as a staff in isolation (e.g. inside a Otro dev-route panel):

```
Input:  a %Radio particle with sc = { Radio:1, src:'…/Oren Ambarchi.mp3', active:1 }
         and .c = { up: <House>, source_n: <Record> }

Output:
 ┌──────┬──────────────────────────────────────────────────────────────┐
 │ gold │ Radio  ║  ◆ active  ▣ src:…/Oren Ambarchi.mp3             ⌖ │  ← sc field
 │──────┤        ╫──────────────────────────────────────────────────── │
 │      │        ║  ≋ up  ≋ source_n                        (c:2)   ║ │  ← undertone
 └──────┴────────╨──────────────────────────────────────────────────╨─┘
          clef     mainkey│                             │icon+raw hatch
```

Checklist for "slice is proven":
- [ ] clef zone shows Matstyle gold for Radio
- [ ] double-bar separates mainkey from sc pills
- [ ] `◆ active` renders as open-diamond (boolean flag)
- [ ] `▣ src:…` renders as filled pill with truncation marker
- [ ] undertone wire shows 2 muted blocks for `up` + `source_n`
- [ ] `(c:2)` count visible at clef right
- [ ] `⌖` icon triggers sc-raw pop when pressed (even if Face is mounted)
- [ ] no .c dereference anywhere in the component

The slice is a self-contained Svelte component — no Cello dependency, no Cyto
 dependency. It proves the fibre-bundle invariant before the field-level logic
  (grouping bars, Travel walk, Matstyle integration) is added.

---

## 10. ASCII field sketch (reading zoom)

```
 ┌── H:Mundo ──────────────────────────────────────────────────────────────────┐
 ║indigo│ House  ║  ◆ root                                           (c:3)  ║  │
 ║─────┬┤        ╫─────────────────────────────────────────────────────────── │  │
 ║     ││        ║  ≋ UIs  ≋ tick  ≋ mutex                                  ║  │
 ║─────┘│                                                                       │
 ║w:Story colour│Story  ║ ◆ running  ▣ phase:beliefs  ▣ step:3/7    ⌖  (c:4)║  │
 ║──────────────╫──────────────────────────────────────────────────────────── │  │
 ║              ║ ≋ H  ≋ tick  ≋ client_w  ≋ last_step                      ║  │
 ║              │                                                               │
 ║       indent │  Step  ║ ▣ n:3  ▣ dige:131313  ◆ ok              (c:1)  ║  │  │
 ║              │──────────────────────────────────────────────────────────── │  │
 ║              │          ≋ H                                               ║  │  │
 ║              │                                                               │
 ║       indent │  see  ║ ▣ claim:music is playing          ▣ beat:3  (c:0)║  │  │
 ║              │──────────────────────────────────────────────────────────── │  │
 ║              │          [blank wire — no .c refs]                         ║  │  │
 ║─────────────────────────────────────────────────────────────────────────── │
 ║w:Radio colour│Radio  ║ ◆ active  ▣ src:… ▣ vol:0.8  ⌖ RadioFace (c:2)║  │
 ║──────────────╫──────────────────────────────────────────────────────────── │  │
 ║              ║ ≋ up  ≋ source_n                                          ║  │
 └───────────────────────────────────────────────────────────────────────────┘
```

Legend:
```
║  double bar      — mainkey / sc boundary (the type|structure divide)
◆  open diamond    — boolean flag (value=1, key IS the claim)
▣  filled pill     — string k:v
≋  undertone block — one .c ref (muted, colour by ref kind)
⌖  face icon       — bespoke Face mounted; sc shown only on tap
▸N collapsed       — N children hidden (tap to expand)
```

---

## 11. Why this is not the obvious answer

Three things the "obvious" rendering would do that this scheme refuses:

1. **Tree with expand/collapse arrows only.** TreeFace is that; it already
    exists. The score adds DENSITY VISIBILITY (staff height), UNDERTONE
     SEPARATION (the .c wire is always drawn, never folded into "c:N" only),
      and the GROUP BAR system — none of which TreeFace has, none of which
       a bare indented tree can carry.

2. **Graph nodes.** Cyto/Vyto are that. Nodes don't show sc k:v inline;
    they show a Face. You cannot read the fibre bundle from a node — you see
     the meaning rendered, not the clay. The score shows both: Face for those
      that have one, sc pills for those that don't, and the undertone wire
       ALWAYS regardless.

3. **Tiling voronoi blobs.** Vyto is that. Beautiful and organic; terrible
    at showing sc field content (pills don't fit in an irregular polygon) and
     impossible to read at field scale without knowing which blob is which.
      The score sacrifices the organic geometry for readability of the language.

The score's genius is not the visual itself but the DOCTRINE it encodes:
 the C** model has three layers and they must ALWAYS render in three
  dedicated zones. Any rendering that merges them (Face hiding sc, sc hiding
   .c, collapsed children presenting as "that's all") is lying. The staff
    score is the first rendering where lying is structurally prohibited.
