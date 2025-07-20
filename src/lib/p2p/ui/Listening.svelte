<script lang="ts">
    import Pier from "./Pier.svelte";

    let {pub,eer} = $props()
</script>
            <li>Listening: {pub}</li>
            <ul class=bitsies>
                {#each eer.Piers as [pub,pier] (pub)}
                    <li>Peering: {pub}</li>
                    <ul class=bitsies>
                        <Pier {pier} />
                    </ul>
                {/each}
            </ul>