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
    //   Cyto      — w:Cyto, cyto_scan, grawave, story_cyto_step handshake
    //   Textures  — pure text/diff functions: depth_of, char_diff_ops,
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
    import Machinery from "$lib/ghost/Machinery.svelte"
    import Story     from "$lib/ghost/Story.svelte"
    import Cyto      from "./Cyto.svelte"
    import Text  from "$lib/ghost/Text.svelte"

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
</script>

<Agency    {M} />
<!-- these are all AI -->
<Machinery {M} />
<Story     {M} />
<Cyto      {M} />
<!-- pure text/diff utilities — depth_of, compute_diff, squish_context, enDif, deDif, etc. -->
<Text  {M} />