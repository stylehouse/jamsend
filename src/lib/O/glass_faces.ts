// glass_faces.ts — the COMPONENT-FREE half of the faces rail (Sounditron_todo §4e).
//  Cyto.svelte imports THIS (never glass_kinds.ts — that one imports the .svelte face
//   components, and the headless spine loads Cyto without a DOM to mount them in), so
//    the map of which mainkeys the glass imposes a face on stays importable everywhere.
//  A face by sc.face is WORN (the particle asked for it); a face by mainkey is IMPOSED
//   by the viewer — the world stays Voro-blind (no snap ever changes because the glass
//    chose to dress a %Heist).  glass_kinds.ts maps the KIND to its component for Cytui.
export const FACE_MAINKEYS: Record<string, string> = {
    Heist: 'Heist',   // the Pirating flow — posed needs | soft wish → %Leads → choose
}
