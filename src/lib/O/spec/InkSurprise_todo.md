# InkSurprise — ink islands + surprise-breaks

*The next Cello: the population renderer.*

## 0. What to get on with next

The prototype is live at `/ink/islands`.  It renders synthetic C particles as layered
 ink-islands and is directly openable in the browser.  The `/ink` route (the single-particle
  proof) links to it.

What to get on with, in order:
- **Wire a live H.** InkSurprise currently synthesises demo particles; passing a real `H`
   prop and scanning its world with `Travel` would show the RUNNING machine through the same
    lens.  The island computation is pure — swapping the particle source is the only change.
- **Make the resolve() rules interactive.** The "playthings" panel at the bottom names the
   rules (`o({Record:1})`, `exactly(sc)`, `n_matches_kv`) — make them LIVE: let the user
    type a query and watch the ink-island re-form around the matched population.  That is
     the "mesh spewer" the owner asked for.
- **Continuous island geometry.** The current layout is a flex-wrap of blob-clipped divs.
   The owner's vision is a large continuous body on which inks LAYER: particle positions
    should be stable (seeded by id) and island boundaries should be SVG `<path>` blobs that
     OVERLAP when a particle belongs to two inks at once (e.g. mainkey ink + shelf ink +
      grant ink).  This is the multi-layer painting step.
- **Surprise-break tearline.** When a surprised mote exceeds ~0.6, draw a visible tear/
   crack in the island outline at that mote's position — the island is literally breaking
    where the anomaly lives.  This is the most direct visual expression of "islands of
     surprise".

---

## The arc

InkSurprise is the population face of the residual lens.  Where `ResidualMote` (at `/ink`)
 proves that ONE particle can be drawn by surprise alone, InkSurprise proves that a
  POPULATION of particles — grouped by how they resolve() — forms a continuous visual field
   where expected particles are texture and anomalies are events.

The two together answer the owner's question about "the next Cello":
- Cello is the TEMPLATE renderer (one main cell + satellites, blob charm, Face mounting).
- InkSurprise is the FIELD renderer (populations as ink-islands, resolve() rules as the
   grouping principle, surprise as the ink rule).
- Both wear the residual LENS (ink ∝ surprise), but at different scales: Cello at the level
   of which Faces to mount and how much chrome to show; InkSurprise at the level of which
    particle populations to treat as one visual body.

---

## The ink-island model

An **ink** is a continuous region of shared style/idea on the canvas.  It is NOT a layout
 grid or a list — it is a FIELD, like an ink-wash painting, where the boundary of the region
  is organic (a cello_blob outline) and the interior has a faint, characteristic tint.

Concretely, one ink = one resolve() query result:
- `o({Record:1})` → all particles with a Record key → one blue-tinted ink-island
- `o({req:1})`    → all reqs → one amber-tinted ink-island
- `o({Card:1})`   → all Cards → one violet-tinted island

A particle can belong to MULTIPLE inks simultaneously (its mainkey ink, its shelf ink, a
 grant it holds) — multiple islands OVERLAP at its position like transparent paint layers.
  The overlap is where the ink is richest, not where it clashes.

### Why this is "expose resolve() to the max"

The matching rules that govern `o()` / `oa()` / `oai()` / `n_matches_kv` ARE the playthings:

- **Numeric 1 = presence wildcard**: `o({Record:1})` matches ANY particle that has a Record
   key, whatever its value.  The island is all-Records.
- **String value = exact match**: `o({state:'ok'})` matches only ok-state particles.  The
   island is only the passing reqs — a different, tighter cut.
- **`exactly(sc)` footgun**: `exactly({req:1})` stringifies to `{req:"1"}` — a literal match
   on the VALUE "1", not a wildcard.  A well-formed req has `req:'abc'` (a serial), not `req:1`
    — so `exactly` makes the island EMPTY.  Making this footgun visible (the island evaporates
     when you toggle `exactly()`) is an educational UI win.
- **Missing key = miss**: `o({of:1})` matches only particles that CARRY an `of:` key — Spin,
   Like, Heist, req — and excludes Records and Cards.  The island is the "referring" particles.

An interactive version of InkSurprise would let the owner type a query in the resolve() panel
 and watch the ink-island re-form around the match in real time.  The canvas IS the query
  result, made continuous.

---

## The surprise-break rule (ink ∝ surprise, made continuous)

Within each ink-island, each particle occupies a position (seeded by its id, stable across
 renders).  Its **surprise** — a cheap O(1) distance from the population norm — controls how
  much ink it spills:

```
surprise(n) = w_k · jaccard_miss(keys(n.sc), Norm.keys)
            + w_c · band_dist(|n.c|, Norm.c_band)
            + w_w · wound_terms(n)   // forced-high: undef, finished req, object in sc
```

