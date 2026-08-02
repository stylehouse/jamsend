---
name: bigwordland-toplevel
description: "/BigWordland — the second toplevel (src/lib/L/): big-empty-room editor, ?E default Educarium (Editron's sibling recipe), H** toc + Actions panel, all H.UIs at once, Lies hidden till summoned, search pin rail; built 2026-07-03, browser-unverified"
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

**/BigWordland (BUILT 2026-07-03, uncommitted, browser-verify OWED).**  A second toplevel
 rivaling Otro; home = the NEW `src/lib/L/` ("a big empty space, yet Lies+Lang in disguise" —
  the user's framing).  The MACHINE is identical (same `<Ghost {H}/>` mounts, same House
   construction incl. Otro's OOM-trap discipline, same disk gate); only the room differs.

- **Boot**: route `/BigWordland` → `L/BigWordland.svelte`; `?E=<Book>` with DEFAULT
   `Educarium`; role is always editor (no ?B/?I — runners board via /Otro).
- **Educarium** = Editron's sibling Book: recipe ghost `L/Educarium.svelte`
   (`Run_A_Educarium` lays A:Educarium/w:Educarium + Lies/Lang editor:1 + Pantheate;
    per-beat `Educarium(A,w)` opens ?W= Waft, default Ghost/Net/Easy), mounted in
     `O/Ghost.svelte`, toc at `wormhole/Story/Educarium/toc.snap` (minimal, lie dige —
      first run re-records).  `?E=Educarium` under /Otro boots the same Book in Otro chrome.
- **The room** (`L/BigWordland.svelte`): sticky top bar = name · **H\*\* toc** (a chip per
   House, ip-depth as indent; click drops that House's panel = Actions rack + C\*\* toggle)
    · **⌐Lies chip** · the universal Searchbar.  Body = ALL `H.UIs` at once, loose, each
     with a tiny `house · UI` tag — EXCEPT `UI:'Lies'`, hidden until the chip summons the
      straight Liesui.  NO NaviScroll.
- **Pin rail**: Searchbar got optional `onpin` (Liesui passes nothing → unchanged); pinned
   hits ride BigWordland $state in a fixed right rail ("the loose space to the right of the
    code"); pin click = the same `Lies_ghost_pick{path,point}` Aside-recorded delivery.
     NEXT HOP the user mused: fold pins into the **DocMinimap** proper.
- **GOTCHA — Brink lives inside Liesui**: with Lies hidden the Sound face is unreachable, so
   the room's gate fires on `disk_gated || ac_wanted` (no `ac_via_brink` suppression).
- **DRY (2026-07-04)**: the disk|audio gate extracted to `O/ui/BootGate.svelte` — Otro
   mounts `<BootGate {H}/>` (role copy, Brink-deferred audio), the room mounts
    `who="the room" audio_fullscreen`.  STILL duplicated by choice: the ~35-line H:Mundo
     construction block (the OOM-trap region — every tab boots through Otro's; extract as
      its own proven slice, not casually), childrenOf (9 lines), the UIs render loop
       (structurally different: column vs room).  Educarium∥Editron recipes stay parallel
        deliberately (per-Book observability).
- The Searchbar's Lies House/w are found by scanning `houses` for the ave carrying
   `%examining` (the Liesui seam).  Waft-hover glow has no source in the room until Lies is
    summoned (hover prop not wired there — Liesui's own wiring covers it).
- **Verify owed (owner, :9091)**: /BigWordland boots to the room, gate → share, toc chips
   drop panels, Langui shows, ⌐Lies summons, '/' search + 📌 pins + pin-click delivery.
    The dev server may need a restart to pick the new route up cleanly (container sync
     re-numbered generated client nodes; see [[running-check-in-container]]).

----
## merged from bigqualand-aufheben.md

---
name: bigqualand-aufheben
description: "Two Big*land toplevels aufheben'd onto shared BigQualand: /BigSoundland (V/BigSoundland.svelte, was Mound; bare / 404s now — bots — via routes/+page.ts) music scape + /BigWordland (L/) editor room. Shared boot hook boot_qualand (O/BigQualand.svelte.ts). Each room's Book IS the background diagnostic probe (Educarium for Word; MusuScape→becoming Sounditron for Sound — central, NO Lies+Lang). /BigSoundland stuck at 'gathering the glass…' = Creduler spine-load hold on a plain tab; BigSoundland shows a boot diagnostic"
metadata:
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

Owner is **aufheben**-ing (sublate) the two new toplevels onto a shared **BigQualand** substrate:
- **`/` = /BigSoundland** = **`src/lib/V/BigSoundland.svelte`** (RENAMED from Mound 2026-07-05, "for
   verbosity"; both `/` and the named `/BigSoundland` route mount it; header "◈ BigSoundland"). The music
    scape — Voronoi stained glass ([[graph-of-music-scape]]); boots a music `?B=` Book, `boot_role:'runner'`.
- **/BigWordland** (`src/lib/L/BigWordland.svelte`) — the editor room, Lies+Lang in disguise; `?E=` Book
   (default Educarium), `boot_role:'editor'`.

**The "check it came up right" role is the BOOK** (owner corrected my qual-Story read). Each room boots an
 **Editron-shaped diagnostic Book** that lurks in the background, probes the real end-user environment, and
  surfaces coherent errors so a user becomes a reporting test-probe. Word = **Educarium**. Sound = **MusuScape
   becoming Sounditron** — the sound twin of Editron/Educarium, but **central, NOT a Musu* test, and with NO
    Lies+Lang** (unlike the editor Books); it probes audio + the networking layer ("is a track playing? are my
     people online?"). Sound's two VALID outcomes: **a track playing OR no peers online**. So `boot_qualand`'s
      `book` param IS the seam — no separate verdict to wire. (Sounditron proper is a NEXT build, not just a
       rename: MusuScape is a green .g test Book with fixtures — de-test-ifying it needs care + a settled shape.)

**THE `/` STALL — "gathering the glass…" forever** (owner sees this): a runner boot HOLDS story-start until
 the **Creduler loads the spine** (`Auto.svelte:458` — "⏳ Creduler loading spine…"). A plain `/` tab with no
  `?I=` identity, no granted FSA share, no relay engagement likely never acquires it → no H:Story → no Cyto.
   The MusuScape green was on a LIVE runner (?B= tab w/ share+relay); the plain `/` tab lacks all that. The
    real fix (a standalone/bundled spine for `/`, or gate `/`→editor role) is deferred, owner-call territory.

DONE 2026-07-05 (svelte-compile-validated, browser-verify OWED, uncommitted):
- **`src/lib/O/BigQualand.svelte.ts`** — `boot_qualand({book, role})` rune hook → reactive `H`+`houses`,
   OOM trap baked in (assign H once; never read $state H in the construction $effect). Alias with
    `let H=$derived(q.H)` (getters — don't destructure). Both toplevels' ~30-line boots collapsed to 3 lines.
- **BigSoundland boot diagnostic** — when the glass isn't up, shows the Story runner UI (+ any non-Cyto UI
   the run produced) plus a live House list + a Creduler/story-stood state line, so you scan the stall.
- **BigWordland**: todo-count as an out-of-flow **exponent** (`.bw-todo position:absolute;left:100%` off a
   `.bw-h-name` wrap) — fixed the searchbar VIBRATE (a changing count re-sized the chip, shoved the toc).
   Tight side margins (`.bw` padding 1.2rem→0.4rem). **Story hidden in the room** (`ROOM_HIDDEN={Story,Cyto,
    Pantheate-include}`) so only the editor (Lies/Langui/LangTwist) paints.

FINDING (deferred, sensitive Lies/Run pipeline): the **two Pantheate-includes** are one-per-compiled-dock —
 `LiesCortex` fires `Pantheate Ghost_update_notify` on EVERY compile (even editor role), `LiesRun.Pantheate`
  mounts a `UI:Pantheate-include`/gen_path per notify. Owner: should sprout only from the **%rungo** run path
   (barely exists; near-term launch = write code, commit, run Books — NOT editor-compile-runs).

DONE 2026-07-05 (BigWordland nav, svelte-compile-clean, browser-verify OWED): the **show-one-thing view
 switcher**. The top toc (Mundo · Story · Educarium — the Run named after the ?E= book) is now a SWITCHER:
  clicking a chip makes that House the ONE fullscreen view (room filters `houses` to `active_ip`). `view` =
   explicit pick; auto falls back to the Educarium Run (opens on **Langui**, its editor UI) else the deepest
    House (boot stays visible). A **⚙ cog** rides beside the ACTIVE chip only → toggles that House's action-
     button rack (was: click-chip-drops-panel `open_panel`; gone). `ui_hidden()` replaces ROOM_HIDDEN: hides
      Pantheate-include always + Lies-unless-⌐summoned; Story/Cyto are NOT hidden (they live on other Houses,
       so the one-House view already leaves them off unless you switch to Story).

PENDING (needs owner steer): Sounditron the Book (see [[radiobuddies-shebang-unnamed]] for the networking it
 rides); nav follow-ons (with-others space-mix vs alone-fullscreen config, Liesui as a partial mix,
  subparts-in-toc, searchbar-parameterised-into-the-common-bit); resolving the `/` stall.

----
## merged from graph-of-music-scape.md

---
name: graph-of-music-scape
description: "VoroScape Book (was MusuScape — graph of music: Artist/Track panes + Peer shares as edges + hubs, crush-folds to voronoi); RENAMED + MOVED to Ghost/V/Voro.g 2026-07-05 (twin VoroMitosis, was MusuMitosis); BigSoundland (was Mound, lib/V/) boots a runner on it full-bleed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

**Session residence for this whole area: `src/lib/O/spec/Radio_scape_handover.md`** (arc + bombs + next move) and the durable spec `Radio_spec.md §8` (rewritten 2026-07-05 to current reality).

**RENAMED 2026-07-05:** MusuScape→**VoroScape**, MusuMitosis→**VoroMitosis**, both MOVED out of `Ghost/Story/Musuation.g` into **`Ghost/V/Voro.g`** (the Vis family home). The crush now writes NOTHING to the snap (c-side `c.stuff`/`c.stuffy`, no `%Crush_Tree`, no `%Opt` — armed via `w.c.crush_wanted`), and VoroMitosis species are keyed by genus (`{Coprosma:'robusta'}`). Book dirs `wormhole/Story/Voro{Mitosis,Scape}`; fixtures cleared, live re-record owed. Details in [[voronoi-cells-render]] round 5. Names below are pre-rename.

The owner's destination for **lib/V/ (Mound, the / route Piracy-scape)**: "Voronoi stained glass graphs
 of music" — the Cyto graph of a music world tessellated into stained-glass cells (Cytui ◈ voronoi mode,
  power-diagram cells coloured by Matstyle — see [[voronoi-cells-render]]). The render already existed;
   the gap was *a graph of music worth tessellating* + *a toplevel that boots it*.

**MusuScape** (2026-07-05, `Ghost/Story/Musuation.g` `//#region scape`, live-recorded **GREEN 6/6
 caveat:0**): the MUSIC twin of **MusuMitosis** (which watched abstract NZ-flora cells divide). Cells are
  MUSIC, edges are SOCIAL — the graph structure MusuMitosis lacks:
- `%Artist,name / %Track,title` panes (the library, folded one-pane-per-artist by the crush).
- `%Peer,name / %Share,track` — a friend and the tracks they share; a **share is an EDGE onto a real
   track** (`MusuScape_dangling`=0 is the health check).
- **hub** = `MusuScape_hub(w,title)` = how many friends share a track = the power-diagram weight (a hit
   blazes, a deep cut is a sliver, zero is dark). The headline differential.
- beats 2-6: library stands → Bo shares → Ada shares (Tide becomes a hub, weight 2) → **Ada leaves and the
   hub cools LIVE 2→1** (a track she alone lit goes dark 1→0) → crush folds every pane, voronoi arms.
- 5 gated `%see`, each `n===K` + live truth so it appears once and DROPS ([[see-is-not-a-latch]]); the
   drop IS the signal (beat-4 "it lights up as a hub" gives way to beat-5 "the hub cools"). Deterministic,
    count-driven (no clock/randomness) like MusuMitosis; headless CredRunner matched the live snap byte-
     for-byte before accept. Registered in Credence What:Musu. Fixtures uncommitted for the human.

**Mound wired** (`src/lib/V/Mound.svelte`, was a stub counter): boots the SAME machine Otro boots, as a
 **runner on a music Book** (`h.c.book`, `boot_role='runner'`; default `MusuScape`, `?B=` overrides —
  ?B=MusuMitosis for the flora colony), and renders the Cyto UI (`house.UIs.ob({UI:'Cyto'})[0].sc.component`,
   full-bleed) — MusuScape crush-folds at its last beat so `saw_stuffy` auto-arms the voronoi and the run
    rests in the stained-glass state. Mirrors Otro's runner boot + BigWordland's render scaffold verbatim
     (the OOM trap: assign H once, never read $state H in the construction effect). **FIRST CUT —
      browser-verify OWED** (pixels no Book can see; compiles clean via svelte compiler). OWNER CALL owed:
       a runner boot joins the relay flock (one runner per / hit — how MusuMitosis is watched today; fits
        a live p2p Piracy-scape, but switch to `boot_role='editor'` if / shouldn't spawn a grid runner).
         NEXT: replace the seeded Book with a LIVE gather (real library + real Piers off the Swarm side),
          and the bespoke Voro surface ("Voro gets gathered in here later").
