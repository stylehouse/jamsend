---
name: voronoi-cells-render
description: "Cytui voronoi render mode — Cyto stays the LAYOUT engine, an SVG power-diagram tessellates the viewport from stuff-node rendered positions and Stuffings stretch into cells; pure pixels (no wave/snap), auto-arms on c.stuffy, ◈ button imposes the crush on ANY graph; crusher = Voro_crush_scan in Ghost/V/Voro.g (CREDULER_GHOSTS), all stamps c-side"
metadata: 
  node_type: memory
  type: project
  originSessionId: f4eec47c-5092-4a7d-a304-39f88375f249
---

**The voronoi cells render (2026-07-04), Cytui.svelte `//#region voronoi`.** The user's pivot off "tight fat edges are hectic": stop asking Cytoscape to also be the renderer — *interpret the result from Cyto*. fcose keeps deciding where chunks want to sit; each stuff-chunk seeds a **power diagram** cell (weight = node renderedWidth/2, so big chunks claim room), computed by hand-rolled half-plane clipping (Sutherland–Hodgman vs each neighbour's radical axis — exact, zero deps, O(n²) fine for ≤~50 seeds; d3-delaunay NOT added). An SVG layer between the cy canvas and the HTML overlays draws a `#070707`/0.5 veil (dims the raw graph — walls, not wires, carry adjacency) + cells filled/stroked in the chunk's Matstyle border colour, 4px centroid-inset gutters. Each Stuffing overlay is stretched into its cell: bbox position/size + `clip-path: polygon(...)`, `maxWidth:none` to beat the 520px cap; flex centering keeps rows mid-cell.

**Why it's safe:** pure pixels — no cy style writes, no wave or snap involvement, so no Book can see the mode (Leaf* keep checking Cyto basically works). Auto-arms when a wave entry's `c.source_n.c.stuffy` is set (only the %crushCyto-gated crusher mints those — [[musureplica-crush]]); ◈ bar button overrides either way, stashed as `Cyto_voronoi` (null = auto). `wave.sc.absolute` resets the auto-arm.

**Load-bearing gotchas:**
- **size_stuff_node MUST bail in voronoi mode** — the cell sets el size, the ResizeObserver would feed cell-bbox → node.style width → seed weight → bigger cell: a runaway loop. Node sizes freeze at last content-driven values (still the layout/weight input); content changes just `voronoi_soon()` re-tessellate.
- Cells recompute ONLY on the overlay quiet cadence (show_overlays_soon timer, after reposition_overlays) — same anti-energise discipline as [[cyto-node-stuffings]]'s waitCyto lesson.
- During wave motion the whole SVG hides with the overlays (`motion_hidden`) → raw graph shows brightly mid-animation, cells settle back at quiet. Deliberate v1; if the pulse annoys, split the veil out of the visibility toggle.
- A seed whose cell is swallowed by a heavier neighbour falls back to plain node-centering.

Verified live: run 9eb8f897, 14/14 green on MusuReplica. Next iterations the user floated: rounder/organic cell shapes, and this was always "perhaps svg at that point" — the door to leaving cytoscape rendering entirely.

**Round 2 (same day), all in the same region:**
- **Maximal fit**: each Stuffing scales to fill its cell. Closed form, no search: an axis-aligned w×h box centered at c fits a convex cell iff for every wall (outward unit normal n̂, `room` = distance c→wall) `s·(w/2·|n̂x| + h/2·|n̂y|) ≤ room`; s = min over walls. Applied as `translate(centroid−bboxcenter) scale(s)` on el.firstElementChild — transform doesn't touch offsetWidth so NO ResizeObserver feedback; floor 0.5, cap ~3.2, 0.92 margin. Needs `:global(.stuff-overlay > *) { flex: none }` or flex shrinks the child to the bbox and spoils the natural-size measure.
- **Braces**: an edge renders as a curly brace kissing the wall it crosses — segment seed→otherEnd exits the convex cell through exactly one wall (seg_hit per wall); brace arms lie inside at depth 7 parallel to the wall, tip AT the crossing; coloured by the OTHER end (cells: border-color, spine: background-color). Chunk↔chunk edges give facing pairs across the gutter = junction glyphs.
- **The rack**: the un-fitting subset (non-parent, non-cell = spine equipment) is hauled to a label-sorted column pinned at the right edge via renderedPosition writes at quiet cadence (re-racks each settle, stays docked through pans); the veil rect covers only the tessellated region (vregion_w) so the rack stays bright — "Voronoi the most sense-making stuff". Guard: bail on <2 seeds BEFORE hauling, else a manual toggle on a non-crushed graph racks the whole graph.
- ~~MusuReco turned on~~ REVERSED in round 4 — see below.

