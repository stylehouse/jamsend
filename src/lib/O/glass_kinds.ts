// glass_kinds — the registry of FACES the glass can mount: a particle wearing sc.face:'<Kind>'
//  — or one whose mainkey the viewer imposes a face on (FACE_MAINKEYS, glass_faces.ts) —
//   gets the mapped Svelte component mounted in its node overlay (Cytui create_face_overlay),
//    earns a voronoi cell like a Stuffing does, and is molded into its cell by paint_final.
//  The FUNK_KINDS pattern (Funk/kinds.ts) worn by the glass: mainkey stays the particle's TYPE;
//   sc.face is a display request, never identity.  Props contract: { n: TheC, H: House } — the
//    live particle plus the House (imperative mount has no Svelte context; react off H.version).
//  Cyto.svelte must NEVER import this file (components need a DOM; the headless spine loads
//   Cyto without one) — the component-free half it needs lives in glass_faces.ts.
import RadioFace from './ui/RadioFace.svelte'
import StokerFace from './ui/StokerFace.svelte'
import TunerFace from './ui/TunerFace.svelte'
import HeistFace from './ui/HeistFace.svelte'

export const GLASS_KINDS: Record<string, any> = {
    Radio: RadioFace,     // the continuous listen — play/pause/skip, now-playing
    Stoker: StokerFace,   // the provisioning organ — watch the digs crank, poke a churn
    Tuner: TunerFace,     // the glass's dial — which crews of cells are shown
    Heist: HeistFace,     // the Pirating flow — posed needs | soft wish → leads → take
}
