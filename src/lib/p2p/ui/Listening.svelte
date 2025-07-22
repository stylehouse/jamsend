<script lang="ts">
    import Pier from "./Pier.svelte";

    let {pub,eer} = $props()
</script>
            <li>Listening: {pub} 
                {#if eer.disconnected}
                    <span class="ohno tech">discon</span>
                {/if}
            </li>
            <ul class="bitsies">
                {#each eer.Piers as [pub,pier] (pub)}
                    <ul class=bitsies>
                        <Pier {pier} />
                    </ul>
                {/each}
            </ul>