**Round 3 (2026-07-04):** flower-wireframe **nuclei** (hidden hub per parent + star spokes to edgeless children so fcose seats orderless siblings as a rosette — pure cy scaffold, excluded from seeds/rack/braces, `paint_final` skips `data('nucleus')` edges); zoom-reveal fixed via the **`overlays_want_show` latch** (whichever morph lands last clears it — the per-morph callback was killed by superseding morphs); **adaptive drag** (overlays stay live per frame, EMA of repaint cost vs 9ms budget, shed to hide-all for the rest of that drag); radial-smudge fcose overrides in voronoi mode (repulsion 9000, separation 60, gravity 0.12, gravityCompound 0.5).

**Round 4 (2026-07-05) — the luxury-layer flip.** The crusher MOVED to `Ghost/V/Voro.g` (`Voro_crush_scan/walk/crushable/clear`, in CREDULER_GHOSTS; drives call it cross-ghost via flat eatfunc). Every stamp went **c-side**: `c.stuff` = the fold (Cyto descent-suppression + `folded` skin read `sc.stuff || c.stuff`), `c.stuffy` = the skin — NOTHING snapped. **◈ imposes**: on an un-crushed world `toggle_voronoi` elvistoes `Cyto_crush {on:1}` → `e_Cyto_crush` (Cyto.svelte) arms `Scannable.c.crush_wanted` → `cyto_update_wave` runs the crusher before every scan; off strips via `Voro_crush_clear`. Editor lacks Voro.g (no CREDULER_GHOSTS there — Auto.svelte:269 "Editor needs none") so ◈ imposition logs + stands down outside runners. **MusuReco de-opted** — the imposition example.

**Round 6 (2026-07-05) — scape UI + docs.** Two Cytui bar changes (pure pixels, no snap impact): (1) **Vexpandy** — use the STANDARD `$lib/O/ui/Vexpandy.svelte` block-mode V-toggle (NOT a hand-rolled `⇕`; owner corrected me) `bind:expanded={tall}` → `.cytui` gets `class:tall` → `.cytui.tall { height: 100vh }` (was 50vh, vh-relative); a `$effect` re-fits (`cy.resize()`+`cy.fit`, skip-initial via `tall_settled`) after the toggle. (2) **Overlays kept LIVE through the layout wave** — `layoutstart`→`start_live_layout()` (reuses drag_frame budget self-heal via a `live_layout` flag) instead of `hide_overlays_now()`; `layoutstop`→`stop_live_layout()`+settle; apply()'s brief pre-mutation hide stays (kills the 0,0 flash). The once-disputed "Stuffings stay visible while animating" claim was CONFIRMED by the owner from the live tab 2026-07-06 ("stays beautifully glidy"). Scape docs wrangled: `Radio_spec.md §8` rewritten to current reality; new residence doc **`Radio_scape_handover.md`** (arc + bombs + next move).

