<script lang="ts">
    import Pier from "./Pier.svelte";

    let {pub,eer} = $props()
</script>
            <div>Listening: {pub} 
                {#if eer.disconnected}
                    <span class="ohno tech">discon</span>
                {/if}
            </div>
            <div class="bitsies">
                {#each eer.Piers as [pub,pier] (pub)}
                    <div class=bitsies>
                        <Pier {pier} />
                    </div>
                {/each}
            </div>
