// glass_faces.ts — the COMPONENT-FREE half of the faces rail (Sounditron_todo §4e).
//  Cyto.svelte imports THIS (never glass_kinds.ts — that one imports the .svelte face
//   components, and the headless spine loads Cyto without a DOM to mount them in), so
//    the map of which mainkeys the glass imposes a face on stays importable everywhere.
//  A face by sc.face is WORN (the particle asked for it); a face by mainkey is IMPOSED
//   by the viewer — the world stays Voro-blind (no snap ever changes because the glass
//    chose to dress a %Caper).  glass_kinds.ts maps the KIND to its component for Cytui.
export const FACE_MAINKEYS: Record<string, string> = {
    Caper: 'Caper',       // the OPERATION — posed needs | soft wish → %Leads → choose → the built pull
    // %Heist,pub:<their prepub> — ONE NAB OF AN ALBUM, the ⇊ keep-what-you're-hearing cell (imposed by
    //  mainkey; no %Heist wears sc.face).  THE NAME TOOK THREE GOES.  %Keep until 2026-08-05 (the human:
    //   "%Keep is too weak a word") → %Haul, because %Heist was already taken by the JOB particle and two
    //    shapes under one mainkey is the tell.  %Haul was always a consolation: a haul is the whole take,
    //     so it was the wrong SCALE for one album (the owner 2026-08-09: *"I actually intended for the
    //      Heist to be each nab of an album, and the Haul to be the larger collective"*).  Fixed by moving
    //       the blocker instead of the blocked: the operation is %Caper now, so the nab finally gets the
    //        name it was always meant to have — and the name matches the verbs (Heist_keep_*) that have
    //         driven it all along.  %Haul is now FREE, reserved for the larger collective: the What
    //          Heisted ledger a finished %Heist graduates into rather than being flattened away.
    Heist: 'Heist',
    // the NESTED heist (the human 2026-07-28 "one for the hierarchy, one for the list of tracks"): under the
    //  nested glass a %Heist goes BARE (a scope suppresses its own face) and tessellates into its %HeistBar
    //   controls cell + one %Pick chip per kept track.  A flat (non-nested) %Heist still wears Heist above.
    HeistBar: 'HeistBar',   // the heist's controls cell — genre · dest · all|none · ▶ start · ✕ · progress
    Pick: 'Pick',         // one kept track in the nested keep — ✓/♪/⇊, click un-keeps
    Diag: 'Diag',         // the diagnostics toggle cell (imposed by mainkey)
    Errlog: 'Errlog',     // the Story error channel (spec/Error_channel_todo.md) — lazy-minted, so this cell
                          //  only ever appears when a run captured a throw; loud-when-broken, no snap byte to dress it
    Supervisor: 'Supervisor', // THE ONE SANITY CELL — the %Supervisor summary row on w:Supervisor (which lives on
                          //  MUNDO, not the run: it must outlive the House it reports on).  Quiet when healthy —
                          //   one dim line — and speaks up only when a registered watch reads wrong, unmet, or
                          //    blind.  It replaces the rank of idle HUDs, and it never names what it watches.
    Transfer: 'Transfer', // the live transfer HUD — a persistent dontSnap cell the wire feeds (top_House().c.xfer);
                          //  jiggling rx/tx bars + per-track pull/serve progress so bytes-in-flight are VISIBLE
    Shuffle: 'Shuffle',   // the shuffle pool — a dontSnap cell showing WHAT THE DIAL CAN REACH vs what
                          //  merely stands in the crate; the husk/dial-able gap is the "same 10 tracks" shape
    MusuSelf: 'Crate',    // my music home — the record collection, spread out to gaze across
    MusuThem: 'Crate',    // a friend's music as I hold it — same spread, worn with their name
    // Tree: THE FACELESS FACE (the human 2026-08-07 "a cell can kind of be a component or a
    //  rendering of the C data all labelled ... and recurse C**") — MISSING from this map since it
    //   was built, which means it has never actually rendered.  `cyto_face_kind` (Cyto.svelte) falls
    //    through to null for any mainkey absent here with no sc.face worn, and Sounditron_commission's
    //     two %Tree mints (the underworld tree, and 2026-08-10's Supervisor tree) neither set sc.face.
    //      Found via runner_shot --svg while checking the Supervisor-as-pure-C-tree case: the capture
    //       showed 4 molds where 6 were minted, and neither missing one was ever a Tree.
    Tree: 'Tree',
}

// CREW_MAINKEYS — the viewer's CREW imposition (the /system/ subcellularity, the human
//  2026-07-19: "a /system/ [group] to put a bunch of the current lot in").  Machinery rows
//   tessellate under ONE 'system' crew, so a single tuner toggle tucks the whole
//    boiler-room away and the glass keeps its space for the user's-eyes faces.
//  Same law as FACE_MAINKEYS: viewer-side, zero snap change, explicit sc.crew always wins.
export const CREW_MAINKEYS: Record<string, string> = {
    req: 'system',
    Machine: 'system',
    Relay: 'system',
    Census: 'system',
    Possibility: 'system',
    Session: 'system',
    Tally: 'system',
    Audio: 'system',
    // the debug shelf (2026-07-19, "should be under a debug folder"): cursor memories, run
    //  records, replication bookkeeping — real state, none of it for a visitor's eyes.
    Dogear: 'system',
    Storyrun: 'system',
    Sent_Tree: 'system',
    Crush_Tree: 'system',
}