**Round 7 (2026-07-06) — motion unification + hand-safety + the grind list.** (1) `pan zoom` now drives the SAME live loop (`pan_zoom_motion` + `live_motion` flag; a wheel burst has no stop event, so a quiet-timer stops the loop) — scroll-to-zoom no longer blanks Stuffings. (2) The settle-jump this exposed (Stuffings flashing to their node then back after every gesture) fixed at the root: `reposition_overlays` SKIPS a cell-molded Stuffing (`el.style.clipPath` set) — paint_final owns those; clear_voronoi strips clipPath first so un-molding still repositions. (3) **Scroll visor** = glass over the right edge: intercepts the wheel (page scrolls, cy can't zoom) + blocks drags; lights on wheel, fades after; in voronoi mode its width ALIGNS to the rack strip (`max(12%, calc(100% - vregion_w px))`), 25% on a plain graph. (4) **Middle-drag pans** from anywhere (`middle_pan_down` on the graph-wrap: pointer capture + `cy.panBy`; cy ignores non-primary buttons so no grab fight; fires 'pan' so the live loop tracks). (5) **`src/lib/O/spec/Voro_todo.md`** = the graded grind list (wrap-width from cell, angle, fold colour|size, family outlines, crush-harder grouping, in-cell microcosms, pinch|spread locale, SVG Stuffing rebuild) with the metaphysics up top — briefed for lesser-model cold pickup.

**Round 8 (2026-07-06) — rack shelved + visor demoted to a guard + canvas story-stepping.** (1) The **rack is SHELVED** behind `RACK_ON = false` in `voronoi_layout()` (owner: "looks great without it — the oddballs can just be included"); CW = W, cells tessellate the full width, veil full-bleed; kept un-deleted as the seed of a future in|out-group process option. Metaphysics §1 now has ZERO layout-write exceptions. (2) The **visor is pure pixels** (`pointer-events:none`, fixed 20%): the wheel-steal moved to `visor_guard`, a capture-phase wheel listener on the graph-wrap — `stopPropagation` beats cy's container listener, NO preventDefault so the page scrolls; clicks/drags in the strip pass through (the round-7 untouchable-rack tension dissolved). It STANDS DOWN when the page can't scroll (`document.scrollingElement` probe), so full-bleed BigSoundland wheel-zooms with no prop or mode. (3) **←/→ on the focused canvas walk the story pips** like Storui's strip: Storui publishes `story_nav(dir)` on `H.c` (re-published each mount, HMR-safe; nothing open → enters at the END) and it routes through `pick()` so `last_user_pick` makes the re-assert effect see its own echo — a second `story_sel` writer WOULD get re-asserted away, that's why it rides Storui's pick. Cytui wrap: `tabindex=-1` + focus parked by hand in `wrap_pointerdown` (cy preventDefaults mousedown, native click-focus never lands). All browser-unverified.

**Round 9 (2026-07-06) — the grind list mostly LANDED (all browser-unverified).** Todo tasks 1-4 BUILT in Cytui: (1) wrap width from the cell (24px-quantised off cell bbox, >15% hysteresis via `wrap_applied`, settle-only); (2) molding angle — T = R(θ)·S, |θ|≤20°, snap-0 under 8°, gated on elongation>1.18; `box_support` grew T21 (defaults to T12 so symmetric callers exact); CSS matrix is column-major (a,b,c,d)=(T11,T21,T12,T22); (3) fold colour+size — crusher stamps `c.fold_kind`/`c.fold_n` (`Voro_stamp_fold`), Cytui `cell_color` reads Matstyle READ-ONLY (o() query, NEVER get_or_create), seed floor lifts log2(1+n)·9; (4) ⬡ family hulls — post-hoc `edge_src` wall attribution (midpoint vs kept cut lines — NO clip_halfplane rewrite), families = compound ancestor one-below-w with ≥2 cells, boundary walls as disjoint faint segments, stash `Cyto_families`. Task 5 PART: `Voro_swarmable` folds a structural container whose children are a homogeneous noisy swarm (≥3 same-mainkey req|witnessed|see; w/H/A never); OPEN: leaf sibling-gangs + dominant-share loosening. Gen recompiled via **LocalGen** (editor tab down — ghost-compile timed out; live flock runs the OLD crusher until human reload). New besides the todo: **❝ properCellable** — `entry.c.source_n` now rides EVERY wave upsert (Cyto make_wave widened, c-side), Cytui `node_src` map + `proper_mounted`; a %see gets a self-row Stuffing (+cell, since stuff_mounts seed) with node label blanked; stash `Cyto_properCellable`, default follows voronoi mode. **wheelSensitivity: 2** (owner: zoom scroll more sensitive). Designs written for 6/7/8: `Voro_microcosm.md` (NO second w:Cyto/channels — crush only suppressed descent, members are fold.o(); grid microcosm → hysteretic zoom-swap → pixel-capped recursion), `Voro_pinch.md` (gaussian brush, fcose undoes it, play-mode), `Voro_svg_stuffing.md` (tuple rows w/ stable rids, char-metric widths kill DOM-measure feedback, greedy per-wall matching over edge_src, walls never move for rows).

**Round 5 (2026-07-05) — Voro family + model-clean.** The two demo Books **RENAMED + MOVED into Voro.g**: `MusuMitosis`→**VoroMitosis**, `MusuScape`→**VoroScape** (world-name dispatch is ghost-agnostic — `do_fn_for` reads `w.sc.w` — so `VoroMitosis(A,w)` in Voro.g just works). Book dirs renamed `wormhole/Story/Voro{Mitosis,Scape}`, stale fixtures + Credulate/Credulation cleared for fresh live re-record. **`%Crush_Tree` report particle DROPPED entirely** (was the last thing the crush snapped) — fold totals come back as live `{folded,count}` stats returned by `Voro_crush_scan(w)` (accumulated in the walk); MusuReplica witness reads those, no `report` arg any more. **Crush + Opt OUT of the model**: the two demo Books arm the crush **c-side** (`w.c.crush_wanted=1` in seed/library) instead of the `%crushCyto` opt → nothing pushed to `w/%Opt` (only `For/w:` opts get pushed, and crushCyto was the only one) → no `%Opt`, no `%Crush_Tree`, zero crush trace in the snap. **Botanical keys**: VoroMitosis species are keyed BY GENUS (`{Coprosma:'robusta'}` not flat `%spore`) so the fold's Stuffing groups by genus; a split re-keys the daughter half to the new genus. MusuReplica stays a Musu Book (keeps `%crushCyto` opt, uses the shared crusher). Credence What:Voro → VoroMitosis+VoroScape (both brand_new); Visua Waft + BigSoundland default (`?B=`) → VoroScape. All 3 crush Books owe live re-records; :9091 verify owed. Open Q the user floated: chunk **node-size accentuation** (fold-count→size) and per-genus chunk COLOR (color a fold by its dominant child mainkey/kind) — NOT built, offered.

**Round 10 (2026-07-06 pm) — owner's first eyes-on, two reaches + TODOs.** Owner ran the render and reported: (a) `Opt/crushCyto` nodes still visible — FIXED by `cytyle_classify` now `skip`ping `%Opt` (Cyto.svelte); it's config scaffolding (VoroMitosis toc still declares a vestigial `Opt/crushCyto` though the seed arms `w.c.crush_wanted`; MusuReplica keeps its opt for real — model unchanged, only render drops it). (b) Stuffing text tiny + dead gap — FIXED: paint_final was forcing `child.style.width` so a short line measured as a full box and the affine shrank it; now `width:''` (keeps `.cytui-stuff` max-content) + `maxWidth` wrap-ceiling only, 480→360. (c) **family hulls never SHOW on VoroMitosis** — confirmed by reading: every `cell:<genus>` sits directly under `w`, so `family_of` (compound ancestor one-below-outermost, `anc[len-2]`) gets `anc.length===1` → null → `vfams` empty. Needs a shared intermediate cyto-compound; only `w:` classifies as compound today. Owner's "nest child notes in %Coprosma" is one level off (hull groups sibling CELLS, not a cell's interior). TODO'd in Voro_todo §4 with Route A (mint `w:<Family>` — rubs the mint-w rule) / Route B (teach classify a `group:` compound — core, prove isolated). (d) ~9-families / "too much in one screenful / sensible intensity" → Voro_todo §9 (density tuning, live calibration). (e) co-crush scattered `%witnessed`+`%reached` into one cell each = the leaf-sibling-GANG task-5 remainder (owner agrees "a lot more work"). ←/→ nav confirmed built+wired (owner keen — nothing to fix). No `.g` touched → no gen recompile; src edits HMR on human reload.

