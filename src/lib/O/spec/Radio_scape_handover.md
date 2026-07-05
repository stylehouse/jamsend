# Radio_scape_handover — the music scape, the Voro luxury layer, the road to Sounditron

Session-continuation brief for the **scape** half of the streaming platform: the Voronoi stained-glass
 view, the crush that feeds it, the two demo Books, and the `/` toplevel that boots them.
 The durable spec is `Radio_spec.md §8`; this is the *arc + the bombs + the next move*.
 Companion memories: `voronoi-cells-render`, `graph-of-music-scape`, `bigqualand-aufheben`,
  `music-cluster-kickoff`, `creduler-runner-architecture`.

## Destination

`/` (BigSoundland) is the music-half toplevel: a **runner booted on a music Book, rendered full-bleed as
 Voronoi stained glass**. The Book underneath is pivoting from a *seeded demo* (VoroScape) toward
  **Sounditron** — the sound twin of Educarium/Editron: a central diagnostic Book (NOT a Musu* test, NO
   Lies+Lang) that lurks in the background, probes the real audio + networking environment ("is a track
    playing? are my people online?"), and surfaces coherent errors so a *user* becomes a reporting
     test-probe. The stained-glass render is now a **decoupled luxury layer** (`Ghost/V/Voro.g`, in
      `CREDULER_GHOSTS`) that can be imposed on any graph via ◈ without the Story underneath ever knowing.

The whole point of the recent work: the crush stopped being a music-test fixture concern and became a
 view you drape over a graph. Everything below is a rung toward "a real music world, gathered live, seen
  as glass."

## Where it stands (the map)

- **`Ghost/V/Voro.g`** is the Vis family home. It holds the crush policy (`Voro_crush_scan / _walk /
   _crushable / _clear`, `Botany_*`) and the two demo Books (`VoroMitosis`, `VoroScape`). Compiles clean
    via LocalGen; enrolled in `CREDULER_GHOSTS` (runner-only).
- **The crush is c-side and snap-blind.** `c.stuff` = the fold (Cyto suppresses descent past it),
   `c.stuffy` = the crushed skin. NOTHING is snapped. No `%Crush_Tree`, no `%Opt` — fold totals are a live
    `{folded,count}` return; the demo Books arm it via `w.c.crush_wanted=1`, not a `%crushCyto` opt.
- **◈ imposes** on any graph (`Cyto_crush{on:1}` → `e_Cyto_crush` → `Scannable.c.crush_wanted`). MusuReplica
   is the imposition example (keeps the `%crushCyto` opt, calls the shared crusher cross-ghost).
- **Cytui UI:** a **Vexpandy** V-toggle in the ◈ bar doubles height (50vh↔100vh, `class:tall`)
   and re-fits after; the layout wave keeps overlays/cells live through the animation
    (`start_live_layout`), and pan/zoom ride the same live loop. The **rack is shelved**
     (`RACK_ON = false` in `voronoi_layout()` — oddballs sit where fcose put them, cells
      tessellate the full width); the **visor** is a pass-through indicator whose wheel-steal
       lives in `visor_guard` (capture-phase on the wrap, stands down when the page can't
        scroll — so full-bleed BigSoundland wheel-zooms with no prop). **←/→ on the focused
         canvas** step the story pips via Storui's published `H.c.story_nav`. All
          code-complete + typecheck clean; browser-unverified.
- **Credence** `What:Voro` lists `VoroMitosis` + `VoroScape` (both `brand_new:1`); the stray `Musu*` names
   are cleared.

## The bombs (know these or waste a session)

1. **Verify ONLY on a live `:9091` runner.** Headless (`Story_cli_run.mjs`) gives false greens — it
    quiesces at a different depth than a live runner. `scripts/runner_ask.mjs run <Book> --watch`. See
     `verify-via-live-runner`, `testing-is-story-books`.
2. **Three fixtures are OWED, live.** `VoroMitosis`, `VoroScape`, `MusuReplica` — fixtures were cleared;
    the rename + the c-side flip invalidated the old snaps. Re-record only **after the human reloads the
     flock tab** (this area landed gen writes + Cytui HMR; never re-record onto stale gens or mid-run).
3. **The crush leaves NO trace in the snap — by design.** Don't hunt for `%Crush_Tree`, `%Opt`, or `,stuff`
    keys in a fixture; their absence is correct. What the run records is the *unfolded* tree.
4. **World-name dispatch: the run world MUST be named after the Book.** `VoroScape` → `VoroScape(A,w)` in
    Voro.g (`do_fn_for` reads `w.sc.w`). Rename the method and the world together or the Book silently does
     nothing. (`music-cluster-kickoff`, `creduler-runner-architecture`.)
5. **`CREDULER_GHOSTS` is runner-only.** The editor never loads Voro.g, so ◈ imposition logs and stands
    down in an editor tab — test the imposition in a runner.
6. **HMR kills in-flight runs; tab reloads are the human's job.** Don't save src mid-run; don't dispatch
    into a wedged tab.

## The next move (ordered)

1. **Reload the flock tab, then live re-record** `VoroMitosis` → watch the genus-keyed flora divide and
    fold one-pane-per-genus → `VoroScape` → `MusuReplica`. Accept the fresh fixtures.
2. **Browser-verify BigSoundland draws glass.** The plain `/` tab stalls at Creduler spine-load (no
    identity/share/relay); BigSoundland.svelte's diagnostic surface shows why. Decide the boot-role open
     question: a runner boot joins the relay flock (fits a live Piracy-scape) vs `boot_role='editor'`.
3. **The Sounditron pivot** — replace the seeded VoroScape with a LIVE gather: real library via the Crate
    nav (`Radio_spec §5.1`) + real Piers off the Swarm side (`Swarm_spec §6`), NO Lies+Lang, a background
     probe that surfaces coherent audio/network errors. This is the real destination; the demo Books were
      the render's gauges.
4. **The grind list is `Voro_todo.md`** — render polish and the bigger render ideas (wrap-width from
    the cell, angle, fold colour|size, family outlines, crush-harder grouping, in-cell microcosms,
     pinch|spread, the SVG Stuffing rebuild) live there now, briefed for cold pickup with the
      metaphysics up top. Per-genus colour + fold-count size are its tasks 3.

## The disputed thread — RESOLVED

The `start_live_layout` claim ("Stuffings stay visible while animating") stood UNVERIFIED for a
 session; the owner then confirmed it from the live tab — "in other conditions it stays beautifully
  glidy" (2026-07-06) — while reporting the one gap: scroll-to-zoom still blanked them. The zoom/pan
   path now drives the same live loop (`pan_zoom_motion`), and the settle-jump it exposed (the
    reposition-to-node flash between gesture end and re-mold) is fixed by `reposition_overlays`
     skipping cell-molded Stuffings. The zoom path is the remaining browser-unverified bit.
