// Voro.g — the Vis family home: the Voronoi-Cyto render (Ghost/V/, Waft:Ghost/Vis/Visua).
//  A late sibling to networking (N), music (M) and society (S).  But where THOSE are spines the
//   runner RUNS, Vis is a lens the runner LOOKS THROUGH — so there is almost no runtime here.
//    The render itself lives in the widget (src/lib/O/Cytui.svelte) because it is pixels over the
//     live Cytoscape canvas, not particles; this ghost is the family's prose home and its
//      canonical reference data, and the Waft:Ghost/Vis/Visua overlay hangs the real Docs
//       (Cytui, Cyto, the crush in Musuation.g) off the Points below.
//
// The idea (see also the memory voronoi-cells-render):
//  Cyto stays the LAYOUT engine — fcose decides where the crushed chunks want to sit — and the
//   render REINTERPRETS that result.  Each %stuff chunk seeds a cell at its node's rendered
//    position, weighted by its content box (a power diagram, so a big chunk claims more room),
//     and its Stuffing is molded into the cell.  Adjacency reads as shared WALLS not wires: an
//      SVG layer between the canvas and the HTML overlays draws the cells over a dimming veil.
//  Orderless siblings would grid-jitter under a pure force sim, so a hidden NUCLEUS per parent
//   gathers them into a radial flower (a rosette that voronois cleanly) — scaffold only, never a
//    cell, never snapped.  It auto-arms when a wave ferries a crusher-stamped particle (c.stuffy,
//     minted only by the %crushCyto-gated crusher); the ◈ bar button overrides either way.
//
// The render pipeline (all in Cytui.svelte): voronoi_layout → install_nuclei (the flower) →
//  morph_voronoi (the cell-division tween) / voronoi_paint_now (the live-drag twin) → paint_final
//   (the vectorised rest state: cells, edge-braces IN the border, the molded Stuffing).

//#region reference — the canonical Voro sets, as data (a nav aid + a future sweep target)

// Voro_books — the Books that exercise this render: each opts %crushCyto, so the crush stamps
//  c.stuffy and the voronoi mode auto-arms.  MusuMitosis is the pure demo (a cell colony that
//   divides — an NZ-flora phylogeny); MusuScape folds a shared library to glass; MusuReco and
//    MusuReplica fold real streaming/replication data.
Voro_books():
    return ['MusuMitosis', 'MusuScape', 'MusuReco', 'MusuReplica']

// Voro_render_map — the Cytui render stages in order, so a reader can walk the pipeline.
Voro_render_map():
    return ['voronoi_layout', 'install_nuclei', 'morph_voronoi', 'voronoi_paint_now', 'paint_final']

//#endregion