## Round 11 (2026-07-06): ALL open TODOs built — gang co-crush, governor, hull route C, microcosm a+b, pinch
Owner: "work on all these Voro TODO, even attempt Voro_pinch|microcosm ... aim for ~9 ... hook into Cyto_scan quite early?"
- **Gang co-crush (task 5)**: Voro_gang_fold — loose leaves gather by mainkey per container; ≥3 noisy (req|witnessed|see|reached) elect first member REP (c.stuff + c.gang=[refs]), rest c.represented; cytyle_classify skips represented (one core line, inert without crusher). NOTHING minted/reparented in model. Rep's pane = Cytui gang_stuff MIRROR (free _C, rebuilt on size change).
- **Intensity governor (task 9)**: Voro_crush_scan escalates/relaxes crush level (0-2) on stats.visible (>15 up, <6 down), level rides w.c.crush_level; each pass authoritative (Voro_unstamp). {folded,count} stay PURE container-folds (MusuReplica ratio %see safe); gangs ride {gangs,ganged}.
- **Hulls (task 4) via Route C — no core, no model**: family_of = c.vfamily tag → compound ancestor → model parent (c.up ≠ w/H/A, WeakMap ids). VoroMitosis stamps Botany_family c-side; genera REORDERED (Brachyglottis in, Pseudopanax out) so Myrtaceae trio + Asteraceae pair radiate in reach.
- **Microcosm (6a+b)**: paint_final(L, settled) — settle-only card grid in cell (char-estimate sizes, clip polygon, cap 24 + "+N more"), swap at depth=√cellArea>300, hysteresis ×1.15/×0.85, Stuffing crossfades via opacity. (c) recursion NOT built.
- **Pinch (task 7)**: 🌀 stash Cyto_gravity_brush; brush_wheel in visor_guard tail — gaussian σ140 rendered px, model-coord writes, guards live_layout/compounds/nuclei, 40px frame clamp, rides pan_zoom_motion. Ctrl+wheel = zoom. fcose undoes sculpt (by design).
- Task 8 SVG-stuffing NOT built (owner named only pinch|microcosm; spec still awaits agreement).
- Voro.go recompiled via LocalGen (editor down); SMOKE: VoroMitosis ran 11/11 on live runner (old gen + HMR'd render) — no errors/wedge, reds = stale-fixture diges as expected; run released.
- GATE UNCHANGED: human reloads flock tab → re-record VoroMitosis/VoroScape/MusuReplica → eyes-on: gangs one-pane-each, ~9-intensity, hulls (Myrtaceae/Asteraceae), micro swap at zoom, 🌀 sculpt. Calibrate 15/6 band + MICRO_Z=300 by eye.

## Round 12 (2026-07-06) — Vtuffing: the pane-content engine

Owner eyes-on verdict on the microcosm cards: "woefully underexpressing — they just say
 Track or Share" (member mainkey only; VoroScape titles thrown away), "they vanish when
  we're dragging", "I want a Stuffing data pipeline so eloquently into a C**... maybe we
   call this Vtuffing". Built (design note spec/Voro_vtuffing.md):
- **Vtuff_build (Voro.g)**: distils a fold|gang's members into a FREE layout C** (new
   TheC, unreachable → never snapped): title | shared-fact rows (one distinct value) |
    spread rows w/ value chips ×count | member rows (≤5) | the /*N dip. Cached
     src.c.vtuffing keyed count+Σversions. Extensible per fold-kind: Vtuff_of_<kind>.
- **Chord fit (Cytui micro_fit)**: cells are CONVEX → poly_chord gives one interval per
   height; rows stack, each clamped to its band's top∩bottom chords — text follows the
    slanted walls. Overflow keeps title+head+dip + "+K more".
- **No vanish**: fit runs BOTH cadences (cache + pure math) — paint_final lost its
   `settled` param, micro_hidden deleted. The old blank-pane-mid-drag (Stuffing dimmed
    to 0 AND card layer hidden) is gone.
- **/*N surf (Vtuff_pop)**: member|dip rows are buttons → pop nodes OUT INTO THE GRAPH
   (owner: "not in the Stuffing** itself"). c.popped (leaf never re-gangs, leaf-only
    guard), c.popped_open (container never folds/swarms — crushable/swarmable refuse).
     Intent stamps persist across passes; Voro_crush_clear forgets them. Then one
      cyto_update_wave re-scans. GOTCHA closed: the walk's non-structural else-branch
       never unstamped (never needed to before popped_open) — now sheds stale stamps.
