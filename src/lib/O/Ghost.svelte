<script lang="ts">
    // Ghost.svelte — single mount under Otro.
    // Presents a shim M to each ghost child so their eatfunc() deposits
    // into H.ghosts and triggers H.ghostsHaunt() across H/%H**.
    // H.ghosts ($state null→object) gates subHouse creation in Otro.
    //
    // ── ghost load order ─────────────────────────────────────────────────────
    //
    //   Agency    — w:officing, self-timekeeping, Aw_satisfied, i_unemits_o_Aw
    //   Machinery — general w:* methods (prandle, requesty_serial, etc.)
    //   Story     — w:Story, snap/toc codec, story_drive, story_save, Run wiring
    //   Cyto      — w:Cyto, cyto_scan, grawave, e_story_cyto_step handshake
    //   Text      — pure text/diff functions: depth_of, char_diff_ops,
    //               compute_diff, squish_context, positional_diff, enDif, deDif
    //
    //   All ghosts call M.eatfunc(hash) in onMount.  eatfunc merges hash into
    //   H.ghosts and calls H.ghostsHaunt() which Object.assigns onto every H
    //   instance reachable from root.  Later ghosts can therefore call methods
    //   deposited by earlier ones (e.g. Story calls this.requesty_serial which
    //   Machinery deposited).
    //
    //   Textures is last because it has no dependencies on the other ghosts
    //   and the other ghosts have no dependency on it — order doesn't matter
    //   for Textures, but last keeps the list logically grouped: infra (Agency,
    //   Machinery), features (Story, Cyto), utilities (Textures).

    import Agency    from "$lib/ghost/Agency.svelte"
    import Machinery from "$lib/O/Machinery.svelte"
    import Story     from "$lib/O/Story.svelte"
    import Cyto      from "./Cyto.svelte"
    import Text  from "$lib/O/Text.svelte"
    import Auto from "./Auto.svelte";
    import Matstyle from "./Matstyle.svelte";
    import Lang from "$lib/L/Lang.svelte";

    let { H } = $props()   // H = H:Mundo (the real House)

    // shim presented to each ghost instead of H directly.
    // each ghost calls M.eatfunc(hash) on onMount.
    const M = {
        eatfunc(hash: Record<string, Function>) {
            // merge into H.ghosts
            H.ghosts = { ...(H.ghosts ?? {}), ...hash }
            // push to all known Houses now
            H.ghostsHaunt()
        }
    }
    // < extract what we will keep from Agency, etc...
</script>
<Agency    {M} />
<!-- below are all AI -->
<Machinery {M} />
<Story     {M} />
<Cyto      {M} />
<Matstyle  {M} />
<Lang      {M} />
<!-- pure text/diff utilities — depth_of, compute_diff, squish_context, enDif, deDif, etc. -->
<Text  {M} />
<!-- what are we working on, and memories drifting away -->
<Auto  {M} />