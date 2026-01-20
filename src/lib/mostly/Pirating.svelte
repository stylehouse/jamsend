<script lang="ts">
    import { onMount } from "svelte";
    import { throttle } from "$lib/Y";
    import { keyser, objectify, TheC } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import type { Modusmem } from "./Modus.svelte.ts";
    import Modus from "./Modus.svelte";
    
    let {M,mem,heist}:{M:Modus,mem:Modusmem,heist:TheC} = $props()


</script>
    <Scrollability maxHeight="60vh" class="content-area">
        {#snippet content()}
            <Stuffing mem={mem.further("heist")} stuff={heist} {M} />
        {/snippet}
    </Scrollability>