- **▤ toggle** (stash Cyto_vtuffing, default on): off = molded Stuffings at every zoom.
   Owner: "there should be a toggle for all these modulations" — full set now
    ◈ ❝ ⬡ 🌀 ▤.
- **Hull rope**: hull stroke was 2.5px@0.38 UNDER the cell strokes on the SAME walls —
   invisible even when grouping. Now two-pass rope 11px@0.30 + 4.5px@0.55. Owner saw no
    hull also because VoroScape folds sit directly under w (none expected) and
     VoroMitosis vfamily stamps need the new gen (reload gate).
- TS fallback in vtuff_rows until reload (old gen lacks Vtuff_build): title + member
   idents + dip — panes say "Track · Tide" not "Track" even pre-reload.
- Smoke: VoroMitosis 11/11 steps error:null on live runner (dige drift = stale
   fixtures/old gen, expected). svelte-check: only the documented cy-void disease in
    range. Gate unchanged: reload flock tab → re-record VoroMitosis/VoroScape/
     MusuReplica → eyes-on (rows, rope hulls, pop-out, ▤).

## Round 13 (2026-07-06 late): stained glass + surf control + list form + recursion carve

- COLOUR: kind_glass = Matstyle swatch → else kind_hue GOLDEN-ANGLE registry (137.5°/slot,
  first-seen order, the fam_seq pattern; a raw name-hash clustered 5 purples). The old teal
  = the single #79b default fold-border every un-swatched kind fell to. Swapped cells wear
  dotted rim + fuller fill; rows kind_tint. Cytui-only → HMRs live, no reload needed.
