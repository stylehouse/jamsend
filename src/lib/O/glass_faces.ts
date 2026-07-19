// glass_faces.ts — the COMPONENT-FREE half of the faces rail (Sounditron_todo §4e).
//  Cyto.svelte imports THIS (never glass_kinds.ts — that one imports the .svelte face
//   components, and the headless spine loads Cyto without a DOM to mount them in), so
//    the map of which mainkeys the glass imposes a face on stays importable everywhere.
//  A face by sc.face is WORN (the particle asked for it); a face by mainkey is IMPOSED
//   by the viewer — the world stays Voro-blind (no snap ever changes because the glass
//    chose to dress a %Heist).  glass_kinds.ts maps the KIND to its component for Cytui.
export const FACE_MAINKEYS: Record<string, string> = {
    Heist: 'Heist',       // the Pirating flow — posed needs | soft wish → %Leads → choose
    MusuSelf: 'Crate',    // my music home — the record collection, spread out to gaze across
    MusuThem: 'Crate',    // a friend's music as I hold it — same spread, worn with their name
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
