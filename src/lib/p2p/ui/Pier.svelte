<script lang="ts">
    import type { Pier } from "../Peerily.svelte";

    let {pier}:{pier:Pier} = $props()
</script>
<li>Pier: {pier.pub} 
    {#if pier.disconnected}
        <span class=ohno>discon</span>
    {/if}
</li>
