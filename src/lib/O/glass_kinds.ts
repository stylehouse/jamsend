// glass_kinds — the registry of FACES the glass can mount: a particle wearing sc.face:'<Kind>'
//  gets the mapped Svelte component mounted in its node overlay (Cytui create_face_overlay),
//   earns a voronoi cell like a Stuffing does, and is molded into its cell by paint_final.
//  The FUNK_KINDS pattern (Funk/kinds.ts) worn by the glass: mainkey stays the particle's TYPE;
//   sc.face is a display request, never identity.  Props contract: { n: TheC, H: House } — the
//    live particle plus the House (imperative mount has no Svelte context; react off H.version).
import RadioFace from './ui/RadioFace.svelte'

export const GLASS_KINDS: Record<string, any> = {
    Radio: RadioFace,
}
