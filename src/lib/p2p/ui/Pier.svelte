<script lang="ts">
    import type { Pier } from "../Peerily.svelte";

    let {pier}:{pier:Pier} = $props()
</script>
Pier: {pier.pub} 
{#if pier.disconnected}
    <span class="ohno tech">discon</span>
{/if}