- `surprise ≈ 0`: the particle is a faint mote — barely visible, absorbed into the island's
   texture.  It IS the expected.  Multiple expected particles together form the island's calm
    body.
- `surprise ≈ 0.5`: the particle blooms partially — a slightly larger, darker mote with a
   label or one deviant-key pill visible.  The island's surface has a small bump.
- `surprise ≈ 1`: the particle blazes — full-size, dark, with anomaly-pill labelling.  The
   island has a TEAR at that position: the anomaly is legible and seizes the eye.

This is the same rule as `ResidualMote` (at `/ink`) — InkSurprise simply renders it at the
 population scale rather than the single-particle scale.

### Hard wounds (forced-high surprise)

These map to `surprise = 1.0` unconditionally:
- `path: undefined` in sc — the undef mint-bug (CLAUDE.md: "a mint bug, not furniture")
- `finished: 1` on a `%req` that hasn't been dropped — the undropped-finished-req antipattern
- An object/function value in `.sc` — the fatal-at-encode wound
- A `.c` weight far above the norm band — foam

The point: the renderer CANNOT lie about wounds.  A wound fires at maximum darkness by the
 same rule that keeps expected particles pale.  There is no separate "error colour"; honesty
  and compression are the same mechanism.

---

## How InkSurprise relates to Cello / the residual lens

InkSurprise is the residual lens rendered as CONTINUOUS FIELDS rather than discrete motes.

- **Cello** renders the FOCUSED view: one main cell (a Face, large, organic, blob-charmed)
   + satellites.  It is the foveal lens — the "what am I looking at right now" renderer.
    Residual surprise in Cello would choose how much of the Face to show and whether the
     blob outline has a distortion warp.
- **InkSurprise** renders the AMBIENT view: populations as fields, anomalies as surface
   events.  It is the peripheral lens — "what is going on in this world" at a glance.
    Residual surprise in InkSurprise is the whole substrate: the ink is surprise, the island
     is normalcy.

The two are composable: a Cello cell is the fovea you drill into from an InkSurprise field,
 and an InkSurprise mote is the thumbnail a Cello cell collapses to when it leaves the main
  slot.  Together they are the foveal-lossless + peripheral-residual eye that the synthesis
   doc (Cello_synthesis_todo.md §R.1) describes.

---

## ASCII diagram of the canvas

```
  ┌─────────────────────── ink canvas ──────────────────────────────────┐
  │                                                                      │
  │   ╭─── %Record ink (blue tint) ──────╮                              │
  │   │  ·  ·  ·  ·  ■■■WOUND■■■  ·  ·  │   ← expected = faint dots    │
  │   │  ·  ·  ·  ·  ·  ·  ●foam  ·  ·  │   ← wound = dark blazing ■   │
  │   ╰──────────────────────────────────╯   ← foam = mid-bloom ●       │
  │                                                                      │
  │   ╭── %req ink (amber) ──╮  ╭── %Card ink (violet) ──╮             │
  │   │  ·  ·  ·  ·  ·  ■   │  │  ·  ·  ·  ●extra  ·   │             │
  │   │  (undropped finished) │  │  (bonus_field surprise) │             │
  │   ╰──────────────────────╯  ╰────────────────────────╯             │
  │                                                                      │
  │   ╭─── %Spin ───╮   ╭─── %Like ──╮   ╭─── %Heist ──╮              │
  │   │  ·  ·  ·  · │   │  ·  ·  ·  │   │  ·  ●  ·    │  ← missing  │
  │   ╰─────────────╯   ╰───────────╯   ╰─────────────╯    'at' key   │
  │                                                                      │
  │   [resolve() rules panel — the exposed playthings]                  │
  └──────────────────────────────────────────────────────────────────────┘
```

The island outlines are `cello_blob()` polygons — same charm as Cello cells, same seeded
 determinism.  They are calm where the particles are expected; a future version tears the
  outline at the wound's position.

---

## Files

- `/app/src/lib/O/ui/InkSurprise.svelte` — the component (self-contained, demo particles)
- `/app/src/routes/ink/islands/+page.svelte` — the route (open at /ink/islands)
- `/app/src/routes/ink/+page.svelte` — links to /ink/islands from the ResidualMote proof
- `/app/src/lib/O/ui/ResidualMote.svelte` — the single-particle proof (the atom this field is made of)
- `/app/src/lib/O/cello_blob.ts` — the blob clip-path primitive (reused for island outlines)
- `/app/src/lib/O/spec/Cello_synthesis_todo.md` — the lineage this continues