- SURF UNDER CONTROL (owner poke found: fold-member pop was a SILENT NO-OP — Cyto's
  no_further stops at a stuffed node, the popped stamp changed nothing). Fix .g-side:
  Voro_crushable/swarmable refuse a fold with popped|popped_open children; Vtuff_pop_stamp
  climbs c.up unfurling the chain (guard 8). Dip = top-K=3 by subtree size; spill relax =
  Voro_gang_fold 4th param (any pop intent among siblings → gang min 2, "rest stays one
  pane"). Un-pop = cxttap (right-click) → Vtuff_unpop (node or hub); contextmenu suppressed
  over canvas only.
- LIST FORM: homogeneous family → title says mainkey ONCE (gang titles by fold_kind, NOT
  rep ident which reads as one member) + row:list of Vtuff_member_bit chips (value|naming
  key, cap 6 + '+N', each chip c.member = its own pop handle); Vtuff_keyrows(root, members,
  skip) skips the family mainkey. Depth-1 row:sub openness for ≤3-member mixed families.
- EXPLODING EDGE mostly free: spilled fold keeps container as plain HUB node; Cyto.svelte's
  non-compound-parent `/` edge rule (line ~523) wires hub→popped + hub→remainder. REMAINING:
  gang directly under w has no hub (w compound) — wants core seam n.c.bond → blue edge in
  cyto_scan_refs, isolation-proof first.
- Two modes of recursion carved in Voro_vtuffing.md: A = same graph (pop bounded + Travel
  Vtuffing openness; AIM FIRST) vs B = subgraph-in-cell (cytoscape can't nest layouts; 2nd
  cy instance or hand-rolled mini-force; defer until A saturates). Wandering-landscape
  answer = intent AGING (beat-stamp popped, brush refreshes, governor folds stalest first)
  — designed not built.
- Voro_svg_stuffing.md reframed: NOT a rival rebuild — the cross-wall alignment LAYER on
  Vtuffing (= agenda #9); Vtuff_build IS its row model.
- Testing delegated to opus subagent (LocalGen + gen grep + svelte-check). Reload gate
  unchanged: .g changes disk-only until tab reload; re-record VoroMitosis/VoroScape owed.

## Round 14 (2026-07-07): one swap rule + name|tag split + 2D lists + trait sprinkle

- HALF/HALF WEIRDNESS root-caused: per-cell hysteresis MEMORY (×1.15/×0.85 around
  MICRO_Z=300) made same-size neighbours differ by zoom HISTORY. Now ONE rule: ▤ on =
  engine owns EVERY fold pane clearing √area ≥ 70px AND fitting ≥1 row; ▤ off = molded
  always. Fixed latent blank-pane bug (next_on.add now AFTER rows-exist check).
- TITLE stutter ('cell: Kunzea ×14' vs 'Artist · Fernway ×2') killed: Vtuff_name splits
  NAME from TYPE; every row = bare name + small kind-coloured .ktag badge (mainkey ≠
  other keys made visible); gang = tag + ×N alone. Properties stay uniform 'key: value'.
- /*N moved out of text into sc.sub → lilac .subn glyph on rows AND chips (matches dip)
  = "has interior, pops with edges" affordance.
- 2D LIST: micro_fit gives a list row ceil(chips/cols) lines (cols = widest-chord/62px,
  cap 5); chips flex-wrap; row.fs = per-LINE font size (not block height). List cap 6→9.
- TRAIT SPRINKLE (owner "all this Stuffing data is one column!"): Voro_hash (FNV-1a, NO
  randomness — fixtures byte-stable); Botany_plant gets %woodystem ~1/3, %habit
  tree|shrub|vine ~1/2 (hash(epithet) — intrinsic), %endemic ~1/6; VoroScape_track gets
  %year spread + %live/%remaster. Simulated seed data confirmed varied not degenerate.
- Gen 46652c compiled clean; svelte-check clean. RELOAD + re-record still the gate.
- OWED next: #1 auto-spill w/*/** (keystone; needs auto-vs-manual intent tags so
  right-click un-pop sticks against a re-popping governor), #5 hull nudge (gated on
  #1), #2 under-w bond edge (core seam), #9 worked window, column-flow for non-list rows.

## Round 15 (2026-07-07): Mitosis flattened + tiny-gang crusher + phi spiral

- "why does it even say cell?" → cell:<genus> containers DELETED from VoroMitosis: flora
  = loose {Genus:'epithet'} leaves directly under w; VoroMitosis_taxa(w) census by mainkey
  replaces w.o({cell:1}) everywhere; vfamily stamped on EVERY taxon inside Botany_plant
  (gang rep carries it → hulls survive). Third %see reworded ('the loose flora ganged
  itself by genus — one representative pane each and no container ever modelled').
  DRAMATURGY: seed=8 taxa < budget 15 → beats 2-3 genuinely loose; governor escalates
  ~beat 4 → gangs snap in. The crusher EARNS the clades on screen.
- CRUSHER EVOLUTION (all crush worlds!): tiny = leaf OR ≤3 all-leaf children → joins
  mainkey gang as a chip (sub glyph) instead of own pane; Voro_gang_fold else-branch
  falls back to crushable fold for containers (lone artist keeps its cell). Popped guard
  now popped+tiny (not leaf-only). MusuReplica husk counts may drift — check pre-Accept.
- PHI SPIRAL (owner asked specifically): list row claims pane's LEFTOVER height; chips at
  Vogel points r∝√(k+0.5), θ=k·137.508° (same golden angle as kind_hue), squeezed to row
  box, .seed chips absolute+centred; list cap 9→25 (+N tail). reserve = ~1 unit/4 chips
  in micro_fit's unit maths.
- Gen 48393c clean; svelte-check clean. Reload + re-record gate unchanged.

## Round 16 (2026-07-07): 📻 RADIO v1 + north stars = system doc

- Voro_vtuffing.md RETITLED "The Voro system" = THE system doc; §North stars leads:
  📻 radio (attention as supplied service — owner's product direction for jamsend
  lean-back) + 🕳 tunnel (cy stays 2D, x→θ over ~250° OPEN arc = letter C cross-section,
  y→z drift; SOLIDITY LEFT = families ordered by fold mass on the C's back; radio dwell
  IS the z-motion; CSS-3D per-overlay transforms first, not WebGL).
- RADIO v1 BUILT: Voro_drift_tick(w) — ages oldest auto-open shut (>3 held) / scores
  candidates (fold_n + freshness starve + same-vfamily/parent nearness + Voro_hash
  taste jitter, seq%4 free jump) / Vtuff_pop(best,null,AUTO) / returns focus; Cytui 📻
  toggle (stash Cyto_radio, default OFF), 7s dwell, cy.animate glide 2.4s, dial-touch
  (grab/pan/zoom not our glide) = 15s holdoff. popped_auto rides beside popped:
  Vtuff_unpop + crush_clear clear it; HUMAN pops never aged. SUBSUMES auto-spill #1.
- micro_click + radio_tick now LOUD on old gen (console.warn "reload") — the owner's
  "/*8 links don't go anywhere" was the silent Vtuff_pop?.() no-op pre-reload.
- Gen 52279c clean; svelte-check clean. RELOAD GATE: radio + surf need the new gen.
- Radio still needs (doc'd): taste from %Share hub weights/listen history, dwell
  modulation by pointer heat, AUDIO COUPLING (focus pane feeds playback — the product
  seam), determinism Book, generalised intent aging.

**Round 17 (2026-07-07 overnight):** 🕳 TUNNEL v1 skeleton — not per-overlay CSS 3D: ONE remap at the seed-gather (`tube_project`) puts seeds on the tube wall (θ by fold-mass rank, solidity-left at π ± alternating Δ over a 250° C-arc; r=R0/d; boxes ×NEAR/d) BEFORE the power diagram → cells/molding/chips/hulls/MORPH follow free (toggle = flat↔rosette morph). Per-cell fog rides `tz`→`fog`; radio dwell advances `tunnel_phase` (wrap-around recycle). Stash `Cyto_tunnel`, 🕳 button. UNTUNED. + **VoroRadio Book** (9 steps, What:Voro, brand_new) = the radio determinism gate (motion/aging/hand %sees); an adversarial Opus audit then caught v1's aging claim GREEN OFF THE LEAK ITSELF: the popped-tiny unstamp deleted `c.gang`, so unpop's gang sweep was dead code and aged locales leaked permanently-popped orphans (pool shrank silently, snap-blind). REAL fix = the popped unstamp KEEPS gang memory (crush_walk) + unpop sweeps then `delete n.c.gang`; Book now FOUR %sees with per-beat evidence (aged read at n=7, full-size re-gang CYCLE at n=8 — the claim that reddens on regression; a loose same-mainkey check is vacuous because the clean remainder mini-gangs). Re-recorded + 9/9 GREEN 2026-07-07 (4 sees live incl. the cycle — the engine fix proved itself); VoroMitosis 11/11 after the crush change (c-side = snap-blind, 8/9 steps matched pre-fix fixtures).


**Round 18 (2026-07-07, owner-directed):** the crush/radio thinking is now SNAPPABLE without polluting the flora. Owner's design: put it on a DIFFERENT w — "a projection on the wall next to it" — seeding Story's future separable snap channels (capture certain A/w on their own layer). `Voro_report(w, stats)` (called at the end of Voro_crush_scan, GATED on `w.c.crush_report` which VoroRadio_seed arms) writes a SIBLING world `w:<name>Report` (find-or-create under w.c.up=A, cleared+refilled each beat): a `crush,beat=N,level:L1,visible,gangs` header, a `drift,focus:<genus epithet>,opens` line, and one `row:<genus>,n,fold:gang|loose,rep,of,pop` per genus. A sibling world is NOT in the flora world's subtree so cyto_scan never renders it — SNAP-ONLY. Result: VoroRadio steps 2-8 (were byte-identical) now each diff, and "why is this genus loose/non-cell" is READABLE (governor level-dependent ganging + radio pops, e.g. `row:Coprosma,n=5,fold:loose,pop=5`). GOTCHA: a numeric level:1 snaps as the boolean sentinel (bare flag) and 0 vanishes — encode as STRING 'L'+n. VoroRadio re-recorded 9/9 green; flora world stays pure; VoroMitosis/VoroScape un-armed → untouched. Host committed it (56bf08c8/2c4d751e).
+ LAYOUT COLLAPSE fix (Cytui apply()): at witness, added disconnected %see nodes made fcose re-pack components into a diagonal, throwing away the grown rosette. Fix = track fresh_ids born this wave; on a PURELY-ADDITIVE wave (no removes) pin the already-settled nodes via fcose fixedNodeConstraint (relayout gained a pins param) so only newcomers place. Visual-only (positions never snap) → zero fixture churn; still UNCOMMITTED (Cytui).