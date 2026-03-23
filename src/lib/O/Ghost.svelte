<script lang="ts">
    // Ghost.svelte — single mount under Otro.
    // Presents a shim M to each ghost child so their eatfunc() deposits
    // into H.ghosts and triggers H.ghostsHaunt() across H/%H**.
    // H.ghosts ($state null→object) gates subHouse creation in Otro.

    import Agency    from "$lib/ghost/Agency.svelte"
    import Machinery from "$lib/ghost/Machinery.svelte"
    import Story     from "$lib/ghost/Story.svelte"
    import Cyto from "./Cyto.svelte";

    let { H } = $props()   // H = H:Mundo (the real House)

    // shim presented to each ghost instead of H directly
    // each ghost calls M.eatfunc(hash) on onMount
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
<Cyto     {M} />